unit Grijjy.OpenSSL.API;

{ Provides an interface to OpenSSL }

{$I Grijjy.inc}

interface

uses
  System.Classes,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF FPC}
  dynlibs,
  {$ENDIF}
  System.SyncObjs,
  System.SysUtils;

const
  {$IFNDEF MSWINDOWS}
  SSLEAY_DLL = 'libssl.so.1.0.0';
  LIBEAY_DLL = 'libcrypto.so.1.0.0';
  {$ELSE}
  SSLEAY_DLL = 'ssleay32.dll';
  LIBEAY_DLL = 'libeay32.dll';
  {$ENDIF}

const
  SSL_ERROR_NONE = 0;
  SSL_ERROR_SSL = 1;
  SSL_ERROR_WANT_READ = 2;
  SSL_ERROR_WANT_WRITE = 3;
  SSL_ERROR_WANT_X509_LOOKUP = 4;
  SSL_ERROR_SYSCALL = 5;
  SSL_ERROR_ZERO_RETURN = 6;
  SSL_ERROR_WANT_CONNECT = 7;
  SSL_ERROR_WANT_ACCEPT = 8;

  SSL_ST_CONNECT = $1000;
  SSL_ST_ACCEPT = $2000;
  SSL_ST_MASK = $0FFF;
  SSL_ST_INIT = (SSL_ST_CONNECT or SSL_ST_ACCEPT);
  SSL_ST_BEFORE = $4000;
  SSL_ST_OK = $03;
  SSL_ST_RENEGOTIATE = ($04 or SSL_ST_INIT);

  SSL_OP_ALL = $000FFFFF;
  SSL_OP_NO_SSLv2 = $01000000;
  SSL_OP_NO_SSLv3 = $02000000;
  SSL_OP_NO_COMPRESSION = $00020000;

  SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS = $00000800;

  BIO_CTRL_INFO = 3;
  BIO_CTRL_PENDING = 10;
  SSL_VERIFY_NONE = $00;

  CRYPTO_LOCK = 1;
  CRYPTO_UNLOCK = 2;
  CRYPTO_READ = 4;
  CRYPTO_WRITE = 8;

  BIO_FLAGS_READ = 1;
  BIO_FLAGS_WRITE = 2;
  BIO_FLAGS_IO_SPECIAL = 4;
  BIO_FLAGS_RWS = (BIO_FLAGS_READ or BIO_FLAGS_WRITE or BIO_FLAGS_IO_SPECIAL);
  BIO_FLAGS_SHOULD_RETRY = 8;
  BIO_NOCLOSE = 0;
  BIO_CLOSE = 1;

