unit Tests.Grijjy.ProtocolBuffers;

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.Types,
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  Grijjy.ProtocolBuffers;

type
  TPhoneType = (Mobile, Home, Work);

type
  TPhoneNumber = record
  public
    [Serialize(1)]
    Number: String;

    [Serialize(2)]
    PhoneType: TPhoneType;
  public
    procedure Initialize;
  end;

type
  TGroup = (Family, Friends, Work);
  TGroups = set of TGroup;

type
  TPerson = record
  public
    [Serialize(1)]
    Name: String;

    [Serialize(2)]
    Id: UInt32;

    [Serialize(3)]
    Email: String;

    [Serialize(4)]
    Phone: TArray<TPhoneNumber>;
  end;

type
  TPersonEx = record
    [Serialize(1)]
    Person: TPerson;

    [Serialize(2)]
    Groups: TGroups;
  end;

type
  TAllTypes = record
  public
    type
      TNestedMessage = record
      public
        [Serialize(1)]
        BB: Int32;
      end;
    type
      TNestedEnum = (Foo, Bar, Baz);
  public
    [Serialize( 1)]
    MyUInt8: UInt8;

    [Serialize( 2)]
    MyUInt16: UInt16;

    [Serialize( 3)]
    MyUInt32: UInt32;

    [Serialize( 4)]
    MyUInt64: UInt64;

    [Serialize( 5)]
    MyInt8: Int8;

    [Serialize( 6)]
    MyInt16: Int16;

    [Serialize( 7)]
    MyInt32: Int32;

    [Serialize( 8)]
    MyInt64: Int64;

    [Serialize( 9)]
    MyFixedUInt32: FixedUInt32;

    [Serialize(10)]
    MyFixedUInt64: FixedUInt64;

    [Serialize(11)]
    MyFixedInt32: FixedInt32;

    [Serialize(12)]
    MyFixedInt64: FixedInt64;

    [Serialize(13)]
    MySingle: Single;

    [Serialize(14)]
    MyDouble: Double;

    [Serialize(15)]
    MyBoolean: Boolean;

    [Serialize(16)]
    MyString: String;

    [Serialize(17)]
    MyBytes: TBytes;

    [Serialize(18)]
    MyNestedMessage: TNestedMessage;

    [Serialize(19)]
    MyNestedEnum: TNestedEnum;

    [Serialize(20)]
    MyRepeatedUInt8: TArray<UInt8>;

    [Serialize(21)]
    MyRepeatedUInt16: TArray<UInt16>;

    [Serialize(22)]
    MyRepeatedUInt32: TArray<UInt32>;

    [Serialize(23)]
    MyRepeatedUInt64: TArray<UInt64>;

    [Serialize(24)]
    MyRepeatedInt8: TArray<Int8>;

    [Serialize(25)]
    MyRepeatedInt16: TArray<Int16>;

    [Serialize(26)]
    MyRepeatedInt32: TArray<Int32>;

    [Serialize(27)]
    MyRepeatedInt64: TArray<Int64>;

    [Serialize(28)]
    MyRepeatedFixedUInt32: TArray<FixedUInt32>;

    [Serialize(29)]
    MyRepeatedFixedUInt64: TArray<FixedUInt64>;

    [Serialize(30)]
    MyRepeatedFixedInt32: TArray<FixedInt32>;

    [Serialize(31)]
    MyRepeatedFixedInt64: TArray<FixedInt64>;

    [Serialize(32)]
    MyRepeatedSingle: TArray<Single>;

    [Serialize(33)]
    MyRepeatedDouble: TArray<Double>;

    [Serialize(34)]
    MyRepeatedBoolean: TArray<Boolean>;

    [Serialize(35)]
    MyRepeatedString: TArray<String>;

    [Serialize(36)]
    MyRepeatedNestedMessage: TArray<TNestedMessage>;

    [Serialize(37)]
    MyRepeatedNestedEnum: TArray<TNestedEnum>;

    [Serialize(38)]
    MyRepeatedEmptyBytes: TBytes;

    [Serialize(39)]
    MyRepeatedEmptyArray: TArray<String>;
  end;

type
  { This copies the MyRepeatedString field from TAllTypes, but removes all
    other fields }
  TUnknownFields = record
    [Serialize(35)]
    MyRepeatedString: TArray<String>;
  end;

