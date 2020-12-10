unit Tests.Grijjy.Bson.Serialization;

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DUnitX.TestFramework,
  Grijjy.Bson,
  Grijjy.Bson.IO,
  Grijjy.Bson.Serialization;

type
  TestBsonSerializeBoolean = class
  public type
    TTestRecord = record
    public
      N: Boolean;

      [BsonRepresentation(TgoBsonRepresentation.Boolean)]
      B: Boolean;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: Boolean;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: Boolean;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: Boolean;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: Boolean;
    public
      procedure Initialize;
    end;
  public
    [Test] procedure TestFalse;
    [Test] procedure TestTrue;
  end;

type
  TestBsonSerializeInt8 = class
  public type
    TTestRecord = record
    public
      N: Int8;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: Int8;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: Int8;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: Int8;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: Int8;
    public
      procedure Initialize(const AValue: Int8);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestMinusOne;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestMax;
  end;

type
  TestBsonSerializeInt16 = class
  public type
    TTestRecord = record
    public
      N: Int16;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: Int16;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: Int16;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: Int16;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: Int16;
    public
      procedure Initialize(const AValue: Int16);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestMinusOne;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestMax;
  end;

type
  TestBsonSerializeInt32 = class
  public type
    TTestClass = class
    private
      FD, FI, FL, FS: Int32;
      function GetD: Int32;
      function GetL: Int32;
      procedure SetI(const Value: Int32);
      procedure SetL(const Value: Int32);
    public
      constructor Create(const AValue: Int32);
    public
      N: Int32;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      property D: Int32 read GetD write FD;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      property I: Int32 read FI write SetI;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      property L: Int32 read GetL write SetL;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      property S: Int32 read FS write FS;
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestMinusOne;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestMax;
  end;

type
  TestBsonSerializeInt64 = class
  public type
    TTestRecord = record
    public
      N: Int64;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: Int64;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: Int64;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: Int64;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: Int64;
    public
      procedure Initialize(const AValue: Int64);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestMinusOne;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestMax;
  end;

type
  TestBsonSerializeUInt8 = class
  public type
    TTestRecord = record
    public
      N: UInt8;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: UInt8;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: UInt8;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: UInt8;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: UInt8;
    public
      procedure Initialize(const AValue: UInt8);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestMax;
  end;

type
  TestBsonSerializeUInt16 = class
  public type
    TTestRecord = record
    public
      N: UInt16;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: UInt16;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: UInt16;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: UInt16;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: UInt16;
    public
      procedure Initialize(const AValue: UInt16);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestMax;
  end;

type
  TestBsonSerializeUInt32 = class
  public type
    TTestRecord = record
    public
      N: UInt32;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: UInt32;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: UInt32;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: UInt32;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: UInt32;
    public
      procedure Initialize(const AValue: UInt32);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestMax;
  end;

type
  TestBsonSerializeUInt64 = class
  public type
    TTestRecord = record
    public
      N: UInt64;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: UInt64;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: UInt64;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: UInt64;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: UInt64;
    public
      procedure Initialize(const AValue: UInt64);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestMax;
  end;

type
  TestBsonSerializeSingle = class
  public type
    TTestRecord = record
    public
      N: Single;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: Single;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: Single;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: Single;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: Single;
    public
      procedure Initialize(const AValue: Single);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestMinusOne;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestOnePointFive;
    [Test] procedure TestMax;
    [Test] procedure TestNaN;
    [Test] procedure TestNegativeInfinity;
    [Test] procedure TestPositiveInfinity;
  end;

type
  TestBsonSerializeDouble = class
  public type
    TTestRecord = record
    public
      N: Double;

      [BsonRepresentation(TgoBsonRepresentation.Double)]
      D: Double;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: Double;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: Double;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: Double;
    public
      procedure Initialize(const AValue: Double);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestMinusOne;
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestOnePointFive;
    [Test] procedure TestMax;
    [Test] procedure TestNaN;
    [Test] procedure TestNegativeInfinity;
    [Test] procedure TestPositiveInfinity;
  end;

type
  TestBsonSerializeChar = class
  public type
    TTestRecord = record
    public
      N: Char;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: Char;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: Char;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: Char;
    public
      procedure Initialize(const AValue: Char);
    end;
  public
    [Test] procedure TestZero;
    [Test] procedure TestOne;
    [Test] procedure TestA;
    [Test] procedure TestMax;
  end;

type
  TestBsonSerializeString = class
  public type
    TTestRecord = record
    public
      N: String;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: String;

      [BsonRepresentation(TgoBsonRepresentation.ObjectId)]
      O: String;

      [BsonRepresentation(TgoBsonRepresentation.Symbol)]
      Y: String;
    public
      procedure Initialize(const AValue: String);
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestHelloWorld;
    [Test] procedure TestObjectId;
  end;

type
  TestBsonSerializeDateTime = class
  public type
    TTestRecord = record
    public
      N: TDateTime;

      [BsonRepresentation(TgoBsonRepresentation.DateTime)]
      D: TDateTime;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: TDateTime;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: TDateTime;

      [BsonRepresentation(TgoBsonRepresentation.Document)]
      O: TDateTime;
    public
      procedure Initialize(const AValue: TDateTime);
    end;
  public
    [Test] procedure TestMin;
    [Test] procedure TestMax;
    [Test] procedure TestSample;
  end;

type
  TestBsonSerializeGuid = class
  public type
    TTestRecord = record
    public
      N: TGUID;

      [BsonRepresentation(TgoBsonRepresentation.Binary)]
      B: TGUID;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: TGUID;
    public
      procedure Initialize(const AValue: TGUID);
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestSample;
  end;

type
  TestBsonSerializeObjectId = class
  public type
    TTestRecord = record
    public
      N: TgoObjectId;

      [BsonRepresentation(TgoBsonRepresentation.ObjectId)]
      O: TgoObjectId;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: TgoObjectId;
    public
      procedure Initialize(const AValue: TgoObjectId);
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestSample;
  end;

type
  TestBsonSerializeTBytes = class
  public type
    TTestRecord = record
    public
      N: TBytes;

      [BsonRepresentation(TgoBsonRepresentation.Binary)]
      B: TBytes;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: TBytes;
    public
      procedure Initialize(const AValue: TBytes);
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestLengthOne;
    [Test] procedure TestLengthTwo;
    [Test] procedure TestLengthNine;
  end;

type
  TestBsonSerializeEnum = class
  public type
    TEnum = (A, B);
  public type
    TTestRecord = record
    public
      N: TEnum;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: TEnum;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: TEnum;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: TEnum;
    public
      procedure Initialize(const AValue: TEnum);
    end;
  public
    [Test] procedure TestA;
    [Test] procedure TestB;
    [Test] procedure TestInvalid;
  end;

type
  TestBsonSerializeSet = class
  public type
    TEnum = (A, B);
    TSet = set of TEnum;
  public type
    TTestRecord = record
    public
      N: TSet;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: TSet;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: TSet;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: TSet;
    public
      procedure Initialize(const AValue: TSet);
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestA;
    [Test] procedure TestB;
    [Test] procedure TestAB;
  end;

type
  TestBsonRecord = class
  public type
    TRec = record
      X: Integer;
      S: String;
    end;
    TTestRecord = record
    public
      A: TRec;
    end;
  public
    [Test] procedure TestRecord;
  end;

{$IF (RTLVersion >= 34)}
type
  TestBsonCustomManagedRecord = class
  public type
    TRec = record
    public class var
      InstanceCount: Integer;
    public
      Y: Integer;
    public
      class operator Initialize(out ADest: TRec);
      class operator Finalize(var ADest: TRec);
      class operator Assign(var ADest: TRec;
        const [ref] ASrc: TRec);
    end;

    TTestRecord = record
    public class var
      InstanceCount: Integer;
    public
      X: Integer;
      R: TRec;
    public
      class operator Initialize(out ADest: TTestRecord);
      class operator Finalize(var ADest: TTestRecord);
      class operator Assign(var ADest: TTestRecord;
        const [ref] ASrc: TTestRecord);
    end;
  public
    [Test] procedure TestCustomManagedRecord;
  end;
{$ENDIF}

type
  TestBsonObject = class
  public type
    TObj = class
    private
      FX: Integer;
      FS: String;
    public
      constructor Create(const AX: Integer; const AStr: String);

      property X: Integer read FX write FX;
      property S: String read FS write FS;
    end;
    TTestRecord = record
    public
      A: TObj;
    public
      procedure Initialize;
    end;
  public
    [Test] procedure TestNilToNil;
    [Test] procedure TestNilToObject;
    [Test] procedure TestObjectToNil;
    [Test] procedure TestObjectToObject;
  end;

type
  TestBsonArrayOfInteger = class
  public type
    TTestRecord = record
    public
      A: TArray<Integer>;
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestLength1;
    [Test] procedure TestLength9;
  end;

type
  TestBsonArrayOfString = class
  public type
    TTestRecord = record
    public
      A: TArray<String>;
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestLength1;
    [Test] procedure TestLength2;
  end;

type
  TestBsonArrayOfEnum = class
  public type
    TEnum = (A, B);
    TTestRecord = record
    public
      N: TArray<TEnum>;

      [BsonRepresentation(TgoBsonRepresentation.Int32)]
      I: TArray<TEnum>;

      [BsonRepresentation(TgoBsonRepresentation.Int64)]
      L: TArray<TEnum>;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      S: TArray<TEnum>;
    public
      procedure Initialize(const AValue: TArray<TEnum>);
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestLength1;
    [Test] procedure TestLength2;
  end;

type
  TestBsonArrayOfRecord = class
  public type
    TRec = record
    public
      X: Integer;
      S: String;
    public
      constructor Create(const AX: Integer; const AStr: String);
    end;
    TTestRecord = record
    public
      A: TArray<TRec>;
    end;
    TTestClass = class
    private
      FValues: TList<TRec>;
      function GetA: TArray<TRec>;
      procedure SetA(const Value: TArray<TRec>);
    public
      constructor Create;
      destructor Destroy; override;

      property A: TArray<TRec> read GetA write SetA;
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestLength1;
    [Test] procedure TestLength2;
    [Test] procedure TestDynArrayProp;
  end;

type
  TestBsonArrayOfObject = class
  public type
    TObj = class
    private
      FX: Integer;
      FS: String;
    public
      constructor Create(const AX: Integer; const AStr: String);

      property X: Integer read FX write FX;
      property S: String read FS write FS;
    end;
    TTestRecord = record
    public
      A: TArray<TObj>;
    end;
  public
    [Test] procedure TestEmpty;
    [Test] procedure TestLength1;
    [Test] procedure TestLength2;
  end;

type
  TestBsonStandAloneArray = class
  public type
    TRec = record
      X: Integer;
      S: String;
    end;
  public
    [Test] procedure TestSimple;
  end;

type
  TestBsonSerializePrimitiveTypesInRecord = class
  public type
    TEnum = (A, B);
    TSet = set of TEnum;
    TRec = record
      X: Integer;
      S: String;
    end;
    TObj = class
    private
      FX: Integer;
      FS: String;
    public
      constructor Create; overload;
      constructor Create(const AX: Integer; const AStr: String); overload;

      property X: Integer read FX write FX;
      property S: String read FS write FS;
    end;
  public type
    TTestRecord = record
    public
      B: Boolean;
      I8: Int8;
      I16: Int16;
      I32: Int32;
      I64: Int64;
      U8: UInt8;
      U16: UInt16;
      U32: UInt32;
      U64: UInt64;
      F32: Single;
      F64: Double;
      C: Char;
      S: String;
      DT: TDateTime;
      G: TGUID;
      Oid: TgoObjectId;
      BA: TBytes;
      E: TEnum;
      St: TSet;
      R: TRec;
      O1: TObj;
      O2: TObj;
      O3: TObj;
      AoS: TArray<String>;
      AoI: TArray<Integer>;
    end;
  public
    [Test] procedure TestAllTypes;
  end;

