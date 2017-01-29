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

{ Fast Unicode to UTF-8 conversion.

  Parameters:
    ASource: Unicode string.

  Returns:
    A byte array with the UTF-8 data.

  @bold(Note): This function is optimized for speed and doesn't perform any
  error checking. If ASource contains invalid characters, then the result will
  be invalid as well. As a result, this version is 2-10 times faster than
  TEncoding.UTF8.GetBytes. }
function goUtf16ToUtf8(const ASource: String): TBytes; overload;

{ Fast Unicode to UTF-8 conversion using a provided buffer.

  Parameters:
    ASource: Unicode string.
    ASourceLength: the number of characters in ASource to use.
    ABuffer: pointer to the buffer to store the UTF-8 data into. The buffer must
      be at least large enough to store ((ASourceLength + 1) * 3) bytes.

  Returns:
    The number of UTF-8 bytes stored in the buffer.

  @bold(Note): This function is optimized for speed and doesn't perform any
  error checking. If ASource contains invalid characters, then the result will
  be invalid as well. As a result, this version is 2-10 times faster than
  TEncoding.UTF8.GetBytes. }
function goUtf16ToUtf8(const ASource: String; const ASourceLength: Integer;
  const ABuffer: Pointer): Integer; overload;

{ Fast UTF-8 to Unicode conversion.

  Parameters:
    ASource: the UTF-8 data.

  Returns:
    The Unicode string.

  @bold(Note): This function is optimized for speed and doesn't perform any
  error checking. If ASource contains invalid bytes, then the result will be
  invalid as well. As a result, this version is 2-35 times faster than
  TEncoding.UTF8.GetString. }
function goUtf8ToUtf16(const ASource: TBytes): String; overload; inline;

{ Fast UTF-8 to Unicode conversion.

  Parameters:
    ASource: pointer to the UTF-8 data.
    ASourceLength: the number of bytes in ASource to use.

  Returns:
    The Unicode string.

  @bold(Note): This function is optimized for speed and doesn't perform any
  error checking. If ASource contains invalid bytes, then the result will be
  invalid as well. As a result, this version is 2-35 times faster than
  TEncoding.UTF8.GetString. }
function goUtf8ToUtf16(const ASource: Pointer; const ASourceLength: Integer): String; overload;

{ Fast UTF-8 to Unicode conversion using a provided buffer.

  Parameters:
    ASource: pointer to the UTF-8 data.
    ASourceLength: the number of bytes in ASource to use.
    ABuffer: pointer to the buffer to store the UTF-16 characters into. The
      buffer must be at least large enough to store (ASourceLength + 1)
      WideChar's.

  Returns:
    The number of WideChar's (NOT bytes) stored in the buffer.

  @bold(Note): This function is optimized for speed and doesn't perform any
  error checking. If ASource contains invalid bytes, then the result will be
  invalid as well. As a result, this version is 2-35 times faster than
  TEncoding.UTF8.GetString. }
function goUtf8ToUtf16(const ASource: Pointer; const ASourceLength: Integer;
  const ABuffer: Pointer): Integer; overload;

{ Calculates a Murmur hash (v2) of a block of data.
  See https://sites.google.com/site/murmurhash/

  Parameters:
    AData: the data to calulate the hash for
    ALen: the size of the data (in bytes).

  Returns:
    The hash value for the data.

  This hash function is *much* faster than Delphi's built-in BobJenkinsHash and
  is also better in avoiding hash collisions. }
function goMurmurHash2(const AData; ALen: Integer): Integer;

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

{$POINTERMATH ON}

