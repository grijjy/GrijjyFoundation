unit Grijjy.Http2;

{ Provides a generic HTTP2 client class based upon the ngHttp2 library }

interface

{$I Grijjy.inc}

uses
  Classes,
  SysUtils,
  StrUtils,
  SyncObjs,
  IOUtils,
  DateUtils,
  Grijjy.Uri,
  Grijjy.SocketPool.Win,
  Nghttp2,
  Grijjy.BinaryCoding;

const
  { Timeout for operations }
  TIMEOUT_CONNECT = 5000;
  TIMEOUT_SEND = 5000;
  DEFAULT_TIMEOUT_RECV = 5000;

  { Ports }
  DEFAULT_HTTP_PORT = 80;
  DEFAULT_HTTPS_PORT = 443;

type
  { HTTP events }
  TOnRedirect = procedure(Sender: TObject; var ALocation: UnicodeString; const AFollow: Boolean) of object;
  TOnPassword = procedure(Sender: TObject; var AAgain: Boolean) of object;

  { Socket activity state }
  TSocketState = (None, Sending, Receiving, Success, Failure);

type
  { Http header }
  THTTPHeader = record
    Name: AnsiString;
    Value: AnsiString;
  end;

  { Http headers class }
  THTTPHeaders = class(TObject)
  private
    FHeaders: TArray<THTTPHeader>;
  public
    constructor Create;
    destructor Destroy; override;
  public
    { Add a header and value to a list of headers }
    procedure Add(const AName, AValue: UnicodeString);

    { Gets the value associated with the header }
    function Value(const AName: UnicodeString): UnicodeString;

    { Writes out the headers as ngHttp2 compatible headers }
    procedure ToNgHttp2Headers(var AHeaders: TArray<nghttp2_nv>);
  public
    property Headers: TArray<THTTPHeader> read FHeaders write FHeaders;
  end;