type
  TestBsonSerializePrimitiveTypesInClass = class
  public type
    TEnum = (A, B);
    TSet = set of TEnum;
    TRec = record
    public
      X: Integer;
      S: String;
    public
      constructor Create(const AX: Integer; const AStr: String);
    end;
    TObj = class
    private
      FX: Integer;
      FS: String;
    public
      constructor Create; overload;
      constructor Create(const AX: Integer; const AStr: String); overload;

      property X: Integer read FX write FX;
      property S: String read FS write FS;
    end;
  public type
    TTestClass = class
    private
      FB: Boolean;
      FI8: Int8;
      FI16: Int16;
      FI32: Int32;
      FI64: Int64;
      FU8: UInt8;
      FU16: UInt16;
      FU32: UInt32;
      FU64: UInt64;
      FF32: Single;
      FF64: Double;
      FC: Char;
      FS: String;
      FDT: TDateTime;
      FG: TGUID;
      FOid: TgoObjectId;
      FBA: TBytes;
      FE: TEnum;
      FSt: TSet;
      FR: TRec;
      FO1: TObj;
      FO2: TObj;
      FO3: TObj;
      FAoS: TArray<String>;
      FAoI: TArray<Integer>;
      function GetOid: TgoObjectId;
      procedure SetOid(const Value: TgoObjectId);
    public
      constructor Create;
      destructor Destroy; override;

      property B: Boolean read FB write FB;
      property I8: Int8 read FI8 write FI8;
      property I16: Int16 read FI16 write FI16;
      property I32: Int32 read FI32 write FI32;
      property I64: Int64 read FI64 write FI64;
      property U8:  UInt8 read FU8 write FU8;
      property U16: UInt16 read FU16 write FU16;
      property U32: UInt32 read FU32 write FU32;
      property U64: UInt64 read FU64 write FU64;
      property F32: Single read FF32 write FF32;
      property F64: Double read FF64 write FF64;
      property C: Char read FC write FC;
      property S: String read FS write FS;
      property DT: TDateTime read FDT write FDT;
      property G: TGUID read FG write FG;
      property Oid: TgoObjectId read GetOid write SetOid;
      property BA: TBytes read FBA write FBA;
      property E: TEnum read FE write FE;
      property St: TSet read FSt write FSt;
      property R: TRec read FR write FR;
      property O1: TObj read FO1;
      property O2: TObj read FO2;
      property O3: TObj read FO3 write FO3;
      property AoS: TArray<String> read FAoS write FAoS;
      property AoI: TArray<Integer> read FAoI write FAoI;
    end;
  public
    [Test] procedure TestAllTypes;
  end;

type
  TestBsonSerializer = class
  public type
    TEmployee = class
    private
      FEmployeeId: TgoObjectId;
      FFirstName: String;
      FLastName: String;
      FDateOfBirth: TDateTime;
      function GetAge: Integer;
    public
      property EmployeeId: TgoObjectId read FEmployeeId write FEmployeeId;
      property FirstName: String read FFirstName write FFirstName;
      property LastName: String read FLastName write FLastName;
      property DateOfBirth: TDateTime read FDateOfBirth write FDateOfBirth;
      property Age: Integer read GetAge;
    end;
  public type
    TOrderDetail = class
    public
      Product: String;
      Quantity: Integer;
    end;
    TOrder = class
    public
      Customer: String;
      OrderDetails: TArray<TOrderDetail>;
    public
      destructor Destroy; override;
    end;
  public
    [Test] procedure TestSerializeEmployee;
    [Test] procedure TestSerializeOrder;
  end;

type
  TestBsonPolymorphicClasses = class
  public type
    TA = class abstract
    public
      FA: String;
    end;

    [BsonDiscriminator(True)]
    TB = class abstract(TA)
    public
      FB: String;
    end;

    [BsonDiscriminator('ClassC')]
    TC = class(TA)
    public
      FC: String;
    end;

    TD = class(TB)
    public
      FD: String;
    end;

    TE = class(TB)
    public
      FE: String;
    end;

    TT = class
    public
      FT: TA;
    public
      destructor Destroy; override;
    end;
  public
    [Test] procedure TestSerializeTCasTC;
    [Test] procedure TestSerializeTCasTA;
    [Test] procedure TestSerializeTDasTA;
    [Test] procedure TestSerializeTDasTB;
    [Test] procedure TestSerializeTDasTD;
    [Test] procedure TestSerializeTEasTA;
    [Test] procedure TestSerializeTEasTB;
    [Test] procedure TestSerializeTEasTE;
    [Test] procedure TestSerializeTTwithNil;
    [Test] procedure TestSerializeTTwithTC;
    [Test] procedure TestSerializeTTwithTD;
    [Test] procedure TestSerializeTTwithTE;
    [Test] procedure TestUnknownDiscriminator;
  end;

type
  TestBsonCircularClass = class
  public type
    TFoo = class
    public
      Value: Integer;
      Child: TFoo;
    public
      destructor Destroy; override;
    end;
  public
    [Test] procedure TestCircularClass;
  end;

