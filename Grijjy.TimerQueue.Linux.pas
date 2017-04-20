unit Grijjy.TimerQueue.Linux;
{ Linux based timer queue }

{$I Grijjy.inc}

interface

uses
  Posix.Time,
  Linuxapi.Timerfd,
  Linuxapi.Epoll,
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections;

const
  INVALID_HANDLE_VALUE = THandle(-1);

  { EPoll consts }
  IGNORED = 1;
  MAX_EVENTS = 1024;

type
  TgoTimer = class;
  TOnTimer = procedure(const ASender: TObject) of object;

  { Timer object }
  TgoTimer = class(TObject)
  private
    FHandle: THandle;
    FInterval: Cardinal;
    FOnTimer: TOnTimer;
  private
    { internal flags }
    FClose: Boolean;
    FClosed: TEvent;
  public
    constructor Create;
    destructor Destroy; override;
  public
    { Handle of the timer object }
    property Handle: THandle read FHandle write FHandle;

    { Timer interval in milliseconds }
    property Interval: Cardinal read FInterval write FInterval;

    { Timer callback event  }
    property OnTimer: TOnTimer read FOnTimer write FOnTimer;
  end;

  { Timer queue instance }
  TgoTimerQueue = class(TObject)
  private
    function _SetInterval(const AHandle: THandle; const AInterval: Cardinal): Boolean;
    procedure _Release(const ATimer: TgoTimer);
    procedure ReleaseAll;
  public
    constructor Create;
    destructor Destroy; override;
  public
    { Adds a new timer to the queue}
    function Add(const AInterval: Cardinal; const AOnTimer: TOnTimer): THandle;

    { Release an existing timer }
    procedure Release(const AHandle: THandle);

    { Change the internal rate of a timer }
    function SetInterval(const AHandle: THandle; const AInterval: Cardinal): Boolean;
  end;

  { timer queue worker thread }
  TTimerQueuePool = class;
  TTimerQueueWorker = class(TThread)
  private
    FOwner: TTimerQueuePool;
    FEvents: array[0..MAX_EVENTS] of epoll_event;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOwner: TTimerQueuePool);
    destructor Destroy; override;
  end;

  { Timer queue pool }
  TTimerQueuePool = class(TObject)
  private
    FHandle: THandle;
    FWorkers: array of TTimerQueueWorker;
  public
    constructor Create(const AWorkers: Integer = 0);
    destructor Destroy; override;
  public
    { EPoll_fd for instance }
    property Handle: THandle read FHandle;
  end;

implementation

uses
  Posix.Unistd,
  Posix.ErrNo;

var
  _Timers: TDictionary<THandle, TgoTimer>;
  _TimersLock: TCriticalSection;
  _TimerQueuePool: TTimerQueuePool;

{ TgoTimer }

constructor TgoTimer.Create;
begin
  inherited;
  FHandle := INVALID_HANDLE_VALUE;
  FInterval := 0;
  FOnTimer := nil;
  FClose := False;
  FClosed := TEvent.Create(nil, True, False, '');
end;

destructor TgoTimer.Destroy;
begin
  FClosed.Free;
  inherited;
end;

{ TgoTimerQueue }

constructor TgoTimerQueue.Create;
begin
  inherited;
end;

destructor TgoTimerQueue.Destroy;
begin
  ReleaseAll;
  inherited;
end;

function TgoTimerQueue._SetInterval(const AHandle: THandle; const AInterval: Cardinal): Boolean;
var
  NewValue: itimerspec;
  TS: timespec;
begin
  FillChar(NewValue, SizeOf(itimerspec), 0);
  TS.tv_sec := AInterval DIV 1000;
  TS.tv_nsec := (AInterval MOD 1000) * 1000000;
  NewValue.it_value := TS;
  NewValue.it_interval := TS;
  Result := timerfd_settime(AHandle, 0, @NewValue, nil) <> -1;
end;

function TgoTimerQueue.Add(const AInterval: Cardinal; const AOnTimer: TOnTimer): THandle;
var
  Handle: THandle;
  Timer: TgoTimer;
  Event: epoll_event;
begin
  Result := INVALID_HANDLE_VALUE;

  { create a non-blocking timer descriptor }
  Handle := timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK);
  if Handle <> -1 then
  begin
    { create a timer object }
    Timer := TgoTimer.Create;
    Timer.Handle := Handle;
    Timer.Interval := AInterval;
    Timer.OnTimer := AOnTimer;

    { add descriptor to the set }
    Event.data.ptr := Timer;
    Event.events := EPOLLIN or EPOLLET;
    if epoll_ctl(_TimerQueuePool.Handle, EPOLL_CTL_ADD, Handle, @Event) <> -1 then
    begin
      { start the timer }
      if _SetInterval(Handle, AInterval) then
      begin
        _TimersLock.Enter;
        try
          _Timers.Add(Handle, Timer);
        finally
          _TimersLock.Leave;
        end;
        Result := Handle;
      end
      else
        Timer.Free;
    end
    else
    begin
      __close(Handle);
      Timer.Free;
    end;
  end;
