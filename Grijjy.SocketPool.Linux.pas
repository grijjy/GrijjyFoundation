unit Grijjy.SocketPool.Linux;

{ Linux epoll based socket pool }

{ TODO: Use epoll_pwait with a signal or an eventfd instead of a timeout to quit the thread }

{$I Grijjy.inc}

interface

uses
  Posix.Unistd,
  Posix.SysSocket,
  Posix.NetinetIn,
  Posix.ArpaInet,
  Posix.NetDB,
  System.Net.Socket,
  Linuxapi.Epoll,
  Classes,
  DateUtils,
  SysUtils,
  SyncObjs,
  System.Generics.Collections,
  Grijjy.OpenSSL,
  Grijjy.Collections,
  Grijjy.MemoryPool;

const
  DEFAULT_BLOCK_SIZE = 4096;
  IGNORED = 1;
  MAX_EVENTS = 100;
  INTERVAL_CLEANUP = 10000;
  INTERVAL_FREE = 5000;

type
  TgoClientSocketManager = class;
  TgoSocketConnection = class;

  { Internal performance optimization }
  TgoSocketOptimization = (Speed, Scale);

  { Internal socket pool behavior }
  TgoSocketPoolBehavior = (CreateAndDestroy, PoolAndReuse);

  { Internal connection state }
  TgoConnectionState = (Disconnected, Disconnecting, Connected);

  { Callback events }
  TgoSocketNotifyEvent = procedure of object;
  TgoSocketDataEvent = procedure(const ABuffer: Pointer; const ASize: Integer) of object;

  { Socket connection instance }
  TgoSocketConnection = class(TObject)
  private
    FOwner: TgoClientSocketManager;
    FSocket: THandle;
    FHostname: String;
    FPort: Word;
    FState: TgoConnectionState;
    FPending: Integer;
    FShutdown: Integer;
    FClosed: Integer;
    FOpenSSL: TgoOpenSSL;
    FReleased: TDateTime;
    FAttemptCloseSocket: Boolean;

    { Log system related errors }
    {$IFDEF GRIJJYLOGGING}
    procedure HandleError(const AError: UnicodeString; const AErrNo: Integer = 0);
    {$ENDIF}

    { Pending operations }
    procedure AddRef; inline;
    procedure ReleaseRef; inline;
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

    procedure SetSSL(const Value: Boolean);
    procedure SetCertificate(const Value: TBytes);
    procedure SetPassword(const Value: UnicodeString);
    procedure SetPrivateKey(const Value: TBytes);
    function GetCertificate: TBytes;
    function GetPassword: UnicodeString;
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
    procedure SetShutdown(AValue: Boolean);

    { Resets the connection }
    procedure Reset;

    { Read from the socket }
    function DoRead(AReadBuffer: Pointer): Boolean;

    { Write to the socket }
    function DoWrite(const ABuffer: Pointer; ASize: Integer): Boolean;

    { Connect the socket }
    function DoConnect(const AHostname: UnicodeString; const APort: Word): Boolean;

    { Disconnect the socket }
    function DoDisconnect: Boolean;
  private
    { Handle data that is read from the socket }
    procedure Read(const ABuffer: Pointer; const ASize: Integer); inline;

    { Write data to the socket }
    function Write(const ABuffer: Pointer; const ASize: Integer): Boolean; inline;
  public
    constructor Create(const AOwner: TgoClientSocketManager; const AHostname: UnicodeString; const APort: Word);
    destructor Destroy; override;
  public
    { Connects the socket }
    function Connect: Boolean;

    { Disconnects the socket }
    procedure Disconnect;

    { Sends the bytes to the socket }
    function Send(const ABytes: TBytes): Boolean;

    { Stops all future callback events }
    procedure StopCallbacks;
  public
    { Socket handle }
    property Socket: THandle read FSocket;

    { Hostname }
    property Hostname: String read FHostname write FHostname;

    { Port }
    property Port: Word read FPort write FPort;

    { Current state of the socket connection }
    property State: TgoConnectionState read FState write FState;

    { Number of pending operations on the socket }
    property Pending: Integer read GetPending write FPending;

    { Socket is shutdown }
    property Shutdown: Boolean read GetShutdown write SetShutdown;

    { Connection is closed }
    property Closed: Boolean read GetClosed write SetClosed;

    { OpenSSL interface }
    property OpenSSL: TgoOpenSSL read GetOpenSSL;
  public
    { Using SSL }
    property SSL: Boolean read FSSL write SetSSL;

    { Using ALPN }
    property ALPN: Boolean read FALPN write FALPN;

    { Certificate in PEM format }
    property Certificate: TBytes read GetCertificate write SetCertificate;

    { Private key in PEM format }
    property PrivateKey: TBytes read GetPrivateKey write SetPrivateKey;

    { Password for private key }
    property Password: UnicodeString read GetPassword write SetPassword;
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
    FEvents: array[0..MAX_EVENTS] of epoll_event;

    { Recv buffer }
    FReadBuffer: Pointer;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOwner: TgoClientSocketManager);
    destructor Destroy; override;
  end;

  { Client socket manager }
  TgoClientSocketManager = class(TThread)
  private
    FHandle: Integer;
    FOptimization: TgoSocketOptimization;
    FBehavior: TgoSocketPoolBehavior;
    FWorkers: array of TSocketPoolWorker;
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
    function Request(const AHostname: UnicodeString; const APort: Word): TgoSocketConnection;
  public
    { EPoll_fd for instance }
    property Handle: Integer {THandle} read FHandle;

    { Optimization mode }
    property Optimization: TgoSocketOptimization read FOptimization;
  end;

