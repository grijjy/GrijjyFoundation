unit Linuxapi.Timerfd;
{ Linux API for Timerfd }

{$I Grijjy.inc}

interface

uses
  Posix.Base,
  Posix.Time,
  Posix.Fcntl;

const
  TFD_NONBLOCK = O_NONBLOCK;

// creates a new timer object
function timerfd_create(clockid: Integer; flags: Integer): Integer; cdecl; external libc name _PU + 'timerfd_create';

// starts or stops the timer
function timerfd_settime(fd: Integer; flags: Integer; const new_value: Pitimerspec; old_value: Pitimerspec): Integer; cdecl; external libc name _PU + 'timerfd_settime';

// returns the current setting of the timer
function timerfd_gettime(fd: Integer; curr_value: Pitimerspec): Integer; cdecl; external libc name _PU + 'timerfd_gettime';

implementation

end.