{ Quick Unicode and UTF-8/UTF-16 recap.

  Unicode codepoint range: U+0..U+10FFFF, except U+D800..U+DFFF (these are used
  for surrogates).
  Codepoints U+0..U+FFFF are stored in a single WideChar.
  Codepoints U+1000..U+10FFFF are stores as two WideChar's (surrogate pair)

  UTF-8 Encodes each Unicode codepoint in 1-4 bytes. The high bits of the first
  byte tell how many bytes are used:

  Range              Scalar codepoint value      1st byte  2nd byte  3rd byte  4th byte
  -------------------------------------------------------------------------------------
  U+0..U+7F          00000000 0xxxxxxx           0xxxxxxx
  U+80..U+7FF        00000yyy yyxxxxxx           110yyyyy  10xxxxxx
  U+800..U+FFFF      zzzzyyyy yyxxxxxx           1110zzzz  10yyyyyy  10xxxxxx
  U+10000..U+10FFFF  000uuuuu zzzzyyyy yyxxxxxx  11110uuu  10uuzzzz  10yyyyyy  10xxxxxx }

function goUtf16ToUtf8(const ASource: String): TBytes;
var
  SrcLength, DstLength: Integer;
  Dst: array [0..255] of Byte;
begin
  SrcLength := Length(ASource);
  if (SrcLength = 0) then
    Exit(nil);

  DstLength := (SrcLength + 1) * 3;
  if (DstLength <= Length(Dst)) then
  begin
    DstLength := goUtf16ToUtf8(ASource, SrcLength, @Dst);
    SetLength(Result, DstLength);
    Move(Dst, Result[0], DstLength);
  end
  else
  begin
    SetLength(Result, DstLength);
    SetLength(Result, goUtf16ToUtf8(ASource, SrcLength, Result));
  end;
end;

function goUtf16ToUtf8(const ASource: String; const ASourceLength: Integer;
  const ABuffer: Pointer): Integer;
var
  SrcLength: Integer;
  S: PWord;
  D, DStart: PByte;
  Codepoint: UInt32;
