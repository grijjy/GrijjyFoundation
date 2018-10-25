unit Tests.Grijjy.Bson.IO;

interface

{$R 'JsonTestData.res'}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Grijjy.Bson.IO,
  Grijjy.Bson;

type
  TestArrayElementNameAccelerator = class
  public
    [Test] procedure GetElementNameBytesShouldReturnExpectedResult;
    [Test] procedure GetElementNameBytesShouldReturnExpectedResultForBoundaryConditions;
    [Test] procedure GetElementNameBytesShouldReturnNewByteArrayWhenNotCached;
    [Test] procedure GetElementNameBytesShouldReturnSameByteArrayWhenCached;
  end;

type
  TestBsonReader = class
  public
    [Test] procedure BsonReaderShouldSupportReadingMultipleDocuments;
    [Test] procedure ReadBsonTypeShouldThrowWhenBsonTypeIsInvalid;
    [Test] procedure TestHelloWorld;
    [Test] procedure TestBsonAwesome;
    [Test] procedure TestIsAtEndOfFileWithTwoDocuments;
    [Test] procedure TestBookmark;
  end;

type
  TestJsonReader = class
  public
    [Test] procedure JsonReaderShouldSupportReadingMultipleDocuments;
    [Test] procedure TestArrayEmpty;
    [Test] procedure TestArrayOneElement;
    [Test] procedure TestArrayTwoElements;
    [Test] procedure TestBinaryData;
    [Test] procedure TestBooleanFalse;
    [Test] procedure TestBooleanTrue;
    [Test] procedure TestDateTime;
    [Test] procedure TestDateTimeStrict;
    [Test] procedure TestDateTimeIso8601;
    [Test] procedure TestDocumentEmpty;
    [Test] procedure TestDocumentNested;
    [Test] procedure TestDocumentOneElement;
    [Test] procedure TestDocumentTwoElements;
    [Test] procedure TestDouble;
    [Test] procedure TestGuid;
    [Test] procedure TestHexData;
    [Test] procedure TestInt32;
    [Test] procedure TestInt32Constructor;
    [Test] procedure TestInt64;
    [Test] procedure TestEndOfStreamWithTwoArrays;
    [Test] procedure TestEndOfStreamWithTwoDocuments;
    [Test] procedure TestJavaScript;
    [Test] procedure TestJavaScriptWithScope;
    [Test] procedure TestMaxKey;
    [Test] procedure TestMinKey;
    [Test] procedure TestNestedArray;
    [Test] procedure TestNestedDocument;
    [Test] procedure TestNull;
    [Test] procedure TestObjectId;
    [Test] procedure TestRegularExpressions;
    [Test] procedure TestRegularExpressionShell;
    [Test] procedure TestRegularExpressionStrict;
    [Test] procedure TestString;
    [Test] procedure TestStringEmpty;
    [Test] procedure TestSymbol;
    [Test] procedure TestTimestamp;
    [Test] procedure TestTimestampConstructor;
    [Test] procedure TestTimestampExtendedJsonNew;
    [Test] procedure TestTimestampExtendedJsonOld;
    [Test] procedure TestUndefined;
    [Test] procedure TestBookmark;
  end;

type
  TestJsonWriter = class
  public
    [Test] procedure JsonWriterShouldSupportWritingMultipleDocuments;
    [Test] procedure TestEmptyDocument;
    [Test] procedure TestSingleString;
    [Test] procedure TestPrettyPrintedEmptyDocument;
    [Test] procedure TestPrettyPrintedOneElement;
    [Test] procedure TestPrettyPrintedTwoElements;
    [Test] procedure TestDouble;
    [Test] procedure TestInt64Shell;
    [Test] procedure TestInt64Strict;
    [Test] procedure TestEmbeddedDocument;
    [Test] procedure TestPrettyPrintedEmbeddedDocument;
    [Test] procedure TestArray;
    [Test] procedure TestBinaryShell;
    [Test] procedure TestBinaryStrict;
    [Test] procedure TestDateTimeShell;
    [Test] procedure TestDateTimeStrict;
    [Test] procedure TestJavaScript;
    [Test] procedure TestJavaScriptWithScope;
    [Test] procedure TestGuid;
    [Test] procedure TestMaxKey;
    [Test] procedure TestMinKey;
    [Test] procedure TestNull;
    [Test] procedure TestObjectIdShell;
    [Test] procedure TestObjectIdStrict;
    [Test] procedure TestRegularExpressionShell;
    [Test] procedure TestRegularExpressionStrict;
    [Test] procedure TestString;
    [Test] procedure TestSymbol;
    [Test] procedure TestTimestamp;
    [Test] procedure TestUndefined;
    [Test] procedure TestSampleDocument;
  end;

type
  TestBsonWriter = class
  public
    [Test] procedure BsonWriterShouldSupportWritingMultipleDocuments;
  end;

type
  TestBsonBuffer = class
  public
    [Test] procedure TestReadCStringEmpty;
    [Test] procedure TestReadCStringOneCharacter;
    [Test] procedure TestReadCStringOneCharacterDecoderException;
    [Test] procedure TestReadCStringTwoCharacters;
    [Test] procedure TestReadCStringTwoCharactersDecoderException;
    [Test] procedure TestReadStringEmpty;
    [Test] procedure TestReadStringInvalidLength;
    [Test] procedure TestReadStringMissingNullTerminator;
    [Test] procedure TestReadStringOneCharacter;
    [Test] procedure TestReadStringOneCharacterDecoderException;
    [Test] procedure TestReadStringTwoCharacters;
    [Test] procedure TestReadStringTwoCharactersDecoderException;
  end;

type
  TestBsonRoundTrip = class
  public
    [Test] procedure TestHelloWorld;
    [Test] procedure TestBsonIsAwesome;
    [Test] procedure TestAllTypes;
  end;

type
  TestJsonData = class
  private
    procedure TestJsonFile(const BaseFilename: String);
    procedure WriteValueTree(const Builder: TStringBuilder;
      const Value: TgoBsonValue; const Path: UnicodeString = '.');
  public
    [Test] procedure test_array_01;
    [Test] procedure test_array_02;
    [Test] procedure test_array_03;
    [Test] procedure test_array_04;
    [Test] procedure test_array_05;
    [Test] procedure test_array_06;
//    procedure test_basic_01; // this test is not JSON compliant
//    procedure test_basic_02; // this test is not JSON compliant
    [Test] procedure test_basic_03;
    [Test] procedure test_basic_04;
    [Test] procedure test_basic_05;
    [Test] procedure test_basic_06;
    [Test] procedure test_basic_07;
//    procedure test_basic_08; // this test is not JSON compliant
//    procedure test_basic_09; // this test is not JSON compliant
//    procedure test_comment_01; // this test is not JSON compliant
    [Test] procedure test_complex_01;
    [Test] procedure test_integer_01;
    [Test] procedure test_integer_02;
    [Test] procedure test_integer_03;
    [Test] procedure test_integer_04;
    [Test] procedure test_integer_05;
    [Test] procedure test_large_01;
    [Test] procedure test_object_01;
    [Test] procedure test_object_02;
    [Test] procedure test_object_03;
    [Test] procedure test_object_04;
//    procedure test_preserve_comment_01; // this test is not JSON compliant
    [Test] procedure test_real_01;
    [Test] procedure test_real_02;
    [Test] procedure test_real_03;
    [Test] procedure test_real_04;
    [Test] procedure test_real_05;
    [Test] procedure test_real_06;
    [Test] procedure test_real_07;
    [Test] procedure test_string_01;
    [Test] procedure test_string_02;
    [Test] procedure test_string_unicode_01;
    [Test] procedure test_string_unicode_02;
    [Test] procedure test_string_unicode_03;
    [Test] procedure test_string_unicode_04;
    [Test] procedure test_string_unicode_05;
  end;

type
  TestJsonChecker = class
  private
    procedure TestPass(const Filename: String);
    procedure TestFail(const Filename: String; const ErrorLine,
      ErrorColumn: Integer);
  public
//    procedure test_fail1;
    [Test] procedure test_fail2;
//    procedure test_fail3;
//    procedure test_fail4;
    [Test] procedure test_fail5;
    [Test] procedure test_fail6;
//    procedure test_fail7;
//    procedure test_fail8;
//    procedure test_fail9;
//    procedure test_fail10;
    [Test] procedure test_fail11;
    [Test] procedure test_fail12;
    [Test] procedure test_fail13;
    [Test] procedure test_fail14;
    [Test] procedure test_fail15;
    [Test] procedure test_fail16;
    [Test] procedure test_fail17;
//    procedure test_fail18;
    procedure test_fail19;
    [Test] procedure test_fail20;
    [Test] procedure test_fail21;
    [Test] procedure test_fail22;
    [Test] procedure test_fail23;
//    procedure test_fail24;
//    procedure test_fail25;
    [Test] procedure test_fail26;
//    procedure test_fail27;
    [Test] procedure test_fail28;
    [Test] procedure test_fail29;
    [Test] procedure test_fail30;
    [Test] procedure test_fail31;
    [Test] procedure test_fail32;
    [Test] procedure test_fail33;
    [Test] procedure test_pass1;
    [Test] procedure test_pass2;
    [Test] procedure test_pass3;
  end;

type
  TestJsonToBson = class
  public
    [Test] procedure TestSingleTypes;
    [Test] procedure TestAllTypes;
  end;

type
  TestBsonDocumentWriter = class
  public
    [Test] procedure TestOneEmptyArray;
    [Test] procedure TestOneNestedEmptyArray;
    [Test] procedure TestTwoEmptyArrays;
    [Test] procedure TestTwoNestedEmptyArrays;
    [Test] procedure TestEmptyDocument;
    [Test] procedure TestOneEmptyDocument;
    [Test] procedure TestOneNestedEmptyDocument;
    [Test] procedure TestTwoEmptyDocuments;
    [Test] procedure TestTwoNestedEmptyDocuments;
    [Test] procedure TestArrayWithOneElement;
    [Test] procedure TestArrayWithTwoElements;
    [Test] procedure TestArrayWithNestedEmptyArray;
    [Test] procedure TestArrayWithNestedArrayWithOneElement;
    [Test] procedure TestArrayWithNestedArrayWithTwoElements;
    [Test] procedure TestArrayWithTwoNestedArrays;
    [Test] procedure TestOneBinary;
    [Test] procedure TestOneNestedBinary;
    [Test] procedure TestTwoBinaries;
    [Test] procedure TestTwoNestedBinaries;
    [Test] procedure TestBoolean;
    [Test] procedure TestDateTime;
    [Test] procedure TestDouble;
    [Test] procedure TestInt32;
    [Test] procedure TestInt64;
    [Test] procedure TestJavaScript;
    [Test] procedure TestJavaScriptWithScope;
    [Test] procedure TestMaxKey;
    [Test] procedure TestMinKey;
    [Test] procedure TestNull;
    [Test] procedure TestObjectId;
    [Test] procedure TestRegularExpression;
    [Test] procedure TestString;
    [Test] procedure TestSymbol;
    [Test] procedure TestTimestamp;
    [Test] procedure TestUndefined;
  end;

type
  TestBsonDocumentReader = class
  private
    procedure Test(const ADocument: TgoBsonDocument);
  public
    [Test] procedure TestEmptyDocument;
    [Test] procedure TestSingleString;
    [Test] procedure TestEmbeddedDocument;
    [Test] procedure TestArray;
    [Test] procedure TestDateTime;
    [Test] procedure TestBinary;
    [Test] procedure TestJavaScript;
    [Test] procedure TestJavaScriptWithScope;
    [Test] procedure TestGuid;
    [Test] procedure TestEndOfStream;
    [Test] procedure TestMaxKey;
    [Test] procedure TestMinKey;
    [Test] procedure TestNull;
    [Test] procedure TestSymbol;
    [Test] procedure TestTimestamp;
    [Test] procedure TestBoolean;
    [Test] procedure TestBytes;
    [Test] procedure TestDouble;
    [Test] procedure TestObjectId;
    [Test] procedure TestRegularExpression;
    [Test] procedure TestUndefined;
    [Test] procedure TestBookmark;
  end;

implementation

uses
  System.Math,
  System.Classes,
  System.DateUtils,
  System.Generics.Defaults,
  System.Generics.Collections,
  Grijjy.SysUtils,
  Tests.Grijjy.Bson;

