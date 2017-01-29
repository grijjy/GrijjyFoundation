unit Tests.Grijjy.Bson;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Grijjy.Bson;

type
  TTestObjectId = class
  public
    [Test] procedure TestByteArrayConstructor;
    [Test] procedure TestIntegerConstructor;
    [Test] procedure TestIntegerConstructorWithInvalidIncrement;
    [Test] procedure TestIntegerConstructorWithInvalidMachine;
    [Test] procedure TestDateTimeConstructor;
    [Test] procedure TestDateTimeConstructorAtEdgeOfRange;
    [Test] procedure TestDateTimeConstructorOutOfRange;
    [Test] procedure TestStringConstructor;
    [Test] procedure TestGenerateNewId;
    [Test] procedure TestGenerateNewIdWithDateTime;
    [Test] procedure TestGenerateNewIdWithTimeStamp;
    [Test] procedure TestOperators;
    [Test] procedure TestCompareSmallerTimestamp;
    [Test] procedure TestCompareSmallerMachine;
    [Test] procedure TestCompareSmallerPid;
    [Test] procedure TestCompareSmallerIncrement;
    [Test] procedure TestCompareSmallerGeneratedId;
    [Test] procedure TestParse;
    [Test] procedure TestTryParse;
  end;

type
  TTestBsonValue = class
  public
    [Test] procedure ImplicitConversionFromBoolShouldReturnPrecreatedInstance;
    [Test] procedure ImplicitConversionFromDoubleShouldReturnNewInstance;
    [Test] procedure ImplicitConversionFromDoubleShouldReturnPrecreatedInstance;
    [Test] procedure ImplicitConversionFromIntegerShouldReturnNewInstance;
    [Test] procedure ImplicitConversionFromIntegerShouldReturnPrecreatedInstance;
    [Test] procedure ImplicitConversionFromInt64ShouldReturnNewInstance;
    [Test] procedure ImplicitConversionFromInt64ShouldReturnPrecreatedInstance;
    [Test] procedure ImplicitConversionFromStringShouldReturnNewInstance;
    [Test] procedure ImplicitConversionFromStringShouldReturnPrecreatedInstance;
    [Test] procedure TestAsBoolean;
    [Test] procedure TestAsArray;
    [Test] procedure TestAsBsonArray;
    [Test] procedure TestAsByteArray;
    [Test] procedure TestAsBsonBinaryData;
    [Test] procedure TestAsBsonDocument;
    [Test] procedure TestAsBsonJavaScript;
    [Test] procedure TestAsBsonJavaScriptWithScope;
    [Test] procedure TestAsBsonMaxKey;
    [Test] procedure TestAsBsonMinKey;
    [Test] procedure TestAsBsonNull;
    [Test] procedure TestAsBsonRegularExpression;
    [Test] procedure TestAsBsonSymbol;
    [Test] procedure TestAsBsonTimestamp;
    [Test] procedure TestAsDateTime;
    [Test] procedure TestAsDouble;
    [Test] procedure TestAsGuid;
    [Test] procedure TestAsInteger;
    [Test] procedure TestAsInt64;
    [Test] procedure TestAsObjectId;
    [Test] procedure TestAsString;
    [Test] procedure TestBsonValueEqualsFalse;
    [Test] procedure TestBsonValueEqualsTrue;
    [Test] procedure TestBsonValueEqualsDouble;
    [Test] procedure TestBsonValueEqualsInt32;
    [Test] procedure TestBsonValueEqualsInt64;
    [Test] procedure TestImplicitConversionFromBoolean;
    [Test] procedure TestImplicitConversionFromByteArray;
    [Test] procedure TestImplicitConversionFromDateTime;
    [Test] procedure TestImplicitConversionFromSingle;
    [Test] procedure TestImplicitConversionFromDouble;
    [Test] procedure TestImplicitConversionFromGuid;
    [Test] procedure TestImplicitConversionFromInt8;
    [Test] procedure TestImplicitConversionFromUInt8;
    [Test] procedure TestImplicitConversionFromInt16;
    [Test] procedure TestImplicitConversionFromUInt16;
    [Test] procedure TestImplicitConversionFromInt32;
    [Test] procedure TestImplicitConversionFromUInt32;
    [Test] procedure TestImplicitConversionFromInt64;
    [Test] procedure TestImplicitConversionFromUInt64;
    [Test] procedure TestImplicitConversionObjectId;
    [Test] procedure TestImplicitConversionString;
  end;

type
  TTestBsonArray = class
  public
    [Test] procedure TestAdd;
    [Test] procedure TestAddNil;
    [Test] procedure TestClone;
    [Test] procedure TestClear;
    [Test] procedure TestContains;
    [Test] procedure TestContainsNil;
    [Test] procedure TestDeepClone;
    [Test] procedure TestEquals;
    [Test] procedure TestNotEquals;
    [Test] procedure TestIndexer;
    [Test] procedure TestIndexerSetNil;
    [Test] procedure TestIndexOf;
    [Test] procedure TestDelete;
    [Test] procedure TestToArray;
  end;

type
  TTestBsonDocument = class
  public
    [Test] procedure TestAddArrayWithOneEntry;
    [Test] procedure TestAddArrayWithTwoEntries;
    [Test] procedure TestAddDocumentWithOneEntry;
    [Test] procedure TestAddDocumentWithTwoEntries;
    [Test] procedure TestAddDocumentWithNestedDocument;
    [Test] procedure TestAutoIndexing;
    [Test] procedure TestClear;
    [Test] procedure TestClone;
    [Test] procedure TestConstructorAllowDuplicateNames;
    [Test] procedure TestConstructorElement;
    [Test] procedure TestConstructorNameValue;
    [Test] procedure TestConstructorNoArgs;
    [Test] procedure TestContains;
    [Test] procedure TestContainsValue;
    [Test] procedure TestDeepClone;
    [Test] procedure TestElementAccess;
    [Test] procedure TestElementNameZeroLength;
    [Test] procedure TestElementGetValueByIndex;
    [Test] procedure TestElementGetValueByName;
    [Test] procedure TestIndexer;
    [Test] procedure TestIndexOfName;
    [Test] procedure TestOperatorEqual;
    [Test] procedure TestOperatorNotEqual;
    [Test] procedure TestParse;
    [Test] procedure TestRemove;
    [Test] procedure TestDelete;
    [Test] procedure TestSetByIndex;
    [Test] procedure TestSetByName;
    [Test] procedure TestSpecBsonAwesomeWithBsonDocument;
    [Test] procedure TestSpecBsonAwesomeWithBsonWriter;
    [Test] procedure TestSpecHelloWorldWithBsonDocument;
    [Test] procedure TestSpecHelloWorldWithBsonWriter;
    [Test] procedure TestTryGetElement;
    [Test] procedure TestTryGetValue;
  end;

type
  TTestBsonEquals = class
  public
    [Test] procedure TestBsonArrayEquals;
    [Test] procedure TestBsonBinaryDataEquals;
    [Test] procedure TestBsonDocumentEquals;
    [Test] procedure TestBsonElementEquals;
    [Test] procedure TestBsonJavaScriptEquals;
    [Test] procedure TestBsonJavaScriptWithScopeEquals;
    [Test] procedure TestBsonObjectIdEquals;
    [Test] procedure TestBsonSymbolEquals;
    [Test] procedure TestBsonTimestampEquals;
  end;

type
  TTestBsonDocumentAllTypes = class
  private
    procedure CheckDocument(const ADoc: TgoBsonDocument);
  public
    [Test] procedure TestManualCreate;
    [Test] procedure TestJsonFromFile;
    [Test] procedure TestWriterSettings;
  end;

type
  TTestBsonValueEquals = class
  public
    [Test] procedure TestBsonArrayEquals;
    [Test] procedure TestBsonBinaryDataEquals;
    [Test] procedure TestBsonDocumentEquals;
    [Test] procedure TestBsonJavaScriptEquals;
    [Test] procedure TestBsonJavaScriptWithScopeEquals;
    [Test] procedure TestBsonMaxKeyEquals;
    [Test] procedure TestBsonMinKeyEquals;
    [Test] procedure TestBsonNullEquals;
    [Test] procedure TestBsonRegularExpressionEquals;
    [Test] procedure TestBsonSymbolEquals;
    [Test] procedure TestBsonTimestampEquals;
    [Test] procedure TestBsonUndefinedEquals;
  end;

function ReferenceEquals(const A, B: TgoBsonValue): Boolean;
function DecodeByteString(const AValue: String): TBytes;
function LoadTestData(const APath: String): TBytes;
function LoadTestString(const APath: String): String;

implementation

uses
  System.Zip,
  System.Math,
  System.Types,
  System.Classes,
  System.DateUtils,
  Grijjy.Bson.IO;

var
  GTestDataStream: TStream = nil;
  GTestDataZipFile: TZipFile = nil;

function ReferenceEquals(const A, B: TgoBsonValue): Boolean;
var
  P1: Pointer absolute A;
  P2: Pointer absolute B;
begin
  Result := (P1 = P2);
end;

function DecodeByteString(const AValue: String): TBytes;
var
  Src, Dst: Integer;
  C: Char;
  S: String;