type
  TestBsonAttributes = class
  public type
    TColor = (Red, Green, Blue);
    TColors = set of TColor;
  public type
    TFoo = class
    public
      Id: Integer;
    public
      constructor Create(const AId: Integer);
    end;
  public type
    [BsonDiscriminator('TCIEE', True)]
    TTestClassIgnoreExtraElements = class
    public
      I: Integer;
      S: String;
    end;
  public type
    [BsonErrorOnExtraElements]
    TTestClassErrorOnExtraElements = class
    public
      I: Integer;
      S: String;
    end;
  public type
    TTestClassReadOnly = class
    private
      FPropReadOnlyInclude: String;
      FPropReadOnlyExclude: String;
      FPropReadOnlyIncludeAltName: String;
    public
      [BsonElement]
      property PropReadOnlyInclude: String read FPropReadOnlyInclude;

      property PropReadOnlyExclude: String read FPropReadOnlyExclude;

      [BsonElement('AltName')]
      property PropReadOnlyIncludeAltName: String read FPropReadOnlyIncludeAltName;
    end;
  public type
    TTestClassElementName = class
    private
      FPropNormalElementName: String;
      FPropAltElementName: String;
    public
      FieldNormalElementName: String;

      [BsonElement('#alt')]
      FieldAltElementName: String;
    public
      property PropNormalElementName: String read FPropNormalElementName write FPropNormalElementName;

      [BsonElement('$alt')]
      property PropAltElementName: String read FPropAltElementName write FPropAltElementName;
    end;
  public type
    TTestClassIgnore = class
    private
      FPropNormal: String;
      FPropIgnore: String;
    public
      FieldNormal: String;

      [BsonIgnore]
      FieldIgnore: String;
    public
      property PropNormal: String read FPropNormal write FPropNormal;

      [BsonIgnore]
      property PropIgnore: String read FPropIgnore write FPropIgnore;
    end;
  public type
    TTestClassIgnoreIfDefault = class
    private
      FPropIgnoreDefaultBoolean1: Boolean;
      FPropIgnoreDefaultBoolean2: Boolean;
      FPropIgnoreCustomDefaultBoolean1: Boolean;
      FPropIgnoreCustomDefaultBoolean2: Boolean;
      FPropIgnoreDefaultInt32_1: Integer;
      FPropIgnoreDefaultInt32_2: Integer;
      FPropIgnoreCustomDefaultInt32_1: Integer;
      FPropIgnoreCustomDefaultInt32_2: Integer;
      FPropIgnoreDefaultInt64_1: Int64;
      FPropIgnoreDefaultInt64_2: Int64;
      FPropIgnoreCustomDefaultInt64_1: Int64;
      FPropIgnoreCustomDefaultInt64_2: Int64;
      FPropIgnoreDefaultString1: String;
      FPropIgnoreDefaultString2: String;
      FPropIgnoreCustomDefaultString1: String;
      FPropIgnoreCustomDefaultString2: String;
      FPropIgnoreDouble1: Double;
      FPropIgnoreDouble2: Double;
      FPropIgnoreDateTime1: TDateTime;
      FPropIgnoreDateTime2: TDateTime;
      FPropIgnoreEnum1: TColor;
      FPropIgnoreEnum2: TColor;
      FPropIgnoreSet1: TColors;
      FPropIgnoreSet2: TColors;
      FPropIgnoreBytes1: TBytes;
      FPropIgnoreBytes2: TBytes;
      FPropIgnoreArray1: TArray<String>;
      FPropIgnoreArray2: TArray<String>;
      FPropIgnoreObject1: TFoo;
      FPropIgnoreObject2: TFoo;
      FPropIgnoreGuid1: TGUID;
      FPropIgnoreGuid2: TGUID;
      FPropIgnoreObjectId1: TgoObjectId;
      FPropIgnoreObjectId2: TgoObjectId;
    public
      [BsonIgnoreIfDefault]
      FieldIgnoreDefaultBoolean1: Boolean;

      [BsonIgnoreIfDefault]
      FieldIgnoreDefaultBoolean2: Boolean;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(True)]
      FieldIgnoreCustomDefaultBoolean1: Boolean;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(True)]
      FieldIgnoreCustomDefaultBoolean2: Boolean;

      [BsonIgnoreIfDefault]
      FieldIgnoreDefaultInt32_1: Integer;

      [BsonIgnoreIfDefault]
      FieldIgnoreDefaultInt32_2: Integer;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(42)]
      FieldIgnoreCustomDefaultInt32_1: Integer;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(42)]
      FieldIgnoreCustomDefaultInt32_2: Integer;

      [BsonIgnoreIfDefault]
      FieldIgnoreDefaultInt64_1: Int64;

      [BsonIgnoreIfDefault]
      FieldIgnoreDefaultInt64_2: Int64;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(-42)]
      FieldIgnoreCustomDefaultInt64_1: Int64;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(-42)]
      FieldIgnoreCustomDefaultInt64_2: Int64;

      [BsonIgnoreIfDefault]
      FieldIgnoreDefaultString1: String;

      [BsonIgnoreIfDefault]
      FieldIgnoreDefaultString2: String;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue('Foo')]
      FieldIgnoreCustomDefaultString1: String;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue('Foo')]
      FieldIgnoreCustomDefaultString2: String;

      [BsonIgnoreIfDefault]
      FieldIgnoreDouble1: Double;

      [BsonIgnoreIfDefault]
      FieldIgnoreDouble2: Double;

      [BsonIgnoreIfDefault]
      FieldIgnoreDateTime1: TDateTime;

      [BsonIgnoreIfDefault]
      FieldIgnoreDateTime2: TDateTime;

      [BsonIgnoreIfDefault]
      FieldIgnoreEnum1: TColor;

      [BsonIgnoreIfDefault]
      FieldIgnoreEnum2: TColor;

      [BsonIgnoreIfDefault]
      FieldIgnoreSet1: TColors;

      [BsonIgnoreIfDefault]
      FieldIgnoreSet2: TColors;

      [BsonIgnoreIfDefault]
      FieldIgnoreBytes1: TBytes;

      [BsonIgnoreIfDefault]
      FieldIgnoreBytes2: TBytes;

      [BsonIgnoreIfDefault]
      FieldIgnoreArray1: TArray<String>;

      [BsonIgnoreIfDefault]
      FieldIgnoreArray2: TArray<String>;

      [BsonIgnoreIfDefault]
      FieldIgnoreObject1: TFoo;

      [BsonIgnoreIfDefault]
      FieldIgnoreObject2: TFoo;

      [BsonIgnoreIfDefault]
      FieldIgnoreGuid1: TGUID;

      [BsonIgnoreIfDefault]
      FieldIgnoreGuid2: TGUID;

      [BsonIgnoreIfDefault]
      FieldIgnoreObjectId1: TgoObjectId;

      [BsonIgnoreIfDefault]
      FieldIgnoreObjectId2: TgoObjectId;
    public
      constructor Create;
      destructor Destroy; override;

      [BsonIgnoreIfDefault]
      property PropIgnoreDefaultBoolean1: Boolean read FPropIgnoreDefaultBoolean1 write FPropIgnoreDefaultBoolean1;

      [BsonIgnoreIfDefault]
      property PropIgnoreDefaultBoolean2: Boolean read FPropIgnoreDefaultBoolean2 write FPropIgnoreDefaultBoolean2;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(True)]
      property PropIgnoreCustomDefaultBoolean1: Boolean read FPropIgnoreCustomDefaultBoolean1 write FPropIgnoreCustomDefaultBoolean1;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(True)]
      property PropIgnoreCustomDefaultBoolean2: Boolean read FPropIgnoreCustomDefaultBoolean2 write FPropIgnoreCustomDefaultBoolean2;

      [BsonIgnoreIfDefault]
      property PropIgnoreDefaultInt32_1: Integer read FPropIgnoreDefaultInt32_1 write FPropIgnoreDefaultInt32_1;

      [BsonIgnoreIfDefault]
      property PropIgnoreDefaultInt32_2: Integer read FPropIgnoreDefaultInt32_2 write FPropIgnoreDefaultInt32_2;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(42)]
      property PropIgnoreCustomDefaultInt32_1: Integer read FPropIgnoreCustomDefaultInt32_1 write FPropIgnoreCustomDefaultInt32_1;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(42)]
      property PropIgnoreCustomDefaultInt32_2: Integer read FPropIgnoreCustomDefaultInt32_2 write FPropIgnoreCustomDefaultInt32_2;

      [BsonIgnoreIfDefault]
      property PropIgnoreDefaultInt64_1: Int64 read FPropIgnoreDefaultInt64_1 write FPropIgnoreDefaultInt64_1;

      [BsonIgnoreIfDefault]
      property PropIgnoreDefaultInt64_2: Int64 read FPropIgnoreDefaultInt64_2 write FPropIgnoreDefaultInt64_2;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(-42)]
      property PropIgnoreCustomDefaultInt64_1: Int64 read FPropIgnoreCustomDefaultInt64_1 write FPropIgnoreCustomDefaultInt64_1;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue(-42)]
      property PropIgnoreCustomDefaultInt64_2: Int64 read FPropIgnoreCustomDefaultInt64_2 write FPropIgnoreCustomDefaultInt64_2;

      [BsonIgnoreIfDefault]
      property PropIgnoreDefaultString1: String read FPropIgnoreDefaultString1 write FPropIgnoreDefaultString1;

      [BsonIgnoreIfDefault]
      property PropIgnoreDefaultString2: String read FPropIgnoreDefaultString2 write FPropIgnoreDefaultString2;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue('Foo')]
      property PropIgnoreCustomDefaultString1: String read FPropIgnoreCustomDefaultString1 write FPropIgnoreCustomDefaultString1;

      [BsonIgnoreIfDefault]
      [BsonDefaultValue('Foo')]
      property PropIgnoreCustomDefaultString2: String read FPropIgnoreCustomDefaultString2 write FPropIgnoreCustomDefaultString2;

      [BsonIgnoreIfDefault]
      property PropIgnoreDouble1: Double read FPropIgnoreDouble1 write FPropIgnoreDouble1;

      [BsonIgnoreIfDefault]
      property PropIgnoreDouble2: Double read FPropIgnoreDouble2 write FPropIgnoreDouble2;

      [BsonIgnoreIfDefault]
      property PropIgnoreDateTime1: TDateTime read FPropIgnoreDateTime1 write FPropIgnoreDateTime1;

      [BsonIgnoreIfDefault]
      property PropIgnoreDateTime2: TDateTime read FPropIgnoreDateTime2 write FPropIgnoreDateTime2;

      [BsonIgnoreIfDefault]
      property PropIgnoreEnum1: TColor read FPropIgnoreEnum1 write FPropIgnoreEnum1;

      [BsonIgnoreIfDefault]
      property PropIgnoreEnum2: TColor read FPropIgnoreEnum2 write FPropIgnoreEnum2;

      [BsonIgnoreIfDefault]
      property PropIgnoreSet1: TColors read FPropIgnoreSet1 write FPropIgnoreSet1;

      [BsonIgnoreIfDefault]
      property PropIgnoreSet2: TColors read FPropIgnoreSet2 write FPropIgnoreSet2;

      [BsonIgnoreIfDefault]
      property PropIgnoreBytes1: TBytes read FPropIgnoreBytes1 write FPropIgnoreBytes1;

      [BsonIgnoreIfDefault]
      property PropIgnoreBytes2: TBytes read FPropIgnoreBytes2 write FPropIgnoreBytes2;

      [BsonIgnoreIfDefault]
      property PropIgnoreArray1: TArray<String> read FPropIgnoreArray1 write FPropIgnoreArray1;

      [BsonIgnoreIfDefault]
      property PropIgnoreArray2: TArray<String> read FPropIgnoreArray2 write FPropIgnoreArray2;

      [BsonIgnoreIfDefault]
      property PropIgnoreObject1: TFoo read FPropIgnoreObject1 write FPropIgnoreObject1;

      [BsonIgnoreIfDefault]
      property PropIgnoreObject2: TFoo read FPropIgnoreObject2 write FPropIgnoreObject2;

      [BsonIgnoreIfDefault]
      property PropIgnoreGuid1: TGUID read FPropIgnoreGuid1 write FPropIgnoreGuid1;

      [BsonIgnoreIfDefault]
      property PropIgnoreGuid2: TGUID read FPropIgnoreGuid2 write FPropIgnoreGuid2;

      [BsonIgnoreIfDefault]
      property PropIgnoreObjectId1: TgoObjectId read FPropIgnoreObjectId1 write FPropIgnoreObjectId1;

      [BsonIgnoreIfDefault]
      property PropIgnoreObjectId2: TgoObjectId read FPropIgnoreObjectId2 write FPropIgnoreObjectId2;
    end;
  public
    [Test] procedure TestIgnoreExtraElements;
    [Test] procedure TestErrorOnExtraElements;
    [Test] procedure TestReadOnly;
    [Test] procedure TestElementName;
    [Test] procedure TestIgnore;
    [Test] procedure TestIgnoreIfDefault;
  end;

type
  TestCustomSerialization = class
  public type
    TCompoundId = record
    private
      FPart1: String;
      FPart2: String;
        function GetComplete: String;
        procedure SetComplete(const Value: String);
    public
      property Part1: String read FPart1 write FPart1;
      property Part2: String read FPart2 write FPart2;
      property Complete: String read GetComplete write SetComplete;
    end;
  public type
    TCompoundIdSerializer = class(TgoBsonSerializer.TCustomSerializer)
    public
      procedure Serialize(const AValue; const AWriter: IgoBsonBaseWriter); override;
      procedure Deserialize(const AReader: IgoBsonBaseReader; out AValue); override;
    end;
  type
    TTestRecord = record
    public
      Id: TCompoundId;
    end;
  public
    [Test] procedure TestCustomRecordSerializer;
  end;

implementation

uses
  System.DateUtils;

{ TestBsonSerializeBoolean }

procedure TestBsonSerializeBoolean.TestFalse;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : false, "B" : false, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "false" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeBoolean.TestTrue;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  FillChar(R, SizeOf(R), True);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : true, "B" : true, "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "true" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeBoolean.TTestRecord }

procedure TestBsonSerializeBoolean.TTestRecord.Initialize;
begin
  FillChar(Self, SizeOf(Self), False);
end;

{ TestBsonSerializeInt8 }

procedure TestBsonSerializeInt8.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Int8.MaxValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 127, "D" : 127.0, "I" : 127, "L" : NumberLong(127), "S" : "127" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt8.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Int8.MinValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -128, "D" : -128.0, "I" : -128, "L" : NumberLong(-128), "S" : "-128" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt8.TestMinusOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(-1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -1, "D" : -1.0, "I" : -1, "L" : NumberLong(-1), "S" : "-1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt8.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1, "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt8.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeInt8.TTestRecord }

procedure TestBsonSerializeInt8.TTestRecord.Initialize(const AValue: Int8);
begin
  N := AValue;
  D := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeInt16 }

procedure TestBsonSerializeInt16.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Int16.MaxValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 32767, "D" : 32767.0, "I" : 32767, "L" : NumberLong(32767), "S" : "32767" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt16.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Int16.MinValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -32768, "D" : -32768.0, "I" : -32768, "L" : NumberLong(-32768), "S" : "-32768" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt16.TestMinusOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(-1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -1, "D" : -1.0, "I" : -1, "L" : NumberLong(-1), "S" : "-1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt16.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1, "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt16.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeInt16.TTestRecord }

procedure TestBsonSerializeInt16.TTestRecord.Initialize(const AValue: Int16);
begin
  N := AValue;
  D := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeInt32 }

procedure TestBsonSerializeInt32.TestMax;
var
  R, Rehydrated: TTestClass;
  Json: String;
  Bson, Actual: TBytes;
begin
  R := TTestClass.Create(Integer.MaxValue);
  Rehydrated := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 2147483647, "D" : 2147483647.0, "I" : 2147483647, "L" : NumberLong(2147483647), "S" : "2147483647" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.Free;
  Rehydrated.Free;
end;

procedure TestBsonSerializeInt32.TestMin;
var
  R, Rehydrated: TTestClass;
  Json: String;
  Bson, Actual: TBytes;
begin
  R := TTestClass.Create(Integer.MinValue);
  Rehydrated := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -2147483648, "D" : -2147483648.0, "I" : -2147483648, "L" : NumberLong(-2147483648), "S" : "-2147483648" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.Free;
  Rehydrated.Free;
end;

procedure TestBsonSerializeInt32.TestMinusOne;
var
  R, Rehydrated: TTestClass;
  Json: String;
  Bson, Actual: TBytes;
begin
  R := TTestClass.Create(-1);
  Rehydrated := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -1, "D" : -1.0, "I" : -1, "L" : NumberLong(-1), "S" : "-1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.Free;
  Rehydrated.Free;
end;

procedure TestBsonSerializeInt32.TestOne;
var
  R, Rehydrated: TTestClass;
  Json: String;
  Bson, Actual: TBytes;
begin
  R := TTestClass.Create(1);
  Rehydrated := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1, "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.Free;
  Rehydrated.Free;
end;

procedure TestBsonSerializeInt32.TestZero;
var
  R, Rehydrated: TTestClass;
  Json: String;
  Bson, Actual: TBytes;