implementation

uses
{$IFDEF GRIJJYLOGGING}
  Grijjy.System.Logging,
{$ENDIF}
  Posix.Pthread,
  Posix.ErrNo;

var
  {$IFDEF GRIJJYLOGGING}
  _Log: TgoLogging;
  {$ENDIF}
  _MemBufferPool: TgoMemoryPool;

function SocketCheck(const AHandle: TSocketHandle): Boolean;
var
  Error, ErrorLength: Cardinal;
begin
  ErrorLength := SizeOf(Error);
  if getsockopt(AHandle, SOL_SOCKET, SO_ERROR, Error, ErrorLength) = 0 then
    Result := Error = 0
  else
    Result := False;
end;

{ TgoSocketConnection }

constructor TgoSocketConnection.Create(const AOwner: TgoClientSocketManager; const AHostname: UnicodeString; const APort: Word);
begin
  inherited Create;
  FOwner := AOwner;
  FHostname := AHostname;
  FPort := APort;
  FState := TgoConnectionState.Disconnected;
  FShutdown := 0;
  FPending := 0;
  FClosed := 0;
  FAttemptCloseSocket := False;
  FReleased := -1;
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
  if FOpenSSL <> nil then
    FOpenSSL.Free;
  FOnConnectedLock.Free;
  FOnDisconnectedLock.Free;
  FOnRecvLock.Free;
  FOnSentLock.Free;
  inherited Destroy;
end;

{$IFDEF GRIJJYLOGGING}
procedure TgoSocketConnection.HandleError(const AError: UnicodeString; const AErrNo: Integer);
begin
  _Log.Send(Format('Error! %s (Socket=%d, Connection=%d, ThreadId=%d, Error=%d, SysErrorMessage=%s)',
    [AError, FSocket, UIntPtr(Self), GetCurrentThreadId, AErrNo, SysErrorMessage(AErrNo)]));
end;
{$ENDIF}

procedure TgoSocketConnection.AddRef;
begin
  TInterlocked.Increment(FPending);
end;

procedure TgoSocketConnection.ReleaseRef;
begin
  TInterlocked.Decrement(FPending);
end;

procedure TgoSocketConnection.SetSSL(const Value: Boolean);
begin
  if FSSL then
    if FOpenSSL <> nil then
    begin
      FOpenSSL.Free;
      FOpenSSL := nil;
    end;
  FSSL := Value;
end;

procedure TgoSocketConnection.SetCertificate(const Value: TBytes);
begin
  OpenSSL.Certificate := Value;
end;

procedure TgoSocketConnection.SetPassword(const Value: UnicodeString);
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

