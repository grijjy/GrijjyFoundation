unit Grijjy.Http;

{ Windows and Linux Cross-platform HTTP/S client class using scalable sockets }

{$I Grijjy.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  System.SyncObjs,
  System.DateUtils,
  Grijjy.Uri,
  {$IF Defined(MSWINDOWS)}
  Grijjy.SocketPool.Win,
  {$ELSEIF Defined(LINUX)}
  Grijjy.SocketPool.Linux,
  {$ELSE}
    {$MESSAGE Error 'Unsupported Platform'}
  {$ENDIF}
  Grijjy.BinaryCoding;

const
  { Socket recv buffer size }
  RECV_BUFFER_SIZE = 32768;

  { Timeout for operations }
  TIMEOUT_CONNECT = 5000;
  TIMEOUT_SEND = 5000;
  DEFAULT_TIMEOUT_RECV = 5000;

  { Strings }
  S_CONTENT_LENGTH = 'content-length:';
  S_TRANSFER_ENCODING = 'transfer-encoding:';
  S_CHUNKED = 'chunked';

  { End of line }
  CRLF = #13#10;

  { Ports }
  DEFAULT_HTTP_PORT = 80;
  DEFAULT_HTTPS_PORT = 443;

type
  { HTTP events }
  TOnRedirect = procedure(Sender: TObject; var ALocation: UnicodeString; const AFollow: Boolean) of object;
  TOnPassword = procedure(Sender: TObject; var AAgain: Boolean) of object;

  { Socket activity state }
  TSocketState = (None, Sending, Receiving, Success, Failure);

  { HTTP client }
  TgoHTTPClient = class(TObject)
  private
    FConnection: TgoSocketConnection;
    FConnectionLock: TCriticalSection;

    { Recv }
    FRecvBuffer: TBytes;
    FRecvSize: Integer;
    FLastRecv: TDateTime;

    { Send }
    FLastSent: TDateTime;

    { Http request }
    FURL: UnicodeString;
    FMethod: UnicodeString;
    FURI: TgoURI;
    FLastURI: TgoURI;
    FContentLength: Int64;
    FTransferEncoding: UnicodeString;
    FHTTPVersion: UnicodeString;
    FFollowRedirects: Boolean;
    FSentCookies: TStrings;
    FCookies: TStrings;
    FAuthorization: UnicodeString;
    FUserName: UnicodeString;
    FPassword: UnicodeString;
    FContentType: UnicodeString;
    FConnected: TEvent;
    FRequestHeader: UnicodeString;
    FRequestHeaders: TStrings;
    FRequestBody: UnicodeString;
    FRequestData: TBytes;
    FRequestSent: TSocketState;
    FUserAgent: UnicodeString;

    { Http response }
    FResponseHeaders: TStrings;
    FResponseStatusCode: Integer;
    FResponseIndexEndOfHeader: Integer;
    FResponseRecv: TSocketState;
  protected
    FOnPassword: TOnPassword;
    FOnRedirect: TOnRedirect;
    procedure SetCookies(const AValue: TStrings);
  private
    function GetCookies: TStrings;
  private
    function BytePos(const ASubStr: AnsiString; AOffset: Integer = 0): Integer;
    procedure Reset;
    procedure CreateRequest;
    procedure SendRequest;
    function ResponseHeaderReady: Boolean;
    function ResponseContentReady: Boolean;
    function ReadResponse: UnicodeString;
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
    { Add a header and value to a list of headers }
    procedure AddHeader(AHTTPHeaders: TStrings; const AHeader, AValue: UnicodeString);

    { Find the index of a header from a list of headers }
    function IndexOfHeader(AHTTPHeaders: TStrings; const AHeader: UnicodeString): Integer;

    { Get the value associated with a header from a list of headers }
    function GetHeaderValue(AHTTPHeaders: TStrings; const AHeader: UnicodeString): UnicodeString;

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

    { Cookies sent to the server and received from the server }
    property Cookies: TStrings read GetCookies write SetCookies;

    { Optional body for a request.
      You can either use RequestBody or RequestData. If both are specified then
      only RequestBody is used. }
    property RequestBody: UnicodeString read FRequestBody write FRequestBody;

    { Optional binary body data for a request.
      You can either use RequestBody or RequestData. If both are specified then
      only RequestBody is used. }
    property RequestData: TBytes read FRequestData write FRequestData;

    { Request headers }
    property RequestHeaders: TStrings read FRequestHeaders;

    { Response headers from the server }
    property ResponseHeaders: TStrings read FResponseHeaders;

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

    { Content type }
    property ContentType: UnicodeString read FContentType write FContentType;

    { User agent }
    property UserAgent: UnicodeString read FUserAgent write FUserAgent;

    { Authorization }
    property Authorization: UnicodeString read FAuthorization write FAuthorization;
  end;

implementation

var
  _HTTPClientSocketManager: TgoClientSocketManager;

{ TgoHTTPClient }

constructor TgoHTTPClient.Create;
begin
  inherited Create;
  FHTTPVersion := '1.1';
  FAuthorization := '';
  FContentType := '';
  FUserAgent := '';
  FConnection := nil;
  FConnectionLock := TCriticalSection.Create;
  FConnected := TEvent.Create(nil, False, False, '');
  FFollowRedirects := True;
  SetLength(FRecvBuffer, RECV_BUFFER_SIZE);
  FRecvSize := 0;
  FRequestHeaders := TStringList.Create;
  FResponseHeaders := TStringList.Create;
end;

destructor TgoHTTPClient.Destroy;
var
  Connection: TgoSocketConnection;
begin
  FConnectionLock.Enter;
  try
    Connection := FConnection;
    FConnection := nil;
  finally
    FConnectionLock.Leave;
  end;
  if Connection <> nil then
    _HTTPClientSocketManager.Release(Connection);
  FreeAndNil(FRequestHeaders);
  FreeAndNil(FResponseHeaders);
  FreeAndNil(FCookies);
  FreeAndNil(FSentCookies);
  FConnected.Free;
  FConnectionLock.Free;
  inherited Destroy;
end;

{ Cookies received from the server }
function TgoHTTPClient.GetCookies: TStrings;
begin
  if FCookies = nil then
    FCookies := TStringList.Create;
  Result := FCookies;
end;

{ Cookies sent to the server }
procedure TgoHTTPClient.SetCookies(const AValue: TStrings);
begin
  if GetCookies = AValue then
    Exit;
  GetCookies.Assign(AValue);
end;

{ Add a header and value to a list of headers }
procedure TgoHTTPClient.AddHeader(AHTTPHeaders: TStrings; const AHeader, AValue: UnicodeString);
var
  Index: Integer;
begin
  Index := IndexOfHeader(AHTTPHeaders, AHeader);
  if (Index <> -1) then
    AHTTPHeaders.Delete(Index);
  AHTTPHeaders.Add(AHeader + ': ' + AValue);
end;

{ Find the index of a header from a list of headers }
function TgoHTTPClient.IndexOfHeader(AHTTPHeaders: TStrings; const AHeader: UnicodeString): Integer;
begin
  Result := AHTTPHeaders.Count - 1;
  while (Result >= 0) and
    (AHTTPHeaders[Result].Substring(0, AHeader.Length).ToLower <> AHeader.ToLower) do
    Dec(Result);
end;

{ Get the value associated with a header from a list of headers }
function TgoHTTPClient.GetHeaderValue(AHTTPHeaders: TStrings; const AHeader: UnicodeString): UnicodeString;
var
  Index, Pos1: Integer;
begin
  Index := IndexOfHeader(AHTTPHeaders, AHeader);
  if (Index = -1) then
    Result := ''
  else
  begin
    Pos1 := AHTTPHeaders[Index].IndexOf(':');
    if Pos1 = -1 then
      Result := ''
    else
      Result := AHTTPHeaders[Index].Substring(Pos1 + 1).TrimLeft;
  end;
end;

procedure TgoHTTPClient.Reset;
begin
  FRecvSize := 0;
  FRequestSent := TSocketState.None;
  FResponseRecv := TSocketState.None;
  FResponseStatusCode := 0;
  FResponseHeaders.Clear;
end;

procedure TgoHTTPClient.CreateRequest;
var
  _Username: UnicodeString;
  _Password: UnicodeString;
  _Cookies: UnicodeString;
  Index: Integer;
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

  { add header status line }
  FRequestHeader := FMethod.ToUpper + ' ' + FURI.ToString + ' ' + 'HTTP/' + FHTTPVersion + CRLF;

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
    FRequestHeader := FRequestHeader + 'Authorization: Basic ' +
      TEncoding.Utf8.GetString(goBase64Encode(TEncoding.Utf8.GetBytes(_Username + ':' + _Password))) + CRLF;
    { remove any existing credentials }
    Index := IndexOfHeader(FRequestHeaders, 'Authorization');
    if Index <> -1 then
      FRequestHeaders.Delete(Index);
  end
  else
    { add authorization }
    if (FAuthorization <> '') then
      FRequestHeader := FRequestHeader + 'Authorization: ' + FAuthorization + CRLF;

  { add host }
  FRequestHeader := FRequestHeader + 'Host: ' + FURI.Host;
  if (FURI.Port <> 0) then
    FRequestHeader := FRequestHeader + ':' + FURI.Port.ToString;
  FRequestHeader := FRequestHeader + CRLF;

  { add user-agent }
  if (FUserAgent <> '') then
    FRequestHeader := FRequestHeader + 'User-Agent: ' + FUserAgent + CRLF;

  { add content type }
  if (FContentType <> '') then
    FRequestHeader := FRequestHeader + 'Content-Type: ' + FContentType + CRLF;

  { add content length }
  if (FRequestBody <> '') then
    FRequestHeader := FRequestHeader + 'Content-Length: ' + IntToStr(Length(FRequestBody)) + CRLF
  else if (FRequestData <> nil) then
    FRequestHeader := FRequestHeader + 'Content-Length: ' + IntToStr(Length(FRequestData)) + CRLF;

  { add additional request headers, if any }
  for Index := 0 to FRequestHeaders.Count - 1 do
    FRequestHeader := FRequestHeader + FRequestHeaders[Index] + CRLF;

  { add cookies, if any }
  if Assigned(FCookies) then
  begin
    _Cookies := 'Cookie:';
    for Index := 0 to FCookies.Count-1 do
    begin
      if Index > 0 then
        _Cookies := _Cookies + '; ';
      _Cookies := _Cookies + FCookies[Index];
    end;
    FRequestHeader := FRequestHeader + _Cookies + CRLF;
  end;
  FreeAndNil(FSentCookies);
  FSentCookies := FCookies;
  FCookies := nil;
  FRequestHeader := FRequestHeader + CRLF;
end;

procedure TgoHTTPClient.SendRequest;
var
  OK: Boolean;
begin
  FConnectionLock.Enter;
  try
    if (FConnection <> nil) then
    begin
      OK := FConnection.Send(TEncoding.Utf8.GetBytes(FRequestHeader));
      if (FRequestBody <> '') then
        OK := OK and FConnection.Send(TEncoding.Utf8.GetBytes(FRequestBody))
      else
        OK := OK and FConnection.Send(FRequestData);

      if OK then
      begin
        FResponseRecv := TSocketState.Receiving;
        FRequestSent := TSocketState.Success;
      end
      else
        FRequestSent := TSocketState.Failure;
    end;
  finally
    FConnectionLock.Leave;
  end;
end;

function TgoHTTPClient.BytePos(const ASubStr: AnsiString; AOffset: Integer = 0): Integer;
var
  Size: Integer;
begin
  Size := Length(ASubStr);
  for Result := AOffset to FRecvSize - Size do
    if CompareMem(@FRecvBuffer[Result], @ASubStr[1], Size) then
      Exit;
  Result := -1;
end;

function TgoHTTPClient.ResponseHeaderReady: Boolean;
var
  Index: Integer;
  Strings: TArray<UnicodeString>;
begin
  Index := BytePos(CRLF + CRLF);
  if Index > 0 then
  begin
    Result := True; { header received }

    { headers }
    FResponseIndexEndOfHeader := Index + 3;
    FResponseHeaders.Text := TEncoding.UTF8.GetString(FRecvBuffer, 0, FResponseIndexEndOfHeader);

    { response status code }
    Strings := FResponseHeaders[0].ToLower.Substring(FResponseHeaders[0].ToLower.LastIndexOf('http:/')).Split([#32]);
    if Length(Strings) >= 2 then
      FResponseStatusCode := StrToInt64Def(Strings[1], -1)
    else
      FResponseStatusCode := -1;

    { content length or transfer encoding? }
    FContentLength := StrToInt64Def(GetHeaderValue(FResponseHeaders, S_CONTENT_LENGTH).Trim, -1);
    if FContentLength < 0 then
      { chunked encoding }
      FTransferEncoding := GetHeaderValue(FResponseHeaders, S_TRANSFER_ENCODING).Trim;
  end
  else
    Result := False;
end;

function TgoHTTPClient.ResponseContentReady: Boolean;
var
  Index: Integer;
  S: UnicodeString;
  Pos1, Pos2: Integer;
  ChunkSize: Integer;
begin
  Index := FResponseIndexEndOfHeader + 1;
  if FContentLength >= 0 then
  begin
    if FContentLength = (FRecvSize - Index) then
      Result := True
    else
      Result := False;
  end
  else
  begin
    { chunked encoding }
    Result := False;
    if FTransferEncoding = S_CHUNKED then
    begin
      while True do
      begin
        Pos1 := BytePos(CRLF, Index);
        if (Pos1 > 0) then
        begin
          S := TEncoding.Default.GetString(FRecvBuffer, Index, Pos1 - Index);
          Pos2 := S.IndexOf(';'); { skip optional chunk parameters }
          if Pos2 > 0 then
            S := TEncoding.Default.GetString(FRecvBuffer, Index, Pos2 - Index + 1);
          ChunkSize := StrToInt64Def('$' + S, -1);
          if ChunkSize = 0 then
          begin
            Result := True;
            Break;
          end
          else
            if ChunkSize > 0 then
            begin
              { ChunkSize + Params + CRLF + Chunk + CRLF }
              Index := Pos1 + 2 + ChunkSize + 2; { next chunk }
              if Index >= FRecvSize then
                Break;
            end;
        end
        else
          Break;
      end;
    end;
  end;
end;

function TgoHTTPClient.ReadResponse: UnicodeString;
var
  Index: Integer;
  S: UnicodeString;
  Pos1, Pos2: Integer;
  ChunkSize: Integer;
begin
  Index := FResponseIndexEndOfHeader + 1;
  if FContentLength >= 0 then
    Result := TEncoding.Default.GetString(FRecvBuffer, Index, FRecvSize - Index)
  else
  begin
    { chunked encoding }
    Result := '';
    if FTransferEncoding = S_CHUNKED then
    begin
      repeat
        Pos1 := BytePos(CRLF, Index);
        if (Pos1 > 0) then
        begin
          S := TEncoding.Default.GetString(FRecvBuffer, Index, Pos1 - Index);
          Pos2 := S.IndexOf(';'); { skip optional chunk parameters }
          if Pos2 > 0 then
            S := TEncoding.Default.GetString(FRecvBuffer, Index, Pos2 - Index + 1);
          ChunkSize := StrToInt64Def('$' + S, -1);
          if ChunkSize > 0 then
          begin
            { ChunkSize + Params + CRLF + Chunk + CRLF }
            Index := Pos1 + 2; { start of chunk }
            Result := Result + TEncoding.Default.GetString(FRecvBuffer, Index, ChunkSize);
            Index := Index + ChunkSize + 2; { next chunk }
          end;
        end
        else ChunkSize := -1;
      until (ChunkSize <= 0);
    end;
  end;
end;

function TgoHTTPClient.WaitForSendSuccess: Boolean;
begin
  FLastSent := Now;
  while (MillisecondsBetween(Now, FLastSent) < TIMEOUT_SEND) and
    (FRequestSent = TSocketState.Sending) do
    Sleep(5);
  Result := FRequestSent = TSocketState.Success;
end;

function TgoHTTPClient.WaitForRecvSuccess(const ARecvTimeout: Integer): Boolean;
begin
  FLastRecv := Now;
  while (MillisecondsBetween(Now, FLastRecv) < ARecvTimeout) and
    (FResponseRecv = TSocketState.Receiving) do
    Sleep(5);
  Result := FResponseRecv = TSocketState.Success;
end;

function TgoHTTPClient.DoResponse(var AAgain: Boolean): UnicodeString;
var
  Location: UnicodeString;
begin
  Result := ReadResponse;
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
        Location := GetHeaderValue(FResponseHeaders, 'Location');
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

function TgoHTTPClient.DoRequest(const AMethod: UnicodeString;
  const AURL: UnicodeString; const ARecvTimeout: Integer): UnicodeString;
var
  Again: Boolean;

  function Connect: Boolean;
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
          FConnection.SSL := True
        else
          FConnection.SSL := False;
      end;
      Result := FConnection.State = TgoConnectionState.Connected;
      if not Result then
        if FConnection.Connect then
          Result := FConnected.WaitFor(TIMEOUT_CONNECT) <> wrTimeout;
    finally
      FConnectionLock.Leave;
    end;
  end;

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

procedure TgoHTTPClient.OnSocketConnected;
begin
  FRequestSent := TSocketState.Sending;
  FConnected.SetEvent;
end;

procedure TgoHTTPClient.OnSocketDisconnected;
begin
  FRequestSent := TSocketState.None;
  FResponseRecv := TSocketState.None;
end;

procedure TgoHTTPClient.OnSocketSent(const ABuffer: Pointer;
  const ASize: Integer);
begin
  FLastSent := Now;
end;

procedure TgoHTTPClient.OnSocketRecv(const ABuffer: Pointer; const ASize: Integer);
begin
  FLastRecv := Now;

  { expand the buffer if we are at capacity }
  if FRecvSize + ASize >= Length(FRecvBuffer) then
    SetLength(FRecvBuffer, (FRecvSize + ASize) * 2);

  { append the new buffer }
  Move(ABuffer^, FRecvBuffer[FRecvSize], ASize);
  FRecvSize := FRecvSize + ASize;

  { received both a complete header and content? }
  if ResponseHeaderReady and ResponseContentReady then
    FResponseRecv := TSocketState.Success;
end;

function TgoHTTPClient.Get(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('GET', AURL, ARecvTimeout);
end;

function TgoHTTPClient.Post(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('POST', AURL, ARecvTimeout);
end;

function TgoHTTPClient.Put(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('PUT', AURL, ARecvTimeout);
end;

function TgoHTTPClient.Delete(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('DELETE', AURL, ARecvTimeout);
end;

function TgoHTTPClient.Options(const AURL: UnicodeString;
  const ARecvTimeout: Integer): UnicodeString;
begin
  Result := DoRequest('OPTIONS', AURL, ARecvTimeout);
end;

initialization
  _HTTPClientSocketManager := TgoClientSocketManager.Create;

finalization
  _HTTPClientSocketManager.Free;

end.