type
  size_t = NativeUInt;

  TSSL_METHOD = packed record
  end;
  PSSL_METHOD = ^TSSL_METHOD;

  TSSL_CTX = packed record
  end;
  PSSL_CTX = ^TSSL_CTX;

  TBIO = packed record
  end;
  PBIO = ^TBIO;
  PPBIO = ^PBIO;

  TSSL = packed record
  end;
  PSSL = ^TSSL;

  TX509_STORE = packed record
  end;
  PX509_STORE = ^TX509_STORE;

  TEVP_PKEY = packed record
  end;
  PEVP_PKEY = ^TEVP_PKEY;
  PPEVP_PKEY = ^PEVP_PKEY;
  PEVP_PKEY_CTX = Pointer;

  PEVP_MD_CTX = Pointer;
  PEVP_MD = Pointer;

  ENGINE = Pointer;

  TX509 = packed record
  end;
  PX509 = ^TX509;
  PPX509 = ^PX509;

  TASN1_STRING = record
    length: Integer;
    type_: Integer;
    data: PAnsiChar;
    flags: Longword;
  end;
  PASN1_STRING = ^TASN1_STRING;
  TASN1_OCTET_STRING = TASN1_STRING;
  PASN1_OCTET_STRING = ^TASN1_OCTET_STRING;
  TASN1_BIT_STRING = TASN1_STRING;
  PASN1_BIT_STRING = ^TASN1_BIT_STRING;

  TSetVerify_cb = function(Ok: Integer; StoreCtx: PX509_STORE): Integer; cdecl;

  TCRYPTO_THREADID = packed record
  end;
  PCRYPTO_THREADID = ^TCRYPTO_THREADID;

  TCRYPTO_dynlock_value = record
    Mutex: TCriticalSection;
  end;
  PCRYPTO_dynlock_value = ^TCRYPTO_dynlock_value;
  CRYPTO_dynlock_value  = TCRYPTO_dynlock_value;

  TBIO_METHOD = packed record
  end;
  PBIO_METHOD = ^TBIO_METHOD;

  TX509_NAME = packed record
  end;
  PX509_NAME = ^TX509_NAME;

  TSTACK = packed record
  end;
  PSTACK = ^TSTACK;

  TASN1_OBJECT = packed record
  end;
  PASN1_OBJECT = ^TASN1_OBJECT;

  TStatLockLockCallback = procedure(Mode: Integer; N: Integer; const _File: PAnsiChar; Line: Integer); cdecl;
  TStatLockIDCallback = function: Longword; cdecl;
  TCryptoThreadIDCallback = procedure(ID: PCRYPTO_THREADID) cdecl;

  TDynLockCreateCallback = function(const _file: PAnsiChar; Line: Integer): PCRYPTO_dynlock_value; cdecl;
  TDynLockLockCallback = procedure(Mode: Integer; L: PCRYPTO_dynlock_value; _File: PAnsiChar; Line: Integer); cdecl;
  TDynLockDestroyCallback = procedure(L: PCRYPTO_dynlock_value; _File: PAnsiChar; Line: Integer); cdecl;
  pem_password_cb = function(buf: Pointer; size: Integer; rwflag: Integer; userdata: Pointer): Integer; cdecl;

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
  end;

