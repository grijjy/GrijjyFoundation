unit Grijjy.SocketPool.Win;

{ IOCP based socket pool }

{$I Grijjy.inc}

{ Note: TgoSocketPoolBehavior = PoolAndReuse does not currently work with TLS/SSL connections }

{ Note: WSAENOBUFS(10055) error would indicate that you have exhausted
  a resource in Windows there are several possibilities:
  1. You may have exhausted the MaxUserPort, with a default of 5000.  To verify this
     run NETSTAT -AN > C:\NETSTAT.TXT and count the number of TIME_WAIT entries.
     This happens when the TIME_WAIT holds onto the connection and there are no more
     left to allocate. You can add more by creating the key for MaxUserPort under
     HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters.
     You can also reduce the TIME_WAIT by reducing the TcpTimedWaitDelay under
     HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\TcpTimedWaitDelay
  2. You may have exhausted the memory available to the page pool.  This should not happen in
     scale optimization because we perform a "zero byte read trick" to avoid buffer allocation.
     However if you run out with speed optimization then you need to consider allocating
     memory more efficiently.  Perhaps use VirtualAlloc to allocate a large block
     and manage the buffer manually in code, or reduce 4K buffers to 2K.
     A good discussion of the issue is here, http://www.coastrd.com/windows-iocp
  3. You may have exhausted the IoPageLockLimit, see
     https://technet.microsoft.com/en-us/library/cc959494.aspx
}

interface

uses
  Windows,
  Messages,
  Winsock2,
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.DateUtils,
  System.IOUtils,
  System.Generics.Collections,
  Grijjy.Winsock2,
  Grijjy.OpenSSL,
  Grijjy.Collections,
  Grijjy.MemoryPool;

const
  DEFAULT_BLOCK_SIZE = 4096;
  TIMEOUT_CLOSE = 5000;
  TIMEOUT_STOP = 5000;
  INTERVAL_CLEANUP = 10000;
  INTERVAL_FREE = 5000;

type
  TgoClientSocketManager = class;
  TgoSocketConnection = class;

  { Internal operation }
  TgoSocketOperation = (Connect, Disconnect, ReadZero, Read, Write);

  { Internal performance optimization }
  TgoSocketOptimization = (Speed, Scale);

  { Internal socket pool behavior }
  TgoSocketPoolBehavior = (CreateAndDestroy, PoolAndReuse);

  { Internal connection state }
  TgoConnectionState = (Disconnected, Disconnecting, Connected);

  { Callback events }
  TgoSocketNotifyEvent = procedure of object;
  TgoSocketDataEvent = procedure(const ABuffer: Pointer; const ASize: Integer)
    of object;

  { Iocp per transaction struct }
  PPerIoData = ^TPerIoData;

  TPerIoData = packed record
    Overlapped: TWSAOverlapped;
    WsaBuf: WsaBuf;
    Socket: TSocket;
    Operation: TgoSocketOperation;
  end;

  { Socket connection instance }
  TgoSocketConnection = class(TObject)
  private
    FOwner: TgoClientSocketManager;
    FSocket: THandle;
    FHostname: String;
    FPort: Word;
    FState: TgoConnectionState;
    FOpenSSL: TgoOpenSSL;
    FReleased: TDateTime;
    FAttemptCloseSocket: Boolean;

    { Thread-safe variables for pending operations }
    FLock: TCriticalSection;
    FPending: array[TgoSocketOperation] of Integer;
    FShutdown: Boolean;
    [volatile] FClosed: Integer;

    { WSARecv buffer }
    FReadBuffer: Pointer;

    { Log WSA and System related errors }
    {$IFDEF GRIJJYLOGGING}
    procedure HandleWSAError(const AError: String);
    procedure HandleError(const AError: String);
    {$ENDIF}

    { Pending operations }
    function AddRef(const AOperation: TgoSocketOperation): Boolean; inline;
    procedure ReleaseRef(const AOperation: TgoSocketOperation); inline;
    function ReleaseRefCheckShutdown(const AOperation: TgoSocketOperation): Boolean; inline;
  protected
    FOnConnectedLock: TCriticalSection;
    FOnConnected: TgoSocketNotifyEvent;
    FOnDisconnectedLock: TCriticalSection;
    FOnDisconnected: TgoSocketNotifyEvent;
    FOnRecvLock: TCriticalSection;
    FOnRecv: TgoSocketDataEvent;
    FOnSentLock: TCriticalSection;
    FOnSent: TgoSocketDataEvent;
  private
    { OpenSSL related }
    FSSL: Boolean;
    FALPN: Boolean;

    procedure SetCertificate(const Value: TBytes);
    procedure SetPassword(const Value: String);
    procedure SetPrivateKey(const Value: TBytes);
    function GetCertificate: TBytes;
    function GetPassword: String;
    function GetPrivateKey: TBytes;
  private
    { SSL callbacks }
    procedure OnSSLConnected;
    procedure OnSSLRead(const ABuffer: Pointer; const ASize: Integer);
    procedure OnSSLWrite(const ABuffer: Pointer; const ASize: Integer);

    { Initialize the OpenSSL interface }
    function GetOpenSSL: TgoOpenSSL;
  private
    { Thread safe number of pending operations on a socket }
    function GetPending: Integer; inline;

    { Thread safe closed boolean flag }
    function GetClosed: Boolean;
    procedure SetClosed(AValue: Boolean);

    { Thread safe shutdown boolean flag }
    function GetShutdown: Boolean;

    { Resets the connection }
    procedure Reset;

    { Post a zero byte read request which effectively tells IOCP to
      notify when a read event is ready but does this without allocating a buffer
      which allows more concurrent connections due to less memory page pooling }
    function PostReadZero: Boolean;

    { Post a normal read request }
    function PostRead(const ABuffer: Pointer): Boolean;

    { Post a normal write request }
    function PostWrite(const ABuffer: Pointer; ASize: Integer): Boolean;

    { Connect the socket }
    function PostConnect(const AHostname: String;
      const APort: Word; const AUseNagle: Boolean = False): Boolean;

    { Disconnect the socket }
    function PostDisconnect: Boolean;
  private
    { Handle data that is read from the socket }
    procedure Read(const ABuffer: Pointer; const ASize: Integer); inline;

    { Write data to the socket }
    function Write(const ABuffer: Pointer; const ASize: Integer): Boolean; inline;
  public
    constructor Create(const AOwner: TgoClientSocketManager; const AHostname: String; const APort: Word);
    destructor Destroy; override;
  public
    { Connects the socket }
    function Connect(const AUseNagle: Boolean = True): Boolean;

    { Disconnects the socket }
    procedure Disconnect;

    { Sends the bytes to the socket }
    function Send(const ABuffer: Pointer; const ASize: Integer): Boolean; overload;
    function Send(const ABytes: TBytes): Boolean; overload;

    { Returns the pending operations as a string }
    function PendingToString: String;

    { Stops all future callback events }
    procedure StopCallbacks;
  public
    { Socket handle }
    property Socket: THandle read FSocket write FSocket;

    { Hostname }
    property Hostname: String read FHostname write FHostname;

    { Port }
    property Port: Word read FPort write FPort;

    { Current state of the socket connection }
    property State: TgoConnectionState read FState write FState;

    { Number of pending operations on the socket }
    property Pending: Integer read GetPending;

    { Socket is shutdown }
    property Shutdown: Boolean read GetShutdown;

    { Connection is closed }
    property Closed: Boolean read GetClosed write SetClosed;

    { OpenSSL interface }
    property OpenSSL: TgoOpenSSL read GetOpenSSL;
  public
    { Using SSL }
    property SSL: Boolean read FSSL write FSSL;

    { Using ALPN }
    property ALPN: Boolean read FALPN write FALPN;

    { Certificate in PEM format }
    property Certificate: TBytes read GetCertificate write SetCertificate;

    { Private key in PEM format }
    property PrivateKey: TBytes read GetPrivateKey write SetPrivateKey;

    { Password for private key }
    property Password: String read GetPassword write SetPassword;
  public
    { Fired when the socket is connected and ready to be written }
    property OnConnected: TgoSocketNotifyEvent read FOnConnected write FOnConnected;

    { Fired when the socket is disconnected, either gracefully if the state
      is Disconnecting or abrupt if the state is Connected }
    property OnDisconnected: TgoSocketNotifyEvent read FOnDisconnected write FOnDisconnected;

    { Fired when the data has been received by the socket }
    property OnRecv: TgoSocketDataEvent read FOnRecv write FOnRecv;

    { Fired when the data has been sent by the socket }
    property OnSent: TgoSocketDataEvent read FOnSent write FOnSent;
  end;

  { Socket pool worker thread }
  TSocketPoolWorker = class(TThread)
  private
    FOwner: TgoClientSocketManager;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOwner: TgoClientSocketManager);
    destructor Destroy; override;
  end;

  { Client socket manager }
  TgoClientSocketManager = class(TThread)
  private
    FHandle: THandle;
    FOptimization: TgoSocketOptimization;
    FBehavior: TgoSocketPoolBehavior;
    FWorkers: array of TSocketPoolWorker;
    FWorkerHandles: array of THandle;
  private
    Connections: TgoSet<TgoSocketConnection>;
    ConnectionsLock: TCriticalSection;
    procedure FreeConnections;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOptimization: TgoSocketOptimization = TgoSocketOptimization.Scale;
      const ABehavior: TgoSocketPoolBehavior = TgoSocketPoolBehavior.CreateAndDestroy; const AWorkers: Integer = 0);
    destructor Destroy; override;
  public
    { Releases the connection back to the socket pool }
    procedure Release(const AConnection: TgoSocketConnection);

    { Requests a connection from the socket pool }
    function Request(const AHostname: String; const APort: Word): TgoSocketConnection;
  public
    { Completion handle for IOCP }
    property Handle: THandle read FHandle;

    { Optimization mode }
    property Optimization: TgoSocketOptimization read FOptimization;
  end;