begin
  R := TTestClass.Create(0);
  Rehydrated := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.Free;
  Rehydrated.Free;
end;

{ TestBsonSerializeInt32.TTestClass }

constructor TestBsonSerializeInt32.TTestClass.Create(const AValue: Int32);
begin
  inherited Create;
  N := AValue;
  FD := AValue;
  FI := AValue;
  FL := AValue;
  FS := AValue;
end;
function TestBsonSerializeInt32.TTestClass.GetD: Int32;
begin
  Result := FD;
end;

function TestBsonSerializeInt32.TTestClass.GetL: Int32;
begin
  Result := FL;
end;

procedure TestBsonSerializeInt32.TTestClass.SetI(const Value: Int32);
begin
  FI := Value;
end;

procedure TestBsonSerializeInt32.TTestClass.SetL(const Value: Int32);
begin
  FL := Value;
end;

{ TestBsonSerializeInt64 }

procedure TestBsonSerializeInt64.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Int64.MaxValue);
  R.D := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NumberLong("9223372036854775807"), "D" : 0.0, "I" : -1, "L" : NumberLong("9223372036854775807"), "S" : "9223372036854775807" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt64.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Int64.MinValue);
  R.D := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NumberLong("-9223372036854775808"), "D" : 0.0, "I" : 0, "L" : NumberLong("-9223372036854775808"), "S" : "-9223372036854775808" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt64.TestMinusOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(-1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NumberLong(-1), "D" : -1.0, "I" : -1, "L" : NumberLong(-1), "S" : "-1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt64.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NumberLong(1), "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeInt64.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NumberLong(0), "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeInt64.TTestRecord }

procedure TestBsonSerializeInt64.TTestRecord.Initialize(const AValue: Int64);
begin
  N := AValue;
  D := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeUInt8 }

procedure TestBsonSerializeUInt8.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(UInt8.MaxValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 255, "D" : 255.0, "I" : 255, "L" : NumberLong(255), "S" : "255" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt8.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(UInt8.MinValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt8.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1, "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt8.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeUInt8.TTestRecord }

procedure TestBsonSerializeUInt8.TTestRecord.Initialize(const AValue: UInt8);
begin
  N := AValue;
  D := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeUInt16 }

procedure TestBsonSerializeUInt16.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(UInt16.MaxValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 65535, "D" : 65535.0, "I" : 65535, "L" : NumberLong(65535), "S" : "65535" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt16.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(UInt16.MinValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt16.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1, "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt16.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeUInt16.TTestRecord }

procedure TestBsonSerializeUInt16.TTestRecord.Initialize(const AValue: UInt16);
begin
  N := AValue;
  D := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeUInt32 }

procedure TestBsonSerializeUInt32.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(UInt32.MaxValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -1, "D" : 4294967295.0, "I" : -1, "L" : NumberLong("4294967295"), "S" : "4294967295" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt32.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(UInt32.MinValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt32.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1, "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt32.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeUInt32.TTestRecord }

procedure TestBsonSerializeUInt32.TTestRecord.Initialize(const AValue: UInt32);
begin
  N := AValue;
  D := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeUInt64 }

procedure TestBsonSerializeUInt64.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(UInt64.MaxValue);
  R.D := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NumberLong(-1), "D" : 0.0, "I" : -1, "L" : NumberLong(-1), "S" : "18446744073709551615" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt64.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(UInt64.MinValue);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NumberLong(0), "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt64.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NumberLong(1), "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeUInt64.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NumberLong(0), "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeUInt64.TTestRecord }

procedure TestBsonSerializeUInt64.TTestRecord.Initialize(const AValue: UInt64);
begin
  N := AValue;
  D := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeSingle }

procedure TestBsonSerializeSingle.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Single.MaxValue);
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 3.40282346638529E38, "D" : 3.40282346638529E38, "I" : 0, "L" : NumberLong(0), "S" : "3.40282346638529E38" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSingle.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Single.MinValue);
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -3.40282346638529E38, "D" : -3.40282346638529E38, "I" : 0, "L" : NumberLong(0), "S" : "-3.40282346638529E38" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSingle.TestMinusOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(-1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -1.0, "D" : -1.0, "I" : -1, "L" : NumberLong(-1), "S" : "-1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSingle.TestNaN;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Single.NaN);
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NaN, "D" : NaN, "I" : 0, "L" : NumberLong(0), "S" : "NaN" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSingle.TestNegativeInfinity;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Single.NegativeInfinity);
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -Infinity, "D" : -Infinity, "I" : 0, "L" : NumberLong(0), "S" : "-Infinity" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSingle.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1.0, "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSingle.TestOnePointFive;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1.5);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1.5, "D" : 1.5, "I" : 1, "L" : NumberLong(1), "S" : "1.5" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSingle.TestPositiveInfinity;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Single.PositiveInfinity);
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : Infinity, "D" : Infinity, "I" : 0, "L" : NumberLong(0), "S" : "Infinity" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSingle.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0.0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeSingle.TTestRecord }

procedure TestBsonSerializeSingle.TTestRecord.Initialize(const AValue: Single);
begin
  N := AValue;
  D := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeDouble }

procedure TestBsonSerializeDouble.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0.99 * Double.MaxValue); // to prevent Delphi StrToFloat exception
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1.77971620351369E308, "D" : 1.77971620351369E308, "I" : 0, "L" : NumberLong(0), "S" : "1.77971620351369E308" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDouble.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0.99 * Double.MinValue); // to prevent Delphi StrToFloat exception
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -1.77971620351369E308, "D" : -1.77971620351369E308, "I" : 0, "L" : NumberLong(0), "S" : "-1.77971620351369E308" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDouble.TestMinusOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(-1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -1.0, "D" : -1.0, "I" : -1, "L" : NumberLong(-1), "S" : "-1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDouble.TestNaN;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Double.NaN);
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : NaN, "D" : NaN, "I" : 0, "L" : NumberLong(0), "S" : "NaN" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDouble.TestNegativeInfinity;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Double.NegativeInfinity);
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : -Infinity, "D" : -Infinity, "I" : 0, "L" : NumberLong(0), "S" : "-Infinity" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDouble.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1.0, "D" : 1.0, "I" : 1, "L" : NumberLong(1), "S" : "1" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDouble.TestOnePointFive;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(1.5);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1.5, "D" : 1.5, "I" : 1, "L" : NumberLong(1), "S" : "1.5" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDouble.TestPositiveInfinity;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(Double.PositiveInfinity);
  R.I := 0;
  R.L := 0;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : Infinity, "D" : Infinity, "I" : 0, "L" : NumberLong(0), "S" : "Infinity" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDouble.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0.0, "D" : 0.0, "I" : 0, "L" : NumberLong(0), "S" : "0" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeDouble.TTestRecord }

procedure TestBsonSerializeDouble.TTestRecord.Initialize(const AValue: Double);
begin
  N := AValue;
  D := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeChar }

procedure TestBsonSerializeChar.TestA;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize('A');
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : "A", "S" : "A", "I" : 65, "L" : NumberLong(65) }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeChar.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(#$FFFF);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : "\uffff", "S" : "\uffff", "I" : 65535, "L" : NumberLong(65535) }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeChar.TestOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(#1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : "\u0001", "S" : "\u0001", "I" : 1, "L" : NumberLong(1) }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeChar.TestZero;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(#0);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : "\u0000", "S" : "\u0000", "I" : 0, "L" : NumberLong(0) }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeChar.TTestRecord }

procedure TestBsonSerializeChar.TTestRecord.Initialize(const AValue: Char);
begin
  N := AValue;
  S := AValue;
  I := AValue;
  L := AValue;
end;

{ TestBsonSerializeString }

procedure TestBsonSerializeString.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize('');
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : "", "S" : "", "O" : ObjectId("000000000000000000000000"), "Y" : { "$symbol" : "" } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeString.TestHelloWorld;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize('Hello World');
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : "Hello World", "S" : "Hello World", "O" : ObjectId("000000000000000000000000"), "Y" : { "$symbol" : "Hello World" } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeString.TestObjectId;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize('123456789012345678901234');
  R.O := '123456789012345678901234';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : "123456789012345678901234", "S" : "123456789012345678901234", "O" : ObjectId("123456789012345678901234"), "Y" : { "$symbol" : "123456789012345678901234" } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeString.TTestRecord }

procedure TestBsonSerializeString.TTestRecord.Initialize(const AValue: String);
begin
  N := AValue;
  S := AValue;
  O := '000000000000000000000000';
  Y := AValue;
end;

{ TestBsonSerializeDateTime }

procedure TestBsonSerializeDateTime.TestMax;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(EncodeDateTime(9999, 12, 31, 23, 59, 59, 999));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : ISODate("9999-12-31T23:59:59.999Z"), "D" : ISODate("9999-12-31T23:59:59.999Z"), ' +
    '"S" : "9999-12-31T23:59:59.9990000", "L" : NumberLong("3155378975999990000"), ' +
    '"O" : { "DateTime" : ISODate("9999-12-31T23:59:59.999Z"), "Ticks" : NumberLong("3155378975999990000") } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDateTime.TestMin;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(EncodeDateTime(1, 1, 1, 0, 0, 0, 0));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : ISODate("0001-01-01T00:00:00Z"), "D" : ISODate("0001-01-01T00:00:00Z"), ' +
    '"S" : "0001-01-01T00:00:00", "L" : NumberLong(0), ' +
    '"O" : { "DateTime" : ISODate("0001-01-01T00:00:00Z"), "Ticks" : NumberLong(0) } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeDateTime.TestSample;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(EncodeDateTime(2016, 5, 1, 15, 28, 57, 784));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : ISODate("2016-05-01T15:28:57.784Z"), "D" : ISODate("2016-05-01T15:28:57.784Z"), ' +
    '"S" : "2016-05-01T15:28:57.7840000", "L" : NumberLong("635977133377840000"), ' +
    '"O" : { "DateTime" : ISODate("2016-05-01T15:28:57.784Z"), "Ticks" : NumberLong("635977133377840000") } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeDateTime.TTestRecord }

procedure TestBsonSerializeDateTime.TTestRecord.Initialize(
  const AValue: TDateTime);
begin
  N := AValue;
  D := AValue;
  S := AValue;
  L := AValue;
  O := AValue;
end;

{ TestBsonSerializeGuid }

procedure TestBsonSerializeGuid.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TGUID.Empty);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : UUID("00000000-0000-0000-0000-000000000000"), ' +
                '"B" : UUID("00000000-0000-0000-0000-000000000000"), ' +
                '"S" : "00000000-0000-0000-0000-000000000000" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeGuid.TestSample;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TGUID.Create('{01020304-0506-0708-090A-0B0C0D0E0F10}'));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : UUID("01020304-0506-0708-090a-0b0c0d0e0f10"), ' +
                '"B" : UUID("01020304-0506-0708-090a-0b0c0d0e0f10"), ' +
                '"S" : "01020304-0506-0708-090a-0b0c0d0e0f10" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeGuid.TTestRecord }

procedure TestBsonSerializeGuid.TTestRecord.Initialize(const AValue: TGUID);
begin
  N := AValue;
  B := AValue;
  S := AValue;
end;

{ TestBsonSerializeObjectId }

