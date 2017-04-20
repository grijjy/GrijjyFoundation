unit Grijjy.TimerQueue.Win;
{ Windows based timer queue }

{$I Grijjy.inc}

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.DateUtils,
  System.Generics.Collections,
  Winapi.Windows;

type
  TgoTimer = class;
  TOnTimer = procedure(const ASender: TObject) of object;

  { Timer object }
  TgoTimer = class(TObject)
  private
    FHandle: THandle;
    FInterval: Cardinal;
    FOnTimer: TOnTimer;
  public
    constructor Create;
    destructor Destroy; override;
  public
    { Handle of the timer object }
    property Handle: THandle read FHandle;

    { Timer interval in milliseconds }
    property Interval: Cardinal read FInterval;

    { Timer callback event  }
    property OnTimer: TOnTimer read FOnTimer write FOnTimer;
end;

  { Timer queue instance }
  TgoTimerQueue = class(TObject)
  private
    FHandle: THandle;
  private
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

implementation

var
  _Timers: TDictionary<THandle, TgoTimer>;
  _TimersLock: TCriticalSection;

{ TgoTimer }

constructor TgoTimer.Create;
begin
  inherited;
  FHandle := INVALID_HANDLE_VALUE;
  FInterval := 0;
  FOnTimer := nil;
end;

destructor TgoTimer.Destroy;
begin
  inherited;
end;

{ TgoTimerQueue }

constructor TgoTimerQueue.Create;
begin
  FHandle := CreateTimerQueue;
end;

destructor TgoTimerQueue.Destroy;
begin
  ReleaseAll;
  DeleteTimerQueueEx(FHandle, INVALID_HANDLE_VALUE);
  FHandle := INVALID_HANDLE_VALUE;
end;

procedure WaitOrTimerCallback(Timer: TgoTimer; TimerOrWaitFired: ByteBool); stdcall;
begin
  if Timer <> nil then
  begin
    _TimersLock.Enter;
    try
      if not _Timers.ContainsKey(Timer.Handle) then
        Exit;
    finally
      _TimersLock.Leave;
    end;
    if TimerOrWaitFired then
      if Assigned(Timer.OnTimer) then
        Timer.OnTimer(Timer);
  end;
end;

function TgoTimerQueue.Add(const AInterval: Cardinal; const AOnTimer: TOnTimer): THandle;
var
  Timer: TgoTimer;
begin
  Result := 0;

  { create a timer object }
  Timer := TgoTimer.Create;
  Timer.FInterval := AInterval;
  Timer.FOnTimer := AOnTimer;
  if CreateTimerQueueTimer(Timer.FHandle, FHandle, @WaitOrTimerCallback, Timer, 0, AInterval, 0) then
  begin
    _TimersLock.Enter;
    try
      _Timers.Add(Timer.Handle, Timer);
      Result := Timer.Handle;
    finally
      _TimersLock.Leave;
    end;
  end
  else
    FreeAndNil(Timer);
end;

procedure TgoTimerQueue._Release(const ATimer: TgoTimer);
begin
  ATimer.OnTimer := nil;

  { the DeleteTimerQueueTimer API will block until all the callbacks are completed }
  if DeleteTimerQueueTimer(FHandle, ATimer.Handle, INVALID_HANDLE_VALUE) then
    ATimer.Free;
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
      if ChangeTimerQueueTimer(FHandle, Timer.Handle, 0, AInterval) then
      begin
        Timer.FInterval := AInterval;
        Result := True;
      end;
  finally
    _TimersLock.Leave;
  end;
end;

initialization
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

end.