implementation

{$IFDEF GRIJJYLOGGING}
uses
  Grijjy.System.Logging;
{$ENDIF}

var
  {$IFDEF GRIJJYLOGGING}
  _Log: TgoLogging;
  {$ENDIF}
  _PerIoDataPool, _MemBufferPool: TgoMemoryPool;

function HasOverlappedIoCompleted(const PerIoData: PPerIoData): BOOL;
begin
  Result := Integer(PerIoData.Overlapped.Internal) <> STATUS_PENDING;
end;

function OperationToString(const AOperation: TgoSocketOperation): String;
begin
  case AOperation of
    TgoSocketOperation.Connect:
      Result := 'Connect';
    TgoSocketOperation.Disconnect:
      Result := 'Disconnect';
    TgoSocketOperation.ReadZero:
      Result := 'ReadZero';
    TgoSocketOperation.Read:
      Result := 'Read';
    TgoSocketOperation.Write:
      Result := 'Write';
  end;
end;

{ WSA Helpers }

function WSAErrorOK(const AValue: Integer): Boolean;
begin
  Result := (AValue = WSAEINTR) or (AValue = WSAECONNABORTED) or
    (AValue = WSAECONNRESET) or (AValue = WSAESHUTDOWN);
end;

{ TgoSocketConnection }

constructor TgoSocketConnection.Create(const AOwner: TgoClientSocketManager; const AHostname: String; const APort: Word);
var
  Operation: TgoSocketOperation;
begin
  inherited Create;
  FOwner := AOwner;
  FHostname := AHostname;
  FPort := APort;
  FState := TgoConnectionState.Disconnected;
  for Operation := Low(TgoSocketOperation) to High(TgoSocketOperation) do
    FPending[Operation] := 0;
  FShutdown := False;
  FClosed := 0;
  FAttemptCloseSocket := False;
  FReleased := -1;
  FLock := TCriticalSection.Create;
  { for speed optimization we allocate a single read buffer that we use
    for serialized reads from the socket for the lifetime of the socket }
  if FOwner.Optimization = TgoSocketOptimization.Speed then
    FReadBuffer := _MemBufferPool.RequestMem('_TgoSocketConnection.ReadBuffer')
  else
    { for scale optimization we allocate a read buffer on demand when a
      pending read is waiting }
    FReadBuffer := nil;
  FOpenSSL := nil;
  FSSL := False;
  FALPN := False;
  FOnConnectedLock := TCriticalSection.Create;
  FOnDisconnectedLock := TCriticalSection.Create;
  FOnRecvLock := TCriticalSection.Create;
  FOnSentLock := TCriticalSection.Create;