type
  TgoBsonWriterAccess = class(TgoBsonWriter);
  TArrayElementNameAccelerator = TgoBsonWriterAccess.TArrayElementNameAccelerator;

{ TestArrayElementNameAccelerator }

procedure TestArrayElementNameAccelerator.GetElementNameBytesShouldReturnExpectedResult;
var
  I: Integer;
  Actual, Expected: TBytes;
begin
  for I := 0 to 1010 do
  begin
    Actual := TArrayElementNameAccelerator.GetElementNameBytes(I);
    Expected := BytesOf(I.ToString);
    Assert.AreEqual(Expected, Actual);
  end;
end;

procedure TestArrayElementNameAccelerator.GetElementNameBytesShouldReturnExpectedResultForBoundaryConditions;
const
  INDICES: array [0..15] of Integer = (0, 9, 10, 99, 100, 999, 1000, 9999, 10000,
    99999, 100000, 999999, 1000000, 9999999, 100000000, Integer.MaxValue);
var
  I: Integer;
  Actual, Expected: TBytes;
begin
  for I := 0 to Length(INDICES) - 1 do
  begin
    Actual := TArrayElementNameAccelerator.GetElementNameBytes(INDICES[I]);
    Expected := BytesOf(INDICES[I].ToString);
    Assert.AreEqual(Expected, Actual);
  end;
end;

procedure TestArrayElementNameAccelerator.GetElementNameBytesShouldReturnNewByteArrayWhenNotCached;
var
  A, B: TBytes;
  IA: NativeInt absolute A;
  IB: NativeInt absolute B;
begin
  A := TArrayElementNameAccelerator.GetElementNameBytes(1000);
  B := TArrayElementNameAccelerator.GetElementNameBytes(1000);
  Assert.AreNotEqual(IA, IB);
end;

procedure TestArrayElementNameAccelerator.GetElementNameBytesShouldReturnSameByteArrayWhenCached;
var
  A, B: TBytes;
  IA: NativeInt absolute A;
  IB: NativeInt absolute B;
  I: Integer;
begin
  for I := 0 to 999 do
  begin
    A := TArrayElementNameAccelerator.GetElementNameBytes(I);
    B := TArrayElementNameAccelerator.GetElementNameBytes(I);
    Assert.AreEqual(IA, IB);
  end;
end;

{ TestBsonReader }

procedure TestBsonReader.BsonReaderShouldSupportReadingMultipleDocuments;
var
  I, NumberOfDocuments: Integer;
  Doc, ResultDoc: TgoBsonDocument;
  Bson, Input: TBytes;
  Actual, Expected: TArray<TgoBsonDocument>;
  Reader: IgoBsonReader;
  Name: String;
  Value: Integer;
begin
  for NumberOfDocuments := 0 to 3 do
  begin
    Doc := TgoBsonDocument.Create('x', 1);
    Bson := Doc.ToBson;
    Input := nil;
    Expected := nil;
    for I := 0 to NumberOfDocuments - 1 do
    begin
      Input := Input + Bson;
      Expected := Expected + [Doc];
    end;

    Actual := nil;
    Reader := TgoBsonReader.Create(Input);
    while (not Reader.EndOfStream) do
    begin
      Reader.ReadStartDocument;
      Name := Reader.ReadName;
      Value := Reader.ReadInt32;
      Reader.ReadEndDocument;

      ResultDoc := TgoBsonDocument.Create(Name, Value);
      Actual := Actual + [ResultDoc];
    end;

    Assert.AreEqual(NumberOfDocuments, Length(Expected));
    Assert.AreEqual(NumberOfDocuments, Length(Actual));
    for I := 0 to NumberOfDocuments - 1 do
      Assert.IsTrue(Expected[I] = Actual[I]);
  end;
end;

procedure TestBsonReader.ReadBsonTypeShouldThrowWhenBsonTypeIsInvalid;
const
  TEST_CASES: array [0..9] of String = (
    '00000000 f0 6100',
    '00000000 08 6100 00 f0 6200',
    '00000000 03 6100 00000000 f0 6200',
    '00000000 03 6100 00000000 08 6200 00 f0 6300',
    '00000000 04 6100 00000000 f0',
    '00000000 04 6100 00000000 08 3000 00 f0',
    '00000000 04 6100 00000000 03 3000 00000000 f0 6200',
    '00000000 04 6100 00000000 03 3000 00000000 08 6200 00 f0 6300',
    '00000000 04 6100 00000000 08 3000 00 03 3100 00000000 f0 6200',
    '00000000 04 6100 00000000 08 3000 00 03 3200 00000000 08 6200 00 f0 6300');
var
  I: Integer;
  Bytes: TBytes;
begin
  for I := 0 to Length(TEST_CASES) - 1 do
  begin
    Bytes := goParseHexString(TEST_CASES[I].Replace(' ', '', [rfReplaceAll]));
    Assert.WillRaise(
      procedure
      var
        Reader: IgoBsonReader;
      begin
        Reader := TgoBsonReader.Create(Bytes);
        Reader.ReadDocument;
      end, EInvalidOperation);
  end;
end;

procedure TestBsonReader.TestBookmark;
const
  JSON = '{ "x" : 1, "y" : 2 }';
var
  Doc: TgoBsonDocument;
  Bson: TBytes;
  Reader: IgoBsonReader;
  Bookmark: IgoBsonReaderBookmark;
begin
  Doc := TgoBsonDocument.Parse(JSON);
  Bson := Doc.ToBson;

  Reader := TgoBsonReader.Create(Bson);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Reader.ReadStartDocument;
  Reader.ReturnToBookmark(Bookmark);
  Reader.ReadStartDocument;

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual('x', Reader.ReadName);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual('x', Reader.ReadName);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(1, Reader.ReadInt32);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(1, Reader.ReadInt32);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual('y', Reader.ReadName);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual('y', Reader.ReadName);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(2, Reader.ReadInt32);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(2, Reader.ReadInt32);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Reader.ReadEndDocument;
  Reader.ReturnToBookmark(Bookmark);
  Reader.ReadEndDocument;

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));
end;

procedure TestBsonReader.TestBsonAwesome;
const
  SOURCE = '1\x00\x00\x00\x04BSON\x00&\x00\x00\x00\x020\x00\x08\x00\x00\x00awesome\x00\x011\x00333333\x14@\x102\x00\xc2\x07\x00\x00\x00\x00';
var
  Bytes: TBytes;
  Reader: IgoBsonReader;
begin
  Bytes := DecodeByteString(SOURCE);
  Reader := TgoBsonReader.Create(Bytes);

  Reader.ReadStartDocument;
  Assert.AreEqual(Ord(TgoBsonType.&Array), Ord(Reader.ReadBsonType));
  Assert.AreEqual('BSON', Reader.ReadName);

  Reader.ReadStartArray;
  Assert.AreEqual(Ord(TgoBsonType.String), Ord(Reader.ReadBsonType));
  Assert.AreEqual('awesome', Reader.ReadString);
  Assert.AreEqual(Ord(TgoBsonType.Double), Ord(Reader.ReadBsonType));
  Assert.AreEqual(5.05, Reader.ReadDouble, 0.001);
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual(1986, Reader.ReadInt32);
  Reader.ReadEndArray;

  Reader.ReadEndDocument;
end;

procedure TestBsonReader.TestHelloWorld;
const
  SOURCE = '\x16\x00\x00\x00\x02hello\x00\x06\x00\x00\x00world\x00\x00';
var
  Bytes: TBytes;
  Reader: IgoBsonReader;
begin
  Bytes := DecodeByteString(SOURCE);
  Reader := TgoBsonReader.Create(Bytes);
  Reader.ReadStartDocument;
  Assert.AreEqual(Ord(TgoBsonType.String), Ord(Reader.ReadBsonType));
  Assert.AreEqual('hello', Reader.ReadName);
  Assert.AreEqual('world', Reader.ReadString);
  Reader.ReadEndDocument;
end;

procedure TestBsonReader.TestIsAtEndOfFileWithTwoDocuments;
var
  Expected, Doc: TgoBsonDocument;
  Bson: TBytes;
  Writer: IgoBsonWriter;
  Reader: IgoBsonReader;
  Count: Integer;
begin
  Expected := TgoBsonDocument.Create('x', 1);

  Writer := TgoBsonWriter.Create;
  Writer.WriteValue(Expected);
  Writer.WriteValue(Expected);
  Bson := Writer.ToBson;

  Reader := TgoBsonReader.Create(Bson);
  Count := 0;
  while (not Reader.EndOfStream) do
  begin
    Doc := Reader.ReadDocument;
    Assert.IsTrue(Doc = Expected);
    Inc(Count);
  end;
  Assert.AreEqual(2, Count);
end;

{ TestJsonReader }

procedure TestJsonReader.JsonReaderShouldSupportReadingMultipleDocuments;
var
  I, NumberOfDocuments: Integer;
  Doc, ResultDoc: TgoBsonDocument;
  Json, Input: String;
  Actual, Expected: TArray<TgoBsonDocument>;
  Reader: IgoJsonReader;
  Name: String;
  Value: Integer;
begin
  for NumberOfDocuments := 0 to 3 do
  begin
    Doc := TgoBsonDocument.Create('x', 1);
    Json := Doc.ToJson;
    Input := '';
    Expected := nil;
    for I := 0 to NumberOfDocuments - 1 do
    begin
      Input := Input + Json;
      Expected := Expected + [Doc];
    end;

    Actual := nil;
    Reader := TgoJsonReader.Create(Input);
    while (not Reader.EndOfStream) do
    begin
      Reader.ReadStartDocument;
      Name := Reader.ReadName;
      Value := Reader.ReadInt32;
      Reader.ReadEndDocument;

      ResultDoc := TgoBsonDocument.Create(Name, Value);
      Actual := Actual + [ResultDoc];
    end;

    Assert.AreEqual(NumberOfDocuments, Length(Expected));
    Assert.AreEqual(NumberOfDocuments, Length(Actual));
    for I := 0 to NumberOfDocuments - 1 do
      Assert.IsTrue(Expected[I] = Actual[I]);
  end;
end;

procedure TestJsonReader.TestArrayEmpty;
const
  JSON = '[]';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.&Array), Ord(Reader.ReadBsonType));
  Reader.ReadStartArray;
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReadEndArray;
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestArrayOneElement;
const
  JSON = '[1]';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.&Array), Ord(Reader.ReadBsonType));
  Reader.ReadStartArray;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual(1, Reader.ReadInt32);
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReadEndArray;
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestArrayTwoElements;
const
  JSON = '[1, 2]';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
  A: TgoBsonArray;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.&Array), Ord(Reader.ReadBsonType));
  Reader.ReadStartArray;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual(1, Reader.ReadInt32);
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual(2, Reader.ReadInt32);
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReadEndArray;
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);

  A := TgoBsonArray.Parse(JSON);
  Assert.AreEqual(JSON, A.ToJson);
end;

procedure TestJsonReader.TestBinaryData;
const
  TEST_CASES: array [0..3] of String = (
    '{ $binary : "AQ==", $type : 0 }',
    '{ $binary : "AQ==", $type : "0" }',
    '{ $binary : "AQ==", $type : "00" }',
    'BinData(0, "AQ==")');
var
  I: Integer;
  Reader: IgoJsonReader;
  Data: TgoBsonBinaryData;
begin
  for I := 0 to Length(TEST_CASES) - 1 do
  begin
    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    Data := Reader.ReadBinaryData;
    Assert.AreEqual(1, Data.Count);
    Assert.AreEqual(1, Integer(Data[0]));
    Assert.IsTrue(Reader.EndOfStream);
  end;
end;

procedure TestJsonReader.TestBookmark;
const
  JSON = '{ "x" : 1, "y" : 2 }';
var
  Reader: IgoJsonReader;
  Bookmark: IgoBsonReaderBookmark;
begin
  Reader := TgoJsonReader.Create(JSON);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Reader.ReadStartDocument;
  Reader.ReturnToBookmark(Bookmark);
  Reader.ReadStartDocument;

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual('x', Reader.ReadName);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual('x', Reader.ReadName);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(1, Reader.ReadInt32);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(1, Reader.ReadInt32);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual('y', Reader.ReadName);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual('y', Reader.ReadName);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(2, Reader.ReadInt32);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(2, Reader.ReadInt32);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Reader.ReadEndDocument;
  Reader.ReturnToBookmark(Bookmark);
  Reader.ReadEndDocument;

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));
end;