end;

procedure TgoTimerQueue._Release(const ATimer: TgoTimer);
begin
  ATimer.FClose := True;

  { timeout quickly }
  _SetInterval(ATimer.Handle, 1);

  { wait for closed signal }
  ATimer.FClosed.WaitFor(INFINITE);
  ATimer.DisposeOf;
end;

procedure TgoTimerQueue.Release(const AHandle: THandle);
var
  Timer: TgoTimer;
begin
  Timer := nil;
  _TimersLock.Enter;
  try
    if _Timers.TryGetValue(AHandle, Timer) then
      _Timers.Remove(AHandle);
  finally
    _TimersLock.Leave;
  end;
  if Timer <> nil then
    _Release(Timer);
end;

procedure TgoTimerQueue.ReleaseAll;
var
  Timer: TgoTimer;
begin
  _TimersLock.Enter;
  try
    for Timer in _Timers.Values do
      _Release(Timer);
    _Timers.Clear;
  finally
    _TimersLock.Leave;
  end;
end;

function TgoTimerQueue.SetInterval(const AHandle: THandle; const AInterval: Cardinal): Boolean;
var
  Timer: TgoTimer;
begin
  Result := False;
  _TimersLock.Enter;
  try
    if _Timers.TryGetValue(AHandle, Timer) then
      if _SetInterval(AHandle, AInterval) then
      begin
        Timer.Interval := AInterval;
        Result := True;
      end;
  finally
    _TimersLock.Leave;
  end;
end;

{ TTimerQueueWorker }

constructor TTimerQueueWorker.Create(const AOwner: TTimerQueuePool);
begin
  FOwner := AOwner;
  inherited Create(False);
end;

destructor TTimerQueueWorker.Destroy;
begin
  inherited;
end;

procedure TTimerQueueWorker.Execute;
var
  NumberOfEvents: Integer;
  I: Integer;
  Event: epoll_event;
  TotalTimeouts: Int64;
  Timer: TgoTimer;
  Error: Integer;
begin
  while not Terminated do
  begin
    NumberOfEvents := epoll_wait(FOwner.Handle, @FEvents, MAX_EVENTS, 100);
    if NumberOfEvents = 0 then { timeout }
      Continue
    else
    if NumberOfEvents = -1 then { error }
    begin
      Error := errno;
      if Error = EINTR then
        Continue
      else
        Break;
    end;
    for I := 0 to NumberOfEvents - 1 do
    begin
      try
        Timer := FEvents[I].data.ptr;
        if not Timer.FClose then
        begin
          if (FEvents[I].events AND EPOLLIN) = EPOLLIN then
          begin
            if __read(Timer.Handle, @TotalTimeouts, SizeOf(TotalTimeouts)) >= 0 then
            begin
              if Assigned(Timer.FOnTimer) then
                Timer.FOnTimer(Timer);
            end
            else
              { read error }
              Timer.FClose := True;
          end;
        end;
      finally
        if Timer.FClose then
        begin
          { remove descriptor from the set }
          epoll_ctl(_TimerQueuePool.Handle, EPOLL_CTL_DEL, Timer.Handle, @Event); { -1 on error }

          { close the timer handle }
          __close(Timer.Handle);

          { trigger closed event }
          Timer.FClosed.SetEvent;
        end;
      end;
    end;
  end;
end;

{ TTimerQueuePool }

constructor TTimerQueuePool.Create(const AWorkers: Integer);
var
  I: Integer;
  Workers: Integer;
begin
  inherited Create;

  { create the epoll instance handle }
  FHandle := epoll_create(IGNORED);
  if FHandle <> -1 then
  begin
    { create worker threads to handle queued events }
    if AWorkers = 0 then
      Workers := CPUCount
    else
      Workers := AWorkers;
    SetLength(FWorkers, Workers);
    for I := 0 to Workers - 1 do
      FWorkers[I] := TTimerQueueWorker.Create(Self);
  end
  else
    raise Exception.Create(Format('epoll_create failed %s',[SysErrorMessage(errno)]));
end;

destructor TTimerQueuePool.Destroy;
var
  Worker: TTimerQueueWorker;
begin
  { signal the workers to quit }
  for Worker in FWorkers do
    Worker.Terminate;

  { wait for them to stop }
  for Worker in FWorkers do
    Worker.WaitFor;

  { destroy workers }
  for Worker in FWorkers do
    Worker.DisposeOf;

  { close the epoll instance handle }
  if FHandle <> -1 then
    __close(FHandle);

  inherited Destroy;
end;

initialization
  _TimerQueuePool := TTimerQueuePool.Create;
  _Timers := TDictionary<THandle, TgoTimer>.Create;
  _TimersLock := TCriticalSection.Create;

finalization
  _TimersLock.Enter;
  try
    _Timers.Free;
  finally
    _TimersLock.Leave;
  end;
  _TimersLock.Free;
  _TimerQueuePool.Free;

end.