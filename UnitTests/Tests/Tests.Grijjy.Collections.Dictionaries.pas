unit Tests.Grijjy.Collections.Dictionaries;

interface

uses
  System.Generics.Defaults,
  System.Generics.Collections,
  DUnitX.TestFramework,
  Tests.Grijjy.Collections.Base,
  Grijjy.Collections;

type
  TTestTgoValueDictionaryByKey<TKey> = class(TTestCollectionBase<TKey>)
  private type
    PValue = TgoPtr<Integer>.P;
    TPair = TPair<TKey, PValue>;
  private
    FCUT: TgoValueDictionary<TKey, Integer>;
    FKeys: TArray<TKey>;
    procedure FillDictionary;
    procedure CheckItems(const AExpectedKeys: TArray<TKey>;
      const AExpectedValues: array of Integer);
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
    procedure TestTryGetValue;

    [Test]
    procedure TestAddOrSetValue;

    [Test]
    procedure TestContainsKey;

    [Test]
    procedure TestGetEnumerator;

    [Test]
    procedure TestGetItem;

    [Test]
    procedure TestKeys;

    [Test]
    procedure TestValues;
  end;

type
  TTestTgoValueDictionaryByValue<TValue{$IF (RTLVersion < 36)}: record{$ENDIF}> = class(TTestCollectionBase<TValue>)
  private type
    PValue = ^TValue;
    TPair = TPair<Integer, PValue>;
  private
    FCUT: TgoValueDictionary<Integer, TValue>;
    FValues: TArray<TValue>;
    procedure FillDictionary;
    procedure CheckItems(const AExpectedKeys: array of Integer;
      const AExpectedValues: TArray<TValue>);
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
    procedure TestTryGetValue;

    [Test]
    procedure TestAddOrSetValue;

    [Test]
    procedure TestContainsKey;

    [Test]
    procedure TestGetEnumerator;

    [Test]
    procedure TestGetItem;

    [Test]
    procedure TestKeys;

    [Test]
    procedure TestValues;
  end;

implementation

uses
  System.SysUtils;

{ TTestTgoValueDictionaryByKey<TKey> }

procedure TTestTgoValueDictionaryByKey<TKey>.CheckItems(
  const AExpectedKeys: TArray<TKey>; const AExpectedValues: array of Integer);
var
  Key: TKey;
  I: Integer;
  Value: PValue;
begin
  Assert.AreEqual(Length(AExpectedKeys), FCUT.Count);
  Assert.AreEqual(Length(AExpectedValues), FCUT.Count);

  for I := 0 to Length(AExpectedKeys) - 1 do
  begin
    Key := AExpectedKeys[I];
    Assert.IsTrue(FCUT.TryGetValue(Key, Value));
    Assert.IsTrue(Value <> nil);
    Assert.AreEqual(AExpectedValues[I], Value^);
  end;
end;

procedure TTestTgoValueDictionaryByKey<TKey>.FillDictionary;
begin
  FKeys := CreateValues(3);
  FCUT.Add(FKeys[0], 10);
  FCUT.Add(FKeys[1], 20);
  FCUT.Add(FKeys[2], 30);
end;

procedure TTestTgoValueDictionaryByKey<TKey>.SetUp;
begin
  inherited;
  FCUT := TgoValueDictionary<TKey, Integer>.Create;
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TearDown;
begin
  FCUT.Free;
  inherited;
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestAdd;
begin
  FillDictionary;
  CheckItems(FKeys, [10, 20, 30]);
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestAddOrSetValue;
var
  Keys: TArray<TKey>;
begin
  Keys := CreateValues(4);
  FCUT.Add(Keys[0], 10);
  FCUT.Add(Keys[1], 20);
  FCUT.Add(Keys[2], 30);
  Assert.AreEqual(3, FCUT.Count);

  FCUT.AddOrSetValue(Keys[1], 40);
  Assert.AreEqual(3, FCUT.Count);

  FCUT.AddOrSetValue(Keys[3], 50);
  CheckItems(Keys, [10, 40, 30, 50]);
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestClear;
begin
  FillDictionary;
  Assert.AreEqual(3, FCUT.Count);

  FCUT.Clear;
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestContainsKey;
var
  RogueKey: TKey;
