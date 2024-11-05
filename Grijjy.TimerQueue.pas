unit Grijjy.TimerQueue;
{ Cross platform thread pool timer queue }

{ This class provides a method to execute timer events in a thread
  that occur outside of the main application or UI thread.  Most operating
  systems provide an efficient kernel managed thread pool specificially for
  threaded timers and we utilize that in this class for each OS. }

{ On Windows we use the CreateTimerQueueTimer() API to allow the OS/kernel to manage
  the thread pool and callback.

  On Android we use the JScheduledThreadPoolExecutor class and JRunnable to allow
  the OS to manage the thread pool

  On macOS/iOS we use the Grand Central Dispatcher and allow the OS
  the OS to manage the thread pool

  On Linux64 we use Epoll and the TimerFd capability to signal timer events
  along with our own managed thread pool

  Note: On some platforms the timer callback will only fire after the previous iteration
  has completed, but on other platforms the callback will overlap at the interval.
}

{$I Grijjy.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  {$IF Defined(MSWINDOWS)}
  Winapi.Windows,
  {$ELSEIF Defined(ANDROID)}
  Androidapi.JNI.Os,
  Androidapi.JNI.JavaTypes,
  Androidapi.JNIBridge,
  {$ELSEIF Defined(LINUX)}
  Posix.Time,
  Linuxapi.Timerfd,
  Linuxapi.Epoll,
  {$ELSEIF Defined(IOS)}
  iOSapi.CocoaTypes,
  Macapi.CoreServices,
  Macapi.Dispatch,
  Macapi.Gcd,
  Grijjy.CodeBlocks,
  {$ELSEIF Defined(MACOS)}
  Macapi.CocoaTypes,
  Macapi.CoreServices,
  Macapi.Dispatch,
  Macapi.Gcd,
  Grijjy.CodeBlocks,
  {$ELSE}
    {$MESSAGE Error 'Unsupported platform'}
  {$ENDIF}
  System.Generics.Collections,
  System.SyncObjs,
  System.DateUtils;

const
  // Default size of the scheduled thread pool executor
  ANDROID_THREAD_POOL_SIZE = 5;

const
  INVALID_HANDLE_VALUE = THandle(-1);

  // EPoll consts
  IGNORED = 1;
  MAX_EVENTS = 1024;


{$IFDEF ANDROID}
  // Workaround for Delphi interface for JScheduledFuture, not inheriting properly
  // from JFuture
type
  _JScheduledThreadPoolExecutor = interface;

  _JScheduledFutureClass = interface(JFutureClass)
    ['{4540CECE-4394-4969-AAAF-8C40ED55DAB8}']
  end;

  [JavaSignature('java/util/concurrent/ScheduledFuture')]
  _JScheduledFuture = interface(JFuture)
    ['{1705E2E4-32D7-420F-B98C-7A646E26EA3F}']
  end;
  _TJScheduledFuture = class(TJavaGenericImport<_JScheduledFutureClass, _JScheduledFuture>) end;

  _JScheduledThreadPoolExecutorClass = interface(JThreadPoolExecutorClass)
    ['{E97835A3-4211-4A02-AC53-E0951A70BFCE}']
    {class} function init(corePoolSize: Integer): _JScheduledThreadPoolExecutor; cdecl; overload;
    {class} function init(corePoolSize: Integer; threadFactory: JThreadFactory): _JScheduledThreadPoolExecutor; cdecl; overload;
    {class} function init(corePoolSize: Integer; handler: JRejectedExecutionHandler): _JScheduledThreadPoolExecutor; cdecl; overload;
    {class} function init(corePoolSize: Integer; threadFactory: JThreadFactory; handler: JRejectedExecutionHandler): _JScheduledThreadPoolExecutor; cdecl; overload;
  end;

  [JavaSignature('java/util/concurrent/ScheduledThreadPoolExecutor')]
  _JScheduledThreadPoolExecutor = interface(JThreadPoolExecutor)
    ['{AE701E15-A4FE-4EDA-A9DE-0953F361F123}']
    function scheduleAtFixedRate(command: JRunnable; initialDelay: Int64; period: Int64; unit_: JTimeUnit): _JScheduledFuture; cdecl;
  end;
  _TJScheduledThreadPoolExecutor = class(TJavaGenericImport<_JScheduledThreadPoolExecutorClass, _JScheduledThreadPoolExecutor>) end;
{$ENDIF}

type
  TgoTimer = class;
  TgoTimerQueue = class;

  TOnTimer = procedure(const ASender: TObject) of object;

  // Timer object
  TgoTimer = class(TObject)
  private
    [weak] FTimerQueue: TgoTimerQueue;
    FInterval: Cardinal;
    FOnTimer: TOnTimer;
    FHandle: THandle;
  private
    {$IFDEF LINUX}
    FClose: Boolean;
    FClosed: TEvent;
    {$ENDIF}

    {$IFDEF ANDROID}
    FRunnable: JRunnable;
    FScheduledFuture: _JScheduledFuture;
    {$ENDIF}

    {$IFDEF MACOS}
    FDispatchTimer: dispatch_source_t;
    {$ENDIF}
  private
    {$IFDEF ANDROID}
    type
      TAndroidRunnable = class(TJavaLocal, JRunnable)
      private
        FTimer: TgoTimer;
      public
        constructor Create(const ATimer: TgoTimer);
        procedure run; cdecl;
      end;
    {$ENDIF}
  protected
    procedure SetInterval(const AInterval: Cardinal);
  public
    constructor Create(const ATimerQueue: TgoTimerQueue; const AInterval: Cardinal; const AOnTimer: TOnTimer);
    destructor Destroy; override;
  public
    // Handle of the timer object
    property Handle: THandle read FHandle;

    // Timer interval in milliseconds
    property Interval: Cardinal read FInterval write SetInterval;

    // Timer callback
    property OnTimer: TOnTimer read FOnTimer write FOnTimer;
  end;

  // Timer queue instance
  TgoTimerQueue = class(TObject)
  private
    {$IFDEF MSWINDOWS}
    FHandleTimerQueue: THandle;
    {$ENDIF}

    {$IFDEF MACOS}
    FGlobalQueue: dispatch_queue_t;
    {$ENDIF}
  private
    procedure ReleaseAll;

    {$IFDEF MACOS}
    function GetGlobalQueue: dispatch_queue_t;
    {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
  public
    // Adds a new timer to the queue
    function Add(const AInterval: Cardinal; const AOnTimer: TOnTimer): THandle;

    // Release an existing timer
    procedure Release(const AHandle: THandle);

    // Change the internal rate of a timer
    function SetInterval(const AHandle: THandle; const AInterval: Cardinal): Boolean;
  public
    {$IFDEF MSWINDOWS}
    property HandleTimerQueue: THandle read FHandleTimerQueue;
    {$ENDIF}

    {$IFDEF MACOS}
    property GlobalQueue: dispatch_queue_t read GetGlobalQueue;
    {$ENDIF}
  end;

  {$IFDEF LINUX}
  // Linux Epoll timer queue worker thread
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

  // Linux Epoll timer queue pool
  TTimerQueuePool = class(TObject)
  private
    FHandle: THandle;
    FWorkers: array of TTimerQueueWorker;
  public
    constructor Create(const AWorkers: Integer = 0);
    destructor Destroy; override;
  public
    // EPoll_fd for instance
    property Handle: THandle read FHandle;
  end;
  {$ENDIF}

implementation

{$IFDEF LINUX}
uses
  Posix.Unistd,
  Posix.ErrNo;
{$ENDIF}

var
  _Timers: TObjectDictionary<THandle, TgoTimer>;
  _TimersLock: TCriticalSection;
  _TimersHandle: THandle = 0;

  {$IFDEF LINUX}
  _TimerQueuePool: TTimerQueuePool;
  {$ENDIF}

  {$IFDEF ANDROID}
  ScheduledThreadPoolExecutor: _JScheduledThreadPoolExecutor;
  {$ENDIF}

{ Helpers }

procedure _Lock;
begin
  _TimersLock.Enter;
end;

procedure _Unlock;
begin
  _TimersLock.Leave;
end;

{$IFDEF MSWINDOWS}
procedure WaitOrTimerCallback(Timer: TgoTimer; TimerOrWaitFired: ByteBool); stdcall;
begin
  if Assigned(Timer) then
  begin
    _Lock;
    try
      if not _Timers.ContainsKey(Timer.Handle) then
        Exit;
    finally
      _Unlock;
    end;
    if TimerOrWaitFired then
      if Assigned(Timer.OnTimer) then
        Timer.OnTimer(Timer);
  end;
end;
{$ENDIF}

{ TgoTimer }

constructor TgoTimer.Create(const ATimerQueue: TgoTimerQueue; const AInterval: Cardinal; const AOnTimer: TOnTimer);
{$IFDEF LINUX}
var
  Event: epoll_event;
{$ENDIF}
begin
  inherited Create;

  FTimerQueue := ATimerQueue;
  FInterval := AInterval;
  FOnTimer := AOnTimer;

  {$IF Defined(MSWINDOWS)}
  if not CreateTimerQueueTimer(FHandle, ATimerQueue.HandleTimerQueue, @WaitOrTimerCallback, Self, 0, AInterval, 0) then
    FHandle := INVALID_HANDLE_VALUE;

  {$ELSEIF Defined(ANDROID)}
  FHandle := AtomicIncrement(_TimersHandle);

  // With scheduleWithFixedDelay(), the scheduler will wait for the task to complete
  // and then wait for five seconds before executing it again.
  // With scheduleWithFixedRate() if you set the period to five seconds then it
  // means that every five seconds your task will be executed
  FRunnable := TAndroidRunnable.Create(Self);
  FScheduledFuture := ScheduledThreadPoolExecutor.scheduleAtFixedRate(FRunnable, AInterval, AInterval, TJTimeUnit.JavaClass.MILLISECONDS);

  {$ELSEIF Defined(LINUX)}
  FHandle := INVALID_HANDLE_VALUE;
  FClose := False;
  FClosed := TEvent.Create(nil, True, False, '');

  // Create a non-blocking timer descriptor
  FHandle := timerfd_create(CLOCK_MONOTONIC, TFD_NONBLOCK);
  if FHandle <> -1 then
  begin
    // Add descriptor to the set
    Event.data.ptr := Self;
    Event.events := EPOLLIN or EPOLLET;
    if epoll_ctl(_TimerQueuePool.Handle, EPOLL_CTL_ADD, FHandle, @Event) <> -1 then
      // start the timer
      SetInterval(AInterval)
    else
      __close(FHandle);
  end;

  {$ELSEIF Defined(MACOS)}
  FHandle := AtomicIncrement(_TimersHandle);

  FDispatchTimer := dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, FTimerQueue.GlobalQueue);
  if Assigned(FDispatchTimer) then
  begin
    dispatch_source_set_timer(FDispatchTimer,
      dispatch_time(DISPATCH_TIME_NOW, AInterval * NSEC_PER_MSEC), // Start delay
      AInterval * NSEC_PER_MSEC, // Interval
      0); // Leeway

    dispatch_source_set_event_handler(FDispatchTimer,
      TObjCBlock.CreateBlockWithProcedure(
        procedure(p1: NSInteger; p2: Pointer)
        begin
          if Assigned(FOnTimer) then
            FOnTimer(Self);
        end));

    dispatch_resume(FDispatchTimer);
  end;
  {$ENDIF}
end;

destructor TgoTimer.Destroy;
begin
  {$IF Defined(MSWINDOWS)}
  // DeleteTimerQueueTimer API will block until all the callbacks are completed
  DeleteTimerQueueTimer(FTimerQueue.HandleTimerQueue, FHandle, INVALID_HANDLE_VALUE);

  {$ELSEIF Defined(ANDROID)}
  ScheduledThreadPoolExecutor.remove(FRunnable);

  {$ELSEIF Defined(LINUX)}
  FClose := True;

  // Timeout quickly
  SetInterval(1);

  // Wait for closed signal
  FClosed.WaitFor(INFINITE);
  FClosed.Free;

  {$ELSEIF Defined(MACOS)}
  dispatch_source_cancel(FDispatchTimer);
  FDispatchTimer := nil;
  {$ENDIF}

  inherited;
end;

procedure TgoTimer.SetInterval(const AInterval: Cardinal);
{$IFDEF LINUX}
var
  NewValue: itimerspec;
  TS: timespec;
{$ENDIF}
begin
  {$IF Defined(MSWINDOWS)}
  if not ChangeTimerQueueTimer(FTimerQueue.HandleTimerQueue, FHandle, 0, AInterval) then
    Exit;

  {$ELSEIF Defined(ANDROID)}
  FScheduledFuture.cancel(True);
  FScheduledFuture := ScheduledThreadPoolExecutor.scheduleAtFixedRate(FRunnable, AInterval, AInterval, TJTimeUnit.JavaClass.MILLISECONDS);

  {$ELSEIF Defined(LINUX)}
  FillChar(NewValue, SizeOf(itimerspec), 0);
  TS.tv_sec := AInterval DIV 1000;
  TS.tv_nsec := (AInterval MOD 1000) * 1000000;
  NewValue.it_value := TS;
  NewValue.it_interval := TS;
  if timerfd_settime(FHandle, 0, @NewValue, nil) = -1 then
    Exit;

  {$ELSEIF Defined(MACOS)}
  if Assigned(FDispatchTimer) then
    dispatch_source_set_timer(FDispatchTimer,
      dispatch_time(DISPATCH_TIME_NOW, AInterval * NSEC_PER_MSEC),
      AInterval * NSEC_PER_MSEC, 0);
  {$ENDIF}

  FInterval := AInterval;
end;

{ TgoTimerQueue }

constructor TgoTimerQueue.Create;
begin
  {$IF Defined(MSWINDOWS)}
  FHandleTimerQueue := CreateTimerQueue;
  {$ELSEIF Defined(ANDROID)}
  {$ELSEIF Defined(LINUX)}
  {$ELSEIF Defined(MACOS)}
  {$ENDIF}
end;

destructor TgoTimerQueue.Destroy;
begin
  ReleaseAll;

  {$IF Defined(MSWINDOWS)}
  DeleteTimerQueueEx(FHandleTimerQueue, INVALID_HANDLE_VALUE);
  FHandleTimerQueue := INVALID_HANDLE_VALUE;
  {$ELSEIF Defined(ANDROID)}
  {$ELSEIF Defined(LINUX)}
  {$ELSEIF Defined(MACOS)}
  FGlobalQueue := nil;
  {$ENDIF}

  {$IFDEF MSWINDOWS}
  {$ENDIF}
end;

{$IFDEF MACOS}
function TgoTimerQueue.GetGlobalQueue: dispatch_queue_t;
begin
  if FGlobalQueue = nil then
    FGlobalQueue := dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  Result := FGlobalQueue;
end;
{$ENDIF}

function TgoTimerQueue.Add(const AInterval: Cardinal; const AOnTimer: TOnTimer): THandle;
var
  Timer: TgoTimer;
begin
  // Create a timer object
  Timer := TgoTimer.Create(Self, AInterval, AOnTimer);
  _Lock;
  try
    _Timers.Add(Timer.Handle, Timer);
    Result := Timer.Handle;
  finally
    _Unlock;
  end;

end;

procedure TgoTimerQueue.Release(const AHandle: THandle);
var
  TimerPair: TPair<THandle, TgoTimer>;
  Timer: TgoTimer;
begin
  _Lock;
  try
    if not _Timers.ContainsKey(AHandle) then
      Exit;

    TimerPair := _Timers.ExtractPair(AHandle);
    Timer := TimerPair.Value;
  finally
    _Unlock;
  end;

  // Stop any events
  Timer.OnTimer := nil;

  // Destroy
  {$IFNDEF NEXTGEN}
  Timer.Free;
  {$ENDIF}
end;

procedure TgoTimerQueue.ReleaseAll;
var
  TimerPair: TPair<THandle, TgoTimer>;
  Timers: TArray<TgoTimer>;
  Timer: TgoTimer;
  Handle: THandle;
begin
  _Lock;
  try
    for Handle in _Timers.Keys.ToArray do
    begin
      TimerPair := _Timers.ExtractPair(Handle);
      Timers := Timers + [TimerPair.Value];
    end;
    _Timers.Clear;
  finally
    _Unlock;
  end;

  // Destroy all timers
  for Timer in Timers do
  begin
    Timer.OnTimer := nil;
    {$IFNDEF NEXTGEN}
    Timer.Free;
    {$ENDIF}
  end;
end;

function TgoTimerQueue.SetInterval(const AHandle: THandle; const AInterval: Cardinal): Boolean;
var
  Timer: TgoTimer;
begin
  _Lock;
  try
    if not _Timers.TryGetValue(AHandle, Timer) then
      Exit(False);

    Timer.Interval := AInterval;
    Result := True;
  finally
    _Unlock;
  end;
end;

{$IFDEF ANDROID}
{ TgoTimer.TAndroidRunnable }

constructor TgoTimer.TAndroidRunnable.Create(const ATimer: TgoTimer);
begin
  inherited Create;

  FTimer := ATimer;
end;

procedure TgoTimer.TAndroidRunnable.run;
begin
  if Assigned(FTimer.OnTimer) then
    FTimer.OnTimer(FTimer);
end;
{$ENDIF}

{$IFDEF LINUX}
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
    if NumberOfEvents = 0 then // Timeout
      Continue
    else
    if NumberOfEvents = -1 then // Error
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
              // Read error
              Timer.FClose := True;
          end;
        end;
      finally
        if Timer.FClose then
        begin
          // Remove descriptor from the set
          epoll_ctl(_TimerQueuePool.Handle, EPOLL_CTL_DEL, Timer.Handle, @Event); // -1 on error

          // Close the timer handle
          __close(Timer.Handle);

          // Trigger closed event
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

  // Create the epoll instance handle
  FHandle := epoll_create(IGNORED);
  if FHandle <> -1 then
  begin
    // Create worker threads to handle queued events
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
  // Signal the workers to quit
  for Worker in FWorkers do
    Worker.Terminate;

  // Wait for them to stop
  for Worker in FWorkers do
    Worker.WaitFor;

  // Destroy workers
  for Worker in FWorkers do
    Worker.Free;

  // Close the epoll instance handle
  if FHandle <> -1 then
    __close(FHandle);

  inherited Destroy;
end;
{$ENDIF}

initialization
  _Timers := TObjectDictionary<THandle, TgoTimer>.Create([doOwnsValues]);
  _TimersLock := TCriticalSection.Create;

  {$IFDEF LINUX}
  _TimerQueuePool := TTimerQueuePool.Create;
  {$ENDIF}

  {$IFDEF ANDROID}
  ScheduledThreadPoolExecutor := _TJScheduledThreadPoolExecutor.JavaClass.init(ANDROID_THREAD_POOL_SIZE);
  {$ENDIF}

finalization
  _Lock;
  try
    _Timers.Free;
  finally
    _Unlock;
  end;
  _TimersLock.Free;

  {$IFDEF LINUX}
  _TimerQueuePool.Free;
  {$ENDIF}

  {$IFDEF ANDROID}
  ScheduledThreadPoolExecutor := nil;
  {$ENDIF}

end.