type
  { HTTP client }
  TgoHTTP2Client = class(TObject)
  private
    FConnection: TgoSocketConnection;
    FConnectionLock: TCriticalSection;
    FCertificate: TBytes;
    FPrivateKey: TBytes;

    { Recv }
    FRecvBuffer: TBytes;
    FRecvIndex: Integer;
    FLastRecv: TDateTime;

    { Send }
    FSendBuffer: TBytes;
    FSendIndex: Integer;
    FLastSent: TDateTime;

    { Http request }
    FURL: UnicodeString;
    FMethod: UnicodeString;
    FURI: TgoURI;
    FLastURI: TgoURI;
    FFollowRedirects: Boolean;
    FAuthorization: UnicodeString;
    FUserName: UnicodeString;
    FPassword: UnicodeString;
    FConnected: TEvent;
    FInternalHeaders: THTTPHeaders;
    FRequestHeaders: THTTPHeaders;
    FRequestBody: UnicodeString;
    FRequestData: TBytes;
    FRequestSent: TSocketState;

    { Http response }
    FResponseHeaders: THTTPHeaders;
    FResponseData: TBytes;
    FResponseStatusCode: Integer;
    FResponseRecv: TSocketState;

    { ngHttp2 }
    FCallbacks_http2: nghttp2_session_callbacks;
    FSession_http2: nghttp2_session;
  protected
    FOnPassword: TOnPassword;
    FOnRedirect: TOnRedirect;
  private
    { ngHttp2 callbacks }
    function nghttp2_data_source_read_callback(session: nghttp2_session;
      stream_id: int32; buf: puint8; len: size_t; data_flags: puint32;
      source: pnghttp2_data_source; user_data: Pointer): ssize_t; cdecl;
    function nghttp2_on_data_chunk_recv_callback(session: nghttp2_session;
      flags: uint8; stream_id: int32; const data: puint8; len: size_t;
      user_data: Pointer): Integer; cdecl;
    function nghttp2_on_frame_recv_callback(session: nghttp2_session;
      const frame: pnghttp2_frame; user_data: Pointer): Integer; cdecl;
    function nghttp2_on_header_callback(session: nghttp2_session;
      const frame: pnghttp2_frame; const name: puint8; namelen: size_t;
      const value: puint8; valuelen: size_t; flags: uint8;
      user_data: Pointer): Integer; cdecl;
    function nghttp2_on_stream_close_callback(session: nghttp2_session;
      stream_id: int32; error_code: uint32; user_data: Pointer): Integer; cdecl;
  private
    procedure Reset;
    function _Send: Boolean;
    function _Recv: Boolean;
    procedure CreateRequest;
    function Connect: Boolean;
    procedure SendRequest;
    function WaitForSendSuccess: Boolean;
    function WaitForRecvSuccess(const ARecvTimeout: Integer): Boolean;
    function DoResponse(var AAgain: Boolean): UnicodeString;
    function DoRequest(const AMethod, AURL: UnicodeString;
      const ARecvTimeout: Integer): UnicodeString;
  protected
    { Socket routines }
    procedure OnSocketConnected;
    procedure OnSocketDisconnected;
    procedure OnSocketSent(const ABuffer: Pointer; const ASize: Integer);
    procedure OnSocketRecv(const ABuffer: Pointer; const ASize: Integer);
  public
    constructor Create;
    destructor Destroy; override;
  public
    { Get method }
    function Get(const AURL: UnicodeString;
      const ARecvTimeout: Integer = DEFAULT_TIMEOUT_RECV): UnicodeString;

    { Post method }
    function Post(const AURL: UnicodeString;
      const ARecvTimeout: Integer = DEFAULT_TIMEOUT_RECV): UnicodeString;

    { Put method }
    function Put(const AURL: UnicodeString;
      const ARecvTimeout: Integer = DEFAULT_TIMEOUT_RECV): UnicodeString;

    { Delete method }
    function Delete(const AURL: UnicodeString;
      const ARecvTimeout: Integer = DEFAULT_TIMEOUT_RECV): UnicodeString;

    { Options method }
    function Options(const AURL: UnicodeString;
      const ARecvTimeout: Integer = DEFAULT_TIMEOUT_RECV): UnicodeString;

    { Optional body for a request.
      You can either use RequestBody or RequestData. If both are specified then
      only RequestBody is used. }
    property RequestBody: UnicodeString read FRequestBody write FRequestBody;

    { Optional binary body data for a request.
      You can either use RequestBody or RequestData. If both are specified then
      only RequestBody is used. }
    property RequestData: TBytes read FRequestData write FRequestData;

    { Request headers }
    property RequestHeaders: THTTPHeaders read FRequestHeaders;

    { Response headers from the server }
    property ResponseHeaders: THTTPHeaders read FResponseHeaders;

    { Response status code }
    property ResponseStatusCode: Integer read FResponseStatusCode;

    { Allow 301 and other redirects }
    property FollowRedirects: Boolean read FFollowRedirects write FFollowRedirects;

    { Called when a redirect is requested }
    property OnRedirect: TOnRedirect read FOnRedirect write FOnRedirect;

    { Called when a password is needed }
    property OnPassword: TOnPassword read FOnPassword write FOnPassword;

    { Username and password for Basic Authentication }
    property UserName: UnicodeString read FUserName write FUserName;
    property Password: UnicodeString read FPassword write FPassword;

    { Certificate in PEM format }
    property Certificate: TBytes read FCertificate write FCertificate;

    { Private key in PEM format }
    property PrivateKey: TBytes read FPrivateKey write FPrivateKey;

    { Authorization }
    property Authorization: UnicodeString read FAuthorization write FAuthorization;
  end;

implementation

uses
  Grijjy.SysUtils;

var
  _HTTPClientSocketManager: TgoClientSocketManager;

{ Helpers }

function AsString(const AString: Pointer; const ALength: Integer): String;
var
  S: AnsiString;
begin
  SetLength(S, ALength);
  Move(AString^, S[1], ALength);
  Result := String(S);
end;

{ ngHttp2 callback cdecl }

function data_source_read_callback(session: nghttp2_session;
  stream_id: int32; buf: puint8; len: size_t; data_flags: puint32;
  source: pnghttp2_data_source; user_data: Pointer): ssize_t; cdecl;
var
  Http: TgoHTTP2Client;
