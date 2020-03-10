unit Tests.Grijjy.PropertyBag;

interface

uses
  DUnitX.TestFramework,
  Grijjy.PropertyBag;

type
  TTestTgoPropertyBag = class
  private
    FCUT: TgoPropertyBag;
  public
    [Setup] procedure SetUp;
    [Teardown] procedure TearDown;

    [Test] procedure TestAsBoolean;
    [Test] procedure TestAsInteger;
    [Test] procedure TestAsCardinal;
    [Test] procedure TestAsInt64;
    [Test] procedure TestAsUInt64;
    [Test] procedure TestAsSingle;
    [Test] procedure TestAsDouble;
    [Test] procedure TestAsPointer;
    [Test] procedure TestAsString;
    [Test] procedure TestAsInterface;
    [Test] procedure TestAsObject;
    [Test] procedure TestAsBytes;
    [Test] procedure TestAsArray;
    [Test] procedure TestAsRecord;
    [Test] procedure TestClear;
    [Test] procedure TestRemove;
    [Test] procedure TestCaseSensitive;
    [Test] procedure TestInterfaceInstanceCounts;
    [Test] procedure TestObjectInstanceCounts;
    [Test] procedure TestStringCopyOnWrite;
    [Test] procedure TestTBytesCopyOnWrite;
    [Test] procedure TestMixedTypes;
  end;

implementation

uses
  System.Types,
  System.SysUtils;

type
  TIntegerArray = TArray<Integer>;

type
  TManagedRecord = record
    S: String;
  end;

type
  TFoo = class
  public class var
    InstanceCount: Integer;
  private
    FValue: Integer;
  public
    constructor Create(const AValue: Integer);
    destructor Destroy; override;

    property Value: Integer read FValue write FValue;
  end;

type
  IBar = interface
  ['{CC3437FD-CDE2-4A3A-BAFE-266394DF4018}']
    function GetValue: Integer;
    procedure SetValue(const AValue: Integer);

    property Value: Integer read GetValue write SetValue;
  end;

type
  TBar = class(TInterfacedObject, IBar)
  public class var
    InstanceCount: Integer;
  private
    FValue: Integer;
  protected
    function GetValue: Integer;
    procedure SetValue(const AValue: Integer);
  public
    constructor Create(const AValue: Integer);
    destructor Destroy; override;
  end;

{ TFoo }

constructor TFoo.Create(const AValue: Integer);
begin
  Inc(InstanceCount);
  inherited Create;
  FValue := AValue;
end;

destructor TFoo.Destroy;
begin
  Dec(InstanceCount);
  inherited;
end;

{ TBar }

constructor TBar.Create(const AValue: Integer);
begin
  Inc(InstanceCount);
  inherited Create;
  FValue := AValue;
end;

destructor TBar.Destroy;
begin
  Dec(InstanceCount);
  inherited;
end;

function TBar.GetValue: Integer;
begin
  Result := FValue;
end;

procedure TBar.SetValue(const AValue: Integer);
begin
  FValue := AValue;
end;

{ TTestTgoPropertyBag }

procedure TTestTgoPropertyBag.SetUp;
begin
  ReportMemoryLeaksOnShutdown := True;
  FCUT := TgoPropertyBag.Create;
end;

procedure TTestTgoPropertyBag.TearDown;
begin
  FCUT.Free;
end;

procedure TTestTgoPropertyBag.TestAsArray;
var
  Integers: TIntegerArray;
begin
  Assert.AreEqual<TIntegerArray>(nil, FCUT.AsArray<Integer>('foo'));

  Integers := TIntegerArray.Create(-3, 42, 10000000);
  FCUT.SetAsArray<Integer>('foo', Integers);
  Assert.AreEqual<TIntegerArray>(Integers, FCUT.AsArray<Integer>('foo'));

  Integers := nil;
  Integers := FCUT.AsArray<Integer>('foo');
  Assert.AreEqual(3, Length(Integers));
  Assert.AreEqual(-3, Integers[0]);
  Assert.AreEqual(42, Integers[1]);
  Assert.AreEqual(10000000, Integers[2]);

  {$IFDEF DEBUG}
  Assert.WillRaise(
    procedure
    begin
      FCUT.AsArray<Single>('foo');
    end, EAssertionFailed);
  {$ENDIF}

  FCUT.AsSingle['foo'] := 1.5;
  Assert.AreEqual<TIntegerArray>(nil, FCUT.AsArray<Integer>('foo'));
