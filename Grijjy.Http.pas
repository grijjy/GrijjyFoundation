unit Grijjy.Http;

{ Windows and Linux Cross-platform HTTP, HTTPS and HTTP/2 protocol
  support class using scalable client sockets }

interface

{$I Grijjy.inc}

//{$DEFINE LOGGING}
{$DEFINE HTTP2}

uses
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  System.SyncObjs,
  System.DateUtils,
  System.Messaging,
  System.Net.URLClient,
  System.Net.Socket,
  System.Generics.Collections,
  {$IFDEF MSWINDOWS}
  Grijjy.SocketPool.Win,
  Windows,
  {$ENDIF}
  {$IFDEF LINUX}
  Grijjy.SocketPool.Linux,
  Posix.Pthread,
  {$ENDIF}
  {$IFDEF HTTP2}
  Nghttp2,
  {$ENDIF}
  Grijjy.BinaryCoding;

const
  { Socket buffer size }
  BUFFER_SIZE = 32768;

  { Timeout for operations }
  TIMEOUT_CONNECT = 20000;
  TIMEOUT_RECV = 5000;

  { Strings }
  S_CONTENT_LENGTH = 'content-length';
  S_CONTENT_TYPE = 'content-type';
  S_TRANSFER_ENCODING = 'transfer-encoding';
  S_CHUNKED = 'chunked';
  S_CHARSET = 'charset';

  { End of line }
  CRLF = #13#10;

  { Ports }
  DEFAULT_HTTP_PORT = 80;
  DEFAULT_HTTPS_PORT = 443;

  { Cleanup }
  INTERVAL_CLEANUP = 5000;

type
  { Http events }
  TOnRedirect = procedure(Sender: TObject; var ALocation: String; const AFollow: Boolean) of object;
  TOnPassword = procedure(Sender: TObject; var AAgain: Boolean) of object;
  TOnRecv = procedure(Sender: TObject; const ABuffer: Pointer; const ASize: Integer; var ACreateResponse: Boolean) of object;
  TOnSent = procedure(Sender: TObject; const ABuffer: Pointer; const ASize: Integer) of object;

  { ISO-8859-1 ASCII compatible string }
  {$IFDEF MSWINDOWS}
  ISO8859String = type AnsiString(28591);
  {$ELSE}
  ISO8859String = type RawByteString;
  {$ENDIF}

type
  { Thread safe buffer }
  TThreadSafeBuffer = class(TObject)
  private
    FLock: TCriticalSection;
    FBuffer: TBytes;
    FSize: Integer;
  public
    constructor Create(const ACapacity: Integer = BUFFER_SIZE);
    destructor Destroy; override;
  protected
    function GetSize: Integer;
  public
    { Write buffer }
    procedure Write(const ABuffer: Pointer; const ASize: Integer);

    { Read entire buffer }
    function Read(out ABytes: TBytes): Boolean; overload;

    { Read count number of bytes from the buffer }
    function Read(out ABytes: TBytes; const ACount: Integer): Boolean; overload;

    { Read up to length number of bytes from the buffer, for nghttp2 }
    function Read(const ABuffer: Pointer; var ALength: NativeInt): Boolean; overload;

    { Read all bytes up to and including substring match }
    function ReadTo(const ASubStr: RawByteString; out ABytes: TBytes): Boolean;

    { Clear the buffer }
    procedure Clear;

    {$IFDEF LOGGING}
    { Outputs the buffer to log }
    procedure Log(const AText: String);
    {$ENDIF}
  public
    { Current actual size of the buffer }
    property Size: Integer read GetSize;
  end;