end;

destructor TgoSocketConnection.Destroy;
begin
  Disconnect;
  if FReadBuffer <> nil then
    _MemBufferPool.ReleaseMem(FReadBuffer, '_TgoSocketConnection.ReadBuffer');
  if FOpenSSL <> nil then
    FOpenSSL.Free;
  FLock.Free;
  FOnConnectedLock.Free;
  FOnDisconnectedLock.Free;
  FOnRecvLock.Free;
  FOnSentLock.Free;
  inherited Destroy;
end;

function IsFatalError(const ALastError: Integer): Boolean;
begin
  { 10053 (An established connection was aborted by the software) is common for aborted connections }
  Result := ALastError <> 10053;
end;

{$IFDEF GRIJJYLOGGING}
procedure TgoSocketConnection.HandleWSAError(const AError: String);
var
  LastError: Integer;
begin
  LastError := WSAGetLastError;
  if IsFatalError(LastError) then
    _Log.Send(Format('Warning! WSA %s (Socket=%d, Connection=%d, ThreadId=%d, LastError=%d, SysErrorMessage=%s)',
      [AError, FSocket, Cardinal(Self), GetCurrentThreadId, LastError, SysErrorMessage(LastError)]));
end;

procedure TgoSocketConnection.HandleError(const AError: String);
var
  LastError: Integer;
begin
  LastError := GetLastError;
  _Log.Send(Format('Warning! %s (Socket=%d, Connection=%d, ThreadId=%d, LastError=%d, SysErrorMessage=%s)',
    [AError, FSocket, Cardinal(Self), GetCurrentThreadId, LastError, SysErrorMessage(LastError)]));
end;
{$ENDIF}

function TgoSocketConnection.AddRef(const AOperation: TgoSocketOperation): Boolean;
begin
  FLock.Enter;
  try
    if FShutdown then
      Result := False
    else
    begin
      if AOperation = TgoSocketOperation.Connect then
      begin
        Inc(FPending[AOperation]);
        Result := True;
      end
      else
      if AOperation = TgoSocketOperation.Disconnect then
      begin
        Inc(FPending[AOperation]);
        Result := True;
        FShutdown := True;
      end
      else
      begin
        if Pending = 0 then
          Result := False
        else
        begin
          Inc(FPending[AOperation]);
          Result := True;
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TgoSocketConnection.ReleaseRef(const AOperation: TgoSocketOperation);
begin
  FLock.Enter;
  try
    Dec(FPending[AOperation]);
  finally
    FLock.Leave;
  end;
end;

function TgoSocketConnection.ReleaseRefCheckShutdown(const AOperation: TgoSocketOperation): Boolean;
begin
  FLock.Enter;
  try
    Dec(FPending[AOperation]);
    Result := (FShutdown) and (Pending = 0);
  finally
    FLock.Leave;
  end;
end;

procedure TgoSocketConnection.SetCertificate(const Value: TBytes);
begin
  OpenSSL.Certificate := Value;
end;

procedure TgoSocketConnection.SetPassword(const Value: String);
begin
  OpenSSL.Password := Value;
end;

procedure TgoSocketConnection.SetPrivateKey(const Value: TBytes);
begin
  OpenSSL.PrivateKey := Value;
end;

function TgoSocketConnection.GetCertificate: TBytes;
begin
  Result := OpenSSL.Certificate;
end;

function TgoSocketConnection.GetPassword: String;
begin
  Result := OpenSSL.Password;
end;

function TgoSocketConnection.GetPrivateKey: TBytes;
begin
  Result := OpenSSL.PrivateKey;
end;

procedure TgoSocketConnection.OnSSLConnected;
begin
  FState := TgoConnectionState.Connected;

  { did ALPN negotation succeed? }
  if FALPN and not OpenSSL.ALPN then
  begin
    {$IFDEF GRIJJYLOGGING}
    HandleError('ALPN negotation failed for SSL.');
    {$ENDIF}
    Exit;
  end;

  FOnConnectedLock.Enter;
  try
    if Assigned(FOnConnected) then
      FOnConnected;
  finally
    FOnConnectedLock.Leave;
  end;
end;

procedure TgoSocketConnection.OnSSLRead(const ABuffer: Pointer; const ASize: Integer);
begin
  FOnRecvLock.Enter;
  try
    if Assigned(FOnRecv) then
      FOnRecv(ABuffer, ASize);
  finally
    FOnRecvLock.Leave;
  end;
end;

procedure TgoSocketConnection.OnSSLWrite(const ABuffer: Pointer; const ASize: Integer);
begin
  PostWrite(ABuffer, ASize);
end;

function TgoSocketConnection.GetOpenSSL: TgoOpenSSL;
begin
  if FOpenSSL = nil then
  begin
    FOpenSSL := TgoOpenSSL.Create;
    FOpenSSL.OnConnected := OnSSLConnected;
    FOpenSSL.OnRead := OnSSLRead;
    FOpenSSL.OnWrite := OnSSLWrite;
  end;
  Result := FOpenSSL;
end;

function TgoSocketConnection.GetPending: Integer;
var
  Operation: TgoSocketOperation;
begin
  Result := 0;
  FLock.Enter;
  try
    for Operation := Low(TgoSocketOperation) to High(TgoSocketOperation) do
      Result := Result + FPending[Operation];
  finally
    FLock.Leave;
  end;
end;

procedure TgoSocketConnection.SetClosed(AValue: Boolean);
begin
  TInterlocked.Increment(FClosed);
end;

function TgoSocketConnection.GetClosed: Boolean;
begin
  Result := TInterlocked.CompareExchange(FClosed, 0, 0) <> 0;
end;

function TgoSocketConnection.GetShutdown: Boolean;
begin
  FLock.Enter;
  try
    Result := FShutdown;
  finally
    FLock.Leave;
  end;
end;