end;

procedure TTestTgoPropertyBag.TestAsBoolean;
begin
  Assert.IsFalse(FCUT.AsBoolean['foo']);

  FCUT.AsBoolean['foo'] := True;
  Assert.IsTrue(FCUT.AsBoolean['foo']);

  FCUT.AsInteger['foo'] := 42;
  Assert.IsFalse(FCUT.AsBoolean['foo']);
end;

procedure TTestTgoPropertyBag.TestAsBytes;
var
  Bytes: TBytes;
begin
  Assert.AreEqual<TBytes>(nil, FCUT.AsBytes['foo']);

  Bytes := TBytes.Create(1, 2, 3);
  FCUT.AsBytes['foo'] := Bytes;
  Assert.AreEqual<TBytes>(Bytes, FCUT.AsBytes['foo']);

  Bytes := nil;
  Bytes := FCUT.AsBytes['foo'];
  Assert.AreEqual(3, Length(Bytes));
  Assert.AreEqual<Byte>(1, Bytes[0]);
  Assert.AreEqual<Byte>(2, Bytes[1]);
  Assert.AreEqual<Byte>(3, Bytes[2]);

  FCUT.AsCardinal['foo'] := 42;
  Assert.AreEqual<TBytes>(nil, FCUT.AsBytes['foo']);
end;

procedure TTestTgoPropertyBag.TestAsCardinal;
begin
  Assert.AreEqual(0, FCUT.AsCardinal['foo']);

  FCUT.AsCardinal['foo'] := 42;
  Assert.AreEqual(42, FCUT.AsCardinal['foo']);

  FCUT.AsInteger['foo'] := 42;
  Assert.AreEqual(0, FCUT.AsCardinal['foo']);
end;

procedure TTestTgoPropertyBag.TestAsDouble;
begin
  Assert.AreEqual<Double>(0, FCUT.AsDouble['foo']);

  FCUT.AsDouble['foo'] := -3.25;
  Assert.AreEqual<Double>(-3.25, FCUT.AsDouble['foo']);

  FCUT.AsSingle['foo'] := -3.25;
  Assert.AreEqual<Double>(0, FCUT.AsDouble['foo']);
end;

procedure TTestTgoPropertyBag.TestAsInt64;
begin
  Assert.AreEqual<Int64>(0, FCUT.AsInt64['foo']);

  FCUT.AsInt64['foo'] := -12345678909876;
  Assert.AreEqual<Int64>(-12345678909876, FCUT.AsInt64['foo']);

  FCUT.AsInteger['foo'] := 42;
  Assert.AreEqual<Int64>(0, FCUT.AsInt64['foo']);
end;

procedure TTestTgoPropertyBag.TestAsInteger;
begin
  Assert.AreEqual(0, FCUT.AsInteger['foo']);

  FCUT.AsInteger['foo'] := -42;
  Assert.AreEqual(-42, FCUT.AsInteger['foo']);

  FCUT.AsCardinal['foo'] := 42;
  Assert.AreEqual(0, FCUT.AsInteger['foo']);
end;

procedure TTestTgoPropertyBag.TestAsInterface;
var
  Bar: IBar;
begin
  Assert.AreEqual<IInterface>(nil, FCUT.AsInterface['foo']);

  Bar := TBar.Create(42);
  FCUT.AsInterface['foo'] := Bar;
  Assert.AreEqual<IInterface>(Bar, FCUT.AsInterface['foo']);

  Bar := nil;
  Bar := FCUT.AsInterface['foo'] as IBar;
  Assert.IsNotNull(Bar);
  Assert.AreEqual(42, Bar.Value);

  FCUT.AsCardinal['foo'] := 42;
  Assert.AreEqual<IInterface>(nil, FCUT.AsInterface['foo']);