var
  SSL_library_init: function: Integer; cdecl = nil;
  SSL_load_error_strings: procedure; cdecl = nil;
  SSLv3_method: function: PSSL_METHOD; cdecl = nil;
  SSLv23_method: function: PSSL_METHOD; cdecl = nil;
  TLSv1_method: function: PSSL_METHOD; cdecl = nil;
  TLSv1_1_method: function: PSSL_METHOD; cdecl = nil;
  SSL_CTX_new: function(meth: PSSL_METHOD): PSSL_CTX; cdecl = nil;
  SSL_CTX_free: procedure(ctx: PSSL_CTX); cdecl = nil;
  SSL_CTX_set_verify: procedure(ctx: PSSL_CTX; mode: Integer; callback: TSetVerify_cb); cdecl = nil;
  SSL_CTX_use_PrivateKey: function(ctx: PSSL_CTX; pkey: PEVP_PKEY): Integer; cdecl = nil;
  SSL_CTX_use_RSAPrivateKey: function(ctx: PSSL_CTX; pkey: PEVP_PKEY): Integer; cdecl = nil;
  SSL_CTX_use_certificate: function(ctx: PSSL_CTX; x: PX509): Integer; cdecl = nil;
  SSL_CTX_check_private_key: function(ctx: PSSL_CTX): Integer; cdecl = nil;
  SSL_CTX_use_certificate_file: function(ctx: PSSL_CTX; f: PAnsiChar; t: Integer): Integer; cdecl = nil;
  SSL_CTX_use_RSAPrivateKey_file: function(ctx: PSSL_CTX; f: PAnsiChar; t: Integer): Integer; cdecl = nil;
  SSL_CTX_get_cert_store: function(ctx: PSSL_CTX): PX509_STORE; cdecl = nil;
  SSL_CTX_ctrl: function(ctx: PSSL_CTX; cmd, i: integer; p: pointer): Integer; cdecl = nil;
  SSL_CTX_load_verify_locations: function(ctx: PSSL_CTX; CAFile: PAnsiChar; CAPath: PAnsiChar): Integer; cdecl = nil;
  SSL_CTX_use_certificate_chain_file: function(ctx: PSSL_CTX; CAFile: PAnsiChar): Integer; cdecl = nil;
  SSL_CTX_set_alpn_protos: function(ctx: PSSL_CTX; protos: PAnsiChar; protos_len: Integer): Integer; cdecl = nil;
  SSL_new: function(ctx: PSSL_CTX): PSSL; cdecl = nil;
  SSL_set_bio: procedure(s: PSSL; rbio, wbio: PBIO); cdecl = nil;
  SSL_get_peer_certificate: function(s: PSSL): PX509; cdecl = nil;
  SSL_get_error: function(s: PSSL; ret_code: Integer): Integer; cdecl = nil;
  SSL_shutdown: function(s: PSSL): Integer; cdecl = nil;
  SSL_free: procedure(s: PSSL); cdecl = nil;
  SSL_connect: function(s: PSSL): Integer; cdecl = nil;
  SSL_set_connect_state: procedure(s: PSSL); cdecl = nil;
  SSL_set_accept_state: procedure(s: PSSL); cdecl = nil;
  SSL_read: function(s: PSSL; buf: Pointer; num: Integer): Integer; cdecl = nil;
  SSL_write: function(s: PSSL; const buf: Pointer; num: Integer): Integer; cdecl = nil;
  SSL_state: function(s: PSSL): Integer; cdecl = nil;
  SSL_pending: function(s: PSSL): Integer; cdecl = nil;
  SSL_set_cipher_list: function(s: PSSL; ciphers: PAnsiChar): Integer; cdecl = nil;
  SSL_get0_alpn_selected: procedure (s: PSSL; out data: PAnsiChar; out len: Integer); cdecl = nil;
  SSL_clear: function(s: PSSL): Integer; cdecl = nil;
  CRYPTO_num_locks: function: Integer; cdecl = nil;
  CRYPTO_set_locking_callback: procedure(callback: TStatLockLockCallback); cdecl = nil;
  CRYPTO_set_dynlock_create_callback: procedure(callback: TDynLockCreateCallBack); cdecl = nil;
  CRYPTO_set_dynlock_lock_callback: procedure(callback: TDynLockLockCallBack); cdecl = nil;
  CRYPTO_set_dynlock_destroy_callback: procedure(callback: TDynLockDestroyCallBack); cdecl = nil;
  CRYPTO_cleanup_all_ex_data: procedure; cdecl = nil;
  ERR_remove_state: procedure(tid: Cardinal); cdecl = nil;
  ERR_free_strings: procedure; cdecl = nil; // thread-unsafe, Application-global cleanup functions
  ERR_error_string_n: procedure(err: Cardinal; buf: PAnsiChar; len: size_t); cdecl = nil;
  ERR_get_error: function: Cardinal; cdecl = nil;
  ERR_remove_thread_state: procedure(pid: Cardinal); cdecl = nil;
  ERR_load_BIO_strings: function: Cardinal; cdecl = nil;
  EVP_cleanup: procedure; cdecl = nil;
  EVP_PKEY_free: procedure(pkey: PEVP_PKEY); cdecl = nil;
  BIO_new: function(BioMethods: PBIO_METHOD): PBIO; cdecl = nil;
  BIO_ctrl: function(bp: PBIO; cmd: Integer; larg: Longint; parg: Pointer): Longint; cdecl = nil;
  BIO_new_mem_buf: function(buf: Pointer; len: Integer): PBIO; cdecl = nil;
  BIO_free: function(b: PBIO): Integer; cdecl = nil;
  BIO_s_mem: function: PBIO_METHOD; cdecl = nil;
  BIO_read: function(b: PBIO; Buf: Pointer; Len: Integer): Integer; cdecl = nil;
  BIO_write: function(b: PBIO; Buf: Pointer; Len: Integer): Integer; cdecl = nil;
  BIO_new_socket: function(sock: Integer; close_flag: Integer): PBIO; cdecl = nil;
  X509_get_issuer_name: function(cert: PX509): PX509_NAME; cdecl = nil;
  X509_get_subject_name: function(cert: PX509): PX509_NAME; cdecl = nil;
  X509_free: procedure(cert: PX509); cdecl = nil;
  X509_NAME_print_ex: function(bout: PBIO; nm: PX509_NAME; indent: Integer; flags: Cardinal): Integer; cdecl = nil;
  sk_num: function(stack: PSTACK): Integer; cdecl = nil;
  sk_pop: function(stack: PSTACK): Pointer; cdecl = nil;
  ASN1_BIT_STRING_get_bit: function(a: PASN1_BIT_STRING; n: Integer): Integer; cdecl = nil;
  OBJ_obj2nid: function(o: PASN1_OBJECT): Integer; cdecl = nil;
  OBJ_nid2sn: function(n: Integer): PAnsiChar; cdecl = nil;
  ASN1_STRING_data: function(x: PASN1_STRING): Pointer; cdecl = nil;
  PEM_read_bio_X509: function(bp: PBIO; x: PX509; cb: pem_password_cb; u: Pointer): PX509; cdecl = nil;
  PEM_read_bio_PrivateKey: function(bp: PBIO; x: PPEVP_PKEY; cb: pem_password_cb; u: Pointer): PEVP_PKEY; cdecl = nil;
  PEM_read_bio_RSAPrivateKey: function(bp: PBIO; x: PPEVP_PKEY; cb: pem_password_cb; u: Pointer): PEVP_PKEY; cdecl = nil;
  EVP_MD_CTX_create: function: PEVP_MD_CTX; cdecl = nil;
  EVP_MD_CTX_destroy: procedure(ctx: PEVP_MD_CTX); cdecl = nil;
  EVP_sha256: function: PEVP_MD; cdecl = nil;
  EVP_PKEY_size: function(key: PEVP_PKEY): Integer; cdecl = nil;
  EVP_DigestSignInit: function(aCtx: PEVP_MD_CTX; aPCtx: PEVP_PKEY_CTX; aType: PEVP_MD; aEngine: ENGINE; aKey: PEVP_PKEY): Integer; cdecl = nil;
  EVP_DigestUpdate: function(ctx: PEVP_MD_CTX; const d: Pointer; cnt: Cardinal): Integer; cdecl = nil;
  EVP_DigestSignFinal: function(ctx : PEVP_MD_CTX; const d: PByte; var cnt: Cardinal): Integer; cdecl = nil;
  EVP_DigestVerifyInit: function(aCtx: PEVP_MD_CTX; aPCtx: PEVP_PKEY_CTX; aType: PEVP_MD; aEngine: ENGINE; aKey: pEVP_PKEY): Integer; cdecl = nil;
  EVP_DigestVerifyFinal: function(ctx : pEVP_MD_CTX; const d: PByte; cnt: Cardinal) : Integer; cdecl = nil;
  CRYPTO_malloc: function(aLength : LongInt; const f : PAnsiChar; aLine : Integer): Pointer; cdecl= nil;
  CRYPTO_free: procedure(str: Pointer); cdecl= nil;