procedure TestBsonSerializeObjectId.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TgoObjectId.Empty);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : ObjectId("000000000000000000000000"), ' +
                '"O" : ObjectId("000000000000000000000000"), ' +
                '"S" : "000000000000000000000000" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeObjectId.TestSample;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TgoObjectId.Create('0102030405060708090A0B0C'));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : ObjectId("0102030405060708090a0b0c"), ' +
                '"O" : ObjectId("0102030405060708090a0b0c"), ' +
                '"S" : "0102030405060708090a0b0c" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeObjectId.TTestRecord }

procedure TestBsonSerializeObjectId.TTestRecord.Initialize(
  const AValue: TgoObjectId);
begin
  N := AValue;
  O := AValue;
  S := AValue;
end;

{ TestBsonSerializeTBytes }

procedure TestBsonSerializeTBytes.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(nil);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : new BinData(0, ""), "B" : new BinData(0, ""), "S" : "" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeTBytes.TestLengthNine;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : new BinData(0, "AQIDBAUGBwgJ"), "B" : new BinData(0, "AQIDBAUGBwgJ"), "S" : "010203040506070809" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeTBytes.TestLengthOne;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TBytes.Create(1));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : new BinData(0, "AQ=="), "B" : new BinData(0, "AQ=="), "S" : "01" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeTBytes.TestLengthTwo;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TBytes.Create(1, 2));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : new BinData(0, "AQI="), "B" : new BinData(0, "AQI="), "S" : "0102" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeTBytes.TTestRecord }

procedure TestBsonSerializeTBytes.TTestRecord.Initialize(const AValue: TBytes);
begin
  N := AValue;
  B := AValue;
  S := AValue;
end;

{ TestBsonSerializeEnum }

procedure TestBsonSerializeEnum.TestA;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TEnum.A);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "I" : 0, "L" : NumberLong(0), "S" : "A" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeEnum.TestB;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TEnum.B);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1, "I" : 1, "L" : NumberLong(1), "S" : "B" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeEnum.TestInvalid;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TEnum(2));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 2, "I" : 2, "L" : NumberLong(2), "S" : "2" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeEnum.TTestRecord }

procedure TestBsonSerializeEnum.TTestRecord.Initialize(const AValue: TEnum);
begin
  N := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonSerializeSet }

procedure TestBsonSerializeSet.TestA;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize([TEnum.A]);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 1, "I" : 1, "L" : NumberLong(1), "S" : "A" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSet.TestAB;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize([TEnum.A, TEnum.B]);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 3, "I" : 3, "L" : NumberLong(3), "S" : "A, B" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSet.TestB;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize([TEnum.B]);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 2, "I" : 2, "L" : NumberLong(2), "S" : "B" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonSerializeSet.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize([]);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : 0, "I" : 0, "L" : NumberLong(0), "S" : "" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonSerializeSet.TTestRecord }

procedure TestBsonSerializeSet.TTestRecord.Initialize(const AValue: TSet);
begin
  N := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonRecord }

procedure TestBsonRecord.TestRecord;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A.X := 42;
  R.A.S := 'Foo';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : { "X" : 42, "S" : "Foo" } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{$IF (RTLVersion >= 34)}

{ TestBsonCustomManagedRecord.TRec }

class operator TestBsonCustomManagedRecord.TRec.Initialize(out ADest: TRec);
begin
  ADest.Y := 42;
  Inc(InstanceCount);
end;

class operator TestBsonCustomManagedRecord.TRec.Finalize(var ADest: TRec);
begin
  ADest.Y := 0;
  Dec(InstanceCount);
end;

class operator TestBsonCustomManagedRecord.TRec.Assign(var ADest: TRec;
  const [ref] ASrc: TRec);
begin
  ADest.Y := ASrc.Y * 2;
end;

{ TestBsonCustomManagedRecord.TTestRecord }

class operator TestBsonCustomManagedRecord.TTestRecord.Initialize(out ADest: TTestRecord);
begin
  ADest.X := -123;
  Inc(InstanceCount);
end;

class operator TestBsonCustomManagedRecord.TTestRecord.Finalize(var ADest: TTestRecord);
begin
  ADest.X := 0;
  Dec(InstanceCount);
end;

class operator TestBsonCustomManagedRecord.TTestRecord.Assign(var ADest: TTestRecord;
  const [ref] ASrc: TTestRecord);
begin
  ADest.X := -ASrc.X;
  ADest.R := ASrc.R;
end;

{ TestBsonCustomManagedRecord }

procedure TestBsonCustomManagedRecord.TestCustomManagedRecord;
var
  Json: String;
begin
  begin
    var R1, R2, Rehydrated: TTestRecord;
    Assert.AreEqual(-123, R1.X);
    Assert.AreEqual(42, R1.R.Y);
    Assert.AreEqual(-123, R2.X);
    Assert.AreEqual(42, R2.R.Y);
    Assert.AreEqual(-123, Rehydrated.X);
    Assert.AreEqual(42, Rehydrated.R.Y);
    Assert.AreEqual(3, TTestRecord.InstanceCount);
    Assert.AreEqual(3, TRec.InstanceCount);

    R1 := R2;
    Assert.AreEqual(123, R1.X);
    Assert.AreEqual(84, R1.R.Y);
    Assert.IsTrue(TgoBsonSerializer.TrySerialize(R1, TgoJsonWriterSettings.Shell, Json));
    Assert.AreEqual('{ "X" : 123, "R" : { "Y" : 84 } }', Json);
    Assert.AreEqual(3, TTestRecord.InstanceCount);
    Assert.AreEqual(3, TRec.InstanceCount);

    Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Json, Rehydrated));
    Assert.AreEqual(123, Rehydrated.X);
    Assert.AreEqual(84, Rehydrated.R.Y);
  end;
  Assert.AreEqual(0, TTestRecord.InstanceCount);
  Assert.AreEqual(0, TRec.InstanceCount);
end;

{$ENDIF !(RTLVersion >= 34)}

{ TestBsonObject }

procedure TestBsonObject.TestNilToNil;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : null }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Rehydrated.A := nil;
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonObject.TestNilToObject;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : null }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));

  Rehydrated.A := TObj.Create(1, 'A');
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));
  Assert.IsNotNull(Rehydrated.A);
  Assert.AreEqual(1, Rehydrated.A.X);
  Assert.AreEqual('A', Rehydrated.A.S);
  FreeAndNil(Rehydrated.A);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  Rehydrated.A.Free;
end;

procedure TestBsonObject.TestObjectToNil;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TObj.Create(42, 'Foo');
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : { "X" : 42, "S" : "Foo" } }', Json);

  Rehydrated.A := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.A.Free;
  Rehydrated.A.Free;
end;

procedure TestBsonObject.TestObjectToObject;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TObj.Create(42, 'Foo');
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : { "X" : 42, "S" : "Foo" } }', Json);

  Rehydrated.A := TObj.Create(1, 'Bar');
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));
  Assert.IsNotNull(Rehydrated.A);
  Assert.AreEqual(42, Rehydrated.A.X);
  Assert.AreEqual('Foo', Rehydrated.A.S);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.A.Free;
  Rehydrated.A.Free;
end;

{ TestBsonObject.TTestRecord }

procedure TestBsonObject.TTestRecord.Initialize;
begin
  { Don't clear fields }
end;

{ TestBsonObject.TObj }

constructor TestBsonObject.TObj.Create(const AX: Integer; const AStr: String);
begin
  inherited Create;
  FX := AX;
  FS := AStr;
end;

{ TestBsonArrayOfInteger }

procedure TestBsonArrayOfInteger.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonArrayOfInteger.TestLength1;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TArray<Integer>.Create(1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [1] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonArrayOfInteger.TestLength9;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TArray<Integer>.Create(1, 2, 3, 4, 5, 6, 7, 8, 9);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [1, 2, 3, 4, 5, 6, 7, 8, 9] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonArrayOfString }

procedure TestBsonArrayOfString.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonArrayOfString.TestLength1;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TArray<String>.Create('Foo');
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : ["Foo"] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonArrayOfString.TestLength2;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TArray<String>.Create('Foo', 'Bar');
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : ["Foo", "Bar"] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonArrayOfEnum }

procedure TestBsonArrayOfEnum.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(nil);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : [], "I" : [], "L" : [], "S" : [] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonArrayOfEnum.TestLength1;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TArray<TEnum>.Create(TEnum.A));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : [0], "I" : [0], "L" : [NumberLong(0)], "S" : ["A"] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonArrayOfEnum.TestLength2;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.Initialize(TArray<TEnum>.Create(TEnum.B, TEnum.A));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "N" : [1, 0], "I" : [1, 0], "L" : [NumberLong(1), NumberLong(0)], "S" : ["B", "A"] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonArrayOfEnum.TTestRecord }

procedure TestBsonArrayOfEnum.TTestRecord.Initialize(
  const AValue: TArray<TEnum>);
begin
  N := AValue;
  I := AValue;
  L := AValue;
  S := AValue;
end;

{ TestBsonArrayOfRecord }

procedure TestBsonArrayOfRecord.TestDynArrayProp;
var
  R, Rehydrated: TTestClass;
  Json: String;
  Bson, Actual: TBytes;
begin
  R := TTestClass.Create;
  Rehydrated := nil;
  R.FValues.Add(TRec.Create(1, 'Foo'));
  R.FValues.Add(TRec.Create(2, 'Bar'));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [{ "X" : 1, "S" : "Foo" }, { "X" : 2, "S" : "Bar" }] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.Free;
  Rehydrated.Free;
end;

procedure TestBsonArrayOfRecord.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonArrayOfRecord.TestLength1;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TArray<TRec>.Create(TRec.Create(1, 'Foo'));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [{ "X" : 1, "S" : "Foo" }] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonArrayOfRecord.TestLength2;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TArray<TRec>.Create(TRec.Create(1, 'Foo'), TRec.Create(2, 'Bar'));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [{ "X" : 1, "S" : "Foo" }, { "X" : 2, "S" : "Bar" }] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestBsonArrayOfRecord.TRec }

constructor TestBsonArrayOfRecord.TRec.Create(const AX: Integer;
  const AStr: String);
begin
  X := AX;
  S := AStr;
end;

{ TestBsonArrayOfRecord.TTestClass }

constructor TestBsonArrayOfRecord.TTestClass.Create;
begin
  inherited Create;
  FValues := TList<TRec>.Create;
end;

destructor TestBsonArrayOfRecord.TTestClass.Destroy;
begin
  FValues.Free;
  inherited;
end;

function TestBsonArrayOfRecord.TTestClass.GetA: TArray<TRec>;
begin
  Result := FValues.ToArray;
end;

procedure TestBsonArrayOfRecord.TTestClass.SetA(const Value: TArray<TRec>);
var
  R: TRec;
begin
  FValues.Clear;
  for R in Value do
    FValues.Add(R);
end;

{ TestBsonArrayOfObject }

procedure TestBsonArrayOfObject.TestEmpty;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := nil;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

procedure TestBsonArrayOfObject.TestLength1;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TArray<TObj>.Create(TObj.Create(1, 'Foo'));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [{ "X" : 1, "S" : "Foo" }] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.A[0].Free;
  Rehydrated.A[0].Free;
end;

procedure TestBsonArrayOfObject.TestLength2;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.A := TArray<TObj>.Create(TObj.Create(1, 'Foo'), TObj.Create(2, 'Bar'));
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "A" : [{ "X" : 1, "S" : "Foo" }, { "X" : 2, "S" : "Bar" }] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.A[0].Free;
  R.A[1].Free;
  Rehydrated.A[0].Free;
  Rehydrated.A[1].Free;