end;

procedure TTestTgoPropertyBag.TestAsObject;
var
  Foo: TFoo;
begin
  Assert.AreEqual<TObject>(nil, FCUT.AsObject['foo']);

  Foo := TFoo.Create(42);
  FCUT.AsObject['foo'] := Foo;
  Assert.AreEqual<TObject>(Foo, FCUT.AsObject['foo']);

  {$IFDEF AUTOREFCOUNT}
  Foo := nil;
  {$ENDIF}
  Foo := FCUT.AsObject['foo'] as TFoo;
  Assert.IsNotNull(Foo);
  Assert.AreEqual(42, Foo.Value);

  FCUT.AsCardinal['foo'] := 42;
  Assert.AreEqual<TObject>(nil, FCUT.AsObject['foo']);

  Foo.Free;
end;

procedure TTestTgoPropertyBag.TestAsPointer;
begin
  Assert.AreEqual(nil, FCUT.AsPointer['foo']);

  FCUT.AsPointer['foo'] := @FCUT;
  Assert.AreEqual(@FCUT, FCUT.AsPointer['foo']);

  FCUT.AsCardinal['foo'] := 42;
  Assert.AreEqual(nil, FCUT.AsPointer['foo']);
end;

procedure TTestTgoPropertyBag.TestAsRecord;
var
  P: TPoint;
  {$IFOPT C+}
  M: TManagedRecord;
  {$ENDIF}
begin
  P := Point(1, 2);
  P := FCUT.AsRecord<TPoint>('foo');
  Assert.AreEqual(0, P.X);
  Assert.AreEqual(0, P.Y);

  FCUT.SetAsRecord('foo', Point(1, 2));
  P := Point(0, 0);
  P := FCUT.AsRecord<TPoint>('foo');
  Assert.AreEqual(1, P.X);
  Assert.AreEqual(2, P.Y);

  {$IFOPT C+}
  M.S := 'bar';
  Assert.WillRaise(
    procedure
    begin
      FCUT.SetAsRecord('foo', M);
    end, EAssertionFailed);
  {$ENDIF}

  {$IFDEF DEBUG}
  Assert.WillRaise(
    procedure
    begin
      FCUT.AsRecord<TRect>('foo');
    end, EAssertionFailed);
  {$ENDIF}

  FCUT.AsCardinal['foo'] := 42;
  P := FCUT.AsRecord<TPoint>('foo');
  Assert.AreEqual(0, P.X);
  Assert.AreEqual(0, P.Y);
end;

procedure TTestTgoPropertyBag.TestAsSingle;
begin
  Assert.AreEqual<Single>(0, FCUT.AsSingle['foo']);

  FCUT.AsSingle['foo'] := -3.25;
  Assert.AreEqual<Single>(-3.25, FCUT.AsSingle['foo']);

  FCUT.AsDouble['foo'] := -3.25;
  Assert.AreEqual<Single>(0, FCUT.AsSingle['foo']);
end;

procedure TTestTgoPropertyBag.TestAsString;
begin
  Assert.AreEqual('', FCUT.AsString['foo']);

  FCUT.AsString['foo'] := 'bar';
  Assert.AreEqual('bar', FCUT.AsString['foo']);

  FCUT.AsCardinal['foo'] := 42;
  Assert.AreEqual('', FCUT.AsString['foo']);
end;

procedure TTestTgoPropertyBag.TestAsUInt64;
begin
  Assert.AreEqual<UInt64>(0, FCUT.AsUInt64['foo']);

  FCUT.AsUInt64['foo'] := 12345678909876;
  Assert.AreEqual<UInt64>(12345678909876, FCUT.AsUInt64['foo']);

  FCUT.AsInt64['foo'] := 12345678909876;
  Assert.AreEqual<UInt64>(0, FCUT.AsUInt64['foo']);
end;

procedure TTestTgoPropertyBag.TestCaseSensitive;
begin
  FCUT.AsInteger['foo'] := 42;
  FCUT.AsString['Foo'] := 'bar';

  Assert.AreEqual(42, FCUT.AsInteger['foo']);
  Assert.AreEqual('bar', FCUT.AsString['Foo']);