procedure TgoSocketConnection.StopCallbacks;
begin
  FOnConnectedLock.Enter;
  try
    FOnConnected := nil;
  finally
    FOnConnectedLock.Leave;
  end;
  FOnDisconnectedLock.Enter;
  try
    FOnDisconnected := nil;
  finally
    FOnDisconnectedLock.Leave;
  end;
  FOnRecvLock.Enter;
  try
    FOnRecv := nil;
  finally
    FOnRecvLock.Leave;
  end;
  FOnSentLock.Enter;
  try
    FOnSent := nil;
  finally
    FOnSentLock.Leave;
  end;
end;

function TgoSocketConnection.PostReadZero: Boolean;
var
  Bytes, Flags: Cardinal;
  PerIoData: PPerIoData;
begin
  Result := False;
  if not AddRef(TgoSocketOperation.ReadZero) then Exit;
  //_Log('PostReadZero');
  PerIoData := _PerIoDataPool.RequestMem('_TgoSocketConnection.PostReadZero.PerIoData');
  PerIoData.Socket := FSocket;
  PerIoData.Operation := TgoSocketOperation.ReadZero;
  PerIoData.WsaBuf.Buf := nil;
  PerIoData.WsaBuf.Len := 0;
  Flags := 0;
  Bytes := 0;
  if (WSARecv(FSocket, @PerIoData.WsaBuf, 1, Bytes, Flags,
    PWSAOverlapped(PerIoData), nil) = SOCKET_ERROR) and
    (WSAGetLastError <> WSA_IO_PENDING) then
  begin
    {$IFDEF GRIJJYLOGGING}
    HandleWSAError('PostReadZero.WSARecv');
    {$ENDIF}
    _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostReadZero.PerIoData');
    ReleaseRef(TgoSocketOperation.ReadZero);
  end
  else
    Result := True;
end;

function TgoSocketConnection.PostRead(const ABuffer: Pointer): Boolean;
var
  Bytes, Flags: Cardinal;
  PerIoData: PPerIoData;
begin
  Result := False;
  if not AddRef(TgoSocketOperation.Read) then Exit;
  //_Log('PostRead');
  PerIoData := _PerIoDataPool.RequestMem('_TgoSocketConnection.PostRead.PerIoData');
  PerIoData.Socket := FSocket;
  PerIoData.Operation := TgoSocketOperation.Read;
  PerIoData.WsaBuf.Buf := ABuffer;
  PerIoData.WsaBuf.Len := DEFAULT_BLOCK_SIZE;
  Flags := 0;
  Bytes := 0;
  if (WSARecv(FSocket, @PerIoData.WsaBuf, 1, Bytes, Flags,
    PWSAOverlapped(PerIoData), nil) = SOCKET_ERROR) and
    (WSAGetLastError <> WSA_IO_PENDING) then
  begin
    {$IFDEF GRIJJYLOGGING}
    HandleWSAError('PostRead.WSARecv');
    {$ENDIF}
    _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostRead.PerIoData');
    ReleaseRef(TgoSocketOperation.Read);
  end
  else
    Result := True;
end;

function TgoSocketConnection.PostWrite(const ABuffer: Pointer;
  ASize: Integer): Boolean;
var
  PerIoData: PPerIoData;
  Bytes: DWORD;
  WriteBuffer: Pointer;
begin
  Result := False;
  if not AddRef(TgoSocketOperation.Write) then Exit;
  //_Log('PostWrite');
  WriteBuffer := _MemBufferPool.RequestMem('_TgoSocketConnection.PostWrite.WriteBuffer');
  Move(ABuffer^, WriteBuffer^, ASize);
  PerIoData := _PerIoDataPool.RequestMem(('_TgoSocketConnection.PostWrite.PerIoData'));
  PerIoData.Socket := FSocket;
  PerIoData.Operation := TgoSocketOperation.Write;
  PerIoData.WsaBuf.Buf := WriteBuffer;
  PerIoData.WsaBuf.Len := ASize;
  if (WSASend(FSocket, @PerIoData.WsaBuf, 1, Bytes, 0, PWSAOverlapped(PerIoData), nil) = SOCKET_ERROR) and
    (WSAGetLastError <> WSA_IO_PENDING) then
  begin
    {$IFDEF GRIJJYLOGGING}
    HandleWSAError('PostWrite.WSASend');
    {$ENDIF}
    _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostWrite.PerIoData');
    _MemBufferPool.ReleaseMem(WriteBuffer, '_TgoSocketConnection.PostWrite.WriteBuffer');
    ReleaseRef(TgoSocketOperation.Write);
  end
  else
    Result := True;
end;

function TgoSocketConnection.PostConnect(const AHostname: String;
  const APort: Word; const AUseNagle: Boolean): Boolean;
var
  Hints: TAddrInfoW;
  AddrInfo: PAddrInfoW;
  ConnectAddr: TSockAddrIn;
  PerIoData: PPerIoData;
  Port: String;
  Size: Integer;
