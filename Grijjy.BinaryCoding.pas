unit Grijjy.BinaryCoding;

{ Binary encoding algorithms, such as Base64 }

{$I Grijjy.inc}

interface

uses
  System.SysUtils;

{ Encodes binary data to a Base64 buffer.

  Parameters:
    AData: pointer to the binary data.
    ASize: size of the binary data.

  Returns:
    A byte array containing the Base64 encoded data }
function goBase64Encode(const AData: Pointer; const ASize: Integer): TBytes; overload;

{ Encodes binary data to a Base64 buffer.

  Parameters:
    AData: byte array containing the binary data.

  Returns:
    A byte array containing the Base64 encoded data }
function goBase64Encode(const AData: TBytes): TBytes; overload; inline;

{ Decodes Base64-encoded binary data.

  Parameters:
    AData: pointer to the Base64-encoded data.
    ASize: size of the Base64-encoded data.

  Returns:
    A byte array containing the decoded binary data data }
function goBase64Decode(const AData: Pointer; const ASize: Integer): TBytes; overload;

{ Decodes Base64-encoded binary data.

  Parameters:
    AData: byte array containing the Base64-encoded data.

  Returns:
    A byte array containing the decoded binary data data }
function goBase64Decode(const AData: TBytes): TBytes; overload; inline;

implementation

{$POINTERMATH ON}

const
  BASE64_ENCODE: array[0..64] of Byte = (
    // A..Z
    $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D,
    $4E, $4F, $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A,
    // a..z
    $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D,
    $6E, $6F, $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7A,
    // 0..9
    $30, $31, $32, $33, $34, $35, $36, $37, $38, $39,
    // +, /, =
    $2B, $2F, $3D);

const
  BASE64_DECODE: array[0..255] of Byte = (
    $FE, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $3E, $FF, $FF, $FF, $3F,
    $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $FF, $FF, $FE, $FF, $FF, $FF,
    $FF, $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E,
    $0F, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $FF, $FF, $FF, $FF, $FF,
    $FF, $1A, $1B, $1C, $1D, $1E, $1F, $20, $21, $22, $23, $24, $25, $26, $27, $28,
    $29, $2A, $2B, $2C, $2D, $2E, $2F, $30, $31, $32, $33, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF);

function goBase64Encode(const AData: Pointer; const ASize: Integer): TBytes;
var
  Src: PByte;
  I, SrcIndex, DstIndex: Integer;
  B: Byte;
  B64: array [0..3] of Byte;
begin
  if (AData = nil) or (ASize = 0) then
    Exit(nil);

  SetLength(Result, ((ASize + 2) div 3) * 4);
  Src := AData;
  SrcIndex := 0;
  DstIndex := 0;

  while (SrcIndex < ASize) do
  begin
    B := Src[SrcIndex];
    Inc(SrcIndex);

    B64[0] := B shr 2;
    B64[1] := (B and $03) shl 4;

    if (SrcIndex < ASize) then
    begin
      B := Src[SrcIndex];
      Inc(SrcIndex);

      B64[1] := B64[1] + (B shr 4);
      B64[2] := (B and $0F) shl 2;

      if (SrcIndex < ASize) then
      begin
        B := Src[SrcIndex];
        Inc(SrcIndex);

        B64[2] := B64[2] + (B shr 6);
        B64[3] := B and $3F;
      end
      else
        B64[3] := $40;
    end
    else
    begin
      B64[2] := $40;
      B64[3] := $40;
    end;

    for I := 0 to 3 do
    begin
      Assert(B64[I] < Length(BASE64_ENCODE));
      Assert(DstIndex < Length(Result));
      Result[DstIndex] := BASE64_ENCODE[B64[I]];
      Inc(DstIndex);
    end;
  end;
  SetLength(Result, DstIndex);
end;

function goBase64Encode(const AData: TBytes): TBytes;
begin
  if Assigned(AData) then
    Result := goBase64Encode(@AData[0], Length(AData))
  else
    Result := nil;
end;

function goBase64Decode(const AData: Pointer; const ASize: Integer): TBytes; overload;
var
  Src: PByte;
  SrcIndex, DstIndex, Count: Integer;
  B: Byte;
  C: Cardinal;
begin
  if (AData = nil) or (ASize = 0) then
    Exit(nil);

  SetLength(Result, (ASize div 4) * 3 + 4);
  Src := AData;
  SrcIndex := 0;
  DstIndex := 0;
  C := 0;
  Count := 4;

  while (SrcIndex < ASize) do
  begin
    B := BASE64_DECODE[Src[SrcIndex]];
    if (B = $FE) then
      Break
    else if (B <> $FF) then
    begin
      C := (C shl 6) or B;
      Dec(Count);
      if (Count = 0) then
      begin
        Result[DstIndex + 2] := Byte(C);
        Result[DstIndex + 1] := Byte(C shr 8);
        Result[DstIndex    ] := Byte(C shr 16);
        Inc(DstIndex, 3);
        C := 0;
        Count := 4;
      end;
    end;
    Inc(SrcIndex);
  end;

  if (Count = 1) then
  begin
    Result[DstIndex + 1] := Byte(C shr 2);
    Result[DstIndex    ] := Byte(C shr 10);
    Inc(DstIndex, 2);
  end
  else if (Count = 2) then
  begin
    Result[DstIndex] := Byte(C shr 4);
    Inc(DstIndex);
  end;

  SetLength(Result, DstIndex);
end;

function goBase64Decode(const AData: TBytes): TBytes; overload; inline;
begin
  if Assigned(AData) then
    Result := goBase64Decode(@AData[0], Length(AData))
  else
    Result := nil;
end;

end.
