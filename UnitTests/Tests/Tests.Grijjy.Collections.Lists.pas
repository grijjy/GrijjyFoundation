unit Tests.Grijjy.Collections.Lists;

interface

uses
  DUnitX.TestFramework,
  Tests.Grijjy.Collections.Base,
  Grijjy.Collections;

type
  TTestTgoValueList<T{$IF (RTLVersion < 36)}: record{$ENDIF}> = class(TTestCollectionBase<T>)
  private const
    LIMIT = 1000;
  private type
    P = ^T;
  private
    FCUT: TgoValueList<T>;
    FValues: TArray<T>;
    procedure SimpleFillList;
  public
    [Setup]
    procedure SetUp;

    [Teardown]
    procedure TearDown;

    [Test]
    procedure TestInit;

    [Test]
    procedure TestAdd;

    [Test]
    procedure TestInsert;

    [Test]
    procedure TestSimpleDelete;

    [Test]
    procedure TestMultipleDelete;

    [Test]
    procedure TestClear;

    [Test]
    procedure TestFirst;

    [Test]
    procedure TestLast;

    [Test]
    procedure TestGetEnumerator;

    [Test]
    procedure TestModify;

    [Test]
    procedure TestSetCountIncrease;

    [Test]
    procedure TestSetCountDecrease;

    [Test]
    procedure TestDeleteRange;
  end;

implementation

{ TTestTgoValueList<T> }

procedure TTestTgoValueList<T>.SetUp;
begin
  inherited;
  FCUT := TgoValueList<T>.Create;
end;

procedure TTestTgoValueList<T>.SimpleFillList;
var
  I: Integer;
begin
  FValues := CreateValues(3);
  for I := 0 to 2 do
    FCUT.Add(FValues[I]);
end;

procedure TTestTgoValueList<T>.TearDown;
begin
  FCUT.Free;
  inherited;
end;

procedure TTestTgoValueList<T>.TestAdd;
var
  Values: TArray<T>;
  I: Integer;
begin
  Values := CreateValues(LIMIT);
  for I := 0 to LIMIT - 1 do
  begin
    Assert.AreEqual(I, FCUT.Count);
    Assert.AreEqual(I, FCUT.Add(Values[I]));
    TestEquals(Values[I], FCUT[I]^);
  end;
end;

procedure TTestTgoValueList<T>.TestClear;
var
  Values: TArray<T>;
  I: Integer;
begin
  Values := CreateValues(LIMIT);
  for I := 0 to LIMIT - 1 do
    FCUT.Add(Values[I]);

  FCUT.Clear;
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoValueList<T>.TestDeleteRange;
var
  Values: TArray<T>;
begin
  Values := CreateValues([1, 2, 3, 2, 1]);
  FCUT.Add(Values[0]);
  FCUT.Add(Values[1]);
  FCUT.Add(Values[2]);
  FCUT.Add(Values[3]);
  FCUT.Add(Values[4]);
  FCUT.DeleteRange(1, 3);
  Assert.AreEqual(2, FCUT.Count);
  TestEquals(Values[0], FCUT[0]^);
  TestEquals(Values[4], FCUT[1]^);
end;

procedure TTestTgoValueList<T>.TestFirst;
begin
  SimpleFillList;
  TestEquals(FValues[0], FCUT.First^);
end;

procedure TTestTgoValueList<T>.TestGetEnumerator;
var
  Item: P;
  I: Integer;
begin
  SimpleFillList;
  I := 0;
  for Item in FCUT do
  begin
    TestEquals(FValues[I], Item^);
    Inc(I);
  end;
end;

procedure TTestTgoValueList<T>.TestInit;
begin
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoValueList<T>.TestInsert;
var
  Values: TArray<T>;
  I: Integer;
begin
  Values := CreateValues(LIMIT);
  for I := 0 to LIMIT - 1 do
  begin
    Assert.AreEqual(I, FCUT.Count);
    FCUT.Insert(0, Values[I]);
    TestEquals(Values[I], FCUT[0]^);
  end;
end;

procedure TTestTgoValueList<T>.TestLast;
begin
  SimpleFillList;
  TestEquals(FValues[2], FCUT.Last^);
end;

procedure TTestTgoValueList<T>.TestModify;
var
  I: Integer;
  Value: P;
  NewValues: TArray<T>;
begin
  SimpleFillList;
  SetLength(NewValues, 3);
  for I := 0 to 2 do
    NewValues[I] := CreateValue(I + 10);

  for I := 0 to FCUT.Count - 1 do
    TestEquals(FValues[I], FCUT[I]^);

  for I := 0 to FCUT.Count - 1 do
  begin
    Value := FCUT[I];
    Value^ := NewValues[I];
  end;

  for I := 0 to FCUT.Count - 1 do
    TestEquals(NewValues[I], FCUT[I]^);
end;

procedure TTestTgoValueList<T>.TestMultipleDelete;
begin
  SimpleFillList;
  Assert.AreEqual(3, FCUT.Count);
  FCUT.Delete(0);
  Assert.AreEqual(2, FCUT.Count);
  FCUT.Delete(0);
  Assert.AreEqual(1, FCUT.Count);
  FCUT.Delete(0);
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoValueList<T>.TestSetCountDecrease;
var
  Values: TArray<T>;
begin
  Values := CreateValues([1, 2, 3, 2, 1]);
  FCUT.Add(Values[0]);
  FCUT.Add(Values[1]);
  FCUT.Add(Values[2]);
  FCUT.Add(Values[3]);
  FCUT.Add(Values[4]);
  FCUT.Count := 3;

  Assert.AreEqual(3, FCUT.Count);

  TestEquals(Values[0], FCUT[0]^);
  TestEquals(Values[1], FCUT[1]^);
  TestEquals(Values[2], FCUT[2]^);
end;

procedure TTestTgoValueList<T>.TestSetCountIncrease;
var
  Values: TArray<T>;
begin
  Values := CreateValues([1, 2, 3, 2, 1]);
  FCUT.Add(Values[0]);
  FCUT.Add(Values[1]);
  FCUT.Add(Values[2]);
  FCUT.Add(Values[3]);
  FCUT.Add(Values[4]);
  FCUT.Count := 7;

  Assert.AreEqual(7, FCUT.Count);

  TestEquals(Values[0], FCUT[0]^);
  TestEquals(Values[1], FCUT[1]^);
  TestEquals(Values[2], FCUT[2]^);
  TestEquals(Values[3], FCUT[3]^);
  TestEquals(Values[4], FCUT[4]^);
  {$IFNDEF FPC}
  TestEquals(Default(T), FCUT[5]^);
  TestEquals(Default(T), FCUT[6]^);
  {$ENDIF}
end;

procedure TTestTgoValueList<T>.TestSimpleDelete;
var
  Value: T;
begin
  Value := CreateValue(1);
  FCUT.Add(Value);
  Assert.AreEqual(1, FCUT.Count);
  FCUT.Delete(0);
  Assert.AreEqual(0, FCUT.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTgoValueList<ShortInt>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Byte>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<SmallInt>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Word>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Integer>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Cardinal>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Boolean>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<TDigit>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Single>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Double>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Extended>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Comp>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Currency>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<Int64>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<UInt64>);
  {$IFNDEF NEXTGEN}
  TDUnitX.RegisterTestFixture(TTestTgoValueList<AnsiChar>);
  {$ENDIF}
  TDUnitX.RegisterTestFixture(TTestTgoValueList<WideChar>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<TManagedRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoValueList<TFooBarRecord>);
end.