begin
  SrcLength := ASourceLength;
  S := Pointer(ASource);
  D := ABuffer;
  DStart := D;

  { Try to convert 2 wide characters at a time if possible. This speeds up the
    process if those 2 characters are both ASCII characters (U+0..U+7F). }
  while (SrcLength >= 2) do
  begin
    if ((PCardinal(S)^ and $FF80FF80) = 0) then
    begin
      { Common case: 2 ASCII characters in a row.
        00000000 0yyyyyyy 00000000 0xxxxxxx => 0yyyyyyy 0xxxxxxx }
      D[0] := S[0]; // 00000000 0yyyyyyy => 0yyyyyyy
      D[1] := S[1]; // 00000000 0xxxxxxx => 0xxxxxxx
      Inc(S, 2);
      Inc(D, 2);
      Dec(SrcLength, 2);
    end
    else
    begin
      Codepoint := S^;
      Inc(S);
      Dec(SrcLength);

      if (Codepoint < $80) then
      begin
        { ASCI character (U+0..U+7F).
          00000000 0xxxxxxx => 0xxxxxxx }
        D^ := Codepoint;
        Inc(D);
      end
      else if (Codepoint < $800) then
      begin
        { 2-byte sequence (U+80..U+7FF)
          00000yyy yyxxxxxx => 110yyyyy 10xxxxxx }
        D^ := (Codepoint shr 6) or $C0;   // 00000yyy yyxxxxxx => 110yyyyy
        Inc(D);
        D^ := (Codepoint and $3F) or $80; // 00000yyy yyxxxxxx => 10xxxxxx
        Inc(D);
      end
      else if (Codepoint >= $D800) and (Codepoint <= $DBFF) then
      begin
        { The codepoint is part of a UTF-16 surrogate pair:
            S[0]: 110110yy yyyyyyyy ($D800-$DBFF, high-surrogate)
            S[1]: 110111xx xxxxxxxx ($DC00-$DFFF, low-surrogate)

          Where the UCS4 codepoint value is:
            0000yyyy yyyyyyxx xxxxxxxx + $00010000 (U+10000..U+10FFFF)

          This can be calculated using:
            (((S[0] and $03FF) shl 10) or (S[1] and $03FF)) + $00010000

          However it can be calculated faster using:
            (S[0] shl 10) + S[1] - $035FDC00

          because:
            * S[0] shl 10: also shifts the leading 110110 to the left, making
              the result $D800 shl 10 = $03600000 too large
            * S[1] is                   $0000DC00 too large
            * So we need to subract     $0360DC00 (sum of the above)
            * But we need to add        $00010000
            * So in total, we subtract  $035FDC00 (difference of the above) }

        Codepoint := (Codepoint shl 10) + S^ - $035FDC00;
        Inc(S);
        Dec(SrcLength);

        { The resulting codepoint is encoded as a 4-byte UTF-8 sequence:

          000uuuuu zzzzyyyy yyxxxxxx => 11110uuu 10uuzzzz 10yyyyyy 10xxxxxx }

        Assert(Codepoint > $FFFF);
        D^ := (Codepoint shr 18) or $F0;           // 000uuuuu zzzzyyyy yyxxxxxx => 11110uuu
        Inc(D);
        D^ := ((Codepoint shr 12) and $3F) or $80; // 000uuuuu zzzzyyyy yyxxxxxx => 10uuzzzz
        Inc(D);
        D^ := ((Codepoint shr 6) and $3F) or $80;  // 000uuuuu zzzzyyyy yyxxxxxx => 10yyyyyy
        Inc(D);
        D^ := (Codepoint and $3F) or $80;          // 000uuuuu zzzzyyyy yyxxxxxx => 10xxxxxx
        Inc(D);
      end
      else
      begin
        { 3-byte sequence (U+800..U+FFFF, excluding U+D800..U+DFFF).
          zzzzyyyy yyxxxxxx => 1110zzzz 10yyyyyy 10xxxxxx }
        D^ := (Codepoint shr 12) or $E0;           // zzzzyyyy yyxxxxxx => 1110zzzz
        Inc(D);
        D^ := ((Codepoint shr 6) and $3F) or $80;  // zzzzyyyy yyxxxxxx => 10yyyyyy
        Inc(D);
        D^ := (Codepoint and $3F) or $80;          // zzzzyyyy yyxxxxxx => 10xxxxxx
        Inc(D);
      end;
    end;
  end;

  { We may have 1 wide character left to encode.
    Use the same process as above. }
  if (SrcLength <> 0) then
  begin
    Codepoint := S^;
    Inc(S);

    if (Codepoint < $80) then
    begin
      D^ := Codepoint;
      Inc(D);
    end
    else if (Codepoint < $800) then
    begin
      D^ := (Codepoint shr 6) or $C0;
      Inc(D);
      D^ := (Codepoint and $3F) or $80;
      Inc(D);
    end
    else if (Codepoint >= $D800) and (Codepoint <= $DBFF) then
    begin
      Codepoint := (Codepoint shl 10) + S^ - $35FDC00;

      Assert(Codepoint > $FFFF);
      D^ := (Codepoint shr 18) or $F0;
      Inc(D);
      D^ := ((Codepoint shr 12) and $3F) or $80;
      Inc(D);
      D^ := ((Codepoint shr 6) and $3F) or $80;
      Inc(D);
      D^ := (Codepoint and $3F) or $80;
      Inc(D);
    end
    else
    begin
      D^ := (Codepoint shr 12) or $E0;
      Inc(D);
      D^ := ((Codepoint shr 6) and $3F) or $80;
      Inc(D);
      D^ := (Codepoint and $3F) or $80;
      Inc(D);
    end;
  end;

  Result := D - DStart;
end;

function goUtf8ToUtf16(const ASource: TBytes): String;
begin
  Result := goUtf8ToUtf16(ASource, Length(ASource));
end;

function goUtf8ToUtf16(const ASource: Pointer; const ASourceLength: Integer): String;
var
  Dst: array [0..127] of Char;
  DstLength: Integer;
