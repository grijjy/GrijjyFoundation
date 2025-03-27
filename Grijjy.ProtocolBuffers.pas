unit Grijjy.ProtocolBuffers;
(*<Google Protocol Buffers for Delphi.

  This unit contains declarations for serializing attributed Delphi records
  in Protocol Buffer format.

  It does @bold(not) use the Google Protocol Buffers framework. Instead, it uses
  a custom framework, but serializes in a Protocol Buffers compatible bitstream.

  @bold(About Protocol Buffers)

  Protocol Buffers is both a framework and a bitstream specification:

  https://developers.google.com/protocol-buffers/

  It is used to serialize messages in an efficient binary format. A message is
  a collection of fields, where each field is uniquely identified with an
  integer Tag. Fields can be of various simple data types, including integers,
  enums, strings, booleans and strings, as well as compound data types such as
  nested messages, repeated messages (arrays) and binary data.

  @bold(Delphi Implementation)

  This Delphi implementation uses attributed records to define messages. These
  are regular Delphi records, but fields that are decorated with the [Serialize]
  attribute can be serialized. For example:

  <source>
  type
    TPhoneType = (Mobile, Home, Work);

  type
    TPhoneNumber = record
    public
      [Serialize(1)] Number: String;
      [Serialize(2)] PhoneType: TPhoneType;
    public
      procedure Initialize;
    end;

  type
    TPerson = record
    public
      [Serialize(1)] Name: String;
      [Serialize(2)] Id: Integer;
      [Serialize(3)] Email: String;
      [Serialize(4)] MainPhone: TPhoneNumber;
      [Serialize(5)] OtherPhones: TArray<TPhoneNumber>;
    public
      procedure Initialize;
    end;
  </source>

  Each serializable field must be decorated with a [Serialize] attribute with a
  single parameter containing the Tag for that field. Tags @bold(must) be unique
  within the record, but you can use the same tag in different records or in
  nested records. When a record contains duplicate tags, an exception will be
  raised when the record is (de)serialized.

  Tags start at 1 and must be positive. You should reserve tags 1-15 for the
  most common fields, since these tags are stored most efficiently (using 1
  byte). Tags 16-2047 are stored in 2 bytes, and other tags take more bytes.

  Records are serialized in an extensible way. You can add, delete and reorder
  fields without breaking compatibility with older bitstreams. However, you
  should never change the tag or data type of a field.

  @bold(Supported Data Types)

  You can use a wide variety of Delphi data types for your serializable fields:

  * UInt8 (Byte), UInt16 (Word), UInt32 (Longword/Cardinal), UInt64
  * Int8 (Shortint), Int16 (Smallint), Int32 (Longint/Integer), Int64
  * Single, Double
  * Boolean
  * Enumerated types, @bold(as long as) the type does @bold(not) contain any
    explicitly assigned values (Delphi does not provide RTTI for these)
  * Records (that is, your field can be of another record type)
  * Strings (of type UnicodeString)
  * TBytes (for raw binary data)
  * 1-dimensional dynamic arrays (TArray<>) of the types described above,

  Tech note: all arrays of primitive numeric types (integers, floats and enums)
  are stored in "packed" format, which is supported since Protocol Buffers
  version 2.1.0. This is a more efficient format that doesn't repeat the tag for
  each element. All other array types are stored unpacked (where the tag is
  repeated for each element).

  The integer data types are stored in an efficient VarInt format. This means
  that smaller values are stored in less bytes than larger values. 32-bit
  integer types are stored in 1-5 bytes, and 64-bit integer types are stored in
  1-10 bytes. Sometimes, you can have integer data that contains random values
  across the entire 32-bit or 64-bit range. In those cases, it is more efficient
  to store these integers as fixed 32-bit or 64-bit values. You can do this
  by declaring the field as one of 4 fixed integer types:

  * FixedInt32, FixedUInt32, FixedInt64, FixedUInt64

  All other data types can @bold(not) be used for serializable fields. An
  exception will be raised when an unsupported data type is encountered.
  However, you can still use these types for regular (non-serializable) fields.
  In particular, the following types are @bold(not) supported:

  * Extended, Comp, Currency
  * Class, Object, Interface
  * Enumerated types with explicitly assigned values
  * AnsiString, RawByteString, UCS4String etc.
  * Static arrays
  * Multi-dimensional dynamic arrays

  @bold(Using the (de)serializer)

  Serializing is very easy. You just fill your record with the values you want
  to serialize and call:

  <source>
  TgoProtocolBuffer.Serialize<TPerson>(MyPerson, 'Person.dat');
  </source>

  This is a generic method with a type parameter that must match the type of
  record you are serializing.

  Since Delphi is able to infer the generic type from the first parameter, you
  can also write this a little bit shorter:

  <source>
  TgoProtocolBuffer.Serialize(MyPerson, 'Person.dat');
  </source>

  You can serialize to a file, stream or TBytes array.

  Deserializing is equally simple:

  <source>
  TgoProtocolBuffer.Deserialize(MyPerson, 'Person.dat');
  </source>

  Because all fields in a record are optional, some fields may not be in the
  stream. To prevent the record from having unitialized fields after
  deserialization, the record is cleared before it is deserialized (that is, all
  fields are set to 0 or nil).

  You can also provide your own means of initializing the record with default
  values. To do that, you have to add a parameterless Initialize procedure to
  your record. Then, the deserialization process will call that routine after
  clearing the record (so it will still clear any fields you don't initialize
  yourself). *)

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.Classes,
  System.SysUtils,
  System.TypInfo,
  System.SyncObjs,
  System.Rtti,
  System.Generics.Collections,
  Grijjy.SysUtils;

type
  { A 32-bit unsigned integer that is always serialized using 4 bytes. }
  FixedUInt32 = type UInt32;
  { A 32-bit signed integer that is always serialized using 4 bytes. }
  FixedInt32  = type Int32;
  { A 64-bit unsigned integer that is always serialized using 8 bytes. }
  FixedUInt64 = type UInt64;
  { A 64-bit signed integer that is always serialized using 8 bytes. }
  FixedInt64  = type Int64;

type
  { Valid range of field tags }
  TgoSerializationTag = 1..536870911;

type
  { Exception type that is raise when an error occurs during (de)serialization }
  EgoSerializationError = class(Exception)

  end;

type
  { A Delphi attribute you use to decorate record fields that need to be
    serialized. }
  SerializeAttribute = class(TCustomAttribute)
  {$REGION 'Internal Declarations'}
  private
    FTag: TgoSerializationTag;
  {$ENDREGION 'Internal Declarations'}
  public
    { Attribute constructor }
    constructor Create(const ATag: TgoSerializationTag);

    { The tag that is associated with the field to which this attribute is
      attached. }
    property Tag: TgoSerializationTag read FTag;
  end;

