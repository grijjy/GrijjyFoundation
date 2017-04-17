unit Linuxapi.Epoll;
{ Linux API for epoll }

{$I Grijjy.inc}

interface

uses
  Posix.Base,
  Posix.Signal;

const
  EPOLLIN = $01;
  EPOLLPRI = $02;
  EPOLLOUT = $04;
  EPOLLERR = $08;
  EPOLLHUP = $10;
  EPOLLRDNORM = $40;
  EPOLLRDBAND = $80;
  EPOLLWRNORM = $100;
  EPOLLWRBAND = $200;
  EPOLLMSG = $400;
  EPOLLRDHUP = $2000;
  EPOLLWAKEUP = 1 shl 29;
  EPOLLONESHOT = 1 shl 30;
  EPOLLET  = UInt32(1 shl 31);

  { opcodes epoll_ctl }
  EPOLL_CTL_ADD = 1;
  EPOLL_CTL_DEL = 2;
  EPOLL_CTL_MOD = 3;

type
  epoll_data = record
    case Integer of
      0: (ptr: Pointer);
      1: (fd: Integer);
      2: (u32: UInt32);
      3: (u64: UInt64);
  end;

  epoll_event = packed record
    events: UInt32;
    data : epoll_data;
  end;
  pepoll_event = ^epoll_event;

  ptsigset = ^sigset_t;

// create an epoll instance
function epoll_create(size: Integer): Integer; cdecl; external libc name _PU + 'epoll_create';
function epoll_create1(flags: Integer): Integer; cdecl; external libc name _PU + 'epoll_create1';

// apply an operation to an epoll instance
function epoll_ctl(epfd: Integer; op: Integer; fd: Integer; event: pepoll_event): Integer; cdecl; external libc name _PU + 'epoll_ctl';

// wait for events on an epoll instance
function epoll_wait(epfd: Integer; events: pepoll_event; maxevents, timeout: Integer): Integer; cdecl; external libc name _PU + 'epoll_wait';
function epoll_pwait(epfd: Integer; events: pepoll_event; maxevents, timeout: Integer; sigmask: ptsigset): Integer; cdecl; external libc name _PU + 'epoll_pwait';

{ Helpers }

function EventToString(const AEvent: epoll_event): UnicodeString;

implementation

uses
  SysUtils;

{ Helpers }

function EventToString(const AEvent: epoll_event): UnicodeString;
begin
  Result := '';
  if (AEvent.events AND EPOLLIN) = EPOLLIN then
    Result := Result + 'EPOLLIN ';
  if (AEvent.events AND EPOLLPRI) = EPOLLPRI then
    Result := Result + 'EPOLLPRI ';
  if (AEvent.events AND EPOLLOUT) = EPOLLOUT then
    Result := Result + 'EPOLLOUT ';
  if (AEvent.events AND EPOLLERR) = EPOLLERR then
    Result := Result + 'EPOLLERR ';
  if (AEvent.events AND EPOLLHUP) = EPOLLHUP then
    Result := Result + 'EPOLLHUP ';
  if (AEvent.events AND EPOLLRDNORM) = EPOLLRDNORM then
    Result := Result + 'EPOLLRDNORM ';
  if (AEvent.events AND EPOLLRDBAND) = EPOLLRDBAND then
    Result := Result + 'EPOLLRDBAND ';
  if (AEvent.events AND EPOLLWRNORM) = EPOLLWRNORM then
    Result := Result + 'EPOLLWRNORM ';
  if (AEvent.events AND EPOLLWRBAND) = EPOLLWRBAND then
    Result := Result + 'EPOLLWRBAND ';
  if (AEvent.events AND EPOLLMSG) = EPOLLMSG then
    Result := Result + 'EPOLLMSG ';
  if (AEvent.events AND EPOLLRDHUP) = EPOLLRDHUP then
    Result := Result + 'EPOLLRDHUP ';
  if (AEvent.events AND EPOLLWAKEUP) = EPOLLWAKEUP then
    Result := Result + 'EPOLLWAKEUP ';
  if (AEvent.events AND EPOLLONESHOT) = EPOLLONESHOT then
    Result := Result + 'EPOLLONESHOT ';
  if (AEvent.events AND EPOLLET) = EPOLLET then
    Result := Result + 'EPOLLET ';
  Result := Result.Trim;
end;

end.
