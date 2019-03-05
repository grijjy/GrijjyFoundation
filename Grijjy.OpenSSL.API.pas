unit Grijjy.OpenSSL.API;

{ Provides an interface to OpenSSL }

{$I Grijjy.inc}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  System.Classes,
  System.SyncObjs,
  System.SysUtils;

const
  {$IFDEF LINUX}
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

  SSL_ST_OK = 3;
  SSL_VERIFY_NONE = 0;

  SSL_OP_ALL = $000FFFFF;
  SSL_OP_NO_SSLv2 = $01000000;
  SSL_OP_NO_SSLv3 = $02000000;
  SSL_OP_NO_COMPRESSION = $00020000;

  BIO_CTRL_INFO = 3;
  BIO_CTRL_PENDING = 10;

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
  PSSL_METHOD = Pointer;
  PSSL_CTX = Pointer;
  PBIO = Pointer;
  PSSL = Pointer;
  PX509_STORE = Pointer;
  PEVP_PKEY = Pointer;
  PPEVP_PKEY = ^PEVP_PKEY;
  PEVP_PKEY_CTX = Pointer;
  PEVP_MD_CTX = Pointer;
  PEVP_MD = Pointer;
  PENGINE = Pointer;
  PX509 = Pointer;
  PPX509 = ^PX509;

  TASN1_STRING = record
    length: Integer;
    type_: Integer;
    data: MarshaledAString;
    flags: Longword;
  end;
  PASN1_STRING = ^TASN1_STRING;
  TASN1_BIT_STRING = TASN1_STRING;
  PASN1_BIT_STRING = ^TASN1_BIT_STRING;

  TSetVerify_cb = function(Ok: Integer; StoreCtx: PX509_STORE): Integer; cdecl;

  TCRYPTO_dynlock_value = record
    Mutex: TCriticalSection;
  end;
  PCRYPTO_dynlock_value = ^TCRYPTO_dynlock_value;

  PBIO_METHOD = Pointer;
  PX509_NAME = Pointer;
  PSTACK = Pointer;
  PASN1_OBJECT = Pointer;

  TStatLockLockCallback = procedure(Mode: Integer; N: Integer; const _File: MarshaledAString; Line: Integer); cdecl;
  TDynLockCreateCallback = function(const _file: MarshaledAString; Line: Integer): PCRYPTO_dynlock_value; cdecl;
  TDynLockLockCallback = procedure(Mode: Integer; L: PCRYPTO_dynlock_value; _File: MarshaledAString; Line: Integer); cdecl;
  TDynLockDestroyCallback = procedure(L: PCRYPTO_dynlock_value; _File: MarshaledAString; Line: Integer); cdecl;
  TPemPasswordCallback = function(buf: Pointer; size: Integer; rwflag: Integer; userdata: Pointer): Integer; cdecl;

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
  SSL_CTX_use_certificate_file: function(ctx: PSSL_CTX; f: MarshaledAString; t: Integer): Integer; cdecl = nil;
  SSL_CTX_use_RSAPrivateKey_file: function(ctx: PSSL_CTX; f: MarshaledAString; t: Integer): Integer; cdecl = nil;
  SSL_CTX_get_cert_store: function(ctx: PSSL_CTX): PX509_STORE; cdecl = nil;
  SSL_CTX_ctrl: function(ctx: PSSL_CTX; cmd, i: integer; p: pointer): Integer; cdecl = nil;
  SSL_CTX_load_verify_locations: function(ctx: PSSL_CTX; CAFile: MarshaledAString; CAPath: MarshaledAString): Integer; cdecl = nil;
  SSL_CTX_use_certificate_chain_file: function(ctx: PSSL_CTX; CAFile: MarshaledAString): Integer; cdecl = nil;
  SSL_CTX_set_alpn_protos: function(ctx: PSSL_CTX; protos: MarshaledAString; protos_len: Integer): Integer; cdecl = nil;
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
  SSL_set_cipher_list: function(s: PSSL; ciphers: MarshaledAString): Integer; cdecl = nil;
  SSL_get0_alpn_selected: procedure (s: PSSL; out data: MarshaledAString; out len: Integer); cdecl = nil;
  SSL_clear: function(s: PSSL): Integer; cdecl = nil;
  SSL_ctrl: function(s: PSSL; cmd: Integer; larg: LongInt; parg: Pointer): Integer; cdecl = nil;
  CRYPTO_num_locks: function: Integer; cdecl = nil;
  CRYPTO_set_locking_callback: procedure(callback: TStatLockLockCallback); cdecl = nil;
  CRYPTO_set_dynlock_create_callback: procedure(callback: TDynLockCreateCallBack); cdecl = nil;
  CRYPTO_set_dynlock_lock_callback: procedure(callback: TDynLockLockCallBack); cdecl = nil;
  CRYPTO_set_dynlock_destroy_callback: procedure(callback: TDynLockDestroyCallBack); cdecl = nil;
  CRYPTO_cleanup_all_ex_data: procedure; cdecl = nil;
  ERR_remove_state: procedure(tid: Cardinal); cdecl = nil;
  ERR_free_strings: procedure; cdecl = nil; // thread-unsafe, Application-global cleanup functions
  ERR_error_string_n: procedure(err: Cardinal; buf: MarshaledAString; len: NativeUInt); cdecl = nil;
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
  OBJ_nid2sn: function(n: Integer): MarshaledAString; cdecl = nil;
  ASN1_STRING_data: function(x: PASN1_STRING): Pointer; cdecl = nil;
  PEM_read_bio_X509: function(bp: PBIO; x: PX509; cb: TPemPasswordCallback; u: Pointer): PX509; cdecl = nil;
  PEM_read_bio_PrivateKey: function(bp: PBIO; x: PPEVP_PKEY; cb: TPemPasswordCallback; u: Pointer): PEVP_PKEY; cdecl = nil;
  PEM_read_bio_RSAPrivateKey: function(bp: PBIO; x: PPEVP_PKEY; cb: TPemPasswordCallback; u: Pointer): PEVP_PKEY; cdecl = nil;
  EVP_MD_CTX_create: function: PEVP_MD_CTX; cdecl = nil;
  EVP_MD_CTX_destroy: procedure(ctx: PEVP_MD_CTX); cdecl = nil;
  EVP_sha256: function: PEVP_MD; cdecl = nil;
  EVP_sha1: function: PEVP_MD; cdecl = nil;
  EVP_PKEY_size: function(key: PEVP_PKEY): Integer; cdecl = nil;
  EVP_DigestSignInit: function(aCtx: PEVP_MD_CTX; aPCtx: PEVP_PKEY_CTX; aType: PEVP_MD; aEngine: PENGINE; aKey: PEVP_PKEY): Integer; cdecl = nil;
  EVP_DigestUpdate: function(ctx: PEVP_MD_CTX; const d: Pointer; cnt: Cardinal): Integer; cdecl = nil;
  EVP_DigestSignFinal: function(ctx : PEVP_MD_CTX; const d: PByte; var cnt: Cardinal): Integer; cdecl = nil;
  EVP_DigestVerifyInit: function(aCtx: PEVP_MD_CTX; aPCtx: PEVP_PKEY_CTX; aType: PEVP_MD; aEngine: PENGINE; aKey: pEVP_PKEY): Integer; cdecl = nil;
  EVP_DigestVerifyFinal: function(ctx : pEVP_MD_CTX; const d: PByte; cnt: Cardinal) : Integer; cdecl = nil;
  CRYPTO_malloc: function(aLength : LongInt; const f : MarshaledAString; aLine : Integer): Pointer; cdecl = nil;
  CRYPTO_free: procedure(str: Pointer); cdecl= nil;
  HMAC: function(evp: PEVP_MD; key: PByte; key_len: Integer; data: PByte; data_len: Integer; md: PByte; var md_len: integer): PByte; cdecl = nil;