end;

procedure TTestTgoPropertyBag.TestClear;
begin
  FCUT.AsInteger['foo'] := 42;
  FCUT.AsString['bar'] := 'baz';
  Assert.AreEqual(2, FCUT.Count);

  FCUT.Clear;
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoPropertyBag.TestInterfaceInstanceCounts;
var
  Bar1, Bar2: IBar;
begin
  Bar1 := TBar.Create(42);
  Bar2 := TBar.Create(3);
  Assert.AreEqual(2, TBar.InstanceCount);

  FCUT.AsInterface['bar1'] := Bar1;
  FCUT.AsInterface['bar2'] := Bar2;
  Assert.AreEqual(2, TBar.InstanceCount);

  Bar1 := nil;
  Assert.AreEqual(2, TBar.InstanceCount);

  FCUT.Remove('bar1');
  Assert.AreEqual(1, TBar.InstanceCount);

  FCUT.Remove('bar2');
  Assert.AreEqual(1, TBar.InstanceCount);

  Bar2 := nil;
  Assert.AreEqual(0, TBar.InstanceCount);
end;

procedure TTestTgoPropertyBag.TestMixedTypes;
const
  EPSILON = 0.000001;
var
  Foo1, Foo2: TFoo;
  A1, A1A: TArray<Integer>;
  A2, A2A: TArray<Single>;
  R1, R1A: TPointF;
  R2, R2A: TRect;