end;

{ TestBsonArrayOfObject.TObj }

constructor TestBsonArrayOfObject.TObj.Create(const AX: Integer;
  const AStr: String);
begin
  inherited Create;
  FX := AX;
  FS := AStr;
end;

{ TestBsonStandAloneArray }

procedure TestBsonStandAloneArray.TestSimple;
var
  A, Rehydrated: TArray<TRec>;
  Json: String;
begin
  SetLength(A, 2);
  A[0].X := 1;
  A[0].S := 'Foo';
  A[1].X := 2;
  A[1].S := 'Bar';

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(A, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('[{ "X" : 1, "S" : "Foo" }, { "X" : 2, "S" : "Bar" }]', Json);

  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Json, Rehydrated));

  Assert.AreEqual(2, Length(Rehydrated));
  Assert.AreEqual(1, Rehydrated[0].X);
  Assert.AreEqual('Foo', Rehydrated[0].S);
  Assert.AreEqual(2, Rehydrated[1].X);
  Assert.AreEqual('Bar', Rehydrated[1].S);
end;

{ TestBsonSerializePrimitiveTypesInRecord }

procedure TestBsonSerializePrimitiveTypesInRecord.TestAllTypes;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  R.B := True;
  R.I8 := -128;
  R.I16 := -32768;
  R.I32 := -2147483648;
  R.I64 := -9223372036854775808;
  R.U8 := 255;
  R.U16 := 65535;
  R.U32 := 4294967295;
  R.U64 := 18446744073709551615;
  R.F32 := 1.5e30;
  R.F64 := -1.5e300;
  R.C := #13;
  R.S := 'Foo';
  R.DT := EncodeDateTime(2016, 5, 1, 15, 28, 57, 784);
  R.G := TGUID.Create('{01020304-0506-0708-090A-0B0C0D0E0F10}');
  R.Oid := TgoObjectId.Create('0102030405060708090A0B0C');
  R.BA := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9);
  R.E := TEnum.B;
  R.St := [TEnum.A, TEnum.B];
  R.R.X := 42;
  R.R.S := 'Foo';
  R.O1 := nil;
  R.O2 := TObj.Create(43, 'Bar');
  R.O3 := TObj.Create(44, 'Baz');
  R.AoS := TArray<String>.Create('Foo', 'Bar');
  R.AoI := TArray<Integer>.Create(42, 1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "B" : true, "I8" : -128, "I16" : -32768, "I32" : -2147483648, ' +
    '"I64" : NumberLong("-9223372036854775808"), "U8" : 255, "U16" : 65535, ' +
    '"U32" : -1, "U64" : NumberLong(-1), "F32" : 1.49999994701334E30, ' +
    '"F64" : -1.5E300, "C" : "\r", "S" : "Foo", "DT" : ISODate("2016-05-01T15:28:57.784Z"), ' +
    '"G" : UUID("01020304-0506-0708-090a-0b0c0d0e0f10"), ' +
    '"Oid" : ObjectId("0102030405060708090a0b0c"), ' +
    '"BA" : new BinData(0, "AQIDBAUGBwgJ"), "E" : 1, "St" : 3, ' +
    '"R" : { "X" : 42, "S" : "Foo" }, "O1" : null, "O2" : { "X" : 43, "S" : "Bar" }, ' +
    '"O3" : { "X" : 44, "S" : "Baz" }, "AoS" : ["Foo", "Bar"], "AoI" : [42, 1] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.O2.Free;
  R.O3.Free;
  Rehydrated.O2.Free;
  Rehydrated.O3.Free;
end;

{ TestBsonSerializePrimitiveTypesInRecord.TObj }

constructor TestBsonSerializePrimitiveTypesInRecord.TObj.Create;
begin
  inherited Create;
end;

constructor TestBsonSerializePrimitiveTypesInRecord.TObj.Create(
  const AX: Integer; const AStr: String);
begin
  inherited Create;
  FX := AX;
  FS := AStr;
end;

{ TestBsonSerializePrimitiveTypesInClass }

procedure TestBsonSerializePrimitiveTypesInClass.TestAllTypes;
var
  R, Rehydrated: TTestClass;
  Json: String;
  Bson, Actual: TBytes;
begin
  R := TTestClass.Create;
  R.B := True;
  R.I8 := -128;
  R.I16 := -32768;
  R.I32 := -2147483648;
  R.I64 := -9223372036854775808;
  R.U8 := 255;
  R.U16 := 65535;
  R.U32 := 4294967295;
  R.U64 := 18446744073709551615;
  R.F32 := 1.5e30;
  R.F64 := -1.5e300;
  R.C := #13;
  R.S := 'Foo';
  R.DT := EncodeDateTime(2016, 5, 1, 15, 28, 57, 784);
  R.G := TGUID.Create('{01020304-0506-0708-090A-0B0C0D0E0F10}');
  R.Oid := TgoObjectId.Create('0102030405060708090A0B0C');
  R.BA := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9);
  R.E := TEnum.B;
  R.St := [TEnum.A, TEnum.B];
  R.R := TRec.Create(42, 'Foo');
  R.O2.X := 43;
  R.O2.S := 'Bar';
  R.O3 := TObj.Create(44, 'Baz');
  R.AoS := TArray<String>.Create('Foo', 'Bar');
  R.AoI := TArray<Integer>.Create(42, 1);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "B" : true, "I8" : -128, "I16" : -32768, "I32" : -2147483648, ' +
    '"I64" : NumberLong("-9223372036854775808"), "U8" : 255, "U16" : 65535, ' +
    '"U32" : -1, "U64" : NumberLong(-1), "F32" : 1.49999994701334E30, ' +
    '"F64" : -1.5E300, "C" : "\r", "S" : "Foo", "DT" : ISODate("2016-05-01T15:28:57.784Z"), ' +
    '"G" : UUID("01020304-0506-0708-090a-0b0c0d0e0f10"), ' +
    '"Oid" : ObjectId("0102030405060708090a0b0c"), ' +
    '"BA" : new BinData(0, "AQIDBAUGBwgJ"), "E" : 1, "St" : 3, ' +
    '"R" : { "X" : 42, "S" : "Foo" }, "O1" : null, "O2" : { "X" : 43, "S" : "Bar" }, ' +
    '"O3" : { "X" : 44, "S" : "Baz" }, "AoS" : ["Foo", "Bar"], "AoI" : [42, 1] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Rehydrated := nil;
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  R.Free;
  Rehydrated.Free;
end;

{ TestBsonSerializePrimitiveTypesInClass.TTestClass }

constructor TestBsonSerializePrimitiveTypesInClass.TTestClass.Create;
begin
  inherited;
  FO2 := TObj.Create;
end;

destructor TestBsonSerializePrimitiveTypesInClass.TTestClass.Destroy;
begin
  FO1.Free;
  FO2.Free;
  FO3.Free;
  inherited;
end;

function TestBsonSerializePrimitiveTypesInClass.TTestClass.GetOid: TgoObjectId;
begin
  Result := FOid;
end;

procedure TestBsonSerializePrimitiveTypesInClass.TTestClass.SetOid(
  const Value: TgoObjectId);
begin
  FOid := Value;
end;

{ TestBsonSerializePrimitiveTypesInClass.TRec }

constructor TestBsonSerializePrimitiveTypesInClass.TRec.Create(
  const AX: Integer; const AStr: String);
begin
  X := AX;
  S := AStr;
end;

{ TestBsonSerializePrimitiveTypesInClass.TObj }

constructor TestBsonSerializePrimitiveTypesInClass.TObj.Create;
begin
  inherited Create;
end;

constructor TestBsonSerializePrimitiveTypesInClass.TObj.Create(
  const AX: Integer; const AStr: String);
begin
  inherited Create;
  FX := AX;
  FS := AStr;
end;

{ TestBsonSerializer }

procedure TestBsonSerializer.TestSerializeEmployee;
var
  Employee, Rehydrated: TEmployee;
  Json: String;
  Bson, Actual: TBytes;
begin
  Employee := TEmployee.Create;
  Employee.EmployeeId := TgoObjectId.Create('0102030405060708090a0b0c');
  Employee.FirstName := 'John';
  Employee.LastName := 'Smith';
  Employee.DateOfBirth := EncodeDate(2001, 2, 3);
  Rehydrated := nil;

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Employee, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "EmployeeId" : ObjectId("0102030405060708090a0b0c"), ' +
    '"FirstName" : "John", "LastName" : "Smith", ' +
    '"DateOfBirth" : ISODate("2001-02-03T00:00:00Z") }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Employee, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  Employee.Free;
  Rehydrated.Free;
end;

procedure TestBsonSerializer.TestSerializeOrder;
var
  Order, Rehydrated: TOrder;
  Json: String;
  Bson, Actual: TBytes;
begin
  Order := TOrder.Create;
  Order.Customer := 'John';
  SetLength(Order.OrderDetails, 2);
  Order.OrderDetails[0] := TOrderDetail.Create;
  Order.OrderDetails[1] := TOrderDetail.Create;

  Order.OrderDetails[0].Product := 'Pen';
  Order.OrderDetails[0].Quantity := 1;
  Order.OrderDetails[1].Product := 'Ruler';
  Order.OrderDetails[1].Quantity := 2;

  Rehydrated := nil;

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Order, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "Customer" : "John", "OrderDetails" : ' +
    '[{ "Product" : "Pen", "Quantity" : 1 }, { "Product" : "Ruler", "Quantity" : 2 }] }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Order, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  Order.Free;
  Rehydrated.Free;
end;

{ TestBsonSerializer.TEmployee }

function TestBsonSerializer.TEmployee.GetAge: Integer;
begin
  Result := YearsBetween(Now, FDateOfBirth)
end;

{ TestBsonSerializer.TOrder }

destructor TestBsonSerializer.TOrder.Destroy;
var
  I: Integer;
begin
  for I := 0 to Length(OrderDetails) - 1 do
    OrderDetails[I].Free;
  inherited;
end;

{ TestBsonPolymorphicClasses }