function BIO_pending(bp: PBIO): Integer; inline;
function BIO_get_mem_data(bp: PBIO; parg: Pointer): Integer; inline;
function BIO_get_flags(b: PBIO): Integer; inline;
function BIO_should_retry(b: PBIO): Boolean; inline;

function SSL_CTX_set_options(ctx: pointer; op: integer): integer;

function SSL_is_init_finished(s: PSSL): Boolean; inline;

function SSL_is_fatal_error(ssl_error: Integer): Boolean;
function SSL_error(ssl: PSSL; ret_code: Integer; out AErrorMsg: UnicodeString): Integer;

function sk_ASN1_OBJECT_num(stack: PSTACK): Integer; inline;
function sk_GENERAL_NAME_num(stack: PSTACK): Integer; inline;
function sk_GENERAL_NAME_pop(stack: PSTACK): Pointer; inline;

implementation

uses
  System.IOUtils;

var
  _SSLEAYHandle, _LIBEAYHandle: HMODULE;
  _FSSLLocks: TArray<TCriticalSection>;

function BIO_pending(bp: PBIO): Integer;
begin
  Result := BIO_ctrl(bp, BIO_CTRL_PENDING, 0, nil);
end;

function BIO_get_mem_data(bp: PBIO; parg: Pointer): Integer;
begin
  Result := BIO_ctrl(bp, BIO_CTRL_INFO, 0, parg);
end;

function sk_ASN1_OBJECT_num(stack: PSTACK): Integer;
begin
  Result := sk_num(stack);
end;

function sk_GENERAL_NAME_num(stack: PSTACK): Integer;
begin
  Result := sk_num(stack);
