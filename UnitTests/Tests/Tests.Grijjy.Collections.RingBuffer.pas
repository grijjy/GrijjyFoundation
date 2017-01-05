unit Tests.Grijjy.Collections.RingBuffer;

interface

uses
  DUnitX.TestFramework;

type
  TTestTgoRingBuffer = class
  public
    [Test]
    procedure TestReadWrite;

    [Test]
    procedure TestTryReadWrite;
  end;

implementation

uses
  Grijjy.Collections;

{ TTestTgoRingBuffer }

procedure TTestTgoRingBuffer.TestReadWrite;
var
  CUT: TgoRingBuffer<Byte>;
  WriteBuffer, ReadBuffer: array [0..99] of Byte;
  I: Integer;
begin
  CUT := TgoRingBuffer<Byte>.Create(100);
  try
    Assert.AreEqual(0, CUT.Read(ReadBuffer));

    for I := 0 to 99 do
      WriteBuffer[I] := i;
    Assert.AreEqual(100, CUT.Write(WriteBuffer));

    Assert.AreEqual(50, CUT.Read(ReadBuffer, 0, 50));
    for I := 0 to 49 do
      Assert.AreEqual(I, Integer(ReadBuffer[I]));

    Assert.AreEqual(50, CUT.Write(WriteBuffer));

    Assert.AreEqual(100, CUT.Read(ReadBuffer));
    for I := 0 to 49 do
      Assert.AreEqual(I + 50, Integer(ReadBuffer[I]));
    for I := 0 to 49 do
      Assert.AreEqual(I, Integer(ReadBuffer[I + 50]));
  finally
    CUT.Free;
  end;
end;

procedure TTestTgoRingBuffer.TestTryReadWrite;
var
  CUT: TgoRingBuffer<Integer>;
  WriteBuffer, ReadBuffer: array [0..70] of Integer;
  I, J, Block, BlockCount, ReadValue, WriteValue: Integer;
begin
  CUT := TgoRingBuffer<Integer>.Create(1000);
  try
    Assert.IsFalse(CUT.TryRead(ReadBuffer));

    for I := 0 to 13 do
      Assert.IsTrue(CUT.TryWrite(WriteBuffer));
    Assert.IsFalse(CUT.TryWrite(WriteBuffer));

    for I := 0 to 13 do
      Assert.IsTrue(CUT.TryRead(ReadBuffer));
    Assert.IsFalse(CUT.TryRead(ReadBuffer));
    Assert.AreEqual(0, CUT.Count);

    ReadValue := 0;
    WriteValue := 0;

    for I := 0 to 999 do
    begin
      BlockCount := Random(5) + 1;
      for Block := 0 to BlockCount - 1 do
      begin
        for J := 0 to 70 do
          WriteBuffer[J] := WriteValue;
        if (CUT.TryWrite(WriteBuffer)) then
          Inc(WriteValue);
      end;

      BlockCount := Random(5) + 1;
      for Block := 0 to BlockCount - 1 do
      begin
        if (CUT.TryRead(ReadBuffer)) then
        begin
          for J := 0 to 70 do
            Assert.AreEqual(ReadValue, ReadBuffer[J]);
          Inc(ReadValue);
        end;
      end;
    end;

    while CUT.TryRead(ReadBuffer) do
    begin
      for J := 0 to 70 do
        Assert.AreEqual(ReadValue, ReadBuffer[J]);
      Inc(ReadValue);
    end;
  finally
    CUT.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTgoRingBuffer);

end.