begin
  Assert(Assigned(user_data));
  Http := TgoHTTP2Client(user_data);
  Result := Http.nghttp2_data_source_read_callback(session, stream_id, buf, len, data_flags, source, user_data);
end;

function on_header_callback(session: nghttp2_session; const frame: pnghttp2_frame;
  const name: puint8; namelen: size_t; const value: puint8; valuelen: size_t;
  flags: uint8; user_data: Pointer): Integer; cdecl;
var
  Http: TgoHTTP2Client;
begin
  Assert(Assigned(user_data));
  Http := TgoHTTP2Client(user_data);
  Result := Http.nghttp2_on_header_callback(session, frame, name, namelen, value, valuelen, flags, user_data);
end;

function on_frame_recv_callback(session: nghttp2_session;
  const frame: pnghttp2_frame; user_data: Pointer): Integer; cdecl;
var
  Http: TgoHTTP2Client;
begin
  Assert(Assigned(user_data));
  Http := TgoHTTP2Client(user_data);
  Result := Http.nghttp2_on_frame_recv_callback(session, frame, user_data);
end;

function on_data_chunk_recv_callback(session: nghttp2_session;
  flags: uint8; stream_id: int32; const data: puint8; len: size_t;
  user_data: Pointer): Integer; cdecl;
var
  Http: TgoHTTP2Client;
begin
  Assert(Assigned(user_data));
  Http := TgoHTTP2Client(user_data);
  Result := Http.nghttp2_on_data_chunk_recv_callback(session, flags, stream_id, data, len, user_data);
end;

function on_stream_close_callback(session: nghttp2_session;
  stream_id: int32; error_code: uint32; user_data: Pointer): Integer; cdecl;
var
  Http: TgoHTTP2Client;
begin
  Assert(Assigned(user_data));
  Http := TgoHTTP2Client(user_data);
  Result := Http.nghttp2_on_stream_close_callback(session, stream_id, error_code, user_data);
end;

{ THTTPHeaders }

constructor THTTPHeaders.Create;
begin
end;

destructor THTTPHeaders.Destroy;
begin
  FHeaders := nil;
  inherited;
end;

procedure THTTPHeaders.Add(const AName, AValue: UnicodeString);
var
  Header: THTTPHeader;
begin
  Header.Name := AnsiString(AName);
  Header.Value := AnsiString(AValue);
  FHeaders := FHeaders + [Header];
end;

function THTTPHeaders.Value(const AName: UnicodeString): UnicodeString;
var
  Header: THTTPHeader;
begin
  Result := '';
  for Header in FHeaders do
    if Header.Name = AnsiString(AName) then
    begin
      Result := String(Header.Value);
      Break;
    end;
end;

procedure THTTPHeaders.ToNgHttp2Headers(var AHeaders: TArray<nghttp2_nv>);
var
  Header: THTTPHeader;
  NgHttp2Header: nghttp2_nv;
begin
  for Header in FHeaders do
  begin
    NgHttp2Header.name := PAnsiChar(Header.Name);
    NgHttp2Header.value := PAnsiChar(Header.Value);
    NgHttp2Header.namelen := Length(Header.Name);
    NgHttp2Header.valuelen := Length(Header.Value);
    NgHttp2Header.flags := NGHTTP2_NV_FLAG_NONE;
    AHeaders := AHeaders + [NgHttp2Header];
  end;
end;

{ TgoHTTP2Client }

constructor TgoHTTP2Client.Create;
var
  Settings: nghttp2_settings_entry;
  Error: Integer;
begin
  inherited Create;

  { initialize nghttp2 library }
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
      Error := nghttp2_submit_settings(FSession_http2, NGHTTP2_FLAG_NONE, Settings, 1);
      if (Error <> 0) then
        raise Exception.Create('Unable to  submit ngHttp2 settings');
    end
    else
      raise Exception.Create('Unable to setup ngHttp2 session.');
  end
  else
    raise Exception.Create('Unable to setup ngHttp2 callbacks.');

  FAuthorization := '';
  FConnection := nil;
  FConnectionLock := TCriticalSection.Create;
  FConnected := TEvent.Create(nil, False, False, '');
  FFollowRedirects := True;
  FInternalHeaders := THTTPHeaders.Create;
  FRequestHeaders := THTTPHeaders.Create;
  FResponseHeaders := THTTPHeaders.Create;