begin
  SetLength(Result, AValue.Length);
  Src := 0;
  Dst := 0;
  while (Src < AValue.Length) do
  begin
    C := AValue.Chars[Src];
    if (C = '\') then
    begin
      Inc(Src);
      System.Assert(Src < AValue.Length);
      C := AValue.Chars[Src];
      System.Assert(C = 'x');
      Inc(Src);
      S := AValue.Substring(Src, 2);
      Result[Dst] := StrToInt('$' + S);
      Inc(Src, 2);
      Inc(Dst);
    end
    else
    begin
      Result[Dst] := Ord(C);
      Inc(Src);
      Inc(Dst);
    end;
  end;
  SetLength(Result, Dst);
end;

function LoadTestData(const APath: String): TBytes;
begin
  if (GTestDataZipFile = nil) then
  begin
    System.Assert(GTestDataStream = nil);
    GTestDataStream := TResourceStream.Create(HInstance, 'JSON_TEST_DATA', RT_RCDATA);
    GTestDataZipFile := TZipFile.Create;
    GTestDataZipFile.Open(GTestDataStream, TZipMode.zmRead);
  end;

  GTestDataZipFile.Read(APath, Result);
end;

function LoadTestString(const APath: String): String;
var
  Bytes: TBytes;
begin
  Bytes := LoadTestData(APath);
  Result := TEncoding.UTF8.GetString(Bytes);
end;

{ TTestObjectId }

procedure TTestObjectId.TestByteArrayConstructor;
var
  Bytes: TBytes;
  ObjectId: TgoObjectId;
  DT: TDateTime;
begin
  Bytes := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
  ObjectId := TgoObjectId.Create(Bytes);
  Assert.AreEqual($01020304, ObjectId.Timestamp);
  Assert.AreEqual($050607, ObjectId.Machine);
  Assert.AreEqual($0809, Integer(ObjectId.Pid));
  Assert.AreEqual($0A0B0C, ObjectId.Increment);

  DT := IncSecond(UnixDateDelta, $01020304);
  Assert.AreEqual(DT, ObjectId.CreationTime);

  Assert.AreEqual('0102030405060708090a0b0c', ObjectId.ToString);
  Assert.AreEqual(Bytes, ObjectId.ToByteArray);
end;

procedure TTestObjectId.TestCompareSmallerGeneratedId;
var
  ObjectId1, ObjectId2: TgoObjectId;
begin
  ObjectId1 := TgoObjectId.GenerateNewId;
  if (ObjectId1.Increment = $FFFFFF) then
    ObjectId1 := TgoObjectId.GenerateNewId;
  ObjectId2 := TgoObjectId.GenerateNewId;

  Assert.IsTrue(ObjectId1 < ObjectId2);
  Assert.IsTrue(ObjectId1 <= ObjectId2);
  Assert.IsTrue(ObjectId1 <> ObjectId2);
  Assert.IsFalse(ObjectId1 = ObjectId2);
  Assert.IsFalse(ObjectId1 > ObjectId2);
  Assert.IsFalse(ObjectId1 >= ObjectId2);
end;

procedure TTestObjectId.TestCompareSmallerIncrement;
var
  ObjectId1, ObjectId2: TgoObjectId;
begin
  ObjectId1 := TgoObjectId.Create('0102030405060708090a0b0c');
  ObjectId2 := TgoObjectId.Create('0102030405060708090a0b0d');
  Assert.IsTrue(ObjectId1 < ObjectId2);
  Assert.IsTrue(ObjectId1 <= ObjectId2);
  Assert.IsTrue(ObjectId1 <> ObjectId2);
  Assert.IsFalse(ObjectId1 = ObjectId2);
  Assert.IsFalse(ObjectId1 > ObjectId2);
  Assert.IsFalse(ObjectId1 >= ObjectId2);
end;

procedure TTestObjectId.TestCompareSmallerMachine;
var
  ObjectId1, ObjectId2: TgoObjectId;
begin
  ObjectId1 := TgoObjectId.Create('0102030405060708090a0b0c');
  ObjectId2 := TgoObjectId.Create('0102030505060708090a0b0c');
  Assert.IsTrue(ObjectId1 < ObjectId2);
  Assert.IsTrue(ObjectId1 <= ObjectId2);
  Assert.IsTrue(ObjectId1 <> ObjectId2);
  Assert.IsFalse(ObjectId1 = ObjectId2);
  Assert.IsFalse(ObjectId1 > ObjectId2);
  Assert.IsFalse(ObjectId1 >= ObjectId2);
end;

procedure TTestObjectId.TestCompareSmallerPid;
var
  ObjectId1, ObjectId2: TgoObjectId;
begin
  ObjectId1 := TgoObjectId.Create('0102030405060708090a0b0c');
  ObjectId2 := TgoObjectId.Create('01020304050607080a0a0b0c');
  Assert.IsTrue(ObjectId1 < ObjectId2);
  Assert.IsTrue(ObjectId1 <= ObjectId2);
  Assert.IsTrue(ObjectId1 <> ObjectId2);
  Assert.IsFalse(ObjectId1 = ObjectId2);
  Assert.IsFalse(ObjectId1 > ObjectId2);
  Assert.IsFalse(ObjectId1 >= ObjectId2);
end;

procedure TTestObjectId.TestCompareSmallerTimestamp;
var
  ObjectId1, ObjectId2: TgoObjectId;
begin
  ObjectId1 := TgoObjectId.Create('0102030405060708090a0b0c');
  ObjectId2 := TgoObjectId.Create('0102030405060808090a0b0c');
  Assert.IsTrue(ObjectId1 < ObjectId2);
  Assert.IsTrue(ObjectId1 <= ObjectId2);
  Assert.IsTrue(ObjectId1 <> ObjectId2);
  Assert.IsFalse(ObjectId1 = ObjectId2);
  Assert.IsFalse(ObjectId1 > ObjectId2);
  Assert.IsFalse(ObjectId1 >= ObjectId2);
end;

procedure TTestObjectId.TestDateTimeConstructor;
var
  Bytes: TBytes;
  ObjectId: TgoObjectId;
  DT: TDateTime;
begin
  Bytes := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
  DT := IncSecond(UnixDateDelta, $01020304);
  ObjectId := TgoObjectId.Create(DT, True, $050607, $0809, $0a0b0c);
  Assert.AreEqual($01020304, ObjectId.Timestamp);
  Assert.AreEqual($050607, ObjectId.Machine);
  Assert.AreEqual($0809, Integer(ObjectId.Pid));
  Assert.AreEqual($0A0B0C, ObjectId.Increment);

  Assert.AreEqual(DT, ObjectId.CreationTime);

  Assert.AreEqual('0102030405060708090a0b0c', ObjectId.ToString);
  Assert.AreEqual(Bytes, ObjectId.ToByteArray);
end;

procedure TTestObjectId.TestDateTimeConstructorAtEdgeOfRange;
var
  I: Integer;
  Delta: Int64;
  DT: TDateTime;
  ObjectId: TgoObjectId;
begin
  Delta := Integer.MinValue;
  for I := 0 to 1 do
  begin
    DT := IncSecond(UnixDateDelta, Delta);
    ObjectId := TgoObjectId.Create(DT, True, 0, 0, 0);
    Assert.AreEqual(DT, ObjectId.CreationTime);
    Delta := Integer.MaxValue;
  end;
end;

procedure TTestObjectId.TestDateTimeConstructorOutOfRange;
var
  I: Integer;
  Delta: Int64;
  DT: TDateTime;
  ObjectId: TgoObjectId;
begin
  Delta := Int64(Integer.MinValue) - 1;
  for I := 0 to 1 do
  begin
    DT := IncSecond(UnixDateDelta, Delta);
    Assert.WillRaise(
      procedure
      begin
        ObjectId := TgoObjectId.Create(DT, True, 0, 0, 0);
      end, EArgumentOutOfRangeException);
    Delta := Int64(Integer.MaxValue) + 1;
  end;
end;

procedure TTestObjectId.TestGenerateNewId;
var
  Timestamp1, Timestamp2, Actual, Delta: Integer;
  ObjectId1, ObjectId2: TgoObjectId;
begin
  Timestamp1 := SecondsBetween(TTimeZone.Local.ToUniversalTime(Now), UnixDateDelta);
  ObjectId1 := TgoObjectId.GenerateNewId;
  ObjectId2 := TgoObjectId.GenerateNewId;
  Timestamp2 := SecondsBetween(TTimeZone.Local.ToUniversalTime(Now), UnixDateDelta);

  Actual := ObjectId1.Timestamp;
  Assert.IsTrue((Actual = Timestamp1) or (Actual = Timestamp2));
  Assert.IsTrue(ObjectId1.Machine <> 0);
  Assert.IsTrue(ObjectId1.Pid <> 0);

  Actual := ObjectId2.Timestamp;
  Assert.IsTrue((Actual = Timestamp1) or (Actual = Timestamp2));
  Assert.IsTrue(ObjectId2.Machine <> 0);
  Assert.IsTrue(ObjectId2.Pid <> 0);

  Delta := ObjectId2.Increment - ObjectId1.Increment;
  Assert.IsTrue((Delta = 1) or ((ObjectId1.Increment = $FFFFFF) and (ObjectId2.Increment = 0)));
end;

procedure TTestObjectId.TestGenerateNewIdWithDateTime;
var
  Timestamp: TDateTime;
  ObjectId: TgoObjectId;
begin
  Timestamp := EncodeDateTime(2011, 1, 2, 3, 4, 5, 0);
  ObjectId := TgoObjectId.GenerateNewId(Timestamp, False);
  Timestamp := TTimeZone.Local.ToUniversalTime(Timestamp);
  Assert.AreEqual(Timestamp, ObjectId.CreationTime);
  Assert.IsTrue(ObjectId.Machine <> 0);
  Assert.IsTrue(ObjectId.Pid <> 0);
end;

procedure TTestObjectId.TestGenerateNewIdWithTimeStamp;
var
  Timestamp: Integer;
  ObjectId: TgoObjectId;
begin
  Timestamp := $01020304;
  ObjectId := TgoObjectId.GenerateNewId(Timestamp);
  Assert.AreEqual(Timestamp, ObjectId.Timestamp);
  Assert.IsTrue(ObjectId.Machine <> 0);
  Assert.IsTrue(ObjectId.Pid <> 0);
end;

procedure TTestObjectId.TestIntegerConstructor;
var
  Bytes: TBytes;
  ObjectId: TgoObjectId;
  DT: TDateTime;
begin
  Bytes := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
  ObjectId := TgoObjectId.Create($01020304, $050607, $0809, $0a0b0c);
  Assert.AreEqual($01020304, ObjectId.Timestamp);
  Assert.AreEqual($050607, ObjectId.Machine);
  Assert.AreEqual($0809, Integer(ObjectId.Pid));
  Assert.AreEqual($0A0B0C, ObjectId.Increment);

  DT := IncSecond(UnixDateDelta, $01020304);
  Assert.AreEqual(DT, ObjectId.CreationTime);

  Assert.AreEqual('0102030405060708090a0b0c', ObjectId.ToString);
  Assert.AreEqual(Bytes, ObjectId.ToByteArray);
end;

procedure TTestObjectId.TestIntegerConstructorWithInvalidIncrement;
var
  ObjectId: TgoObjectId;
begin
  ObjectId := TgoObjectId.Create(0, 0, 0, $00FFFFFF);
  Assert.AreEqual($00FFFFFF, ObjectId.Increment);

  Assert.WillRaise(
    procedure
    begin
      ObjectId := TgoObjectId.Create(0, 0, 0, $01000000);
    end, EArgumentOutOfRangeException);
end;

procedure TTestObjectId.TestIntegerConstructorWithInvalidMachine;
var
  ObjectId: TgoObjectId;
begin
  ObjectId := TgoObjectId.Create(0, $00FFFFFF, 0, 0);
  Assert.AreEqual($00FFFFFF, ObjectId.Machine);

  Assert.WillRaise(
    procedure
    begin
      ObjectId := TgoObjectId.Create(0, $01000000, 0, 0);
    end, EArgumentOutOfRangeException);
end;

procedure TTestObjectId.TestOperators;
var
  ObjectId1, ObjectId2: TgoObjectId;
begin
  ObjectId1 := TgoObjectId.GenerateNewId;
  if (ObjectId1.Increment = $FFFFFF) then
    ObjectId1 := TgoObjectId.GenerateNewId;
  ObjectId2 := TgoObjectId.GenerateNewId;

  Assert.IsTrue(ObjectId1 = ObjectId1);
  Assert.IsTrue(ObjectId1 <= ObjectId1);
  Assert.IsTrue(ObjectId1 >= ObjectId1);
  Assert.IsFalse(ObjectId1 <> ObjectId1);
  Assert.IsFalse(ObjectId1 < ObjectId1);
  Assert.IsFalse(ObjectId1 > ObjectId1);

  Assert.IsFalse(ObjectId1 = ObjectId2);
  Assert.IsTrue(ObjectId1 <= ObjectId2);
  Assert.IsFalse(ObjectId1 >= ObjectId2);
  Assert.IsTrue(ObjectId1 <> ObjectId2);
  Assert.IsTrue(ObjectId1 < ObjectId2);
  Assert.IsFalse(ObjectId1 > ObjectId2);
end;

procedure TTestObjectId.TestParse;
var
  ObjectId1, ObjectId2: TgoObjectId;
begin
  ObjectId1 := TgoObjectId.Parse('0102030405060708090a0b0c');
  ObjectId2 := TgoObjectId.Parse('0102030405060708090A0B0C');
  Assert.IsTrue(ObjectId1 = ObjectId2);
  Assert.AreEqual(ObjectId1.ToByteArray, ObjectId2.ToByteArray);
  Assert.AreEqual('0102030405060708090a0b0c', ObjectId1.ToString);
  Assert.AreEqual('0102030405060708090a0b0c', ObjectId2.ToString);

  Assert.WillRaise(
    procedure
    begin
      ObjectId1 := TgoObjectId.Parse('102030405060708090a0b0c');
    end, EArgumentException);

  Assert.WillRaise(
    procedure
    begin
      ObjectId1 := TgoObjectId.Parse('x102030405060708090a0b0c');
    end, EArgumentException);

  Assert.WillRaise(
    procedure
    begin
      ObjectId1 := TgoObjectId.Parse('00102030405060708090a0b0c');
    end, EArgumentException);
end;

procedure TTestObjectId.TestStringConstructor;
var
  Bytes: TBytes;
  ObjectId: TgoObjectId;
  DT: TDateTime;
begin
  Bytes := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
  ObjectId := TgoObjectId.Create('0102030405060708090a0b0c');
  Assert.AreEqual($01020304, ObjectId.Timestamp);
  Assert.AreEqual($050607, ObjectId.Machine);
  Assert.AreEqual($0809, Integer(ObjectId.Pid));
  Assert.AreEqual($0A0B0C, ObjectId.Increment);

  DT := IncSecond(UnixDateDelta, $01020304);
  Assert.AreEqual(DT, ObjectId.CreationTime);

  Assert.AreEqual('0102030405060708090a0b0c', ObjectId.ToString);
  Assert.AreEqual(Bytes, ObjectId.ToByteArray);
end;

procedure TTestObjectId.TestTryParse;
var
  ObjectId1, ObjectId2: TgoObjectId;
begin
  Assert.IsTrue(TgoObjectId.TryParse('0102030405060708090a0b0c', ObjectId1));
  Assert.IsTrue(TgoObjectId.TryParse('0102030405060708090A0B0C', ObjectId2));
  Assert.IsTrue(ObjectId1 = ObjectId2);
  Assert.AreEqual(ObjectId1.ToByteArray, ObjectId2.ToByteArray);
  Assert.AreEqual('0102030405060708090a0b0c', ObjectId1.ToString);
  Assert.AreEqual('0102030405060708090a0b0c', ObjectId2.ToString);

  Assert.IsFalse(TgoObjectId.TryParse('102030405060708090a0b0c', ObjectId1));
  Assert.IsFalse(TgoObjectId.TryParse('x102030405060708090a0b0c', ObjectId1));
  Assert.IsFalse(TgoObjectId.TryParse('00102030405060708090a0b0c', ObjectId1));
  Assert.IsFalse(TgoObjectId.TryParse('', ObjectId1));
end;

{ TTestBsonValue }

procedure TTestBsonValue.ImplicitConversionFromBoolShouldReturnPrecreatedInstance;
var
  B: Boolean;
  V1, V2: TgoBsonValue;
begin
  for B := False to True do
  begin
    V1 := B;
    V2 := B;
    Assert.IsTrue(ReferenceEquals(V1, V2));
  end;
end;

procedure TTestBsonValue.ImplicitConversionFromDoubleShouldReturnNewInstance;
const
  VALUES: array [0..1] of Double = (-101, 101);
var
  I: Integer;
  V1, V2: TgoBsonValue;
begin
  for I := 0 to Length(VALUES) - 1 do
  begin
    V1 := VALUES[I];
    V2 := VALUES[I];
    Assert.IsFalse(ReferenceEquals(V1, V2));
  end;
end;

procedure TTestBsonValue.ImplicitConversionFromDoubleShouldReturnPrecreatedInstance;
var
  D: Double;
  V1, V2: TgoBsonValue;
begin
  D := 0;
  V1 := D;
  V2 := D;
  Assert.IsTrue(ReferenceEquals(V1, V2));
end;

procedure TTestBsonValue.ImplicitConversionFromInt64ShouldReturnNewInstance;
const
  VALUES: array [0..1] of Int64 = (-101, 101);
var
  I: Integer;
  V1, V2: TgoBsonValue;
begin
  for I := 0 to Length(VALUES) - 1 do
  begin
    V1 := VALUES[I];
    V2 := VALUES[I];
    Assert.IsFalse(ReferenceEquals(V1, V2));
  end;
end;

procedure TTestBsonValue.ImplicitConversionFromInt64ShouldReturnPrecreatedInstance;
var
  I: Int64;
  V1, V2: TgoBsonValue;
begin
  for I := -100 to 100 do
  begin
    V1 := I;
    V2 := I;
    Assert.IsTrue(ReferenceEquals(V1, V2));
  end;
end;

procedure TTestBsonValue.ImplicitConversionFromIntegerShouldReturnNewInstance;
const
  VALUES: array [0..1] of Integer = (-101, 101);
var
  I: Integer;
  V1, V2: TgoBsonValue;
begin
  for I := 0 to Length(VALUES) - 1 do
  begin
    V1 := VALUES[I];
    V2 := VALUES[I];
    Assert.IsFalse(ReferenceEquals(V1, V2));
  end;
end;

procedure TTestBsonValue.ImplicitConversionFromIntegerShouldReturnPrecreatedInstance;
var
  I: Integer;
  V1, V2: TgoBsonValue;
begin
  for I := -100 to 100 do
  begin
    V1 := I;
    V2 := I;
    Assert.IsTrue(ReferenceEquals(V1, V2));
  end;
end;

procedure TTestBsonValue.ImplicitConversionFromStringShouldReturnNewInstance;
var
  V1, V2: TgoBsonValue;
begin
  V1 := 'x';
  V2 := 'x';
  Assert.IsFalse(ReferenceEquals(V1, V2));
end;

procedure TTestBsonValue.ImplicitConversionFromStringShouldReturnPrecreatedInstance;
var
  V1, V2: TgoBsonValue;
begin
  V1 := '';
  V2 := '';
  Assert.IsTrue(ReferenceEquals(V1, V2));
end;

procedure TTestBsonValue.TestAsArray;
var
  V, S: TgoBsonValue;
  A: TArray<TgoBsonValue>;
begin
  V := TgoBsonArray.Create([1, 2]);
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.&Array), Ord(V.BsonType));

  A := V.AsArray;
  Assert.AreEqual(2, Length(A));
  Assert.AreEqual(1, A[0].AsInteger);
  Assert.AreEqual(2, A[1].AsInteger);

  Assert.WillRaise(
    procedure
    begin
      S.AsArray;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonBinaryData;
var
  V, S: TgoBsonValue;
  B: TgoBsonBinaryData;
begin
  V := TBytes.Create(1, 2);
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Binary), Ord(V.BsonType));

  B := V.AsBsonBinaryData;
  Assert.AreEqual(Ord(TgoBsonBinarySubType.Binary), Ord(B.SubType));
  Assert.AreEqual(2, B.Count);
  Assert.AreEqual(1, Integer(B[0]));
  Assert.AreEqual(2, Integer(B[1]));

  Assert.AreEqual(2, Length(B.AsBytes));
  Assert.AreEqual(1, Integer(B.AsBytes[0]));
  Assert.AreEqual(2, Integer(B.AsBytes[1]));

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonBinaryData;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBoolean;
var
  V, S: TgoBsonValue;
