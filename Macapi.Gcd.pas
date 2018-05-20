unit Macapi.Gcd;
{ Mising header translations for Grand Central Dispatch for macOS and iOS }

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.SysUtils,
  Macapi.Dispatch,
  Macapi.CoreServices,
  Macapi.CoreFoundation;

const
  {$IFDEF IOS}
  libDispatch = '/usr/lib/libSystem.dylib'; // Workaround for incorrect setting for iOS in Macapi.Dispatch
  {$ELSE}
  libDispatch = '/usr/lib/system/libdispatch.dylib';
  {$ENDIF}

  DISPATCH_QUEUE_SERIAL = nil;
  DISPATCH_QUEUE_PRIORITY_DEFAULT = 0;

  DISPATCH_TIMER_WALL_CLOCK = $4;
  DISPATCH_TIMER_INTERVAL = $8;
  DISPATCH_TIMER_WITH_AGGREGATE = $10;

  DISPATCH_TIMER_ONESHOT = $1;
  DISPATCH_TIMER_TYPE_MASK = $1;
  DISPATCH_TIMER_ABSOLUTE = $0;
  DISPATCH_TIMER_CLOCK_MASK = $2;

type
  dispatch_queue_t = dispatch_object_t;
  dispatch_group_t = dispatch_object_t;
  dispatch_source_t = dispatch_object_t;
  dispatch_source_type_t = dispatch_object_t;
  dispatch_block_t = Pointer;

function dispatch_group_create:dispatch_group_t;
  cdecl; external libDispatch name _PU + 'dispatch_group_create';

function dispatch_group_wait(group: dispatch_group_t;
  timeout: dispatch_time_t): UInt64;
  cdecl; external libDispatch name _PU + 'dispatch_group_wait';

function dispatch_get_global_queue(priority: LongInt; flags: LongInt): dispatch_queue_t;
  cdecl; external libDispatch name _PU + 'dispatch_get_global_queue';

procedure dispatch_group_async_f(group: dispatch_group_t;
  queue: dispatch_queue_t; context: pointer;
  work: dispatch_function_t);
  cdecl; external libDispatch name _PU + 'dispatch_group_async_f';

procedure dispatch_release(obj: dispatch_object_t);
  cdecl; external libDispatch name _PU + 'dispatch_release';

function dispatch_source_create(&type: dispatch_source_type_t;
  handle: NativeUInt; mask: NativeUInt;
  queue: dispatch_queue_t): dispatch_source_t;
  cdecl; external libDispatch name _PU + 'dispatch_source_create';

procedure dispatch_source_set_timer(source: dispatch_source_t;
  start: dispatch_time_t;
  interval: LongInt; leeway: LongInt);
  cdecl; external libDispatch name _PU + 'dispatch_source_set_timer';

procedure dispatch_source_set_event_handler(source: dispatch_source_t;
  handler: dispatch_block_t);
  cdecl; external libDispatch name _PU + 'dispatch_source_set_event_handler';

procedure dispatch_resume(source: dispatch_source_t);
  cdecl; external libDispatch name _PU + 'dispatch_resume';

procedure dispatch_source_cancel(source: dispatch_source_t);
  cdecl; external libDispatch name _PU + 'dispatch_source_cancel';

var
  DISPATCH_SOURCE_TYPE_TIMER:  dispatch_source_type_t = nil;

implementation

function InitLibDispatch: Boolean;
var
  HandleLibDispatch: HMODULE;
begin
  Result := False;
  HandleLibDispatch := LoadLibrary(PWideChar(libdispatch));
  if HandleLibDispatch <> 0 then
  try
    DISPATCH_SOURCE_TYPE_TIMER := dispatch_source_type_t(GetProcAddress(HandleLibDispatch, PWideChar('_dispatch_source_type_timer')));

    Result := True;
  finally
    FreeLibrary(HandleLibDispatch);
  end;
end;

initialization
  InitLibDispatch;

end.
