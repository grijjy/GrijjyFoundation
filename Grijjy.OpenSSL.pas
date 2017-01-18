unit Grijjy.OpenSSL;

{ OpenSSL handler for Grijjy connections }

{$I Grijjy.inc}

interface

uses
  System.SysUtils,
  Grijjy.OpenSSL.API,
  Grijjy.MemoryPool;

const
  DEFAULT_BLOCK_SIZE = 4096;

type
  { Callback events }
  TgoOpenSSLNotify = procedure of object;
  TgoOpenSSLData = procedure(const ABuffer: Pointer; const ASize: Integer) of object;

  { OpenSSL handler instance }
  TgoOpenSSL = class(TObject)
  protected
    FOnConnected: TgoOpenSSLNotify;
    FOnRead: TgoOpenSSLData;
    FOnWrite: TgoOpenSSLData;
  private
    { OpenSSL related objects }
    FHandshaking: Boolean;
    FSSLContext: PSSL_CTX;
    FSSL: PSSL;
    FBIORead: PBIO;
    FBIOWrite: PBIO;
    FSSLWriteBuffer: Pointer;
    FSSLReadBuffer: Pointer;

    { Certificate and Private Key }
    FCertificate: TBytes;
    FPrivateKey: TBytes;
    FPassword: UnicodeString;
  public
    constructor Create;
    destructor Destroy; override;
  public
    { Start SSL connect handshake }
    function Connect(const AALPN: Boolean = False): Boolean;

    { Free SSL related objects }
    procedure Release;

    { Do SSL read from socket }
    procedure Read(const ABuffer: Pointer = nil; const ASize: Integer = 0);

    { Do SSL write to socket }
    function Write(const ABuffer: Pointer; const ASize: Integer): Boolean;

    { Returns True if ALPN is negotiated }
    function ALPN: Boolean;
  public
    { Certificate in PEM format }
    property Certificate: TBytes read FCertificate write FCertificate;

    { Private key in PEM format }
    property PrivateKey: TBytes read FPrivateKey write FPrivateKey;

    { Password for private key }
    property Password: UnicodeString read FPassword write FPassword;
  public
    { Fired when the SSL connection is established }
    property OnConnected: TgoOpenSSLNotify read FOnConnected write FOnConnected;

    { Fired when decrypted SSL data is ready to be read }
    property OnRead: TgoOpenSSLData read FOnRead write FOnRead;

    { Fired when encrypted SSL data is ready to be sent }
    property OnWrite: TgoOpenSSLData read FOnWrite write FOnWrite;
  end;

implementation

var
  _MemBufferPool: TgoMemoryPool;

{ TgoOpenSSL }

constructor TgoOpenSSL.Create;
begin
  inherited Create;
  FHandshaking := False;
  FSSL := nil;
  FSSLContext := nil;
  FSSLWriteBuffer := nil;
  FSSLReadBuffer := nil;
end;

destructor TgoOpenSSL.Destroy;
begin
  Release;
  ERR_remove_thread_state(0);
  inherited Destroy;
end;