begin
  V := True;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Boolean), Ord(V.BsonType));

  Assert.IsTrue(V.AsBoolean);
  Assert.WillRaise(
    procedure
    begin
      S.AsBoolean;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonArray;
var
  V, S: TgoBsonValue;
  A: TgoBsonArray;
begin
  V := TgoBsonArray.Create([1, 2]);
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.&Array), Ord(V.BsonType));

  A := V.AsBsonArray;
  Assert.AreEqual(2, A.Count);
  Assert.AreEqual(1, A[0].AsInteger);
  Assert.AreEqual(2, A[1].AsInteger);

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonArray;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonDocument;
var
  V, S: TgoBsonValue;
  D: TgoBsonDocument;
begin
  V := TgoBsonDocument.Create('x', 1);
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(V.BsonType));

  D := V.AsBsonDocument;
  Assert.AreEqual(1, D.Count);
  Assert.AreEqual('x', D.Elements[0].Name);
  Assert.AreEqual(1, D.Values[0].AsInteger);

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonArray;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonJavaScript;
var
  V, S: TgoBsonValue;
  JS: TgoBsonJavaScript;
begin
  V := TgoBsonJavaScript.Create('code');
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.JavaScript), Ord(V.BsonType));

  JS := V.AsBsonJavaScript;
  Assert.AreEqual('code', JS.Code);

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonJavaScript;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonJavaScriptWithScope;
var
  Scope: TgoBsonDocument;
  V, S: TgoBsonValue;
  JS: TgoBsonJavaScript;
  JSS: TgoBsonJavaScriptWithScope;
begin
  Scope := TgoBsonDocument.Create('x', 1);
  V := TgoBsonJavaScriptWithScope.Create('code', Scope);
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.JavaScriptWithScope), Ord(V.BsonType));
  JS := V.AsBsonJavaScript;
  JSS := V.AsBsonJavaScriptWithScope;

  Assert.IsTrue(ReferenceEquals(JS, JSS));

  Assert.AreEqual('code', JSS.Code);
  Assert.AreEqual(1, JSS.Scope.Count);
  Assert.AreEqual('x', JSS.Scope.Elements[0].Name);
  Assert.AreEqual(1, JSS.Scope['x'].AsInteger);

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonJavaScriptWithScope;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonMaxKey;
var
  V, S: TgoBsonValue;
  M: TgoBsonMaxKey;
begin
  V := TgoBsonMaxKey.Value;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.MaxKey), Ord(V.BsonType));

  M := V.AsBsonMaxKey;
  Assert.IsTrue(ReferenceEquals(TgoBsonMaxKey.Value, M));

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonMaxKey;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonMinKey;
var
  V, S: TgoBsonValue;
  M: TgoBsonMinKey;
begin
  V := TgoBsonMinKey.Value;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.MinKey), Ord(V.BsonType));

  M := V.AsBsonMinKey;
  Assert.IsTrue(ReferenceEquals(TgoBsonMinKey.Value, M));

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonMinKey;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonNull;
var
  V, S: TgoBsonValue;
  N: TgoBsonNull;
begin
  V := TgoBsonNull.Value;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Null), Ord(V.BsonType));

  N := V.AsBsonNull;
  Assert.IsTrue(ReferenceEquals(TgoBsonNull.Value, N));

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonNull;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonRegularExpression;
var
  V, S: TgoBsonValue;
  R: TgoBsonRegularExpression;
begin
  V := TgoBsonRegularExpression.Create('pattern', 'options');
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.RegularExpression), Ord(V.BsonType));

  R := V.AsBsonRegularExpression;
  Assert.AreEqual('pattern', R.Pattern);
  Assert.AreEqual('options', R.Options);

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonRegularExpression;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonSymbol;
var
  V, S: TgoBsonValue;
  Sym: TgoBsonSymbol;
begin
  V := TgoBsonSymbolTable.Lookup('name');
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Symbol), Ord(V.BsonType));

  Sym := V.AsBsonSymbol;
  Assert.AreEqual('name', Sym.Name);

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonSymbol;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsBsonTimestamp;
var
  V, S: TgoBsonValue;
  TS: TgoBsonTimestamp;