begin
  if (ASourceLength = 0) then
    Exit('');

  if (ASourceLength < Length(Dst)) then
  begin
    DstLength := goUtf8ToUtf16(ASource, ASourceLength, @Dst);
    SetString(Result, PChar(@Dst), DstLength);
  end
  else
  begin
    SetLength(Result, ASourceLength + 1);
    SetLength(Result, goUtf8ToUtf16(ASource, ASourceLength, Pointer(Result)));
  end;
end;

function goUtf8ToUtf16(const ASource: Pointer; const ASourceLength: Integer;
  const ABuffer: Pointer): Integer;
var
  SrcLength: Integer;
  S: PByte;
  D, DStart: PWord;
  Codepoint: UInt32;
begin
  SrcLength := ASourceLength;

  S := ASource;
  D := ABuffer;
  DStart := D;

  { Try to convert 4 bytes at a time. This speeds up the process if those 4
    bytes are all ASCII characters (U+0..U+7F) }
  while (SrcLength >= 4) do
  begin
    if ((PCardinal(S)^ and $80808080) = 0) then
    begin
      { Common case: 4 ASCII characters in a row.
        0zzzzzzz 0yyyyyyy 0xxxxxxx 0wwwwwww => 00000000 0zzzzzzz 00000000 0yyyyyyy 00000000 0xxxxxxx 00000000 0wwwwwww }
      D[0] := S[0]; // 0zzzzzzz => 00000000 0zzzzzzz
      D[1] := S[1]; // 0yyyyyyy => 00000000 0yyyyyyy
      D[2] := S[2]; // 0xxxxxxx => 00000000 0xxxxxxx
      D[3] := S[3]; // 0wwwwwww => 00000000 0wwwwwww
      Inc(S, 4);
      Inc(D, 4);
      Dec(SrcLength, 4);
    end
    else
    begin
      Codepoint := S^;
      Inc(S);
      if (Codepoint < $80) then
      begin
        { ASCI character (U+0..U+7F).
          0xxxxxxx => 00000000 0xxxxxxx }
        D^ := Codepoint;
        Dec(SrcLength);
      end
      else
      if ((Codepoint shr 5) = $06) then
      begin
        { 2-byte sequence (U+80..U+7FF)
          110yyyyy 10xxxxxx => 00000yyy yyxxxxxx }
        D^ := ((Codepoint shl 6) and $7FF) // 110yyyyy => 00000yyy yy000000
            + (S^ and $3F);                // 10xxxxxx => 00000000 00xxxxxx
        Inc(S);
        Dec(SrcLength, 2);
      end
      else
      begin
        if ((Codepoint shr 4) = $0E) then
        begin
          { 3-byte sequence (U+800..U+FFFF, excluding U+D800..U+DFFF).
            1110zzzz 10yyyyyy 10xxxxxx => zzzzyyyy yyxxxxxx }
          Codepoint :=
             ((Codepoint shl 12) and $FFFF) // 1110zzzz => zzzz0000 00000000
           + ((S^ shl 6) and $FFF);         // 10yyyyyy => 0000yyyy yy000000
          Inc(S);
          Inc(Codepoint, S^ and $3F);       // 10xxxxxx => 00000000 00xxxxxx
          Inc(S);
          Dec(SrcLength, 3);
          Assert(CodePoint <= $FFFF);
          D^ := Codepoint;
        end
        else
        begin
          Assert((Codepoint shr 3) = $1E);
          { 4-byte sequence (U+10000..U+10FFFF).
            11110uuu 10uuzzzz 10yyyyyy 10xxxxxx => 000uuuuu zzzzyyyy yyxxxxxx }
          Codepoint :=
             ((Codepoint shl 18) and $1FFFFF) // 11110uuu => 000uuu00 00000000 00000000
           + ((S^ shl 12) and $3FFFF);        // 10uuzzzz => 000000uu zzzz0000 00000000
          Inc(S);
          Inc(Codepoint, (S^ shl 6) and $FFF);// 10yyyyyy => 00000000 0000yyyy yy000000
          Inc(S);
          Inc(Codepoint, S^ and $3F);         // 10xxxxxx => 00000000 00000000 00xxxxxx
          Inc(S);
          Dec(SrcLength, 4);

          { The value $00010000 must be subtracted from this codepoint, and the
            result must be converted to a UTF-16 surrogate pair:
              D[0]: 110110yy yyyyyyyy ($D800-$DBFF, high-surrogate)
              D[1]: 110111xx xxxxxxxx ($DC00-$DFFF, low-surrogate) }

          Assert(Codepoint > $FFFF);
          Dec(Codepoint, $00010000);
          D^ := $D800 + (Codepoint shr 10);
          Inc(D);
          D^ := $DC00 + (Codepoint and $3FF);
        end;
      end;
      Inc(D);
    end;
  end;

  { We may 1-3 bytes character left to encode.
    Use the same process as above. }
  while (SrcLength > 0) do
  begin
    Codepoint := S^;
    Inc(S);
    if (Codepoint < $80) then
    begin
      D^ := Codepoint;
      Dec(SrcLength);
    end
    else
    if ((Codepoint shr 5) = $06) then
    begin
      D^ := ((Codepoint shl 6) and $7FF) + (S^ and $3F);
      Inc(S);
      Dec(SrcLength, 2);
    end
    else
    begin
      if ((Codepoint shr 4) = $0E) then
      begin
        Codepoint := ((Codepoint shl 12) and $FFFF) + ((S^ shl 6) and $FFF);
        Inc(S);
        Inc(Codepoint, S^ and $3F);
        Inc(S);
        Dec(SrcLength, 3);
        Assert(CodePoint <= $FFFF);
        D^ := Codepoint;
      end
      else
      begin
        Assert((Codepoint shr 3) = $1E);
        Codepoint := ((Codepoint shl 18) and $1FFFFF) + ((S^ shl 12) and $3FFFF);
        Inc(S);
        Inc(Codepoint, (S^ shl 6) and $FFF);
        Inc(S);
        Inc(Codepoint, S^ and $3F);
        Inc(S);
        Dec(SrcLength, 4);

        Assert(CodePoint > $FFFF);
        D^ := $D7C0 + (Codepoint shr 10);
        Inc(D);
        D^ := $DC00 + (Codepoint and $3FF);
      end;
    end;
    Inc(D);
  end;
  Result := D - DStart;