procedure TestJsonReader.TestBooleanFalse;
const
  JSON = 'false';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.Boolean), Ord(Reader.ReadBsonType));
  Assert.IsFalse(Reader.ReadBoolean);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestBooleanTrue;
const
  JSON = 'true';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.Boolean), Ord(Reader.ReadBsonType));
  Assert.IsTrue(Reader.ReadBoolean);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestDateTime;

  procedure Test(const AJson: String; const AExpected: Int64);
  var
    Reader: IgoJsonReader;
    Actual: Int64;
  begin
    Reader := TgoJsonReader.Create(AJson);
    Actual := Reader.ReadDateTime;
    Assert.AreEqual(AExpected, Actual);
    Assert.IsTrue(Reader.EndOfStream);
  end;

begin
  Test('{ $date : 0 }', 0);
  Test('{ $date : -9223372036854775808 }', -9223372036854775808);
  Test('{ $date : 9223372036854775807 }', 9223372036854775807);
  Test('{ $date : { $numberLong : 0 } }', 0);
  Test('{ $date : { $numberLong : -9223372036854775808 } }', -9223372036854775808);
  Test('{ $date : { $numberLong : 9223372036854775807 } }', 9223372036854775807);
  Test('{ $date : { $numberLong : "0" } }', 0);
  Test('{ $date : { $numberLong : "-9223372036854775808" } }', -9223372036854775808);
  Test('{ $date : { $numberLong : "9223372036854775807" } }', 9223372036854775807);
  Test('{ $date : "1970-01-01T00:00:00Z" }', 0);
  Test('{ $date : "0001-01-01T00:00:00Z" }', -62135596800000);
  Test('{ $date : "1970-01-01T00:00:00.000Z" }', 0);
  Test('{ $date : "0001-01-01T00:00:00.000Z" }', -62135596800000);
  Test('{ $date : "9999-12-31T23:59:59.999Z" }', 253402300799999);
  Test('new Date(0)', 0);
  Test('new Date(9223372036854775807)', 9223372036854775807);
  Test('new Date(-9223372036854775808)', -9223372036854775808);
  Test('ISODate("1970-01-01T00:00:00Z")', 0);
  Test('ISODate("0001-01-01T00:00:00Z")', -62135596800000);
  Test('ISODate("1970-01-01T00:00:00.000Z")', 0);
  Test('ISODate("0001-01-01T00:00:00.000Z")', -62135596800000);
  Test('ISODate("9999-12-31T23:59:59.999Z")', 253402300799999);
end;

procedure TestJsonReader.TestDateTimeIso8601;
const
  JSON = '{ "$date" : "1970-01-01T00:00:00Z" }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
  Settings: TgoJsonWriterSettings;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.DateTime), Ord(Reader.ReadBsonType));
  Assert.AreEqual<Double>(0, Reader.ReadDateTime);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;

  Settings := TgoJsonWriterSettings.Create(TgoJsonOutputMode.Strict);
  Assert.AreEqual('{ "$date" : 0 }', V.ToJson(Settings));
end;

procedure TestJsonReader.TestDateTimeStrict;
const
  JSON = '{ "$date" : 0 }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
  Settings: TgoJsonWriterSettings;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.DateTime), Ord(Reader.ReadBsonType));
  Assert.AreEqual<Double>(0, Reader.ReadDateTime);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;

  Settings := TgoJsonWriterSettings.Create(TgoJsonOutputMode.Strict);
  Assert.AreEqual(JSON, V.ToJson(Settings));
end;

procedure TestJsonReader.TestDocumentEmpty;
const
  JSON = '{ }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));
  Reader.ReadStartDocument;
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReadEndDocument;
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestDocumentNested;
const
  JSON = '{ "a" : { "x" : 1 }, "y" : 2 }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));
  Reader.ReadStartDocument;
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));
  Assert.AreEqual('a', Reader.ReadName);

  Reader.ReadStartDocument;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual('x', Reader.ReadName);
  Assert.AreEqual(1, Reader.ReadInt32);

  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReadEndDocument;

  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual('y', Reader.ReadName);
  Assert.AreEqual(2, Reader.ReadInt32);

  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReadEndDocument;

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestDocumentOneElement;
const
  JSON = '{ "x" : 1 }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));

  Reader.ReadStartDocument;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual('x', Reader.ReadName);
  Assert.AreEqual(1, Reader.ReadInt32);

  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReadEndDocument;

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestDocumentTwoElements;
const
  JSON = '{ "x" : 1, "y" : 2 }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));

  Reader.ReadStartDocument;

  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual('x', Reader.ReadName);
  Assert.AreEqual(1, Reader.ReadInt32);

  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual('y', Reader.ReadName);
  Assert.AreEqual(2, Reader.ReadInt32);

  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReadEndDocument;

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestDouble;
const
  JSON = '1.5';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.Double), Ord(Reader.ReadBsonType));
  Assert.AreEqual<Double>(1.5, Reader.ReadDouble);

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestEndOfStreamWithTwoArrays;
const
  JSON = '[1,2][1,2]';
var
  Reader: IgoJsonReader;
  Count: Integer;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Count := 0;
  while (not Reader.EndOfStream) do
  begin
    V := Reader.ReadValue;
    Assert.IsTrue(V.IsBsonArray);
    Assert.AreEqual(2, V.AsBsonArray.Count);
    Assert.AreEqual<Integer>(1, V.AsBsonArray[0]);
    Assert.AreEqual<Integer>(2, V.AsBsonArray[1]);
    Inc(Count);
  end;
  Assert.AreEqual(2, Count);
end;

procedure TestJsonReader.TestEndOfStreamWithTwoDocuments;
const
  JSON = '{x:1}{x:1}';
var
  Reader: IgoJsonReader;
  Count: Integer;
  D: TgoBsonDocument;
begin
  Reader := TgoJsonReader.Create(JSON);
  Count := 0;
  while (not Reader.EndOfStream) do
  begin
    D := Reader.ReadDocument;
    Assert.AreEqual(1, D.Count);
    Assert.AreEqual<Integer>(1, D['x']);
    Inc(Count);
  end;
  Assert.AreEqual(2, Count);
end;

procedure TestJsonReader.TestGuid;
const
  JSON = 'CSUUID("B5F21E0C2A0D42D6AD03D827008D8AB6")';
var
  Guid: TGuid;
  Reader: IgoJsonReader;
  BinaryData: TgoBsonBinaryData;
  V: TgoBsonValue;
begin
  Guid := TGuid.Create('{B5F21E0C-2A0D-42D6-AD03-D827008D8AB6}');
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.Binary), Ord(Reader.ReadBsonType));
  BinaryData := Reader.ReadBinaryData;
  Assert.AreEqual(Guid.ToByteArray, BinaryData.AsBytes);
  Assert.AreEqual(Ord(TgoBsonBinarySubType.UuidLegacy), Ord(BinaryData.SubType));
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual('CSUUID("b5f21e0c-2a0d-42d6-ad03-d827008d8ab6")', V.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonReader.TestHexData;
const
  JSON = 'HexData(0, "123")';
var
  Reader: IgoJsonReader;
  Bytes: TBytes;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.Binary), Ord(Reader.ReadBsonType));
  Bytes := Reader.ReadBytes;
  Assert.AreEqual(2, Length(Bytes));
  Assert.AreEqual<Byte>($01, Bytes[0]);
  Assert.AreEqual<Byte>($23, Bytes[1]);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual('new BinData(0, "ASM=")', V.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonReader.TestInt32;
const
  JSON = '42';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual(42, Reader.ReadInt32);

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestInt32Constructor;
const
  TEST_CASES: array [0..1] of String = ('Number(42)', 'NumberInt(42)');
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
  I: Integer;
begin
  for I := 0 to Length(TEST_CASES) - 1 do
  begin
    Reader := TgoJsonReader.Create(TEST_CASES[I]);

    Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
    Assert.AreEqual(42, Reader.ReadInt32);

    Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    V := Reader.ReadValue;
    Assert.AreEqual('42', V.ToJson);
  end;
end;

procedure TestJsonReader.TestInt64;

  procedure Test(const AJson: String; const AExpected: Int64);
  var
    Reader: IgoJsonReader;
  begin
    Reader := TgoJsonReader.Create(AJson);
    Assert.AreEqual(AExpected, Reader.ReadInt64);
    Assert.IsTrue(Reader.EndOfStream);
  end;

begin
  Test('{ $numberLong: 1 }', 1);
  Test('{ $numberLong: -9223372036854775808 }', -9223372036854775808);
  Test('{ $numberLong: 9223372036854775807 }', 9223372036854775807);
  Test('{ $numberLong: "1" }', 1);
  Test('{ $numberLong: "-9223372036854775808" }', -9223372036854775808);
  Test('{ $numberLong: "9223372036854775807" }', 9223372036854775807);
  Test('NumberLong(1)', 1);
  Test('NumberLong(-9223372036854775808)', -9223372036854775808);
  Test('NumberLong(9223372036854775807)', 9223372036854775807);
  Test('NumberLong("1")', 1);
  Test('NumberLong("-9223372036854775808")', -9223372036854775808);
  Test('NumberLong("9223372036854775807")', 9223372036854775807);
end;

procedure TestJsonReader.TestJavaScript;
const
  JSON = '{ "$code" : "function f() { return 1; }" }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.JavaScript), Ord(Reader.ReadBsonType));
  Assert.AreEqual('function f() { return 1; }', Reader.ReadJavaScript);

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestJavaScriptWithScope;
const
  JSON = '{ "$code" : "function f() { return n; }", "$scope" : { "n" : 1 } }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.JavaScriptWithScope), Ord(Reader.ReadBsonType));
  Assert.AreEqual('function f() { return n; }', Reader.ReadJavaScriptWithScope);

  Reader.ReadStartDocument;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Assert.AreEqual('n', Reader.ReadName);
  Assert.AreEqual(1, Reader.ReadInt32);
  Reader.ReadEndDocument;

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);

  V := TgoBsonValue.Parse(JSON);
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestMaxKey;
const
  TEST_CASES: array [0..2] of String = ('{ $maxKey : 1 }', '{ $maxkey : 1 }', 'MaxKey');
var
  Reader: IgoJsonReader;
  I: Integer;
  V: TgoBsonValue;
begin
  for I := 0 to Length(TEST_CASES) - 1 do
  begin
    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    Reader.ReadMaxKey;
    Assert.IsTrue(Reader.EndOfStream);
    Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    V := Reader.ReadValue;
    Assert.AreEqual('MaxKey', V.ToJson(TgoJsonWriterSettings.Shell));
  end;
end;

procedure TestJsonReader.TestMinKey;
const
  TEST_CASES: array [0..2] of String = ('{ $minKey : 1 }', '{ $minkey : 1 }', 'MinKey');
var
  Reader: IgoJsonReader;
  I: Integer;
  V: TgoBsonValue;
begin
  for I := 0 to Length(TEST_CASES) - 1 do
  begin
    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    Reader.ReadMinKey;
    Assert.IsTrue(Reader.EndOfStream);
    Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    V := Reader.ReadValue;
    Assert.AreEqual('MinKey', V.ToJson(TgoJsonWriterSettings.Shell));
  end;
end;

procedure TestJsonReader.TestNestedArray;
const
  JSON = '{ "a" : [1, 2] }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));
  Reader.ReadStartDocument;

  Assert.AreEqual(Ord(TgoBsonType.&Array), Ord(Reader.ReadBsonType));
  Assert.AreEqual('a', Reader.ReadName);

  Reader.ReadStartArray;
  Assert.AreEqual(1, Reader.ReadInt32);
  Assert.AreEqual(2, Reader.ReadInt32);
  Reader.ReadEndArray;

  Reader.ReadEndDocument;
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestNestedDocument;
const
  JSON = '{ "a" : { "b" : 1, "c" : 2 } }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));
  Reader.ReadStartDocument;

  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));
  Assert.AreEqual('a', Reader.ReadName);

  Reader.ReadStartDocument;
  Assert.AreEqual('b', Reader.ReadName);
  Assert.AreEqual(1, Reader.ReadInt32);
  Assert.AreEqual('c', Reader.ReadName);
  Assert.AreEqual(2, Reader.ReadInt32);
  Reader.ReadEndDocument;

  Reader.ReadEndDocument;
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestNull;
const
  JSON = 'null';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.Null), Ord(Reader.ReadBsonType));
  Reader.ReadNull;
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestObjectId;
const
  TEST_CASES: array [0..2] of String = (
    '{ $oid : "0102030405060708090a0b0c" }',
    '{ "$oid" : "0102030405060708090a0b0c" }',
    'ObjectId("0102030405060708090a0b0c")');