begin
  V := TgoBsonTimestamp.Create(1234);
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Timestamp), Ord(V.BsonType));

  TS := V.AsBsonTimestamp;
  Assert.AreEqual(1234, Integer(TS.Value));

  Assert.WillRaise(
    procedure
    begin
      S.AsBsonTimestamp;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsByteArray;
var
  V, S: TgoBsonValue;
  B: TBytes;
begin
  V := TBytes.Create(1, 2);
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Binary), Ord(V.BsonType));

  B := V.AsByteArray;
  Assert.AreEqual(2, Length(B));
  Assert.AreEqual(1, Integer(B[0]));
  Assert.AreEqual(2, Integer(B[1]));

  Assert.WillRaise(
    procedure
    begin
      S.AsByteArray;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsDateTime;
var
  UtcNow, DT: TDateTime;
  V, S: TgoBsonValue;
begin
  UtcNow := TTimeZone.Local.ToUniversalTime(Now);
  V := UtcNow;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.DateTime), Ord(V.BsonType));

  DT := V.ToUniversalTime;
  Assert.AreEqual(UtcNow, DT);
  Assert.AreEqual<Double>(0, S.ToUniversalTime);
end;

procedure TTestBsonValue.TestAsDouble;
var
  V, S: TgoBsonValue;
begin
  V := 1.5;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Double), Ord(V.BsonType));

  Assert.AreEqual<Double>(1.5, V.AsDouble);

  Assert.WillRaise(
    procedure
    begin
      S.AsDouble;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsGuid;
var
  Guid: TGUID;
  V, S: TgoBsonValue;
begin
  CreateGUID(Guid);
  V := Guid;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Binary), Ord(V.BsonType));
  Assert.AreEqual(Ord(TgoBsonBinarySubType.UuidStandard), Ord(V.AsBsonBinaryData.SubType));

  Assert.IsTrue(V.AsGuid = Guid);

  Assert.WillRaise(
    procedure
    begin
      S.AsGuid;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsInt64;
var
  V, S: TgoBsonValue;
begin
  V := $100000001;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Int64), Ord(V.BsonType));

  Assert.AreEqual($100000001, V.AsInt64);

  Assert.WillRaise(
    procedure
    begin
      S.AsInt64;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsInteger;
var
  V, S: TgoBsonValue;
begin
  V := 1;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(V.BsonType));

  Assert.AreEqual(1, V.AsInteger);

  Assert.WillRaise(
    procedure
    begin
      S.AsInteger;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsObjectId;
var
  ObjectId: TgoObjectId;
  V, S: TgoBsonValue;
begin
  ObjectId := TgoObjectId.GenerateNewId;
  V := ObjectId;
  S := '';

  Assert.AreEqual(Ord(TgoBsonType.ObjectId), Ord(V.BsonType));

  Assert.IsTrue(V.AsObjectId = ObjectId);

  Assert.WillRaise(
    procedure
    begin
      S.AsObjectId;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestAsString;
var
  V, I: TgoBsonValue;
begin
  V := 'Hello';
  I := 1;

  Assert.AreEqual(Ord(TgoBsonType.String), Ord(V.BsonType));

  Assert.AreEqual('Hello', V.AsString);

  Assert.WillRaise(
    procedure
    begin
      I.AsString;
    end, EIntfCastError);
end;

procedure TTestBsonValue.TestBsonValueEqualsDouble;
var
  A: TgoBsonValue;
begin
  A := 1;
  Assert.IsTrue(A = 1.0);
  Assert.IsFalse(A <> 1.0);
  Assert.IsFalse(A = 2.0);
  Assert.IsTrue(A <> 2.0);
end;

procedure TTestBsonValue.TestBsonValueEqualsFalse;
var
  A: TgoBsonValue;
begin
  A := False;
  Assert.IsTrue(A = False);
  Assert.IsFalse(A <> False);
  Assert.IsFalse(A = True);
  Assert.IsTrue(A <> True);
end;

procedure TTestBsonValue.TestBsonValueEqualsInt32;
var
  A: TgoBsonValue;
begin
  A := 1.0;
  Assert.IsTrue(A = 1);
  Assert.IsFalse(A <> 1);
  Assert.IsFalse(A = 2);
  Assert.IsTrue(A <> 2);
end;

procedure TTestBsonValue.TestBsonValueEqualsInt64;
var
  A: TgoBsonValue;
begin
  A := 1.0;
  Assert.IsTrue(A = Int64(1));
  Assert.IsFalse(A <> Int64(1));
  Assert.IsFalse(A = Int64(2));
  Assert.IsTrue(A <> Int64(2));
end;

procedure TTestBsonValue.TestBsonValueEqualsTrue;
var
  A: TgoBsonValue;
begin
  A := True;
  Assert.IsTrue(A = True);
  Assert.IsFalse(A <> True);
  Assert.IsFalse(A = False);
  Assert.IsTrue(A <> False);
end;

procedure TTestBsonValue.TestImplicitConversionFromBoolean;
var
  V: TgoBsonValue;
  B: Boolean;
begin
  V := True;
  Assert.AreEqual(Ord(TgoBsonType.Boolean), Ord(V.BsonType));
  B := V;
  Assert.AreEqual<Boolean>(V, B);
end;

procedure TTestBsonValue.TestImplicitConversionFromByteArray;
var
  V: TgoBsonValue;
  A: TBytes;
begin
  V := TBytes.Create(1, 2);
  Assert.AreEqual(Ord(TgoBsonType.Binary), Ord(V.BsonType));
  Assert.AreEqual(Ord(TgoBsonBinarySubType.Binary), Ord(V.AsBsonBinaryData.SubType));
  A := V;
  Assert.AreEqual(2, Length(A));
  Assert.AreEqual(1, Integer(A[0]));
  Assert.AreEqual(2, Integer(A[1]));
end;

procedure TTestBsonValue.TestImplicitConversionFromDateTime;
var
  V: TgoBsonValue;
  UtcNow, DT: TDateTime;
begin
  UtcNow := TTimeZone.Local.ToUniversalTime(Now);
  V := UtcNow;
  Assert.AreEqual(Ord(TgoBsonType.DateTime), Ord(V.BsonType));
  DT := V;
  Assert.AreEqual(UtcNow, DT);
end;

procedure TTestBsonValue.TestImplicitConversionFromDouble;
var
  V: TgoBsonValue;
  D: Double;
begin
  V := 1.5;
  Assert.AreEqual(Ord(TgoBsonType.Double), Ord(V.BsonType));
  D := V;
  Assert.AreEqual<Double>(1.5, D);
end;

procedure TTestBsonValue.TestImplicitConversionFromGuid;
var
  V: TgoBsonValue;
  G1, G2: TGUID;
begin
  CreateGUID(G1);
  V := G1;
  Assert.AreEqual(Ord(TgoBsonType.Binary), Ord(V.BsonType));
  Assert.AreEqual(Ord(TgoBsonBinarySubType.UuidStandard), Ord(V.AsBsonBinaryData.SubType));
  G2 := V;
  Assert.IsTrue(G1 = G2);
end;

procedure TTestBsonValue.TestImplicitConversionFromInt16;
var
  V: TgoBsonValue;
  I: Int16;
begin
  I := -1000;
  V := I;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(V.BsonType));
  I := V;
  Assert.AreEqual(-1000, I);
end;

procedure TTestBsonValue.TestImplicitConversionFromInt32;
var
  V: TgoBsonValue;
  I: Integer;
begin
  V := 42;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(V.BsonType));
  I := V;
  Assert.AreEqual(42, I);
end;

procedure TTestBsonValue.TestImplicitConversionFromInt64;
var
  V: TgoBsonValue;
  I: Int64;
begin
  V := $123456789;
  Assert.AreEqual(Ord(TgoBsonType.Int64), Ord(V.BsonType));
  I := V;
  Assert.AreEqual($123456789, I);
end;

procedure TTestBsonValue.TestImplicitConversionFromInt8;
var
  V: TgoBsonValue;
  I: Int8;
begin
  I := -100;
  V := I;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(V.BsonType));
  I := V;
  Assert.AreEqual(-100, I);
end;

procedure TTestBsonValue.TestImplicitConversionFromSingle;
var
  V: TgoBsonValue;
  S: Single;
begin
  S := 1.5;
  V := S;
  Assert.AreEqual(Ord(TgoBsonType.Double), Ord(V.BsonType));
  S := V;
  Assert.AreEqual<Double>(1.5, S);
end;

procedure TTestBsonValue.TestImplicitConversionFromUInt16;
var
  V: TgoBsonValue;
  I: UInt16;
begin
  I := 40000;
  V := I;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(V.BsonType));
  I := V;
  Assert.AreEqual(40000, I);
end;

procedure TTestBsonValue.TestImplicitConversionFromUInt32;
var
  V: TgoBsonValue;
  I: UInt32;
begin
  I := $98765432;
  V := I;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(V.BsonType));
  I := V;
  Assert.AreEqual($98765432, I);
end;

procedure TTestBsonValue.TestImplicitConversionFromUInt64;
var
  V: TgoBsonValue;
  U: UInt64;
begin
  U := $9876543298765432;
  V := U;
  Assert.AreEqual(Ord(TgoBsonType.Int64), Ord(V.BsonType));
  U := V;
  Assert.AreEqual($9876543298765432, U);
end;

procedure TTestBsonValue.TestImplicitConversionFromUInt8;
var
  V: TgoBsonValue;
  I: UInt8;
begin
  I := 200;
  V := I;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(V.BsonType));
  I := V;
  Assert.AreEqual(200, I);
end;

procedure TTestBsonValue.TestImplicitConversionObjectId;
var
  V: TgoBsonValue;
  O1, O2: TgoObjectId;
begin
  O1 := TgoObjectId.GenerateNewId;
  V := O1;
  Assert.AreEqual(Ord(TgoBsonType.ObjectId), Ord(V.BsonType));
  O2 := V;
  Assert.IsTrue(O1 = O2);
end;

procedure TTestBsonValue.TestImplicitConversionString;
var
  V: TgoBsonValue;
  S: String;
begin
  V := 'Foo';
  Assert.AreEqual(Ord(TgoBsonType.String), Ord(V.BsonType));
  S := V;
  Assert.AreEqual('Foo', S);
end;

{ TTestBsonArray }

procedure TTestBsonArray.TestAdd;
var
  A: TgoBsonArray;
begin
  A := TgoBsonArray.Create;
  A.Add(42);
  Assert.AreEqual(1, A.Count);
  Assert.AreEqual<Integer>(42, A[0]);
end;

procedure TTestBsonArray.TestAddNil;
var
  A: TgoBsonArray;
  V: TgoBsonValue;
begin
  A := TgoBsonArray.Create;

  Assert.WillRaise(
    procedure
    begin
      A.Add(V);
    end, EArgumentNilException);
end;

procedure TTestBsonArray.TestClear;
var
  A: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1, 2]);
  Assert.AreEqual(2, A.Count);
  A.Clear;
  Assert.AreEqual(0, A.Count);
end;