type
  { Client activity state }
  TgoHttpClientState = (None, Error, Sending, Receiving, Finished);

  { Http header }
  TgoHttpHeader = record
    Name: String;
    Value: String;
    {$IFDEF HTTP2}
    NameAsISO8859: ISO8859String; { nghttp2 requires a pointer to a memory object we maintain }
    ValueAsISO8859: ISO8859String;
    {$ENDIF}
  end;

  { Http headers class }
  TgoHttpHeaders = class(TObject)
  private
    FHeaders: TArray<TgoHttpHeader>;
  public
    constructor Create;
    destructor Destroy; override;
  public
    { Add or set a header and value to a list of headers }
    procedure AddOrSet(const AName, AValue: String); overload;
    procedure AddOrSet(const AHeader: String); overload;

    { Get the value associated with the header }
    function Value(const AName: String): String;

    { Returns the index of the associated header }
    function IndexOf(const AName: String): Integer;

    { Reads headers as http compatible header string }
    function AsString: String;

    { Reads headers as ngHttp2 compatible header array }
    {$IFDEF HTTP2}
    procedure AsNgHttp2Array(var AHeaders: TArray<nghttp2_nv>);
    {$ENDIF}
  public
    property Headers: TArray<TgoHttpHeader> read FHeaders write FHeaders;
  end;

  { Http client }
  TgoHttpClient = class(TObject)
  private
    {$IFDEF HTTP2}
    FHttp2: Boolean;
    {$ENDIF}
    FBlocking: Boolean;
    FConnection: TgoSocketConnection;
    FConnectionLock: TCriticalSection;
    FState: TgoHttpClientState;
    FConnectTimeout: Integer;
    FRecvTimeout: Integer;

    { SSL }
    FCertificate: TBytes;
    FPrivateKey: TBytes;

    { Recv }
    FRecvBuffer: TThreadSafeBuffer;
    FRecvBuffer2: TThreadSafeBuffer;
    FLastRecv: TDateTime;
    FRecvAbort: Boolean;
    FRecv: TEvent;

    { Send }
    FSendBuffer: TThreadSafeBuffer;
    FLastSent: TDateTime;

    { Http request }
    FURL: String;
    FMethod: String;
    FURI: TURI;
    FLastURI: TURI;
    FContentLength: Int64;
    FTransferEncoding: String;
    FHttpVersion: String;
    FFollowRedirects: Boolean;
    FSentCookies: TStrings;
    FCookies: TStrings;
    FAuthorization: String;
    FUserName: String;
    FPassword: String;
    FContentType: String;
    FConnected: TEvent;
    FInternalHeaders: TgoHttpHeaders;
    FRequestStatusLine: String;
    FRequestHeaders: TgoHttpHeaders;
    FRequestBody: String;
    FRequestData: TBytes;
    FUserAgent: String;
    FRange: String;

    { Http response }
    FResponseHeader: Boolean;
    FResponseHeaders: TgoHttpHeaders;
    FResponseStatusCode: Integer;
    FResponseContentType: String;
    FResponseContentCharset: String;
    FResponse: TBytes;
    FResponseBytes: Integer;
    FChunkSize: Integer;

    { ngHttp2 }
    {$IFDEF HTTP2}
    FStreamId2: Integer;
    FResponseHeader2: Boolean;
    FResponseContent2: Boolean;
    FCallbacks_http2: pnghttp2_session_callbacks;
    FSession_http2: pnghttp2_session;
    {$ENDIF}
  private
    { ngHttp2 callbacks }
    {$IFDEF HTTP2}
    function nghttp2_data_source_read_callback(session: pnghttp2_session;
      stream_id: int32; buf: puint8; len: size_t; data_flags: puint32;
      source: pnghttp2_data_source; user_data: Pointer): ssize_t; cdecl;
    function nghttp2_on_data_chunk_recv_callback(session: pnghttp2_session;
      flags: uint8; stream_id: int32; const data: puint8; len: size_t;
      user_data: Pointer): Integer; cdecl;
    function nghttp2_on_frame_recv_callback(session: pnghttp2_session;
      const frame: pnghttp2_frame; user_data: Pointer): Integer; cdecl;
    function nghttp2_on_header_callback(session: pnghttp2_session;
      const frame: pnghttp2_frame; const name: puint8; namelen: size_t;
      const value: puint8; valuelen: size_t; flags: uint8;
      user_data: Pointer): Integer; cdecl;
    function nghttp2_on_stream_close_callback(session: pnghttp2_session;
      stream_id: int32; error_code: uint32; user_data: Pointer): Integer; cdecl;
    function nghttp2_Send: Boolean;
    function nghttp2_Recv: Boolean;
    {$ENDIF}
  protected
    FOnPassword: TOnPassword;
    FOnRedirect: TOnRedirect;
    FOnSent: TOnSent;
    FOnRecv: TOnRecv;
    procedure SetCookies(const AValue: TStrings);
    function GetIdleTime: Integer;
  private
    function GetCookies: TStrings;
  private
    procedure Reset;
    procedure CreateRequest;
    function SendRequest: Boolean;
    function ResponseHeader: Boolean;
    function ResponseContent: Boolean;
    function WaitForRecv: Boolean;
    function DoResponse(var AAgain: Boolean): TBytes;
    function DoRequest(const AMethod, AURL: String;
      out AResponse: TBytes; const AConnectTimeout, ARecvTimeout: Integer): Boolean;
  protected
    { Socket routines }
    procedure OnSocketConnected;
    procedure OnSocketDisconnected;
    procedure OnSocketSent(const ABuffer: Pointer; const ASize: Integer);
    procedure OnSocketRecv(const ABuffer: Pointer; const ASize: Integer);
  protected
    procedure DoRecv(const ABuffer: Pointer; const ASize: Integer);
  public
    constructor Create(const AHttp2: Boolean = False; const ABlocking: Boolean = True);
    destructor Destroy; override;
  public
    { Get method }
    function Get(const AURL: String; out AResponse: TBytes;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Get(const AURL: String; out AResponse: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Get(const AURL: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): String; overload;

    { Head method }
    function Head(const AURL: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean;

    { Post method }
    function Post(const AURL: String; out AResponse: TBytes;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Post(const AURL: String; out AResponse: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Post(const AURL: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): String; overload;

    { Put method }
    function Put(const AURL: String; out AResponse: TBytes;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Put(const AURL: String; out AResponse: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Put(const AURL: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): String; overload;

    { Delete method }
    function Delete(const AURL: String; out AResponse: TBytes;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Delete(const AURL: String; out AResponse: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Delete(const AURL: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): String; overload;

    { Options method }
    function Options(const AURL: String; out AResponse: TBytes;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Options(const AURL: String; out AResponse: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): Boolean; overload;
    function Options(const AURL: String;
      const AConnectTimeout: Integer = TIMEOUT_CONNECT;
      const ARecvTimeout: Integer = TIMEOUT_RECV): String; overload;

    { Close connection }
    procedure Close;

    { Convert bytes to string }
    function BytesToString(const ABytes: TBytes; const ACharset: String): String;
  public
    { State }
    property State: TgoHttpClientState read FState;

    { Idle time in milliseconds }
    property IdleTime: Integer read GetIdleTime;

    { Cookies sent to the server and received from the server }
    property Cookies: TStrings read GetCookies write SetCookies;

    { Optional body for a request.
      You can either use RequestBody or RequestData. If both are specified then
      only RequestBody is used. }
    property RequestBody: String read FRequestBody write FRequestBody;

    { Optional binary body data for a request.
      You can either use RequestBody or RequestData. If both are specified then
      only RequestBody is used. }
    property RequestData: TBytes read FRequestData write FRequestData;

    { Request headers }
    property RequestHeaders: TgoHttpHeaders read FRequestHeaders;

    { Response headers from the server }
    property ResponseHeaders: TgoHttpHeaders read FResponseHeaders;

    { Response status code }
    property ResponseStatusCode: Integer read FResponseStatusCode;

    { Response content type }
    property ResponseContentType: String read FResponseContentType;

    { Response charset }
    property ResponseContentCharset: String read FResponseContentCharset;

    { Response content length }
    property ContentLength: Int64 read FContentLength;

    { Allow 301 and other redirects }
    property FollowRedirects: Boolean read FFollowRedirects write FFollowRedirects;

    { Called when a redirect is requested }
    property OnRedirect: TOnRedirect read FOnRedirect write FOnRedirect;

    { Called when a password is needed }
    property OnPassword: TOnPassword read FOnPassword write FOnPassword;

    { Called when a buffer is received from the socket }
    property OnRecv: TOnRecv read FOnRecv write FOnRecv;

    { Called when the data has been sent by the socket }
    property OnSent: TOnSent read FOnSent write FOnSent;

    { Username and password for Basic Authentication }
    property UserName: String read FUserName write FUserName;
    property Password: String read FPassword write FPassword;

    { Content type }
    property ContentType: String read FContentType write FContentType;

    { User agent }
    property UserAgent: String read FUserAgent write FUserAgent;

    { Range }
    property Range: String read FRange write FRange;

    { Authorization }
    property Authorization: String read FAuthorization write FAuthorization;

    { Certificate in PEM format }
    property Certificate: TBytes read FCertificate write FCertificate;

    { Private key in PEM format }
    property PrivateKey: TBytes read FPrivateKey write FPrivateKey;
  end;

  { Http response message }
  TgoHttpResponseMessage = class(TMessage)
  private
    FHttpClient: TgoHttpClient;
    FResponseHeaders: TgoHttpHeaders;
    FResponseStatusCode: Integer;
    FResponseContentType: String;
    FResponseContentCharset: String;
    FResponse: TBytes;
  public
    constructor Create(
      const AHttpClient: TgoHttpClient;
      const AResponseHeaders: TgoHttpHeaders;
      const AResponseStatusCode: Integer;
      const AResponseContentType: String;
      const AResponseContentCharset: String;
      const AResponse: TBytes);
  public
    property HttpClient: TgoHttpClient read FHttpClient;
    property ResponseHeaders: TgoHttpHeaders read FResponseHeaders;
    property ResponseStatusCode: Integer read FResponseStatusCode;
    property ResponseContentType: String read FResponseContentType;
    property ResponseContentCharset: String read FResponseContentCharset;
    property Response: TBytes read FResponse;
  end;

  { Http client manager }
  TgoHttpClientManager = class(TThread)
  private
    FHttpClients: TList<TgoHttpClient>;
    FLock: TCriticalSection;
    procedure FreeClients(const AForce: Boolean = False);
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
  public
    { Queues the http client for release }
    procedure Release(const AHttpClient: TgoHttpClient);
  end;

var
  HttpClientManager: TgoHttpClientManager;

implementation

uses
  Grijjy.SysUtils;

var
  _HttpClientSocketManager: TgoClientSocketManager;

{ ngHttp2 callback cdecl }

{$IFDEF HTTP2}
function data_source_read_callback(session: pnghttp2_session;
  stream_id: int32; buf: puint8; len: size_t; data_flags: puint32;
  source: pnghttp2_data_source; user_data: Pointer): ssize_t; cdecl;
var
  Http: TgoHttpClient;
begin
  Assert(Assigned(user_data));
  Http := TgoHttpClient(user_data);
  Result := Http.nghttp2_data_source_read_callback(session, stream_id, buf, len, data_flags, source, user_data);
end;

function on_header_callback(session: pnghttp2_session; const frame: pnghttp2_frame;
  const name: puint8; namelen: size_t; const value: puint8; valuelen: size_t;
  flags: uint8; user_data: Pointer): Integer; cdecl;
var
  Http: TgoHttpClient;
begin
  Assert(Assigned(user_data));
  Http := TgoHttpClient(user_data);
  Result := Http.nghttp2_on_header_callback(session, frame, name, namelen, value, valuelen, flags, user_data);
end;

function on_frame_recv_callback(session: pnghttp2_session;
  const frame: pnghttp2_frame; user_data: Pointer): Integer; cdecl;
var
  Http: TgoHttpClient;
begin
  Assert(Assigned(user_data));
  Http := TgoHttpClient(user_data);
  Result := Http.nghttp2_on_frame_recv_callback(session, frame, user_data);
end;

function on_data_chunk_recv_callback(session: pnghttp2_session;
  flags: uint8; stream_id: int32; const data: puint8; len: size_t;
  user_data: Pointer): Integer; cdecl;
var
  Http: TgoHttpClient;
begin
  Assert(Assigned(user_data));
  Http := TgoHttpClient(user_data);
  Result := Http.nghttp2_on_data_chunk_recv_callback(session, flags, stream_id, data, len, user_data);
end;

function on_stream_close_callback(session: pnghttp2_session;
  stream_id: int32; error_code: uint32; user_data: Pointer): Integer; cdecl;
var
  Http: TgoHttpClient;
begin
  Assert(Assigned(user_data));
  Http := TgoHttpClient(user_data);
  Result := Http.nghttp2_on_stream_close_callback(session, stream_id, error_code, user_data);
end;
{$ENDIF}

{ TThreadSafeBuffer }

constructor TThreadSafeBuffer.Create(const ACapacity: Integer);
begin
  SetLength(FBuffer, ACapacity);
  FSize := 0;
  FLock := TCriticalSection.Create;
end;

destructor TThreadSafeBuffer.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TThreadSafeBuffer.GetSize: Integer;
begin
  FLock.Enter;
  try
    Result := FSize;
  finally
    FLock.Leave;
  end;
end;

procedure TThreadSafeBuffer.Write(const ABuffer: Pointer; const ASize: Integer);
begin
  FLock.Enter;
  try
    { expand buffer }
    if FSize + ASize >= Length(FBuffer) then
      SetLength(FBuffer, (FSize + ASize) * 2);

    { append bytes }
    Move(ABuffer^, FBuffer[FSize], ASize);
    FSize := FSize + ASize;
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeBuffer.Read(out ABytes: TBytes): Boolean;
begin
  FLock.Enter;
  try
    if FSize > 0 then
    begin
      { read bytes into new buffer }
      SetLength(ABytes, FSize);
      Move(FBuffer[0], ABytes[0], FSize);

      { clear buffer }
      FSize := 0;
      Result := True;
    end
    else
      Result := False;
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeBuffer.Read(out ABytes: TBytes; const ACount: Integer): Boolean;
var
  Size: Integer;
begin
  FLock.Enter;
  try
    if FSize > 0 then
    begin
      { read bytes into new buffer }
      if FSize >= ACount then
        Size := ACount
      else
        Size := FSize;
      SetLength(ABytes, Size);
      Move(FBuffer[0], ABytes[0], Size);

      { delete buffer }
      if FSize > Size then
      begin
        Move(FBuffer[Size], FBuffer[0], FSize - Size);
        FSize := FSize - Size;
      end
      else
        FSize := 0;

      Result := True;
    end
    else
      Result := False;
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeBuffer.Read(const ABuffer: Pointer;
  var ALength: NativeInt): Boolean;
begin
  FLock.Enter;
  try
    if FSize > 0 then
    begin
      { read bytes into existing buffer }
      if FSize < ALength then
        ALength := FSize;
      Move(FBuffer[0], ABuffer^, ALength);

      { delete buffer }
      if FSize > ALength then
      begin
        Move(FBuffer[Size], FBuffer[0], FSize - ALength);
        FSize := FSize - ALength;
      end
      else
        FSize := 0;

      Result := True;
    end
    else
      Result := False;
  finally
    FLock.Leave;
  end;
end;

function TThreadSafeBuffer.ReadTo(const ASubStr: RawByteString; out ABytes: TBytes): Boolean;
var
  Size, Index: Integer;
begin
  Result := False;
  Size := Length(ASubStr);
  FLock.Enter;
  try
    if FSize > Size then
      for Index := 0 to FSize - Size do
        if CompareMem(@FBuffer[Index], @ASubStr[1], Size) then
        begin
          { read bytes into new buffer }
          SetLength(ABytes, Index + Size);
          Move(FBuffer[0], ABytes[0], Index + Size);

          { delete buffer }
          if FSize > (Index + Size) then
          begin
            Move(FBuffer[Index + Size], FBuffer[0], FSize - (Index + Size));
            FSize := FSize - (Index + Size);
          end
          else
            FSize := 0;

          Result := True;
          Break;
        end;
  finally
    FLock.Leave;
  end;
end;

procedure TThreadSafeBuffer.Clear;
begin
  FLock.Enter;
  try
    FSize := 0;
  finally
    FLock.Leave;
  end;
end;

{$IFDEF LOGGING}
procedure TThreadSafeBuffer.Log(const AText: String);
begin
  //grLog(Format('RecvBuffer %s (Size=%d)', [AText, FSize]), @FBuffer[0], FSize);
end;
{$ENDIF}

{ THttpHeaders }

constructor TgoHttpHeaders.Create;
begin
end;

destructor TgoHttpHeaders.Destroy;
begin
  FHeaders := nil;
  inherited;
end;

procedure TgoHttpHeaders.AddOrSet(const AName, AValue: String);
var
  Index: Integer;
  Header: TgoHttpHeader;
begin
  Index := IndexOf(AName);
  if Index = -1 then
  begin
    Header.Name := AName;
    Header.Value := AValue;
    {$IFDEF HTTP2}
    Header.NameAsISO8859 := ISO8859String(AName);
    Header.ValueAsISO8859 := ISO8859String(AValue);
    {$ENDIF}
    FHeaders := FHeaders + [Header];
  end
  else
  begin
    FHeaders[Index].Name := AName;
    FHeaders[Index].Value := AValue;
    {$IFDEF HTTP2}
    FHeaders[Index].NameAsISO8859 := ISO8859String(AName);
    FHeaders[Index].ValueAsISO8859 := ISO8859String(AValue);
    {$ENDIF}
  end;
end;

procedure TgoHttpHeaders.AddOrSet(const AHeader: String);
var
  Index: Integer;
  Name: String;
  Value: String;
begin
  Index := AHeader.IndexOf(':');
  if Index > -1 then
  begin
    Name := AHeader.Substring(0, Index);
    Value := AHeader.Substring(Index + 1);
    AddOrSet(Name, Value);
  end;
end;

function TgoHttpHeaders.Value(const AName: String): String;
var
  Header: TgoHttpHeader;
begin
  Result := '';
  for Header in FHeaders do
    if Header.Name.ToLower = AName.ToLower then
    begin
      Result := String(Header.Value).TrimLeft;
      Break;
    end;
end;

function TgoHttpHeaders.IndexOf(const AName: String): Integer;
var
  Index: Integer;
begin
  Result := -1;
  for Index := 0 to Length(FHeaders) - 1 do
    if FHeaders[Index].Name.ToLower = AName.ToLower then
    begin
      Result := Index;
      Break;
    end;
end;

function TgoHttpHeaders.AsString: String;
var
  Header: TgoHttpHeader;
begin
  for Header in FHeaders do
    Result := Result + Header.Name + ': ' + Header.Value + CRLF;
end;

{$IFDEF HTTP2}
procedure TgoHttpHeaders.AsNgHttp2Array(var AHeaders: TArray<nghttp2_nv>);
var
  Header: TgoHttpHeader;
  NgHttp2Header: nghttp2_nv;
begin
  for Header in FHeaders do
  begin
    NgHttp2Header.name := MarshaledAString(Header.NameAsISO8859);
    NgHttp2Header.value := MarshaledAString(Header.ValueAsISO8859);
    NgHttp2Header.namelen := Length(Header.Name);
    NgHttp2Header.valuelen := Length(Header.Value);
    NgHttp2Header.flags := NGHTTP2_NV_FLAG_NONE;
    AHeaders := AHeaders + [NgHttp2Header];
  end;
end;
{$ENDIF}

{ TgoHttpResponseMessage }

constructor TgoHttpResponseMessage.Create(const AHttpClient: TgoHttpClient;
  const AResponseHeaders: TgoHttpHeaders;
  const AResponseStatusCode: Integer;
  const AResponseContentType, AResponseContentCharset: String;
  const AResponse: TBytes);
begin
  inherited Create;
  FHttpClient := AHttpClient;
  FResponseHeaders := AResponseHeaders;
  FResponseStatusCode := AResponseStatusCode;
  FResponseContentType := AResponseContentType;
  FResponseContentCharset := AResponseContentCharset;
  FResponse := AResponse;
end;

{ TgoHttpClientManager }

constructor TgoHttpClientManager.Create;
begin
  inherited Create;
  FHttpClients := TList<TgoHttpClient>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TgoHttpClientManager.Destroy;
begin
  FreeClients(True);
  FLock.Free;
  FHttpClients.Free;
  inherited;
end;

procedure TgoHttpClientManager.FreeClients(const AForce: Boolean);
var
  HttpClient: TgoHttpClient;
  HttpClients: TArray<TgoHttpClient>;
  ClientsToFree: TArray<TgoHttpClient>;
begin
  FLock.Enter;
  try
    HttpClients := FHttpClients.ToArray;
    for HttpClient in HttpClients do
    begin
      if (AForce) or
        (HttpClient.IdleTime > HttpClient.FRecvTimeout) then
        if (HttpClient.State = TgoHttpClientState.Sending) or
          (HttpClient.State = TgoHttpClientState.Receiving) then
          HttpClient.Close;
      if (AForce) or
        (HttpClient.IdleTime > HttpClient.FRecvTimeout) or
        (HttpClient.State = TgoHttpClientState.Finished) or
        (HttpClient.State = TgoHttpClientState.Error) or
        (HttpClient.State = TgoHttpClientState.None) then
      begin
        ClientsToFree := ClientsToFree + [HttpClient];
        FHttpClients.Remove(HttpClient);
      end;
    end;
  finally
    FLock.Leave;
  end;
  for HttpClient in ClientsToFree do
    HttpClient.DisposeOf;
end;

procedure TgoHttpClientManager.Execute;
var
  LastCleanup: TDateTime;
begin
  LastCleanup := Now;
  while not Terminated do
  begin
    if MillisecondsBetween(Now, LastCleanup) > INTERVAL_CLEANUP then
    begin
      FreeClients;
      LastCleanup := Now;
    end
    else
      Sleep(5); { waiting for interval }
  end;
end;

procedure TgoHttpClientManager.Release(const AHttpClient: TgoHttpClient);
begin
  FLock.Enter;
  try
    FHttpClients.Add(AHttpClient);
  finally
    FLock.Leave;
  end;
end;

{ TgoHttpClient }

constructor TgoHttpClient.Create(const AHttp2: Boolean = False; const ABlocking: Boolean = True);
{$IFDEF HTTP2}
var
  Settings: nghttp2_settings_entry;
  Error: Integer;
{$ENDIF}
begin
  inherited Create;

  { initialize nghttp2 library }
  {$IFDEF HTTP2}
  if nghttp2_session_callbacks_new(FCallbacks_http2) = 0 then
  begin
    nghttp2_session_callbacks_set_on_header_callback(FCallbacks_http2, on_header_callback);
    nghttp2_session_callbacks_set_on_frame_recv_callback(FCallbacks_http2, on_frame_recv_callback);
    nghttp2_session_callbacks_set_on_data_chunk_recv_callback(FCallbacks_http2, on_data_chunk_recv_callback);
    nghttp2_session_callbacks_set_on_stream_close_callback(FCallbacks_http2, on_stream_close_callback);
    if (nghttp2_session_client_new(FSession_http2, FCallbacks_http2, Self) = 0) then
    begin
      Settings.settings_id := NGHTTP2_SETTINGS_MAX_CONCURRENT_STREAMS;
      Settings.value := 100;
      Error := nghttp2_submit_settings(FSession_http2, NGHTTP2_FLAG_NONE, @Settings, 1);
      if (Error <> 0) then
        raise Exception.Create('Unable to  submit ngHttp2 settings');
    end
    else
      raise Exception.Create('Unable to setup ngHttp2 session.');
  end
  else
    raise Exception.Create('Unable to setup ngHttp2 callbacks.');
  FHttp2 := AHttp2;
  {$ENDIF}

  FState := TgoHttpClientState.None;
  FBlocking := ABlocking;
  FHttpVersion := '1.1';
  FAuthorization := '';
  FContentType := '';
  FUserAgent := '';
  FRange := '';
  FConnection := nil;
  FConnectionLock := TCriticalSection.Create;
  FConnected := TEvent.Create(nil, False, False, '');
  FFollowRedirects := True;
  FSendBuffer := TThreadSafeBuffer.Create;
  FRecvBuffer := TThreadSafeBuffer.Create;
  FRecvBuffer2 := TThreadSafeBuffer.Create;
  FRecv := TEvent.Create(nil, False, False, '');
  FRequestHeaders := TgoHttpHeaders.Create;
  FInternalHeaders := TgoHttpHeaders.Create;
  FResponseHeaders := TgoHttpHeaders.Create;
end;

destructor TgoHttpClient.Destroy;
var
  Connection: TgoSocketConnection;
begin
  {$IFDEF HTTP2}
  nghttp2_session_callbacks_del(FCallbacks_http2);
  nghttp2_session_terminate_session(FSession_http2, NGHTTP2_NO_ERROR);
  {$ENDIF}
  FConnectionLock.Enter;
  try
    Connection := FConnection;
    FConnection := nil;
  finally
    FConnectionLock.Leave;
  end;
  if Connection <> nil then
    _HttpClientSocketManager.Release(Connection);
  FreeAndNil(FRequestHeaders);
  FreeAndNil(FInternalHeaders);
  FreeAndNil(FResponseHeaders);
  FreeAndNil(FCookies);
  FreeAndNil(FSentCookies);
  FConnected.Free;
  FConnectionLock.Free;
  FSendBuffer.Free;
  FRecvBuffer2.Free;
  FRecvBuffer.Free;
  FRecv.Free;
  inherited Destroy;
end;

{$IFDEF HTTP2}
function TgoHttpClient.nghttp2_data_source_read_callback(session: pnghttp2_session;
  stream_id: int32; buf: puint8; len: size_t; data_flags: puint32;
  source: pnghttp2_data_source; user_data: Pointer): ssize_t;
begin
  // Note: if you want request specific data you can use the API nghttp2_session_get_stream_user_data(session, stream_id);
  if NativeUInt(FSendBuffer.Size) <= len then
  begin
    Result := FSendBuffer.Size;
    FSendBuffer.Read(Buf, Result);
    data_flags^ := data_flags^ or NGHTTP2_DATA_FLAG_EOF;
  end
  else
  begin
    Result := len;
    FSendBuffer.Read(Buf, Result);
  end;
end;

function TgoHttpClient.nghttp2_on_header_callback(session: pnghttp2_session; const frame: pnghttp2_frame;
  const name: puint8; namelen: size_t; const value: puint8; valuelen: size_t;
  flags: uint8; user_data: Pointer): Integer;
var
  AName, AValue: String;
  Index: Integer;
begin
  {$IFDEF LOGGING}
  //grLog('on_header_callback');
  {$ENDIF}
  if frame.hd.&type = _NGHTTP2_HEADERS then
    if (frame.headers.cat = NGHTTP2_HCAT_RESPONSE) then
    begin
      AName := TEncoding.ASCII.GetString(BytesOf(name, namelen));
      AValue := TEncoding.ASCII.GetString(BytesOf(value, valuelen));
      FResponseHeaders.AddOrSet(AName, AValue);
      {$IFDEF LOGGING}
      //grLog(AName, AValue);
      {$ENDIF}

      { response status code }
      if AName = ':status' then
        FResponseStatusCode := StrToInt64Def(AValue, -1);

      { content type }
      if AName = 'content-type' then
      begin
        FResponseContentType := AValue;

        { charset }
        Index := FResponseContentType.IndexOf(S_CHARSET + '=');
        if Index >= 0 then
          FResponseContentCharset := FResponseContentType.Substring(Index + Length(S_CHARSET) + 1, Length(FResponseContentType) - Index - Length(S_CHARSET)).ToLower;
      end;

      { content length }
      if AName = 'content-length' then
        FContentLength := StrToInt64Def(AValue, -1);
    end;
  Result := 0;
end;

function TgoHttpClient.nghttp2_on_frame_recv_callback(session: pnghttp2_session;
  const frame: pnghttp2_frame; user_data: Pointer): Integer;
begin
  {$IFDEF LOGGING}
  //grLog('on_frame_recv_callback');
  {$ENDIF}
  if frame.hd.&type = _NGHTTP2_HEADERS then
    if (frame.headers.cat = NGHTTP2_HCAT_RESPONSE) then
    begin
      // all headers received
      {$IFDEF LOGGING}
      //grLog('All headers received');
      {$ENDIF}
      FResponseHeader2 := True;
    end;
  Result := 0;
end;

function TgoHttpClient.nghttp2_on_data_chunk_recv_callback(session: pnghttp2_session;
  flags: uint8; stream_id: int32; const data: puint8; len: size_t;
  user_data: Pointer): Integer;
begin
  if stream_id = FStreamId2 then
  begin
    {$IFDEF LOGGING}
    //grLog('on_data_chunk_recv_callback ' + stream_id.ToString, data, len);
    {$ENDIF}
    // response chunk
    FRecvBuffer2.Write(data, len);
  end;
  Result := 0;
end;

function TgoHttpClient.nghttp2_on_stream_close_callback(session: pnghttp2_session;
  stream_id: int32; error_code: uint32; user_data: Pointer): Integer;
begin
  if stream_id = FStreamId2 then
  begin
    {$IFDEF LOGGING}
    //grLog('on_stream_close_callback ' + stream_id.ToString);
    {$ENDIF}
    FResponseContent2 := True;
  end;
  Result := 0;
  { Note : connection is still open at this point unless you call
    nghttp2_session_terminate_session(session, NGHTTP2_NO_ERROR) }
end;

function TgoHttpClient.nghttp2_Send: Boolean;
var
  data: Pointer;
  len: Integer;
  Bytes: TBytes;
begin
  Result := False;
  while nghttp2_session_want_write(FSession_http2) > 0 do
  begin
    len := nghttp2_session_mem_send(FSession_http2, data);
    if len > 0 then
    begin
      SetLength(Bytes, len);
      Move(data^, Bytes[0], len);
      Result := FConnection.Send(Bytes);
    end;
  end;
end;

function TgoHttpClient.nghttp2_Recv: Boolean;
var
  Bytes: TBytes;
begin
  Result := FRecvBuffer.Read(Bytes);
  if Result then
    nghttp2_session_mem_recv(FSession_http2, @Bytes[0], Length(Bytes));
end;
{$ENDIF}


function TgoHttpClient.GetIdleTime: Integer;
begin
  Result := MillisecondsBetween(Now, FLastRecv);
end;

procedure TgoHttpClient.Close;
begin
  FRecvAbort := True;
  FRecv.SetEvent;
  if FConnection <> nil then
    FConnection.Disconnect;
end;

{ Cookies received from the server }
function TgoHttpClient.GetCookies: TStrings;
begin
  if FCookies = nil then
    FCookies := TStringList.Create;
  Result := FCookies;
end;
{ Cookies sent to the server }
procedure TgoHttpClient.SetCookies(const AValue: TStrings);
begin
  if GetCookies = AValue then
    Exit;
  GetCookies.Assign(AValue);
end;

procedure TgoHttpClient.Reset;
begin
  FLastRecv := Now;
  FInternalHeaders.Headers := nil;
  FRequestStatusLine := '';
  FResponseStatusCode := 0;
  FResponseHeaders.Headers := nil;
  FResponseHeader := False;
  FChunkSize := -1;
  FRecvAbort := False;
  FResponse := nil;
  FResponseBytes := 0;
  FResponseHeaders.Headers := nil;
  {$IFDEF HTTP2}
  FResponseHeader2 := False;
  FResponseContent2 := False;
  {$ENDIF}
end;

procedure TgoHttpClient.CreateRequest;
var
  _Username: String;
  _Password: String;
  Cookies: String;
  Path: String;
  Index: Integer;
begin
  { parse the URL into a URI }
  FURI := TURI.Create(FURL);

  { http or https }
  if (FURI.Port = 0) then
  begin
    if FURI.Scheme.ToLower = 'https' then
      FURI.Port := DEFAULT_HTTPS_PORT
    else
      FURI.Port := DEFAULT_HTTP_PORT;
  end;

  { use credentials in URI, if provided }
  _Username := FURI.Username;
  _Password := FURI.Password;
  if (_Username = '') then
  begin
    { credentials provided? }
    _Username := FUserName;
    _Password := FPassword;
  end;

  {$IFDEF HTTP2}
  if FHttp2 then
  begin
    { add method }
    FInternalHeaders.AddOrSet(':method', FMethod.ToUpper);

    { add scheme }
    FInternalHeaders.AddOrSet(':scheme', FURI.Scheme.ToLower);

    { add path }
    FInternalHeaders.AddOrSet(':path', FURI.Path);

    { add host }
    FInternalHeaders.AddOrSet('host', FURI.Host);

    { add authorization }
    if (_Username <> '') then
    begin
      { basic authentication }
      FInternalHeaders.AddOrSet('authorization', 'Basic ' +
        TEncoding.Utf8.GetString(goBase64Encode(TEncoding.Utf8.GetBytes(_Username + ':' + _Password))));
    end
    else
      if (FAuthorization <> '') then
        FInternalHeaders.AddOrSet('authorization', FAuthorization);
  end
  else
  {$ENDIF}
  begin
    { add header status line }
    Path := FURI.Path;
    if Length(FURI.Params) > 0 then
      Path := Path + '?' + FURI.Query;
    FRequestStatusLine := FMethod.ToUpper + ' ' + Path + ' ' + 'HTTP/' + FHttpVersion;

    { add host }
    FInternalHeaders.AddOrSet('Host', FURI.Host);

    { add user-agent }
    if (FUserAgent <> '') then
      FInternalHeaders.AddOrSet('User-Agent', FUserAgent);

    { range request }
    if (FRange <> '') then
      FInternalHeaders.AddOrSet('Range', FRange);

    { add content type }
    if (FContentType <> '') then
      FInternalHeaders.AddOrSet('Content-Type', FContentType);

    { add content length }
    if (FRequestBody <> '') then
      FInternalHeaders.AddOrSet('Content-Length', Length(FRequestBody).ToString)
    else
    if (FRequestData <> nil) then
      FInternalHeaders.AddOrSet('Content-Length', Length(FRequestData).ToString)
    else
      FInternalHeaders.AddOrSet('Content-Length', '0');

    { add authorization }
    if (_Username <> '') then
    begin
      { add basic authentication }
      FInternalHeaders.AddOrSet('Authorization', 'Basic ' +
        TEncoding.Utf8.GetString(goBase64Encode(TEncoding.Utf8.GetBytes(_Username + ':' + _Password))));
    end
    else
      if (FAuthorization <> '') then
        FInternalHeaders.AddOrSet('Authorization', FAuthorization);

    { add cookies, if any }
    if Assigned(FCookies) then
    begin
      Cookies := '';
      for Index := 0 to FCookies.Count-1 do
      begin
        if Index > 0 then
          Cookies := Cookies + '; ';
        Cookies := Cookies + FCookies[Index];
      end;
      FInternalHeaders.AddOrSet('Cookie', Cookies);
    end;
    FreeAndNil(FSentCookies);
    FSentCookies := FCookies;
    FCookies := nil;
  end;
end;

function TgoHttpClient.SendRequest: Boolean;
var
  Headers: String;
  {$IFDEF HTTP2}
  DataProvider: nghttp2_data_provider;
  Data: TBytes;
  FHeaders2: TArray<nghttp2_nv>;
  {$ENDIF}
begin
  {$IFDEF LOGGING}
  //grLog('SendRequest Thread', GetCurrentThreadId);
  {$ENDIF}
  Result := False;
//  FConnectionLock.Enter;
  try
    if (FConnection <> nil) then
    begin
      {$IFDEF HTTP2}
      if FHttp2 then
      begin
        { setup data callback }
        DataProvider.source.ptr := nil;
        DataProvider.read_callback := data_source_read_callback;

        { create nghttp2 compatible headers }
        FInternalHeaders.AsNgHttp2Array(FHeaders2);
        FRequestHeaders.AsNgHttp2Array(FHeaders2);

        { prepare send buffer for request body }
        if (FRequestBody <> '') then
          Data := TEncoding.Utf8.GetBytes(FRequestBody)
        else
          Data := FRequestData;
        FSendBuffer.Write(@Data[0], Length(Data));

        { submit request }
        FStreamId2 := nghttp2_submit_request(FSession_http2, Nil, @FHeaders2[0], Length(FHeaders2), @DataProvider, Self);
        if FStreamId2 >= 0 then
          Result := nghttp2_Send;
      end
      else
      {$ENDIF}
      begin
        Headers :=
          FRequestStatusLine + CRLF +
          FInternalHeaders.AsString +
          FRequestHeaders.AsString + CRLF;
        {$IFDEF LOGGING}
        //grLog('RequestHeader', TEncoding.ASCII.GetBytes(Headers));
        {$ENDIF}
        if (FRequestBody <> '') then
          Result := FConnection.Send(TEncoding.ASCII.GetBytes(Headers) + TEncoding.Utf8.GetBytes(FRequestBody))
        else
          Result := FConnection.Send(TEncoding.ASCII.GetBytes(Headers) + FRequestData);
      end;
    end;
  finally
//    FConnectionLock.Leave;
  end;
end;

function TgoHttpClient.WaitForRecv: Boolean;
begin
  {$IFDEF LOGGING}
  //grLog('WaitForRecv Thread', GetCurrentThreadId);
  {$ENDIF}
  Result := False;
  FLastRecv := Now;
  while ((FRecv.WaitFor(FRecvTimeout) <> wrTimeout) and (not FRecvAbort)) do
    if ResponseHeader and ResponseContent then
    begin
      Result := True;
      Break;
    end;
  {$IFDEF LOGGING}
  //grLog('WaitForRecv ', Result);
  {$ENDIF}
end;

function TgoHttpClient.DoResponse(var AAgain: Boolean): TBytes;
var
  Location: String;
begin
  Result := FResponse;
  case FResponseStatusCode of
    301,
    302,
    303,
    307,
    308,
    808: { redirect? }
    begin
      if FFollowRedirects then
      begin
        Location := FResponseHeaders.Value('Location');
        try
          if not Assigned(FOnRedirect) then
          begin
            FURL := Location;
            AAgain := True;
          end
          else
          begin
            AAgain := True;
            FOnRedirect(Self, Location, AAgain);
            if AAgain then
              FURL := Location;
          end;
          if (FResponseStatusCode = 303) then
            FMethod := 'GET';
        finally
          FreeAndNil(FCookies);
          FCookies := FSentCookies;
          FSentCookies := nil;
        end;
      end;
    end;

    401: { password required? }
    begin
      if Assigned(FOnPassword) then
        FOnPassword(Self, AAgain);
    end;
  end;
end;

function TgoHttpClient.DoRequest(const AMethod, AURL: String;
  out AResponse: TBytes; const AConnectTimeout, ARecvTimeout: Integer): Boolean;
var
  Again: Boolean;

  function Connect: Boolean;
  begin
    {$IFDEF LOGGING}
    //grLog('ConnectToUrl', AUrl);
    {$ENDIF}
    FConnectionLock.Enter;
    try
      if (FConnection <> nil) and
        ((FURI.Scheme.ToLower <> FLastURI.Scheme) or
        (FURI.Host <> FLastURI.Host ) or
        (FURI.Port <> FLastURI.Port)) then
      begin
        _HttpClientSocketManager.Release(FConnection);
        FConnection := nil;
      end;
      if FConnection = nil then
      begin
        FConnection := _HttpClientSocketManager.Request(FURI.Host, FURI.Port);
        FConnection.OnConnected := OnSocketConnected;
        FConnection.OnDisconnected := OnSocketDisconnected;
        FConnection.OnSent := OnSocketSent;
        FConnection.OnRecv := OnSocketRecv;
        if FURI.Scheme.ToLower = 'https' then
        begin
          FConnection.SSL := True;
          {$IFDEF HTTP2}
          FConnection.ALPN := FHttp2;
          {$ENDIF}
          if FCertificate <> nil then
            FConnection.Certificate := FCertificate;
          if FPrivateKey <> nil then
            FConnection.PrivateKey := FPrivateKey;
        end
        else
          FConnection.SSL := False;
      end;
      Result := FConnection.State = TgoConnectionState.Connected;
      if not Result then
      begin
        {$IFDEF LOGGING}
        //grLog('Connecting');
        {$ENDIF}
        if FConnection.Connect then
          Result := FConnected.WaitFor(FConnectTimeout) <> wrTimeout;
        {$IFDEF LOGGING}
        //grLog('Connected', Result);
        {$ENDIF}
      end;
    finally
      FConnectionLock.Leave;
    end;
  end;

begin
  FState := TgoHttpClientState.None;
  Result := False;
  FURL := AURL;
  FMethod := AMethod;
  FConnectTimeout := AConnectTimeout;
  FRecvTimeout := ARecvTimeout;
  repeat
    AResponse := nil;
    Again := False;
    Reset;
    CreateRequest;
    FState := TgoHttpClientState.Sending;
    if Connect then
    begin
      if SendRequest then
      begin
        FState := TgoHttpClientState.Receiving;
        if FBlocking then
        begin
          if WaitForRecv then
          begin
            AResponse := DoResponse(Again);
            FState := TgoHttpClientState.Finished;
            Result := True;
          end;
        end
        else
          Result := True;
      end
      else
        FState := TgoHttpClientState.Error;
      FLastURI := FURI;
    end
    else
      FState := TgoHttpClientState.Error;
  until not Again;
  {$IFDEF LOGGING}
  //grLog('ResponseLength', Length(AResponse));
  {$ENDIF}
end;

procedure TgoHttpClient.OnSocketConnected;
begin
  {$IFDEF LOGGING}
  //grLog('OnSocketConnected');
  {$ENDIF}
  FConnected.SetEvent;
end;

procedure TgoHttpClient.OnSocketDisconnected;
begin
  {$IFDEF LOGGING}
  //grLog('OnSocketDisconnected');
  {$ENDIF}
end;

procedure TgoHttpClient.OnSocketSent(const ABuffer: Pointer;
  const ASize: Integer);
begin
  FLastSent := Now;

  if Assigned(FOnSent) then
    FOnSent(Self, ABuffer, ASize);
end;

{ DoRecv is always called with a copy buffer and outside of the main buffer
  lock so that we do not block any socket pooling threads with our own
  worker logic }
procedure TgoHttpClient.DoRecv(const ABuffer: Pointer; const ASize: Integer);
var
  Index: Integer;
  CreateResponse: Boolean;
begin
  {$IFDEF LOGGING}
  //grLog(Format('DoRecv (Size=%d)', [ASize]), ABuffer, ASize);
  {$ENDIF}

  FResponseBytes := FResponseBytes + ASize;
  CreateResponse := True;
  if Assigned(FOnRecv) then
    FOnRecv(Self, ABuffer, ASize, CreateResponse);

  { append response buffer, optional }
  if CreateResponse then
  begin
    Index := Length(FResponse);
    SetLength(FResponse, Length(FResponse) + ASize);
    Move(ABuffer^, FResponse[Index], ASize);
  end;
end;

function TgoHttpClient.ResponseHeader: Boolean;
var
  Bytes: TBytes;

  procedure ParseResponseHeader(const ABytes: TBytes);
  var
    Headers: TStringList;
    Strings: TArray<String>;
    Index: Integer;
  begin
    Headers := TStringList.Create;
    try
      Headers.Text := TEncoding.ASCII.GetString(ABytes, 0, Length(ABytes) - 4); // exclude CRLFCRLF

      if Headers.Count > 0 then
      begin
        { response status code }
        Strings := Headers[0].ToLower.Substring(Headers[0].ToLower.LastIndexOf('http:/')).Split([#32]);
        if Length(Strings) >= 2 then
          FResponseStatusCode := StrToInt64Def(Strings[1], -1)
        else
          FResponseStatusCode := -1;

        { response headers }
        if Headers.Count > 1 then
          for Index := 1 to Headers.Count - 1 do
            FResponseHeaders.AddOrSet(Headers[Index]);

        { content type }
        FResponseContentType := FResponseHeaders.Value(S_CONTENT_TYPE);

        { charset }
        Index := FResponseContentType.IndexOf(S_CHARSET + '=');
        if Index >= 0 then
          FResponseContentCharset := FResponseContentType.Substring(Index + Length(S_CHARSET) + 1, Length(FResponseContentType) - Index - Length(S_CHARSET)).ToLower;

        { content length or transfer encoding? }
        FContentLength := StrToInt64Def(FResponseHeaders.Value(S_CONTENT_LENGTH), -1);
        if FContentLength < 0 then
          { chunked encoding }
          FTransferEncoding := FResponseHeaders.Value(S_TRANSFER_ENCODING);
      end;
    finally
      Headers.Free;
    end;
  end;

begin
  {$IFDEF HTTP2}
  if FHttp2 then
    Result := FResponseHeader2
  else
  {$ENDIF}
  begin
    Result := FResponseHeader;
    if not FResponseHeader then
    begin
      if FRecvBuffer.ReadTo(CRLF + CRLF, Bytes) then
      begin
        ParseResponseHeader(Bytes);
        FResponseHeader := True;
        Result := True;
      end;
    end;
  end;
  {$IFDEF LOGGING}
  //grLog('ResponseHeader', Result);
  {$ENDIF}
end;

function TgoHttpClient.ResponseContent: Boolean;
var
  S: RawByteString;
  Index: Integer;
  Bytes: TBytes;
begin
  if FMethod.ToUpper = 'HEAD' then  // no content expected
    Result := True
  else
  begin
    {$IFDEF HTTP2}
    if FHttp2 then
    begin
      if FRecvBuffer2.Read(Bytes) then
        DoRecv(@Bytes[0], Length(Bytes));
      Result := FResponseContent2;
    end
    else
    {$ENDIF}
    begin
      if FContentLength >= 0 then
      begin
        if FRecvBuffer.Read(Bytes) then
          DoRecv(@Bytes[0], Length(Bytes));
        Result := FResponseBytes >= FContentLength;
      end
      else
      begin
        Result := False;
        { chunked encoding }
        if FTransferEncoding = S_CHUNKED then
        begin
          while True do
          begin
            { calculate expected next chunk size, only once }
            if FChunkSize = -1 then
              if FRecvBuffer.ReadTo(CRLF, Bytes) then
              begin
                SetLength(S, Length(Bytes) - 2);
                Move(Bytes[0], S[1], Length(Bytes) - 2);
                Index := String(S).IndexOf(';'); { skip optional chunk parameters }
                if Index >= 0 then
                  SetLength(S, Index);
                FChunkSize := StrToInt64Def('$' + String(S), -1);
                {$IFDEF LOGGING}
                //grLog('ChunkSize', FChunkSize);
                {$ENDIF}
              end;

            if FChunkSize > 0 then
            begin
              { did we receive the chunk plus all padding bytes? }
              if FRecvBuffer.Size > FChunkSize + 2 then
              begin
                if FRecvBuffer.Read(Bytes, FChunkSize + 2) then
                  DoRecv(@Bytes[0], Length(Bytes) - 2);
                FChunkSize := -1;
              end
              else
                Break; // need more data
            end
            else
            if FChunkSize = 0 then // completed
            begin
              FRecvBuffer.Clear; // ignore chunking tail
              Result := True;
              Break;
            end
            else
              Break; // need more data
          end;
        end;
      end;
    end;
  end;
  {$IFDEF LOGGING}
  //grLog('ResponseContent', Result);
  {$ENDIF}
end;

{ OnSocketRecv can be called by multiple threads from the socket pool in relation
  to the same http request.  These threads are always different from the main
  thread.  This can create issues with FIFO buffer ordering so we write the buffer
  into our main buffer in a thread safe manner, and we do it as quickly as possible. }
procedure TgoHttpClient.OnSocketRecv(const ABuffer: Pointer; const ASize: Integer);
var
  ResponseMessage: TgoHttpResponseMessage;
begin
  {$IFDEF LOGGING}
  //grLog(Format('OnSocketRecv (ThreadId=%d, Size=%d)', [GetCurrentThreadId, ASize]), ABuffer, ASize);
  {$ENDIF}
  FLastRecv := Now;
  FRecvBuffer.Write(ABuffer, ASize);

  { http2 receive }
  {$IFDEF HTTP2}
  if FHttp2 then
    nghttp2_Recv;
  {$ENDIF}

  if FState <> TgoHttpClientState.Finished then
  begin
    if FBlocking then
      FRecv.SetEvent
    else
    begin
      if ResponseHeader and ResponseContent then
      begin
        ResponseMessage := TgoHttpResponseMessage.Create(
          Self,
          FResponseHeaders,
          FResponseStatusCode,
          FResponseContentType,
          FResponseContentCharset,
          FResponse);
        TMessageManager.DefaultManager.SendMessage(Self, ResponseMessage);
        FState := TgoHttpClientState.Finished;
      end;
    end;
  end;
end;

function TgoHttpClient.BytesToString(const ABytes: TBytes; const ACharset: String): String;
begin
  if ACharset = 'iso-8859-1' then
    Result := TEncoding.ANSI.GetString(ABytes)
  else
  if ACharset = 'utf-8' then
    Result := TEncoding.UTF8.GetString(ABytes)
  else
    Result := TEncoding.ANSI.GetString(ABytes)
end;

function TgoHttpClient.Get(const AURL: String; out AResponse: TBytes;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
begin
  Result := DoRequest('GET', AURL, AResponse, AConnectTimeout, ARecvTimeout);
end;

function TgoHttpClient.Get(const AURL: String; out AResponse: String;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
var
  Response: TBytes;
begin
  if Get(AURL, Response, AConnectTimeout, ARecvTimeout) then
  begin
    AResponse := BytesToString(Response, FResponseContentCharset);
    Result := True;
  end
  else
    Result := False;
end;

function TgoHttpClient.Get(const AURL: String; const AConnectTimeout, ARecvTimeout: Integer): String;
var
  Response: TBytes;
begin
  if Get(AURL, Response, AConnectTimeout, ARecvTimeout) then
    Result := BytesToString(Response, FResponseContentCharset);
end;

function TgoHttpClient.Head(const AURL: String; const AConnectTimeout, ARecvTimeout: Integer): Boolean;
var
  AResponse: TBytes;
begin
  Result := DoRequest('HEAD', AURL, AResponse, AConnectTimeout, ARecvTimeout);
end;

function TgoHttpClient.Post(const AURL: String; out AResponse: TBytes;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
begin
  Result := DoRequest('POST', AURL, AResponse, AConnectTimeout, ARecvTimeout);
end;

function TgoHttpClient.Post(const AURL: String; out AResponse: String;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
var
  Response: TBytes;
begin
  if Post(AURL, Response, AConnectTimeout, ARecvTimeout) then
  begin
    AResponse := BytesToString(Response, FResponseContentCharset);
    Result := True;
  end
  else
    Result := False;
end;

function TgoHttpClient.Post(const AURL: String; const AConnectTimeout, ARecvTimeout: Integer): String;
var
  Response: TBytes;
begin
  if Post(AURL, Response, AConnectTimeout, ARecvTimeout) then
    Result := BytesToString(Response, FResponseContentCharset);
end;

function TgoHttpClient.Put(const AURL: String; out AResponse: TBytes;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
begin
  Result := DoRequest('PUT', AURL, AResponse, AConnectTimeout, ARecvTimeout);
end;

function TgoHttpClient.Put(const AURL: String; out AResponse: String;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
var
  Response: TBytes;
begin
  if Put(AURL, Response, AConnectTimeout, ARecvTimeout) then
  begin
    AResponse := BytesToString(Response, FResponseContentCharset);
    Result := True;
  end
  else
    Result := False;
end;

function TgoHttpClient.Put(const AURL: String; const AConnectTimeout, ARecvTimeout: Integer): String;
var
  Response: TBytes;
begin
  if Put(AURL, Response, AConnectTimeout, ARecvTimeout) then
    Result := BytesToString(Response, FResponseContentCharset);
end;

function TgoHttpClient.Delete(const AURL: String; out AResponse: TBytes;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
begin
  Result := DoRequest('DELETE', AURL, AResponse, AConnectTimeout, ARecvTimeout);
end;

function TgoHttpClient.Delete(const AURL: String; out AResponse: String;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
var
  Response: TBytes;
begin
  if Delete(AURL, Response, AConnectTimeout, ARecvTimeout) then
  begin
    AResponse := BytesToString(Response, FResponseContentCharset);
    Result := True;
  end
  else
    Result := False;
end;

function TgoHttpClient.Delete(const AURL: String; const AConnectTimeout, ARecvTimeout: Integer): String;
var
  Response: TBytes;
begin
  if Delete(AURL, Response, AConnectTimeout, ARecvTimeout) then
    Result := BytesToString(Response, FResponseContentCharset);
end;

function TgoHttpClient.Options(const AURL: String; out AResponse: TBytes;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
begin
  Result := DoRequest('OPTIONS', AURL, AResponse, AConnectTimeout, ARecvTimeout);
end;

function TgoHttpClient.Options(const AURL: String; out AResponse: String;
  const AConnectTimeout, ARecvTimeout: Integer): Boolean;
var
  Response: TBytes;
begin
  if Options(AURL, Response, AConnectTimeout, ARecvTimeout) then
  begin
    AResponse := BytesToString(Response, FResponseContentCharset);
    Result := True;
  end
  else
    Result := False;
end;

function TgoHttpClient.Options(const AURL: String; const AConnectTimeout, ARecvTimeout: Integer): String;
var
  Response: TBytes;
begin
  if Options(AURL, Response, AConnectTimeout, ARecvTimeout) then
    Result := BytesToString(Response, FResponseContentCharset);
end;

initialization
  _HttpClientSocketManager := TgoClientSocketManager.Create;
  HttpClientManager := TgoHttpClientManager.Create;

finalization
  HttpClientManager.Free;
  _HttpClientSocketManager.Free;

end.
