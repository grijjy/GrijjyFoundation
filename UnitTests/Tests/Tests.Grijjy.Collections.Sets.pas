unit Tests.Grijjy.Collections.Sets;

interface

uses
  DUnitX.TestFramework,
  Tests.Grijjy.Collections.Base,
  Grijjy.Collections;

type
  TTestTgoSet<T> = class(TTestCollectionBase<T>)
  private
    FCUT: TgoSet<T>;
    FValues: TArray<T>;
    procedure FillSet;
    procedure CheckItems(const AExpected: TArray<T>);
  public
    [Setup]
    procedure SetUp;

    [Teardown]
    procedure TearDown;

    [Test]
    procedure TestAdd;

    [Test]
    procedure TestRemove;

    [Test]
    procedure TestClear;

    [Test]
    procedure TestAddOrSet;

    [Test]
    procedure TestContains;

    [Test]
    procedure TestToArray;

    [Test]
    procedure TestGetEnumerator;
  end;

type
  TTestTgoObjectSet = class(TTestCollectionBase<TFoo>)
  private
    FCUT: TgoObjectSet<TFoo>;
    FValues: TArray<TFoo>;
    procedure FillSet;
    procedure CheckItems(const AExpectedIndices: array of Integer);
  public
    [Setup]
    procedure SetUp;

    [Teardown]
    procedure TearDown;

    [Test]
    procedure TestAdd;

    [Test]
    procedure TestRemove;

    [Test]
    procedure TestClear;

    [Test]
    procedure TestAddOrSet;

    [Test]
    procedure TestContains;

    [Test]
    procedure TestToArray;

    [Test]
    procedure TestGetEnumerator;

    [Test]
    procedure TestExtract;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Defaults;

{ TTestTgoSet<T> }

procedure TTestTgoSet<T>.CheckItems(const AExpected: TArray<T>);
var
  Value: T;
  I: Integer;
begin
  Assert.AreEqual(Length(AExpected), FCUT.Count);

  for I := 0 to Length(AExpected) - 1 do
  begin
    Value := AExpected[I];
    Assert.IsTrue(FCUT.Contains(Value));
  end;
end;

procedure TTestTgoSet<T>.FillSet;
begin
  FValues := CreateValues(3);
  FCUT.Add(FValues[0]);
  FCUT.Add(FValues[1]);
  FCUT.Add(FValues[2]);
end;

procedure TTestTgoSet<T>.SetUp;
begin
  inherited;
  FCUT := TgoSet<T>.Create;
end;

procedure TTestTgoSet<T>.TearDown;
begin
  inherited;
  FCUT.Free;
end;

procedure TTestTgoSet<T>.TestAdd;
begin
  FillSet;
  CheckItems(FValues);
end;

procedure TTestTgoSet<T>.TestAddOrSet;
var
  Values: TArray<T>;
begin
  Values := CreateValues(4);
  FCUT.Add(Values[0]);
  FCUT.Add(Values[1]);
  FCUT.Add(Values[2]);
  Assert.AreEqual(3, FCUT.Count);

  FCUT.AddOrSet(Values[1]);
  Assert.AreEqual(3, FCUT.Count);

  FCUT.AddOrSet(Values[3]);
  CheckItems(Values);
end;

procedure TTestTgoSet<T>.TestClear;
begin
  FillSet;
  Assert.AreEqual(3, FCUT.Count);

  FCUT.Clear;
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoSet<T>.TestContains;
var
  RogueValue: T;
begin
  FillSet;
  RogueValue := CreateValue(3);
  Assert.IsTrue(FCUT.Contains(FValues[0]));
  Assert.IsTrue(FCUT.Contains(FValues[1]));
  Assert.IsTrue(FCUT.Contains(FValues[2]));
  Assert.IsFalse(FCUT.Contains(RogueValue));
end;

procedure TTestTgoSet<T>.TestGetEnumerator;
var
  Value: T;
  B: Byte;
  C: IEqualityComparer<T>;
begin
  FillSet;

  C := TEqualityComparer<T>.Default;
  B := 0;
  for Value in FCUT do
  begin
    if (C.Equals(Value, FValues[0])) then
      B := B or $01
    else if (C.Equals(Value, FValues[1])) then
      B := B or $02
    else if (C.Equals(Value, FValues[2])) then
      B := B or $04
    else
      Assert.Fail('Unexpected item');
  end;
  Assert.AreEqual($07, Integer(B));
end;

procedure TTestTgoSet<T>.TestRemove;
var
  RogueValue: T;
  V: TArray<T>;
begin
  FillSet;
  RogueValue := CreateValue(3);
  Assert.AreEqual(3, FCUT.Count);

  FCUT.Remove(RogueValue);
  Assert.AreEqual(3, FCUT.Count);
  CheckItems(FValues);

  FCUT.Remove(FValues[0]);
  Assert.AreEqual(2, FCUT.Count);
  SetLength(V, 2);
  V[0] := FValues[1];
  V[1] := FValues[2];
  CheckItems(V);

  FCUT.Remove(FValues[2]);
  Assert.AreEqual(1, FCUT.Count);
  SetLength(V, 1);
  V[0] := FValues[1];
  CheckItems(V);

  FCUT.Remove(FValues[1]);
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoSet<T>.TestToArray;
var
  A: TArray<T>;
  C: IEqualityComparer<T>;
  I: Integer;
  B: Byte;
begin
  FillSet;
  C := TEqualityComparer<T>.Default;
  A := FCUT.ToArray;
  Assert.AreEqual(3, Length(A));
  B := 0;
  for I := 0 to 2 do
  begin
    if C.Equals(A[I], FValues[0]) then
      B := B or $01
    else if C.Equals(A[I], FValues[1]) then
      B := B or $02
    else if C.Equals(A[I], FValues[2]) then
      B := B or $04
    else
      Assert.Fail('Unexpected key in set');
  end;
  Assert.AreEqual($07, Integer(B));