{ Helpers }

function BIOGetFlags(const ABIO: PBIO): Integer; inline;
function BIORetry(const ABIO: PBIO): Boolean; inline;

function SetSSLCTXOptions(const ACTX: Pointer; const AOP: Integer): Integer;

function SSLErrorFatal(const AError: Integer): Boolean;
function SSLError(const ASSL: PSSL; const AReturnCode: Integer; out AErrorMsg: String): Integer;
function SSL_set_tlsext_host_name(s: PSSL; name: String): Integer;

procedure LoadSSLEAY;
procedure UnloadSSLEAY;
procedure LoadLIBEAY;
procedure UnloadLIBEAY;
procedure SSLInitialize;
procedure SSLFinalize;

implementation

var
  _SSLEAYHandle, _LIBEAYHandle: HMODULE;
  _FSSLLocks: TArray<TCriticalSection>;

function BIOGetFlags(const ABIO: PBIO): Integer;
begin
  Result := PInteger(MarshaledAString(ABIO) + 3 * SizeOf(Pointer) + 2 * SizeOf(Integer))^;
end;

function BIORetry(const ABIO: PBIO): Boolean;
begin
  Result := ((BIOGetFlags(ABIO) and BIO_FLAGS_SHOULD_RETRY) <> 0);
end;