procedure TTestBsonArray.TestClone;
var
  A, C: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1, 2, TgoBsonArray.Create([3, 4])]);
  C := A.Clone;
  Assert.IsFalse(ReferenceEquals(A, C));
  Assert.AreEqual(3, C.Count);
  Assert.AreEqual<Integer>(1, C[0]);
  Assert.AreEqual<Integer>(2, C[1]);
  Assert.IsTrue(ReferenceEquals(A[2], C[2])); // Shallow clone
  Assert.AreEqual<Integer>(3, C[2].AsArray[0]);
  Assert.AreEqual<Integer>(4, C[2].AsArray[1]);
end;

procedure TTestBsonArray.TestContains;
var
  A: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1, 2]);
  Assert.IsTrue(A.Contains(1));
  Assert.IsTrue(A.Contains(2));
  Assert.IsFalse(A.Contains(3));
end;

procedure TTestBsonArray.TestContainsNil;
var
  A: TgoBsonArray;
  V: TgoBsonValue;
begin
  A := TgoBsonArray.Create([1, 2]);
  Assert.IsFalse(A.Contains(V));
end;

procedure TTestBsonArray.TestDeepClone;
var
  A, C: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1, 2, TgoBsonArray.Create([3, 4])]);
  C := A.DeepClone;
  Assert.IsFalse(ReferenceEquals(A, C));
  Assert.AreEqual(3, C.Count);
  Assert.AreEqual<Integer>(1, C[0]);
  Assert.AreEqual<Integer>(2, C[1]);
  Assert.IsFalse(ReferenceEquals(A[2], C[2])); // Deep clone
  Assert.AreEqual<Integer>(3, C[2].AsArray[0]);
  Assert.AreEqual<Integer>(4, C[2].AsArray[1]);
end;

procedure TTestBsonArray.TestDelete;
var
  A: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1, 2, 3]);
  Assert.AreEqual(3, A.Count);
  A.Delete(1);
  Assert.AreEqual(2, A.Count);
  Assert.AreEqual<Integer>(1, A[0]);
  Assert.AreEqual<Integer>(3, A[1]);
end;

procedure TTestBsonArray.TestEquals;
var
  A, B, C, D: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1, 2]);
  B := TgoBsonArray.Create([1, 2]);
  C := TgoBsonArray.Create([3, 4]);
  Assert.IsTrue(A = A);
  Assert.IsTrue(A = B);
  Assert.IsFalse(A = C);
  Assert.IsFalse(A = D);
  Assert.IsFalse(D = A);
  Assert.IsTrue(D = D);
  Assert.IsFalse(TgoBsonValue(A) = 1);
end;

procedure TTestBsonArray.TestIndexer;
var
  A: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1]);
  Assert.AreEqual<Integer>(1, A[0]);
  A[0] := 2;
  Assert.AreEqual<Integer>(2, A[0]);
  A[0] := 'Foo';
  Assert.AreEqual<String>('Foo', A[0]);
end;

procedure TTestBsonArray.TestIndexerSetNil;
var
  A: TgoBsonArray;
  B: TgoBsonValue;
begin
  A := TgoBsonArray.Create([1]);
  Assert.AreEqual<Integer>(1, A[0]);
  Assert.WillRaise(
    procedure
    begin
      A[0] := B;
    end, EArgumentNilException);
end;

procedure TTestBsonArray.TestIndexOf;
var
  A: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1, 2]);
  Assert.AreEqual(0, A.IndexOf(1));
  Assert.AreEqual(1, A.IndexOf(2));
  Assert.AreEqual(-1, A.IndexOf(3));
end;

procedure TTestBsonArray.TestNotEquals;
var
  A, B, C, D: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1, 2]);
  B := TgoBsonArray.Create([1, 2]);
  C := TgoBsonArray.Create([3, 4]);
  Assert.IsFalse(A <> A);
  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> C);
  Assert.IsTrue(A <> D);
  Assert.IsTrue(D <> A);
  Assert.IsFalse(D <> D);
  Assert.IsTrue(TgoBsonValue(A) <> 1);
end;

procedure TTestBsonArray.TestToArray;
var
  A: TgoBsonArray;
  V: TArray<TgoBsonValue>;
begin
  A := TgoBsonArray.Create([1, 2, 3]);
  V := A.ToArray;
  Assert.AreEqual(3, Length(V));
  Assert.AreEqual<Integer>(1, V[0]);
  Assert.AreEqual<Integer>(2, V[1]);
  Assert.AreEqual<Integer>(3, V[2]);
end;

{ TTestBsonDocument }

procedure TTestBsonDocument.TestAddArrayWithOneEntry;
var
  A: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1]);
  Assert.AreEqual('[1]', A.ToJson);
end;

procedure TTestBsonDocument.TestAddArrayWithTwoEntries;
var
  A: TgoBsonArray;
begin
  A := TgoBsonArray.Create([1, 2]);
  Assert.AreEqual('[1, 2]', A.ToJson);
end;

procedure TTestBsonDocument.TestAddDocumentWithNestedDocument;
var
  D, Nested: TgoBsonDocument;
begin
  Nested := TgoBsonDocument.Create;
  Nested.Add('C', 2);
  Nested.Add('D', 3);

  D := TgoBsonDocument.Create;
  D.Add('A', 1);
  D.Add('B', Nested);
  Assert.AreEqual('{ "A" : 1, "B" : { "C" : 2, "D" : 3 } }', D.ToJson);
end;

procedure TTestBsonDocument.TestAddDocumentWithOneEntry;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create('A', 1);
  Assert.AreEqual('{ "A" : 1 }', D.ToJson);
end;

procedure TTestBsonDocument.TestAddDocumentWithTwoEntries;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create;
  D.Add('A', 1);
  D.Add('B', 2);
  Assert.AreEqual('{ "A" : 1, "B" : 2 }', D.ToJson);
end;

procedure TTestBsonDocument.TestAutoIndexing;
var
  D: TgoBsonDocument;
  A: TgoBsonArray;
  V: TgoBsonValue;
begin
  A := TgoBsonArray.Create;

  D := TgoBsonDocument.Create;
  D.Add('StreetAddress', '123 Main St');
  D.Add('City', 'Hope');
  A.Add(D);

  D := TgoBsonDocument.Create;
  D.Add('StreetAddress', '456 Main St');
  D.Add('City', 'Despair');
  A.Add(D);

  D := TgoBsonDocument.Create('Addresses', A);
  V := D['Addresses'].AsBsonArray[0].AsBsonDocument['StreetAddress'];
  Assert.AreEqual('123 Main St', V.AsString);
end;

procedure TTestBsonDocument.TestClear;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create('X', 1);
  Assert.AreEqual(1, D.Count);
  D.Clear;
  Assert.AreEqual(0, D.Count);
end;

procedure TTestBsonDocument.TestClone;
var
  Doc, SubDoc, Clone: TgoBsonDocument;
begin
  SubDoc := TgoBsonDocument.Create('x', 1);
  Doc := TgoBsonDocument.Create('d', SubDoc);
  Clone := Doc.Clone;
  Assert.AreEqual<Integer>(1, Clone['d'].AsBsonDocument['x']);
  Assert.IsTrue(ReferenceEquals(Clone['d'], SubDoc)); // Shallow copy
end;

procedure TTestBsonDocument.TestConstructorAllowDuplicateNames;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create(True);
  Assert.IsTrue(D.AllowDuplicateNames);
  D.AllowDuplicateNames := False;
  Assert.IsFalse(D.AllowDuplicateNames);
end;

procedure TTestBsonDocument.TestConstructorElement;
var
  E: TgoBsonElement;
  D: TgoBsonDocument;
begin
  E := TgoBsonElement.Create('x', 1);
  D := TgoBsonDocument.Create(E);
  Assert.AreEqual(1, D.Count);
  Assert.AreEqual(1, D['x'].AsInteger);
  Assert.IsTrue(D.Contains('x'));
  Assert.IsTrue(D.ContainsValue(1));
  Assert.IsTrue(ReferenceEquals(E.Value, D['x']));
end;

procedure TTestBsonDocument.TestConstructorNameValue;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create('x', 1);
  Assert.AreEqual(1, D.Count);
  Assert.AreEqual(1, D['x'].AsInteger);
  Assert.IsTrue(D.Contains('x'));
  Assert.IsTrue(D.ContainsValue(1));
end;

procedure TTestBsonDocument.TestConstructorNoArgs;
var
  D: TgoBsonDocument;
  V: TgoBsonValue;
begin
  D := TgoBsonDocument.Create;
  V := D;
  Assert.IsFalse(D.AllowDuplicateNames);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(V.BsonType));
  Assert.IsFalse(D.Contains('name'));
  Assert.IsFalse(D.ContainsValue(0));
  Assert.AreEqual(0, D.Count);
  Assert.IsFalse(V.IsBsonArray);
  Assert.IsTrue(V.IsBsonDocument);
  Assert.AreEqual('{ }', D.ToJson);
end;

procedure TTestBsonDocument.TestContains;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create;
  Assert.IsFalse(D.Contains('x'));
  D['x'] := 1;
  Assert.IsTrue(D.Contains('x'));
end;

procedure TTestBsonDocument.TestContainsValue;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create;
  Assert.IsFalse(D.ContainsValue(1));
  D['x'] := 1;
  Assert.IsTrue(D.ContainsValue(1));
end;

procedure TTestBsonDocument.TestDeepClone;
var
  Doc, SubDoc, Clone: TgoBsonDocument;
begin
  SubDoc := TgoBsonDocument.Create('x', 1);
  Doc := TgoBsonDocument.Create('d', SubDoc);
  Clone := Doc.DeepClone;
  Assert.AreEqual<Integer>(1, Clone['d'].AsBsonDocument['x']);
  Assert.IsFalse(ReferenceEquals(Clone['d'], SubDoc)); // Deep copy
end;

procedure TTestBsonDocument.TestDelete;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create;
  D.Add('x', 1);
  D.Add('y', 2);
  Assert.AreEqual(2, D.Count);
  D.Delete(0);
  Assert.AreEqual(1, D.Count);
  Assert.AreEqual<Integer>(2, D['y']);
end;

procedure TTestBsonDocument.TestElementAccess;
var
  Book: TgoBsonDocument;
begin
  Book := TgoBsonDocument.Create;
  Book.Add('author', 'Ernest Hemingway');
  Book.Add('title', 'For Whom the Bell Tolls');
  Book.Add('pages', 123);
  Book.Add('price', 9.95);
  Book.Add('ok', TgoBsonNull.Value);

  Assert.AreEqual<String>('Ernest Hemingway', Book['author']);
  Assert.AreEqual<Integer>(123, Book['pages']);
  Assert.AreEqual(9.95, Book['price'], 0.001);
  Assert.AreEqual<Boolean>(False, Book['ok']);

  Book['err'] := '';
  Assert.AreEqual<Boolean>(False, Book['err']);
  Book['err'] := 'Error message';
  Assert.AreEqual<Boolean>(True, Book['err']);

  Book['price'] := Book['price'].AsDouble * 1.1;
  Assert.AreEqual(10.945, Book['price'], 0.001);
end;

procedure TTestBsonDocument.TestElementGetValueByIndex;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create('x', 1);
  Assert.AreEqual<Integer>(1, D.Values[0]);
end;

procedure TTestBsonDocument.TestElementGetValueByName;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create('x', 1);
  Assert.AreEqual<Integer>(1, D['x']);
end;

procedure TTestBsonDocument.TestElementNameZeroLength;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create('', 'zero length');
  Assert.AreEqual(0, D.Elements[0].Name.Length);