begin
  ReportMemoryLeaksOnShutdown := True;

  Foo1 := nil;
  Foo2 := nil;
  try
    Foo1 := TFoo.Create(1);
    Foo2 := TFoo.Create(2);
    A1 := TArray<Integer>.Create(1, 2, 3);
    A2 := TArray<Single>.Create(1.5, -2.25, 3.125);
    R1 := PointF(-1.2, 3.4);
    R2 := Rect(5, 6, 7, 8);

    { Set properties }
    FCUT.AsBoolean['BoolProp1'] := False;
    FCUT.AsBoolean['BoolProp2'] := True;
    FCUT.AsInteger['IntProp1'] := 42;
    FCUT.AsInteger['IntProp2'] := -42;
    FCUT.AsCardinal['CardinalProp1'] := 1;
    FCUT.AsCardinal['CardinalProp2'] := $FFFFFFFF;
    FCUT.AsInt64['Int64Prop1'] := -$1234567890;
    FCUT.AsInt64['Int64Prop2'] :=  $1234567890;
    FCUT.AsUInt64['UInt64Prop1'] := 2;
    FCUT.AsUInt64['UInt64Prop2'] := $FEDCBA9876543210;
    FCUT.AsSingle['SingleProp1'] := Pi;
    FCUT.AsSingle['SingleProp2'] := -Pi;
    FCUT.AsDouble['DoubleProp1'] := Pi * Pi;
    FCUT.AsDouble['DoubleProp2'] := -Pi * Pi;
    FCUT.AsPointer['PointerProp1'] := @FCUT;
    FCUT.AsString['StringProp1'] := 'Foo';
    FCUT.AsString['StringProp2'] := 'Bar';
    FCUT.AsInterface['InterfaceProp1'] := TBar.Create(1);
    FCUT.AsInterface['InterfaceProp2'] := TBar.Create(2);
    FCUT.AsObject['ObjectProp1'] := Foo1;
    FCUT.AsObject['ObjectProp2'] := Foo2;
    FCUT.AsBytes['BytesProp1'] := BytesOf('Foo');
    FCUT.AsBytes['BytesProp2'] := BytesOf('Bar');
    FCUT.SetAsArray<Integer>('ArrayProp1', A1);
    FCUT.SetAsArray<Single>('ArrayProp2', A2);
    FCUT.SetAsRecord('RecordProp1', R1);
    FCUT.SetAsRecord('RecordProp2', R2);

    { Check properties, including non-existing ones and wrong-case names }
    Assert.AreEqual(False, FCUT.AsBoolean['BoolProp1']);
    Assert.AreEqual(True, FCUT.AsBoolean['BoolProp2']);
    Assert.AreEqual(False, FCUT.AsBoolean['BoolProp3']);
    Assert.AreEqual(False, FCUT.AsBoolean['boolProp1']);

    Assert.AreEqual(42, FCUT.AsInteger['IntProp1']);
    Assert.AreEqual(-42, FCUT.AsInteger['IntProp2']);
    Assert.AreEqual(0, FCUT.AsInteger['IntProp3']);
    Assert.AreEqual(0, FCUT.AsInteger['Intprop1']);

    Assert.AreEqual(1, FCUT.AsCardinal['CardinalProp1']);
    Assert.AreEqual($FFFFFFFF, FCUT.AsCardinal['CardinalProp2']);
    Assert.AreEqual(0, FCUT.AsCardinal['CardinalProp3']);
    Assert.AreEqual(0, FCUT.AsCardinal['cardinalprop1']);

    Assert.AreEqual(-$1234567890, FCUT.AsInt64['Int64Prop1']);
    Assert.AreEqual($1234567890, FCUT.AsInt64['Int64Prop2']);
    Assert.AreEqual<Int64>(0, FCUT.AsInt64['Int64Prop3']);

    Assert.AreEqual<UInt64>(2, FCUT.AsUInt64['UInt64Prop1']);
    Assert.AreEqual($FEDCBA9876543210, FCUT.AsUInt64['UInt64Prop2']);
    Assert.AreEqual<UInt64>(0, FCUT.AsUInt64['UInt64Prop3']);

    Assert.AreEqual(Pi, FCUT.AsSingle['SingleProp1'], EPSILON);
    Assert.AreEqual(-Pi, FCUT.AsSingle['SingleProp2'], EPSILON);
    Assert.AreEqual<Single>(0, FCUT.AsSingle['SingleProp3']);

    Assert.AreEqual(Pi * Pi, FCUT.AsDouble['DoubleProp1'], EPSILON);
    Assert.AreEqual(-Pi * Pi, FCUT.AsDouble['DoubleProp2'], EPSILON);
    Assert.AreEqual<Double>(0, FCUT.AsDouble['DoubleProp3']);

    Assert.AreEqual(@FCUT, FCUT.AsPointer['PointerProp1']);
    Assert.AreEqual(nil, FCUT.AsPointer['PointerProp2']);

    Assert.AreEqual('Foo', FCUT.AsString['StringProp1']);
    Assert.AreEqual('Bar', FCUT.AsString['StringProp2']);
    Assert.AreEqual('', FCUT.AsString['StringProp3']);

    Assert.IsNotNull(FCUT.AsInterface['InterfaceProp1']);
    Assert.AreEqual(1, (FCUT.AsInterface['InterfaceProp1'] as IBar).Value);
    Assert.IsNotNull(FCUT.AsInterface['InterfaceProp2']);
    Assert.AreEqual(2, (FCUT.AsInterface['InterfaceProp2'] as IBar).Value);
    Assert.IsNull(FCUT.AsInterface['InterfaceProp3']);

    Assert.IsNotNull(FCUT.AsObject['ObjectProp1']);
    Assert.AreEqual(1, (FCUT.AsObject['ObjectProp1'] as TFoo).Value);
    Assert.IsNotNull(FCUT.AsObject['ObjectProp2']);
    Assert.AreEqual(2, (FCUT.AsObject['ObjectProp2'] as TFoo).Value);
    Assert.IsNull(FCUT.AsObject['ObjectProp3']);

    Assert.AreEqual('Foo', StringOf(FCUT.AsBytes['BytesProp1']));
    Assert.AreEqual('Bar', StringOf(FCUT.AsBytes['BytesProp2']));
    Assert.AreEqual(0, Length(FCUT.AsBytes['BytesProp3']));

    A1A := FCUT.AsArray<Integer>('ArrayProp1');
    Assert.AreEqual(3, Length(A1A));
    Assert.AreEqual(1, A1A[0]);
    Assert.AreEqual(2, A1A[1]);
    Assert.AreEqual(3, A1A[2]);

    A2A := FCUT.AsArray<Single>('ArrayProp2');
    Assert.AreEqual(3, Length(A2A));
    Assert.AreEqual<Single>(1.5, A2A[0]);
    Assert.AreEqual<Single>(-2.25, A2A[1]);
    Assert.AreEqual<Single>(3.125, A2A[2]);

    A1 := FCUT.AsArray<Integer>('ArrayProp3');
    Assert.AreEqual(0, Length(A1));

    R1A := FCUT.AsRecord<TPointF>('RecordProp1');
    Assert.AreEqual(-1.2, R1A.X, EPSILON);
    Assert.AreEqual( 3.4, R1A.Y, EPSILON);

    R2A := FCUT.AsRecord<TRect>('RecordProp2');
    Assert.AreEqual(5, R2A.Left);
    Assert.AreEqual(6, R2A.Top);
    Assert.AreEqual(7, R2A.Right);
    Assert.AreEqual(8, R2A.Bottom);

    R1 := FCUT.AsRecord<TPointF>('RecordProp3');
    Assert.AreEqual<Single>(0, R1.X);
    Assert.AreEqual<Single>(0, R1.Y);

    { Check type mismatches (no conversion is performed) }
    Assert.AreEqual(False, FCUT.AsBoolean['IntProp1']);
    Assert.AreEqual(0, FCUT.AsInteger['CardinalProp2']);
    Assert.AreEqual('', FCUT.AsString['BoolProp2']);
  finally
    Foo1.Free;
    Foo2.Free;
  end;