procedure TestBsonPolymorphicClasses.TestSerializeTCasTA;
var
  A, Rehydrated: TA;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  TgoBsonSerializer.RegisterSubClass(TC);

  A := TC.Create;
  A.FA := 'a';
  (A as TC).FC := 'c';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(A, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "_t" : "ClassC", "FA" : "a", "FC" : "c" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(A, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TC);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  A.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTCasTC;
var
  C, Rehydrated: TC;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  C := TC.Create;
  C.FA := 'a';
  C.FC := 'c';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(C, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "FA" : "a", "FC" : "c" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(C, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TC);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  C.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTDasTA;
var
  A, Rehydrated: TA;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  TgoBsonSerializer.RegisterSubClass(TD);

  A := TD.Create;
  A.FA := 'a';
  (A as TD).FB := 'b';
  (A as TD).FD := 'd';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(A, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "_t" : "TestBsonPolymorphicClasses.TD", "FA" : "a", "FB" : "b", "FD" : "d" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(A, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TD);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  A.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTDasTB;
var
  B, Rehydrated: TB;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  TgoBsonSerializer.RegisterSubClass(TD);

  B := TD.Create;
  B.FA := 'a';
  (B as TD).FB := 'b';
  (B as TD).FD := 'd';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(B, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "_t" : "TestBsonPolymorphicClasses.TD", "FA" : "a", "FB" : "b", "FD" : "d" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(B, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TD);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  B.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTDasTD;
var
  D, Rehydrated: TD;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  D := TD.Create;
  D.FA := 'a';
  D.FB := 'b';
  D.FD := 'd';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(D, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "_t" : "TestBsonPolymorphicClasses.TD", "FA" : "a", "FB" : "b", "FD" : "d" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(D, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TD);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  D.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTEasTA;
var
  A, Rehydrated: TA;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  TgoBsonSerializer.RegisterSubClass(TE);

  A := TE.Create;
  A.FA := 'a';
  (A as TE).FB := 'b';
  (A as TE).FE := 'e';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(A, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "_t" : "TestBsonPolymorphicClasses.TE", "FA" : "a", "FB" : "b", "FE" : "e" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(A, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TE);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  A.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTEasTB;
var
  B, Rehydrated: TB;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  TgoBsonSerializer.RegisterSubClass(TD);

  B := TE.Create;
  B.FA := 'a';
  (B as TE).FB := 'b';
  (B as TE).FE := 'e';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(B, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "_t" : "TestBsonPolymorphicClasses.TE", "FA" : "a", "FB" : "b", "FE" : "e" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(B, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TE);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  B.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTEasTE;
var
  E, Rehydrated: TE;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  E := TE.Create;
  E.FA := 'a';
  E.FB := 'b';
  E.FE := 'e';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(E, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "_t" : "TestBsonPolymorphicClasses.TE", "FA" : "a", "FB" : "b", "FE" : "e" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(E, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TE);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  E.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTTwithNil;
var
  T, Rehydrated: TT;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  T := TT.Create;
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(T, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "FT" : null }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(T, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TT);
  Assert.IsNull(Rehydrated.FT);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  T.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTTwithTC;
var
  T, Rehydrated: TT;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  T := TT.Create;
  T.FT := TC.Create;
  T.FT.FA := 'a';
  TC(T.FT).FC := 'c';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(T, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "FT" : { "_t" : "ClassC", "FA" : "a", "FC" : "c" } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(T, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TT);
  Assert.IsNotNull(Rehydrated.FT);
  Assert.IsTrue(Rehydrated.FT.ClassType = TC);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  T.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTTwithTD;
var
  T, Rehydrated: TT;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  T := TT.Create;
  T.FT := TD.Create;
  T.FT.FA := 'a';
  TD(T.FT).FB := 'b';
  TD(T.FT).FD := 'd';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(T, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "FT" : { "_t" : "TestBsonPolymorphicClasses.TD", "FA" : "a", "FB" : "b", "FD" : "d" } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(T, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TT);
  Assert.IsNotNull(Rehydrated.FT);
  Assert.IsTrue(Rehydrated.FT.ClassType = TD);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  T.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestSerializeTTwithTE;
var
  T, Rehydrated: TT;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  T := TT.Create;
  T.FT := TE.Create;
  T.FT.FA := 'a';
  TE(T.FT).FB := 'b';
  TE(T.FT).FE := 'e';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(T, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "FT" : { "_t" : "TestBsonPolymorphicClasses.TE", "FA" : "a", "FB" : "b", "FE" : "e" } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(T, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(Rehydrated.ClassType = TT);
  Assert.IsNotNull(Rehydrated.FT);
  Assert.IsTrue(Rehydrated.FT.ClassType = TE);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  T.Free;
  Rehydrated.Free;
end;

procedure TestBsonPolymorphicClasses.TestUnknownDiscriminator;
const
  JSON = '{ "_t" : "ClassD", "FA" : "a", "FB" : "b", "FD" : "d" }';
begin
  Assert.WillRaise(
    procedure
    var
      D: TD;
    begin
      TgoBsonSerializer.Deserialize(JSON, D);
    end, EgoBsonSerializerError);
end;

{ TestBsonPolymorphicClasses.TT }

destructor TestBsonPolymorphicClasses.TT.Destroy;
begin
  FT.Free;
  inherited;
end;

{ TestBsonCircularClass }

procedure TestBsonCircularClass.TestCircularClass;
var
  Foo, Rehydrated: TFoo;
  Json: String;
  Bson, Actual: TBytes;
begin
  Foo := TFoo.Create;
  Foo.Value := 1;
  Foo.Child := TFoo.Create;
  Foo.Child.Value := 2;

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Foo, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "Value" : 1, "Child" : { "Value" : 2, "Child" : null } }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Foo, Bson));

  Rehydrated := nil;
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsNotNull(Rehydrated);
  Assert.AreEqual(1, Rehydrated.Value);
  Assert.IsNotNull(Rehydrated.Child);
  Assert.AreEqual(2, Rehydrated.Child.Value);
  Assert.IsNull(Rehydrated.Child.Child);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  Foo.Free;
  Rehydrated.Free;
end;

{ TestBsonCircularClass.TFoo }

destructor TestBsonCircularClass.TFoo.Destroy;
begin
  Child.Free;
  inherited;
end;

{ TestBsonAttributes }

procedure TestBsonAttributes.TestElementName;
var
  Obj, Rehydrated: TTestClassElementName;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  Obj := TTestClassElementName.Create;
  Obj.PropNormalElementName := 'PNEN';
  Obj.PropAltElementName := 'PAEN';
  Obj.FieldNormalElementName := 'FNEN';
  Obj.FieldAltElementName := 'FAEN';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "FieldNormalElementName" : "FNEN", "#alt" : "FAEN", "PropNormalElementName" : "PNEN", "$alt" : "PAEN" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  Obj.Free;
  Rehydrated.Free;
end;

procedure TestBsonAttributes.TestErrorOnExtraElements;
var
  Obj, Rehydrated: TTestClassErrorOnExtraElements;
  Json: String;
begin
  Rehydrated := nil;

  Obj := TTestClassErrorOnExtraElements.Create;
  Obj.I := 42;
  Obj.S := 'Foo';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "I" : 42, "S" : "Foo" }', Json);

  Json := '{ "I" : 42, "S" : "Foo", "Extra" : true }';
  try
    Assert.WillRaise(
      procedure
      begin
        TgoBsonSerializer.Deserialize(Json, Rehydrated); // Should raise an exception
      end, EgoBsonSerializerError);
  finally
    Obj.Free;
  end;
end;

procedure TestBsonAttributes.TestIgnore;
var
  Obj, Rehydrated: TTestClassIgnore;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  Obj := TTestClassIgnore.Create;
  Obj.PropNormal := 'PN';
  Obj.PropIgnore := 'PI';
  Obj.FieldNormal := 'FN';
  Obj.FieldIgnore := 'FI';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "FieldNormal" : "FN", "PropNormal" : "PN" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  Obj.Free;
  Rehydrated.Free;
end;

procedure TestBsonAttributes.TestIgnoreExtraElements;
var
  Obj, Rehydrated: TTestClassIgnoreExtraElements;
  Json: String;
begin
  Rehydrated := nil;

  Obj := TTestClassIgnoreExtraElements.Create;
  Obj.I := 42;
  Obj.S := 'Foo';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "_t" : "TCIEE", "I" : 42, "S" : "Foo" }', Json);

  Json := '{ "_t" : "TCIEE", "I" : 42, "S" : "Foo", "Extra" : true }';
  TgoBsonSerializer.Deserialize(Json, Rehydrated); // Should not raise an exception

  Assert.IsTrue(Rehydrated.ClassType = TTestClassIgnoreExtraElements);
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "_t" : "TCIEE", "I" : 42, "S" : "Foo" }', Json);

  Obj.Free;
  Rehydrated.Free;
end;

procedure TestBsonAttributes.TestIgnoreIfDefault;
var
  Obj, Rehydrated: TTestClassIgnoreIfDefault;
  Json: String;
  Bson, Actual: TBytes;
begin
  Rehydrated := nil;

  Obj := TTestClassIgnoreIfDefault.Create;

  Obj.FieldIgnoreDefaultBoolean1 := False;
  Obj.FieldIgnoreDefaultBoolean2 := True;
  Obj.FieldIgnoreCustomDefaultBoolean1 := False;
  Obj.FieldIgnoreCustomDefaultBoolean2 := True;

  Obj.FieldIgnoreDefaultInt32_1 := 0;
  Obj.FieldIgnoreDefaultInt32_2 := 42;
  Obj.FieldIgnoreCustomDefaultInt32_1 := 0;
  Obj.FieldIgnoreCustomDefaultInt32_2 := 42;

  Obj.FieldIgnoreDefaultInt64_1 := 0;
  Obj.FieldIgnoreDefaultInt64_2 := -42;
  Obj.FieldIgnoreCustomDefaultInt64_1 := 0;
  Obj.FieldIgnoreCustomDefaultInt64_2 := -42;

  Obj.FieldIgnoreDefaultString1 := '';
  Obj.FieldIgnoreDefaultString2 := 'Foo';
  Obj.FieldIgnoreCustomDefaultString1 := '';
  Obj.FieldIgnoreCustomDefaultString2 := 'Foo';

  Obj.FieldIgnoreDouble1 := 0;
  Obj.FieldIgnoreDouble2 := 1.5;
  Obj.FieldIgnoreDateTime1 := 0;
  Obj.FieldIgnoreDateTime2 := EncodeDate(2016, 5, 12);

  Obj.FieldIgnoreEnum1 := TColor.Red;
  Obj.FieldIgnoreEnum2 := TColor.Green;
  Obj.FieldIgnoreSet1 := [];
  Obj.FieldIgnoreSet2 := [TColor.Green, TColor.Blue];

  Obj.FieldIgnoreBytes1 := nil;
  Obj.FieldIgnoreBytes2 := TBytes.Create(1, 2, 3);
  Obj.FieldIgnoreArray1 := nil;
  Obj.FieldIgnoreArray2 := TArray<String>.Create('Foo', 'Bar');

  Obj.FieldIgnoreGuid1 := TGUID.Empty;
  Obj.FieldIgnoreGuid2 := TGUID.Create('{E898E713-23FB-4B92-A46F-0D5B7E3DEB62}');
  Obj.FieldIgnoreObjectId1 := TgoObjectId.Empty;
  Obj.FieldIgnoreObjectId2 := TgoObjectId.Create('5734c5688a057d1924e552cf');

  Obj.FieldIgnoreObject1 := nil;
  Obj.FieldIgnoreObject2 := TFoo.Create(42);

  Obj.PropIgnoreDefaultBoolean1 := False;
  Obj.PropIgnoreDefaultBoolean2 := True;
  Obj.PropIgnoreCustomDefaultBoolean1 := False;
  Obj.PropIgnoreCustomDefaultBoolean2 := True;

  Obj.PropIgnoreDefaultInt32_1 := 0;
  Obj.PropIgnoreDefaultInt32_2 := 42;
  Obj.PropIgnoreCustomDefaultInt32_1 := 0;
  Obj.PropIgnoreCustomDefaultInt32_2 := 42;

  Obj.PropIgnoreDefaultInt64_1 := 0;
  Obj.PropIgnoreDefaultInt64_2 := -42;
  Obj.PropIgnoreCustomDefaultInt64_1 := 0;
  Obj.PropIgnoreCustomDefaultInt64_2 := -42;

  Obj.PropIgnoreDefaultString1 := '';
  Obj.PropIgnoreDefaultString2 := 'Foo';
  Obj.PropIgnoreCustomDefaultString1 := '';
  Obj.PropIgnoreCustomDefaultString2 := 'Foo';

  Obj.PropIgnoreDouble1 := 0;
  Obj.PropIgnoreDouble2 := 1.5;
  Obj.PropIgnoreDateTime1 := 0;
  Obj.PropIgnoreDateTime2 := EncodeDate(2016, 5, 12);

  Obj.PropIgnoreEnum1 := TColor.Red;
  Obj.PropIgnoreEnum2 := TColor.Green;
  Obj.PropIgnoreSet1 := [];
  Obj.PropIgnoreSet2 := [TColor.Green, TColor.Blue];

  Obj.PropIgnoreBytes1 := nil;
  Obj.PropIgnoreBytes2 := TBytes.Create(1, 2, 3);
  Obj.PropIgnoreArray1 := nil;
  Obj.PropIgnoreArray2 := TArray<String>.Create('Foo', 'Bar');

  Obj.PropIgnoreObject1 := nil;
  Obj.PropIgnoreObject2 := TFoo.Create(42);

  Obj.PropIgnoreGuid1 := TGUID.Empty;
  Obj.PropIgnoreGuid2 := TGUID.Create('{E898E713-23FB-4B92-A46F-0D5B7E3DEB62}');
  Obj.PropIgnoreObjectId1 := TgoObjectId.Empty;
  Obj.PropIgnoreObjectId2 := TgoObjectId.Create('5734c5688a057d1924e552cf');

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ ' +
    '"FieldIgnoreDefaultBoolean2" : true, ' +
    '"FieldIgnoreCustomDefaultBoolean1" : false, ' +
    '"FieldIgnoreDefaultInt32_2" : 42, ' +
    '"FieldIgnoreCustomDefaultInt32_1" : 0, ' +
    '"FieldIgnoreDefaultInt64_2" : NumberLong(-42), ' +
    '"FieldIgnoreCustomDefaultInt64_1" : NumberLong(0), ' +
    '"FieldIgnoreDefaultString2" : "Foo", ' +
    '"FieldIgnoreCustomDefaultString1" : "", ' +
    '"FieldIgnoreDouble2" : 1.5, ' +
    '"FieldIgnoreDateTime2" : ISODate("2016-05-12T00:00:00Z"), ' +
    '"FieldIgnoreEnum2" : 1, ' +
    '"FieldIgnoreSet2" : 6, ' +
    '"FieldIgnoreBytes2" : new BinData(0, "AQID"), ' +
    '"FieldIgnoreArray2" : ["Foo", "Bar"], ' +
    '"FieldIgnoreObject2" : { "Id" : 42 }, ' +
    '"FieldIgnoreGuid2" : UUID("e898e713-23fb-4b92-a46f-0d5b7e3deb62"), ' +
    '"FieldIgnoreObjectId2" : ObjectId("5734c5688a057d1924e552cf"), ' +
    '"PropIgnoreDefaultBoolean2" : true, ' +
    '"PropIgnoreCustomDefaultBoolean1" : false, ' +
    '"PropIgnoreDefaultInt32_2" : 42, ' +
    '"PropIgnoreCustomDefaultInt32_1" : 0, ' +
    '"PropIgnoreDefaultInt64_2" : NumberLong(-42), ' +
    '"PropIgnoreCustomDefaultInt64_1" : NumberLong(0), ' +
    '"PropIgnoreDefaultString2" : "Foo", ' +
    '"PropIgnoreCustomDefaultString1" : "", ' +
    '"PropIgnoreDouble2" : 1.5, ' +
    '"PropIgnoreDateTime2" : ISODate("2016-05-12T00:00:00Z"), ' +
    '"PropIgnoreEnum2" : 1, ' +
    '"PropIgnoreSet2" : 6, ' +
    '"PropIgnoreBytes2" : new BinData(0, "AQID"), ' +
    '"PropIgnoreArray2" : ["Foo", "Bar"], ' +
    '"PropIgnoreObject2" : { "Id" : 42 }, ' +
    '"PropIgnoreGuid2" : UUID("e898e713-23fb-4b92-a46f-0d5b7e3deb62"), ' +
    '"PropIgnoreObjectId2" : ObjectId("5734c5688a057d1924e552cf") }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);

  Obj.Free;
  Rehydrated.Free;
end;

procedure TestBsonAttributes.TestReadOnly;
var
  Obj, Rehydrated: TTestClassReadOnly;
  Json, Actual: String;
  Bson: TBytes;
begin
  Rehydrated := nil;

  Obj := TTestClassReadOnly.Create;
  Obj.FPropReadOnlyInclude := 'ROI';
  Obj.FPropReadOnlyExclude := 'ROE';
  Obj.FPropReadOnlyIncludeAltName := 'ROIAN';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "PropReadOnlyInclude" : "ROI", "AltName" : "ROIAN" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Obj, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual('{ "PropReadOnlyInclude" : "", "AltName" : "" }', Actual);

  Obj.Free;
  Rehydrated.Free;
end;

{ TestBsonAttributes.TFoo }

constructor TestBsonAttributes.TFoo.Create(const AId: Integer);
begin
  inherited Create;
  Id := AId;
end;

{ TestBsonAttributes.TTestClassIgnoreIfDefault }

constructor TestBsonAttributes.TTestClassIgnoreIfDefault.Create;
begin
  inherited Create;
  { Set default values }
  FieldIgnoreCustomDefaultBoolean1 := True;
  FieldIgnoreCustomDefaultBoolean2 := True;
  FieldIgnoreCustomDefaultInt32_1 := 42;
  FieldIgnoreCustomDefaultInt32_2 := 42;
  FieldIgnoreCustomDefaultInt64_1 := -42;
  FieldIgnoreCustomDefaultInt64_2 := -42;
  FieldIgnoreCustomDefaultString1 := 'Foo';
  FieldIgnoreCustomDefaultString2 := 'Foo';

  FPropIgnoreCustomDefaultBoolean1 := True;
  FPropIgnoreCustomDefaultBoolean2 := True;
  FPropIgnoreCustomDefaultInt32_1 := 42;
  FPropIgnoreCustomDefaultInt32_2 := 42;
  FPropIgnoreCustomDefaultInt64_1 := -42;
  FPropIgnoreCustomDefaultInt64_2 := -42;
  FPropIgnoreCustomDefaultString1 := 'Foo';
  FPropIgnoreCustomDefaultString2 := 'Foo';
end;

destructor TestBsonAttributes.TTestClassIgnoreIfDefault.Destroy;
begin
  FieldIgnoreObject1.Free;
  FieldIgnoreObject2.Free;
  FPropIgnoreObject1.Free;
  FPropIgnoreObject2.Free;
  inherited;
end;

{ TestCustomSerialization }

procedure TestCustomSerialization.TestCustomRecordSerializer;
var
  R, Rehydrated: TTestRecord;
  Json: String;
  Bson, Actual: TBytes;
begin
  TgoBsonSerializer.RegisterCustomSerializer<TCompoundId>(TCompoundIdSerializer);

  R.Id.Part1 := 'abc';
  R.Id.Part2 := 'def';
  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, TgoJsonWriterSettings.Shell, Json));
  Assert.AreEqual('{ "Id" : "abc:def" }', Json);

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(R, Bson));
  Assert.IsTrue(TgoBsonSerializer.TryDeserialize(Bson, Rehydrated));

  Assert.IsTrue(TgoBsonSerializer.TrySerialize(Rehydrated, Actual));
  Assert.AreEqual(Bson, Actual);
end;

{ TestCustomSerialization.TCompoundId }

function TestCustomSerialization.TCompoundId.GetComplete: String;
begin
  Result := FPart1 + ':' + FPart2;
end;

procedure TestCustomSerialization.TCompoundId.SetComplete(const Value: String);
var
  I: Integer;
begin
  I := Value.IndexOf(':');
  if (I < 0) then
  begin
    FPart1 := Value;
    FPart2 := '';
  end
  else
  begin
    FPart1 := Value.Substring(0, I);
    FPart2 := Value.Substring(I + 1)
  end;
end;

{ TestCustomSerialization.TCompoundIdSerializer }

procedure TestCustomSerialization.TCompoundIdSerializer.Deserialize(
  const AReader: IgoBsonBaseReader; out AValue);
var
  Value: TestCustomSerialization.TCompoundId absolute AValue;
begin
  Value.Complete := AReader.ReadString;
end;

procedure TestCustomSerialization.TCompoundIdSerializer.Serialize(const AValue;
  const AWriter: IgoBsonBaseWriter);
var
  Value: TestCustomSerialization.TCompoundId absolute AValue;
begin
  AWriter.WriteString(Value.Complete);
end;

initialization
  TDUnitX.RegisterTestFixture(TestBsonSerializeBoolean);
  TDUnitX.RegisterTestFixture(TestBsonSerializeInt8);
  TDUnitX.RegisterTestFixture(TestBsonSerializeInt16);
  TDUnitX.RegisterTestFixture(TestBsonSerializeInt32);
  TDUnitX.RegisterTestFixture(TestBsonSerializeInt64);
  TDUnitX.RegisterTestFixture(TestBsonSerializeUInt8);
  TDUnitX.RegisterTestFixture(TestBsonSerializeUInt16);
  TDUnitX.RegisterTestFixture(TestBsonSerializeUInt32);
  TDUnitX.RegisterTestFixture(TestBsonSerializeUInt64);
  TDUnitX.RegisterTestFixture(TestBsonSerializeSingle);
  TDUnitX.RegisterTestFixture(TestBsonSerializeDouble);
  TDUnitX.RegisterTestFixture(TestBsonSerializeChar);
  TDUnitX.RegisterTestFixture(TestBsonSerializeString);
  TDUnitX.RegisterTestFixture(TestBsonSerializeDateTime);
  TDUnitX.RegisterTestFixture(TestBsonSerializeGuid);
  TDUnitX.RegisterTestFixture(TestBsonSerializeObjectId);
  TDUnitX.RegisterTestFixture(TestBsonSerializeTBytes);
  TDUnitX.RegisterTestFixture(TestBsonSerializeEnum);
  TDUnitX.RegisterTestFixture(TestBsonSerializeSet);
  TDUnitX.RegisterTestFixture(TestBsonRecord);
  {$IF (RTLVersion >= 34)}
  TDUnitX.RegisterTestFixture(TestBsonCustomManagedRecord);
  {$ENDIF}
  TDUnitX.RegisterTestFixture(TestBsonObject);
  TDUnitX.RegisterTestFixture(TestBsonArrayOfInteger);
  TDUnitX.RegisterTestFixture(TestBsonArrayOfString);
  TDUnitX.RegisterTestFixture(TestBsonArrayOfEnum);
  TDUnitX.RegisterTestFixture(TestBsonArrayOfRecord);
  TDUnitX.RegisterTestFixture(TestBsonArrayOfObject);
  TDUnitX.RegisterTestFixture(TestBsonStandAloneArray);
  TDUnitX.RegisterTestFixture(TestBsonSerializePrimitiveTypesInRecord);
  TDUnitX.RegisterTestFixture(TestBsonSerializePrimitiveTypesInClass);
  TDUnitX.RegisterTestFixture(TestBsonSerializer);
  TDUnitX.RegisterTestFixture(TestBsonPolymorphicClasses);
  TDUnitX.RegisterTestFixture(TestBsonCircularClass);
  TDUnitX.RegisterTestFixture(TestBsonAttributes);
  TDUnitX.RegisterTestFixture(TestCustomSerialization);

end.