end;

procedure TTestBsonDocument.TestIndexer;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create;
  Assert.AreEqual(0, D.Count);

  D['x'] := 1;
  Assert.AreEqual(1, D.Count);
  Assert.AreEqual<Integer>(1, D['x']);
  Assert.AreEqual<Integer>(1, D.Values[0]);

  D['y'] := 2;
  Assert.AreEqual(2, D.Count);
  Assert.AreEqual<Integer>(2, D['y']);
  Assert.AreEqual<Integer>(2, D.Values[1]);

  D['y'] := 3;
  Assert.AreEqual(2, D.Count);
  Assert.AreEqual<Integer>(3, D['y']);
  Assert.AreEqual<Integer>(3, D.Values[1]);

  D.Values[1] := 4;
  Assert.AreEqual(2, D.Count);
  Assert.AreEqual<Integer>(4, D['y']);
  Assert.AreEqual<Integer>(4, D.Values[1]);
end;

procedure TTestBsonDocument.TestIndexOfName;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create;
  D.Add('_id', 1);
  D.Add('x', 2);
  D.Add('y', 3);

  Assert.AreEqual(0, D.IndexOfName('_id'));
  Assert.AreEqual(1, D.IndexOfName('x'));
  Assert.AreEqual(2, D.IndexOfName('y'));
  Assert.AreEqual(-1, D.IndexOfName('z'));
end;

procedure TTestBsonDocument.TestOperatorEqual;
var
  D1, D2, N1, N2: TgoBsonDocument;
begin
  D1 := TgoBsonDocument.Create('x', 1);
  D2 := TgoBsonDocument.Create('x', 1);
  Assert.IsFalse(ReferenceEquals(D1, D2));
  Assert.IsTrue(D1 = D2);

  Assert.IsTrue(N1 = N2);
  Assert.IsFalse(N1 = D1);
  Assert.IsFalse(D1 = N1);
end;

procedure TTestBsonDocument.TestOperatorNotEqual;
var
  D1, D2, N1, N2: TgoBsonDocument;
begin
  D1 := TgoBsonDocument.Create('x', 1);
  D2 := TgoBsonDocument.Create('x', 1);
  Assert.IsFalse(ReferenceEquals(D1, D2));
  Assert.IsFalse(D1 <> D2);

  Assert.IsFalse(N1 <> N2);
  Assert.IsTrue(N1 <> D1);
  Assert.IsTrue(D1 <> N1);
end;

procedure TTestBsonDocument.TestParse;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Parse('{ a : 1, b : ''abc'' }');
  Assert.AreEqual('{ "a" : 1, "b" : "abc" }', D.ToJson);
end;

procedure TTestBsonDocument.TestRemove;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create('x', 1);
  Assert.AreEqual(1, D.Count);
  D.Remove('x');
  Assert.AreEqual(0, D.Count);
end;

procedure TTestBsonDocument.TestSetByIndex;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create('x', 1);
  Assert.AreEqual(1, D.Count);
  Assert.AreEqual<Integer>(1, D['x']);
  D.Values[0] := 2;
  Assert.AreEqual(1, D.Count);
  Assert.AreEqual<Integer>(2, D['x']);
end;

procedure TTestBsonDocument.TestSetByName;
var
  D: TgoBsonDocument;
begin
  D := TgoBsonDocument.Create;
  Assert.AreEqual(0, D.Count);
  D['x'] := 1;
  Assert.AreEqual(1, D.Count);
  Assert.AreEqual<Integer>(1, D['x']);
  D['x'] := 2;
  Assert.AreEqual(1, D.Count);
  Assert.AreEqual<Integer>(2, D['x']);
end;

procedure TTestBsonDocument.TestSpecBsonAwesomeWithBsonDocument;
var
  A: TgoBsonArray;
  D: TgoBsonDocument;
  Bson: TBytes;
begin
  A := TgoBsonArray.Create(['awesome', 5.05, 1986]);
  D := TgoBsonDocument.Create('BSON', A);
  Bson := D.ToBson;
  Assert.AreEqual(DecodeByteString('1\x00\x00\x00\x04BSON\x00&\x00\x00\x00\x020\x00\x08\x00\x00\x00awesome\x00\x011\x00333333\x14@\x102\x00\xc2\x07\x00\x00\x00\x00'), Bson);
end;

procedure TTestBsonDocument.TestSpecBsonAwesomeWithBsonWriter;
var
  Writer: IgoBsonWriter;
  Bson: TBytes;
begin
  Writer := TgoBsonWriter.Create;
  Writer.WriteStartDocument;
  Writer.WriteStartArray('BSON');
  Writer.WriteString('awesome');
  Writer.WriteDouble(5.05);
  Writer.WriteInt32(1986);
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Bson := Writer.ToBson;
  Assert.AreEqual(DecodeByteString('1\x00\x00\x00\x04BSON\x00&\x00\x00\x00\x020\x00\x08\x00\x00\x00awesome\x00\x011\x00333333\x14@\x102\x00\xc2\x07\x00\x00\x00\x00'), Bson);
end;

procedure TTestBsonDocument.TestSpecHelloWorldWithBsonDocument;
var
  D: TgoBsonDocument;
  Bson: TBytes;
begin
  D := TgoBsonDocument.Create('hello', 'world');
  Bson := D.ToBson;
  Assert.AreEqual(DecodeByteString('\x16\x00\x00\x00\x02hello\x00\x06\x00\x00\x00world\x00\x00'), Bson);
end;

procedure TTestBsonDocument.TestSpecHelloWorldWithBsonWriter;
var
  Writer: IgoBsonWriter;
  Bson: TBytes;
begin
  Writer := TgoBsonWriter.Create;
  Writer.WriteStartDocument;
  Writer.WriteString('hello', 'world');
  Writer.WriteEndDocument;
  Bson := Writer.ToBson;
  Assert.AreEqual(DecodeByteString('\x16\x00\x00\x00\x02hello\x00\x06\x00\x00\x00world\x00\x00'), Bson);
end;

procedure TTestBsonDocument.TestTryGetElement;
var
  D: TgoBsonDocument;
  E: TgoBsonElement;
begin
  D := TgoBsonDocument.Create;
  Assert.IsFalse(D.TryGetElement('x', E));
  D['x'] := 1;
  Assert.IsTrue(D.TryGetElement('x', E));
  Assert.AreEqual('x', E.Name);
  Assert.AreEqual<Integer>(1, E.Value);
end;

procedure TTestBsonDocument.TestTryGetValue;
var
  D: TgoBsonDocument;
  V: TgoBsonValue;
begin
  D := TgoBsonDocument.Create;
  Assert.IsFalse(D.TryGetValue('x', V));
  D['x'] := 1;
  Assert.IsTrue(D.TryGetValue('x', V));
  Assert.AreEqual<Integer>(1, V);
end;

{ TTestBsonEquals }

procedure TTestBsonEquals.TestBsonArrayEquals;
var
  L, R: TgoBsonArray;
begin
  L := TgoBsonArray.Create([1, 2, 3]);
  R := TgoBsonArray.Create().Add(1).Add(2).Add(3);
  Assert.IsFalse(ReferenceEquals(L, R));
  Assert.IsTrue(L = R);
end;

procedure TTestBsonEquals.TestBsonBinaryDataEquals;
var
  L, R: TgoBsonBinaryData;
begin
  L := TgoBsonBinaryData.Create(TBytes.Create(1, 2, 3));
  R := TgoBsonBinaryData.Create(TBytes.Create(1, 2, 3));
  Assert.IsFalse(ReferenceEquals(L, R));
  Assert.IsTrue(L = R);
end;

procedure TTestBsonEquals.TestBsonDocumentEquals;
var
  L, R: TgoBsonDocument;
begin
  L := TgoBsonDocument.Create('Hello', 'World').Add('Foo', 'Bar');
  R := TgoBsonDocument.Create().Add('Hello', 'World').Add('Foo', 'Bar');
  Assert.IsFalse(ReferenceEquals(L, R));
  Assert.IsTrue(L = R);
end;

procedure TTestBsonEquals.TestBsonElementEquals;
var
  L, R: TgoBsonElement;
begin
  L := TgoBsonElement.Create('Hello', 'World');
  R := TgoBsonElement.Create('Hello', 'World');
  Assert.IsTrue(L = R);
end;

procedure TTestBsonEquals.TestBsonJavaScriptEquals;
var
  L, R: TgoBsonJavaScript;
begin
  L := TgoBsonJavaScript.Create('n = 1');
  R := TgoBsonJavaScript.Create('n = 1');
  Assert.IsFalse(ReferenceEquals(L, R));
  Assert.IsTrue(L = R);
end;

procedure TTestBsonEquals.TestBsonJavaScriptWithScopeEquals;
var
  L, R: TgoBsonJavaScriptWithScope;
begin
  L := TgoBsonJavaScriptWithScope.Create('n = 1', TgoBsonDocument.Create('x', '2'));
  R := TgoBsonJavaScriptWithScope.Create('n = 1', TgoBsonDocument.Create().Add('x', '2'));
  Assert.IsFalse(ReferenceEquals(L, R));
  Assert.IsTrue(L = R);
end;

procedure TTestBsonEquals.TestBsonObjectIdEquals;
var
  L, R: TgoObjectId;
begin
  L := TgoObjectId.Create([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
  R := TgoObjectId.Create('0102030405060708090a0b0c');
  Assert.IsTrue(L = R);
end;

procedure TTestBsonEquals.TestBsonSymbolEquals;
var
  L, R: TgoBsonSymbol;
begin
  L := TgOBsonSymbolTable.Lookup('name');
  R := TgOBsonSymbolTable.Lookup('name');
  Assert.IsTrue(ReferenceEquals(L, R));
  Assert.IsTrue(L = R);
end;

procedure TTestBsonEquals.TestBsonTimestampEquals;
var
  L, R: TgoBsonTimestamp;
begin
  L := TgoBsonTimestamp.Create(1);
  R := TgoBsonTimestamp.Create(1);
  Assert.IsFalse(ReferenceEquals(L, R));
  Assert.IsTrue(L = R);
end;

{ TTestBsonValueEquals }

procedure TTestBsonValueEquals.TestBsonArrayEquals;
var
  A, B, C, N: TgoBsonArray;
begin
  A := TgoBsonArray.Create(['a', 1]);
  B := TgoBsonArray.Create(['a', 1]);
  C := TgoBsonArray.Create(['b', 1]);

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = C);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> C);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonBinaryDataEquals;
var
  A, B, C, N: TgoBsonBinaryData;
begin
  A := TgoBsonBinaryData.Create(TBytes.Create(1, 2, 3));
  B := TgoBsonBinaryData.Create(TBytes.Create(1, 2, 3));
  C := TgoBsonBinaryData.Create(TBytes.Create(2, 3, 4));

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = C);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> C);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonDocumentEquals;
var
  A, B, C, N: TgoBsonDocument;
begin
  A := TgoBsonDocument.Create('a', 1);
  B := TgoBsonDocument.Create('a', 1);
  C := TgoBsonDocument.Create('b', 1);

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = C);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> C);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonJavaScriptEquals;
var
  A, B, C, N: TgoBsonJavaScript;
