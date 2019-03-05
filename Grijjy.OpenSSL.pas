unit Grijjy.OpenSSL;

{ OpenSSL handler for Grijjy connections }

{$I Grijjy.inc}

interface

uses
  Grijjy.OpenSSL.API,
  System.SysUtils,
  Grijjy.MemoryPool;

const
  DEFAULT_BLOCK_SIZE = 4096;

type
  { Callback events }
  TgoOpenSSLNotify = procedure of object;
  TgoOpenSSLData = procedure(const ABuffer: Pointer; const ASize: Integer) of object;

  { OpenSSL protocol handler }
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

    { Hostname for SNI }
    FHost: String;
    FPort: Word;

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
    { Host }
    property Host: String read FHost write FHost;

    { Port }
    property Port: Word read FPort write FPort;

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

  { Helper class for SSL }
  TgoSSLHelper = class
  private class var
    FTarget: Integer;
  public
    class procedure LoadSSL;
    class procedure UnloadSSL;
    class procedure SetCertificate(ctx: PSSL_CTX; const ACertificate, APrivateKey: TBytes;
      const APassword: UnicodeString = ''); overload;
    class procedure SetCertificate(ctx: PSSL_CTX; const ACertificateFile, APrivateKeyFile: UnicodeString;
      const APassword: UnicodeString = ''); overload;
  public
    class function Sign_RSASHA256(const AData: TBytes; const APrivateKey: TBytes;
      out ASignature: TBytes): Boolean;
    class function HMAC_SHA256(const AKey, AData: RawByteString): String;
    class function HMAC_SHA1(const AKey, AData: RawByteString): TBytes;
  end;

implementation

uses
  System.IOUtils,
  System.SyncObjs,
  System.Classes;

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
      SetSSLCTXOptions(FSSLContext,
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
      { Apply SNI hostname }
      SSL_set_tlsext_host_name(FSSL, FHost);

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
    if not BIORetry(FBIORead) then
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
      if not SSLErrorFatal(Error) then
        Break
      else
        Exit;
    end;
  end;

  { handshake data needs to be written? }
  if BIO_ctrl(FBIOWrite, BIO_CTRL_PENDING, 0, nil) <> 0 then
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
      if SSLErrorFatal(Error) then
        Exit;
    end;
  end;

  { with ssl we are only connected and can write once the handshake is finished }
  if FHandshaking then
    if SSL_state(FSSL) = SSL_ST_OK then
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
    if SSLErrorFatal(Error) then
      Exit;
  end;

  while BIO_ctrl(FBIOWrite, BIO_CTRL_PENDING, 0, nil) <> 0 do
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
      if SSLErrorFatal(Error) then
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

{ TgoSSLHelper }

class procedure TgoSSLHelper.LoadSSL;
begin
  if (TInterlocked.Increment(FTarget) = 1) then
  begin
    LoadLIBEAY;
    LoadSSLEAY;
    SSLInitialize;
  end;
end;

class procedure TgoSSLHelper.UnloadSSL;
begin
  if (TInterlocked.Decrement(FTarget) = 0) then
  begin
    SSLFinalize;
    UnloadSSLEAY;
    UnloadLIBEAY;
  end;
end;

class procedure TgoSSLHelper.SetCertificate(ctx: PSSL_CTX; const ACertificate, APrivateKey: TBytes;
  const APassword: UnicodeString = '');
var
  BIOCert, BIOPrivateKey: PBIO;
  Certificate: PX509;
  PrivateKey: PEVP_PKEY;
  Password: RawByteString;
begin
	BIOCert := BIO_new_mem_buf(@ACertificate[0], Length(ACertificate));
	BIOPrivateKey := BIO_new_mem_buf(@APrivateKey[0], Length(APrivateKey));
	Certificate := PEM_read_bio_X509(BIOCert, nil, nil, nil);
  if APassword <> '' then
  begin
    Password := MarshaledAString(RawByteString(APassword));
	  PrivateKey := PEM_read_bio_PrivateKey(BIOPrivateKey, nil, nil, @Password[1]);
  end
  else
	  PrivateKey := PEM_read_bio_PrivateKey(BIOPrivateKey, nil, nil, nil);
	SSL_CTX_use_certificate(ctx, Certificate);
	SSL_CTX_use_privatekey(ctx, PrivateKey);
	X509_free(Certificate);
	EVP_PKEY_free(PrivateKey);
	BIO_free(BIOCert);
	BIO_free(BIOPrivateKey);
  if (SSL_CTX_check_private_key(ctx) = 0) then
    raise Exception.Create('Private key does not match the certificate public key');
end;

class procedure TgoSSLHelper.SetCertificate(ctx: PSSL_CTX; const ACertificateFile, APrivateKeyFile: UnicodeString;
  const APassword: UnicodeString = '');
var
  Certificate, PrivateKey: TBytes;
begin
  Certificate := TFile.ReadAllBytes(ACertificateFile);
  PrivateKey := TFile.ReadAllBytes(APrivateKeyFile);
  SetCertificate(ctx, Certificate, PrivateKey, APassword);
end;

class function TgoSSLHelper.Sign_RSASHA256(const AData: TBytes; const APrivateKey: TBytes;
  out ASignature: TBytes): Boolean;
var
  BIOPrivateKey: PBIO;
  PrivateKey: PEVP_PKEY;
  Ctx: PEVP_MD_CTX;
  SHA256: PEVP_MD;
  Size: Cardinal;
begin
	BIOPrivateKey := BIO_new_mem_buf(@APrivateKey[0], Length(APrivateKey));
  PrivateKey := PEM_read_bio_PrivateKey(BIOPrivateKey, nil, nil, nil);
  Ctx := EVP_MD_CTX_create;
  try
    SHA256 := EVP_sha256;
    if (EVP_DigestSignInit(Ctx, nil, SHA256, nil, PrivateKey) > 0) and
      (EVP_DigestUpdate(Ctx, @AData[0], Length(AData)) > 0) and
      (EVP_DigestSignFinal(Ctx, nil, Size) > 0) then
    begin
      SetLength(ASignature, Size);
      Result := EVP_DigestSignFinal(Ctx, @ASignature[0], Size) > 0;
    end
    else
      Result := False;
  finally
    EVP_MD_CTX_destroy(Ctx);
  end;
end;

class function TgoSSLHelper.HMAC_SHA256(const AKey, AData: RawByteString): String;
const
  EVP_MAX_MD_SIZE = 64;
var
  MessageAuthCode: PByte;
  Size: Integer;
  Buffer, Text: TBytes;
begin
  Size := EVP_MAX_MD_SIZE;
  SetLength(Buffer, Size);
  MessageAuthCode := HMAC(EVP_sha256, @AKey[1], Length(AKey), @AData[1], Length(AData), @Buffer[0], Size);
  if MessageAuthCode <> nil then
  begin
    SetLength(Text, Size * 2);
    BinToHex(Buffer, 0, Text, 0, Size);
    Result := TEncoding.UTF8.GetString(Text).ToLower;
  end;
end;

class function TgoSSLHelper.HMAC_SHA1(const AKey, AData: RawByteString): TBytes;
const
  EVP_MAX_MD_SIZE = 20;
var
  MessageAuthCode: PByte;
  Size: Integer;
begin
  Size := EVP_MAX_MD_SIZE;
  SetLength(Result, Size);
  MessageAuthCode := HMAC(EVP_sha1, @AKey[1], Length(AKey), @AData[1], Length(AData), @Result[0], Size);
  if MessageAuthCode <> nil then
    SetLength(Result, Size);
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