end;
{$POINTERMATH OFF}

{$IFOPT Q+}
  {$DEFINE OVERFLOW_CHECKS_WAS_ON}
{$ENDIF}
{$Q-}
function goMurmurHash2(const AData; ALen: Integer): Integer;
{ https://sites.google.com/site/murmurhash/MurmurHash2.cpp?attredirects=0 }
const
  M = $5bd1e995;
  R = 24;
var
  H, K: Cardinal;
  Data: PByte;
label
  label1, label2, label3, finish;
begin
  H := ALen;
  Data := @AData;

  while (ALen >= 4) do
  begin
    K := PCardinal(Data)^;

    K := K * M;
    K := K xor (K shr R);
    K := K * M;

    H := H * M;
    H := H xor K;

    Inc(Data, 4);
    Dec(ALen, 4);
  end;

  case ALen of
    3: goto label3;
    2: goto label2;
    1: goto label1;
  else
    goto finish;
  end;

label3:
  H := H xor (Data[2] shl 16);

label2:
  H := H xor (Data[1] shl 8);

label1:
  H := H xor Data[0];
  H := H * M;

finish:
  H := H xor (H shr 13);
  H := H * M;
  Result := (H xor (H shr 15)) and $7FFFFFFF;
end;
{$IFDEF OVERFLOW_CHECKS_WAS_ON}
  {$Q+}
{$ENDIF}

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