begin
  A := TgoBsonJavaScript.Create('script 1');
  B := TgoBsonJavaScript.Create('script 1');
  C := TgoBsonJavaScript.Create('script 2');

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = C);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> C);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonJavaScriptWithScopeEquals;
var
  A, B, C, D, N: TgoBsonJavaScriptWithScope;
begin
  A := TgoBsonJavaScriptWithScope.Create('script 1', TgoBsonDocument.Create('x', 1));
  B := TgoBsonJavaScriptWithScope.Create('script 1', TgoBsonDocument.Create('x', 1));
  C := TgoBsonJavaScriptWithScope.Create('script 2', TgoBsonDocument.Create('x', 1));
  D := TgoBsonJavaScriptWithScope.Create('script 2', TgoBsonDocument.Create('x', 2));

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = C);
  Assert.IsFalse(B = D);
  Assert.IsFalse(C = D);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> C);
  Assert.IsTrue(B <> D);
  Assert.IsTrue(C <> D);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonMaxKeyEquals;
var
  A, B, N: TgoBsonMaxKey;
begin
  A := TgoBsonMaxKey.Value;
  B := TgoBsonMaxKey.Value;

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonMinKeyEquals;
var
  A, B, N: TgoBsonMinKey;
begin
  A := TgoBsonMinKey.Value;
  B := TgoBsonMinKey.Value;

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonNullEquals;
var
  A, B, N: TgoBsonNull;
begin
  A := TgoBsonNull.Value;
  B := TgoBsonNull.Value;

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonRegularExpressionEquals;
var
  A, B, C, D, N: TgoBsonRegularExpression;
begin
  A := TgoBsonRegularExpression.Create('pattern 1', 'options 1');
  B := TgoBsonRegularExpression.Create('pattern 1', 'options 1');
  C := TgoBsonRegularExpression.Create('pattern 2', 'options 1');
  D := TgoBsonRegularExpression.Create('pattern 2', 'options 2');

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = C);
  Assert.IsFalse(B = D);
  Assert.IsFalse(C = D);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> C);
  Assert.IsTrue(B <> D);
  Assert.IsTrue(C <> D);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonSymbolEquals;
var
  A, B, C, N: TgoBsonSymbol;
begin
  A := TgOBsonSymbolTable.Lookup('symbol 1');
  B := TgOBsonSymbolTable.Lookup('symbol 1');
  C := TgOBsonSymbolTable.Lookup('symbol 2');

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = C);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> C);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonTimestampEquals;
var
  A, B, C, N: TgoBsonTimestamp;
begin
  A := TgoBsonTimestamp.Create(1);
  B := TgoBsonTimestamp.Create(1);
  C := TgoBsonTimestamp.Create(2);

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = C);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> C);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

procedure TTestBsonValueEquals.TestBsonUndefinedEquals;
var
  A, B, N: TgoBsonUndefined;
begin
  A := TgoBsonUndefined.Value;
  B := TgoBsonUndefined.Value;

  Assert.IsTrue(A = B);
  Assert.IsFalse(A = N);
  Assert.IsFalse(N = A);
  Assert.IsFalse(A.IsNil);
  Assert.IsTrue(N.IsNil);

  Assert.IsFalse(A <> B);
  Assert.IsTrue(A <> N);
  Assert.IsTrue(N <> A);
end;

{ TTestBsonDocumentAllTypes }

procedure TTestBsonDocumentAllTypes.CheckDocument(const ADoc: TgoBsonDocument);
var
  RootArray, SubArray: TgoBsonArray;
  SubDoc: TgoBsonDocument;
  ActualBytes, ExpectedBytes: TBytes;
  ActualDateTime, ExpectedDateTime: TDateTime;