end;

function sk_GENERAL_NAME_pop(stack: PSTACK): Pointer;
begin
  Result := sk_pop(stack);
end;

function BIO_get_flags(b: PBIO): Integer;
begin
  Result := PInteger(PAnsiChar(b) + 3 * SizeOf(Pointer) + 2 * SizeOf(Integer))^;
end;

function BIO_should_retry(b: PBIO): Boolean;
begin
  Result := ((BIO_get_flags(b) and BIO_FLAGS_SHOULD_RETRY) <> 0);
end;

function SSL_CTX_set_options(ctx: pointer; op: integer): integer;
const
  SSL_CTRL_OPTIONS = 32;
begin
  result := SSL_CTX_ctrl(ctx, SSL_CTRL_OPTIONS, op, nil);
end;

function SSL_is_init_finished(s: PSSL): Boolean; inline;
begin
  Result := (SSL_state(s) = SSL_ST_OK);
end;

function SSL_is_fatal_error(ssl_error: Integer): Boolean;
begin
	case ssl_error of
		SSL_ERROR_NONE,
		SSL_ERROR_WANT_READ,
		SSL_ERROR_WANT_WRITE,
		SSL_ERROR_WANT_CONNECT,
		SSL_ERROR_WANT_ACCEPT: Result := False;
  else
    Result := True;
	end;
end;

function SSL_error(ssl: PSSL; ret_code: Integer; out AErrorMsg: UnicodeString): Integer;
var
  error, error_log: Integer;
  ErrorBuf: TBytes;
begin
	error := SSL_get_error(ssl, ret_code);
	if(error <> SSL_ERROR_NONE) then
	begin
		error_log := error;
		while (error_log <> SSL_ERROR_NONE) do
    begin
      SetLength(ErrorBuf, 512);
			ERR_error_string_n(error_log, @ErrorBuf[0], Length(ErrorBuf));
			if (SSL_is_fatal_error(error_log)) then
        AErrorMsg := StringOf(ErrorBuf);
			error_log := ERR_get_error();
		end;
	end;
	Result := error;
end;

function LoadLib(const ALibFile: String): HMODULE;
begin
  Result := LoadLibrary(PChar(ALibFile));
  if (Result = 0) then
    raise Exception.CreateFmt('load %s failed', [ALibFile]);
end;

function FreeLib(ALibModule: HMODULE): Boolean;
begin
  Result := FreeLibrary(ALibModule);
end;

function GetProc(AModule: HMODULE; const AProcName: String): Pointer;
begin
  Result := GetProcAddress(AModule, PChar(AProcName));
  if (Result = nil) then
    raise Exception.CreateFmt('%s is not found', [AProcName]);
end;