begin
  Result := False;
  FillChar(Hints, SizeOf(TAddrInfoW), 0);
  Hints.ai_family := AF_INET;
  Hints.ai_socktype := SOCK_STREAM;
  Hints.ai_protocol := IPPROTO_TCP;
  AddrInfo := nil;

  { get the addrinfo for hostname and port }
  Port := IntToStr(APort);
  if getaddrinfo(PWideChar(AHostname), PWideChar(Port), @Hints, @AddrInfo) <> 0
  then
  begin
    {$IFDEF GRIJJYLOGGING}
    HandleWSAError('PostConnect.getaddrinfo');
    {$ENDIF}
    Exit;
  end;

  try
    { create an overlapped socket }
    FSocket := WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nil, 0,
      WSA_FLAG_OVERLAPPED);
    if FSocket = INVALID_SOCKET then
    begin
      {$IFDEF GRIJJYLOGGING}
      HandleWSAError('PostConnect.WSASocket');
      {$ENDIF}
      Exit;
    end;

    { set SO_SNDBUF to zero for a zero-copy network stack as we maintain the buffers }
    Size := 0;
    if setsockopt(FSocket, SOL_SOCKET, SO_SNDBUF, @Size, SizeOf(Size)) = SOCKET_ERROR
    then
    begin
      {$IFDEF GRIJJYLOGGING}
      HandleError('PostConnect.setsockopt');
      {$ENDIF}
      Exit;
    end;

    { set SO_RCVBUF to zero for a zero-copy network stack as we maintain the buffers }
    Size := 0;
    if setsockopt(FSocket, SOL_SOCKET, SO_RCVBUF, @Size, SizeOf(Size)) = SOCKET_ERROR
    then
    begin
      {$IFDEF GRIJJYLOGGING}
      HandleError('PostConnect.setsockopt');
      {$ENDIF}
      Exit;
    end;

    { set TCP_NODELAY to reduce latency }
    if not AUseNagle then
    begin
      Size := 0;
      if setsockopt(FSocket, IPPROTO_TCP, TCP_NODELAY, @Size, SizeOf(Size)) = SOCKET_ERROR then
      begin
        {$IFDEF GRIJJYLOGGING}
        HandleError('PostConnect.setsockopt');
        {$ENDIF}
        Exit;
      end;
    end;

    { bind the socket }
    ConnectAddr.sin_family := AF_INET;
    ConnectAddr.sin_addr.S_addr := INADDR_ANY;
    ConnectAddr.sin_port := 0;
    if bind(FSocket, @ConnectAddr, SizeOf(ConnectAddr)) = SOCKET_ERROR then
    begin
      {$IFDEF GRIJJYLOGGING}
      HandleWSAError('PostConnect.bind');
      {$ENDIF}
      closesocket(FSocket);
      Closed := True;
      Exit;
    end;

    { associate socket and connection object with completion port }
    if CreateIoCompletionPort(FSocket, FOwner.Handle, ULONG_PTR(Self), 0) = 0
    then
    begin
      {$IFDEF GRIJJYLOGGING}
      HandleError('PostConnect.CreateIoCompletionPort');
      {$ENDIF}
      closesocket(FSocket);
      Closed := True;
      Exit;
    end;

    { queue a connect command to the completion port }
    //_Log('PostConnect');
    if not AddRef(TgoSocketOperation.Connect) then Exit;
    PerIoData := _PerIoDataPool.RequestMem('_TgoSocketConnection.PostConnect.PerIoData');
    PerIoData.Socket := FSocket;
    PerIoData.Operation := TgoSocketOperation.Connect;
    if not ConnectEx(FSocket, AddrInfo.ai_addr, AddrInfo.ai_addrlen, nil, 0,
      PCardinal(0)^, PWSAOverlapped(PerIoData)) and
      (WSAGetLastError <> WSA_IO_PENDING) then
    begin
      {$IFDEF GRIJJYLOGGING}
      HandleWSAError('PostConnect.ConnectEx');
      {$ENDIF}
      _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostConnect.PerIoData');
      ReleaseRef(TgoSocketOperation.Connect);
      closesocket(FSocket);
      Closed := True;
    end
    else
      Result := True;
  finally
    freeaddrinfo(AddrInfo);
  end;
end;

function TgoSocketConnection.PostDisconnect: Boolean;
var
  PerIoData: PPerIoData;
begin
  Result := False;
  if not AddRef(TgoSocketOperation.Disconnect) then Exit;
  if FSocket = 0 then Exit;
  //_Log('PostDisconnect');
  PerIoData := _PerIoDataPool.RequestMem('_TgoSocketConnection.PostDisconnect.PerIoData');
  PerIoData.Socket := FSocket;
  PerIoData.Operation := TgoSocketOperation.Disconnect;
  if not DisconnectEx(FSocket, PWSAOverlapped(PerIoData), TF_REUSE_SOCKET, 0)
    and (WSAGetLastError <> WSA_IO_PENDING) then
  begin
    {$IFDEF GRIJJYLOGGING}
    HandleWSAError('PostDisconnect.DisconnectEx');
    {$ENDIF}
    _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostDisconnect.PerIoData');
    ReleaseRef(TgoSocketOperation.Disconnect);
  end
  else
    Result := True;
end;

procedure TgoSocketConnection.Reset;
var
  Operation: TgoSocketOperation;
begin
  FLock.Enter;
  try
    for Operation := Low(TgoSocketOperation) to High(TgoSocketOperation) do
      FPending[Operation] := 0;
    FShutdown := False;
  finally
    FLock.Leave;
  end;
  FClosed := 0;
  FAttemptCloseSocket := False;
  FReleased := -1;
end;

function TgoSocketConnection.PendingToString: String;
begin
  FLock.Enter;
  try
    Result := Format('(Connect=%d, Disconnect=%d, ReadZero=%d, Read=%d, Write=%d)', [
      FPending[TgoSocketOperation.Connect],
      FPending[TgoSocketOperation.Disconnect],
      FPending[TgoSocketOperation.ReadZero],
      FPending[TgoSocketOperation.Read],
      FPending[TgoSocketOperation.Write]
      ]);
  finally
    FLock.Leave;
  end;
end;

function TgoSocketConnection.Connect(const AUseNagle: Boolean): Boolean;
begin
  Reset;
  if PostConnect(FHostname, FPort, AUseNagle) then
    Result := True
  else
    Result := False;
end;

procedure TgoSocketConnection.Disconnect;
begin
  //_Log('Disconnect');

  { if not already shutdown, then post disconnect }
  if not Shutdown then
  begin
    { we set the state to disconnecting so we know when the OnDisconnected event
      was triggered gracefully by a requested disconnect or abruptly by a socket error }
    FState := TgoConnectionState.Disconnecting;
    PostDisconnect;
  end;
end;

function TgoSocketConnection.Send(const ABuffer: Pointer;
  const ASize: Integer): Boolean;
var
  Index: Integer;
  BlockSize: Integer;
  Bytes: PByte;
begin
  Result := True;
  Index := 0;
  Bytes := ABuffer;
  { we chunk the buffer to match the memory pool block size to
    avoid memory reallocations }
  if ASize < DEFAULT_BLOCK_SIZE then
    BlockSize := ASize
  else
    BlockSize := DEFAULT_BLOCK_SIZE;
  while Index < ASize do
  begin
    if ASize - Index < BlockSize then
      BlockSize := ASize - Index;
    if Write(@Bytes[Index], BlockSize) then
      Inc(Index, BlockSize)
    else
    begin
      Result := False;
      PostDisconnect;
      Break; { write failed }
    end;
  end;