begin
  FillDictionary;
  RogueKey := CreateValue(3);
  Assert.IsTrue(FCUT.ContainsKey(FKeys[0]));
  Assert.IsTrue(FCUT.ContainsKey(FKeys[1]));
  Assert.IsTrue(FCUT.ContainsKey(FKeys[2]));
  Assert.IsFalse(FCUT.ContainsKey(RogueKey));
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestGetEnumerator;
var
  Pair: TPair;
  B: Byte;
  C: IEqualityComparer<TKey>;
begin
  FillDictionary;
  C := TEqualityComparer<TKey>.Default;
  B := 0;
  for Pair in FCUT do
  begin
    Assert.IsTrue(Pair.Value <> nil);
    if (C.Equals(Pair.Key, FKeys[0])) then
    begin
      B := B or $01;
      Assert.AreEqual(10, PInteger(Pair.Value)^)
    end
    else if (C.Equals(Pair.Key, FKeys[1])) then
    begin
      B := B or $02;
      Assert.AreEqual(20, PInteger(Pair.Value)^)
    end
    else if (C.Equals(Pair.Key, FKeys[2])) then
    begin
      B := B or $04;
      Assert.AreEqual(30, PInteger(Pair.Value)^)
    end
    else
      Assert.Fail('Unexpected item');
  end;
  Assert.AreEqual($07, Integer(B));
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestGetItem;
begin
  FillDictionary;
  Assert.AreEqual(10, FCUT[FKeys[0]]^);
  Assert.AreEqual(20, FCUT[FKeys[1]]^);
  Assert.AreEqual(30, FCUT[FKeys[2]]^);
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestKeys;
var
  Key: TKey;
  B: Byte;
  C: IEqualityComparer<TKey>;
begin
  FillDictionary;
  B := 0;
  C := TEqualityComparer<TKey>.Default;
  for Key in FCUT.Keys do
  begin
    if (C.Equals(Key, FKeys[0])) then
      B := B or $01
    else if (C.Equals(Key, FKeys[1])) then
      B := B or $02
    else if (C.Equals(Key, FKeys[2])) then
      B := B or $04
    else
      Assert.Fail('Unexpected item');
  end;
  Assert.AreEqual($07, Integer(B));
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestRemove;
var
  RogueKey: TKey;
  V: TArray<TKey>;
begin
  FillDictionary;
  RogueKey := CreateValue(3);
  Assert.AreEqual(3, FCUT.Count);

  FCUT.Remove(RogueKey);
  Assert.AreEqual(3, FCUT.Count);
  CheckItems(FKeys, [10, 20, 30]);

  FCUT.Remove(FKeys[0]);
  Assert.AreEqual(2, FCUT.Count);
  SetLength(V, 2);
  V[0] := FKeys[1];
  V[1] := FKeys[2];
  CheckItems(V, [20, 30]);

  FCUT.Remove(FKeys[2]);
  Assert.AreEqual(1, FCUT.Count);
  SetLength(V, 1);
  V[0] := FKeys[1];
  CheckItems(V, [20]);

  FCUT.Remove(FKeys[1]);
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestTryGetValue;
var
  RogueKey: TKey;
  Value: PValue;
begin
  FillDictionary;
  RogueKey := CreateValue(3);
  Assert.IsFalse(FCUT.TryGetValue(RogueKey, Value));
  Assert.IsTrue(Value = nil);

  Assert.IsTrue(FCUT.TryGetValue(FKeys[1], Value));
  Assert.IsTrue(Value <> nil);
  Assert.AreEqual(Value^, 20);
end;