procedure LoadSSLEAY;
begin
  if (_SSLEAYHandle <> 0) then Exit;
  _SSLEAYHandle := LoadLib(SSLEAY_DLL);
  if (_SSLEAYHandle = 0) then
  begin
    raise Exception.CreateFmt('Load %s failed', [SSLEAY_DLL]);
    Exit;
  end;

  SSL_library_init := GetProc(_SSLEAYHandle, 'SSL_library_init');
  SSL_load_error_strings := GetProc(_SSLEAYHandle, 'SSL_load_error_strings');
  SSLv3_method := GetProc(_SSLEAYHandle, 'SSLv3_method');
  SSLv23_method := GetProc(_SSLEAYHandle, 'SSLv23_method');
  TLSv1_method := GetProc(_SSLEAYHandle, 'TLSv1_method');
  TLSv1_1_method := GetProc(_SSLEAYHandle, 'TLSv1_1_method');
  SSL_CTX_new := GetProc(_SSLEAYHandle, 'SSL_CTX_new');
  SSL_CTX_free := GetProc(_SSLEAYHandle, 'SSL_CTX_free');
  SSL_CTX_set_verify := GetProc(_SSLEAYHandle, 'SSL_CTX_set_verify');
  SSL_CTX_use_PrivateKey := GetProc(_SSLEAYHandle, 'SSL_CTX_use_PrivateKey');
  SSL_CTX_use_RSAPrivateKey := GetProc(_SSLEAYHandle, 'SSL_CTX_use_RSAPrivateKey');
  SSL_CTX_use_certificate := GetProc(_SSLEAYHandle, 'SSL_CTX_use_certificate');
  SSL_CTX_check_private_key := GetProc(_SSLEAYHandle, 'SSL_CTX_check_private_key');
  SSL_CTX_use_certificate_file := GetProc(_SSLEAYHandle, 'SSL_CTX_use_certificate_file');
  SSL_CTX_use_RSAPrivateKey_file := GetProc(_SSLEAYHandle, 'SSL_CTX_use_RSAPrivateKey_file');
  SSL_CTX_get_cert_store := GetProc(_SSLEAYHandle, 'SSL_CTX_get_cert_store');
  SSL_CTX_ctrl := GetProc(_SSLEAYHandle, 'SSL_CTX_ctrl');
  SSL_CTX_load_verify_locations := GetProc(_SSLEAYHandle, 'SSL_CTX_load_verify_locations');
  SSL_CTX_use_certificate_chain_file := GetProc(_SSLEAYHandle, 'SSL_CTX_use_certificate_chain_file');
  SSL_CTX_set_alpn_protos := GetProc(_SSLEAYHandle, 'SSL_CTX_set_alpn_protos');
  SSL_new := GetProc(_SSLEAYHandle, 'SSL_new');
  SSL_set_bio := GetProc(_SSLEAYHandle, 'SSL_set_bio');
  SSL_get_peer_certificate := GetProc(_SSLEAYHandle, 'SSL_get_peer_certificate');
  SSL_get_error := GetProc(_SSLEAYHandle, 'SSL_get_error');
  SSL_shutdown := GetProc(_SSLEAYHandle, 'SSL_shutdown');
  SSL_free := GetProc(_SSLEAYHandle, 'SSL_free');
  SSL_connect := GetProc(_SSLEAYHandle, 'SSL_connect');
  SSL_set_connect_state := GetProc(_SSLEAYHandle, 'SSL_set_connect_state');
  SSL_set_accept_state := GetProc(_SSLEAYHandle, 'SSL_set_accept_state');
  SSL_read := GetProc(_SSLEAYHandle, 'SSL_read');
  SSL_write := GetProc(_SSLEAYHandle, 'SSL_write');
  SSL_state := GetProc(_SSLEAYHandle, 'SSL_state');
  SSL_pending := GetProc(_SSLEAYHandle, 'SSL_pending');
  SSL_set_cipher_list := GetProc(_SSLEAYHandle, 'SSL_set_cipher_list');
  SSL_get0_alpn_selected := GetProc(_SSLEAYHandle, 'SSL_get0_alpn_selected');
  SSL_clear := GetProc(_SSLEAYHandle, 'SSL_clear');
end;

procedure UnloadSSLEAY;
begin
  if (_SSLEAYHandle = 0) then Exit;
  FreeLib(_SSLEAYHandle);
  _SSLEAYHandle := 0;
end;

