unit Grijjy.Console;

{$INCLUDE 'Grijjy.inc'}

interface

uses
  {$IFDEF LINUX}
  Posix.Signal,
  {$ENDIF}
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF}
  SysUtils;

procedure WaitForCtrlC;

implementation

var
  Control_C: Boolean = False;

{$IFDEF MSWINDOWS}
function ConsoleCtrlHandler(dwCtrlType: DWORD): BOOL; stdcall;
begin
  if (dwCtrlType = CTRL_C_EVENT) then
    Control_C := True;
  Result := True;
end;
{$ENDIF}

{$IFDEF LINUX}
var
  sigIntHandler: sigaction_t;

procedure SigHandler(SigNum: Integer); cdecl;
begin
  Control_C := True;
end;
{$ENDIF}

procedure WaitForCtrlC;
begin
  while not Control_C do
    Sleep(25);
end;

initialization
  {$IFDEF MSWINDOWS}
  Windows.SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);
  {$ENDIF}
  {$IFDEF LINUX}
  sigIntHandler._u.sa_handler := @SigHandler;
  sigemptyset(sigIntHandler.sa_mask);
  sigIntHandler.sa_flags := 0;
  sigaction(SIGINT, @sigIntHandler, nil);
  {$ENDIF}

end.