procedure TTestTgoValueDictionaryByKey<TKey>.TestValues;
var
  Value: PValue;
  B: Byte;
begin
  FillDictionary;
  B := 0;
  for Value in FCUT.Values do
  begin
    Assert.IsTrue(Value <> nil);
    if (Value^ = 10) then
      B := B or $01
    else if (Value^ = 20) then
      B := B or $02
    else if (Value^ = 30) then
      B := B or $04
    else
      Assert.Fail('Unexpected item');
  end;
  Assert.AreEqual($07, Integer(B));
end;

{ TTestTgoValueDictionaryByValue<TValue> }

procedure TTestTgoValueDictionaryByValue<TValue>.CheckItems(
  const AExpectedKeys: array of Integer; const AExpectedValues: TArray<TValue>);
var
  Value: PValue;
  I, Key: Integer;
begin
  Assert.AreEqual(Length(AExpectedKeys), FCUT.Count);
  Assert.AreEqual(Length(AExpectedValues), FCUT.Count);

  for I := 0 to Length(AExpectedKeys) - 1 do
  begin
    Key := AExpectedKeys[I];
    Assert.IsTrue(FCUT.TryGetValue(Key, Value));
    Assert.IsTrue(Value <> nil);
    TestEquals(AExpectedValues[I], Value^);
  end;
end;

procedure TTestTgoValueDictionaryByValue<TValue>.FillDictionary;
begin
  FValues := CreateValues(3);
  FCUT.Add(10, FValues[0]);
  FCUT.Add(20, FValues[1]);
  FCUT.Add(30, FValues[2]);
end;

procedure TTestTgoValueDictionaryByValue<TValue>.SetUp;
begin
  inherited;
  FCUT := TgoValueDictionary<Integer, TValue>.Create;
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TearDown;
begin
  FCUT.Free;
  inherited;
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestAdd;
begin
  FillDictionary;
  CheckItems([10, 20, 30], FValues);
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestAddOrSetValue;
var
  Values, NewValues: TArray<TValue>;
begin
  Values := CreateValues(5);
  FCUT.Add(10, Values[0]);
  FCUT.Add(20, Values[1]);
  FCUT.Add(30, Values[2]);
  Assert.AreEqual(3, FCUT.Count);

  FCUT.AddOrSetValue(20, Values[3]);
  Assert.AreEqual(3, FCUT.Count);

  FCUT.AddOrSetValue(40, Values[4]);

  SetLength(NewValues, 4);
  NewValues[0] := Values[0];
  NewValues[1] := Values[3];
  NewValues[2] := Values[2];
  NewValues[3] := Values[4];
  CheckItems([10, 20, 30, 40], NewValues);
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestClear;
begin
  FillDictionary;
  Assert.AreEqual(3, FCUT.Count);

  FCUT.Clear;
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestContainsKey;
begin
  FillDictionary;
  Assert.IsTrue(FCUT.ContainsKey(10));
  Assert.IsTrue(FCUT.ContainsKey(20));
  Assert.IsTrue(FCUT.ContainsKey(30));
  Assert.IsFalse(FCUT.ContainsKey(40));
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestGetEnumerator;
var
  Pair: TPair;
  B: Byte;
  C: IEqualityComparer<TValue>;
begin
  FillDictionary;
  C := TEqualityComparer<TValue>.Default;
  B := 0;
  for Pair in FCUT do
  begin
    Assert.IsTrue(Pair.Value <> nil);
    if (Pair.Key = 10) then
    begin
      B := B or $01;
      Assert.IsTrue(C.Equals(PValue(Pair.Value)^, FValues[0]))
    end
    else if (Pair.Key = 20) then
    begin
      B := B or $02;
      Assert.IsTrue(C.Equals(PValue(Pair.Value)^, FValues[1]))
    end
    else if (Pair.Key = 30) then
    begin
      B := B or $04;
      Assert.IsTrue(C.Equals(PValue(Pair.Value)^, FValues[2]))
    end
    else
      Assert.Fail('Unexpected item');
  end;
  Assert.AreEqual($07, Integer(B));
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestGetItem;
begin
  FillDictionary;
  TestEquals(FValues[0], FCUT[10]^);
  TestEquals(FValues[1], FCUT[20]^);
  TestEquals(FValues[2], FCUT[30]^);
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestKeys;
var
  Key: Integer;
  B: Byte;