end;

function TgoSocketConnection.Send(const ABytes: TBytes): Boolean;
begin
  Result := Send(@ABytes[0], Length(ABytes));
end;

procedure TgoSocketConnection.Read(const ABuffer: Pointer;
  const ASize: Integer);
begin
  if FSSL then
    OpenSSL.Read(ABuffer, ASize)
  else
  begin
    FOnRecvLock.Enter;
    try
      if Assigned(FOnRecv) then
        FOnRecv(ABuffer, ASize);
    finally
      FOnRecvLock.Leave;
    end;
  end;
end;

function TgoSocketConnection.Write(const ABuffer: Pointer;
  const ASize: Integer): Boolean;
begin
  if FSSL then
    Result := OpenSSL.Write(ABuffer, ASize)
  else
    Result := PostWrite(ABuffer, ASize);
end;

{ TSocketPoolWorker }

constructor TSocketPoolWorker.Create(const AOwner: TgoClientSocketManager);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TSocketPoolWorker.Destroy;
begin
  inherited;
end;

procedure TSocketPoolWorker.Execute;
var
  ReturnValue: Boolean;
  BytesTransferred: DWORD;
  Connection: TgoSocketConnection;
  PerIoData: PPerIoData;
  ReadBuffer: Pointer;
  Error: Integer;
begin
  {$IFDEF DEBUG}
  NameThreadForDebugging('TSocketPoolWorker');
  {$ENDIF}
  while True do
  begin
    ReturnValue := GetQueuedCompletionStatus(FOwner.FHandle, BytesTransferred,
      ULONG_PTR(Connection), POverlapped(PerIoData), WSA_INFINITE);
    try
      if ReturnValue then
      begin
        if PerIoData <> nil then
        begin
          { success, so process operation }
          case PerIoData.Operation of
            TgoSocketOperation.ReadZero: { only called for scale optimization }
              begin
                { for scale optimization we allocate memory from the page pool only
                  when we know that a pending data is ready to be read from the socket }
                ReadBuffer := _MemBufferPool.RequestMem('_TSocketPoolWorker.ReadBuffer');
                if not Connection.PostRead(ReadBuffer) then
                begin
                  { if WSARecv fails then we need to release the buffer immediately }
                  _MemBufferPool.ReleaseMem(ReadBuffer, '_TSocketPoolWorker.ReadBuffer');
                  Connection.PostDisconnect;
                end;
              end;
            TgoSocketOperation.Read:
              begin
                case FOwner.Optimization of
                  TgoSocketOptimization.Speed:
                    begin
                      { with speed optimization we use the singleton recvbuffer to handle the operation }
                      if BytesTransferred <> 0 then
                      begin
                        Connection.Read(PerIoData.WsaBuf.Buf, BytesTransferred);
                        if not Connection.PostRead(Connection.FReadBuffer) then
                        begin
                          { if this fails, we will start the disconnect sequence }
                          Connection.PostDisconnect;
                        end;
                      end
                      //else
                      //  { connection reset by peer }
                      //  _Log('Read.BytesTransferred = 0');
                    end;
                  TgoSocketOptimization.Scale:
                    begin
                      ReadBuffer := PerIoData.WsaBuf.Buf;
                      try
                        if BytesTransferred <> 0 then
                        begin
                          Connection.Read(ReadBuffer, BytesTransferred);
                          if not Connection.PostReadZero then
                          begin
                            { if this fails, we will start the disconnect sequence }
                            Connection.PostDisconnect;
                          end;
                        end
                        //else
                        //  { connection reset by peer }
                        //  _Log('Read.BytesTransferred = 0');
                      finally
                        { make sure we release the receive buffer we previously
                          allocated when returning from a pending readzero }
                        _MemBufferPool.ReleaseMem(ReadBuffer, '_TSocketPoolWorker.ReadBuffer');
                      end;
                    end;
                end;
              end;
            TgoSocketOperation.Write:
              begin
                try
                  if BytesTransferred <> 0 then
                  begin
                    Connection.FOnSentLock.Enter;
                    try
                      if Assigned(Connection.FOnSent) then
                        Connection.FOnSent(PerIoData.WsaBuf.Buf, BytesTransferred);
                    finally
                      Connection.FOnSentLock.Leave;
                    end;
                  end
                  //else
                  //  { connection reset by peer }
                  //  _Log('Write.BytesTransferred = 0');
                finally
                  _MemBufferPool.ReleaseMem(PerIoData.WsaBuf.Buf, '_TgoSocketConnection.PostWrite.WriteBuffer');
                end;
              end;
            TgoSocketOperation.Connect:
              begin
                { using SSL? }
                if Connection.SSL then
                  { use optional Application-Layer Protocol Negotiation Extension, defined in RFC 7301 }
                  Connection.OpenSSL.Connect(Connection.ALPN)
                else
                begin
                  Connection.State := TgoConnectionState.Connected;
                  Connection.FOnConnectedLock.Enter;
                  try
                    if Assigned(Connection.FOnConnected) then
                      Connection.FOnConnected;
                  finally
                    Connection.FOnConnectedLock.Leave;
                  end;
                end;
                case FOwner.Optimization of
                  TgoSocketOptimization.Speed:
                    begin
                      if not Connection.PostRead(Connection.FReadBuffer) then
                      begin
                        { if this fails, we will start the disconnect sequence }
                        Connection.PostDisconnect;
                      end;
                    end;
                  TgoSocketOptimization.Scale:
                    if not Connection.PostReadZero then
                    begin
                      { if this fails, we will start the disconnect sequence }
                      Connection.PostDisconnect;
                    end;
                end;
              end;
            TgoSocketOperation.Disconnect:
              begin
                Connection.FOnDisconnectedLock.Enter;
                try
                  { disconnected event }
                  if Assigned(Connection.FOnDisconnected) then
                    Connection.FOnDisconnected;
                finally
                  Connection.FOnDisconnectedLock.Leave;
                end;
                Connection.State := TgoConnectionState.Disconnected;
              end;
          end;
        end
        else { PerIoData = nil }
          if Connection = nil then
            Break; { thread shutdown from PostQueuedCompletionStatus signal }
      end
      else { not ReturnValue }
        if PerIoData <> nil then
        begin
          { error happened }
          Error := WSAGetLastError;
          try
            { ERROR_NETNAME_DELETED happens when the connection was reset while operations were still pending }
            {$IFDEF GRIJJYLOGGING}
            if Error <> ERROR_NETNAME_DELETED then
              _Log.Send(Format('Warning! GetQueuedCompletionStatus (Socket=%d, ThreadId=%d, Operation=%s, Error=%d)',
                [PerIoData.Socket, GetCurrentThreadId, OperationToString(PerIoData.Operation), Error]));
            {$ENDIF}

            { these are potential error codes for operations that are
              queued after the socket is closed }
            if (Error = ERROR_OPERATION_ABORTED) or
              (Error = ERROR_CONNECTION_ABORTED) or
              (Error = ERROR_IO_INCOMPLETE) then
            begin
            end;
          finally
            { cleanup buffer for failed writes }
            if PerIoData.Operation = TgoSocketOperation.Write then
              _MemBufferPool.ReleaseMem(PerIoData.WsaBuf.Buf, '_TgoSocketConnection.PostWrite.WriteBuffer');
          end;
        end;

    finally { this is always executed for both success and failure, except for thread shutdown }
      if PerIoData <> nil then
      begin
        if Connection <> nil then { Connection object is valid }
        begin
          //_Log('Status, Pending=' + IntToStr(Connection.Pending));
          if Connection.ReleaseRefCheckShutdown(PerIoData.Operation) then
          begin
            { free the socket handle }
            closesocket(Connection.Socket);

            {$IFDEF GRIJJYLOGGING}
            _Log.Send(Format('Closesocket (Socket=%d, Connection=%d, ThreadId=%d) Pending=%s',
              [Connection.Socket, Cardinal(Self), GetCurrentThreadId, Connection.PendingToString]));
            {$ENDIF}

            { trigger closed event }
            Connection.Closed := True;
          end;
        end;

        { release periodata }
        if HasOverlappedIoCompleted(PerIoData) then
          case PerIoData.Operation of
            TgoSocketOperation.Connect: _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostConnect.PerIoData');
            TgoSocketOperation.Disconnect: _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostDisconnect.PerIoData');
            TgoSocketOperation.ReadZero: _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostReadZero.PerIoData');
            TgoSocketOperation.Read: _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostRead.PerIoData');
            TgoSocketOperation.Write: _PerIoDataPool.ReleaseMem(PerIoData, '_TgoSocketConnection.PostWrite.PerIoData');
          end;
      end;
    end;
  end;
  //Log('Worker thread finished.');