function TgoSocketConnection.GetPassword: UnicodeString;
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
  DoWrite(ABuffer, ASize);
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
begin
  Result := TInterlocked.CompareExchange(FPending, 0, 0);
end;

procedure TgoSocketConnection.SetClosed(AValue: Boolean);
begin
  TInterlocked.Increment(FClosed);
end;

function TgoSocketConnection.GetClosed: Boolean;
begin
  Result := TInterlocked.CompareExchange(FClosed, 0, 0) <> 0;
end;

procedure TgoSocketConnection.SetShutdown(AValue: Boolean);
begin
  TInterlocked.Increment(FShutdown);
end;

function TgoSocketConnection.GetShutdown: Boolean;
begin
  Result := TInterlocked.CompareExchange(FShutdown, 0, 0) <> 0;
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

function TgoSocketConnection.DoRead(AReadBuffer: Pointer): Boolean;
var
  BytesReceived: Integer;
  Error: Integer;
begin
  Result := False;
  BytesReceived := Posix.SysSocket.recv(FSocket, AReadBuffer^, DEFAULT_BLOCK_SIZE, 0);
  if BytesReceived > 0 then
  begin
    Read(AReadBuffer, BytesReceived);
    Result := True;
  end
  else
    { an error has happened }
    if BytesReceived < 0 then
    begin
      Error := errno;
      if Error = EINTR then
        Result := True
      else
      if Error = EAGAIN then
        Result := True
      else
      begin
        {$IFDEF GRIJJYLOGGING}
        HandleError('DoRead.Receive', Error);
        {$ENDIF}
      end;
    end
//    else
//      { socket has closed }
//      grLog('DoRead.BytesReceived = 0');
end;

function TgoSocketConnection.DoWrite(const ABuffer: Pointer; ASize: Integer): Boolean;
begin
  Result := False;
  if Shutdown then Exit;
  //grLog('DoWrite', ABuffer, ASize);
  if Posix.SysSocket.send(FSocket, ABuffer^, ASize, 0) = -1 then
  begin
    {$IFDEF GRIJJYLOGGING}
    HandleError('DoWrite.Send', errno);
    {$ENDIF}
  end
  else
  begin
    if Assigned(FOnSent) then
      FOnSent(ABuffer, ASize);
    Result := True;
  end;
end;

function TgoSocketConnection.DoConnect(const AHostname: UnicodeString; const APort: Word): Boolean;
var
  ConnectAddr: sockaddr_in;
  Event: epoll_event;
  HostEnt: PHostEnt;