begin
  Assert.IsFalse(ADoc.IsNil);

  // Root is an array with 20 values
  RootArray := ADoc['Root'].AsBsonArray;
  Assert.AreEqual(20, RootArray.Count);

  // "JSON Test Pattern pass1"
  Assert.AreEqual<String>('JSON Test Pattern pass1', RootArray[0]);

  // {"object with 1 member":["array with 1 element"]}
  SubDoc := RootArray[1].AsBsonDocument;
  Assert.AreEqual(1, SubDoc.Count);
  SubArray := SubDoc['object with 1 member'].AsBsonArray;
  Assert.AreEqual(1, SubArray.Count);
  Assert.AreEqual<String>('array with 1 element', SubArray[0]);

  // {}
  SubDoc := RootArray[2].AsBsonDocument;
  Assert.AreEqual(0, SubDoc.Count);

  // []
  SubArray := RootArray[3].AsBsonArray;
  Assert.AreEqual(0, SubArray.Count);

  // -42
  Assert.AreEqual<Integer>(-42, RootArray[4]);

  // true
  Assert.IsTrue(RootArray[5]);

  // false
  Assert.IsFalse(RootArray[6]);

  // null
  Assert.IsTrue(RootArray[7].IsBsonNull);

  // { ... object with 38 key/value pairs
  SubDoc := RootArray[8].AsBsonDocument;
  Assert.AreEqual(38, SubDoc.Count);

  begin
    // "integer": 1234567890
    Assert.AreEqual<Integer>(1234567890, SubDoc['integer']);

    // "real": -9876.543210
    Assert.IsTrue(SameValue(-9876.543210, SubDoc['real']));

    // "e": 0.123456789e-12,
    Assert.IsTrue(SameValue(0.123456789e-12, SubDoc['e']));

    // "E": 1.234567890E+34
    Assert.IsTrue(SameValue(1.234567890e34, SubDoc['E']));

    // "": 23456789012E66
    Assert.IsTrue(SameValue(23456789012e66, SubDoc['']));

    // "zero": 0
    Assert.AreEqual<Integer>(0, SubDoc['zero']);

    // "one": 1
    Assert.AreEqual<Integer>(1, SubDoc['one']);

    // "space": " "
    Assert.AreEqual<String>(' ', SubDoc['space']);

    // "quote": "\""
    Assert.AreEqual<String>('"', SubDoc['quote']);

    // "backslash": "\\"
    Assert.AreEqual<String>('\', SubDoc['backslash']);

    // "controls": "\b\f\n\r\t"
    Assert.AreEqual<String>(#8#12#10#13#9, SubDoc['controls']);

    // "slash": "/ & \/"
    Assert.AreEqual<String>('/ & /', SubDoc['slash']);

    // "alpha": "abcdefghijklmnopqrstuvwyz"
    Assert.AreEqual<String>('abcdefghijklmnopqrstuvwyz', SubDoc['alpha']);

    // "ALPHA": "ABCDEFGHIJKLMNOPQRSTUVWYZ"
    Assert.AreEqual<String>('ABCDEFGHIJKLMNOPQRSTUVWYZ', SubDoc['ALPHA']);

    // "digit": "0123456789"
    Assert.AreEqual<String>('0123456789', SubDoc['digit']);

    // "0123456789": "digit"
    Assert.AreEqual<String>('digit', SubDoc['0123456789']);

    // "special": "`1~!@#$%^&*()_+-={':[,]}|;.</>?"
    Assert.AreEqual<String>('`1~!@#$%^&*()_+-={'':[,]}|;.</>?', SubDoc['special']);

    // "hex": "\u0123\u4567\u89AB\uCDEF\uabcd\uef4A"
    Assert.AreEqual<String>(#$0123#$4567#$89AB#$CDEF#$ABCD#$EF4A, SubDoc['hex']);

    // "true": true
    Assert.IsTrue(SubDoc['true']);

    // "false": false
    Assert.IsFalse(SubDoc['false']);

    // "null": null
    Assert.IsFalse(SubDoc['null'].IsNil);
    Assert.IsTrue(SubDoc['null'].IsBsonNull);

    // "array":[  ]
    Assert.AreEqual(0, SubDoc['array'].AsBsonArray.Count);

    // "object":{  }
    Assert.AreEqual(0, SubDoc['object'].AsBsonDocument.Count);

    // "binary": "$B64:VGhlIFF1aWNrIEJyb3duIEZveCBKdW1wcyBPdmVyIFRoZSBMYXp5IERvZw=="
    ExpectedBytes := BytesOf('The Quick Brown Fox Jumps Over The Lazy Dog');
    ActualBytes := SubDoc['binary'].AsByteArray;
    Assert.AreEqual(ExpectedBytes, ActualBytes);

    // "date1": { "$date": "2014-10-18T14:24:02Z" }
    ExpectedDateTime := EncodeDateTime(2014, 10, 18, 14, 24, 2, 0);
    ActualDateTime := SubDoc['date1'].AsBsonDateTime.ToUniversalTime;
    Assert.AreEqual(ExpectedDateTime, ActualDateTime);

    // "date2": { "$date" : { "$numberLong" : "-1742117758000" } }
    ExpectedDateTime := EncodeDateTime(1914, 10, 18, 14, 24, 2, 0);
    ActualDateTime := SubDoc['date2'].AsBsonDateTime.ToUniversalTime;
    Assert.AreEqual(ExpectedDateTime, ActualDateTime);

    // "time stamp": { "$timestamp": { "t": 1000, "i": 3 } }
    Assert.AreEqual(1000, SubDoc['time stamp'].AsBsonTimestamp.Timestamp);
    Assert.AreEqual(3, SubDoc['time stamp'].AsBsonTimestamp.Increment);

    // "regular expression": {"$regex": "A-Za-z", "$options": "mi"}
    Assert.AreEqual('A-Za-z', SubDoc['regular expression'].AsBsonRegularExpression.Pattern);
    Assert.AreEqual('mi', SubDoc['regular expression'].AsBsonRegularExpression.Options);

    // "object id": { "$oid" : "5442830b093d429b7cfc1312" }
    Assert.AreEqual('5442830b093d429b7cfc1312', SubDoc['object id'].AsObjectId.ToString);

    // "address": "50 St. James Street"
    Assert.AreEqual<String>('50 St. James Street', SubDoc['address']);

    // "url": "http://www.JSON.org/"
    Assert.AreEqual<String>('http://www.JSON.org/', SubDoc['url']);

    // "comment": "// /* <!-- --"
    Assert.AreEqual<String>('// /* <!-- --', SubDoc['comment']);

    // "# -- --> */": " "
    Assert.AreEqual<String>(' ', SubDoc['# -- --> */']);

    // " s p a c e d " :[1,2 , 3
    //
    //  ,
    //
    //  4 , 5        ,          6           ,7        ,256   ]
    SubArray := SubDoc[' s p a c e d '].AsBsonArray;
    Assert.AreEqual(8, SubArray.Count);
    Assert.AreEqual<Integer>(1, SubArray[0]);
    Assert.AreEqual<Integer>(2, SubArray[1]);
    Assert.AreEqual<Integer>(3, SubArray[2]);
    Assert.AreEqual<Integer>(4, SubArray[3]);
    Assert.AreEqual<Integer>(5, SubArray[4]);
    Assert.AreEqual<Integer>(6, SubArray[5]);
    Assert.AreEqual<Integer>(7, SubArray[6]);
    Assert.AreEqual<Integer>(256, SubArray[7]);

    // "compact":[1,2,3,4,5,6,7]
    SubArray := SubDoc['compact'].AsBsonArray;
    Assert.AreEqual(8, SubArray.Count);
    Assert.AreEqual<Integer>(1, SubArray[0]);
    Assert.AreEqual<Integer>(2, SubArray[1]);
    Assert.AreEqual<Integer>(3, SubArray[2]);
    Assert.AreEqual<Integer>(4, SubArray[3]);
    Assert.AreEqual<Integer>(5, SubArray[4]);
    Assert.AreEqual<Integer>(6, SubArray[5]);
    Assert.AreEqual<Integer>(7, SubArray[6]);
    Assert.AreEqual<Integer>(256, SubArray[7]);

    // "jsontext": "{\"object with 1 member\":[\"array with 1 element\"]}"
    Assert.AreEqual<String>('{"object with 1 member":["array with 1 element"]}', SubDoc['jsontext']);

    // "quotes": "&#34; \u0022 %22 0x22 034 &#x22;"
    Assert.AreEqual<String>('&#34; '#$0022' %22 0x22 034 &#x22;', SubDoc['quotes']);

    // "\/\\\"\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t`1~!@#$%^&*()_+-=[]{}|;:',./<>?"
    // : "A key can be any string"
    Assert.AreEqual<String>('A key can be any string', SubDoc['/\"'#$CAFE#$BABE#$AB98#$FCDE#$bcda#$ef4A#8#12#10#13#9'`1~!@#$%^&*()_+-=[]{}|;:'',./<>?']);
  end;

  // 0.5
  Assert.IsTrue(SameValue(0.5, RootArray[9]));

  // 98.6
  Assert.IsTrue(SameValue(98.6, RootArray[10]));

  // 99.44
  Assert.IsTrue(SameValue(99.44, RootArray[11]));

  // 1066
  Assert.AreEqual<Integer>(1066, RootArray[12]);

  // 1e1
  Assert.IsTrue(SameValue(10.0, RootArray[13]));

  // 0.1e1
  Assert.IsTrue(SameValue(1.0, RootArray[14]));

  // 1e-1
  Assert.IsTrue(SameValue(0.1, RootArray[15]));

  // 1e00
  Assert.IsTrue(SameValue(1.0, RootArray[16]));

  // 2e+00
  Assert.IsTrue(SameValue(2.0, RootArray[17]));

  // 2e-00
  Assert.IsTrue(SameValue(2.0, RootArray[18]));

  // "rosebud"
  Assert.AreEqual<String>('rosebud', RootArray[19]);
end;

procedure TTestBsonDocumentAllTypes.TestJsonFromFile;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Parse(LoadTestString('documents/document1.json'));
  CheckDocument(Doc);
end;

procedure TTestBsonDocumentAllTypes.TestManualCreate;
var
  Doc, SubDoc: TgoBsonDocument;
  RootArray: TgoBsonArray;
begin
  // {"Root":
  Doc := TgoBsonDocument.Create;
  RootArray := TgoBsonArray.Create;
  Doc.Add('Root', RootArray);

  // [ ... array with 20 items

  // "JSON Test Pattern pass1"
  RootArray.Add('JSON Test Pattern pass1');

  // {"object with 1 member":["array with 1 element"]}
  RootArray.Add(TgoBsonDocument.Create(
    'object with 1 member', TgoBsonArray.Create(['array with 1 element'])));

  // {}
  RootArray.Add(TgoBsonDocument.Create());

  // []
  RootArray.Add(TgoBsonArray.Create());

  // -42
  RootArray.Add(-42);

  // true
  RootArray.Add(True);

  // false
  RootArray.Add(False);

  // null
  RootArray.Add(TgoBsonNull.Value);

  // { ... object with 38 key/value pairs
  SubDoc := TgoBsonDocument.Create;
  RootArray.Add(SubDoc);
  begin
    // "integer": 1234567890
    SubDoc.Add('integer', 1234567890);

    // "real": -9876.543210
    SubDoc.Add('real', -9876.543210);

    // "e": 0.123456789e-12,
    SubDoc.Add('e', 0.123456789e-12);

    // "E": 1.234567890E+34
    SubDoc.Add('E', 1.234567890E+34);

    // "": 23456789012E66
    SubDoc.Add('', 23456789012E66);

    // "zero": 0
    SubDoc.Add('zero', 0);

    // "one": 1
    SubDoc.Add('one', 1);

    // "space": " "
    SubDoc.Add('space', ' ');

    // "quote": "\""
    SubDoc.Add('quote', '"');

    // "backslash": "\\"
    SubDoc.Add('backslash', '\');

    // "controls": "\b\f\n\r\t"
    SubDoc.Add('controls', #8#12#10#13#9);

    // "slash": "/ & \/"
    SubDoc.Add('slash', '/ & /');

    // "alpha": "abcdefghijklmnopqrstuvwyz"
    SubDoc.Add('alpha', 'abcdefghijklmnopqrstuvwyz');

    // "ALPHA": "ABCDEFGHIJKLMNOPQRSTUVWYZ"
    SubDoc.Add('ALPHA', 'ABCDEFGHIJKLMNOPQRSTUVWYZ');

    // "digit": "0123456789"
    SubDoc.Add('digit', '0123456789');

    // "0123456789": "digit"
    SubDoc.Add('0123456789', 'digit');

    // "special": "`1~!@#$%^&*()_+-={':[,]}|;.</>?"
    SubDoc.Add('special', '`1~!@#$%^&*()_+-={'':[,]}|;.</>?');

    // "hex": "\u0123\u4567\u89AB\uCDEF\uabcd\uef4A"
    SubDoc.Add('hex', #$0123#$4567#$89AB#$CDEF#$ABCD#$EF4A);

    // "true": true
    SubDoc.Add('true', True);

    // "false": false
    SubDoc.Add('false', False);

    // "null": null
    SubDoc.Add('null', TgoBsonNull.Value);

    // "array":[  ]
    SubDoc.Add('array', TgoBsonArray.Create());

    // "object":{  }
    SubDoc.Add('object', TgoBsonDocument.Create);

    // "binary": { "$binary": "VGhlIFF1aWNrIEJyb3duIEZveCBKdW1wcyBPdmVyIFRoZSBMYXp5IERvZw==", "$type": "00"
    SubDoc.Add('binary', BytesOf('The Quick Brown Fox Jumps Over The Lazy Dog'));

    // "date1": { "$date": "2014-10-18T14:24:02Z" }
    SubDoc.Add('date1', TgoBsonDateTime.Create(EncodeDateTime(2014, 10, 18, 14, 24, 2, 0), True));

    // "date2": { "$date" : { "$numberLong" : "-1742117758000" } }
    SubDoc.Add('date2', TgoBsonDateTime.Create(EncodeDateTime(1914, 10, 18, 14, 24, 2, 0), True));

    // "time stamp": { "$timestamp": { "t": 1000, "i": 3 } }
    SubDoc.Add('time stamp', TgoBsonTimestamp.Create(1000, 3));

    // "regular expression": {"$regex": "A-Za-z", "$options": "mi"}
    SubDoc.Add('regular expression', TgoBsonRegularExpression.Create('A-Za-z', 'mi'));

    // "object id": { "$oid" : "5442830b093d429b7cfc1312" }
    SubDoc.Add('object id', TgoObjectId.Create('5442830b093d429b7cfc1312'));

    // "address": "50 St. James Street"
    SubDoc.Add('address', '50 St. James Street');

    // "url": "http://www.JSON.org/"
    SubDoc.Add('url', 'http://www.JSON.org/');

    // "comment": "// /* <!-- --"
    SubDoc.Add('comment',  '// /* <!-- --');

    // "# -- --> */": " "
    SubDoc.Add('# -- --> */', ' ');

    // " s p a c e d " :[1,2 , 3
    //
    //  ,
    //
    //  4 , 5        ,          6           ,7        ,256      ]
    SubDoc.Add(' s p a c e d ', TgoBsonArray.Create([1, 2, 3, 4, 5, 6, 7, 256]));

    // "compact":[1,2,3,4,5,6,7,256]
    SubDoc.Add('compact', TgoBsonArray.Create([1, 2, 3, 4, 5, 6, 7, 256]));

    // "jsontext": "{\"object with 1 member\":[\"array with 1 element\"]}"
    SubDoc.Add('jsontext', '{"object with 1 member":["array with 1 element"]}');

    // "quotes": "&#34; \u0022 %22 0x22 034 &#x22;"
    SubDoc.Add('quotes', '&#34; '#$0022' %22 0x22 034 &#x22;');

    // "\/\\\"\uCAFE\uBABE\uAB98\uFCDE\ubcda\uef4A\b\f\n\r\t`1~!@#$%^&*()_+-=[]{}|;:',./<>?"
    // : "A key can be any string"
    SubDoc.Add('/\"'#$CAFE#$BABE#$AB98#$FCDE#$bcda#$ef4A#8#12#10#13#9'`1~!@#$%^&*()_+-=[]{}|;:'',./<>?', 'A key can be any string');
  end;

  // 0.5
  RootArray.Add(0.5);

  // 98.6
  RootArray.Add(98.6);

  // 99.44
  RootArray.Add(99.44);

  // 1066
  RootArray.Add(1066);

  // 1e1
  RootArray.Add(1e1);

  // 0.1e1
  RootArray.Add(0.1e1);

  // 1e-1
  RootArray.Add(1e-1);

  // 1e00
  RootArray.Add(1e00);

  // 2e+00
  RootArray.Add(2e+00);

  // 2e-00
  RootArray.Add(2e-00);

  // "rosebud"
  RootArray.Add('rosebud');

  CheckDocument(Doc);
end;

procedure TTestBsonDocumentAllTypes.TestWriterSettings;
const
  INDENTS: array [0..2] of String = ('', '  ', #9);
  LINE_BREAKS: array [0..2] of String = ('', #10, #13#10);
var
  Json: String;
  SourceDoc, TargetDoc: TgoBsonDocument;
  Settings: TgoJsonWriterSettings;
  OutputMode: TgoJsonOutputMode;
  IndentIndex, LineBreakIndex: Integer;
begin
  SourceDoc := TgoBsonDocument.Parse(LoadTestString('documents/document1.json'));

  // No pretty printing
  for OutputMode := Low(TgoJsonOutputMode) to High(TgoJsonOutputMode) do
  begin
    Settings := TgoJsonWriterSettings.Create(OutputMode);
    Json := SourceDoc.ToJson(Settings);

    TargetDoc := TgoBsonDocument.Parse(Json);
    CheckDocument(TargetDoc);
  end;

  // With pretty printing
  for OutputMode := Low(TgoJsonOutputMode) to High(TgoJsonOutputMode) do
  begin
    for IndentIndex := 0 to 2 do
    begin
      for LineBreakIndex := 0 to 2 do
      begin
        Settings := TgoJsonWriterSettings.Create(
          INDENTS[IndentIndex], LINE_BREAKS[LineBreakIndex], OutputMode);
        Json := SourceDoc.ToJson(Settings);

        TargetDoc := TgoBsonDocument.Parse(Json);
        CheckDocument(TargetDoc);
      end;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestObjectId);
  TDUnitX.RegisterTestFixture(TTestBsonValue);
  TDUnitX.RegisterTestFixture(TTestBsonArray);
  TDUnitX.RegisterTestFixture(TTestBsonDocument);
  TDUnitX.RegisterTestFixture(TTestBsonDocumentAllTypes);
  TDUnitX.RegisterTestFixture(TTestBsonEquals);
  TDUnitX.RegisterTestFixture(TTestBsonValueEquals);

finalization
  FreeAndNil(GTestDataZipFile);
  FreeAndNil(GTestDataStream);

end.
