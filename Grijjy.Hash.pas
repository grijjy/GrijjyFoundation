unit Grijjy.Hash;

{$INCLUDE 'Grijjy.inc'}

{$OVERFLOWCHECKS OFF} // required since overflow checks will fail (code works ok w/o checking on)

interface

type
  { Incremental Murmur-2 hash.
      See https://sites.google.com/site/murmurhash/
    Uses the CMurmurHash2A variant, which can be used incrementally.
    The results are *not* the same as for goMurmurHash2 in Grijjy.SysUtils }
  TgoHashMurmur2 = record
  {$REGION 'Internal Declarations'}
  private const
    M = $5bd1e995;
    R = 24;
  private
    FHash: Cardinal;
    FTail: Cardinal;
    FCount: Cardinal;
    FSize: Cardinal;
  private
    class procedure Mix(var H, K: Cardinal); static; inline;
  private
    procedure MixTail(var AData: PByte; var ALength: Integer);
  {$ENDREGION 'Internal Declarations'}
  public
    { Starts a new hash.

      Parameters:
        ASeed: (optional) seed value for the hash.

      This is identical to calling Reset. }
    class function Create(const ASeed: Integer = 0): TgoHashMurmur2; static; inline;

    { Restarts the hash

      Parameters:
        ASeed: (optional) seed value for the hash.

      This is identical to using Create. }
    procedure Reset(const ASeed: Integer = 0); inline;

    { Updates the hash with new data.

      Parameters:
        AData: the data to hash
        ALength: the size of the data in bytes. }
    procedure Update(const AData; ALength: Integer);

    { Finishes the hash and returns the hash code.

      Returns:
        The hash code }
    function Finish: Cardinal;
  end;

implementation

{ TgoHashMurmur2 }

class function TgoHashMurmur2.Create(const ASeed: Integer): TgoHashMurmur2;
begin
  Result.Reset(ASeed);
end;

function TgoHashMurmur2.Finish: Cardinal;
begin
  Mix(FHash, FTail);
  Mix(FHash, FSize);

  FHash := FHash xor (FHash shr 13);
  FHash := FHash * M;
  FHash := FHash xor (FHash shr 15);

  Result := FHash;
end;

class procedure TgoHashMurmur2.Mix(var H, K: Cardinal);
begin
  K := K * M;
  K := K xor (K shr R);
  K := K * M;
  H := H * M;
  H := H xor K;
end;

procedure TgoHashMurmur2.MixTail(var AData: PByte; var ALength: Integer);
begin
  while (ALength <> 0) and ((ALength < 4) or (FCount <> 0)) do
  begin
    FTail := FTail or (AData^ shl (FCount * 8));
    Inc(AData);
    Inc(FCount);
    Dec(ALength);

    if (FCount = 4) then
    begin
      Mix(FHash, FTail);
      FTail := 0;
      FCount := 0;
    end;
  end;
end;

procedure TgoHashMurmur2.Reset(const ASeed: Integer);
begin
  FHash := ASeed;
  FTail := 0;
  FCount := 0;
  FSize := 0;
end;

procedure TgoHashMurmur2.Update(const AData; ALength: Integer);
var
  Data: PByte;
  K: Cardinal;
begin
  Inc(FSize, ALength);
  Data := @AData;
  MixTail(Data, ALength);
  while (ALength >= 4) do
  begin
    K := PCardinal(Data)^;
    Mix(FHash, K);
    Inc(Data, 4);
    Dec(ALength, 4);
  end;
  MixTail(Data, ALength);
end;

end.