end;

procedure TTestTgoPropertyBag.TestObjectInstanceCounts;
var
  Foo1, Foo2: TFoo;
begin
  Foo1 := TFoo.Create(42);
  Foo2 := TFoo.Create(3);
  Assert.AreEqual(2, TFoo.InstanceCount);

  FCUT.AsObject['foo1'] := Foo1;
  FCUT.AsObject['foo2'] := Foo2;
  Assert.AreEqual(2, TFoo.InstanceCount);

  Foo1.Free;
  {$IFDEF AUTOREFCOUNT}
  Assert.AreEqual(2, TFoo.InstanceCount);
  {$ELSE}
  Assert.AreEqual(1, TFoo.InstanceCount);
  {$ENDIF}

  FCUT.Remove('foo1');
  Assert.AreEqual(1, TFoo.InstanceCount);

  FCUT.Remove('foo2');
  Assert.AreEqual(1, TFoo.InstanceCount);

  Foo2.Free;
  Assert.AreEqual(0, TFoo.InstanceCount);
end;

procedure TTestTgoPropertyBag.TestRemove;
begin
  FCUT.AsInteger['foo'] := 42;
  FCUT.AsString['bar'] := 'baz';
  Assert.AreEqual(2, FCUT.Count);

  FCUT.Remove('Foo');
  Assert.AreEqual(2, FCUT.Count);

  FCUT.Remove('foo');
  Assert.AreEqual(1, FCUT.Count);

  FCUT.Remove('bar');
  Assert.AreEqual(0, FCUT.Count);
end;

procedure TTestTgoPropertyBag.TestStringCopyOnWrite;
var
  S: String;
begin
  S := 'Foo';
  FCUT.AsString['foo'] := S;
  S := 'Bar';
  Assert.AreEqual('Foo', FCUT.AsString['foo']);
end;

procedure TTestTgoPropertyBag.TestTBytesCopyOnWrite;
var
  B1, B2: TBytes;
begin
  B1 := TBytes.Create(1, 2, 3);
  FCUT.AsBytes['foo'] := B1;
  B1 := [0] + B1 + [4];

  B2 := FCUT.AsBytes['foo'];
  Assert.AreEqual(3, Length(B2));
  Assert.AreEqual<Byte>(1, B2[0]);
  Assert.AreEqual<Byte>(2, B2[1]);
  Assert.AreEqual<Byte>(3, B2[2]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTgoPropertyBag);

end.