function SetSSLCTXOptions(const ACTX: pointer; const AOP: integer): Integer;
const
  SSL_CTRL_OPTIONS = 32;
begin
  result := SSL_CTX_ctrl(ACTX, SSL_CTRL_OPTIONS, AOP, nil);
end;

function SSLErrorFatal(const AError: Integer): Boolean;
begin
	case AError of
		SSL_ERROR_NONE,
		SSL_ERROR_WANT_READ,
		SSL_ERROR_WANT_WRITE,
		SSL_ERROR_WANT_CONNECT,
		SSL_ERROR_WANT_ACCEPT: Result := False;
  else
    Result := True;
	end;
end;

function SSLError(const ASSL: PSSL; const AReturnCode: Integer; out AErrorMsg: String): Integer;
var
  error, error_log: Integer;
  ErrorBuf: TBytes;
begin
	error := SSL_get_error(ASSL, AReturnCode);
	if(error <> SSL_ERROR_NONE) then
	begin
		error_log := error;
		while (error_log <> SSL_ERROR_NONE) do
    begin
      SetLength(ErrorBuf, 512);
			ERR_error_string_n(error_log, @ErrorBuf[0], Length(ErrorBuf));
			if (SSLErrorFatal(error_log)) then
        AErrorMsg := StringOf(ErrorBuf);
			error_log := ERR_get_error();
		end;
	end;
	Result := error;
end;

function SSL_set_tlsext_host_name(s: PSSL; name: String): Integer;
const
  SSL_CTRL_SET_TLSEXT_HOSTNAME = 55;
  TLSEXT_NAMETYPE_host_name = 0;
var
  M: TMarshaller;
begin
  Result := SSL_ctrl(s, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, M.AsAnsi(name).ToPointer);
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
  SSL_ctrl := GetProc(_SSLEAYHandle, 'SSL_ctrl');
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
  EVP_sha1 := GetProc(_LIBEAYHandle, 'EVP_sha1');
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
  HMAC := GetProc(_LIBEAYHandle, 'HMAC');
end;

procedure UnloadLIBEAY;
begin
  if (_LIBEAYHandle = 0) then Exit;
  FreeLib(_LIBEAYHandle);
  _LIBEAYHandle := 0;
end;

procedure CRYPTO_locking_callback(Mode, N: Integer; const _File: MarshaledAString; Line: Integer); cdecl;
begin
	if(mode and CRYPTO_LOCK <> 0) then
    _FSSLLocks[N].Enter
	else
    _FSSLLocks[N].Leave;
end;

procedure CRYPTO_dynlock_callback_lock(Mode: Integer; L: PCRYPTO_dynlock_value; _File: MarshaledAString; Line: Integer); cdecl;
begin
  if (Mode and CRYPTO_LOCK <> 0) then
    L.Mutex.Enter
  else
    L.Mutex.Leave;
end;

function CRYPTO_dynlock_callback_create(const _file: MarshaledAString; Line: Integer): PCRYPTO_dynlock_value; cdecl;
begin
  New(Result);
  Result.Mutex := TCriticalSection.Create;
end;

procedure CRYPTO_dynlock_callback_destroy(L: PCRYPTO_dynlock_value; _File: MarshaledAString; Line: Integer); cdecl;
begin
  L.Mutex.Free;
  Dispose(L);
end;

procedure SSLInitialize;
var
  Locks, I: Integer;
begin
  if (_SSLEAYHandle = 0) or (_LIBEAYHandle = 0) then Exit;

  Locks := CRYPTO_num_locks();
	if(Locks > 0) then
  begin
    SetLength(_FSSLLocks, Locks);
    for I := Low(_FSSLLocks) to High(_FSSLLocks) do
      _FSSLLocks[I] := TCriticalSection.Create;
	end;

	CRYPTO_set_locking_callback(CRYPTO_locking_callback);
  CRYPTO_set_dynlock_create_callback(CRYPTO_dynlock_callback_create);
	CRYPTO_set_dynlock_lock_callback(CRYPTO_dynlock_callback_lock);
  CRYPTO_set_dynlock_destroy_callback(CRYPTO_dynlock_callback_destroy);

  SSL_load_error_strings();
  SSL_library_init();
end;

procedure SSLFinalize;
var
  I: Integer;
begin
  if (_SSLEAYHandle = 0) or (_LIBEAYHandle = 0) then
    Exit;

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

end.