unit Grijjy.System.Console;

{$INCLUDE 'Grijjy.inc'}

interface

uses
  {$IFDEF LINUX}
  Posix.Signal,
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  System.SysUtils,
  System.SyncObjs;

function WaitForCtrlC(const ATimeout: Cardinal = INFINITE): Boolean;

var
  CtrlC: Boolean = False;

implementation

var
  CtrlC_Event: TEvent;

{$IFDEF MSWINDOWS}
function ConsoleCtrlHandler(dwCtrlType: DWORD): BOOL; stdcall;
begin
  if (dwCtrlType = CTRL_C_EVENT) then
  begin
    CtrlC_Event.SetEvent;
    CtrlC := True;
  end;
  Result := True;
end;
{$ENDIF}

{$IFDEF LINUX}
var
  sigIntHandler: sigaction_t;

procedure SigHandler(SigNum: Integer); cdecl;
begin
  CtrlC_Event.SetEvent;
end;
{$ENDIF}

function WaitForCtrlC(const ATimeout: Cardinal): Boolean;
begin
  Result := (CtrlC_Event.WaitFor(ATimeout) = TWaitResult.wrTimeout);
end;

{$IFDEF MSWINDOWS}
procedure DisableQuickEdit;
const
  ENABLE_QUICK_EDIT = $40;
  ENABLE_EXTENDED_FLAGS = $80;
var
  StdHandle: THandle;
  Mode: UInt32;
begin
  StdHandle := GetStdHandle(STD_INPUT_HANDLE);
  GetConsoleMode(StdHandle, Mode);
  Mode := Mode and not ENABLE_QUICK_EDIT;
  Mode := Mode and not ENABLE_LINE_INPUT;
  Mode := Mode and not ENABLE_MOUSE_INPUT;
  Mode := Mode and not ENABLE_EXTENDED_FLAGS;
  SetConsoleMode(StdHandle, Mode);
end;
{$ENDIF}

initialization
  CtrlC_Event := TEvent.Create(nil, True, False, '');

  {$IFDEF MSWINDOWS}
  Windows.SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);
  DisableQuickEdit;
  {$ENDIF}
  {$IFDEF LINUX}
  sigIntHandler._u.sa_handler := @SigHandler;
  sigemptyset(sigIntHandler.sa_mask);
  sigIntHandler.sa_flags := 0;
  sigaction(SIGINT, @sigIntHandler, nil);
  {$ENDIF}

finalization
  CtrlC_Event.Free;

end.