type
  TTestProtocolBuffers = class
  private
    function SerializePerson(out A: TPerson): TBytes;
    function SerializePersonEx(out A: TPersonEx): TBytes;
    function SerializeAllTypes(out A: TAllTypes): TBytes;
    procedure CheckData(const ExpectedResourceName: String;
      const Actual: TBytes);
  public
    [Test] procedure TestPerson;
    [Test] procedure TestPersonEx;
    [Test] procedure TestPersonOutput;
    [Test] procedure TestAllTypes;
    [Test] procedure TestAllTypesOutput;
    [Test] procedure TestInitialize;
    [Test] procedure TestUnknownFields;
    [Test] procedure TestDeserializeFromBuffer;
    [Test] procedure TestDoubleDeserialization;
  end;

implementation

{$R Grijjy.ProtocolBuffers.Tests.Resources.res}

{ TPhoneNumber }

procedure TPhoneNumber.Initialize;
begin
  PhoneType := TPhoneType.Home;
end;

{ TTestProtocolBuffers }

procedure TTestProtocolBuffers.CheckData(const ExpectedResourceName: String;
  const Actual: TBytes);
var
  Stream: TResourceStream;
  Expected: TBytes;
begin
  { Compare serialized output with Google's C-code output }
  Stream := TResourceStream.Create(HInstance, ExpectedResourceName, RT_RCDATA);
  try
    SetLength(Expected, Stream.Size);
    Assert.AreEqual(Length(Expected), Length(Actual));
    Stream.ReadBuffer(Expected[0], Length(Expected));
  finally
    Stream.Free;
  end;
  Assert.AreEqualMemory(@Expected[0], @Actual[0], Length(Expected));
end;

function TTestProtocolBuffers.SerializeAllTypes(out A: TAllTypes): TBytes;
begin
  A.MyUInt8  := $FE;
  A.MyUInt16 := $FEDC;
  A.MyUInt32 := $FEDCBA98;
  A.MyUInt64 := UInt64($FEDCBA9876543210);
  A.MyInt8  := -$7E;
  A.MyInt16 := -$7EDC;
  A.MyInt32 := -$7EDCBA98;
  A.MyInt64 := -$7EDCBA9876543210;
  A.MyFixedUInt32 := $89ABCDEF;
  A.MyFixedUInt64 := $0123456789ABCDEF;
  A.MyFixedInt32 := -$012345678;
  A.MyFixedInt64 := -$0123456789ABCDEF;
  A.MySingle := 3.14;
  A.MyDouble := -3.14;
  A.MyBoolean := True;
  A.MyString := 'The Quick Brown Fox Jumps Over The Lazy Dog';
  A.MyBytes := TBytes.Create(0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144);
  A.MyNestedMessage.BB := 42;
  A.MyNestedEnum := TAllTypes.TNestedEnum.Bar;

  { These values excercise all VarInt variants }
  A.MyRepeatedUInt8 := TArray<UInt8>.Create($00, $7F, $80, $FF);
  A.MyRepeatedUInt16 := TArray<UInt16>.Create($00, $7F, $80, $3FFF, $4000, $FFFF);
  A.MyRepeatedUInt32 := TArray<UInt32>.Create($00, $7F, $80, $3FFF, $4000,
    $001FFFFF, $00200000, $0FFFFFFF, $10000000, $FFFFFFFF);
  A.MyRepeatedUInt64 := TArray<UInt64>.Create($00, $7F, $80, $3FFF, $4000,
    $001FFFFF, $00200000, $0FFFFFFF, $10000000, $00000007FFFFFFFF,
    $0000000800000000, $000003FFFFFFFFFF, $0000040000000000, $0001FFFFFFFFFFFF,
    $0002000000000000, $00FFFFFFFFFFFFFF, $0100000000000000, $7FFFFFFFFFFFFFFF,
    UInt64($8000000000000000), UInt64($FFFFFFFFFFFFFFFF));
  A.MyRepeatedInt8 := TArray<Int8>.Create(-$80, -$01, $00, $7F);
  A.MyRepeatedInt16 := TArray<Int16>.Create(-$8000, -$4000, -$3FFF, -$80, -$01, $00,
    $7F, $80, $3FFF, $4000, $7FFF);
  A.MyRepeatedInt32 := TArray<Int32>.Create(-$80000000, -$10000000, -$0FFFFFFF,
    -$00200000, -$001FFFFF, -$4000, -$3FFF, -$80, -$01, $00, $7F, $80, $3FFF,
    $4000, $001FFFFF, $00200000, $0FFFFFFF, $10000000, $7FFFFFFF);
  A.MyRepeatedInt64 := TArray<Int64>.Create(-$8000000000000000, -$7FFFFFFFFFFFFFFF,
    -$0100000000000000, -$00FFFFFFFFFFFFFF, -$0002000000000000, -$0001FFFFFFFFFFFF,
    -$0000040000000000, -$000003FFFFFFFFFF, -$0000000800000000, -$00000007FFFFFFFF,
    -$10000000, -$0FFFFFFF, -$00200000, -$001FFFFF, -$4000, -$3FFF, -$80, -$01,
    $00, $7F, $80, $3FFF, $4000, $001FFFFF, $00200000, $0FFFFFFF, $10000000,
    $00000007FFFFFFFF, $0000000800000000, $000003FFFFFFFFFF, $0000040000000000,
    $0001FFFFFFFFFFFF, $0002000000000000, $00FFFFFFFFFFFFFF, $0100000000000000,
    $7FFFFFFFFFFFFFFF);
  A.MyRepeatedFixedUInt32 := TArray<FixedUInt32>.Create($00, $7F, $80, $3FFF, $4000,
    $001FFFFF, $00200000, $0FFFFFFF, $10000000, $FFFFFFFF);
  A.MyRepeatedFixedUInt64 := TArray<FixedUInt64>.Create($00, $7F, $80, $3FFF, $4000,
    $001FFFFF, $00200000, $0FFFFFFF, $10000000, $00000007FFFFFFFF,
    $0000000800000000, $000003FFFFFFFFFF, $0000040000000000, $0001FFFFFFFFFFFF,
    $0002000000000000, $00FFFFFFFFFFFFFF, $0100000000000000, $7FFFFFFFFFFFFFFF,
    UInt64($8000000000000000), UInt64($FFFFFFFFFFFFFFFF));
  A.MyRepeatedFixedInt32 := TArray<FixedInt32>.Create(-$80000000, -$10000000, -$0FFFFFFF,
    -$00200000, -$001FFFFF, -$4000, -$3FFF, -$80, -$01, $00, $7F, $80, $3FFF,
    $4000, $001FFFFF, $00200000, $0FFFFFFF, $10000000, $7FFFFFFF);
  A.MyRepeatedFixedInt64 := TArray<FixedInt64>.Create(-$8000000000000000, -$7FFFFFFFFFFFFFFF,
    -$0100000000000000, -$00FFFFFFFFFFFFFF, -$0002000000000000, -$0001FFFFFFFFFFFF,
    -$0000040000000000, -$000003FFFFFFFFFF, -$0000000800000000, -$00000007FFFFFFFF,
    -$10000000, -$0FFFFFFF, -$00200000, -$001FFFFF, -$4000, -$3FFF, -$80, -$01,
    $00, $7F, $80, $3FFF, $4000, $001FFFFF, $00200000, $0FFFFFFF, $10000000,
    $00000007FFFFFFFF, $0000000800000000, $000003FFFFFFFFFF, $0000040000000000,
    $0001FFFFFFFFFFFF, $0002000000000000, $00FFFFFFFFFFFFFF, $0100000000000000,
    $7FFFFFFFFFFFFFFF);
  A.MyRepeatedSingle := TArray<Single>.Create(-3.4e37, -1.5e-44, 0, 1.5e-44, 3.4e37);
  A.MyRepeatedDouble := TArray<Double>.Create(-1.7e307, -5.0e-323, 0, 5.0e-323, 1.7e307);
  A.MyRepeatedBoolean := TArray<Boolean>.Create(True, False, True);
  A.MyRepeatedString := TArray<String>.Create('Foo', 'Bar', 'Baz');
  SetLength(A.MyRepeatedNestedMessage, 2);
  A.MyRepeatedNestedMessage[0].BB := 1;
  A.MyRepeatedNestedMessage[1].BB := 2;
  A.MyRepeatedNestedEnum := TArray<TAllTypes.TNestedEnum>.Create(
    TAllTypes.TNestedEnum.Foo, TAllTypes.TNestedEnum.Baz);
  A.MyRepeatedEmptyBytes := nil;
  A.MyRepeatedEmptyArray := nil;

  Result := TgoProtocolBuffer.Serialize(A);
end;

function TTestProtocolBuffers.SerializePerson(out A: TPerson): TBytes;
begin
  A.Name := 'Erik van Bilsen';
  A.Id := 42;
  A.Email := 'erik@mymail.com';
  SetLength(A.Phone, 2);
  A.Phone[0].Number := 'Number1';
  A.Phone[0].PhoneType := TPhoneType.Mobile;
  A.Phone[1].Number := 'Number2';
  A.Phone[1].PhoneType := TPhoneType.Work;

  Result := TgoProtocolBuffer.Serialize(A);
end;

function TTestProtocolBuffers.SerializePersonEx(out A: TPersonEx): TBytes;
begin
  A.Person.Name := 'Allen Drennan';
  A.Person.Id := 24;
  A.Person.Email := 'allen@mymail.com';
  SetLength(A.Person.Phone, 1);
  A.Person.Phone[0].Number := 'Number1';
  A.Person.Phone[0].PhoneType := TPhoneType.Mobile;
  A.Groups := [TGroup.Family, TGroup.Work];

  Result := TgoProtocolBuffer.Serialize(A);
end;

procedure TTestProtocolBuffers.TestAllTypes;
var
  A, B: TAllTypes;
  I: Integer;
  Serialized: TBytes;
begin
  Serialized := SerializeAllTypes(A);
  TgoProtocolBuffer.Deserialize(B, Serialized);

  Assert.AreEqual(A.MyUInt8, B.MyUInt8);
  Assert.AreEqual(A.MyUInt16, B.MyUInt16);
  Assert.AreEqual(A.MyUInt32, B.MyUInt32);
  Assert.AreEqual(A.MyUInt64, B.MyUInt64);
  Assert.AreEqual(A.MyInt8, B.MyInt8);
  Assert.AreEqual(A.MyInt16, B.MyInt16);
  Assert.AreEqual(A.MyInt32, B.MyInt32);
  Assert.AreEqual(A.MyInt64, B.MyInt64);
  Assert.AreEqual(A.MyFixedUInt32, B.MyFixedUInt32);
  Assert.AreEqual(A.MyFixedUInt64, B.MyFixedUInt64);
  Assert.AreEqual(A.MyFixedInt32, B.MyFixedInt32);
  Assert.AreEqual(A.MyFixedInt64, B.MyFixedInt64);
  Assert.AreEqual(A.MySingle, B.MySingle);
  Assert.AreEqual(A.MyDouble, B.MyDouble);
  Assert.AreEqual(A.MyBoolean, B.MyBoolean);
  Assert.AreEqual(A.MyString, B.MyString);
  Assert.AreEqualMemory(@A.MyBytes[0], @B.MyBytes[0], Length(A.MyBytes));
  Assert.AreEqual(A.MyNestedMessage.BB, B.MyNestedMessage.BB);
  Assert.AreEqual(A.MyNestedEnum, B.MyNestedEnum);
  Assert.AreEqualMemory(@A.MyRepeatedUInt8[0], @B.MyRepeatedUInt8[0], Length(A.MyRepeatedUInt8) * SizeOf(UInt8));
  Assert.AreEqualMemory(@A.MyRepeatedUInt16[0], @B.MyRepeatedUInt16[0], Length(A.MyRepeatedUInt16) * SizeOf(UInt16));
  Assert.AreEqualMemory(@A.MyRepeatedUInt32[0], @B.MyRepeatedUInt32[0], Length(A.MyRepeatedUInt32) * SizeOf(UInt32));
  Assert.AreEqualMemory(@A.MyRepeatedUInt64[0], @B.MyRepeatedUInt64[0], Length(A.MyRepeatedUInt64) * SizeOf(UInt64));
  Assert.AreEqualMemory(@A.MyRepeatedInt8[0], @B.MyRepeatedInt8[0], Length(A.MyRepeatedInt8) * SizeOf(Int8));
  Assert.AreEqualMemory(@A.MyRepeatedInt16[0], @B.MyRepeatedInt16[0], Length(A.MyRepeatedInt16) * SizeOf(Int16));
  Assert.AreEqualMemory(@A.MyRepeatedInt32[0], @B.MyRepeatedInt32[0], Length(A.MyRepeatedInt32) * SizeOf(Int32));
  Assert.AreEqualMemory(@A.MyRepeatedInt64[0], @B.MyRepeatedInt64[0], Length(A.MyRepeatedInt64) * SizeOf(Int64));
  Assert.AreEqualMemory(@A.MyRepeatedFixedUInt32[0], @B.MyRepeatedFixedUInt32[0], Length(A.MyRepeatedFixedUInt32) * SizeOf(UInt32));
  Assert.AreEqualMemory(@A.MyRepeatedFixedUInt64[0], @B.MyRepeatedFixedUInt64[0], Length(A.MyRepeatedFixedUInt64) * SizeOf(UInt64));
  Assert.AreEqualMemory(@A.MyRepeatedFixedInt32[0], @B.MyRepeatedFixedInt32[0], Length(A.MyRepeatedFixedInt32) * SizeOf(Int32));
  Assert.AreEqualMemory(@A.MyRepeatedFixedInt64[0], @B.MyRepeatedFixedInt64[0], Length(A.MyRepeatedFixedInt64) * SizeOf(Int64));
  Assert.AreEqualMemory(@A.MyRepeatedSingle[0], @B.MyRepeatedSingle[0], Length(A.MyRepeatedSingle) * SizeOf(Single));
  Assert.AreEqualMemory(@A.MyRepeatedDouble[0], @B.MyRepeatedDouble[0], Length(A.MyRepeatedDouble) * SizeOf(Double));
  Assert.AreEqualMemory(@A.MyRepeatedBoolean[0], @B.MyRepeatedBoolean[0], Length(A.MyRepeatedBoolean) * SizeOf(Boolean));

  Assert.AreEqual(Length(A.MyRepeatedString), Length(B.MyRepeatedString));
  for I := 0 to Length(A.MyRepeatedString) - 1 do
    Assert.AreEqual(A.MyRepeatedString[I], B.MyRepeatedString[I]);

  Assert.AreEqual(Length(A.MyRepeatedNestedMessage), Length(B.MyRepeatedNestedMessage));
  for I := 0 to Length(A.MyRepeatedNestedMessage) - 1 do
    Assert.AreEqual(A.MyRepeatedNestedMessage[I].BB, B.MyRepeatedNestedMessage[I].BB);

  Assert.AreEqualMemory(@A.MyRepeatedNestedEnum[0], @B.MyRepeatedNestedEnum[0], Length(A.MyRepeatedNestedEnum) * SizeOf(TAllTypes.TNestedEnum));
  Assert.IsTrue(B.MyRepeatedEmptyBytes = nil);
  Assert.IsTrue(B.MyRepeatedEmptyArray = nil);
end;

procedure TTestProtocolBuffers.TestAllTypesOutput;
var
  A: TAllTypes;
  Serialized: TBytes;
begin
  Serialized := SerializeAllTypes(A);
  CheckData('ALLTYPES', Serialized);
end;

procedure TTestProtocolBuffers.TestDeserializeFromBuffer;
var
  Person1, Person2: TPerson;
  I: Integer;
  Serialized: TBytes;
begin
  Serialized := SerializePerson(Person1);
  TgoProtocolBuffer.Deserialize(Person2, @Serialized[0], Length(Serialized));

  Assert.AreEqual(Person1.Name, Person2.Name);
  Assert.AreEqual(Person1.Id, Person2.Id);
  Assert.AreEqual(Person1.Email, Person2.Email);
  Assert.AreEqual(Length(Person1.Phone), Length(Person2.Phone));
  for I := 0 to Length(Person1.Phone) - 1 do
  begin
    Assert.AreEqual(Person1.Phone[I].Number, Person2.Phone[I].Number);
    Assert.AreEqual(Person1.Phone[I].PhoneType, Person2.Phone[I].PhoneType);
  end;
end;

procedure TTestProtocolBuffers.TestDoubleDeserialization;
var
  Person1, Person2: TPerson;
  Serialized: TBytes;
begin
  ReportMemoryLeaksOnShutdown := True;
  Serialized := SerializePerson(Person1);
  TgoProtocolBuffer.Deserialize(Person2, Serialized);

  { Deserializing a record fills the record with zeros at te beginning. If the
    record contains refcounted data (such as strings), then this would create
    a memory leak. However, since the record is an "out" parameter, Delphi
    should finalize the record first before passing it again to the Deserialize
    method. So there should be no memory leaks. }
  TgoProtocolBuffer.Deserialize(Person2, Serialized);
end;

procedure TTestProtocolBuffers.TestInitialize;
var
  A: TPhoneNumber;
  EmptyMessage: TBytes;
begin
  { TPhoneNumber.Initialize sets PhoneType to Home and clears other fields. }
  A.Number := '12345';
  A.PhoneType := TPhoneType.Work;

  { Deserialize an empty message to just initialize the record }
  EmptyMessage := nil;
  TgoProtocolBuffer.Deserialize(TypeInfo(TPhoneNumber), A, EmptyMessage);

  Assert.AreEqual(String(''), A.Number);
  Assert.AreEqual(TPhoneType.Home, A.PhoneType);
end;

procedure TTestProtocolBuffers.TestPerson;
var
  Person1, Person2: TPerson;
  I: Integer;
  Serialized: TBytes;
begin
  Serialized := SerializePerson(Person1);
  TgoProtocolBuffer.Deserialize(Person2, Serialized);

  Assert.AreEqual(Person1.Name, Person2.Name);
  Assert.AreEqual(Person1.Id, Person2.Id);
  Assert.AreEqual(Person1.Email, Person2.Email);
  Assert.AreEqual(Length(Person1.Phone), Length(Person2.Phone));
  for I := 0 to Length(Person1.Phone) - 1 do
  begin
    Assert.AreEqual(Person1.Phone[I].Number, Person2.Phone[I].Number);
    Assert.AreEqual(Person1.Phone[I].PhoneType, Person2.Phone[I].PhoneType);
  end;
end;

procedure TTestProtocolBuffers.TestPersonEx;
var
  Person1, Person2: TPersonEx;
  I: Integer;
  Serialized: TBytes;
begin
  Serialized := SerializePersonEx(Person1);
  TgoProtocolBuffer.Deserialize(Person2, Serialized);

  Assert.AreEqual(Person1.Person.Name, Person2.Person.Name);
  Assert.AreEqual(Person1.Person.Id, Person2.Person.Id);
  Assert.AreEqual(Person1.Person.Email, Person2.Person.Email);
  Assert.AreEqual(Length(Person1.Person.Phone), Length(Person2.Person.Phone));
  for I := 0 to Length(Person1.Person.Phone) - 1 do
  begin
    Assert.AreEqual(Person1.Person.Phone[I].Number, Person2.Person.Phone[I].Number);
    Assert.AreEqual(Person1.Person.Phone[I].PhoneType, Person2.Person.Phone[I].PhoneType);
  end;
  Assert.AreEqual(Person1.Groups, Person2.Groups);
end;

procedure TTestProtocolBuffers.TestPersonOutput;
var
  P: TPerson;
  Serialized: TBytes;
begin
  Serialized := SerializePerson(P);
  CheckData('PERSON', Serialized);
end;

procedure TTestProtocolBuffers.TestUnknownFields;
var
  Serialized: TBytes;
  A: TAllTypes;
  U: TUnknownFields;
begin
  { Serialize a TAllTypes record to create a bitstream with data of every type.
    We then read it back into a TUnknownFields record, which doesn't know any
    of the serialized data, except for MyRepeatedString. This is done to test if
    the deserializer successfully skips over any unknown data. }
  Serialized := SerializeAllTypes(A);
  TgoProtocolBuffer.Deserialize(TypeInfo(TUnknownFields), U, Serialized);
  Assert.AreEqual(3, Length(U.MyRepeatedString));
  Assert.AreEqual('Foo', U.MyRepeatedString[0]);
  Assert.AreEqual('Bar', U.MyRepeatedString[1]);
  Assert.AreEqual('Baz', U.MyRepeatedString[2]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestProtocolBuffers);

end.