end;

destructor TgoHTTP2Client.Destroy;
var
  Connection: TgoSocketConnection;
begin
  nghttp2_session_callbacks_del(FCallbacks_http2);
  nghttp2_session_terminate_session(FSession_http2, NGHTTP2_NO_ERROR);
  FConnectionLock.Enter;
  try
    Connection := FConnection;
    FConnection := nil;
  finally
    FConnectionLock.Leave;
  end;
  if Connection <> nil then
    _HTTPClientSocketManager.Release(Connection);
  FInternalHeaders.Free;
  FRequestHeaders.Free;
  FResponseHeaders.Free;
  FConnected.Free;
  FConnectionLock.Free;
  inherited Destroy;
end;

procedure TgoHTTP2Client.Reset;
begin
  FRecvIndex := 0;
  FSendIndex := 0;
  FRequestSent := TSocketState.None;
  FResponseRecv := TSocketState.None;
  FResponseStatusCode := 0;
  FInternalHeaders.Headers := nil;
  FResponseHeaders.Headers := nil;
end;

function TgoHTTP2Client.WaitForSendSuccess: Boolean;
begin
  FLastSent := Now;
  while (MillisecondsBetween(Now, FLastSent) < TIMEOUT_SEND) and
    (FRequestSent = TSocketState.Sending) do
    Sleep(5);
  Result := FRequestSent = TSocketState.Success;
end;

function TgoHTTP2Client.WaitForRecvSuccess(const ARecvTimeout: Integer): Boolean;
begin
  FLastRecv := Now;
  while (MillisecondsBetween(Now, FLastRecv) < ARecvTimeout) and
    (FResponseRecv = TSocketState.Receiving) do
    Sleep(5);
  Result := FResponseRecv = TSocketState.Success;
end;

function TgoHTTP2Client.DoResponse(var AAgain: Boolean): UnicodeString;
var
  Location: UnicodeString;
begin
  Result := TEncoding.Default.GetString(FResponseData);
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
      end;
    end;

    401: { password required? }
    begin
      if Assigned(FOnPassword) then
        FOnPassword(Self, AAgain);
    end;
  end;
end;

function TgoHTTP2Client.DoRequest(const AMethod: UnicodeString;
  const AURL: UnicodeString; const ARecvTimeout: Integer): UnicodeString;
var
  Again: Boolean;
begin
  Result := '';
  FURL := AURL;
  FMethod := AMethod;
  repeat
    Again := False;
    Reset;
    CreateRequest;
    if Connect then
    begin
      SendRequest;
      if (WaitForSendSuccess) and (WaitForRecvSuccess(ARecvTimeout)) then
        Result := DoResponse(Again);
      FLastURI := FURI;
    end;
  until not Again;
end;

procedure TgoHTTP2Client.OnSocketConnected;
begin
  FRequestSent := TSocketState.Sending;
  FConnected.SetEvent;
end;

procedure TgoHTTP2Client.OnSocketDisconnected;
begin
  FRequestSent := TSocketState.None;
  FResponseRecv := TSocketState.None;
end;

procedure TgoHTTP2Client.OnSocketSent(const ABuffer: Pointer;
  const ASize: Integer);
begin
  FLastSent := Now;
end;

procedure TgoHTTP2Client.OnSocketRecv(const ABuffer: Pointer; const ASize: Integer);
begin
  FLastRecv := Now;

  { expand the buffer }
  SetLength(FRecvBuffer, Length(FRecvBuffer) + ASize);
  Move(ABuffer^, FRecvBuffer[Length(FRecvBuffer) - ASize], ASize);

  { send to nghttp2 }
  _Recv;
end;