var
  Reader: IgoJsonReader;
  I: Integer;
  ObjId: TgoObjectId;
  V: TgoBsonValue;
begin
  for I := 0 to Length(TEST_CASES) - 1 do
  begin
    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    ObjId := Reader.ReadObjectId;
    Assert.AreEqual('0102030405060708090a0b0c', ObjId.ToString);
    Assert.IsTrue(Reader.EndOfStream);
    Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    V := Reader.ReadValue;
    Assert.AreEqual('ObjectId("0102030405060708090a0b0c")', V.ToJson(TgoJsonWriterSettings.Shell));

    Assert.AreEqual('{ "$oid" : "0102030405060708090a0b0c" }', V.ToJson);
  end;
end;

procedure TestJsonReader.TestRegularExpressions;
const
  TEST_CASES: array [0..3] of String = (
    '{ $regex : "abc", $options : "i" }',
    '{ $regex : "abc/", $options : "i" }',
    '/abc/i',
    '/abc\//i');
var
  Reader: IgoJsonReader;
  I: Integer;
  ExpectedPattern: String;
  Actual, Expected: TgoBsonRegularExpression;
begin
  for I := 0 to Length(TEST_CASES) - 1 do
  begin
    if (Odd(I)) then
      ExpectedPattern := 'abc/'
    else
      ExpectedPattern := 'abc';

    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    Actual := Reader.ReadRegularExpression;
    Expected := TgoBsonRegularExpression.Create(ExpectedPattern, 'i');
    Assert.IsTrue(Actual = Expected);
    Assert.IsTrue(Reader.EndOfStream);
  end;
end;

procedure TestJsonReader.TestRegularExpressionShell;
const
  JSON = '/pattern/imxs';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
  RegEx: TgoBsonRegularExpression;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.RegularExpression), Ord(Reader.ReadBsonType));
  RegEx := Reader.ReadRegularExpression;
  Assert.AreEqual('pattern', RegEx.Pattern);
  Assert.AreEqual('imxs', RegEx.Options);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonReader.TestRegularExpressionStrict;
const
  JSON = '{ "$regex" : "pattern", "$options" : "imxs" }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
  RegEx: TgoBsonRegularExpression;
begin
  Reader := TgoJsonReader.Create(JSON);
  Assert.AreEqual(Ord(TgoBsonType.RegularExpression), Ord(Reader.ReadBsonType));
  RegEx := Reader.ReadRegularExpression;
  Assert.AreEqual('pattern', RegEx.Pattern);
  Assert.AreEqual('imxs', RegEx.Options);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;

  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestString;
const
  JSON = '"abc"';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.String), Ord(Reader.ReadBsonType));
  Assert.AreEqual('abc', Reader.ReadString);

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestStringEmpty;
const
  JSON = '""';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.String), Ord(Reader.ReadBsonType));
  Assert.AreEqual('', Reader.ReadString);

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestSymbol;
const
  JSON = '{ "$symbol" : "symbol" }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.Symbol), Ord(Reader.ReadBsonType));
  Assert.AreEqual('symbol', Reader.ReadSymbol);

  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson);
end;

procedure TestJsonReader.TestTimestamp;

  procedure Test(const AJson: String; const AExpected: Int64);
  var
    Reader: IgoJsonReader;
    Actual: Int64;
  begin
    Reader := TgoJsonReader.Create(AJson);
    Actual := Reader.ReadTimestamp;
    Assert.AreEqual(AExpected, Actual);
    Assert.IsTrue(Reader.EndOfStream);
  end;

begin
  Test('{ $timestamp : { t : 1, i : 2 } }', $100000002);
  Test('{ $timestamp : { t : -2147483648, i : -2147483648 } }', Int64($8000000080000000));
  Test('{ $timestamp : { t : 2147483647, i : 2147483647 } }', $7fffffff7fffffff);
  Test('Timestamp(1, 2)', $100000002);
  Test('Timestamp(-2147483648, -2147483648)', Int64($8000000080000000));
  Test('Timestamp(2147483647, 2147483647)', $7fffffff7fffffff);
end;

procedure TestJsonReader.TestTimestampConstructor;
const
  JSON = 'Timestamp(1, 2)';