end;

{ TTestTgoObjectSet }

procedure TTestTgoObjectSet.CheckItems(
  const AExpectedIndices: array of Integer);
var
  I: Integer;
  Value: TFoo;
begin
  Assert.AreEqual(Length(AExpectedIndices), FCUT.Count);

  for I := 0 to Length(AExpectedIndices) - 1 do
  begin
    Value := FValues[AExpectedIndices[I]];
    Assert.IsTrue(FCUT.Contains(Value));
  end;
end;

procedure TTestTgoObjectSet.FillSet;
var
  I: Integer;
begin
  SetLength(FValues, 3);
  for I := 0 to 2 do
  begin
    FValues[I] := TFoo.Create(I);
    FCUT.Add(FValues[I]);
  end;
end;

procedure TTestTgoObjectSet.SetUp;
begin
  inherited;
  FCUT := TgoObjectSet<TFoo>.Create;
end;

procedure TTestTgoObjectSet.TearDown;
var
  I: Integer;
begin
  for I := 0 to Length(FValues) - 1 do
    FValues[I] := nil;
  FCUT.Free;
  FCUT := nil;
  inherited;
end;

procedure TTestTgoObjectSet.TestAdd;
begin
  FillSet;
  CheckItems([0, 1, 2]);
end;

procedure TTestTgoObjectSet.TestAddOrSet;
begin
  FillSet;
  Assert.AreEqual(3, FCUT.Count);

  FCUT.AddOrSet(FValues[1]);
  Assert.AreEqual(3, FCUT.Count);

  SetLength(FValues, 4);
  FValues[3] := TFoo.Create(5);
  FCUT.AddOrSet(FValues[3]);
  CheckItems([0, 1, 2, 3]);
end;

procedure TTestTgoObjectSet.TestClear;
begin
  FillSet;
  Assert.AreEqual(3, FCUT.Count);

  FCUT.Clear;
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoObjectSet.TestContains;
var
  RogueValue: TFoo;
begin
  FillSet;
  RogueValue := TFoo.Create(5);
  Assert.IsTrue(FCUT.Contains(FValues[0]));
  Assert.IsTrue(FCUT.Contains(FValues[1]));
  Assert.IsTrue(FCUT.Contains(FValues[2]));
  Assert.IsFalse(FCUT.Contains(RogueValue));
  RogueValue.Free;
end;

procedure TTestTgoObjectSet.TestExtract;
var
  Value, RogueValue: TFoo;
begin
  FillSet;
  RogueValue := TFoo.Create(5);

  Value := FCUT.Extract(FValues[1]);
  Assert.IsNotNull(Value);
  Value.Free;

  Value := FCUT.Extract(RogueValue);
  Assert.IsNull(Value);
  RogueValue.Free;
end;

procedure TTestTgoObjectSet.TestGetEnumerator;
var
  Value: TFoo;
  B: Byte;
begin
  FillSet;
  B := 0;
  for Value in FCUT do
  begin
    if (Value.Value = 0) then
      B := B or $01
    else if (Value.Value = 1) then
      B := B or $02
    else if (Value.Value = 2) then
      B := B or $04
    else
      Assert.Fail('Unexpected item');
  end;
  Assert.AreEqual($07, Integer(B));
end;

procedure TTestTgoObjectSet.TestRemove;
var
  RogueValue: TFoo;
begin
  FillSet;
  RogueValue := TFoo.Create(3);
  Assert.AreEqual(3, FCUT.Count);

  FCUT.Remove(RogueValue);
  Assert.AreEqual(3, FCUT.Count);
  CheckItems([0, 1, 2]);
  RogueValue.Free;

  FCUT.Remove(FValues[0]);
  Assert.AreEqual(2, FCUT.Count);
  CheckItems([1, 2]);

  FCUT.Remove(FValues[2]);
  Assert.AreEqual(1, FCUT.Count);
  CheckItems([1]);

  FCUT.Remove(FValues[1]);
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoObjectSet.TestToArray;
var
  A: TArray<TFoo>;
  I: Integer;
  B: Byte;
begin
  FillSet;
  A := FCUT.ToArray;
  Assert.AreEqual(3, Length(A));
  B := 0;
  for I := 0 to 2 do
  begin
    if (A[I].Value = 0) then
      B := B or $01
    else if (A[I].Value = 1) then
      B := B or $02
    else if (A[I].Value = 2) then
      B := B or $04
    else
      Assert.Fail('Unexpected key in set');
  end;
  Assert.AreEqual($07, Integer(B));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTgoSet<ShortInt>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<ShortInt>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Byte>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<SmallInt>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Word>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Integer>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Cardinal>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Boolean>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TDigit>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TDigits>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Single>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Double>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Extended>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Comp>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Currency>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TFoo>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<IBaz>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<PInteger>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TTestProc>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TTestMethod>);
  {$IFNDEF NEXTGEN}
  TDUnitX.RegisterTestFixture(TTestTgoSet<TStr1>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TStr2>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TStr3>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<ShortString>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<AnsiString>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<WideString>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<AnsiChar>);
  {$ENDIF}
  TDUnitX.RegisterTestFixture(TTestTgoSet<UnicodeString>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Variant>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<Int64>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<UInt64>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TBytes>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<WideChar>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TTestArray>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TManagedRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TFooBarRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TManagedArray>);
  TDUnitX.RegisterTestFixture(TTestTgoSet<TFooBarArray>);

  TDUnitX.RegisterTestFixture(TTestTgoObjectSet);
end.
