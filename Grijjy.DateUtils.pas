unit Grijjy.DateUtils;
{< System level date/time utilities }

{$INCLUDE 'Grijjy.inc'}

interface

const
  { The minimum and maximum number of milliseconds since the Unix epoch that
    we can use to convert to and from a TDateTime value without loss in
    precision. Note that Delphi's TDateTime type can safely handle a larger
    range of milliseconds, but other languages may not. }
  MIN_MILLISECONDS_SINCE_EPOCH = -62135596800000;
  MAX_MILLISECONDS_SINCE_EPOCH = 253402300799999;

{ Converts a date/time value to a number of milliseconds since the Unix
  epoch.

  Parameters:
    AValue: the date/time value to convert.
    AInputIsUTC: whether AValue is in UTC format.

  Returns:
    The number of milliseconds since the Unix epoch. }
function goDateTimeToMillisecondsSinceEpoch(const AValue: TDateTime;
  const AInputIsUTC: Boolean): Int64;

{ Converts a number of milliseconds since the Unix epoch to a date/time value.

  Parameters:
    AValue: number of milliseconds since the Unix epoch.
    AReturnUTC: whether to return the corresponding date/time value in
      local time (False) or universal time (True).

  Returns:
    The date/time value.

  Raises:
    EArgumentOutOfRangeException if AValue cannot be accurately converted to
    a date/time value }
function goToDateTimeFromMillisecondsSinceEpoch(const AValue: Int64;
  const AReturnUTC: Boolean): TDateTime;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.RTLConsts;

function goDateTimeToMillisecondsSinceEpoch(const AValue: TDateTime;
  const AInputIsUTC: Boolean): Int64;
var
  Date: TDateTime;
begin
  if AInputIsUTC then
    Date := AValue
  else
    Date := TTimeZone.Local.ToUniversalTime(AValue);

  Result := MilliSecondsBetween(UnixDateDelta, Date);
  if (Date < UnixDateDelta) then
     Result := -Result;
end;

function goToDateTimeFromMillisecondsSinceEpoch(
  const AValue: Int64; const AReturnUTC: Boolean): TDateTime;
begin
  if (AValue < MIN_MILLISECONDS_SINCE_EPOCH) or (AValue > MAX_MILLISECONDS_SINCE_EPOCH) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  if AReturnUTC then
    Result := IncMilliSecond(UnixDateDelta, AValue)
  else
    Result := TTimeZone.Local.ToLocalTime(IncMilliSecond(UnixDateDelta, AValue));
end;

end.