end;

{ TgoClientSocketManager }

constructor TgoClientSocketManager.Create(const AOptimization: TgoSocketOptimization;
  const ABehavior: TgoSocketPoolBehavior; const AWorkers: Integer);
var
  I: Integer;
  Workers: Integer;
begin
  inherited Create;
  FOptimization := AOptimization;
  FBehavior := ABehavior;

  Connections := TgoSet<TgoSocketConnection>.Create;
  ConnectionsLock := TCriticalSection.Create;

  { create the primary completion port handle }
  FHandle := CreateIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 0);
  if FHandle <> INVALID_HANDLE_VALUE then
  begin
    { create worker threads to handle queued events }
    if AWorkers = 0 then
      Workers := CPUCount
    else
      Workers := AWorkers;
    if Workers < 2 then
      Workers := 2; { minimum number of workers }

    {$IFDEF GRIJJYLOGGING}
    _Log.Send(Format('Starting %d workers', [Workers]));
    {$ENDIF}
    SetLength(FWorkers, Workers);
    SetLength(FWorkerHandles, Workers);
    for I := 0 to Workers - 1 do
    begin
      FWorkers[I] := TSocketPoolWorker.Create(Self);
      FWorkerHandles[I] := FWorkers[I].Handle;
    end;
    {$IFDEF GRIJJYLOGGING}
    _Log.Send('Workers started');
    {$ENDIF}
  end
  else
    raise Exception.Create('CreateIoCompletionPort failed, ' +
      IntToStr(GetLastError));
end;

destructor TgoClientSocketManager.Destroy;
var
  Worker: TSocketPoolWorker;
  Timeout: LongWord;
  Connection: TgoSocketConnection;
  Start: TDateTime;
begin
  inherited Destroy;

  { There are 2 ways to shutdown and cleanup for IOCP:

    In the first scenario, you can call PostQueueCompletionStatus (N times,
    where N is the number of worker threads) to post a special completion packet
    that informs the worker thread to exit immediately, close all socket handles
    and their associated overlapped structures, and then close the completion
    port. Again, make sure you use HasOverlappedIoCompleted to check the
    completion status of an overlapped structure before you free it. If a
    socket is closed, all outstanding I/O on the socket eventually complete quickly.

    In the second scenario, you can delay exiting worker threads so that all
    completion packets can be properly dequeued. You can start by closing all
    socket handles and the IOCP. However, you need to maintain a count of the
    number of outstanding I/Os so that your worker thread can know when it is
    safe to exit the thread. }

  { destroy all pending connections }
  ConnectionsLock.Enter;
  try
    for Connection in Connections.ToArray do
    begin
      if not Connection.Closed then
      begin
        Connection.PostDisconnect;
        //closesocket(Connection.Socket);
        CancelIoEx(Connection.Socket, nil);
        Start := Now;
        while (MillisecondsBetween(Now, Start) < TIMEOUT_CLOSE) and
          (not Connection.Closed) do
          Sleep(5);
      end;
      Connection.Free;
    end;
    Connections.Free;
  finally
    ConnectionsLock.Leave;
  end;
  ConnectionsLock.Free;

  { signal the workers to quit }
  {$IFDEF GRIJJYLOGGING}
  _Log.Send('Signaling workers to quit');
  {$ENDIF}
  for Worker in FWorkers do
  begin
    PostQueuedCompletionStatus(FHandle, 0, 0, nil);
    SleepEx(10, True);
  end;

  { wait for them to stop }
  Timeout := TIMEOUT_STOP;
  WaitForMultipleObjects(Length(FWorkerHandles), Pointer(FWorkerHandles),
    True, Timeout);
  {$IFDEF GRIJJYLOGGING}
  _Log.Send('Workers finished');
  {$ENDIF}

  { destroy workers }
  for Worker in FWorkers do
    Worker.Free;

  { close the completion handle }
  if FHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FHandle);