procedure LoadLIBEAY;
begin
  if (_LIBEAYHandle <> 0) then Exit;
  _LIBEAYHandle := LoadLib(LIBEAY_DLL);
  if (_LIBEAYHandle = 0) then
  begin
    raise Exception.CreateFmt('Load %s failed', [LIBEAY_DLL]);
    Exit;
  end;

  CRYPTO_malloc := GetProc(_LIBEAYHandle, 'CRYPTO_malloc');
  CRYPTO_free := GetProc(_LIBEAYHandle, 'CRYPTO_free');
  CRYPTO_num_locks := GetProc(_LIBEAYHandle, 'CRYPTO_num_locks');
  CRYPTO_set_locking_callback := GetProc(_LIBEAYHandle, 'CRYPTO_set_locking_callback');
  CRYPTO_set_dynlock_create_callback := GetProc(_LIBEAYHandle, 'CRYPTO_set_dynlock_create_callback');
  CRYPTO_set_dynlock_lock_callback := GetProc(_LIBEAYHandle, 'CRYPTO_set_dynlock_lock_callback');
  CRYPTO_set_dynlock_destroy_callback := GetProc(_LIBEAYHandle, 'CRYPTO_set_dynlock_destroy_callback');
  CRYPTO_cleanup_all_ex_data := GetProc(_LIBEAYHandle, 'CRYPTO_cleanup_all_ex_data');
  ERR_remove_state := GetProc(_LIBEAYHandle, 'ERR_remove_state');
  ERR_free_strings := GetProc(_LIBEAYHandle, 'ERR_free_strings');
  ERR_error_string_n := GetProc(_LIBEAYHandle, 'ERR_error_string_n');
  ERR_get_error := GetProc(_LIBEAYHandle, 'ERR_get_error');
  ERR_remove_thread_state := GetProc(_LIBEAYHandle, 'ERR_remove_thread_state');
  ERR_load_BIO_strings := GetProc(_LIBEAYHandle, 'ERR_load_BIO_strings');
  EVP_cleanup := GetProc(_LIBEAYHandle, 'EVP_cleanup');
  EVP_MD_CTX_create := GetProc(_LIBEAYHandle, 'EVP_MD_CTX_create');
  EVP_MD_CTX_destroy := GetProc(_LIBEAYHandle, 'EVP_MD_CTX_destroy');
  EVP_sha256 := GetProc(_LIBEAYHandle, 'EVP_sha256');
  EVP_PKEY_size := GetProc(_LIBEAYHandle, 'EVP_PKEY_size');
  EVP_DigestSignInit := GetProc(_LIBEAYHandle, 'EVP_DigestSignInit');
  EVP_DigestUpdate := GetProc(_LIBEAYHandle, 'EVP_DigestUpdate');
  EVP_DigestSignFinal := GetProc(_LIBEAYHandle, 'EVP_DigestSignFinal');
  EVP_DigestVerifyInit := GetProc(_LIBEAYHandle, 'EVP_DigestVerifyInit');
  EVP_DigestVerifyFinal := GetProc(_LIBEAYHandle, 'EVP_DigestVerifyFinal');
  EVP_PKEY_free := GetProc(_LIBEAYHandle, 'EVP_PKEY_free');
  BIO_new := GetProc(_LIBEAYHandle, 'BIO_new');
  BIO_ctrl := GetProc(_LIBEAYHandle, 'BIO_ctrl');
  BIO_new_mem_buf := GetProc(_LIBEAYHandle, 'BIO_new_mem_buf');
  BIO_free := GetProc(_LIBEAYHandle, 'BIO_free');
  BIO_s_mem := GetProc(_LIBEAYHandle, 'BIO_s_mem');
  BIO_read := GetProc(_LIBEAYHandle, 'BIO_read');
  BIO_write := GetProc(_LIBEAYHandle, 'BIO_write');
  BIO_new_socket := GetProc(_LIBEAYHandle, 'BIO_new_socket');
  X509_get_issuer_name := GetProc(_LIBEAYHandle, 'X509_get_issuer_name');
  X509_get_subject_name := GetProc(_LIBEAYHandle, 'X509_get_subject_name');
  X509_free := GetProc(_LIBEAYHandle, 'X509_free');
  X509_NAME_print_ex := GetProc(_LIBEAYHandle, 'X509_NAME_print_ex');
  sk_num := GetProc(_LIBEAYHandle, 'sk_num');
  sk_pop := GetProc(_LIBEAYHandle, 'sk_pop');
  ASN1_BIT_STRING_get_bit := GetProc(_LIBEAYHandle, 'ASN1_BIT_STRING_get_bit');
  OBJ_obj2nid := GetProc(_LIBEAYHandle, 'OBJ_obj2nid');
  OBJ_nid2sn := GetProc(_LIBEAYHandle, 'OBJ_nid2sn');
  ASN1_STRING_data := GetProc(_LIBEAYHandle, 'ASN1_STRING_data');
  PEM_read_bio_X509 := GetProc(_LIBEAYHandle, 'PEM_read_bio_X509');
  PEM_read_bio_PrivateKey := GetProc(_LIBEAYHandle, 'PEM_read_bio_PrivateKey');
  PEM_read_bio_RSAPrivateKey := GetProc(_LIBEAYHandle, 'PEM_read_bio_RSAPrivateKey');
end;