function TgoOpenSSL.Connect(const AALPN: Boolean): Boolean;
begin
  Result := False;

  { create ssl context }
  FSSLContext := SSL_CTX_new(SSLv23_method);
  if FSSLContext <> nil then
  begin
    { if we are connecting using the http2 protocol and TLS }
    if AALPN then
    begin
      { force TLS 1.2 }
      SSL_CTX_set_options(FSSLContext,
        SSL_OP_ALL + SSL_OP_NO_SSLv2 + SSL_OP_NO_SSLv3 + SSL_OP_NO_COMPRESSION);

      { enable Application-Layer Protocol Negotiation Extension }
      SSL_CTX_set_alpn_protos(FSSLContext, #2'h2', 3);
    end;

    { no certificate validation }
    SSL_CTX_set_verify(FSSLContext, SSL_VERIFY_NONE, nil);

    { apply PEM Certificate }
    if FCertificate <> nil then
    begin
      if FPrivateKey = nil then
        TgoSSLHelper.SetCertificate(FSSLContext, FCertificate, FCertificate, FPassword)
      else
        TgoSSLHelper.SetCertificate(FSSLContext, FCertificate, FPrivateKey, FPassword);

      { Example loading certificate directly from a file:
        S := ExtractFilePath(ParamStr(0)) + 'Grijjy.pem';
        SSL_CTX_use_certificate_file(FSSLContext, PAnsiChar(S), 1);
        SSL_CTX_use_RSAPrivateKey_file(FSSLContext, PAnsiChar(S), 1);
      }

      { Example loading CA certificate directly from a file:
        SSL_CTX_load_verify_locations(FSSLContext, 'entrust_2048_ca.cer', nil);
      }

      { Example loading CA certificate into memory:
        X509_Store := SSL_CTX_get_cert_store(FSSLContext);
        ABIO := BIO_new(BIO_s_file);
        BIO_read_filename(ABIO, PAnsiChar(AFile));
        ACert := PEM_read_bio_X509(ABIO, nil, nil, nil);
        X509_STORE_add_cert(X509_Store, ACert); }
    end;

    { create an SSL struct for the connection }
    FSSL := SSL_new(FSSLContext);
    if FSSL <> nil then
    begin
      { create the read and write BIO }
      FBIORead := BIO_new(BIO_s_mem);
      if FBIORead <> nil then
      begin
        FBIOWrite := BIO_new(BIO_s_mem);
        if FBIOWrite <> nil then
        begin
          FHandshaking := True;

          { relate the BIO to the SSL object }
          SSL_set_bio(FSSL, FBIORead, FBIOWrite);

          { ssl session should start the negotiation }
          SSL_set_connect_state(FSSL);

          { allocate buffers }
          FSSLWriteBuffer :=_MemBufferPool.RequestMem;
          FSSLReadBuffer :=_MemBufferPool.RequestMem;

          { start ssl handshake sequence }
          Read;

          { SSL success }
          Result := True;
        end;
      end;
    end;
  end;
end;

procedure TgoOpenSSL.Release;
begin
  { free handle }
  if FSSL <> nil then
  begin
    SSL_shutdown(FSSL);
    SSL_free(FSSL);
    FSSL := nil;
  end;
  { free context }
  if FSSLContext <> nil then
  begin
    SSL_CTX_free(FSSLContext);
    FSSLContext := nil;
  end;
  { release buffers }
  if FSSLWriteBuffer <> nil then
  begin
    _MemBufferPool.ReleaseMem(FSSLWriteBuffer);
    FSSLWriteBuffer := nil;
  end;
  if FSSLReadBuffer <> nil then
  begin
    _MemBufferPool.ReleaseMem(FSSLReadBuffer);
    FSSLReadBuffer := nil;
  end;
end;

procedure TgoOpenSSL.Read(const ABuffer: Pointer; const ASize: Integer);
var
  Bytes: Integer;
  Error: Integer;
begin
  while True do
  begin
    BIO_write(FBIORead, ABuffer, ASize);
    if not BIO_should_retry(FBIORead) then
      Break;
  end;

  while True do
  begin
    Bytes := SSL_read(FSSL, FSSLReadBuffer, DEFAULT_BLOCK_SIZE);
    if Bytes > 0 then
    begin
      if Assigned(FOnRead) then
        FOnRead(FSSLReadBuffer, Bytes)
    end
    else
    begin
      Error := SSL_get_error(FSSL, Bytes);
      if not ssl_is_fatal_error(Error) then
        Break
      else
        Exit;
    end;
  end;

  { handshake data needs to be written? }
  if BIO_pending(FBIOWrite) <> 0 then
  begin
    Bytes := BIO_read(FBIOWrite, FSSLWriteBuffer, DEFAULT_BLOCK_SIZE);
    if Bytes > 0 then
    begin
      if Assigned(FOnWrite) then
        FOnWrite(FSSLWriteBuffer, Bytes);
    end
    else
    begin
      Error := SSL_get_error(FSSL, Bytes);
      if ssl_is_fatal_error(Error) then
        Exit;
    end;
  end;

  { with ssl we are only connected and can write once the handshake is finished }
  if FHandshaking then
    if SSL_is_init_finished(FSSL) then
    begin
      FHandshaking := False;
      if Assigned(FOnConnected) then
        FOnConnected;
    end
end;

function TgoOpenSSL.Write(const ABuffer: Pointer; const ASize: Integer): Boolean;
var
  Bytes: Integer;
  Error: Integer;
begin
  Result := False;

  Bytes := SSL_write(FSSL, ABuffer, ASize);
  if Bytes <> ASize then
  begin
    Error := SSL_get_error(FSSL, Bytes);
    if ssl_is_fatal_error(Error) then
      Exit;
  end;

  while BIO_pending(FBIOWrite) <> 0 do
  begin
    Bytes := BIO_read(FBIOWrite, FSSLWriteBuffer, DEFAULT_BLOCK_SIZE);
    if Bytes > 0 then
    begin
      Result := True;
      if Assigned(FOnWrite) then
        FOnWrite(FSSLWriteBuffer, Bytes);
    end
    else
    begin
      Error := SSL_get_error(FSSL, Bytes);
      if ssl_is_fatal_error(Error) then
        Exit;
    end;
  end;
end;

function TgoOpenSSL.ALPN: Boolean;
var
  ALPN: MarshaledAString;
  ALPNLen: Integer;
begin
  SSL_get0_alpn_selected(FSSL, ALPN, ALPNLen);
  Result := (ALPNLen = 2) and (ALPN[0] = 'h') and (ALPN[1] = '2');
end;

initialization
  TgoSSLHelper.LoadSSL;
  SSL_load_error_strings;
  SSL_library_init;
  _MemBufferPool := TgoMemoryPool.Create(DEFAULT_BLOCK_SIZE);

finalization
  TgoSSLHelper.UnloadSSL;
  _MemBufferPool.Free;

end.