end;

procedure TgoClientSocketManager.FreeConnections;
var
  Connection: TgoSocketConnection;
  ConnectionsToFree: TList<TgoSocketConnection>;
begin
  ConnectionsToFree := TList<TgoSocketConnection>.Create;
  try
    ConnectionsLock.Enter;
    try
      {$IFDEF GRIJJYLOGGING}
      _Log.Send('Checking for connections to free...');
      if Connections.Count > 0 then
        _Log.Send(Format('%d connections waiting to be freed', [Connections.Count]));
      {$ENDIF}
      for Connection in Connections.ToArray do
      begin
        if Connection.Closed then
        begin
          ConnectionsToFree.Add(Connection);
          Connections.Remove(Connection);
        end
        else
        if MillisecondsBetween(Now, Connection.FReleased) > INTERVAL_FREE then
        begin
          if (FBehavior = TgoSocketPoolBehavior.PoolAndReuse) and (Connection.State = TgoConnectionState.Connected) then
            Connection.Disconnect
          else
          if not Connection.FAttemptCloseSocket then
          begin
            { if the socket did not disconnect normally, we attempt to close the socket manually }
            Connection.FAttemptCloseSocket := True;
            closesocket(Connection.Socket);
          end
          {$IFDEF GRIJJYLOGGING}
          else
            _Log.Send(Format('Error! Closing connection failed (Socket=%d, Connection=%d, ThreadId=%d) Pending=%s',
            [Connection.Socket, Cardinal(Connection), GetCurrentThreadId, Connection.PendingToString]));
          {$ENDIF}
        end;
      end;
    finally
      ConnectionsLock.Leave;
    end;

    {$IFDEF GRIJJYLOGGING}
    if ConnectionsToFree.Count > 0 then
      _Log.Send(Format('Freeing %d connections', [ConnectionsToFree.Count]));
    {$ENDIF}

    for Connection in ConnectionsToFree do
    begin
      {$IFDEF GRIJJYLOGGING}
      _Log.Send(Format('Freeing connection (Socket=%d, Connection=%d, ThreadId=%d)', [Connection.Socket, Cardinal(Connection), GetCurrentThreadId]));
      {$ENDIF}
      Connection.Free;
    end;
  finally
    ConnectionsToFree.Free;
  end;
end;

procedure TgoClientSocketManager.Execute;
var
  LastCleanup: TDateTime;
begin
  {$IFDEF DEBUG}
  NameThreadForDebugging('TgoClientSocketManager');
  {$ENDIF}
  LastCleanup := Now;
  while not Terminated do
  begin
    if MillisecondsBetween(Now, LastCleanup) > INTERVAL_CLEANUP then
    begin
      FreeConnections;
      LastCleanup := Now;
    end
    else
      Sleep(5); { waiting for interval }
  end;
end;

procedure TgoClientSocketManager.Release(const AConnection: TgoSocketConnection);
{$IFDEF GRIJJYLOGGING}
var
  Socket: TSocket;
{$ENDIF}
begin
  {$IFDEF GRIJJYLOGGING}
  Socket := AConnection.Socket;
  {$ENDIF}

  {$IFDEF GRIJJYLOGGING}
  _Log.Send(Format('Releasing connection (Socket=%d, Connection=%d, ThreadId=%d)', [Socket, Cardinal(AConnection), GetCurrentThreadId]));
  {$ENDIF}

  { disconnect the socket }
  if FBehavior = TgoSocketPoolBehavior.CreateAndDestroy then
    AConnection.Disconnect;

  { track the release time }
  AConnection.FReleased := Now;

  { stop events }
  {$IFDEF GRIJJYLOGGING}
  _Log.Send(Format('Stopping callbacks for connection (Socket=%d, Connection=%d, ThreadId=%d)', [Socket, Cardinal(AConnection), GetCurrentThreadId]));
  {$ENDIF}

  { it is critical that we prevent future callbacks because the parent method
    that calls HandleFree() will be destroying other objects that may be accessed
    in those events }
  AConnection.StopCallbacks;
  {$IFDEF GRIJJYLOGGING}
  _Log.Send(Format('Callbacks stopped for connection (Socket=%d, Connection=%d, ThreadId=%d)', [Socket, Cardinal(AConnection), GetCurrentThreadId]));
  {$ENDIF}

  { add the new connection }
  ConnectionsLock.Enter;
  try
    Connections.Add(AConnection);
  finally
    ConnectionsLock.Leave;
  end;
end;

function TgoClientSocketManager.Request(const AHostname: String; const APort: Word): TgoSocketConnection;
var
  Connection: TgoSocketConnection;
begin
  if FBehavior = TgoSocketPoolBehavior.CreateAndDestroy then
    Result := TgoSocketConnection.Create(Self, AHostname, APort)
  else
  begin
    { TgoSocketPoolBehavior.PoolAndReuse }
    Result := nil;
    ConnectionsLock.Enter;
    try
      for Connection in Connections.ToArray do
      begin
        if (Connection.State = TgoConnectionState.Connected) and
          (Connection.Hostname = AHostname) and (Connection.Port = APort) then
        begin
          Connections.Remove(Connection);
          Result := Connection;
          Break;
        end;
      end;
    finally
      ConnectionsLock.Leave;
    end;
    if Result = nil then
      Result := TgoSocketConnection.Create(Self, AHostname, APort)
  end;
end;

initialization
  {$IFDEF GRIJJYLOGGING}
  _Log := TgoLogging.Create([TgoLog.ToFile, TgoLog.ToConsole, TgoLog.ToDefault], 'SocketPool');
  {$ENDIF}
  _PerIoDataPool := TgoMemoryPool.Create(SizeOf(TPerIoData));
  _MemBufferPool := TgoMemoryPool.Create(DEFAULT_BLOCK_SIZE);

finalization
  _PerIoDataPool.Free;
  _MemBufferPool.Free;
  {$IFDEF GRIJJYLOGGING}
  _Log.Free;
  {$ENDIF}

end.