type
  { Static class used for (de)serializing records in Protocol Buffer format }
  TgoProtocolBuffer = class
  {$REGION 'Internal Declarations'}
  private
    type
      TWriter = class(TgoByteBuffer)
      public
        procedure WriteVarUInt(const AValue: Cardinal);
        procedure WriteVarInt(const AValue: Integer); inline;
        procedure WriteVarUInt64(const AValue: UInt64);
        procedure WriteVarInt64(const AValue: Int64); inline;
      end;

    type
      TReader = class
      private
        FBuffer: PByte;
        FSize: Integer;
        FIndex: Integer;
      public
        constructor Create(const ABuffer: Pointer; const ASize: Integer);
        function HasData: Boolean; inline;
        procedure Skip(const ASize: Integer); inline;
        procedure ReadBytes(out AData; const ASize: Integer);
        function ReadByte: Byte; inline;
        function ReadVarUInt: Cardinal;
        function ReadVarInt: Integer;
        function ReadVarUInt64: UInt64;
        function ReadVarInt64: Int64;
        function PeekVarUInt(out ASize: Integer): Cardinal;

        property Index: Integer read FIndex;
      end;

    type
      TInitializeProc = procedure(Self: Pointer);
      TSerializeProc = procedure(const AWriter: TWriter; const ARecord: PByte;
        const ATag, AOffset: Integer; const AParam: TObject);
      TDeserializeProc = procedure(const AReader: TReader; const ARecord: PByte;
        const ATag, AOffset: Integer; const AParam: TObject);

    type
      TFieldTypeInfo = class
      strict private
        FTag: Integer;
        FOffset: Integer;
        FSerializeProc: TSerializeProc;
        FDeserializeProc: TDeserializeProc;
        FParam: TObject;
      public
        constructor Create(const ATag, AOffset: Integer;
          const ASerializeProc: TSerializeProc;
          const ADeserializeProc: TDeserializeProc; const AParam: TObject);

        property Tag: Integer read FTag;
        property Offset: Integer read FOffset;
        property SerializeProc: TSerializeProc read FSerializeProc;
        property DeserializeProc: TDeserializeProc read FDeserializeProc;
        property Param: TObject read FParam;
      end;

    type
      TBaseTypeInfo = class
      strict private
        FSize: Integer;
        FTypeInfo: PTypeInfo;
      public
        constructor Create(const ATypeInfo: PTypeInfo; const ASize: Integer);

        property Size: Integer read FSize;
        property TypeInfo: PTypeInfo read FTypeInfo;
      end;

    type
      TRecordTypeInfo = class(TBaseTypeInfo)
      strict private
        FFields: TArray<TFieldTypeInfo>;
        FInitProc: TInitializeProc;
      public
        constructor Create(const ATypeInfo: PTypeInfo; const ASize: Integer;
          const AInitProc: TInitializeProc; const AFields: TArray<TFieldTypeInfo>);
        destructor Destroy; override;
        procedure Serialize(const AWriter: TWriter; const ARecord: Pointer);
        procedure Deserialize(const AReader: TReader; const ARecord: Pointer);

        property InitProc: TInitializeProc read FInitProc;
      end;

    type
      TArrayTypeInfo = class(TBaseTypeInfo)
      strict private
        FElementType: PTypeInfo;
        FElementSize: Integer;
        FElementInfo: TBaseTypeInfo;
        FElementSerializeProc: TSerializeProc;
        FElementDeserializeProc: TDeserializeProc;
        FElementParam: TObject;
      public
        constructor Create(const ATypeInfo: PTypeInfo; const ASize: Integer;
          const AElementType: PTypeInfo; const AElementSize: Integer;
          const AElementInfo: TBaseTypeInfo;
          const AElementSerializeProc: TSerializeProc;
          const AElementDeserializeProc: TDeserializeProc;
          const AElementParam: TObject);

        property ElementType: PTypeInfo read FElementType;
        property ElementSize: Integer read FElementSize;
        property ElementInfo: TBaseTypeInfo read FElementInfo;
        property ElementSerializeProc: TSerializeProc read FElementSerializeProc;
        property ElementDeserializeProc: TDeserializeProc read FElementDeserializeProc;
        property ElementParam: TObject read FElementParam;
      end;
  private
    class var FTypeInfoMap: TObjectDictionary<Pointer, TBaseTypeInfo>;
    class var FTypeInfoMapLock: TCriticalSection;
  private
    class function RegisterRecordTypeInfo(const ATypeInfo: Pointer): TRecordTypeInfo; static;
    class function RegisterArrayTypeInfo(const ATypeInfo: PTypeInfo): TArrayTypeInfo; static;
    class function GetSerializationProcs(const AType: TRttiType;
      out ASerializeProc: TSerializeProc; out ADeserializeProc: TDeserializeProc;
      out AParam: TObject): Boolean; static;
  private
    class procedure SerializeUInt8(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeUInt16(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeUInt32(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeUInt64(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeInt8(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeInt16(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeInt32(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeInt64(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeFixed32(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeFixed64(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeUString(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeRecord(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeBytes(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeDynArrayPacked(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure SerializeDynArrayUnpacked(const AWriter: TWriter;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
  private
    class procedure DeserializeUInt8(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeUInt16(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeUInt32(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeUInt64(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeInt8(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeInt16(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeInt32(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeInt64(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeFixed32(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeFixed64(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeUString(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeBytes(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeRecord(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeDynArrayPacked(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
    class procedure DeserializeDynArrayUnpacked(const AReader: TReader;
      const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject); static;
  public
    { @exclude }
    class constructor Create;
    { @exclude }
    class destructor Destroy;
  {$ENDREGION 'Internal Declarations'}
  public
    { Serializes a record to an array of bytes.

      Parameters:
        T: the type of the record to serialize.
        ARecord: the record (of type T) to serialize.

      Returns:
        A byte array containing the serialized record. }
    class function Serialize<T{$IF (RTLVersion < 36)}: record{$ENDIF}>(const ARecord: T): TBytes; overload; static; inline;

    { Serializes a record to an array of bytes.

      Parameters:
        ARecordType: the type of the record to serialize. This is the result
          from a TypeInfo(TMyRecord) call.
        ARecord: the record (of ARecordType) to serialize.

      Returns:
        A byte array containing the serialized record. }
    class function Serialize(const ARecordType: Pointer;
      const ARecord): TBytes; overload; static;

    { Serializes a record to a file.

      Parameters:
        T: the type of the record to serialize.
        ARecord: the record (of type T) to serialize.
        AFilename: the name of the file to serialize the record to. }
    class procedure Serialize<T{$IF (RTLVersion < 36)}: record{$ENDIF}>(const ARecord: T;
      const AFilename: String); overload; static; inline;

    { Serializes a record to a file.

      Parameters:
        ARecordType: the type of the record to serialize. This is the result
          from a TypeInfo(TMyRecord) call.
        ARecord: the record (of ARecordType) to serialize.
        AFilename: the name of the file to serialize the record to. }
    class procedure Serialize(const ARecordType: Pointer; const ARecord;
      const AFilename: String); overload; static;

    { Serializes a record to a stream.

      Parameters:
        T: the type of the record to serialize.
        ARecord: the record (of type T) to serialize.
        AStream: the stream to serialize the record to. }
    class procedure Serialize<T{$IF (RTLVersion < 36)}: record{$ENDIF}>(const ARecord: T;
      const AStream: TStream); overload; static; inline;

    { Serializes a record to a stream.

      Parameters:
        ARecordType: the type of the record to serialize. This is the result
          from a TypeInfo(TMyRecord) call.
        ARecord: the record (of ARecordType) to serialize.
        AStream: the stream to serialize the record to. }
    class procedure Serialize(const ARecordType: Pointer; const ARecord;
      const AStream: TStream); overload; static;

    { Deserializes a record from an array of bytes.
      When the record contains a parameterless @code(Initialize) procedure, then
      that procedure will be called before the record is deserialized.

      Parameters:
        T: the type of the record to deserialize.
        ARecord: the record (of type T) to deserialize.
        AData: the byte array containing the serialized record. }
    class procedure Deserialize<T{$IF (RTLVersion < 36)}: record{$ENDIF}>(out ARecord: T;
      const AData: TBytes); overload; static; inline;

    { Deserializes a record from an array of bytes.
      When the record contains a parameterless @code(Initialize) procedure, then
      that procedure will be called before the record is deserialized.

      Parameters:
        ARecordType: the type of the record to deserialize. This is the result
          from a TypeInfo(TMyRecord) call.
        ARecord: the record (of ARecordType) to deserialize.
        AData: the byte array containing the serialized record. }
    class procedure Deserialize(const ARecordType: Pointer; out ARecord;
      const AData: TBytes); overload; static;

    { Deserializes a record from a memory buffer.
      When the record contains a parameterless @code(Initialize) procedure, then
      that procedure will be called before the record is deserialized.

      Parameters:
        T: the type of the record to deserialize.
        ARecord: the record (of type T) to deserialize.
        ABuffer: the memory buffer containing the serialized record.
        ABufferSize: the size of the buffer }
    class procedure Deserialize<T{$IF (RTLVersion < 36)}: record{$ENDIF}>(out ARecord: T; const ABuffer: Pointer;
      const ABufferSize: Integer); overload; static; inline;

    { Deserializes a record from a stream.
      When the record contains a parameterless @code(Initialize) procedure, then
      that procedure will be called before the record is deserialized.

      Parameters:
        T: the type of the record to deserialize.
        ARecordType: the type of the record to deserialize. This is the result
          from a TypeInfo(TMyRecord) call.
        ARecord: the record (of ARecordType) to deserialize.
        ABuffer: the memory buffer containing the serialized record.
        ABufferSize: the size of the buffer }
    class procedure Deserialize(const ARecordType: Pointer; out ARecord;
      const ABuffer: Pointer; const ABufferSize: Integer); overload; static;

    { Deserializes a record from a file.
      When the record contains a parameterless @code(Initialize) procedure, then
      that procedure will be called before the record is deserialized.

      Parameters:
        T: the type of the record to deserialize.
        ARecord: the record (of type T) to deserialize.
        AFilename: the name of the file containing the serialized record. }
    class procedure Deserialize<T{$IF (RTLVersion < 36)}: record{$ENDIF}>(out ARecord: T; const AFilename: String); overload; static; inline;

    { Deserializes a record from a file.
      When the record contains a parameterless @code(Initialize) procedure, then
      that procedure will be called before the record is deserialized.

      Parameters:
        ARecordType: the type of the record to deserialize. This is the result
          from a TypeInfo(TMyRecord) call.
        ARecord: the record (of ARecordType) to deserialize.
        AFilename: the name of the file containing the serialized record. }
    class procedure Deserialize(const ARecordType: Pointer; out ARecord;
      const AFilename: String); overload; static;

    { Deserializes a record from a stream.
      When the record contains a parameterless @code(Initialize) procedure, then
      that procedure will be called before the record is deserialized.

      Parameters:
        T: the type of the record to deserialize.
        ARecord: the record (of type T) to deserialize.
        AStream: the stream containing the serialized record. }
    class procedure Deserialize<T{$IF (RTLVersion < 36)}: record{$ENDIF}>(out ARecord: T; const AStream: TStream); overload; static; inline;

    { Deserializes a record from a stream.
      When the record contains a parameterless @code(Initialize) procedure, then
      that procedure will be called before the record is deserialized.

      Parameters:
        T: the type of the record to deserialize.
        ARecordType: the type of the record to deserialize. This is the result
          from a TypeInfo(TMyRecord) call.
        ARecord: the record (of ARecordType) to deserialize.
        AStream: the stream containing the serialized record. }
    class procedure Deserialize(const ARecordType: Pointer; out ARecord;
      const AStream: TStream); overload; static;

    { Registers a record for serialization in Protocol Buffer format. This is
      only needed for use with Free Pascal. When using Delphi, the record type is
      automatically registered when it is first (de)serialized.

      You can also use this method to register 3rd party or RTL record types.

      Every record type you want to use for serialization must be registered
      once and only once. You usually do this at application startup. If a
      record has fields of other record types, then those other record types
      must be registered as well.

      To register a record, you must declare a dummy variable of the record
      type and then call this method as in the following example:

      <source>
      var
        P: TPerson; // Dummy variable
      begin
        TgoProtocolBuffer.Register(TypeInfo(TPerson), P, @TPerson.Initialize,
          [@P.Name, 1, @P.Id, 2, @P.Email, 3, @P.Phone, 4]);
      end;
      </source>

      The parameters are the @code(TypeInfo(..)) of the record type, the dummy
      variable, the optional address of an Initialize method and an array of
      tags and field addresses.

      The dummy variable is just used as a helper to pass the field addresses.
      You don't need to initialize this variable with any data.

      Before a record of this type is deserialized, its fields are always
      cleared (set to 0 or nil). You can perform additional initialization after
      this by specifying an Initialize method. If set, that method will be
      called after clearing all fields, but before deserializing. Pass nil to
      clear the record only.

      The final parameter is an array of tags and field addresses. Each tag
      uniquely identifies the corresponding field. Tags must be in the range
      1-536870911. Tags must be unique within the record and each tag must have
      a corresponding field address. If the number of tags doesn't match the
      number of addresses, or if there are any other invalid parameters, then an
      exception is raised.

      You can pass the tags and field addresses in any way you want, as long as
      you pass the tags in the same order as the corresponding field addresses.
      You can use the (Field, Tag)* order as in the example above, or the
      opposite (Tag, Field)* order as in this example:

      <source>[1, @P.Name, 2, @P.Id, 3, @P.Email, 4, @P.Phone]</source>

      You can also specify all fields first, followed by all tags, or the other
      way around:

      <source>[@P.Name, @P.Id, @P.Email, @P.Phone, 1, 2, 3, 4]</source>

      Or any other combination that makes sense in the declaration:

      <source>
      [@P.Name,  @P.Id,
       1      ,  2,
       @P.Email, @P.Phone,
       3       , 4]
      </source>

      Just remember that the order of the tags must match the order of the
      fields.

      Parameters:
        ARecordType: the type of the record to register. This is the result
          from a TypeInfo(TMyRecord) call.
        ARecord: a dummy instance of the record type to register (of type
          ARecordType).
        AInitializeProc: the record method to call to initialize the record
          with its default values.
        AFields: an array of tags and record field addresses. See the
          documentation above for more information. }
    class procedure Register(const ARecordType: Pointer; const ARecord;
      const AInitializeProc: TInitializeProc; const AFields: array of const); static;
  end;

implementation

uses
  Grijjy.Collections;

const
  WIRE_TYPE_VARINT        = 0;
  WIRE_TYPE_64BIT         = 1;
  WIRE_TYPE_VARIABLE_SIZE = 2;
  WIRE_TYPE_START_GROUP   = 3;
  WIRE_TYPE_END_GROUP     = 4;
  WIRE_TYPE_32BIT         = 5;

type
  PInt8 = ^Int8;
  PInt16 = ^Int16;
  PInt32 = ^Int32;
  PUInt8 = ^UInt8;
  PUInt16 = ^UInt16;
  PUInt32 = ^UInt32;

{ SerializeAttribute }

constructor SerializeAttribute.Create(const ATag: TgoSerializationTag);
begin
  inherited Create;
  FTag := ATag;
end;

{ TgoProtocolBuffer }

class constructor TgoProtocolBuffer.Create;
begin
  FTypeInfoMap := TObjectDictionary<Pointer, TBaseTypeInfo>.Create([doOwnsValues]);
  FTypeInfoMapLock := TCriticalSection.Create;
end;

class procedure TgoProtocolBuffer.Deserialize<T>(out ARecord: T;
  const AData: TBytes);
begin
  Deserialize(TypeInfo(T), ARecord, AData);
end;

class procedure TgoProtocolBuffer.Deserialize<T>(out ARecord: T;
  const ABuffer: Pointer; const ABufferSize: Integer);
begin
  Deserialize(TypeInfo(T), ARecord, ABuffer, ABufferSize);
end;

class procedure TgoProtocolBuffer.Deserialize<T>(out ARecord: T;
  const AFilename: String);
begin
  Deserialize(TypeInfo(T), ARecord, AFilename);
end;

class procedure TgoProtocolBuffer.Deserialize<T>(out ARecord: T;
  const AStream: TStream);
begin
  Deserialize(TypeInfo(T), ARecord, AStream);
end;

class procedure TgoProtocolBuffer.Deserialize(const ARecordType: Pointer;
  out ARecord; const AData: TBytes);
begin
  Deserialize(ARecordType, ARecord, Pointer(AData), Length(AData));
end;

class procedure TgoProtocolBuffer.Deserialize(const ARecordType: Pointer;
  out ARecord; const ABuffer: Pointer; const ABufferSize: Integer);
var
  RecordTypeInfo: TRecordTypeInfo;
  RecordPtr: Pointer;
  Reader: TReader;
begin
  RecordPtr := @ARecord;
  RecordTypeInfo := RegisterRecordTypeInfo(ARecordType);

  Reader := TReader.Create(ABuffer, ABufferSize);
  try
    RecordTypeInfo.Deserialize(Reader, RecordPtr);
  finally
    Reader.Free;
  end;
end;

class procedure TgoProtocolBuffer.Deserialize(const ARecordType: Pointer;
  out ARecord; const AFilename: String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    Deserialize(ARecordType, ARecord, Stream);
  finally
    Stream.Free;
  end;
end;

class procedure TgoProtocolBuffer.Deserialize(const ARecordType: Pointer;
  out ARecord; const AStream: TStream);
var
  Bytes: TBytes;
begin
  SetLength(Bytes, AStream.Size - AStream.Position);
  if Assigned(Bytes) then
    AStream.ReadBuffer(Bytes[0], Length(Bytes));
  Deserialize(ARecordType, ARecord, Bytes);
end;

class procedure TgoProtocolBuffer.Register(const ARecordType: Pointer; const ARecord;
  const AInitializeProc: TInitializeProc; const AFields: array of const);
var
  Context: TRttiContext;
  RecordAddress, RecordEndAddress: NativeUInt;
  RecordType, FieldType: TRttiType;
  RecordTypeInfo: TRecordTypeInfo;
  Tags: TArray<Integer>;
  Offsets: TArray<NativeUInt>;
  TagSet: TgoSet<Integer>;
  OffsetToTag: TDictionary<NativeUInt, Integer>;
  OffsetsToIgnore: TgoSet<NativeUInt>;
  I, FieldCount, TagCount, OffsetCount, Count, Tag: Integer;
  V: TVarRec;
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  FieldInfo: TFieldTypeInfo;
  FieldInfos: TArray<TFieldTypeInfo>;
  SerializeProc: TSerializeProc;
  DeserializeProc: TDeserializeProc;
  Param: TObject;
begin
  Assert(Assigned(FTypeInfoMap));

  if (ARecordType = nil) then
    raise EgoSerializationError.Create('Invalid call to TgoProtocolBuffer.Register. ARecordType cannot be nil.');

  if (FTypeInfoMap.ContainsKey(ARecordType)) then
    raise EgoSerializationError.Create('Invalid call to TgoProtocolBuffer.Register. Duplicate registration of type ' + GetTypeName(ARecordType));

  Context := TRttiContext.Create;
  RecordType := Context.GetType(ARecordType);
  if (RecordType = nil) then
    raise EgoSerializationError.Create('Unable to get data type for type ' + GetTypeName(ARecordType));

  if (Length(AFields) = 0) then
    raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). No fields specified.', [RecordType.Name]);

  if (Odd(Length(AFields))) then
    raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Number of elements in AFields array must be even.', [RecordType.Name]);

  RecordAddress := NativeUInt(@ARecord);
  RecordEndAddress := RecordAddress + NativeUInt(RecordType.TypeSize);
  FieldCount := Length(AFields) div 2;
  SetLength(Tags, FieldCount);
  SetLength(Offsets, FieldCount);
  TagCount := 0;
  OffsetCount := 0;
  TagSet := TgoSet<Integer>.Create;
  try
    { Sort all AFields values into tags and offsets }
    for I := 0 to Length(AFields) - 1 do
    begin
      V := AFields[I];
      if (V.VType = vtInteger) then
      begin
        if (TagCount >= FieldCount) then
          raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Too many tags specified.', [RecordType.Name]);
        if (TagSet.Contains(V.VInteger)) then
          raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Duplicate tag %d.', [RecordType.Name, V.VInteger]);
        if ((V.VInteger < 1) or (V.VInteger > 536870911)) and (V.VInteger <> -1) then
          raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Tag %d must be between 1 and 536870911.', [RecordType.Name, V.VInteger]);
        TagSet.Add(V.VInteger);
        Tags[TagCount] := V.VInteger;
        Inc(TagCount);
      end
      else if (V.VType = vtPointer) then
      begin
        if (OffsetCount >= FieldCount) then
          raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Too many field addresses specified.', [RecordType.Name]);
        if (NativeUInt(V.VPointer) < RecordAddress) or (NativeUInt(V.VPointer) >= RecordEndAddress) then
          raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Field address does not belong to record.', [RecordType.Name]);
        Offsets[OffsetCount] := NativeUInt(V.VPointer) - RecordAddress;
        Inc(OffsetCount);
      end
      else
        raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Each AFields element must be an Integer (tag) or Pointer (field address).', [RecordType.Name]);
    end;
  finally
    TagSet.Free;
  end;

  if (TagCount <> FieldCount) then
    raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Insufficient number of tags specified.', [RecordType.Name]);
  if (OffsetCount <> FieldCount) then
    raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Insufficient number of field addresses specified.', [RecordType.Name]);

  Count := 0;
  OffsetsToIgnore := nil;
  OffsetToTag := TDictionary<NativeUInt, Integer>.Create;
  try
    OffsetsToIgnore := TgoSet<NativeUInt>.Create;
    for I := 0 to FieldCount - 1 do
    begin
      if (Tags[I] > 0) then
      begin
        if (OffsetToTag.TryGetValue(Offsets[I], Tag)) then
          raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Duplicate field offset %d (tags %d and %d).', [RecordType.Name, Offsets[I], Tag, Tags[I]]);
        OffsetToTag.Add(Offsets[I], Tags[I]);
      end
      else
        OffsetsToIgnore.AddOrSet(Offsets[I]);
    end;
    Fields := RecordType.GetDeclaredFields;
    SetLength(FieldInfos, FieldCount);
    for Field in Fields do
    begin
      if (OffsetToTag.TryGetValue(Field.Offset, Tag)) then
      begin
        FieldType := Field.FieldType;

        if (not GetSerializationProcs(FieldType, SerializeProc, DeserializeProc, Param)) then
        begin
          if (OffsetsToIgnore.Contains(Field.Offset)) then
            Continue;

          if (FieldType.TypeKind in [tkString, tkLString, tkWString]) then
            raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Unsupported data type "%s". Note that string types other than UnicodeString are not supported.', [RecordType.Name, FieldType.Name])
          else
            raise EgoSerializationError.CreateFmt('Invalid call to TgoProtocolBuffer.Register(%s). Unsupported data type "%s".', [RecordType.Name, FieldType.Name]);
        end;

        Assert(Count < FieldCount);
        FieldInfo := TFieldTypeInfo.Create(Tag, Field.Offset, SerializeProc, DeserializeProc, Param);
        FieldInfos[Count] := FieldInfo;
        Inc(Count);

        { Remove this field offset. This is to support variant parts in record.
          For example, TRectF is defined as:

            TRectF = record
            case Integer of
              0: (Left, Top, Right, Bottom: Single);
              1: (TopLeft, BottomRight: TPointF);
            end;

          Both Left and TopLeft have the same offset. However, once Left has
          been processed, we don't want to process TopLeft anymore.

          NOTE: this means that only the "first variants" in a variant record
          can be registered (the 4 Single fields in this example }
        OffsetToTag.Remove(Field.Offset);
      end;
    end;
  finally
    OffsetsToIgnore.Free;
    OffsetToTag.Free;
  end;

  if (Count = 0) then
    raise EgoSerializationError.CreateFmt('Unable register record type %s. It does not contain any [Serialize] fields',
      [RecordType.Name]);

  SetLength(FieldInfos, Count);
  RecordTypeInfo := TRecordTypeInfo.Create(ARecordType, RecordType.TypeSize, AInitializeProc, FieldInfos);

  { Another thread may already have registered the same type in the meantime.
    In that case, ignore this one and use the existing type. }
  Assert(Assigned(FTypeInfoMap));
  Assert(Assigned(FTypeInfoMapLock));
  FTypeInfoMapLock.Enter;
  try
    if (FTypeInfoMap.ContainsKey(ARecordType)) then
      { Ignore and free the type we just created. }
      FreeAndNil(RecordTypeInfo)
    else
      FTypeInfoMap.Add(ARecordType, RecordTypeInfo);
  finally
    FTypeInfoMapLock.Leave;
  end;
end;

class procedure TgoProtocolBuffer.DeserializeBytes(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
type
  PBytes = ^TBytes;
var
  Len: Integer;
  Bytes: TBytes;
  P: PBytes;
begin
  Len := AReader.ReadVarUInt;
  if (Len > 0) then
  begin
    SetLength(Bytes, Len);
    AReader.ReadBytes(Bytes[0], Len);
  end;

  P := @ARecord[AOffset];
  P^ := Bytes;
end;

class procedure TgoProtocolBuffer.DeserializeDynArrayPacked(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  ArrayInfo: TArrayTypeInfo absolute AParam;
  ElementDeserializeProc: TDeserializeProc;
  ElementParam: TObject;
  ElementSize, Len, EndIndex, Count: Integer;
  Capacity: NativeInt;
  PA: PPointer;
  P: Pointer;
  Element: PByte;
begin
  Assert(Assigned(AParam));
  Assert(AParam is TArrayTypeInfo);
  ElementDeserializeProc := ArrayInfo.ElementDeserializeProc;
  ElementParam := ArrayInfo.ElementParam;
  ElementSize := ArrayInfo.ElementSize;
  PA := @ARecord[AOffset];
  P := PA^;
  Element := P;
  Len := AReader.ReadVarUInt;
  EndIndex := AReader.Index + Len;
  Count := 0;
  Capacity := 0;
  while (AReader.Index < EndIndex) do
  begin
    if (Count >= Capacity) then
    begin
      Inc(Capacity, 16);
      DynArraySetLength(P, ArrayInfo.TypeInfo, 1, @Capacity);
      Element := PByte(P) + (Count * ElementSize);
    end;

    Inc(Count);
    ElementDeserializeProc(AReader, Element, ATag, 0, ElementParam);
    Inc(Element, ElementSize);
  end;
  Assert(AReader.Index = EndIndex);

  Capacity := Count;
  DynArraySetLength(P, ArrayInfo.TypeInfo, 1, @Capacity);
  PA^ := P;
end;

class procedure TgoProtocolBuffer.DeserializeDynArrayUnpacked(
  const AReader: TReader; const ARecord: PByte; const ATag, AOffset: Integer;
  const AParam: TObject);
var
  ArrayInfo: TArrayTypeInfo absolute AParam;
  ElementDeserializeProc: TDeserializeProc;
  ElementParam: TObject;
  PA: PPointer;
  P: Pointer;
  Element: PByte;
  Count, NextTag, Size, ElementSize: Integer;
  Capacity: NativeInt;
begin
  Assert(Assigned(AParam));
  Assert(AParam is TArrayTypeInfo);
  ElementDeserializeProc := ArrayInfo.ElementDeserializeProc;
  ElementParam := ArrayInfo.ElementParam;
  ElementSize := ArrayInfo.ElementSize;
  PA := @ARecord[AOffset];
  P := PA^;
  Element := P;
  Count := 0;
  Capacity := 0;
  while True do
  begin
    if (Count >= Capacity) then
    begin
      Inc(Capacity, 16);
      DynArraySetLength(P, ArrayInfo.TypeInfo, 1, @Capacity);
      Element := PByte(P) + (Count * ElementSize);
    end;

    Inc(Count);
    ElementDeserializeProc(AReader, Element, ATag, 0, ElementParam);

    if (not AReader.HasData) then
      Break;

    NextTag := AReader.PeekVarUInt(Size) shr 3;
    if (NextTag <> ATag) then
      Break;

    AReader.Skip(Size);
    Inc(Element, ElementSize);
  end;

  Capacity := Count;
  DynArraySetLength(P, ArrayInfo.TypeInfo, 1, @Capacity);
  PA^ := P;
end;

class procedure TgoProtocolBuffer.DeserializeFixed32(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt32;
begin
  P := @ARecord[AOffset];
  AReader.ReadBytes(P^, 4);
end;

class procedure TgoProtocolBuffer.DeserializeFixed64(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt32;
begin
  P := @ARecord[AOffset];
  AReader.ReadBytes(P^, 8);
end;

class procedure TgoProtocolBuffer.DeserializeInt16(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt16;
begin
  P := @ARecord[AOffset];
  P^ := AReader.ReadVarInt;
end;

class procedure TgoProtocolBuffer.DeserializeInt32(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt32;
begin
  P := @ARecord[AOffset];
  P^ := AReader.ReadVarInt;
end;

class procedure TgoProtocolBuffer.DeserializeInt64(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt64;
begin
  P := @ARecord[AOffset];
  P^ := AReader.ReadVarInt64;
end;

class procedure TgoProtocolBuffer.DeserializeInt8(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt8;
begin
  P := @ARecord[AOffset];
  P^ := AReader.ReadVarInt;
end;

class procedure TgoProtocolBuffer.DeserializeRecord(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: Pointer;
  Info: TRecordTypeInfo absolute AParam;
  Len: Integer;
  RecBytes: TBytes;
  RecReader: TReader;
begin
  Assert(Assigned(AParam));
  Assert(AParam is TRecordTypeInfo);
  P := @ARecord[AOffset];
  Len := AReader.ReadVarUInt;
  SetLength(RecBytes, Len);
  if (Len > 0) then
  begin
    AReader.ReadBytes(RecBytes[0], Len);
    RecReader := TReader.Create(@RecBytes[0], Len);
    try
      Info.Deserialize(RecReader, P);
    finally
      RecReader.Free;
    end;
  end;
end;

class procedure TgoProtocolBuffer.DeserializeUInt16(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PUInt16;
begin
  P := @ARecord[AOffset];
  P^ := AReader.ReadVarUInt;
end;

class procedure TgoProtocolBuffer.DeserializeUInt32(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PUInt32;
begin
  P := @ARecord[AOffset];
  P^ := AReader.ReadVarUInt;
end;

class procedure TgoProtocolBuffer.DeserializeUInt64(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PUInt64;
begin
  P := @ARecord[AOffset];
  P^ := AReader.ReadVarUInt64;
end;

class procedure TgoProtocolBuffer.DeserializeUInt8(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PUInt8;
begin
  P := @ARecord[AOffset];
  P^ := AReader.ReadVarUInt;
end;

class procedure TgoProtocolBuffer.DeserializeUString(const AReader: TReader;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  Len: Integer;
  Bytes: TBytes;
  S: UnicodeString;
  P: PUnicodeString;
begin
  Len := AReader.ReadVarUInt;
  if (Len > 0) then
  begin
    SetLength(Bytes, Len);
    AReader.ReadBytes(Bytes[0], Len);
    S := TEncoding.UTF8.GetString(Bytes);
  end;

  P := @ARecord[AOffset];
  P^ := S;
end;

class destructor TgoProtocolBuffer.Destroy;
begin
  FreeAndNil(FTypeInfoMap);
  FreeAndNil(FTypeInfoMapLock);
end;

class function TgoProtocolBuffer.GetSerializationProcs(const AType: TRttiType;
  out ASerializeProc: TSerializeProc; out ADeserializeProc: TDeserializeProc;
  out AParam: TObject): Boolean;
var
  ArrayInfo: TArrayTypeInfo;
  TypeData: PTypeData;
  S: String;
begin
  ASerializeProc := nil;
  ADeserializeProc := nil;
  AParam := nil;
  case AType.TypeKind of
    tkUString:
      begin
        ASerializeProc := SerializeUString;
        ADeserializeProc := DeserializeUString;
      end;

    tkInteger:
      begin
        S := UpperCase(AType.Name);
        if (S = 'FIXEDINT32') or (S = 'FIXEDUINT32') then
        begin
          ASerializeProc := SerializeFixed32;
          ADeserializeProc := DeserializeFixed32;
        end
        else
        begin
          TypeData := GetTypeData(AType.Handle);
          case TypeData.OrdType of
            otSByte: begin
                       ASerializeProc := SerializeInt8;
                       ADeserializeProc := DeserializeInt8;
                     end;
            otUByte: begin
                       ASerializeProc := SerializeUInt8;
                       ADeserializeProc := DeserializeUInt8;
                     end;
            otSWord: begin
                       ASerializeProc := SerializeInt16;
                       ADeserializeProc := DeserializeInt16;
                     end;
            otUWord: begin
                       ASerializeProc := SerializeUInt16;
                       ADeserializeProc := DeserializeUInt16;
                     end;
            otSLong: begin
                       ASerializeProc := SerializeInt32;
                       ADeserializeProc := DeserializeInt32;
                     end;
            otULong: begin
                       ASerializeProc := SerializeUInt32;
                       ADeserializeProc := DeserializeUInt32;
                     end;
          else
            Assert(False);
          end;
        end;
      end;

    tkInt64:
      begin
        S := UpperCase(AType.Name);
        if (S = 'FIXEDINT64') or (S = 'FIXEDUINT64') then
        begin
          ASerializeProc := SerializeFixed64;
          ADeserializeProc := DeserializeFixed64;
        end
        else
        begin
          TypeData := GetTypeData(AType.Handle);
          if (TypeData.MinInt64Value > TypeData.MaxInt64Value) then
          begin
            ASerializeProc := SerializeUInt64;
            ADeserializeProc := DeserializeUInt64;
          end
          else
          begin
            ASerializeProc := SerializeInt64;
            ADeserializeProc := DeserializeInt64;
          end;
        end;
      end;

    tkFloat:
      begin
        TypeData := GetTypeData(AType.Handle);
        if (TypeData.FloatType = ftSingle) then
        begin
          ASerializeProc := SerializeFixed32;
          ADeserializeProc := DeserializeFixed32;
        end
        else if (TypeData.FloatType = ftDouble) then
        begin
          ASerializeProc := SerializeFixed64;
          ADeserializeProc := DeserializeFixed64;
        end;
      end;

    tkEnumeration,
    tkSet:
      begin
        TypeData := GetTypeData(AType.Handle);
        case TypeData.OrdType of
          otUByte: begin
                     ASerializeProc := SerializeUInt8;
                     ADeserializeProc := DeserializeUInt8;
                   end;
          otUWord: begin
                     ASerializeProc := SerializeUInt16;
                     ADeserializeProc := DeserializeUInt16;
                   end;
          otULong: begin
                     ASerializeProc := SerializeUInt32;
                     ADeserializeProc := DeserializeUInt32;
                   end;
        else
          Assert(False);
        end;
      end;

    tkRecord:
      begin
        AParam := RegisterRecordTypeInfo(AType.Handle);
        ASerializeProc := SerializeRecord;
        ADeserializeProc := DeserializeRecord;
      end;

    tkDynArray:
      begin
        ArrayInfo := RegisterArrayTypeInfo(AType.Handle);
        AParam := ArrayInfo;
        TypeData := GetTypeData(ArrayInfo.ElementType);
        if (ArrayInfo.ElementType.Kind = tkInteger)
          and (TypeData.OrdType = otUByte) then
        begin
          { Binary data (TBytes) }
          ASerializeProc := SerializeBytes;
          ADeserializeProc := DeserializeBytes;
        end
        else if (ArrayInfo.ElementType.Kind in [tkInteger, tkFloat, tkEnumeration, tkInt64]) then
        begin
          { Use "packed" arrays for 32-bit and 64-bit types }
          ASerializeProc := SerializeDynArrayPacked;
          ADeserializeProc := DeserializeDynArrayPacked;
        end
        else
        begin
          { Use "unpacked" arrays for all other types }
          ASerializeProc := SerializeDynArrayUnpacked;
          ADeserializeProc := DeserializeDynArrayUnpacked;
        end;
      end;
  end;
  Result := Assigned(ASerializeProc) and Assigned(ADeserializeProc);
end;

class function TgoProtocolBuffer.RegisterArrayTypeInfo(
  const ATypeInfo: PTypeInfo): TArrayTypeInfo;
var
  BaseTypeInfo, ElementInfo: TBaseTypeInfo;
  ElementTypePtr: PPTypeInfo;
  ElementTypeInfo: PTypeInfo;
  ElementType: TRttiType;
  ElementSerializeProc: TSerializeProc;
  ElementDeserializeProc: TDeserializeProc;
  ElementParam: TObject;
  Context: TRttiContext;
  TypeName: String;
begin
  Assert(Assigned(FTypeInfoMap));
  if (FTypeInfoMap.TryGetValue(ATypeInfo, BaseTypeInfo)) then
  begin
    Assert(BaseTypeInfo is TArrayTypeInfo);
    Exit(TArrayTypeInfo(BaseTypeInfo));
  end;

  TypeName := ATypeInfo.NameFld.ToString;
  ElementTypePtr := GetTypeData(ATypeInfo).DynArrElType;
  if (ElementTypePtr = nil) or (ElementTypePtr^ = nil) then
    raise EgoSerializationError.Create('Unsupported element type for array type ' + TypeName);
  ElementTypeInfo := ElementTypePtr^;

  Context := TRttiContext.Create;
  ElementType := Context.GetType(ElementTypeInfo);
  if (ElementType = nil) then
    raise EgoSerializationError.Create('Cannot get type information for array type ' + TypeName);

  if (ElementTypeInfo.Kind = tkRecord) then
    ElementInfo := RegisterRecordTypeInfo(ElementTypeInfo)
  else
    ElementInfo := nil;

  if (not GetSerializationProcs(ElementType, ElementSerializeProc,
    ElementDeserializeProc, ElementParam))
  then
    raise EgoSerializationError.Create('Unsupported element type for array type ' + TypeName);

  Result := TArrayTypeInfo.Create(ATypeInfo, 4, ElementTypeInfo,
    ElementType.TypeSize, ElementInfo, ElementSerializeProc,
    ElementDeserializeProc, ElementParam);

  { Another thread may already have registered the same type in the meantime.
    In that case, ignore this one and use the existing type. }
  Assert(Assigned(FTypeInfoMap));
  Assert(Assigned(FTypeInfoMapLock));
  FTypeInfoMapLock.Enter;
  try
    if (FTypeInfoMap.TryGetValue(ATypeInfo, BaseTypeInfo)) then
    begin
      { Ignore and free the type we just created, and return the existing one
        instead. }
      FreeAndNil(Result);
      Assert(BaseTypeInfo is TArrayTypeInfo);
      Result := TArrayTypeInfo(BaseTypeInfo);
    end
    else
      FTypeInfoMap.Add(ATypeInfo, Result);
  finally
    FTypeInfoMapLock.Leave;
  end;
end;

class function TgoProtocolBuffer.RegisterRecordTypeInfo(const ATypeInfo: Pointer): TRecordTypeInfo;
var
  BaseTypeInfo: TBaseTypeInfo;
  Context: TRttiContext;
  RecType, FieldType: TRttiType;
  InitMethod: TRttiMethod;
  InitProc: TInitializeProc;
  Fields: TArray<TRttiField>;
  Field: TRttiField;
  Attr: TCustomAttribute;
  SerializeAttr: SerializeAttribute absolute Attr;
  SerializeProc: TSerializeProc;
  DeserializeProc: TDeserializeProc;
  FieldInfo: TFieldTypeInfo;
  FieldInfos: TArray<TFieldTypeInfo>;
  Count: Integer;
  Param: TObject;
  Tags: TgoSet<Integer>;
begin
  Assert(Assigned(FTypeInfoMap));
  if (FTypeInfoMap.TryGetValue(ATypeInfo, BaseTypeInfo)) then
  begin
    Assert(BaseTypeInfo is TRecordTypeInfo);
    Exit(TRecordTypeInfo(BaseTypeInfo));
  end;

  Context := TRttiContext.Create;
  RecType := Context.GetType(ATypeInfo);
  if (RecType = nil) then
    raise EgoSerializationError.Create('Unable to get data type for type ' +
      {$IFDEF NEXTGEN}
      PTypeInfo(ATypeInfo).NameFld.ToString);
      {$ELSE}
      String(PTypeInfo(ATypeInfo).Name));
      {$ENDIF}

  InitProc := nil;
  InitMethod := RecType.GetMethod('Initialize');
  if Assigned(InitMethod) and (Length(InitMethod.GetParameters) = 0)
    and (InitMethod.MethodKind = mkProcedure)
    and (InitMethod.CallingConvention = ccReg)
  then
    InitProc := InitMethod.CodeAddress;

  Tags := TgoSet<Integer>.Create;
  try
    Count := 0;
    Fields := RecType.GetDeclaredFields;
    SetLength(FieldInfos, Length(Fields));
    for Field in Fields do
    begin
      for Attr in Field.GetAttributes do
      begin
        if (Attr is SerializeAttribute) then
        begin
          if (SerializeAttr.Tag <= 0) or (SerializeAttr.Tag > 536870911) then
            raise EgoSerializationError.CreateFmt('Invalid serialization tag value for %s.%s',
              [RecType.Name, Field.Name]);

          FieldType := Field.FieldType;
          if (FieldType = nil) then
            raise EgoSerializationError.CreateFmt('Unable to get serialization type value for %s.%s',
              [RecType.Name, Field.Name]);

          if (not GetSerializationProcs(FieldType, SerializeProc, DeserializeProc, Param)) then
            raise EgoSerializationError.CreateFmt('Unsupported data type "%s" for %s.%s',
              [FieldType.Name, RecType.Name, Field.Name]);

          if (Tags.Contains(SerializeAttr.Tag)) then
            raise EgoSerializationError.CreateFmt('Duplicate tag %d for %s.%s',
              [SerializeAttr.Tag, RecType.Name, Field.Name]);

          Tags.Add(SerializeAttr.Tag);
          FieldInfo := TFieldTypeInfo.Create(SerializeAttr.Tag, Field.Offset,
            SerializeProc, DeserializeProc, Param);

          Assert(Count < Length(FieldInfos));
          FieldInfos[Count] := FieldInfo;
          Inc(Count);
          Break;
        end;
      end;
    end;
  finally
    Tags.Free;
  end;

  if (Count = 0) then
    raise EgoSerializationError.CreateFmt('Unable register record type %s. It does not contain any [Serialize] fields',
      [RecType.Name]);

  SetLength(FieldInfos, Count);
  Result := TRecordTypeInfo.Create(RecType.Handle, RecType.TypeSize, InitProc, FieldInfos);

  { Another thread may already have registered the same type in the meantime.
    In that case, ignore this one and use the existing type. }
  Assert(Assigned(FTypeInfoMap));
  Assert(Assigned(FTypeInfoMapLock));
  FTypeInfoMapLock.Enter;
  try
    if (FTypeInfoMap.TryGetValue(ATypeInfo, BaseTypeInfo)) then
    begin
      { Ignore and free the type we just created, and return the existing one
        instead. }
      FreeAndNil(Result);
      Assert(BaseTypeInfo is TRecordTypeInfo);
      Result := TRecordTypeInfo(BaseTypeInfo);
    end
    else
      FTypeInfoMap.Add(ATypeInfo, Result);
  finally
    FTypeInfoMapLock.Leave;
  end;
end;

class function TgoProtocolBuffer.Serialize(const ARecordType: Pointer;
  const ARecord): TBytes;
var
  RecordTypeInfo: TRecordTypeInfo;
  Writer: TWriter;
begin
  RecordTypeInfo := RegisterRecordTypeInfo(ARecordType);
  Writer := TWriter.Create;
  try
    RecordTypeInfo.Serialize(Writer, @ARecord);
    Result := Writer.ToBytes;
  finally
    Writer.Free;
  end;
end;

class procedure TgoProtocolBuffer.Serialize(const ARecordType: Pointer;
  const ARecord; const AFilename: String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmCreate);
  try
    Serialize(ARecordType, ARecord, Stream);
  finally
    Stream.Free;
  end;
end;

class procedure TgoProtocolBuffer.Serialize(const ARecordType: Pointer;
  const ARecord; const AStream: TStream);
var
  Bytes: TBytes;
begin
  Bytes := Serialize(ARecordType, ARecord);
  if Assigned(Bytes) then
    AStream.WriteBuffer(Bytes[0], Length(Bytes));
end;

class procedure TgoProtocolBuffer.SerializeBytes(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
type
  PBytes = ^TBytes;
var
  P: PBytes;
  Bytes: TBytes;
begin
  P := @ARecord[AOffset];
  Bytes := P^;

  if (Length(Bytes) > 0) then
  begin
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARIABLE_SIZE);
    AWriter.WriteVarUInt(Length(Bytes));
    AWriter.Append(Bytes);
  end;
end;

class function TgoProtocolBuffer.Serialize<T>(const ARecord: T): TBytes;
begin
  Result := Serialize(TypeInfo(T), ARecord);
end;

class procedure TgoProtocolBuffer.Serialize<T>(const ARecord: T;
  const AFilename: String);
begin
  Serialize(TypeInfo(T), ARecord, AFilename);
end;

class procedure TgoProtocolBuffer.Serialize<T>(const ARecord: T;
  const AStream: TStream);
begin
  Serialize(TypeInfo(T), ARecord, AStream);
end;

class procedure TgoProtocolBuffer.SerializeDynArrayPacked(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  ArrayInfo: TArrayTypeInfo absolute AParam;
  ElementSerializeProc: TSerializeProc;
  ElementParam: TObject;
  PA: PPointer;
  P: PByte;
  ArrayWriter: TWriter;
  I, ElementSize, Length: Integer;
begin
  Assert(Assigned(AParam));
  Assert(AParam is TArrayTypeInfo);
  PA := @ARecord[AOffset];
  P := PA^;
  if (P = nil) then
    { Empty array }
    Exit;

  ElementSerializeProc := ArrayInfo.ElementSerializeProc;
  ElementSize := ArrayInfo.ElementSize;
  ElementParam := ArrayInfo.ElementParam;
  Length := DynArraySize(P);

  AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARIABLE_SIZE);
  { To calculate the size of the array, we must serialize it first }
  ArrayWriter := TWriter.Create;
  try
    for I := 0 to Length - 1 do
    begin
      ElementSerializeProc(ArrayWriter, P, 0, 0, ElementParam);
      Inc(P, ElementSize);
    end;

    AWriter.WriteVarUInt(ArrayWriter.Size);
    AWriter.Append(ArrayWriter.ToBytes);
  finally
    ArrayWriter.Free;
  end;
end;

class procedure TgoProtocolBuffer.SerializeDynArrayUnpacked(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  ArrayInfo: TArrayTypeInfo absolute AParam;
  ElementSerializeProc: TSerializeProc;
  ElementParam: TObject;
  PA: PPointer;
  P: PByte;
  I, Length, ElementSize: Integer;
begin
  Assert(Assigned(AParam));
  Assert(AParam is TArrayTypeInfo);
  PA := @ARecord[AOffset];
  P := PA^;
  if (P = nil) then
    { Empty array }
    Exit;

  ElementSerializeProc := ArrayInfo.ElementSerializeProc;
  ElementSize := ArrayInfo.ElementSize;
  ElementParam := ArrayInfo.ElementParam;
  Length := DynArraySize(P);

  for I := 0 to Length - 1 do
  begin
    ElementSerializeProc(AWriter, P, ATag, 0, ElementParam);
    Inc(P, ElementSize);
  end;
end;

class procedure TgoProtocolBuffer.SerializeFixed32(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: Pointer;
begin
  P := @ARecord[AOffset];
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_32BIT);
  AWriter.AppendBuffer(P^, 4);
end;

class procedure TgoProtocolBuffer.SerializeFixed64(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: Pointer;
begin
  P := @ARecord[AOffset];
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_64BIT);
  AWriter.AppendBuffer(P^, 8);
end;

class procedure TgoProtocolBuffer.SerializeInt16(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt16;
  I: Integer;
begin
  P := @ARecord[AOffset];
  I := P^;
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARINT);
  AWriter.WriteVarInt(I);
end;

class procedure TgoProtocolBuffer.SerializeInt32(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt32;
  I: Integer;
begin
  P := @ARecord[AOffset];
  I := P^;
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARINT);
  AWriter.WriteVarInt(I);
end;

class procedure TgoProtocolBuffer.SerializeInt64(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt64;
  V: Int64;
begin
  P := @ARecord[AOffset];
  V := P^;
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARINT);
  AWriter.WriteVarInt64(V);
end;

class procedure TgoProtocolBuffer.SerializeInt8(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PInt8;
  I: Integer;
begin
  P := @ARecord[AOffset];
  I := P^;
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARINT);
  AWriter.WriteVarInt(I);
end;

class procedure TgoProtocolBuffer.SerializeRecord(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: Pointer;
  Info: TRecordTypeInfo absolute AParam;
  RecWriter: TWriter;
begin
  Assert(Assigned(AParam));
  Assert(AParam is TRecordTypeInfo);
  AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARIABLE_SIZE);
  P := @ARecord[AOffset];

  { To calculate the size of the record, we must serialize it first }
  RecWriter := TWriter.Create;
  try
    Info.Serialize(RecWriter, P);
    AWriter.WriteVarUInt(RecWriter.Size);
    AWriter.Append(RecWriter.ToBytes);
  finally
    RecWriter.Free;
  end;
end;

class procedure TgoProtocolBuffer.SerializeUInt16(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PUInt16;
  C: Cardinal;
begin
  P := @ARecord[AOffset];
  C := P^;
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARINT);
  AWriter.WriteVarUInt(C);
end;

class procedure TgoProtocolBuffer.SerializeUInt32(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PUInt32;
  C: Cardinal;
begin
  P := @ARecord[AOffset];
  C := P^;
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARINT);
  AWriter.WriteVarUInt(C);
end;

class procedure TgoProtocolBuffer.SerializeUInt64(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PUInt64;
  V: UInt64;
begin
  P := @ARecord[AOffset];
  V := P^;
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARINT);
  AWriter.WriteVarUInt64(V);
end;

class procedure TgoProtocolBuffer.SerializeUInt8(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PUInt8;
  C: Cardinal;
begin
  P := @ARecord[AOffset];
  C := P^;
  if (ATag > 0) then // Tag 0 is used for "packed" arrays
    AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARINT);
  AWriter.WriteVarUInt(C);
end;

class procedure TgoProtocolBuffer.SerializeUString(const AWriter: TWriter;
  const ARecord: PByte; const ATag, AOffset: Integer; const AParam: TObject);
var
  P: PUnicodeString;
  S: UnicodeString;
  Bytes: TBytes;
begin
  P := @ARecord[AOffset];
  S := P^;
  Bytes := TEncoding.UTF8.GetBytes(S);

  AWriter.WriteVarUInt((ATag shl 3) or WIRE_TYPE_VARIABLE_SIZE);
  AWriter.WriteVarUInt(Length(Bytes));
  AWriter.Append(Bytes);
end;

{ TgoProtocolBuffer.TWriter }

{$IFOPT R+}
  {$DEFINE HAS_RANGECHECKS}
  {$RANGECHECKS OFF}
{$ENDIF}
procedure TgoProtocolBuffer.TWriter.WriteVarInt(const AValue: Integer);
var
  ZigZag: Cardinal;
begin
  ZigZag := Cardinal(AValue) shl 1;
  if (AValue < 0) then
    ZigZag := ZigZag xor $FFFFFFFF;
  WriteVarUInt(ZigZag);
end;

procedure TgoProtocolBuffer.TWriter.WriteVarInt64(const AValue: Int64);
var
  ZigZag: UInt64;
begin
  ZigZag := UInt64(AValue) shl 1;
  if (AValue < 0) then
    ZigZag := ZigZag xor UInt64($FFFFFFFFFFFFFFFF);
  WriteVarUInt64(ZigZag);
end;
{$IFDEF HAS_RANGECHECKS}
  {$RANGECHECKS ON}
{$ENDIF}

procedure TgoProtocolBuffer.TWriter.WriteVarUInt(const AValue: Cardinal);
begin
  if (AValue >= $80) then
  begin
    Append(Byte(AValue) or $80);
    if (AValue >= $4000) then
    begin
      Append(Byte((AValue shr 7) or $80));
      if (AValue >= $200000) then
      begin
        Append(Byte((AValue shr 14) or $80));
        if (AValue >= $10000000)  then
        begin
          Append(Byte((AValue shr 21) or $80));
          Append(Byte(AValue shr 28));
        end
        else
          Append(Byte(AValue shr 21));
      end
      else
        Append(Byte(AValue shr 14));
    end
    else
      Append(Byte(AValue shr 7));
  end
  else
    Append(Byte(AValue));
end;

{$IFOPT R+}
  {$DEFINE HAS_RANGECHECKS}
  {$RANGECHECKS OFF}
{$ENDIF}
procedure TgoProtocolBuffer.TWriter.WriteVarUInt64(const AValue: UInt64);
var
  A, B, C: UInt32;
  Size: Integer;
  Target: array [0..9] of Byte;
label
  Size1, Size2, Size3, Size4, Size5, Size6, Size7, Size8, Size9;
begin
  A := UInt32(AValue);
  B := UInt32(AValue shr 28);
  C := UInt32(AValue shr 56);

  { There are GOTO's here. Ugly, but it really increases efficiency in this
    case. Taken from the Google source code. }
  if (C = 0) then
  begin
    if (B = 0) then
    begin
      if (A < $4000) then
      begin
        if (A < $80) then
        begin
          Size := 1; goto Size1;
        end
        else
        begin
          Size := 2; goto Size2;
        end;
      end
      else
      begin
        if (A < $200000) then
        begin
          Size := 3; goto Size3;
        end
        else
        begin
          Size := 4; goto Size4;
        end;
      end;
    end
    else if (B < $4000) then
    begin
      if (B < $80) then
      begin
        Size := 5; goto Size5;
      end
      else
      begin
        Size := 6; goto Size6;
      end;
    end
    else if (B < $200000) then
    begin
      Size := 7; goto Size7;
    end
    else
    begin
      Size := 8; goto Size8;
    end;
  end
  else if (C < $80) then
  begin
    Size := 9; goto Size9;
  end
  else
    Size := 10;

       Target[9] := (C shr  7) or $80;
Size9: Target[8] := (C       ) or $80;
Size8: Target[7] := (B shr 21) or $80;
Size7: Target[6] := (B shr 14) or $80;
Size6: Target[5] := (B shr  7) or $80;
Size5: Target[4] := (B       ) or $80;
Size4: Target[3] := (A shr 21) or $80;
Size3: Target[2] := (A shr 14) or $80;
Size2: Target[1] := (A shr  7) or $80;
Size1: Target[0] := (A       ) or $80;

  Target[Size - 1] := Target[Size - 1] and $7F;
  Append(Target, 0, Size);
end;
{$IFDEF HAS_RANGECHECKS}
  {$RANGECHECKS ON}
{$ENDIF}

{ TgoProtocolBuffer.TReader }

constructor TgoProtocolBuffer.TReader.Create(const ABuffer: Pointer;
  const ASize: Integer);
begin
  inherited Create;
  FBuffer := ABuffer;
  FSize := ASize;
end;

function TgoProtocolBuffer.TReader.HasData: Boolean;
begin
  Result := (FIndex < FSize);
end;

function TgoProtocolBuffer.TReader.PeekVarUInt(out ASize: Integer): Cardinal;
var
  SavedIndex: Integer;
begin
  SavedIndex := FIndex;
  Result := ReadVarUInt;
  ASize := FIndex - SavedIndex;
  FIndex := SavedIndex;
end;

function TgoProtocolBuffer.TReader.ReadByte: Byte;
begin
  if (FIndex >= FSize) then
    raise EgoSerializationError.Create('Unexpected end of protocol buffer');
  Result := FBuffer[FIndex];
  Inc(FIndex);
end;

procedure TgoProtocolBuffer.TReader.ReadBytes(out AData; const ASize: Integer);
begin
  if ((FIndex + ASize) > FSize) then
    raise EgoSerializationError.Create('Unexpected end of protocol buffer');
  Move(FBuffer[FIndex], AData{%H-}, ASize);
  Inc(FIndex, ASize);
end;

function TgoProtocolBuffer.TReader.ReadVarInt: Integer;
var
  C: Cardinal;
begin
  C := ReadVarUInt;
  Result := Integer(C shr 1) xor -Integer(C and 1);
end;

function TgoProtocolBuffer.TReader.ReadVarInt64: Int64;
var
  V: UInt64;
begin
  V := ReadVarUInt64;
  Result := Int64(V shr 1) xor -Int64(V and 1);
end;

function TgoProtocolBuffer.TReader.ReadVarUInt: Cardinal;
var
  B: Byte;
begin
  B := ReadByte;
  Result := B and $7F;
  if (B >= $80) then
  begin
    B := ReadByte;
    Result := Result or ((B and $7F) shl 7);
    if (B >= $80) then
    begin
      B := ReadByte;
      Result := Result or ((B and $7F) shl 14);
      if (B >= $80) then
      begin
        B := ReadByte;
        Result := Result or ((B and $7F) shl 21);
        if (B >= $80) then
        begin
          B := ReadByte;
          Assert(B < $80);
          Result := Result or (B shl 28);
        end;
      end;
    end;
  end;
end;

function TgoProtocolBuffer.TReader.ReadVarUInt64: UInt64;
var
  A, B, C: UInt32;
  V: Byte;
begin
  B := 0; C := 0;

  V := ReadByte;
  A := (V and $7F);
  if (V >= $80) then
  begin
    V := ReadByte;
    A := A or ((V and $7F) shl 7);
    if (V >= $80) then
    begin
      V := ReadByte;
      A := A or ((V and $7F) shl 14);
      if (V >= $80) then
      begin
        V := ReadByte;
        A := A or ((V and $7F) shl 21);
        if (V >= $80) then
        begin
          V := ReadByte;
          B := (V and $7F);
          if (V >= $80) then
          begin
            V := ReadByte;
            B := B or ((V and $7F) shl 7);
            if (V >= $80) then
            begin
              V := ReadByte;
              B := B or ((V and $7F) shl 14);
              if (V >= $80) then
              begin
                V := ReadByte;
                B := B or ((V and $7F) shl 21);
                if (V >= $80) then
                begin
                  V := ReadByte;
                  C := (V and $7F);
                  if (V >= $80) then
                  begin
                    V := ReadByte;
                    C := C or ((V and $7F) shl 7);
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  Result := UInt64(A) or (UInt64(B) shl 28) or (UInt64(C) shl 56);
end;

procedure TgoProtocolBuffer.TReader.Skip(const ASize: Integer);
begin
  Inc(FIndex, ASize);
end;

{ TgoProtocolBuffer.TFieldTypeInfo }

constructor TgoProtocolBuffer.TFieldTypeInfo.Create(const ATag, AOffset: Integer;
  const ASerializeProc: TSerializeProc; const ADeserializeProc: TDeserializeProc;
  const AParam: TObject);
begin
  inherited Create;
  FTag := ATag;
  FOffset := AOffset;
  FSerializeProc := ASerializeProc;
  FDeserializeProc := ADeserializeProc;
  FParam := AParam;
end;

{ TgoProtocolBuffer.TBaseTypeInfo }

constructor TgoProtocolBuffer.TBaseTypeInfo.Create(const ATypeInfo: PTypeInfo;
  const ASize: Integer);
begin
  inherited Create;
  FTypeInfo := ATypeInfo;
  FSize := ASize;
end;

{ TgoProtocolBuffer.TRecordTypeInfo }

constructor TgoProtocolBuffer.TRecordTypeInfo.Create(const ATypeInfo: PTypeInfo;
  const ASize: Integer; const AInitProc: TInitializeProc;
  const AFields: TArray<TFieldTypeInfo>);
begin
  inherited Create(ATypeInfo, ASize);
  FFields := AFields;
  FInitProc := AInitProc;
end;

procedure TgoProtocolBuffer.TRecordTypeInfo.Deserialize(const AReader: TReader;
  const ARecord: Pointer);
var
  C: Cardinal;
  I, Tag, WireType, FieldIndex, FieldCount: Integer;
  F, Field: TFieldTypeInfo;
begin
  FillChar(ARecord^, Size, 0);
  if Assigned(FInitProc) then
    FInitProc(ARecord);

  FieldCount := Length(FFields);
  FieldIndex := 0;
  while (AReader.HasData) do
  begin
    C := AReader.ReadVarUInt;
    Tag := C shr 3;

    { Records are serialized in field order, so the fields should be consecutive
      when deserializing. However, this isn't a requirement, so we may need to
      search for a field. We could use a Dictionary<Tag, Field> for this, but
      that is too much overhead and not needed most of the time. }
    Field := nil;
    for I := 0 to FieldCount - 1 do
    begin
      F := FFields[FieldIndex];
      Inc(FieldIndex);

      if (FieldIndex = FieldCount) then
        FieldIndex := 0;

      if (F.Tag = Tag) then
      begin
        { Found field. Most of the time a field is found on the first try. }
        Field := F;
        Break;
      end;
    end;

    if Assigned(Field) then
      Field.DeserializeProc(AReader, ARecord, Tag, Field.Offset, Field.Param)
    else
    begin
      { Field not found. Use WireType to skip field }
      WireType := C and $07;
      case WireType of
        WIRE_TYPE_VARINT:
          AReader.ReadVarUInt64;

        WIRE_TYPE_64BIT:
          AReader.Skip(8);

        WIRE_TYPE_VARIABLE_SIZE:
          AReader.Skip(AReader.ReadVarUInt);

        WIRE_TYPE_32BIT:
          AReader.Skip(4);
      else
        raise EgoSerializationError.Create('Unsupported wire type in protocol buffer');
      end;
    end;
  end;
end;

destructor TgoProtocolBuffer.TRecordTypeInfo.Destroy;
{$IFNDEF NEXTGEN}
var
  Field: TFieldTypeInfo;
{$ENDIF}
begin
  {$IFNDEF NEXTGEN}
  for Field in FFields do
    Field.Free;
  {$ENDIF}
  inherited;
end;

procedure TgoProtocolBuffer.TRecordTypeInfo.Serialize(const AWriter: TWriter;
  const ARecord: Pointer);
var
  I: Integer;
  Field: TFieldTypeInfo;
begin
  { Don't use for..in here because we want top performance }
  for I := 0 to Length(FFields) - 1 do
  begin
    Field := FFields[I];
    Field.SerializeProc(AWriter, ARecord, Field.Tag, Field.Offset, Field.Param);
  end;
end;

{ TgoProtocolBuffer.TArrayTypeInfo }

constructor TgoProtocolBuffer.TArrayTypeInfo.Create(const ATypeInfo: PTypeInfo;
  const ASize: Integer; const AElementType: PTypeInfo; const AElementSize: Integer;
  const AElementInfo: TBaseTypeInfo; const AElementSerializeProc: TSerializeProc;
  const AElementDeserializeProc: TDeserializeProc; const AElementParam: TObject);
begin
  inherited Create(ATypeInfo, ASize);
  FElementType := AElementType;
  FElementSize := AElementSize;
  FElementInfo := AElementInfo;
  FElementSerializeProc := AElementSerializeProc;
  FElementDeserializeProc := AElementDeserializeProc;
  FElementParam := AElementParam;
end;

end.