procedure UnloadLIBEAY;
begin
  if (_LIBEAYHandle = 0) then Exit;
  FreeLib(_LIBEAYHandle);
  _LIBEAYHandle := 0;
end;

procedure ssl_lock_callback(Mode, N: Integer; const _File: PAnsiChar; Line: Integer); cdecl;
begin
	if(mode and CRYPTO_LOCK <> 0) then
    _FSSLLocks[N].Enter
	else
    _FSSLLocks[N].Leave;
end;

procedure ssl_lock_dyn_callback(Mode: Integer; L: PCRYPTO_dynlock_value; _File: PAnsiChar; Line: Integer); cdecl;
begin
  if (Mode and CRYPTO_LOCK <> 0) then
    L.Mutex.Enter
  else
    L.Mutex.Leave;
end;

function ssl_lock_dyn_create_callback(const _file: PAnsiChar; Line: Integer): PCRYPTO_dynlock_value; cdecl;
begin
  New(Result);
  Result.Mutex := TCriticalSection.Create;
end;

procedure ssl_lock_dyn_destroy_callback(L: PCRYPTO_dynlock_value; _File: PAnsiChar; Line: Integer); cdecl;
begin
  L.Mutex.Free;
  Dispose(L);
end;

procedure SslInit;
var
  LNumberOfLocks, I: Integer;
begin
  if (_SSLEAYHandle = 0) or (_LIBEAYHandle = 0) then Exit;

  LNumberOfLocks := CRYPTO_num_locks();
	if(LNumberOfLocks > 0) then
  begin
    SetLength(_FSSLLocks, LNumberOfLocks);
    for I := Low(_FSSLLocks) to High(_FSSLLocks) do
      _FSSLLocks[I] := TCriticalSection.Create;
	end;

	CRYPTO_set_locking_callback(ssl_lock_callback);
  CRYPTO_set_dynlock_create_callback(ssl_lock_dyn_create_callback);
	CRYPTO_set_dynlock_lock_callback(ssl_lock_dyn_callback);
  CRYPTO_set_dynlock_destroy_callback(ssl_lock_dyn_destroy_callback);

  SSL_load_error_strings();
  SSL_library_init();
end;

procedure SslUninit;
var
  I: Integer;
begin
  if (_SSLEAYHandle = 0) or (_LIBEAYHandle = 0) then Exit;

	CRYPTO_set_locking_callback(nil);
	CRYPTO_set_dynlock_create_callback(nil);
	CRYPTO_set_dynlock_lock_callback(nil);
	CRYPTO_set_dynlock_destroy_callback(nil);

  EVP_cleanup();
  CRYPTO_cleanup_all_ex_data();
  ERR_remove_state(0);
  ERR_free_strings();

  for I := Low(_FSSLLocks) to High(_FSSLLocks) do
    _FSSLLocks[I].Free;
  _FSSLLocks := nil;
end;

{ TgoSSLHelper }

class procedure TgoSSLHelper.LoadSSL;
begin
  {$IFDEF FPC}
  if (InterlockedIncrement(FTarget) = 1) then
  {$ELSE}
  if (TInterlocked.Increment(FTarget) = 1) then
  {$ENDIF}
  begin
    LoadLIBEAY;
    LoadSSLEAY;
    SslInit;
  end;
end;

class procedure TgoSSLHelper.UnloadSSL;
begin
  {$IFDEF FPC}
  if (InterlockedDecrement(FTarget) = 0) then
  {$ELSE}
  if (TInterlocked.Decrement(FTarget) = 0) then
  {$ENDIF}
  begin
    SslUninit;
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
  Password: AnsiString;
begin
	BIOCert := BIO_new_mem_buf(@ACertificate[0], Length(ACertificate));
	BIOPrivateKey := BIO_new_mem_buf(@APrivateKey[0], Length(APrivateKey));
	Certificate := PEM_read_bio_X509(BIOCert, nil, nil, nil);
  if APassword <> '' then
  begin
    Password := MarshaledAString({$IFNDEF FPC}TMarshal.AsAnsi{$ELSE}AnsiString{$ENDIF}(APassword));
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
    if (EVP_DigestSignInit(Ctx, nil , SHA256, nil, PrivateKey) > 0) and
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

end.
