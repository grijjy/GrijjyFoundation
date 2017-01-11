unit Grijjy.SysUtils;
{< System level utilities }

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.SysUtils;

{ Returns the name of the machine.

  Tech notes:
  * On Windows, returns result from GetComputerName.
  * On other platforms, returns result from Posix gethostname api }
function goGetMachineName: String;

{ Returns the ID of the current process. }
function goGetCurrentProcessId: UInt32;

{ Converts a byte array to a hex string.

  Parameters:
    ABytes: the array of bytes to convert.

  Returns:
    A string containing 2 hex digits for each converted byte.

  @bold(Note): the returned string is in lowercase format. }
function goToHexString(const ABytes: TBytes): String;

{ Converts a hex string to a byte array.

  Parameters:
    AString: the string to convert.

  Returns:
    The converted byte array.

  Raises:
    EArgumentException if the string contains illegal characters.

  @bold(Note): AString may contain both lowercase and uppercase hex digits,
  and it may contain an even or odd number of characters. If the string
  contains an odd number of characters, then it is prefixed with an
  additional 0. }
function goParseHexString(const AString: String): TBytes;

{ Tries to convert a hex string to a byte array.

  Parameters:
    AString: the string to convert.
    ABytes: is set to the converted byte array.

  Returns:
    True on success, False on failure.

  @bold(Note): AString may contain both lowercase and uppercase hex digits,
  and it may contain an even or odd number of characters. If the string
  contains an odd number of characters, then it is prefixed with an
  additional 0. }
function goTryParseHexString(const AString: String;
  out ABytes: TBytes): Boolean;

{ Converts a digit to a byte.

  Parameters:
    AChar: the character to convert.

  Returns:
    The value of the hex digit.

  Raises:
    EArgumentException if the characeter is an illegal hex character.

  @bold(Note): AChar may be both lowercase and uppercase. }
function goCharToHex(const AChar: Char): Byte;

{ Reverses the bytes in (part of) a byte array.

  Parameters:
    ABytes: the byte array.
    AIndex: the index to start reversing.
    ALength: the number of bytes to reverse.

  Raises:
    EArgumentOutOfRangeException (AIndex + ALength) is out of range. }
procedure goReverseBytes(const ABytes: TBytes; const AIndex, ALength: Integer);

var
  { Format settings that always use a period ('.') as a decimal separator }
  goUSFormatSettings: TFormatSettings;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows,
  {$ELSE}
  Posix.UniStd,
  {$ENDIF}
  System.RTLConsts;

{$IFDEF MSWINDOWS}
function goGetMachineName: String;
var
  ComputerName: array [0..MAX_COMPUTERNAME_LENGTH] of Char;
  Size: DWORD;
begin
  Size := MAX_COMPUTERNAME_LENGTH + 1;
  if (GetComputerName(ComputerName, Size)) then
    Result := ComputerName
  else
    Result := '';
end;

function goGetCurrentProcessId: UInt32;
begin
  Result := GetCurrentProcessId;
end;
{$ELSE}
function goGetMachineName: String;
var
  HostName: TBytes;
  HostNameStr: MarshaledAString;
begin
  SetLength(HostName, 513);
  HostNameStr := @HostName[0];
  if (gethostname(HostNameStr, 512) = 0) then
    Result := String(HostNameStr)
  else
    Result := '';
end;

function goGetCurrentProcessId: UInt32;
begin
  Result := getpid;
end;
{$ENDIF}

function goToHexString(const ABytes: TBytes): String;
const
  HEX_CHARS: array [0..15] of Char = '0123456789abcdef';
var
  I, J: Integer;
begin
  if (ABytes = nil) then
    Exit('');

  SetLength(Result, Length(ABytes) * 2);
  J := Low(Result);
  for I := 0 to Length(ABytes) - 1 do
  begin
    Result[J] := HEX_CHARS[ABytes[I] shr 4];
    Result[J + 1] := HEX_CHARS[ABytes[I] and $0F];
    Inc(J, 2);
  end;
end;

function goParseHexString(const AString: String): TBytes;
var
  I: Integer;
  S: String;
begin
  if Odd(AString.Length) then
    S := '0' + AString
  else
    S := AString;

  SetLength(Result, S.Length shr 1);

  for I := 0 to Length(Result) - 1 do
    Result[I] := (goCharToHex(S.Chars[(I shl 1)]) shl 4)
               or goCharToHex(S.Chars[(I shl 1) + 1]);
end;

function goTryParseHexString(const AString: String;
  out ABytes: TBytes): Boolean;
begin
  try
    ABytes := goParseHexString(AString);
    Result := True;
  except
    ABytes := nil;
    Result := False;
  end;
end;

function goCharToHex(const AChar: Char): Byte;
begin
  case AChar of
    '0'..'9': Result := Ord(AChar) - Ord('0');
    'A'..'F': Result := Ord(AChar) - Ord('A') + 10;
    'a'..'f': Result := Ord(AChar) - Ord('a') + 10;
  else
    raise EArgumentException.CreateRes(@sArgumentInvalid);
  end;
end;

procedure goReverseBytes(const ABytes: TBytes; const AIndex, ALength: Integer);
var
  B, E: Integer;
  Temp: Byte;
begin
  if (ALength = 0) then
    Exit;

  if (AIndex < 0) or (ALength < 0) or ((AIndex + ALength) >= Length(ABytes)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  B := AIndex;
  E := AIndex + ALength - 1;
  while (B < E) do
  begin
    Temp := ABytes[B];
    ABytes[B] := ABytes[E];
    ABytes[E] := Temp;
    Inc(B);
    Dec(E);
  end;
end;

initialization
  goUSFormatSettings := TFormatSettings.Create('en-US');
  goUSFormatSettings.DecimalSeparator := '.';
  goUSFormatSettings.ThousandSeparator := ',';

end.