begin
  Result := False;
  if Shutdown then Exit;

  { create socket }
  FSocket := Posix.SysSocket.socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
  //grLog('Socket', FSocket);
  if FSocket = -1 then
  begin
    Closed := True;
    Exit;
  end;

  { We could use TIPAddress.LookupName(AHostname) here to obtain the address related
    to the host name but the Delphi routine appears to be unreliable because
    it calls gethostbyname() without being null terminated,
    HostEnt := gethostbyname(MarshaledAString(TEncoding.UTF8.GetBytes(Name)));

    This should probably be...
    HostEnt := gethostbyname(MarshaledAString(TEncoding.UTF8.GetBytes(Name + #0)));
    or
    HostEnt := gethostbyname(MarshaledAString(Utf8String(Name))); because the Utf8String
    is null terminated internally.

    unfortunately this one bug makes using the entire System.Net.Socket not feasible
    as everything is related to this initial connection sequence.
  }

  { get host name }
  FillChar(ConnectAddr, SizeOf(ConnectAddr), 0);
  ConnectAddr.sin_family := PF_INET;
  HostEnt := gethostbyname(MarshaledAString(Utf8String(AHostname)));
  if HostEnt <> nil then
    ConnectAddr.sin_addr.s_addr := PCardinal(HostEnt.h_addr_list^)^
  else
  begin
    Posix.Unistd.__close(FSocket);
    Closed := True;
    Exit;
  end;
  ConnectAddr.sin_port := htons(APort);

  //_Log('Connect');
  { connect }
  if Posix.SysSocket.connect(FSocket, sockaddr(ConnectAddr), SizeOf(ConnectAddr)) = -1 then
  begin
    {$IFDEF GRIJJYLOGGING}
    HandleError('DoConnect.Connect', errno);
    {$ENDIF}
    Posix.Unistd.__close(FSocket);
    Closed := True;
    Exit;
  end;

  { add descriptor to the EPoll set }
  Event.data.ptr := Self;

  { we use EPOLLOUT as an initial signal for connected }
  Event.events := EPOLLIN or EPOLLOUT or EPOLLET or EPOLLONESHOT or EPOLLRDHUP;
  if epoll_ctl(FOwner.Handle, EPOLL_CTL_ADD, FSocket, @Event) = -1 then
  begin
    {$IFDEF GRIJJYLOGGING}
    HandleError('DoConnect.epoll_ctl', errno);
    {$ENDIF}
    Posix.Unistd.__close(FSocket);
    Closed := True;
    Exit;
  end;
  Result := True;
end;

function TgoSocketConnection.DoDisconnect: Boolean;
begin
  Result := False;
  //grLog('DoDisconnect');
  if Shutdown then Exit;
  Shutdown := True;

  { if the connection was reset by the peer, the socket will be invalid at this point
    so we check the socket first }
  if SocketCheck(FSocket) then
    if Posix.SysSocket.shutdown(FSocket, SHUT_RDWR) = -1 then
    begin
      {$IFDEF GRIJJYLOGGING}
      HandleError('DoDisconnect.Close', errno);
      {$ENDIF}
    end
    else
      Result := True;
end;

procedure TgoSocketConnection.Reset;
begin
  FShutdown := 0;
  FClosed := 0;
  FAttemptCloseSocket := False;
  FReleased := -1;
end;

function TgoSocketConnection.Connect: Boolean;
begin
  Reset;
  if DoConnect(FHostname, FPort) then
    Result := True
  else
    Result := False;
end;

procedure TgoSocketConnection.Disconnect;
begin
  //grLog('Disconnect');

  { if not already shutdown, then post disconnect }
  if not Shutdown then
  begin
    FState := TgoConnectionState.Disconnecting;
    DoDisconnect;
  end;
end;

function TgoSocketConnection.Send(const ABytes: TBytes): Boolean;
begin
  Result := Write(ABytes, Length(ABytes));
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
    Result := DoWrite(ABuffer, ASize);
end;

{ TSocketPoolWorker }

constructor TSocketPoolWorker.Create(const AOwner: TgoClientSocketManager);
begin
  FOwner := AOwner;
  if FOwner.Optimization = TgoSocketOptimization.Speed then
    FReadBuffer := _MemBufferPool.RequestMem{$IFDEF TRACK_MEMORY}('_TSocketPoolWorker.ReadBuffer'){$ENDIF}
  else
    FReadBuffer := nil;
  inherited Create;
end;

destructor TSocketPoolWorker.Destroy;
begin
  if FReadBuffer <> nil then
    _MemBufferPool.ReleaseMem(FReadBuffer {$IFDEF TRACK_MEMORY}, '_TSocketPoolWorker.ReadBuffer'{$ENDIF});
  inherited;
end;

procedure TSocketPoolWorker.Execute;
var
  NumberOfEvents: Integer;
  I: Integer;
  Connection: TgoSocketConnection;
  ReadBuffer: Pointer;
  Event: epoll_event;
  Close: Boolean;
  Error: Integer;
begin
  while True do
  begin
    NumberOfEvents := epoll_pwait(FOwner.Handle, @FEvents, MAX_EVENTS, 100, nil);
    if NumberOfEvents = 0 then { timeout }
    begin
      //grLog('Timeout');
      Continue;
    end
    else
    if NumberOfEvents = -1 then { error }
    begin
      Error := errno;
      //grLog('Error', Error);
      if Error = EINTR then
        Continue
      else
      begin
        {$IFDEF GRIJJYLOGGING}
        _Log.Send(Format('Error! epoll_pwait (ThreadId=%d, Error=%d, SysErrorMessage=%s)',
          [GetCurrentThreadId, Error, SysErrorMessage(Error)]));
        {$ENDIF}
        Break;
      end;
    end;
    //grLog('NumberOfEvents', NumberOfEvents);
    for I := 0 to NumberOfEvents - 1 do
    begin
      Close := False;
      Connection := FEvents[I].data.ptr;
      {$IFDEF GRIJJYLOGGING}
      _Log.Send(Format('Event %s (Socket=%d, Connection=%d, ThreadId=%d)',
        [EventToString(FEvents[I]), Connection.Socket, UIntPtr(Connection), GetCurrentThreadId]));
      {$ENDIF}
      Connection.AddRef;
      try
        { EPOLLIN means the associated descriptor is available for read operations }
        if (FEvents[I].events AND EPOLLIN) = EPOLLIN then
        begin
          if FOwner.Optimization = TgoSocketOptimization.Scale then
          begin
            { scale optimization we allocation the read buffer each time }
            ReadBuffer := _MemBufferPool.RequestMem{$IFDEF TRACK_MEMORY}('_TSocketPoolWorker.ReadBuffer'){$ENDIF};
            try
              { although the documentation recommends using a non-blocking socket
                with edge triggered polling and looping receive until we get an EAGAIN
                I have found that using blocking sockets also works if you perform a
                single read with each EPOLLIN event and allow other threads to continue
                the process of receiving.  this is similar to how Windows IOCP works
                with the advantage to this approach is it may allow greater scalability to
                a server with many socket connections and should prevent a continuous
                socket receive from starving the thread }
              if not Connection.DoRead(ReadBuffer) then
                Close := True;
            finally
              _MemBufferPool.ReleaseMem(ReadBuffer {$IFDEF TRACK_MEMORY}, '_TSocketPoolWorker.ReadBuffer'{$ENDIF});
            end;
          end
          else
          begin
            if not Connection.DoRead(FReadBuffer) then
              Close := True;
          end;
        end
        else
        { EPOLLOUT means the associated descriptor is available for write operations }
        if (FEvents[I].events AND EPOLLOUT) = EPOLLOUT then
        begin
          { EPOLLOUT is only called once, to signal the initial connection
            has succeeded and the socket is ready to be written }
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
        end
        else
        { EPOLLIN and EPOLLRDHUP may both been set in the previous iteration,
          but we only get here if EPOLLIN and EPOLLOUT are not set.  This allows
          us to read all the data that is pending before closing the socket }

        { EPOLLRDHUP means the peer closed the connection, or shut down writing half of connection }
        if ((FEvents[I].events AND EPOLLRDHUP) = EPOLLRDHUP) or
        { EPOLLERR and EPOLLHUP means an error happened with the descriptor.  Usually a connection
          reset by peer (RST) instead of (FIN).  This can also happen if the peer is using
          SO_LINGER of zero and other situations where the connection was interrupted.
          epoll_pwait will always wait for EPOLLERR, it is not necessary to set it }
          ((FEvents[I].events AND EPOLLHUP) = EPOLLHUP) or
          ((FEvents[I].events AND EPOLLERR) = EPOLLERR) then
        begin
          { to determine the error, call SocketCheck }
          Close := True;
        end;
      finally
        Connection.ReleaseRef;
        { if the shutdown flag for the connection object is True, then
          this close was gracefully triggered by the application, otherwise it
          is an abrupt close of the socket }
        if Close then
        begin
          //grLog('Close');
          { remove descriptor from the set }
          if epoll_ctl(FOwner.Handle, EPOLL_CTL_DEL, Connection.Socket, @Event) = -1 then
          begin
            {$IFDEF GRIJJYLOGGING}
            Connection.HandleError('epoll_ctl_del', errno);
            {$ENDIF}
          end;

          { free the socket handle }
          Posix.Unistd.__close(Connection.Socket);

          {$IFDEF GRIJJYLOGGING}
          _Log.Send(Format('Closesocket (Socket=%d, Connection=%d, ThreadId=%d Pending=%d)',
            [Connection.Socket, UIntPtr(Connection), GetCurrentThreadId, Connection.Pending]));
          {$ENDIF}

          { disconnected event }
          Connection.FOnDisconnectedLock.Enter;
          try
            { disconnected event }
            if Assigned(Connection.FOnDisconnected) then
              Connection.FOnDisconnected;
          finally
            Connection.FOnDisconnectedLock.Leave;
          end;
          Connection.State := TgoConnectionState.Disconnected;

          { trigger closed event }
          Connection.Closed := True;
        end
        else
        begin
          { EPOLLONESHOT serializes all EPoll events with a common descriptor and
            only triggers the next event when epoll_ctl for the descriptor is set after
            each iteration.  This is useful for multi-threaded worker scenarios.
            Newer Linux kernels offer EPOLLEXCLUSIVE flag as a better alternative. }
          FEvents[I].events := EPOLLIN or EPOLLET or EPOLLONESHOT or EPOLLRDHUP;
          if epoll_ctl(FOwner.Handle, EPOLL_CTL_MOD, Connection.Socket, @FEvents[I]) = -1 then
          begin
            {$IFDEF GRIJJYLOGGING}
            Connection.HandleError('epoll_ctl_mod', errno);
            {$ENDIF}
          end;
        end;
      end;
    end;
  end;
  //grLog('Worker thread finished.');
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

  { create the epoll instance handle }
  FHandle := epoll_create(IGNORED);
  if FHandle <> -1 then
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
    for I := 0 to Workers - 1 do
      FWorkers[I] := TSocketPoolWorker.Create(Self);
    {$IFDEF GRIJJYLOGGING}
    _Log.Send('Workers started');
    {$ENDIF}
  end
  else
    raise Exception.Create(Format('epoll_create failed %s',[SysErrorMessage(errno)]));
end;

destructor TgoClientSocketManager.Destroy;
var
  Worker: TSocketPoolWorker;
  Connection: TgoSocketConnection;
begin
  { destroy all pending connections }
  ConnectionsLock.Enter;
  try
    for Connection in Connections.ToArray do
    begin
      if not Connection.Closed then
        Posix.Unistd.__close(Connection.Socket);
      Connection.DisposeOf;
    end;
    Connections.DisposeOf;
  finally
    ConnectionsLock.Leave;
  end;
  ConnectionsLock.Free;

  { signal the workers to quit }
  {$IFDEF GRIJJYLOGGING}
  _Log.Send('Signaling workers to quit');
  {$ENDIF}
  for Worker in FWorkers do
    Worker.Terminate;

  { wait for them to stop }
  for Worker in FWorkers do
    Worker.WaitFor;
  {$IFDEF GRIJJYLOGGING}
  _Log.Send('Workers finished');
  {$ENDIF}

  { close the epoll instance handle }
  if FHandle <> -1 then
    Posix.Unistd.__close(FHandle);

  inherited Destroy;
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
          //_Log.Send(Format('Set free Connection (Socket=%d, Connection=%d, ThreadId=%d)', [Connection.Socket, Cardinal(Connection), GetCurrentThreadId]));
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
            Posix.Unistd.__close(Connection.Socket);
          end
          {$IFDEF GRIJJYLOGGING}
          else
            _Log.Send(Format('Error! Closing connection failed (Socket=%d, Connection=%d, ThreadId=%d) Pending=%d',
            [Connection.Socket, Cardinal(Connection), GetCurrentThreadId, Connection.Pending]));
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
      Connection.DisposeOf;
    end;
  finally
    ConnectionsToFree.Free;
  end;
end;

procedure TgoClientSocketManager.Execute;
var
  LastCleanup: TDateTime;
begin
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
  Socket: THandle;
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
    {$IFDEF GRIJJYLOGGING}
    _Log.Send(Format('Add connection (Socket=%d, Connection=%d, ThreadId=%d)', [AConnection.Socket, Cardinal(AConnection), GetCurrentThreadId]));
    {$ENDIF}
    Connections.Add(AConnection);
  finally
    ConnectionsLock.Leave;
  end;
end;

function TgoClientSocketManager.Request(const AHostname: UnicodeString; const APort: Word): TgoSocketConnection;
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
          (Connection.FHostname = AHostname) and (Connection.FPort = APort) then
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
  _MemBufferPool := TgoMemoryPool.Create(DEFAULT_BLOCK_SIZE);

finalization
  _MemBufferPool.Free;
  {$IFDEF GRIJJYLOGGING}
  _Log.Free;
  {$ENDIF}

end.