function TgoHTTP2Client.Get(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('GET', AURL, ARecvTimeout);
end;

function TgoHTTP2Client.Post(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('POST', AURL, ARecvTimeout);
end;

function TgoHTTP2Client.Put(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('PUT', AURL, ARecvTimeout);
end;

function TgoHTTP2Client.Delete(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('DELETE', AURL, ARecvTimeout);
end;

function TgoHTTP2Client.Options(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('OPTIONS', AURL, ARecvTimeout);
end;

function TgoHTTP2Client._Send: Boolean;
var
  DataPtr: Pointer;
  DataLen: Integer;
  Data: TBytes;
begin
  Result := False;
  while nghttp2_session_want_write(FSession_http2) > 0 do
  begin
    DataLen := nghttp2_session_mem_send(FSession_http2, DataPtr);
    if DataLen > 0 then
    begin
      SetLength(Data, DataLen);
      Move(DataPtr^, Data[0], DataLen);
      Result := FConnection.Send(Data);
    end;
  end;
end;

function TgoHTTP2Client._Recv: Boolean;
var
  ReadLen: Integer;
begin
  Result := False;
  if FRecvIndex < Length(FRecvBuffer) then
  begin
    ReadLen := nghttp2_session_mem_recv(FSession_http2, @FRecvBuffer[FRecvIndex], Length(FRecvBuffer) - FRecvIndex);
    if ReadLen > 0 then
      FRecvIndex := FRecvIndex + ReadLen;
  end;
end;

procedure TgoHTTP2Client.CreateRequest;
var
  _Username: UnicodeString;
  _Password: UnicodeString;
begin
  { parse the URL into a URI }
  FURI := TgoURI.Create(FURL);

  { http or https }
  if (FURI.Port = 0) then
  begin
    if FURI.Scheme.ToLower = 'https' then
      FURI.Port := DEFAULT_HTTPS_PORT
    else
      FURI.Port := DEFAULT_HTTP_PORT;
  end;

  { add method }
  FInternalHeaders.Add(':method', FMethod.ToUpper);

  { add scheme }
  FInternalHeaders.Add(':scheme', FURI.Scheme.ToLower);

  { add path }
  FInternalHeaders.Add(':path', FURI.Path);

  { add host }
  FInternalHeaders.Add('host', FURI.Host);

  { use credentials in URI, if provided }
  _Username := FURI.Username;
  _Password := FURI.Password;
  if (_Username = '') then
  begin
    { credentials provided? }
    _Username := FUserName;
    _Password := FPassword;
  end;
  if (_Username <> '') then
  begin
    { add basic authentication }
    FInternalHeaders.Add('authorization', 'Basic ' +
      TEncoding.Utf8.GetString(goBase64Encode(TEncoding.Utf8.GetBytes(_Username + ':' + _Password))));
  end
  else
    { add authorization }
    if (FAuthorization <> '') then
      FInternalHeaders.Add('authorization', FAuthorization);
end;

function TgoHTTP2Client.Connect: Boolean;
begin
  FConnectionLock.Enter;
  try
    if (FConnection <> nil) and
      ((FURI.Scheme.ToLower <> FLastURI.Scheme) or
      (FURI.Host <> FLastURI.Host ) or
      (FURI.Port <> FLastURI.Port)) then
    begin
      _HTTPClientSocketManager.Release(FConnection);
      FConnection := nil;
    end;
    if FConnection = nil then
    begin
      FConnection := _HTTPClientSocketManager.Request(FURI.Host, FURI.Port);
      FConnection.OnConnected := OnSocketConnected;
      FConnection.OnDisconnected := OnSocketDisconnected;
      FConnection.OnRecv := OnSocketRecv;
      if FURI.Scheme.ToLower = 'https' then
      begin
        FConnection.SSL := True;
        FConnection.ALPN := True;
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
      if FConnection.Connect(False) then { disable nagle }
        Result := FConnected.WaitFor(TIMEOUT_CONNECT) <> wrTimeout;
  finally
    FConnectionLock.Leave;
  end;
end;

procedure TgoHTTP2Client.SendRequest;
var
  Stream_id: Integer;
  DataProvider: nghttp2_data_provider;
  Headers: TArray<nghttp2_nv>;
begin
  FConnectionLock.Enter;
  try
    if (FConnection <> nil) then
    begin
      { setup data callback }
      DataProvider.source.ptr := nil;
      DataProvider.read_callback := data_source_read_callback;

      { create nghttp2 compatible headers }
      FInternalHeaders.ToNgHttp2Headers(Headers);
      FRequestHeaders.ToNgHttp2Headers(Headers);

      { setup send buffer }
      if (FRequestBody <> '') then
        FSendBuffer := TEncoding.Utf8.GetBytes(FRequestBody)
      else
        FSendBuffer := FRequestData;

      { submit request }
      Stream_id := nghttp2_submit_request(FSession_http2, Nil, Headers[0], Length(Headers), @DataProvider, Self);
      if Stream_id >= 0 then
      begin
        if _Send then
        begin
          FResponseRecv := TSocketState.Receiving;
          FRequestSent := TSocketState.Success;
        end
        else
          FRequestSent := TSocketState.Failure;
      end
      else
        FRequestSent := TSocketState.Failure;
    end;
  finally
    FConnectionLock.Leave;
  end;
end;

function TgoHTTP2Client.nghttp2_data_source_read_callback(session: nghttp2_session;
  stream_id: int32; buf: puint8; len: size_t; data_flags: puint32;
  source: pnghttp2_data_source; user_data: Pointer): ssize_t;
begin
  // Note: if you want request specific data you can use the API nghttp2_session_get_stream_user_data(session, stream_id);

  {$WARNINGS OFF}
  if (Length(FSendBuffer) - FSendIndex) <= len then
  {$WARNINGS ON}
  begin
    Result := Length(FSendBuffer) - FSendIndex;
    Move(FSendBuffer[FSendIndex], Buf^, Result);
    data_flags^ := data_flags^ or NGHTTP2_DATA_FLAG_EOF;
  end
  else
  begin
    Result := len;
    Move(FSendBuffer[FSendIndex], Buf^, Result);
    FSendIndex := FSendIndex + Result;
  end;
end;

function TgoHTTP2Client.nghttp2_on_header_callback(session: nghttp2_session; const frame: pnghttp2_frame;
  const name: puint8; namelen: size_t; const value: puint8; valuelen: size_t;
  flags: uint8; user_data: Pointer): Integer;
var
  AName, AValue: String;
begin
  if frame.hd.&type = _NGHTTP2_HEADERS then
    if (frame.headers.cat = NGHTTP2_HCAT_RESPONSE) then
    begin
      { single response header }
      AName := AsString(name, namelen);
      AValue := AsString(value, valuelen);
      FResponseHeaders.Add(AName, AValue);

      { response status code }
      if AName = ':status' then
        FResponseStatusCode := StrToInt64Def(AValue, -1)
    end;
  Result := 0;
end;

function TgoHTTP2Client.nghttp2_on_frame_recv_callback(session: nghttp2_session;
  const frame: pnghttp2_frame; user_data: Pointer): Integer;
begin
  if frame.hd.&type = _NGHTTP2_HEADERS then
    if (frame.headers.cat = NGHTTP2_HCAT_RESPONSE) then
    begin
      // all headers received
    end;
  Result := 0;
end;

function TgoHTTP2Client.nghttp2_on_data_chunk_recv_callback(session: nghttp2_session;
  flags: uint8; stream_id: int32; const data: puint8; len: size_t;
  user_data: Pointer): Integer;
begin
  // response chunk
  {$WARNINGS OFF}
  SetLength(FResponseData, Length(FResponseData) + len);
  Move(data^, FResponseData[Length(FResponseData) - len], len);
  {$WARNINGS ON}
  Result := 0;
end;

function TgoHTTP2Client.nghttp2_on_stream_close_callback(session: nghttp2_session;
  stream_id: int32; error_code: uint32; user_data: Pointer): Integer;
begin
  if FResponseStatusCode <> 0 then
    FResponseRecv := TSocketState.Success
  else
    FResponseRecv := TSocketState.Failure;
  Result := 0;
  { Note : connection is still open at this point unless you call
    nghttp2_session_terminate_session(session, NGHTTP2_NO_ERROR) }
end;

initialization
  _HTTPClientSocketManager := TgoClientSocketManager.Create;

finalization
  _HTTPClientSocketManager.Free;

end.