var
  Reader: IgoJsonReader;
  TS: TgoBsonTimestamp;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.Timestamp), Ord(Reader.ReadBsonType));
  TS := TgoBsonTimestamp.Create(1, 2);
  Assert.AreEqual(TS.Value, Reader.ReadTimestamp);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual(JSON, V.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonReader.TestTimestampExtendedJsonNew;
const
  JSON = '{ "$timestamp" : { "t" : 1, "i" : 2 } }';
var
  Reader: IgoJsonReader;
  TS: TgoBsonTimestamp;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.Timestamp), Ord(Reader.ReadBsonType));
  TS := TgoBsonTimestamp.Create(1, 2);
  Assert.AreEqual(TS.Value, Reader.ReadTimestamp);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual('Timestamp(1, 2)', V.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonReader.TestTimestampExtendedJsonOld;
const
  JSON = '{ "$timestamp" : NumberLong(1234) }';
var
  Reader: IgoJsonReader;
  V: TgoBsonValue;
begin
  Reader := TgoJsonReader.Create(JSON);

  Assert.AreEqual(Ord(TgoBsonType.Timestamp), Ord(Reader.ReadBsonType));
  Assert.AreEqual<Int64>(1234, Reader.ReadTimestamp);
  Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

  Reader := TgoJsonReader.Create(JSON);
  V := Reader.ReadValue;
  Assert.AreEqual('Timestamp(0, 1234)', V.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonReader.TestUndefined;
const
  TEST_CASES: array [0..1] of String = ('{ $undefined : true }', 'undefined');
var
  Reader: IgoJsonReader;
  I: Integer;
  V: TgoBsonValue;
begin
  for I := 0 to Length(TEST_CASES) - 1 do
  begin
    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    Reader.ReadUndefined;
    Assert.IsTrue(Reader.EndOfStream);
    Assert.AreEqual(Ord(TgoBsonReaderState.Initial), Ord(Reader.State));

    Reader := TgoJsonReader.Create(TEST_CASES[I]);
    V := Reader.ReadValue;
    Assert.AreEqual('undefined', V.ToJson(TgoJsonWriterSettings.Shell));
  end;
end;

{ TestJsonWriter }

procedure TestJsonWriter.JsonWriterShouldSupportWritingMultipleDocuments;
const
  DOCUMENT_SEPARATORS: array [0..2] of String = ('', ' ', #13#10);
var
  I, NumberOfDocuments, SeparatorIndex: Integer;
  Doc: TgoBsonDocument;
  Json, Expected: String;
  Writer: IgoJsonWriter;
begin
  for NumberOfDocuments := 0 to 3 do
  begin
    for SeparatorIndex := 0 to 2 do
    begin
      Doc := TgoBsonDocument.Create('x', 1);
      Json := Doc.ToJson;

      Expected := '';
      for I := 0 to NumberOfDocuments - 1 do
        Expected := Expected + Json + DOCUMENT_SEPARATORS[SeparatorIndex];

      Writer := TgoJsonWriter.Create;
      for I := 0 to NumberOfDocuments - 1 do
      begin
        Writer.WriteStartDocument;
        Writer.WriteName('x');
        Writer.WriteInt32(1);
        Writer.WriteEndDocument;
        Writer.WriteRaw(DOCUMENT_SEPARATORS[SeparatorIndex]);
      end;

      Assert.AreEqual(Expected, Writer.ToJson);
    end;
  end;
end;

procedure TestJsonWriter.TestArray;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('array',
    TgoBsonArray.Create([1, 2, 3]));

  Assert.AreEqual('{ "array" : [1, 2, 3] }', Doc.ToJson);
end;

procedure TestJsonWriter.TestBinaryShell;

  procedure Test(const AValue: TgoBsonValue; const AExpected: String);
  var
    Json: String;
    Actual: TgoBsonValue;
    Reader: IgoJsonReader;
  begin
    Json := AValue.ToJson(TgoJsonWriterSettings.Shell);
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;

    Assert.AreEqual(AValue.AsByteArray, Actual.AsByteArray);
  end;

begin
  Test(TBytes.Create(), 'new BinData(0, "")');
  Test(TBytes.Create(1), 'new BinData(0, "AQ==")');
  Test(TBytes.Create(1, 2), 'new BinData(0, "AQI=")');
  Test(TBytes.Create(1, 2, 3), 'new BinData(0, "AQID")');
  Test(TGuid.Empty, 'UUID("00000000-0000-0000-0000-000000000000")');
end;

procedure TestJsonWriter.TestBinaryStrict;
  procedure Test(const AValue: TgoBsonValue; const AExpected: String);
  var
    Json: String;
    Actual: TgoBsonValue;
    Reader: IgoJsonReader;
  begin
    Json := AValue.ToJson;
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;

    Assert.AreEqual(AValue.AsByteArray, Actual.AsByteArray);
  end;

begin
  Test(TBytes.Create(), '{ "$binary" : "", "$type" : "00" }');
  Test(TBytes.Create(1), '{ "$binary" : "AQ==", "$type" : "00" }');
  Test(TBytes.Create(1, 2), '{ "$binary" : "AQI=", "$type" : "00" }');
  Test(TBytes.Create(1, 2, 3), '{ "$binary" : "AQID", "$type" : "00" }');
  Test(TGuid.Empty, '{ "$binary" : "AAAAAAAAAAAAAAAAAAAAAA==", "$type" : "04" }');
end;

procedure TestJsonWriter.TestDateTimeShell;
var
  DT: TDateTime;

  procedure Test(const AValue: TgoBsonDateTime; const AExpected: String);
  var
    Json: String;
    Actual: TgoBsonValue;
    Reader: IgoJsonReader;
  begin
    Json := AValue.ToJson(TgoJsonWriterSettings.Shell);
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;

    Assert.AreEqual(AValue.MillisecondsSinceEpoch, Actual.AsBsonDateTime.MillisecondsSinceEpoch);
  end;

begin
  Test(TgoBsonDateTime.Create(Int64.MinValue), 'new Date(-9223372036854775808)');
  Test(TgoBsonDateTime.Create(0), 'ISODate("1970-01-01T00:00:00Z")');
  Test(TgoBsonDateTime.Create(Int64.MaxValue), 'new Date(9223372036854775807)');
  Test(TgoBsonDateTime.Create(UnixDateDelta, True), 'ISODate("1970-01-01T00:00:00Z")');

  DT := EncodeDateTime(2014, 4, 22, 10, 7, 23, 123);
  Test(TgoBsonDateTime.Create(DT, True), 'ISODate("2014-04-22T10:07:23.123Z")');
end;

procedure TestJsonWriter.TestDateTimeStrict;
var
  DT: TDateTime;

  procedure Test(const AValue: TgoBsonDateTime; const AExpected: String);
  var
    Json: String;
    Actual: TgoBsonValue;
    Reader: IgoJsonReader;
  begin
    Json := AValue.ToJson;
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;

    Assert.AreEqual(AValue.MillisecondsSinceEpoch, Actual.AsBsonDateTime.MillisecondsSinceEpoch);
  end;

begin
  Test(TgoBsonDateTime.Create(Int64.MinValue), '{ "$date" : -9223372036854775808 }');
  Test(TgoBsonDateTime.Create(0), '{ "$date" : 0 }');
  Test(TgoBsonDateTime.Create(Int64.MaxValue), '{ "$date" : 9223372036854775807 }');
  Test(TgoBsonDateTime.Create(UnixDateDelta, True), '{ "$date" : 0 }');

  DT := EncodeDateTime(2014, 4, 22, 10, 7, 23, 123);
  Test(TgoBsonDateTime.Create(DT, True), '{ "$date" : 1398161243123 }');
end;

procedure TestJsonWriter.TestDouble;

  procedure Test(const AValue: Double; const AExpected: String);
  var
    Value, Actual: TgoBsonValue;
    Json: String;
    Reader: IgoJsonReader;
  begin
    Value := AValue;
    Json := Value.ToJson;
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;

    if (AValue.IsNan) then
      Assert.IsTrue(Actual.AsDouble.IsNan)
    else if (AValue.IsInfinity) then
      Assert.IsTrue(Actual.AsDouble.IsInfinity)
    else
      Assert.IsTrue(SameValue(AValue, Actual.AsDouble));
  end;

begin
  Test(0.0, '0.0');
  Test(0.0005, '0.0005');
  Test(0.5, '0.5');
  Test(1.0, '1.0');
  Test(1.5, '1.5');
  Test(1.5E+40, '1.5E40');
  Test(1.5E-40, '1.5E-40');
  Test(1234567890.1234568E+123, '1.23456789012346E132');
  Test(Double.Epsilon, '4.94065645841247E-324');
//  Test(Double.MaxValue, '1.79769313486232E308'); // floating-point exception in Delphi
//  Test(Double.MinValue, '-1.7976931348623157E+308');
  Test(-0.0005, '-0.0005');
  Test(-0.5, '-0.5');
  Test(-1.0, '-1.0');
  Test(-1.5, '-1.5');
  Test(-1.5E+40, '-1.5E40');
  Test(-1.5E-40, '-1.5E-40');
  Test(-1234567890.1234568E+123, '-1.23456789012346E132');
  Test(-Double.Epsilon, '-4.94065645841247E-324');

  Test(Double.NaN, 'NaN');
  Test(Double.NegativeInfinity, '-Infinity');
  Test(Double.PositiveInfinity, 'Infinity');
end;

procedure TestJsonWriter.TestEmbeddedDocument;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('doc',
    TgoBsonDocument.Create('a', 1).Add('b', 2));

  Assert.AreEqual('{ "doc" : { "a" : 1, "b" : 2 } }', Doc.ToJson);
end;

procedure TestJsonWriter.TestEmptyDocument;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create;
  Assert.AreEqual('{ }', Doc.ToJson);
end;

procedure TestJsonWriter.TestGuid;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('guid', TGuid.Create('{B5F21E0C-2A0D-42d6-AD03-D827008D8AB6}'));

  Assert.AreEqual('{ "guid" : UUID("b5f21e0c-2a0d-42d6-ad03-d827008d8ab6") }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonWriter.TestInt64Shell;

  procedure Test(const AValue: Int64; const AExpected: String);
  var
    Value, Actual: TgoBsonValue;
    Json: String;
    Reader: IgoJsonReader;
  begin
    Value := AValue;
    Json := Value.ToJson(TgoJsonWriterSettings.Shell);
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;

    Assert.AreEqual(AValue, Actual.AsInt64);
  end;

begin
  Test(Int64.MinValue, 'NumberLong("-9223372036854775808")');
  Test(Int64(Integer.MinValue) - 1, 'NumberLong("-2147483649")');
  Test(Integer.MinValue, 'NumberLong(-2147483648)');
  Test(0, 'NumberLong(0)');
  Test(Integer.MaxValue, 'NumberLong(2147483647)');
  Test(Int64(Integer.MaxValue) + 1, 'NumberLong("2147483648")');
  Test(Int64.MaxValue, 'NumberLong("9223372036854775807")');
end;

procedure TestJsonWriter.TestInt64Strict;

  procedure Test(const AValue: Int64; const AExpected: String);
  var
    Value, Actual: TgoBsonValue;
    Json: String;
    Reader: IgoJsonReader;
  begin
    Value := AValue;
    Json := Value.ToJson;
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;
    Assert.AreEqual<Int64>(AValue, Actual);
  end;

begin
  Test(Int64.MinValue, '-9223372036854775808');
  Test(Int64(Integer.MinValue) - 1, '-2147483649');
  Test(Integer.MinValue, '-2147483648');
  Test(0, '0');
  Test(Integer.MaxValue, '2147483647');
  Test(Int64(Integer.MaxValue) + 1, '2147483648');
  Test(Int64.MaxValue, '9223372036854775807');
end;

procedure TestJsonWriter.TestJavaScript;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('f',
    TgoBsonJavaScript.Create('function f() { return 1; }'));

  Assert.AreEqual('{ "f" : { "$code" : "function f() { return 1; }" } }', Doc.ToJson);
end;

procedure TestJsonWriter.TestJavaScriptWithScope;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('f',
    TgoBsonJavaScriptWithScope.Create(
      'function f() { return n; }',
      TgoBsonDocument.Create('n', 1)));

  Assert.AreEqual('{ "f" : { "$code" : "function f() { return n; }", "$scope" : { "n" : 1 } } }', Doc.ToJson);
end;

procedure TestJsonWriter.TestMaxKey;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('maxkey', TgoBsonMaxKey.Value);
  Assert.AreEqual('{ "maxkey" : MaxKey }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonWriter.TestMinKey;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('minkey', TgoBsonMinKey.Value);
  Assert.AreEqual('{ "minkey" : MinKey }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonWriter.TestNull;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('null', TgoBsonNull.Value);
  Assert.AreEqual('{ "null" : null }', Doc.ToJson);
end;

procedure TestJsonWriter.TestObjectIdShell;
var
  Value, Actual: TgoBsonValue;
  Json: String;
  Reader: IgoJsonReader;
begin
  Value := TgoObjectId.Create('4d0ce088e447ad08b4721a37');
  Json := Value.ToJson(TgoJsonWriterSettings.Shell);
  Assert.AreEqual('ObjectId("4d0ce088e447ad08b4721a37")', Json);

  Reader := TgoJsonReader.Create(Json);
  Actual := Reader.ReadValue;
  Assert.IsTrue(Value.AsObjectId = Actual.AsObjectId);
end;

procedure TestJsonWriter.TestObjectIdStrict;
var
  Value, Actual: TgoBsonValue;
  Json: String;
  Reader: IgoJsonReader;
begin
  Value := TgoObjectId.Create('4d0ce088e447ad08b4721a37');
  Json := Value.ToJson;
  Assert.AreEqual('{ "$oid" : "4d0ce088e447ad08b4721a37" }', Json);

  Reader := TgoJsonReader.Create(Json);
  Actual := Reader.ReadValue;
  Assert.IsTrue(Value.AsObjectId = Actual.AsObjectId);
end;

procedure TestJsonWriter.TestPrettyPrintedEmbeddedDocument;
var
  Doc: TgoBsonDocument;
  Settings: TgoJsonWriterSettings;
begin
  Doc := TgoBsonDocument.Create('doc',
    TgoBsonDocument.Create('a', 1).Add('b', 2));

  Settings := TgoJsonWriterSettings.Create(True);
  Assert.AreEqual('{'#13#10'  "doc" : {'#13#10'    "a" : 1,'#13#10'    "b" : 2'#13#10'  }'#13#10'}', Doc.ToJson(Settings));
end;

procedure TestJsonWriter.TestPrettyPrintedEmptyDocument;
var
  Doc: TgoBsonDocument;
  Settings: TgoJsonWriterSettings;
begin
  Doc := TgoBsonDocument.Create;
  Settings := TgoJsonWriterSettings.Create(True);
  Assert.AreEqual('{ }', Doc.ToJson(Settings));
end;

procedure TestJsonWriter.TestPrettyPrintedOneElement;
var
  Doc: TgoBsonDocument;
  Settings: TgoJsonWriterSettings;
begin
  Doc := TgoBsonDocument.Create('name', 'value');
  Settings := TgoJsonWriterSettings.Create(True);
  Assert.AreEqual('{'#13#10'  "name" : "value"'#13#10'}', Doc.ToJson(Settings));
end;

procedure TestJsonWriter.TestPrettyPrintedTwoElements;
var
  Doc: TgoBsonDocument;
  Settings: TgoJsonWriterSettings;
begin
  Doc := TgoBsonDocument.Create('a', 'x').Add('b', 'y');
  Settings := TgoJsonWriterSettings.Create(True);
  Assert.AreEqual('{'#13#10'  "a" : "x",'#13#10'  "b" : "y"'#13#10'}', Doc.ToJson(Settings));
end;

procedure TestJsonWriter.TestRegularExpressionShell;

  procedure Test(const AValue: TgoBsonRegularExpression; const AExpected: String);
  var
    Json: String;
    Actual: TgoBsonValue;
    Reader: IgoJsonReader;
  begin
    Json := AValue.ToJson(TgoJsonWriterSettings.Shell);
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;

    Assert.IsTrue(AValue = Actual.AsBsonRegularExpression);
  end;

begin
  Test(TgoBsonRegularExpression.Create(''), '/(?:)/');
  Test(TgoBsonRegularExpression.Create('a'), '/a/');
  Test(TgoBsonRegularExpression.Create('a/b'), '/a\/b/');
  Test(TgoBsonRegularExpression.Create('a\b'), '/a\b/');
  Test(TgoBsonRegularExpression.Create('a', 'i'), '/a/i');
  Test(TgoBsonRegularExpression.Create('a', 'm'), '/a/m');
  Test(TgoBsonRegularExpression.Create('a', 'x'), '/a/x');
  Test(TgoBsonRegularExpression.Create('a', 's'), '/a/s');
  Test(TgoBsonRegularExpression.Create('a', 'imxs'), '/a/imxs');
end;

procedure TestJsonWriter.TestRegularExpressionStrict;

  procedure Test(const AValue: TgoBsonRegularExpression; const AExpected: String);
  var
    Json: String;
    Actual: TgoBsonValue;
    Reader: IgoJsonReader;
  begin
    Json := AValue.ToJson;
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;

    Assert.IsTrue(AValue = Actual.AsBsonRegularExpression);
  end;

begin
  Test(TgoBsonRegularExpression.Create(''), '{ "$regex" : "", "$options" : "" }');
  Test(TgoBsonRegularExpression.Create('a'), '{ "$regex" : "a", "$options" : "" }');
  Test(TgoBsonRegularExpression.Create('a/b'), '{ "$regex" : "a/b", "$options" : "" }');
  Test(TgoBsonRegularExpression.Create('a\b'), '{ "$regex" : "a\\b", "$options" : "" }');
  Test(TgoBsonRegularExpression.Create('a', 'i'), '{ "$regex" : "a", "$options" : "i" }');
  Test(TgoBsonRegularExpression.Create('a', 'm'), '{ "$regex" : "a", "$options" : "m" }');
  Test(TgoBsonRegularExpression.Create('a', 'x'), '{ "$regex" : "a", "$options" : "x" }');
  Test(TgoBsonRegularExpression.Create('a', 's'), '{ "$regex" : "a", "$options" : "s" }');
  Test(TgoBsonRegularExpression.Create('a', 'imxs'), '{ "$regex" : "a", "$options" : "imxs" }');
end;

procedure TestJsonWriter.TestSampleDocument;
var
  Writer: IgoJsonWriter;
begin
  Writer := TgoJsonWriter.Create;
  Writer.WriteStartDocument;
    Writer.WriteStartDocument('tester');
      Writer.WriteString('email', 'tester@grijjy.com');
      Writer.WriteStartDocument('profile');
        Writer.WriteString('first_name', 'John');
        Writer.WriteString('last_name', 'Doe');
      Writer.WriteEndDocument;
    Writer.WriteEndDocument;
  Writer.WriteEndDocument;

  Assert.AreEqual('{ "tester" : { "email" : "tester@grijjy.com", "profile" : { "first_name" : "John", "last_name" : "Doe" } } }', Writer.ToJson);

  Writer := TgoJsonWriter.Create;
  Writer.WriteStartDocument;
    Writer.WriteName('tester');
    Writer.WriteStartDocument;
      Writer.WriteString('email', 'tester@grijjy.com');
      Writer.WriteName('profile');
      Writer.WriteStartDocument;
        Writer.WriteString('first_name', 'John');
        Writer.WriteString('last_name', 'Doe');
      Writer.WriteEndDocument;
    Writer.WriteEndDocument;
  Writer.WriteEndDocument;

  Assert.AreEqual('{ "tester" : { "email" : "tester@grijjy.com", "profile" : { "first_name" : "John", "last_name" : "Doe" } } }', Writer.ToJson);
end;

procedure TestJsonWriter.TestSingleString;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('abc', 'xyz');
  Assert.AreEqual('{ "abc" : "xyz" }', Doc.ToJson);
end;

procedure TestJsonWriter.TestString;

  procedure Test(const AValue: TgoBsonValue; const AExpected: String);
  var
    Json: String;
    Actual: TgoBsonValue;
    Reader: IgoJsonReader;
  begin
    Json := AValue.ToJson;
    Assert.AreEqual(AExpected, Json);

    Reader := TgoJsonReader.Create(Json);
    Actual := Reader.ReadValue;

    Assert.AreEqual(Actual.AsString, AValue.AsString);
  end;

begin
  Test('', '""');
  Test(' ', '" "');
  Test('a', '"a"');
  Test('ab', '"ab"');
  Test('abc', '"abc"');
  Test('abc'#0'def', '"abc\u0000def"');
  Test('''', '"''"');
  Test('"', '"\""');
  Test(#0, '"\u0000"');
  Test(#7, '"\u0007"');
  Test(#8, '"\b"');
  Test(#12, '"\f"');
  Test(#10, '"\n"');
  Test(#13, '"\r"');
  Test(#9, '"\t"');
  Test(#11, '"\u000b"');
  Test(#$0080, '"\u0080"');
  Test(#$0080#$0081, '"\u0080\u0081"');
  Test(#$0080#$0081#$0082, '"\u0080\u0081\u0082"');
end;

procedure TestJsonWriter.TestSymbol;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('symbol', TgoBsonSymbolTable.Lookup('name'));
  Assert.AreEqual('{ "symbol" : { "$symbol" : "name" } }', Doc.ToJson);
end;

procedure TestJsonWriter.TestTimestamp;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('timestamp', TgoBsonTimestamp.Create(1, 2));
  Assert.AreEqual('{ "timestamp" : Timestamp(1, 2) }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestJsonWriter.TestUndefined;
var
  Doc: TgoBsonDocument;
begin
  Doc := TgoBsonDocument.Create('undefined', TgoBsonUndefined.Value);
  Assert.AreEqual('{ "undefined" : undefined }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

{ TestBsonWriter }

procedure TestBsonWriter.BsonWriterShouldSupportWritingMultipleDocuments;
var
  NumberOfDocuments, I: Integer;
  Doc: TgoBsonDocument;
  Bson, Expected, Actual: TBytes;
  Writer: IgoBsonWriter;
begin
  for NumberOfDocuments := 0 to 3 do
  begin
    Doc := TgoBsonDocument.Create('x', 1);
    Bson := Doc.ToBson;

    Expected := nil;
    for I := 0 to NumberOfDocuments - 1 do
      Expected := Expected + Bson;

    Writer := TgoBsonWriter.Create;
    for I := 0 to NumberOfDocuments - 1 do
    begin
      Writer.WriteStartDocument;
      Writer.WriteName('x');
      Writer.WriteInt32(1);
      Writer.WriteEndDocument;
    end;
    Actual := Writer.ToBson;
    Assert.AreEqual(Expected, Actual);
  end;
end;

{ TestBsonBuffer }

procedure TestBsonBuffer.TestReadCStringEmpty;
var
  Bytes: TBytes;
  Doc: TgoBsonDocument;
begin
  Bytes := TBytes.Create(8, 0, 0, 0, Ord(TgoBsonType.Boolean), 0, 0, 0);
  Assert.AreEqual(8, Length(Bytes));
  Doc := TgoBsonDocument.Load(Bytes);
  Assert.AreEqual('', Doc.Elements[0].Name);
end;

procedure TestBsonBuffer.TestReadCStringOneCharacter;
var
  Bytes: TBytes;
  Doc: TgoBsonDocument;
begin
  Bytes := TBytes.Create(9, 0, 0, 0, Ord(TgoBsonType.Boolean), Ord('b'), 0, 0, 0);
  Assert.AreEqual(9, Length(Bytes));
  Doc := TgoBsonDocument.Load(Bytes);
  Assert.AreEqual('b', Doc.Elements[0].Name);
end;

procedure TestBsonBuffer.TestReadCStringOneCharacterDecoderException;
var
  Bytes: TBytes;
begin
  Bytes := TBytes.Create(9, 0, 0, 0, Ord(TgoBsonType.Boolean), $80, 0, 0, 0);
  Assert.AreEqual(9, Length(Bytes));
  Assert.WillRaise(
    procedure
    begin
      TgoBsonDocument.Load(Bytes);
    end, EEncodingError);
end;

procedure TestBsonBuffer.TestReadCStringTwoCharacters;
var
  Bytes: TBytes;
  Doc: TgoBsonDocument;
begin
  Bytes := TBytes.Create(10, 0, 0, 0, Ord(TgoBsonType.Boolean), Ord('b'), Ord('b'), 0, 0, 0);
  Assert.AreEqual(10, Length(Bytes));
  Doc := TgoBsonDocument.Load(Bytes);
  Assert.AreEqual('bb', Doc.Elements[0].Name);
end;

procedure TestBsonBuffer.TestReadCStringTwoCharactersDecoderException;
var
  Bytes: TBytes;
begin
  Bytes := TBytes.Create(10, 0, 0, 0, Ord(TgoBsonType.Boolean), Ord('b'), $80, 0, 0, 0);
  Assert.AreEqual(10, Length(Bytes));
  Assert.WillRaise(
    procedure
    begin
      TgoBsonDocument.Load(Bytes);
    end, EEncodingError);
end;

procedure TestBsonBuffer.TestReadStringEmpty;
var
  Bytes: TBytes;
  Doc: TgoBsonDocument;
begin
  Bytes := TBytes.Create(13, 0, 0, 0, Ord(TgoBsonType.String), Ord('s'), 0, 1, 0, 0, 0, 0, 0);
  Assert.AreEqual(13, Length(Bytes));
  Doc := TgoBsonDocument.Load(Bytes);
  Assert.AreEqual<String>('', Doc['s']);
end;

procedure TestBsonBuffer.TestReadStringInvalidLength;
var
  Bytes: TBytes;
begin
  Bytes := TBytes.Create(13, 0, 0, 0, Ord(TgoBsonType.String), Ord('s'), 0, 0, 0, 0, 0, 0, 0);
  Assert.AreEqual(13, Length(Bytes));
  Assert.WillRaise(
    procedure
    begin
      TgoBsonDocument.Load(Bytes);
    end, EInvalidOperation);
end;

procedure TestBsonBuffer.TestReadStringMissingNullTerminator;
var
  Bytes: TBytes;
begin
  Bytes := TBytes.Create(13, 0, 0, 0, Ord(TgoBsonType.String), Ord('s'), 0, 1, 0, 0, 0, 123, 0);
  Assert.AreEqual(13, Length(Bytes));
  Assert.WillRaise(
    procedure
    begin
      TgoBsonDocument.Load(Bytes);
    end, EInvalidOperation);
end;

procedure TestBsonBuffer.TestReadStringOneCharacter;
var
  Bytes: TBytes;
  Doc: TgoBsonDocument;
begin
  Bytes := TBytes.Create(14, 0, 0, 0, Ord(TgoBsonType.String), Ord('s'), 0, 2, 0, 0, 0, Ord('x'), 0, 0);
  Assert.AreEqual(14, Length(Bytes));
  Doc := TgoBsonDocument.Load(Bytes);
  Assert.AreEqual<String>('x', Doc['s']);
end;

procedure TestBsonBuffer.TestReadStringOneCharacterDecoderException;
var
  Bytes: TBytes;
begin
  Bytes := TBytes.Create(14, 0, 0, 0, Ord(TgoBsonType.String), Ord('s'), 0, 2, 0, 0, 0, $80, 0, 0);
  Assert.AreEqual(14, Length(Bytes));
  Assert.WillRaise(
    procedure
    begin
      TgoBsonDocument.Load(Bytes);
    end, EEncodingError);
end;

procedure TestBsonBuffer.TestReadStringTwoCharacters;
var
  Bytes: TBytes;
  Doc: TgoBsonDocument;
begin
  Bytes := TBytes.Create(15, 0, 0, 0, Ord(TgoBsonType.String), Ord('s'), 0, 3, 0, 0, 0, Ord('x'), Ord('y'), 0, 0);
  Assert.AreEqual(15, Length(Bytes));
  Doc := TgoBsonDocument.Load(Bytes);
  Assert.AreEqual<String>('xy', Doc['s']);
end;

procedure TestBsonBuffer.TestReadStringTwoCharactersDecoderException;
var
  Bytes: TBytes;
begin
  Bytes := TBytes.Create(15, 0, 0, 0, Ord(TgoBsonType.String), Ord('s'), 0, 3, 0, 0, 0, Ord('x'), $80, 0, 0);
  Assert.AreEqual(15, Length(Bytes));
  Assert.WillRaise(
    procedure
    begin
      TgoBsonDocument.Load(Bytes);
    end, EEncodingError);
end;

{ TestBsonRoundTrip }

procedure TestBsonRoundTrip.TestAllTypes;
var
  D1, D2: TgoBsonDocument;
  B1, B2: TBytes;
begin
  D1 := TgoBsonDocument.Create;
  D1.Add('double', 1.23);
  D1.Add('string', 'rosebud');
  D1.Add('document', TgoBsonDocument.Create('hello', 'world'));
  D1.Add('array', TgoBsonArray.Create([1, 2, 3]));
  D1.Add('binary', TBytes.Create(1, 2, 3));
  D1.Add('objectid', TgoObjectId.Create('0102030405060708090a0b0c'));
  D1.Add('boolean1', False);
  D1.Add('boolean2', True);
  B1 := D1.ToBson;

  D2 := TgoBsonDocument.Load(B1);
  B2 := D2.ToBson;

  Assert.AreEqual(B1, B2);
end;

procedure TestBsonRoundTrip.TestBsonIsAwesome;
var
  D1, D2: TgoBsonDocument;
  B1, B2: TBytes;
begin
  D1 := TgoBsonDocument.Create('BSON', TgoBsonArray.Create(['awesome', 5.05, 1986]));
  B1 := D1.ToBson;

  D2 := TgoBsonDocument.Load(B1);
  B2 := D2.ToBson;

  Assert.AreEqual(B1, B2);
end;

procedure TestBsonRoundTrip.TestHelloWorld;
var
  D1, D2: TgoBsonDocument;
  B1, B2: TBytes;
begin
  D1 := TgoBsonDocument.Create('hello', 'world');
  B1 := D1.ToBson;

  D2 := TgoBsonDocument.Load(B1);
  B2 := D2.ToBson;

  Assert.AreEqual(B1, B2);
end;

{ TestJsonData }

procedure TestJsonData.TestJsonFile(const BaseFilename: String);
{ These tests originate from JsonCpp:
  https://github.com/open-source-parsers/jsoncpp }
var
  JsonFilename, ExpectedFilename: String;
  Reader: IgoJsonReader;
  Actual, Expected: UnicodeString;
  Value: TgoBsonValue;
  Builder: TStringBuilder;
begin
  JsonFilename := 'data/' + BaseFilename + '.json';
  ExpectedFilename := 'data/' + BaseFilename + '.expected';

  Reader := TgoJsonReader.Create(LoadTestString(JsonFilename));
  Value := Reader.ReadValue;
  Assert.IsFalse(Value.IsNil);
  Builder := TStringBuilder.Create;
  try
    WriteValueTree(Builder, Value);
    Actual := Trim(Builder.ToString);
  finally
    Builder.Free;
  end;

  Expected := LoadTestString(ExpectedFilename);
  Actual := Actual.Replace(#13#10, #10, [rfReplaceAll]).Trim;
  Expected := Expected.Replace(#13#10, #10, [rfReplaceAll]).Trim;
  Assert.AreEqual(Expected, Actual);
end;

procedure TestJsonData.test_array_01;
begin
  TestJsonFile('test_array_01');
end;

procedure TestJsonData.test_array_02;
begin
  TestJsonFile('test_array_02');
end;

procedure TestJsonData.test_array_03;
begin
  TestJsonFile('test_array_03');
end;

procedure TestJsonData.test_array_04;
begin
  TestJsonFile('test_array_04');
end;

procedure TestJsonData.test_array_05;
begin
  TestJsonFile('test_array_05');
end;

procedure TestJsonData.test_array_06;
begin
  TestJsonFile('test_array_06');
end;

//procedure TestJsonData.test_basic_01;
//begin
//  TestJsonFile('test_basic_01');
//end;

//procedure TestJsonData.test_basic_02;
//begin
//  TestJsonFile('test_basic_02');
//end;

procedure TestJsonData.test_basic_03;
begin
  TestJsonFile('test_basic_03');
end;

procedure TestJsonData.test_basic_04;
begin
  TestJsonFile('test_basic_04');
end;

procedure TestJsonData.test_basic_05;
begin
  TestJsonFile('test_basic_05');
end;

procedure TestJsonData.test_basic_06;
begin
  TestJsonFile('test_basic_06');
end;

procedure TestJsonData.test_basic_07;
begin
  TestJsonFile('test_basic_07');
end;

//procedure TestJsonData.test_basic_08;
//begin
//  TestJsonFile('test_basic_08');
//end;

//procedure TestJsonData.test_basic_09;
//begin
//  TestJsonFile('test_basic_09');
//end;

//procedure TestJsonData.test_comment_01;
//begin
//  TestJsonFile('test_comment_01');
//end;

procedure TestJsonData.test_complex_01;
begin
  TestJsonFile('test_complex_01');
end;

procedure TestJsonData.test_integer_01;
begin
  TestJsonFile('test_integer_01');
end;

procedure TestJsonData.test_integer_02;
begin
  TestJsonFile('test_integer_02');
end;

procedure TestJsonData.test_integer_03;
begin
  TestJsonFile('test_integer_03');
end;

procedure TestJsonData.test_integer_04;
begin
  TestJsonFile('test_integer_04');
end;

procedure TestJsonData.test_integer_05;
begin
  TestJsonFile('test_integer_05');
end;

procedure TestJsonData.test_large_01;
begin
  TestJsonFile('test_large_01');
end;

procedure TestJsonData.test_object_01;
begin
  TestJsonFile('test_object_01');
end;

procedure TestJsonData.test_object_02;
begin
  TestJsonFile('test_object_02');
end;

procedure TestJsonData.test_object_03;
begin
  TestJsonFile('test_object_03');
end;

procedure TestJsonData.test_object_04;
begin
  TestJsonFile('test_object_04');
end;

//procedure TestJsonData.test_preserve_comment_01;
//begin
//  TestJsonFile('test_preserve_comment_01');
//end;

procedure TestJsonData.test_real_01;
begin
  TestJsonFile('test_real_01');
end;

procedure TestJsonData.test_real_02;
begin
  TestJsonFile('test_real_02');
end;

procedure TestJsonData.test_real_03;
begin
  TestJsonFile('test_real_03');
end;

procedure TestJsonData.test_real_04;
begin
  TestJsonFile('test_real_04');
end;

procedure TestJsonData.test_real_05;
begin
  TestJsonFile('test_real_05');
end;

procedure TestJsonData.test_real_06;
begin
  TestJsonFile('test_real_06');
end;

procedure TestJsonData.test_real_07;
begin
  TestJsonFile('test_real_07');
end;

procedure TestJsonData.test_string_01;
begin
  TestJsonFile('test_string_01');
end;

procedure TestJsonData.test_string_02;
begin
  TestJsonFile('test_string_02');
end;

procedure TestJsonData.test_string_unicode_01;
begin
  TestJsonFile('test_string_unicode_01');
end;

procedure TestJsonData.test_string_unicode_02;
begin
  TestJsonFile('test_string_unicode_02');
end;

procedure TestJsonData.test_string_unicode_03;
begin
  TestJsonFile('test_string_unicode_03');
end;

procedure TestJsonData.test_string_unicode_04;
begin
  TestJsonFile('test_string_unicode_04');
end;

procedure TestJsonData.test_string_unicode_05;
begin
  TestJsonFile('test_string_unicode_05');
end;

procedure TestJsonData.WriteValueTree(const Builder: TStringBuilder;
  const Value: TgoBsonValue; const Path: UnicodeString);

  procedure WriteLine(const S: UnicodeString; const Args: array of const);
  begin
    Builder.Append(Format(S, Args, goUSFormatSettings)).AppendLine;
  end;

var
  I: Integer;
  A: TgoBsonArray;
  Elements: TArray<TgoBsonElement>;
  Suffix: String;
begin
  case Value.BsonType of
    TgoBsonType.Null:
      WriteLine('%s=null', [Path]);

    TgoBsonType.Int32:
      WriteLine('%s=%d', [Path, Value.AsInteger]);

    TgoBsonType.Int64:
      WriteLine('%s=%d', [Path, Value.AsInt64]);

    TgoBsonType.Double:
      WriteLine('%s=%.16g', [Path, Value.AsDouble]);

    TgoBsonType.String:
      WriteLine('%s="%s"', [Path, Value.AsString]);

    TgoBsonType.Boolean:
      if Value.AsBoolean then
        WriteLine('%s=true', [Path])
      else
        WriteLine('%s=false', [Path]);

    TgoBsonType.&Array:
      begin
        WriteLine('%s=[]', [Path]);
        A := Value.AsBsonArray;
        for I := 0 to A.Count - 1 do
          WriteValueTree(Builder, A[I], Format('%s[%d]', [Path, I]));
      end;

    TgoBsonType.Document:
      begin
        WriteLine('%s={}', [Path]);
        Elements := Value.AsBsonDocument.ToArray;
        TArray.Sort<TgoBsonElement>(Elements, TComparer<TgoBsonElement>.Construct(
          function (const ALeft, ARight: TgoBsonElement): Integer
          begin
            Result := CompareText(ALeft.Name, ARight.Name);
          end));

        if (Path <> '') and (Path[Length(Path) - 1 + Low(Path)] = '.') then
          Suffix := ''
        else
          Suffix := '.';

        for I := 0 to Length(Elements) - 1 do
          WriteValueTree(Builder, Elements[I].Value, Path + Suffix + Elements[I].Name);
      end;
  end;
end;

{ TestJsonChecker }

procedure TestJsonChecker.TestFail(const Filename: String; const ErrorLine,
  ErrorColumn: Integer);
var
  JsonFilename: String;
  Reader: IgoJsonReader;
  Value: TgoBsonValue;
begin
  JsonFilename := 'jsonchecker/' + Filename;

  Reader := TgoJsonReader.Create(LoadTestString(JsonFilename));
  try
    Value := Reader.ReadValue;
  except
    on E: EgoJsonParserError do
    begin
      Assert.AreEqual(ErrorLine, E.LineNumber);
      Assert.AreEqual(ErrorColumn, E.ColumnNumber);
      Exit;
    end
    else
      raise;
  end;
  Assert.Fail('EgoJsonParserError exception expected');
end;

procedure TestJsonChecker.TestPass(const Filename: String);
var
  JsonFilename: String;
  Reader: IgoJsonReader;
  Value: TgoBsonValue;
begin
  JsonFilename := 'jsonchecker/' + Filename;
  Reader := TgoJsonReader.Create(LoadTestString(JsonFilename));
  Value := Reader.ReadValue;
  Assert.IsFalse(Value.IsNil);
end;

{procedure TestJsonChecker.test_fail1;
begin
  // We allow root values of type String
  TestFail('fail1.json', 0, 0);
end;}

{procedure TestJsonChecker.test_fail10;
begin
  // We allow data after close
  TestFail('fail10.json', 0, 0);
end;}

procedure TestJsonChecker.test_fail11;
begin
  TestFail('fail11.json', 1, 26);
end;

procedure TestJsonChecker.test_fail12;
begin
  TestFail('fail12.json', 1, 24);
end;

procedure TestJsonChecker.test_fail13;
begin
  TestFail('fail13.json', 1, 42);
end;

procedure TestJsonChecker.test_fail14;
begin
  TestFail('fail14.json', 1, 27);
end;

procedure TestJsonChecker.test_fail15;
begin
  TestFail('fail15.json', 1, 30);
end;

procedure TestJsonChecker.test_fail16;
begin
  TestFail('fail16.json', 1, 2);
end;

procedure TestJsonChecker.test_fail17;
begin
  TestFail('fail17.json', 1, 30);
end;

{procedure TestJsonChecker.test_fail18;
begin
  // We allow unlimited depth
  TestFail('fail18.json', 0, 0);
end;}

procedure TestJsonChecker.test_fail19;
begin
  TestFail('fail19.json', 1, 18);
end;

procedure TestJsonChecker.test_fail2;
begin
  TestFail('fail2.json', 1, 17);
end;

procedure TestJsonChecker.test_fail20;
begin
  TestFail('fail20.json', 1, 17);
end;

procedure TestJsonChecker.test_fail21;
begin
  TestFail('fail21.json', 1, 26);
end;

procedure TestJsonChecker.test_fail22;
begin
  TestFail('fail22.json', 1, 26);
end;

procedure TestJsonChecker.test_fail23;
begin
  TestFail('fail23.json', 1, 15);
end;

{procedure TestJsonChecker.test_fail24;
begin
  // We allow strings with single quotes
  TestFail('fail24.json', 1, 2);
end;}

{procedure TestJsonChecker.test_fail25;
begin
  // We allow tabs in strings
  TestFail('fail25.json', 0, 0);
end;}

procedure TestJsonChecker.test_fail26;
begin
  TestFail('fail26.json', 1, 7);
end;

{procedure TestJsonChecker.test_fail27;
begin
  // We allow line breaks in strings
  TestFail('fail27.json', 0, 0);
end;}

procedure TestJsonChecker.test_fail28;
begin
  TestFail('fail28.json', 1, 8);
end;

procedure TestJsonChecker.test_fail29;
begin
  TestFail('fail29.json', 1, 3);
end;

{procedure TestJsonChecker.test_fail3;
begin
  // We allow unquoted key names
  TestFail('fail3.json', 1, 2);
end;}

procedure TestJsonChecker.test_fail30;
begin
  TestFail('fail30.json', 1, 4);
end;

procedure TestJsonChecker.test_fail31;
begin
  TestFail('fail31.json', 1, 4);
end;

procedure TestJsonChecker.test_fail32;
begin
  TestFail('fail32.json', 1, 40);
end;

procedure TestJsonChecker.test_fail33;
begin
  TestFail('fail33.json', 1, 12);
end;

{procedure TestJsonChecker.test_fail4;
begin
  // We allow extra commas
  TestFail('fail4.json', 1, 16);
end;}

procedure TestJsonChecker.test_fail5;
begin
  TestFail('fail5.json', 1, 23);
end;

procedure TestJsonChecker.test_fail6;
begin
  TestFail('fail6.json', 1, 5);
end;

{procedure TestJsonChecker.test_fail7;
begin
  // We allow comma after close
  TestFail('fail7.json', 0, 0);
end;}

{procedure TestJsonChecker.test_fail8;
begin
  // We allow extra close bracket
  TestFail('fail8.json', 0, 0);
end;}

{procedure TestJsonChecker.test_fail9;
begin
  // We allow extra commas
  TestFail('fail9.json', 1, 22);
end;}

procedure TestJsonChecker.test_pass1;
begin
  TestPass('pass1.json');
end;

procedure TestJsonChecker.test_pass2;
begin
  TestPass('pass2.json');
end;

procedure TestJsonChecker.test_pass3;
begin
  TestPass('pass3.json');
end;

{ TestJsonToBson }

procedure TestJsonToBson.TestAllTypes;
var
  JsonDoc, BsonDoc: TgoBsonDocument;
  Bson: TBytes;
begin
  JsonDoc := TgoBsonDocument.Parse(LoadTestString('documents/document1.json'));

  Bson := JsonDoc.ToBson;
  BsonDoc := TgoBsonDocument.Load(Bson);

  Assert.IsTrue(JsonDoc = BsonDoc);
end;

procedure TestJsonToBson.TestSingleTypes;
var
  I: Integer;
  BaseFilename: String;
  JsonDoc, BsonDoc: TgoBsonDocument;
  Bson: TBytes;
begin
  for I := $01 to $12 do
  begin
    BaseFilename := 'documents/Data' + IntToHex(I, 2);

    JsonDoc := TgoBsonDocument.Parse(LoadTestString(BaseFilename + '.json'));
    BsonDoc := TgoBsonDocument.Load(LoadTestData(BaseFilename + '.bson'));
    Assert.IsTrue(JsonDoc = BsonDoc);

    Bson := JsonDoc.ToBson;
    BsonDoc := TgoBsonDocument.Load(Bson);
    Assert.IsTrue(JsonDoc = BsonDoc);
  end;
end;

{ TestBsonDocumentWriter }

procedure TestBsonDocumentWriter.TestArrayWithNestedArrayWithOneElement;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartArray('a');
  Writer.WriteStartArray;
  Writer.WriteString('a');
  Writer.WriteEndArray;
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : [["a"]] }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestArrayWithNestedArrayWithTwoElements;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartArray('a');
  Writer.WriteStartArray;
  Writer.WriteString('a');
  Writer.WriteString('b');
  Writer.WriteEndArray;
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : [["a", "b"]] }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestArrayWithNestedEmptyArray;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartArray('a');
  Writer.WriteStartArray;
  Writer.WriteEndArray;
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : [[]] }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestArrayWithOneElement;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartArray('a');
  Writer.WriteInt32(1);
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : [1] }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestArrayWithTwoElements;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartArray('a');
  Writer.WriteInt32(1);
  Writer.WriteInt32(2);
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : [1, 2] }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestArrayWithTwoNestedArrays;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartArray('a');
  Writer.WriteStartArray;
  Writer.WriteString('a');
  Writer.WriteString('b');
  Writer.WriteEndArray;
  Writer.WriteStartArray;
  Writer.WriteString('c');
  Writer.WriteStartDocument;
  Writer.WriteInt32('d', 9);
  Writer.WriteEndDocument;
  Writer.WriteEndArray;
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : [["a", "b"], ["c", { "d" : 9 }]] }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestEmptyDocument;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestInt32;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteInt32('a', 1);
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : 1 }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestInt64;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteInt64('a', 1);
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : NumberLong(1) }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestJavaScript;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteJavaScript('a', 'x');
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : { "$code" : "x" } }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestJavaScriptWithScope;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteJavaScriptWithScope('a', 'x');
  Writer.WriteStartDocument;
  Writer.WriteInt32('x', 1);
  Writer.WriteInt32('y', 2);
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : { "$code" : "x", "$scope" : { "x" : 1, "y" : 2 } } }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestMaxKey;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteMaxKey('a');
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : MaxKey }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestMinKey;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteMinKey('a');
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : MinKey }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestNull;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteNull('a');
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : null }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestObjectId;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteObjectId('a', TgoObjectId.Empty);
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : ObjectId("000000000000000000000000") }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestOneBinary;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteBytes('a', TBytes.Create(1));
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : new BinData(0, "AQ==") }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestBoolean;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteBoolean('a', True);
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : true }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestDateTime;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteDateTime('a', 0);
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : ISODate("1970-01-01T00:00:00Z") }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestDouble;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteDouble('a', 1.5);
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : 1.5 }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestOneEmptyArray;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartArray('a');
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : [] }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestOneEmptyDocument;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartDocument('a');
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : { } }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestOneNestedBinary;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartDocument('nested');
  Writer.WriteBytes('a', TBytes.Create(1, 2));
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "nested" : { "a" : new BinData(0, "AQI=") } }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestOneNestedEmptyArray;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartDocument('nested');
  Writer.WriteStartArray('a');
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "nested" : { "a" : [] } }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestOneNestedEmptyDocument;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartDocument('nested');
  Writer.WriteStartDocument('a');
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "nested" : { "a" : { } } }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestRegularExpression;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteRegularExpression('a', TgoBsonRegularExpression.Create('p', 'i'));
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : /p/i }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestString;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteString('a', 'x');
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : "x" }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestSymbol;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteSymbol('a', 'x');
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : { "$symbol" : "x" } }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestTimestamp;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteTimestamp('a', 1);
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : Timestamp(0, 1) }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestTwoBinaries;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteBytes('a', TBytes.Create(1));
  Writer.WriteBytes('b', TBytes.Create(2));
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : new BinData(0, "AQ=="), "b" : new BinData(0, "Ag==") }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestTwoEmptyArrays;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartArray('a');
  Writer.WriteEndArray;
  Writer.WriteStartArray('b');
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : [], "b" : [] }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestTwoEmptyDocuments;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartDocument('a');
  Writer.WriteEndDocument;
  Writer.WriteStartDocument('b');
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : { }, "b" : { } }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestTwoNestedBinaries;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartDocument('nested');
  Writer.WriteBytes('a', TBytes.Create(1));
  Writer.WriteBytes('b', TBytes.Create(2));
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "nested" : { "a" : new BinData(0, "AQ=="), "b" : new BinData(0, "Ag==") } }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

procedure TestBsonDocumentWriter.TestTwoNestedEmptyArrays;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartDocument('nested');
  Writer.WriteStartArray('a');
  Writer.WriteEndArray;
  Writer.WriteStartArray('b');
  Writer.WriteEndArray;
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "nested" : { "a" : [], "b" : [] } }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestTwoNestedEmptyDocuments;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteStartDocument('nested');
  Writer.WriteStartDocument('a');
  Writer.WriteEndDocument;
  Writer.WriteStartDocument('b');
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "nested" : { "a" : { }, "b" : { } } }', Doc.ToJson);
end;

procedure TestBsonDocumentWriter.TestUndefined;
var
  Doc: TgoBsonDocument;
  Writer: IgoBsonDocumentWriter;
begin
  Doc := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(Doc);
  Writer.WriteStartDocument;
  Writer.WriteUndefined('a');
  Writer.WriteEndDocument;
  Assert.AreEqual('{ "a" : undefined }', Doc.ToJson(TgoJsonWriterSettings.Shell));
end;

{ TestBsonDocumentReader }

procedure TestBsonDocumentReader.Test(const ADocument: TgoBsonDocument);
var
  Rehydrated: TgoBsonDocument;
  Reader: IgoBsonDocumentReader;
begin
  Reader := TgoBsonDocumentReader.Create(ADocument);
  Rehydrated := Reader.ReadDocument;

  Assert.IsFalse(ReferenceEquals(ADocument, Rehydrated));
  Assert.IsTrue(ADocument = Rehydrated);
  Assert.AreEqual(ADocument.ToJson, Rehydrated.ToJson);
end;

procedure TestBsonDocumentReader.TestArray;
begin
  Test(TgoBsonDocument.Create('array', TgoBsonArray.Create([1, 2, 3])));
end;

procedure TestBsonDocumentReader.TestBinary;
begin
  Test(TgoBsonDocument.Create('bin', TBytes.Create(1, 2, 3)));
end;

procedure TestBsonDocumentReader.TestBookmark;
const
  JSON = '{ "x" : 1, "y" : 2 }';
var
  Doc: TgoBsonDocument;
  Reader: IgoBsonDocumentReader;
  Bookmark: IgoBsonReaderBookmark;
begin
  Doc := TgoBsonDocument.Parse(JSON);

  Reader := TgoBsonDocumentReader.Create(Doc);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.Document), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Reader.ReadStartDocument;
  Reader.ReturnToBookmark(Bookmark);
  Reader.ReadStartDocument;

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual('x', Reader.ReadName);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual('x', Reader.ReadName);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(1, Reader.ReadInt32);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(1, Reader.ReadInt32);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.Int32), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual('y', Reader.ReadName);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual('y', Reader.ReadName);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(2, Reader.ReadInt32);
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(2, Reader.ReadInt32);

  Bookmark := Reader.GetBookmark;
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));
  Reader.ReturnToBookmark(Bookmark);
  Assert.AreEqual(Ord(TgoBsonType.EndOfDocument), Ord(Reader.ReadBsonType));

  Bookmark := Reader.GetBookmark;
  Reader.ReadEndDocument;
  Reader.ReturnToBookmark(Bookmark);
  Reader.ReadEndDocument;

  Assert.AreEqual(Ord(TgoBsonReaderState.Done), Ord(Reader.State));
end;

procedure TestBsonDocumentReader.TestBoolean;
begin
  Test(TgoBsonDocument.Create('bool', True));
end;

procedure TestBsonDocumentReader.TestBytes;
begin
  Test(TgoBsonDocument.Create('bytes', TBytes.Create(1, 2, 3)));
end;

procedure TestBsonDocumentReader.TestDateTime;
begin
  Test(TgoBsonDocument.Create('date', EncodeDate(2010, 1, 1)));
end;

procedure TestBsonDocumentReader.TestDouble;
begin
  Test(TgoBsonDocument.Create('doc', 1.5));
end;

procedure TestBsonDocumentReader.TestEmbeddedDocument;
begin
  Test(TgoBsonDocument.Create('doc', TgoBsonDocument.Create('a', 1).Add('b', 2)));
end;

procedure TestBsonDocumentReader.TestEmptyDocument;
begin
  Test(TgoBsonDocument.Create);
end;

procedure TestBsonDocumentReader.TestGuid;
begin
  Test(TgoBsonDocument.Create('guid', TGUID.Create('{E470CAE8-0B6D-4393-A229-1E999DE51B59}')));
end;

procedure TestBsonDocumentReader.TestEndOfStream;
var
  Expected, Doc: TgoBsonDocument;
  Reader: IgoBsonDocumentReader;
  Count: Integer;
begin
  Expected := TgoBsonDocument.Create('x', 1);
  Reader := TgoBsonDocumentReader.Create(Expected);
  Count := 0;
  while (not Reader.EndOfStream) do
  begin
    Doc := Reader.ReadDocument;
    Assert.IsTrue(Doc = Expected);
    Inc(Count);
  end;
  Assert.AreEqual(1, Count);
end;

procedure TestBsonDocumentReader.TestJavaScript;
begin
  Test(TgoBsonDocument.Create('f', TgoBsonJavaScript.Create('function f() { return 1; }')));
end;

procedure TestBsonDocumentReader.TestJavaScriptWithScope;
begin
  Test(TgoBsonDocument.Create('f',
    TgoBsonJavaScriptWithScope.Create('function f() { return n; }',
      TgoBsonDocument.Create('n', 1))));
end;

procedure TestBsonDocumentReader.TestMaxKey;
begin
  Test(TgoBsonDocument.Create('maxkey', TgoBsonMaxKey.Value));
end;

procedure TestBsonDocumentReader.TestMinKey;
begin
  Test(TgoBsonDocument.Create('minkey', TgoBsonMinKey.Value));
end;

procedure TestBsonDocumentReader.TestNull;
begin
  Test(TgoBsonDocument.Create('null', TgoBsonNull.Value));
end;

procedure TestBsonDocumentReader.TestObjectId;
begin
  Test(TgoBsonDocument.Create('doc', TgoObjectId.Empty));
end;

procedure TestBsonDocumentReader.TestRegularExpression;
begin
  Test(TgoBsonDocument.Create('doc', TgoBsonRegularExpression.Create('p', 'i')));
end;

procedure TestBsonDocumentReader.TestSingleString;
begin
  Test(TgoBsonDocument.Create('abc', 'xyz'));
end;

procedure TestBsonDocumentReader.TestSymbol;
begin
  Test(TgoBsonDocument.Create('symbol', TgoBsonSymbolTable.Lookup('name')));
end;

procedure TestBsonDocumentReader.TestTimestamp;
begin
  Test(TgoBsonDocument.Create('timestamp', TgoBsonTimestamp.Create(1234567890)));
end;

procedure TestBsonDocumentReader.TestUndefined;
begin
  Test(TgoBsonDocument.Create('undefined', TgoBsonUndefined.Value));
end;

initialization
  TDUnitX.RegisterTestFixture(TestJsonToBson);
  TDUnitX.RegisterTestFixture(TestJsonData);
  TDUnitX.RegisterTestFixture(TestJsonChecker);
  TDUnitX.RegisterTestFixture(TestArrayElementNameAccelerator);
  TDUnitX.RegisterTestFixture(TestBsonReader);
  TDUnitX.RegisterTestFixture(TestBsonWriter);
  TDUnitX.RegisterTestFixture(TestBsonBuffer);
  TDUnitX.RegisterTestFixture(TestBsonRoundTrip);
  TDUnitX.RegisterTestFixture(TestJsonReader);
  TDUnitX.RegisterTestFixture(TestJsonWriter);
  TDUnitX.RegisterTestFixture(TestBsonDocumentWriter);
  TDUnitX.RegisterTestFixture(TestBsonDocumentReader);

end.