begin
  FillDictionary;
  B := 0;
  for Key in FCUT.Keys do
  begin
    if (Key = 10) then
      B := B or $01
    else if (Key = 20) then
      B := B or $02
    else if (Key = 30) then
      B := B or $04
    else
      Assert.Fail('Unexpected item');
  end;
  Assert.AreEqual($07, Integer(B));
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestRemove;
var
  V: TArray<TValue>;
begin
  FillDictionary;
  Assert.AreEqual(3, FCUT.Count);

  FCUT.Remove(40);
  Assert.AreEqual(3, FCUT.Count);
  CheckItems([10, 20, 30], FValues);

  FCUT.Remove(10);
  Assert.AreEqual(2, FCUT.Count);
  SetLength(V, 2);
  V[0] := FValues[1];
  V[1] := FValues[2];
  CheckItems([20, 30], V);

  FCUT.Remove(30);
  Assert.AreEqual(1, FCUT.Count);
  SetLength(V, 1);
  V[0] := FValues[1];
  CheckItems([20], V);

  FCUT.Remove(20);
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestTryGetValue;
var
  Value: PValue;
  C: IEqualityComparer<TValue>;
begin
  FillDictionary;
  C := TEqualityComparer<TValue>.Default;

  Assert.IsFalse(FCUT.TryGetValue(40, Value));
  Assert.IsTrue(Value = nil);

  Assert.IsTrue(FCUT.TryGetValue(20, Value));
  Assert.IsTrue(Value <> nil);
  Assert.IsTrue(C.Equals(FValues[1], Value^));
end;

procedure TTestTgoValueDictionaryByValue<TValue>.TestValues;
var
  Value: PValue;
  B: Byte;
  C: IEqualityComparer<TValue>;
begin
  FillDictionary;
  C := TEqualityComparer<TValue>.Default;
  B := 0;
  for Value in FCUT.Values do
  begin
    Assert.IsTrue(Value <> nil);
    if (C.Equals(Value^, FValues[0])) then
      B := B or $01
    else if (C.Equals(Value^, FValues[1])) then
      B := B or $02
    else if (C.Equals(Value^, FValues[2])) then
      B := B or $04
    else
      Assert.Fail('Unexpected item');
  end;
  Assert.AreEqual($07, Integer(B));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<ShortInt>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Byte>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<SmallInt>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Word>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Integer>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Cardinal>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Boolean>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TDigit>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TDigits>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Single>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Double>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Extended>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Comp>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Currency>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TFoo>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<IBaz>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<PInteger>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TTestProc>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TTestMethod>);
  {$IFNDEF NEXTGEN}
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TStr1>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TStr2>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TStr3>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<ShortString>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<AnsiString>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<WideString>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<AnsiChar>);
  {$ENDIF}
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<UnicodeString>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Variant>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<Int64>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<UInt64>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TBytes>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<WideChar>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TTestArray>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TManagedRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TFooBarRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TManagedArray>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByKey<TFooBarArray>);

  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<ShortInt>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Byte>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<SmallInt>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Word>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Integer>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Cardinal>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Boolean>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<TDigit>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Single>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Double>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Extended>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Comp>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Currency>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<Int64>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<UInt64>);
  {$IFNDEF NEXTGEN}
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<AnsiChar>);
  {$ENDIF}
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<WideChar>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<TSimpleRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<TManagedRecord>);
  TDUnitX.RegisterTestFixture(TTestTgoValueDictionaryByValue<TFooBarRecord>);
end.
