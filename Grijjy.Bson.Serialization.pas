unit Grijjy.Bson.Serialization;
(*< Serializing Delphi records and objects to JSON and BSON format (or to
  TgoBsonDocument values).

@bold(Quick Start)

  <source>
  type
    TOrderDetail = record
    public
      Product: String;
      Quantity: Integer;
    end;

    TOrder = record
    public
      Customer: String;
      OrderDetails: TArray<<TOrderDetail>;
    end;

  procedure TestSerialization;
  var
    Order, Rehydrated: TOrder;
    Json: String;
  begin
    Order.Customer := 'John';

    SetLength(Order.OrderDetails, 2);
    Order.OrderDetails[0].Product := 'Pen';
    Order.OrderDetails[0].Quantity := 1;
    Order.OrderDetails[1].Product := 'Ruler';
    Order.OrderDetails[1].Quantity := 2;

    { Serialize Order record to JSON: }
    TgoBsonSerializer.Serialize(Order, Json);
    WriteLn(Json); // Outputs:
    // { "Customer" : "John",
    //   "OrderDetails" : [
    //     { "Product" : "Pen", "Quantity" : 1 },
    //     { "Product" : "Ruler", "Quantity" : 2 }
    //   ]
    // }

    { Deserialize JSON to Order record: }
    TgoBsonSerializer.Deserialize(Json, Rehydrated);
    { Rehydrated will have the same values as Order }
  end;
  </source>

@bold(Features)

The serialization engine supports the following features:
* You can serialize records and classes to JSON, BSON and TgoBsonDocument.
* You can also serialize dynamic arrays to JSON (but not to BSON and
  TgoBsonDocument).
* By default, all public fields and public and published read/write properties
  are serialized. Private and protected fields and properties are never
  serialized.
* Fields can be of type boolean, integer (all sizes and flavors), floating-point
  (Single and Double), WideChar, UnicodeString, TDateTime, TGUID,
  TgoObjectId and TBytes (for binary data).
* Fields can also be of an enumerated type, as long as that type does not
  have any explicitly declared values (since Delphi provides no RTTI for those).
* Likewise, a set of an enumerated type is also supported.
* Furthermore, a field can also be of a serializable record or class type, or a
  dynamic array of a serializable type.
* You can customize some behavior and output using attributes.

@bold(Representations)

By default, the serialization engine serializes fields and properties
(collecively called "members" from here onward) as their native types. That is,
integers are serialized as integers and strings are serialized as strings.
However, you can use the <tt>BsonRepresentation</tt> attribute to change the way
a member is serialized to JSON:

  <source>
  type
    TColor = (Red, Green, Blue);

  type
    TOrderDetail = record
    public
      Color: TColor;

      [BsonRepresentation(TgoBsonRepresentation.String)]
      ColorAsString: TColor;
    end;
  </source>

This serializes the Color member as a integer (which is the default
serialization type for enums), but serializes the ColorAsString member as a
string (using the name of the enum, eg "Red", "Green" or "Blue"). Not all types
can be serialized as other types. Below is a list of the types that can be
serialized as another type, and the conversion that will take place.

Boolean, can be serialized as:
* Boolean (default)
* Int32, Int64, Double (False=0, True=1)
* String (False="false", True="true")

Integer types:
* Int32, Int64 (default)
* Double
* String (IntToStr-conversion)

Enumerated types:
* Int32 (default, ordinal value)
* Int64 (ordinal value)
* String (name of the enum value)

Set types:
* Int32, Int64 (default, stored as a bitmask)
* String (comma-separated list of elements, without any (square) brackets)

Floating point types:
* Double (default)
* Int32, Int64 (truncated version)
* String (FloatToStr-conversion, in US format)

TDateTime:
* DateTime (default)
* Int64 (number of UTC ticks since midnight 1/1/0001, using 10,000 ticks per
  millisecond)
* String (DateToISO8601-conversion)
* Document (a document with two elements: TimeStamp serialized as a DateTime
  value, and Ticks serialized as the number of ticks since midnight 1/1/0001).
  For example:
    <tt>{ "DateTime" : ISODate("2016-05-01T15:28:57.784Z"),
          "Ticks" : NumberLong("635977133377840000") }</tt>

String:
* String (default)
* Symbol
* ObjectId (if the string is a valid TgoObjectId)

WideChar:
* Int32 (default, ordinal value)
* Int64 (ordinal value)
* String (single-character string)

TGUID:
* Binary (default)
* String (without curly braces)

TgoObjectId:
* TgoObjectId (default)
* String (string value of ObjectId)

TBytes:
* Binary (default)
* String (hex string, using 2 hex digits per byte)
* Array (a regular JSON array of bytes)

Note that for array members, the BsonRepresentation attribute applies to the
element types, not to the array itself:

  <source>
  type
    TColor = (Red, Green, Blue);

  type
    TMyColors = record
    public
      [BsonRepresentation(TgoBsonRepresentation.String)]
      Colors: TArray<<TColor>;
    end;
  </source>

This will serialize each color as a string (not the entire array as a string).

@bold(Handling Extra Elements)

When a JSON/BSON stream is deserialized, the name of each element is used to look
up a matching member in the record or class. Normally, if no matching member is
found, the element is ignored. This also means that when the record or class is
rendered back to JSON/BSON, those extra exlements will not exist and may be lost
forever.

You can also treat extra members in the JSON/BSON stream as an error condition.
In that case, an exception will be raised when extra elements are found. To
enable this error, use the <tt>BsonErrorOnExtraElements</tt> attribute at the
record or class level:

  <source>
    [BsonErrorOnExtraElements]
    TOrderDetail = record
    public
      ...
    end;
  </source>

@bold(Member Customization)

Normally, read-only properties are not serialized (unless the property is of a
class type, and the object property has already been created). If you want to
serialize read-only properties, you can mark them with a <tt>BsonElement</tt>
attribute:

  <source>
    TOrder = class
    public
      [BsonElement]
      property TotalAmount: Double read GetTotalAmount;
    end;
  </source>

Of course, read-only properties are never deserialized.

Also, you may wish to serialize a member using a different name than the member
name. A common use for this is if you want to serialize using a C-style name
(lower case with underscores) but you would like the member to have a Pascal-style
name (with camel caps). Another situation where you may want to use this is if
the serialization name includes a character that is invalid in a Delphi
identifier. You can use the <tt>BsonElement</tt> attribute to provide the
serialization name:

  <source>
    TOrder = record
    public
      [BsonElement('customer_name')]
      CustomerName: String;

      [BsonElement('$id')]
      Id: TgoObjectId;
    end;
  </source>

You may also choose to ignore a public member when serializing using the
<tt>BsonIgnore</tt> attribute:

  <source>
    TOrder = record
    public
      CustomerName: String;

      [BsonIgnore]
      CustomerAge: Integer;
    end;
  </source>

This will only serialize the CustomerName member. This would be the same as
making the CustomerAge field private or protected, with the difference that the
CustomAge field is still accessible in code outside of the TOrder class.

You can also ignore a field only when it has a default value, using the
<tt>BsonIgnoreIfDefault</tt> attribute:

  <source>
    TOrder = record
    public
      [BsonIgnoreIfDefault]
      CustomerName: String;
    end;
  </source>

This will only serialize the customer name if it is not an empty string. For
other types the default value will be 0, False, [] etc. For Boolean, integral
and String types, you can specify the default value using the
<tt>BsonDefaultValue</tt> attribute:

  <source>
    TOrder = record
    public
      [BsonIgnoreIfDefault]
      [BsonDefaultValue('John Smith')]
      CustomerName: String;
    end;
  </source>

This will only serialize the customer name if it isn't 'John Smith'.

@bold(Note): an exception will be raised if you apply the
<tt>BsonDefaultValue</tt> attribute to a member that is not of a Boolean,
integral or String type.

@bold(Note): the <tt>BsonIgnoreIfDefault</tt> attribute can be used on all types
except record types.

@bold(Using Records)

The easiest way to serialize to/from JSON/BSON is by declaring record types as
shown above.

When a record is deserialized, all its values will be cleared first. This
assures that no values will be left uninitialized if certain members are not
deserialized.

If you want to customize the initialization behavior, then you can add a method
called <tt>Initialize</tt> without parameters. If such a method exists, then it
is called instead of clearing all fields:

  <source>
    TOrder = record
    public
      // This method gets called before deserializing a TOrder
      procedure Initialize;
    end;
  </source>

@bold(Using Classes)

Serialization is easiest and most efficient when used with record types. You can
also serialize objects (class instances), but need to be aware of a different
behavior.

When you deserialize the object, and the object you pass has a value of nil,
then a new instance will be created. You are responsible for releasing the
instance at some later point:

  <source>
  type
    TOrder = class
    public
      Customer: String;
    end;

  procedure TestDeserialization;
  var
    Order: TOrder;
  begin
    Order := nil;
    TgoBsonSerializer.Deserialize('{ "Customer" : "John" }', Order);
  end;
  </source>

This will create a new TOrder instance and return it in the Order parameter.
The TOrder instance is created by calling a parameterless constructor. If the
TOrder class has constructor without parameters, then that constructor will be
called. Otherwise, a parameterless constructor of the ancestor class will be
used. If the ancestor class also doesn't have a parameterless constructor, then
we keep going up one ancestor in the chain, until TObject is reached, which
always has a parameterless constructor.

If you pass a non-nil value to Deserialize, then the existing object will be
updated and no new instance will be created.

When deserializing a field or property of a class type, the behavior depends on
whether the member is already assigned.

@bold(Deserializing Assigned object-properties)

Usually, it is best to make sure that the member is always assigned, by creating
it in the constructor and destroying it in the destructor:

  <source>
  type
    TOrderDetail = class
    ...
    end;

    TOrder = class
    private
      FCustomer: String;
      FDetail: TOrderDetail;
    public
      constructor Create;
      destructor Destroy; override;

      property Customer: String read FCustomer write FCustomer;
      property Detail: TOrderDetail read FDetail; // Read-only
    end;

    constructor TOrder.Create;
    begin
      inherited;
      FDetail := TOrderDetail.Create;
    end;

    destructor TOrder.Destroy;
    begin
      FDetail.Free;
      inherited;
    end;
  </source>

This is a very common design pattern when using composition. Properties that are
of a class type (like Detail in this example) are usually read-only.

When deserializing the TOrder.Detail property in this example, its members are
deserialized as usual. Even though the Detail property is read-only, it will
still be deserialized (other read-only properties are usually ignored).

@bold(Deserializing Non-Assigned object-properties)

If the member is not assigned, it is only created and assigned if it is a
read/write property (or field):

  <source>
  type
    TOrderDetail = class
    ...
    end;

    TOrder = class
    private
      FCustomer: String;
      FDetail: TOrderDetail;
    public
      property Customer: String read FCustomer write FCustomer;
      property Detail: TOrderDetail read FDetail write FDetail; // Read/write
    end;
  </source>

In this case, when deserializing the Detail property, it will be created (using
a parameterless constructor) and assigned to Detail. You need to make sure
though that the Detail property will be destroyed at some point. You could make
the Order class the owner and have it destroy the property in the destructor.

This design pattern is less common and not recommended. The recommended approach
is to always make sure the Detail property is assigned (and read-only), as
mentioned previously.

@bold(Polymorphism)

A complication that arises when serializing classes (instead of records) it that
they may be part of a class hierarchy:

  <source>
  type
    TAnimal = class
    public
      Weight: Double;
    end;

    TDog = class(TAnimal)
    public
      FurColor: String;
    end;
  </source>

All animals have a weight, but only dogs have fur. When serializing a TDog, the
output is as expected:

  <source>
  var
    Dog: TDog;
    Json: String;
  begin
    Dog.Weight := 30;
    Dog.FurColor := 'Blond';
    TgoBsonSerializer.Serialize(Dog, Json); // Result:
    // { "Weight" : 30.0, "FurColor" : "Blond" }
  end;
  </source>

However, output is different when a TDog is serialized as a TAnimal:

  <source>
  var
    Dog: TDog;
    Animal, Rehydrated: TAnimal;
    Json: String;
  begin
    Dog.Weight := 30;
    Dog.FurColor := 'Blond';
    Animal := Dog;
    TgoBsonSerializer.Serialize(Animal, Json); // Result:
    // { "_t" : "TDog", "Weight" : 30.0, "FurColor" : "Blond" }

    TgoBsonSerializer.Deserialize(Json, Rehydrated);
    // This will actually create a TDog instance (instead of TAnimal)
  end;
  </source>

In this case, an extra "_t" element is added (called a Discriminator) that
specifies the actual type that is serialized. This way, when you deserialize a
TAnimal, and the JSON/BSON contains a discriminator, it knows what actual type
of class to instantiate.

However, this only works if the serialization engine "knows" about the TDog
type. You have to let the engine know what kind of sub classes can be expected
when deserializing. You do this by calling <tt>RegisterSubClass(es)</tt>:

  <source>
  TgoBsonSerializer.RegisterSubClass(TDog);
  </source>

Note that this is only needed if you plan to deserialize dogs using type
TAnimal. If you always serialize and deserialize dogs as TDog, then you don't
need to do this.

You can choose to always serialize a descriminator, even if not strictly
necessary, by adding a <tt>BsonDiscriminator</tt> attribute to the class:

  <source>
  type
    [BsonDiscriminator(True)]
    TAnimal = class
    public
      Weight: Double;
    end;
  </source>

The True argument indicates that the descriminator is required. You can also
specify a custom discriminator name using the same attribute:

  <source>
  type
    [BsonDiscriminator('animal', True)]
    TAnimal = class
    public
      Weight: Double;
    end;
  </source>

This will serialize the descriminator as <tt>{ "_t" : "animal" }</tt> instead of
using the Delphi type name <tt>{ "_t" : "TAnimal" }</tt>. In this case, the
second parameter (True) is optional. If not specified, the descriminator is not
required.

@bold(Custom Serialization)

Is some situations, you may want to customize the way a certain type is
(de)serialized entirely. For example, the TgoAlias type in Grijjy.Protocol.Types
is a record consisting of a prefix and a value. But when serializing records of
this type, you always want to serialize them as a single string containing both
the prefix and value.

To do this, you have to create and register a custom serializer for this type.
You can find an example of a custom serializer for TgoAlias in the
Grijjy.Protocol.Types unit.

First, you create a class derived from TgoBsonSerializer.TCustomSerializer. You
only need to override its Serialize and Deserialize methods. In those methods
you perform the type-specific (de)serialization. Both methods have an untyped
AValue parameter that you must cast to the actual type (TgoAlias in this
example):

<source>
type
  TgoAliasSerializer = class(TgoBsonSerializer.TCustomSerializer)
  public
    procedure Serialize(const AValue; const AWriter: IgoBsonBaseWriter); override;
    procedure Deserialize(const AReader: IgoBsonBaseReader; out AValue); override;
  end;

procedure TgoAliasSerializer.Deserialize(const AReader: IgoBsonBaseReader;
  out AValue);
var
  Value: TgoAlias absolute AValue;
begin
  // TgoAlias has in implicit conversion operator to convert from a String
  Value := AReader.ReadString;
end;

procedure TgoAliasSerializer.Serialize(const AValue;
  const AWriter: IgoBsonBaseWriter);
var
  Value: TgoAlias absolute AValue;
begin
  // TgoAlias has in implicit conversion operator to convert to a String
  AWriter.WriteString(Value);
end;
</source>

Next, you need to register the custom serializer for the type. For our example:

<source>
TgoBsonSerializer.RegisterCustomSerializer<TgoAlias>(TgoAliasSerializer);
</source>

@bold(Note) that custom serializers currently only work for record types.

@bold(Notes)

* The Serialize and Deserialize methods will raise an exception if the type is
  not serializable, or if the JSON/BSON to deserialize is invalid. To prevent
  exceptions, you can use the TrySerialize and TryDeserialize methods instead.
  These return False if (de)serialization failed.
* Members of type TDateTime are expected to be un UTC format. No attempt is made
  to convert from local time to UTC and vice versa. *)

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.SysUtils,
  System.SyncObjs,
  System.TypInfo,
  System.Rtti,
  System.Generics.Collections,
  Grijjy.Collections,
  Grijjy.Bson,
  Grijjy.Bson.IO;

type
  { Type of exception that is raised on serialization errors }
  EgoBsonSerializerError = class(Exception);

type
  { Possible representation types for use with BsonRepresentationAttribute }
  TgoBsonRepresentation = (Default, Boolean, Int32, Int64, Double, &String,
    DateTime, Document, Binary, ObjectId, Symbol, &Array);

type
  { Used internally by BsonDefaultValueAttribute to specify a default value }
  TgoBsonDefaultValue = record
  {$REGION 'Internal Declarations'}
  private
    constructor Create(const AValue: Boolean); overload;
    constructor Create(const AValue: Int32); overload;
    constructor Create(const AValue: Int64); overload;
    constructor Create(const AValue: String); overload;
  private
    FAsString: String;
    case FRepresentation: TgoBsonRepresentation of
      TgoBsonRepresentation.Boolean: (FAsBoolean: Boolean);
      TgoBsonRepresentation.Int32: (FAsInt32: Int32);
      TgoBsonRepresentation.Int64: (FAsInt64: Int64);
  {$ENDREGION 'Internal Declarations'}
  end;

type
  { Attribute used to force serializing read-only properties and to modify the
    name of an element for serialization }
  BsonElementAttribute = class(TCustomAttribute)
  {$REGION 'Internal Declarations'}
  private
    FName: String;
  {$ENDREGION 'Internal Declarations'}
  public
    constructor Create(const AName: String = '');

    { The name the element is serialized as }
    property Name: String read FName;
  end;

type
  { Apply this attribute to elements you want to ignore for serialization }
  BsonIgnoreAttribute = class(TCustomAttribute)
  end;

type
  { Apply this attribute to elements you want to ignore if they have the default
    value. Can be used in combination with BsonDefaultValueAttribute. }
  BsonIgnoreIfDefaultAttribute = class(TCustomAttribute)
  end;

type
  { Specifies the default value for an element. Mostly used in combination with
    BsonIgnoreIfDefaultAttribute. }
  BsonDefaultValueAttribute = class(TCustomAttribute)
  {$REGION 'Internal Declarations'}
  private
    FDefaultValue: TgoBsonDefaultValue;
  {$ENDREGION 'Internal Declarations'}
  public
    constructor Create(const ADefaultValue: Boolean); overload;
    constructor Create(const ADefaultValue: Int32); overload;
    constructor Create(const ADefaultValue: Int64); overload;
    constructor Create(const ADefaultValue: String); overload;

    { The default value of the element }
    property DefaultValue: TgoBsonDefaultValue read FDefaultValue;
  end;

type
  { Changes the representation type of an element when serializing. For example,
    this can be used to serialize Integer elements as Strings. }
  BsonRepresentationAttribute = class(TCustomAttribute)
  {$REGION 'Internal Declarations'}
  private
    FRepresentation: TgoBsonRepresentation;
  {$ENDREGION 'Internal Declarations'}
  public
    constructor Create(const ARepresentation: TgoBsonRepresentation);

    { The type to use to serialize the element }
    property Representation: TgoBsonRepresentation read FRepresentation;
  end;

type
  { Applies a discriminator to a class. See the unit documentation for details }
  BsonDiscriminatorAttribute = class(TCustomAttribute)
  {$REGION 'Internal Declarations'}
  private
    FDiscriminator: String;
    FRequired: Boolean;
  {$ENDREGION 'Internal Declarations'}
  public
    constructor Create(const ADiscriminator: String;
      const ARequired: Boolean = False); overload;
    constructor Create(const ARequired: Boolean); overload;

    { The discriminator to use for the class }
    property Discriminator: String read FDiscriminator;

    { Whether the discriminator is always serialized or not }
    property Required: Boolean read FRequired;
  end;

type
  { Apply this attribute to a record or class if you want to raise an exception
    when deserializing elements that are not part of the record or class. }
  BsonErrorOnExtraElementsAttribute = class(TCustomAttribute)
  end;

type
  { Static class for serializing and deserializing to JSON and BSON format }
  TgoBsonSerializer = record
  {$REGION 'Internal Declarations'}
  private type
    TSerializer = class abstract
    private
      FTypeInfo: PTypeInfo;
      FIsCustomSerializer: Boolean;
    private
      function GetTypeKind: TTypeKind; inline;
    public
      constructor Create(const ATypeInfo: PTypeInfo);
      procedure Setup; virtual;

      property TypeInfo: PTypeInfo read FTypeInfo;
      property TypeKind: TTypeKind read GetTypeKind;
      property IsCustomSerializer: Boolean read FIsCustomSerializer;
    end;
  private type
    TInfo = class abstract
    private
      FName: String;
      FType: PTypeInfo;
      [unsafe] FSerializer: TSerializer;
      FRepresentation: TgoBsonRepresentation;
      FDefaultValue: TgoBsonDefaultValue;
      FHasDefaultValue: Boolean;
      FIgnoreIfDefault: Boolean;
      FIsProperty: Boolean;
    public
      property Name: String read FName;
      property &Type: PTypeInfo read FType;
      property Representation: TgoBsonRepresentation read FRepresentation;
      property IsProperty: Boolean read FIsProperty;
      property DefaultValue: TgoBsonDefaultValue read FDefaultValue;
      property IgnoreIfDefault: Boolean read FIgnoreIfDefault;
      property Serializer: TSerializer read FSerializer;
    end;
  private type
    TVarInfo = class;

    TSerializeVarProc = procedure(const AVar: TVarInfo;
      const AAddress: Pointer; const AWriter: IgoBsonBaseWriter);

    TDeserializeVarProc = procedure(const AVar: TVarInfo;
      const AAddress: Pointer; const AReader: IgoBsonBaseReader);

    TVarInfo = class(TInfo)
    private
      FSerializeProc: TSerializeVarProc;
      FDeserializeProc: TDeserializeVarProc;
    private
      procedure GetSerializationProcs(const AType: PTypeInfo);
    private
      class procedure SerializeBoolean(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeBoolean(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeInt8(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeInt8(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeUInt8(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeUInt8(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeInt16(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeInt16(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeUInt16(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeUInt16(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeInt32(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeInt32(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeUInt32(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeUInt32(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeInt64(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeInt64(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeUInt64(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeUInt64(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeSingle(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeSingle(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeDouble(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeDouble(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeChar(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeChar(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeString(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeString(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeDateTime(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeDateTime(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeGuid(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeGuid(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeObjectId(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeObjectId(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeTBytes(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeTBytes(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeEnum8(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeEnum8(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeEnum16(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeEnum16(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeEnum32(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeEnum32(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeSet8(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeSet8(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeSet16(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeSet16(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeSet32(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeSet32(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeArray(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeArray(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeRecord(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeRecord(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeObject(const AVar: TVarInfo;
        const AAddress: Pointer; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeObject(const AVar: TVarInfo;
        const AAddress: Pointer; const AReader: IgoBsonBaseReader); static;
    public
      constructor Create(const AType: PTypeInfo);

      property SerializeProc: TSerializeVarProc read FSerializeProc;
      property DeserializeProc: TDeserializeVarProc read FDeserializeProc;
    end;
  private type
    TFieldInfo = class(TVarInfo)
    private
      FOffset: Integer;
    public
      constructor Create(const AStructType: TRttiType; const AField: TRttiField;
        const AAttrs: TArray<TCustomAttribute>);

      property Offset: Integer read FOffset;
    end;
  private type
    TPropertyInfo = class;

    TSerializePropertyProc = procedure(const AProp: TPropertyInfo;
      const AInstance: TObject; const AWriter: IgoBsonBaseWriter);

    TDeserializePropertyProc = procedure(const AProp: TPropertyInfo;
      const AInstance: TObject; const AReader: IgoBsonBaseReader);

    TPropertyInfo = class(TInfo)
    private
      FSerializeProc: TSerializePropertyProc;
      FDeserializeProc: TDeserializePropertyProc;
      FInfo: PPropInfo;
    private
      procedure GetSerializationProcs(const AType: PTypeInfo);
    private
      class procedure SerializeBoolean(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeBoolean(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeInt32(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeInt32(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeUInt32(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeUInt32(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeInt64(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeInt64(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeUInt64(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeUInt64(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeDouble(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeDouble(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeChar(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeChar(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeString(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeString(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeDateTime(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeDateTime(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeGuid(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeGuid(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeObjectId(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeObjectId(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeTBytes(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeTBytes(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeEnum(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeEnum(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeSet(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeSet(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeArray(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeArray(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeRecord(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeRecord(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
      class procedure SerializeObject(const AProp: TPropertyInfo;
        const AInstance: TObject; const AWriter: IgoBsonBaseWriter); static;
      class procedure DeserializeObject(const AProp: TPropertyInfo;
        const AInstance: TObject; const AReader: IgoBsonBaseReader); static;
    public
      constructor Create(const AStructType: TRttiType; const AProp: TRttiProperty);

      property SerializeProc: TSerializePropertyProc read FSerializeProc;
      property DeserializeProc: TDeserializePropertyProc read FDeserializeProc;
      property Info: PPropInfo read FInfo;
    end;
  private type
    TStructSerializer = class abstract(TSerializer)
    private
      FFields: TArray<TFieldInfo>;
      FInfoByName: TObjectDictionary<String, TInfo>;
      FErrorOnExtraElements: Boolean;
    private
      procedure MapFields(const AStructType: TRttiType);
    private
      procedure SerializeFields(const ABaseAddress: PByte;
        const AWriter: IgoBsonBaseWriter);
    protected
      procedure Initialize(const AStructType: TRttiType); virtual;
    public
      destructor Destroy; override;

      procedure Setup; override;
    end;
  private type
    TInitializeRecordProc = procedure(const ASelf: Pointer);

    TRecordSerializer = class(TStructSerializer)
    private
      FInitializeProc: TInitializeRecordProc;
    private
      procedure MapInitialize(const AStructType: TRttiType);
    protected
      procedure Initialize(const AStructType: TRttiType); override;
    public
      procedure Serialize(const ABaseAddress: PByte; const AWriter: IgoBsonBaseWriter);
      procedure Deserialize(const ABaseAddress: PByte; const AReader: IgoBsonBaseReader);

      property InitializeProc: TInitializeRecordProc read FInitializeProc;
    end;
  private type
    TConstructorProc = function(const AClass: TClass; const AAlloc: Shortint): TObject;

    TClassSerializer = class(TStructSerializer)
    private const
      NAME_DISCRIMINATOR = '_t';
    private
      {$IFDEF MSWINDOWS}
      FConstructorProc: TConstructorProc;
      {$ELSE}
      FConstructorAddress: Pointer;
      FConstructorArgs: TArray<TValue>;
      {$ENDIF}
      FClass: TClass;
      FProperties: TArray<TPropertyInfo>;
      FDiscriminator: String;
      FDiscriminatorRequired: Boolean;
    private
      procedure MapConstructor(const AStructType: TRttiType);
      procedure MapProperties(const AStructType: TRttiType);
      procedure MapAttributes(const AStructType: TRttiType);
      procedure SerializeProperties(const AInstance: TObject;
        const AWriter: IgoBsonBaseWriter);
      function ShouldSerializeDiscriminator(const ANominalType: PTypeInfo): Boolean; inline;
      procedure SerializeDiscriminator(const AWriter: IgoBsonBaseWriter);
      function GetActualType(const AReader: IgoBsonBaseReader;
        const ANominalType: PTypeInfo): PTypeInfo;
    protected
      procedure Initialize(const AStructType: TRttiType); override;
    public
      procedure Serialize(const AInstance: TObject;
        const AWriter: IgoBsonBaseWriter; const ANominalType: PTypeInfo);
      procedure Deserialize(var AInstance: TObject; const AReader: IgoBsonBaseReader);
    end;
  private type
    TArraySerializer = class(TSerializer)
    private
      FElementSize: Integer;
      FElementInfo: TVarInfo;
    public
      constructor Create(const ATypeInfo: PTypeInfo);
      destructor Destroy; override;

      procedure Serialize(const AArray: Pointer; const AWriter: IgoBsonBaseWriter;
        const AElementRepresentation: TgoBsonRepresentation);
      function Deserialize(const AReader: IgoBsonBaseReader): Pointer;
    end;
  private class var
    FRegisteredSerializers: TObjectDictionary<PTypeInfo, TSerializer>;
    FDiscriminatedTypes: TgoSet<PTypeInfo>;
    FDiscriminatedTypesByName: TDictionary<String, PTypeInfo>;
    FLock: TCriticalSection;
  private
    class function GetOrAddSerializer<T>: TSerializer; overload; static;
    class function GetOrAddSerializer(const ATypeInfo: PTypeInfo): TSerializer; overload; static;
    class procedure CheckBooleanRepresentation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckIntegerRepresentation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckInt64Representation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckFloatRepresentation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckCharRepresentation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckStringRepresentation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckDateTimeRepresentation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckGuidRepresentation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckObjectIdRepresentation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckTBytesRepresentation(const ARepresentation: TgoBsonRepresentation); static;
    class procedure CheckEnumRepresentation(const ARepresentation: TgoBsonRepresentation); static;
  private
    class procedure SerializeBoolean(const AInfo: TInfo;
      const AValue: Boolean; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeBoolean(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): Boolean; static;
    class procedure SerializeInt32(const AInfo: TInfo;
      const AValue: Int32; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeInt32(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): Int32; static;
    class procedure SerializeUInt32(const AInfo: TInfo;
      const AValue: UInt32; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeUInt32(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): UInt32; static;
    class procedure SerializeInt64(const AInfo: TInfo;
      const AValue: Int64; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeInt64(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): Int64; static;
    class procedure SerializeUInt64(const AInfo: TInfo;
      const AValue: UInt64; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeUInt64(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): UInt64; static;
    class procedure SerializeDouble(const AInfo: TInfo;
      const AValue: Double; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeDouble(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): Double; static;
    class procedure SerializeChar(const AInfo: TInfo;
      const AValue: Char; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeChar(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): Char; static;
    class procedure SerializeString(const AInfo: TInfo;
      const AValue: String; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeString(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): String; static;
    class procedure SerializeDateTime(const AInfo: TInfo;
      const AValue: TDateTime; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeDateTime(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): TDateTime; static;
    class procedure SerializeGuid(const AInfo: TInfo;
      const AValue: TGUID; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeGuid(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): TGUID; static;
    class procedure SerializeObjectId(const AInfo: TInfo;
      const AValue: TgoObjectId; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeObjectId(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): TgoObjectId; static;
    class procedure SerializeTBytes(const AInfo: TInfo;
      const AValue: TBytes; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeTBytes(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): TBytes; static;
    class procedure SerializeEnum(const AInfo: TInfo;
      const AValue: UInt32; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeEnum(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): UInt32; static;
    class procedure SerializeSet(const AInfo: TInfo;
      const AValue: UInt32; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeSet(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): UInt32; static;
    class procedure SerializeArray(const AInfo: TInfo;
      const AValue: Pointer; const AWriter: IgoBsonBaseWriter); static;
    class function DeserializeArray(const AInfo: TInfo;
      const AReader: IgoBsonBaseReader): Pointer; static;
    class procedure SerializeRecord(const AInfo: TInfo;
      const AValue: Pointer; const AWriter: IgoBsonBaseWriter); static;
    class procedure DeserializeRecord(const AInfo: TInfo;
      const AValue: Pointer; const AReader: IgoBsonBaseReader); static;
    class procedure SerializeObject(const AInfo: TInfo;
      const AValue: TObject; const AWriter: IgoBsonBaseWriter); static;
    class procedure DeserializeObject(const AInfo: TInfo;
      var AValue: TObject; const AReader: IgoBsonBaseReader); static;
  public
    { @exclude }
    class constructor Create;
    { @exclude }
    class destructor Destroy;
  {$ENDREGION 'Internal Declarations'}
  public type
    TCustomSerializer = class abstract(TSerializer)
    public
      constructor Create(const ATypeInfo: PTypeInfo);

      procedure Serialize(const AValue; const AWriter: IgoBsonBaseWriter); virtual; abstract;
      procedure Deserialize(const AReader: IgoBsonBaseReader; out AValue); virtual; abstract;
    end;
    TCustomSerializerClass = class of TCustomSerializer;
  public
    { Serializes a value to JSON format.

      Parameters:
        AValue: the value to serialize. Must be a record, class or dynamic array.
        AJson: is set to the serialized JSON output.

      Raises:
        EgoBsonSerializerError if type T is not serializable }
    class procedure Serialize<T>(const AValue: T; out AJson: String); overload; inline; static;

    { Serializes a value to JSON format using custom output settings.

      Parameters:
        AValue: the value to serialize. Must be a record, class or dynamic array.
        ASettings: settings to use to customize the JSON output.
        AJson: is set to the serialized JSON output.

      Raises:
        EgoBsonSerializerError if type T is not serializable }
    class procedure Serialize<T>(const AValue: T; const ASettings: TgoJsonWriterSettings; out AJson: String); overload; inline; static;

    { Serializes a value to BSON format.

      Parameters:
        AValue: the value to serialize. Must be a record or class.
        ABson: is set to the serialized BSON output.

      Raises:
        EgoBsonSerializerError if type T is not serializable }
    class procedure Serialize<T>(const AValue: T; out ABson: TBytes); overload; inline; static;

    { Serializes a value to a BSON document.

      Parameters:
        AValue: the value to serialize. Must be a record or class.
        ADocument: is set to the serialized document.

      Raises:
        EgoBsonSerializerError if type T is not serializable }
    class procedure Serialize<T>(const AValue: T; out ADocument: TgoBsonDocument); overload; inline; static;

    { Serializes a value using a writer interface.

      Parameters:
        AValue: the value to serialize. Must be a record or class.
        AWriter: the writer to serialize to.

      Raises:
        EgoBsonSerializerError if type T is not serializable }
    class procedure Serialize<T>(const AValue: T; const AWriter: IgoBsonBaseWriter); overload; static;

    { Tries to serialize a value to JSON format.

      Parameters:
        AValue: the value to serialize. Must be a record, class or dynamic array.
        AJson: is set to the serialized JSON output, or an empty string if
          serialization failed.

      Returns:
        True on success, or False when type T is not serializable }
    class function TrySerialize<T>(const AValue: T; out AJson: String): Boolean; overload; inline; static;

    { Tries to serialize a value to JSON format using custom output settings.

      Parameters:
        AValue: the value to serialize. Must be a record, class or dynamic array.
        ASettings: settings to use to customize the JSON output.
        AJson: is set to the serialized JSON output, or an empty string if
          serialization failed.

      Returns:
        True on success, or False when type T is not serializable }
    class function TrySerialize<T>(const AValue: T; const ASettings: TgoJsonWriterSettings; out AJson: String): Boolean; overload; inline; static;

    { Tries to serialize a value to BSON format.

      Parameters:
        AValue: the value to serialize. Must be a record or class.
        ABson: is set to the serialized BSON output, or nil if serialization
          failed.

      Returns:
        True on success, or False when type T is not serializable }
    class function TrySerialize<T>(const AValue: T; out ABson: TBytes): Boolean; overload; inline; static;

    { Tries to serialize a value to a BSON document.

      Parameters:
        AValue: the value to serialize. Must be a record or class.
        ADocument: is set to the serialized document, or an empty document if
          serialization failed.

      Returns:
        True on success, or False when type T is not serializable }
    class function TrySerialize<T>(const AValue: T; out ADocument: TgoBsonDocument): Boolean; overload; inline; static;

    { Tries to serialize a value using a writer interface.

      Parameters:
        AValue: the value to serialize. Must be a record or class.
        AWriter: the writer to serialize to.

      Returns:
        True on success, or False when type T is not serializable }
    class function TrySerialize<T>(const AValue: T; const AWriter: IgoBsonBaseWriter): Boolean; overload; static;

    { Deserializes data in JSON format.

      Parameters:
        AJson: the JSON string to deserialize.
        AValue: is set to the deserialized value. Must be a record, class or
          dynamic array. In case of a class, an instance of type T will be
          created if it is not already assigned.

      Raises:
        EgoBsonSerializerError if type T is not serializable or the JSON string
        is invalid. }
    class procedure Deserialize<T>(const AJson: String; var AValue: T); overload; inline; static;

    { Deserializes data in BSON format.

      Parameters:
        ABson: the BSON data to deserialize.
        AValue: is set to the deserialized value. Must be a record, class or
          dynamic array. In case of a class, an instance of type T will be
          created if it is not already assigned.

      Raises:
        EgoBsonSerializerError if type T is not serializable or the BSON data
        is invalid. }
    class procedure Deserialize<T>(const ABson: TBytes; var AValue: T); overload; inline; static;

    { Deserializes data in a BSON document.

      Parameters:
        ADocument: the document containing the data to deserialize.
        AValue: is set to the deserialized value. Must be a record, class or
          dynamic array. In case of a class, an instance of type T will be
          created if it is not already assigned.

      Raises:
        EgoBsonSerializerError if type T is not serializable. }
    class procedure Deserialize<T>(const ADocument: TgoBsonDocument; var AValue: T); overload; inline; static;

    { Deserializes data using a reader interface.

      Parameters:
        AReader: the reader to deserialize from
        AValue: is set to the deserialized value. Must be a record, class or
          dynamic array. In case of a class, an instance of type T will be
          created if it is not already assigned.

      Raises:
        EgoBsonSerializerError if type T is not serializable or the reader
        contains invalid data.. }
    class procedure Deserialize<T>(const AReader: IgoBsonBaseReader; var AValue: T); overload; static;

    { Tries to deserialize data in JSON format.

      Parameters:
        AJson: the JSON string to deserialize.
        AValue: is set to the deserialized value. Must be a record, class or
          dynamic array. In case of a class, an instance of type T will be
          created if it is not already assigned.

      Raises:
        True on success, or False when type T is not serializable or the JSON
        string is invalid. }
    class function TryDeserialize<T>(const AJson: String; var AValue: T): Boolean; overload; inline; static;

    { Tries to deserialize data in BSON format.

      Parameters:
        ABson: the BSON data to deserialize.
        AValue: is set to the deserialized value. Must be a record, class or
          dynamic array. In case of a class, an instance of type T will be
          created if it is not already assigned.

      Raises:
        True on success, or False when type T is not serializable or the BSON
        data is invalid. }
    class function TryDeserialize<T>(const ABson: TBytes; var AValue: T): Boolean; overload; inline; static;

    { Tries to deserialize data in a BSON document.

      Parameters:
        ADocument: the document containing the data to deserialize.
        AValue: is set to the deserialized value. Must be a record, class or
          dynamic array. In case of a class, an instance of type T will be
          created if it is not already assigned.

      Raises:
        True on success, or False when type T is not serializable. }
    class function TryDeserialize<T>(const ADocument: TgoBsonDocument; var AValue: T): Boolean; overload; inline; static;

    { Tries to deserialize data using a reader interface.

      Parameters:
        AReader: the reader to deserialize from
        AValue: is set to the deserialized value. Must be a record, class or
          dynamic array. In case of a class, an instance of type T will be
          created if it is not already assigned.

      Raises:
        True on success, or False when type T is not serializable or the reader
        contains invalid data. }
    class function TryDeserialize<T>(const AReader: IgoBsonBaseReader; var AValue: T): Boolean; overload; static;

    { Registers a known sub-class. See unit documentation for details.

      Parameters:
        ASubClass: the sub-class to register }
    class procedure RegisterSubClass(const ASubClass: TClass); static;

    { Registers an array  known sub-classes. See unit documentation for details.

      Parameters:
        ASubClasses: the sub-classes to register }
    class procedure RegisterSubClasses(const ASubClasses: array of TClass); static;

    { Registers a custom serializer for a specific type.
      See unit documentation for details.

      Parameters:
        T: the type for which to use the custom serializer.
        ASerializerClass: the serializer class to use to (de)serialize values
          of type T. }
    class procedure RegisterCustomSerializer<T: record>(const ASerializerClass: TCustomSerializerClass); overload; static;

    { Registers a custom serializer for a specific type.
      See unit documentation for details.

      Parameters:
        AForType: the type for which to use the custom serializer.
        ASerializerClass: the serializer class to use to (de)serialize values
          of type AForType. }
    class procedure RegisterCustomSerializer(const AForType: PTypeInfo; const ASerializerClass: TCustomSerializerClass); overload; static;
  end;

implementation

uses
  System.DateUtils,
  System.RTLConsts,
  {$IF Defined(IOS)}
  Macapi.CoreFoundation,
  {$ENDIF}
  Grijjy.SysUtils,
  Grijjy.DateUtils;

{ These should be in System.pas }

type
  PInt8 = ^Int8;
  PInt16 = ^Int16;
  PInt32 = ^Int32;

  PUInt8 = ^UInt8;
  PUInt16 = ^UInt16;
  PUInt32 = ^UInt32;

{ Dynamic array utilities. Mostly copied from the System unit }

type
  PDynArrayRec = ^TDynArrayRec;
  TDynArrayRec = packed record
  {$IFDEF CPU64BITS}
    _Padding: Integer; // Make 16 byte align for payload..
  {$ENDIF}
    RefCnt: Integer;
    Length: NativeInt;
  end;

function DynArrayRefCnt(const AArray: Pointer): Integer; inline;
begin
  Result := PDynArrayRec(PByte(AArray) - SizeOf(TDynArrayRec))^.RefCnt;
end;

procedure DynArrayRelease(const AArray: Pointer);
begin
  if Assigned(AArray) then
  begin
    if (DynArrayRefCnt(AArray) > 0) then
      AtomicDecrement(PDynArrayRec(PByte(AArray) - SizeOf(TDynArrayRec))^.RefCnt);
  end;
end;

{ Additions to System.TypInfo }

type
  PIntPtr = ^IntPtr;
  PBytes = ^TBytes;

function InsufficientRtti: Exception;
begin
  Result := EInsufficientRtti.CreateRes(@SInsufficientRtti);
end;

procedure CheckCodeAddress(code: Pointer);
begin
  if (code = nil) or (PPointer(code)^ = nil) then
    raise InsufficientRtti;
end;

function GetValueProp(const AInstance: TObject; const APropInfo: PPropInfo): TValue;
{ Mostly from function TRttiInstanceProperty.DoGetValue }
var
  Getter: Pointer;
  Code: Pointer;
  Args: TArray<TValue>;
begin
  Getter := APropInfo^.GetProc;
  if ((IntPtr(Getter) and PROPSLOT_MASK) = PROPSLOT_FIELD) then
  begin
    // Field
    TValue.Make(PByte(AInstance) + (IntPtr(Getter) and (not PROPSLOT_MASK)),
      APropInfo.PropType^, Result);
    Exit;
  end;

  if ((IntPtr(Getter) and PROPSLOT_MASK) = PROPSLOT_VIRTUAL) then
  begin
    // Virtual dispatch, but with offset, not slot
    Code := PPointer(PIntPtr(AInstance)^ + SmallInt(IntPtr(Getter)))^;
  end
  else
  begin
    // Static dispatch
    Code := Getter;
  end;

  CheckCodeAddress(Code);

  if (APropInfo.Index = Integer($80000000)) then
  begin
    // no index
    SetLength(Args, 1);
    Args[0] := AInstance;
    Result := Invoke(Code, Args, ccReg, APropInfo.PropType^, False); // not static
  end
  else
  begin
    SetLength(Args, 2);
    Args[0] := AInstance;
    Args[1] := APropInfo.Index;
    Result := Invoke(Code, Args, ccReg, APropInfo.PropType^, False); // not static
  end;
end;

procedure SetValueProp(const AInstance: TObject; const APropInfo: PPropInfo;
  const AValue: TValue);
{ Mostly from function TRttiInstanceProperty.DoSetValue }
var
  Setter: Pointer;
  Code: Pointer;
  Args: TArray<TValue>;
begin
  Setter := APropInfo^.SetProc;
  if ((IntPtr(Setter) and PROPSLOT_MASK) = PROPSLOT_FIELD) then
  begin
    // Field
    AValue.Cast(APropInfo.PropType^).ExtractRawData(
      PByte(AInstance) + (IntPtr(Setter) and (not PROPSLOT_MASK)));
    Exit;
  end;

  if ((IntPtr(Setter) and PROPSLOT_MASK) = PROPSLOT_VIRTUAL) then
  begin
    // Virtual dispatch, but with offset, not slot
    Code := PPointer(PIntPtr(AInstance)^ + SmallInt(IntPtr(Setter)))^;
  end
  else
  begin
    // Static dispatch
    Code := Setter;
  end;

  CheckCodeAddress(Code);

  if (APropInfo.Index = Integer($80000000)) then
  begin
    // no index
    SetLength(Args, 2);
    Args[0] := AInstance;
    Args[1] := AValue.Cast(APropInfo.PropType^);
    Invoke(Code, Args, ccReg, nil);
  end
  else
  begin
    SetLength(Args, 3);
    Args[0] := AInstance;
    Args[1] := APropInfo.Index;
    Args[2] := AValue.Cast(APropInfo.PropType^);
    Invoke(Code, Args, ccReg, nil);
  end;
end;

function SetToString(ATypeInfo: PTypeInfo; const AValue: Integer): String;
{ Custom version that adds a space after each comma }
var
  S: TIntegerSet;
  I: Integer;
begin
  Result := '';
  Integer(S) := AValue;
  ATypeInfo := GetTypeData(ATypeInfo)^.CompType^;
  for I := 0 to SizeOf(Integer) * 8 - 1 do
  begin
    if I in S then
    begin
      if (Result <> '') then
        Result := Result + ', ';
      Result := Result + GetEnumName(ATypeInfo, I);
    end;
  end;
end;

{ TgoBsonDefaultValue }

constructor TgoBsonDefaultValue.Create(const AValue: Int32);
begin
  FRepresentation := TgoBsonRepresentation.Int32;
  FAsInt32 := AValue;
end;

constructor TgoBsonDefaultValue.Create(const AValue: Boolean);
begin
  FRepresentation := TgoBsonRepresentation.Boolean;
  FAsBoolean := AValue;
end;

constructor TgoBsonDefaultValue.Create(const AValue: Int64);
begin
  FRepresentation := TgoBsonRepresentation.Int64;
  FAsInt64 := AValue;
end;

constructor TgoBsonDefaultValue.Create(const AValue: String);
begin
  FRepresentation := TgoBsonRepresentation.String;
  FAsString := AValue;
end;

{ BsonElementAttribute }

constructor BsonElementAttribute.Create(const AName: String);
begin
  inherited Create;
  FName := AName;
end;

{ BsonDefaultValueAttribute }

constructor BsonDefaultValueAttribute.Create(const ADefaultValue: Int32);
begin
  inherited Create;
  FDefaultValue := TgoBsonDefaultValue.Create(ADefaultValue);
end;

constructor BsonDefaultValueAttribute.Create(const ADefaultValue: Boolean);
begin
  inherited Create;
  FDefaultValue := TgoBsonDefaultValue.Create(ADefaultValue);
end;

constructor BsonDefaultValueAttribute.Create(const ADefaultValue: Int64);
begin
  inherited Create;
  FDefaultValue := TgoBsonDefaultValue.Create(ADefaultValue);
end;

constructor BsonDefaultValueAttribute.Create(const ADefaultValue: String);
begin
  inherited Create;
  FDefaultValue := TgoBsonDefaultValue.Create(ADefaultValue);
end;

{ BsonRepresentationAttribute }

constructor BsonRepresentationAttribute.Create(
  const ARepresentation: TgoBsonRepresentation);
begin
  inherited Create;
  FRepresentation := ARepresentation;
end;

{ BsonDiscriminatorAttribute }

constructor BsonDiscriminatorAttribute.Create(const ARequired: Boolean);
begin
  inherited Create;
  FRequired := ARequired;
end;

constructor BsonDiscriminatorAttribute.Create(const ADiscriminator: String;
  const ARequired: Boolean);
begin
  inherited Create;
  FDiscriminator := ADiscriminator;
  FRequired := ARequired;
end;

{ TgoBsonSerializer }

class procedure TgoBsonSerializer.CheckBooleanRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.Boolean,
    TgoBsonRepresentation.Double, TgoBsonRepresentation.Int32,
    TgoBsonRepresentation.Int64, TgoBsonRepresentation.String]))
  then
    raise EgoBsonSerializerError.Create('Invalid Boolean representation');
end;

class procedure TgoBsonSerializer.CheckCharRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.String,
    TgoBsonRepresentation.Int32, TgoBsonRepresentation.Int64]))
  then
    raise EgoBsonSerializerError.Create('Invalid Char representation');
end;

class procedure TgoBsonSerializer.CheckDateTimeRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.DateTime,
    TgoBsonRepresentation.Document, TgoBsonRepresentation.Int64,
    TgoBsonRepresentation.String]))
  then
    raise EgoBsonSerializerError.Create('Invalid date/time representation');
end;

class procedure TgoBsonSerializer.CheckEnumRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.Int32,
    TgoBsonRepresentation.Int64, TgoBsonRepresentation.String]))
  then
    raise EgoBsonSerializerError.Create('Invalid Enum representation');
end;

class procedure TgoBsonSerializer.CheckFloatRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.Double,
    TgoBsonRepresentation.Int32, TgoBsonRepresentation.Int64,
    TgoBsonRepresentation.String]))
  then
    raise EgoBsonSerializerError.Create('Invalid floating-point representation');
end;

class procedure TgoBsonSerializer.CheckGuidRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.Binary,
    TgoBsonRepresentation.String]))
  then
    raise EgoBsonSerializerError.Create('Invalid GUID representation');
end;

class procedure TgoBsonSerializer.CheckIntegerRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.Double,
    TgoBsonRepresentation.Int32, TgoBsonRepresentation.Int64,
    TgoBsonRepresentation.String]))
  then
    raise EgoBsonSerializerError.Create('Invalid Integer representation');
end;

class procedure TgoBsonSerializer.CheckObjectIdRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.ObjectId,
    TgoBsonRepresentation.String]))
  then
    raise EgoBsonSerializerError.Create('Invalid ObjectId representation');
end;

class procedure TgoBsonSerializer.CheckStringRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.String,
    TgoBsonRepresentation.ObjectId, TgoBsonRepresentation.Symbol]))
  then
    raise EgoBsonSerializerError.Create('Invalid String representation');
end;

class procedure TgoBsonSerializer.CheckTBytesRepresentation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.Binary,
    TgoBsonRepresentation.String, TgoBsonRepresentation.Array]))
  then
    raise EgoBsonSerializerError.Create('Invalid TBytes representation');
end;

class procedure TgoBsonSerializer.CheckInt64Representation(
  const ARepresentation: TgoBsonRepresentation);
begin
  if (not (ARepresentation in [TgoBsonRepresentation.Double,
    TgoBsonRepresentation.Int32, TgoBsonRepresentation.Int64,
    TgoBsonRepresentation.String]))
  then
    raise EgoBsonSerializerError.Create('Invalid Int64 representation');
end;

class constructor TgoBsonSerializer.Create;
begin
  FRegisteredSerializers := TObjectDictionary<PTypeInfo, TSerializer>.Create([doOwnsValues]);
  FDiscriminatedTypes := TgoSet<PTypeInfo>.Create;
  FDiscriminatedTypesByName := TDictionary<String, PTypeInfo>.Create;
  FLock := TCriticalSection.Create;
end;

class procedure TgoBsonSerializer.Deserialize<T>(const ABson: TBytes;
  var AValue: T);
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Create(ABson);
  Deserialize<T>(Reader, AValue);
end;

class procedure TgoBsonSerializer.Deserialize<T>(const AJson: String;
  var AValue: T);
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Create(AJson);
  Deserialize<T>(Reader, AValue);
end;

class procedure TgoBsonSerializer.Deserialize<T>(
  const ADocument: TgoBsonDocument; var AValue: T);
var
  Reader: IgoBsonDocumentReader;
begin
  Reader := TgoBsonDocumentReader.Create(ADocument);
  Deserialize<T>(Reader, AValue);
end;

class procedure TgoBsonSerializer.Deserialize<T>(
  const AReader: IgoBsonBaseReader; var AValue: T);
var
  Serializer: TSerializer;
  Instance: TObject;
  RecordSerializer: TRecordSerializer absolute Serializer;
  ClassSerializer: TClassSerializer absolute Serializer;
  ArraySerializer: TArraySerializer absolute Serializer;
  CustomSerializer: TCustomSerializer absolute Serializer;
begin
  Serializer := GetOrAddSerializer<T>;
  if (Serializer.IsCustomSerializer) then
  begin
    CustomSerializer.Deserialize(AReader, AValue);
    Exit;
  end;

  case Serializer.TypeKind of
    tkRecord {$IF (RTLVersion >= 34)},tkMRecord{$ENDIF}:
      begin
        Assert(Serializer is TRecordSerializer);

        { Issue #8: finalize previous value before clearing }
        Finalize(AValue);

        if Assigned(RecordSerializer.InitializeProc) then
          RecordSerializer.InitializeProc(@AValue)
        else
        begin
          FillChar(AValue, SizeOf(T), 0);
          {$IF (RTLVersion >= 34)}
          if (Serializer.TypeKind = tkMRecord) then
            { Make sure Initialize operator is called (if available). }
            Initialize(AValue);
          {$ENDIF}
        end;
        RecordSerializer.Deserialize(@AValue, AReader);
      end;

    tkClass:
      begin
        Assert(Serializer is TClassSerializer);
        Instance := PObject(@AValue)^;
        ClassSerializer.Deserialize(Instance, AReader);
        PObject(@AValue)^ := Instance;
      end;

    tkDynArray:
      begin
        Assert(Serializer is TArraySerializer);
        PPointer(@AValue)^ := ArraySerializer.Deserialize(AReader);
      end
  else
    raise EgoBsonSerializerError.Create('Only class, record and dynamic array types can be deserialized');
  end;
end;

class function TgoBsonSerializer.DeserializeArray(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): Pointer;
begin
  Assert(Assigned(AInfo.Serializer));
  Assert(AInfo.Serializer is TArraySerializer);
  Result := TArraySerializer(AInfo.Serializer).Deserialize(AReader);
end;

class function TgoBsonSerializer.DeserializeBoolean(
  const AInfo: TInfo; const AReader: IgoBsonBaseReader): Boolean;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Boolean:
      Result := AReader.ReadBoolean;

    TgoBsonType.Double:
      Result := (AReader.ReadDouble <> 0);

    TgoBsonType.Int32:
      Result := (AReader.ReadInt32 <> 0);

    TgoBsonType.Int64:
      Result := (AReader.ReadInt64 <> 0);

    TgoBsonType.String:
      Result := SameText(AReader.ReadString, 'true');
  else
    raise EgoBsonSerializerError.Create('Unsupported Boolean deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeChar(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): Char;
var
  S: String;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.String:
      begin
        S := AReader.ReadString;
        if (S = '') then
          raise EgoBsonSerializerError.Create('Cannot read Char from empty string');
        Result := S.Chars[0];
      end;

    TgoBsonType.Int32:
      Result := Chr(AReader.ReadInt32);

    TgoBsonType.Int64:
      Result := Chr(AReader.ReadInt64);
  else
    raise EgoBsonSerializerError.Create('Unsupported Char deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeDateTime(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): TDateTime;
var
  DT: TgoBsonDateTime;
  Name: String;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.DateTime:
      begin
        DT := TgoBsonDateTime.Create(AReader.ReadDateTime);
        Result := DT.ToUniversalTime;
      end;

    TgoBsonType.Document:
      begin
        Result := 0;
        AReader.ReadStartDocument;
        while (AReader.ReadBsonType <> TgoBsonType.EndOfDocument) do
        begin
          Name := AReader.ReadName;
          if (Name = 'DateTime') then
            // Ignore (use Ticks instead)
            AReader.SkipValue
          else if (Name = 'Ticks') then
            Result := goDateTimeFromTicks(AReader.ReadInt64, True);
        end;
        AReader.ReadEndDocument;
      end;

    TgoBsonType.Int64:
      Result := goDateTimeFromTicks(AReader.ReadInt64, True);

    TgoBsonType.String:
      Result := ISO8601ToDate(AReader.ReadString, True);
  else
    raise EgoBsonSerializerError.Create('Unsupported TDateTime deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeDouble(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): Double;
var
  S: String;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Double:
      Result := AReader.ReadDouble;

    TgoBsonType.Int32:
      Result := AReader.ReadInt32;

    TgoBsonType.Int64:
      Result := AReader.ReadInt64;

    TgoBsonType.String:
      begin
        S := AReader.ReadString;
        if SameText(S, 'NaN') then
          Result := Double.NaN
        else if (SameText(S, 'Infinity')) then
          Result := Double.PositiveInfinity
        else if (SameText(S, '-Infinity')) then
          Result := Double.NegativeInfinity
        else
          Result := StrToFloat(S, goUSFormatSettings);
      end
  else
    raise EgoBsonSerializerError.Create('Unsupported Double deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeEnum(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): UInt32;
var
  S: String;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Int32:
      Result := UInt32(AReader.ReadInt32);

    TgoBsonType.Int64:
      Result := AReader.ReadInt64;

    TgoBsonType.String:
      begin
        S := AReader.ReadString;
        if (not TryStrToInt(S, Integer(Result))) then
          Result := GetEnumValue(AInfo.&Type, S);
      end
  else
    raise EgoBsonSerializerError.Create('Unsupported Enum deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeGuid(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): TGUID;
var
  V: TgoBsonValue;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Binary:
      begin
        V := AReader.ReadBinaryData;
        Result := V;
      end;

    TgoBsonType.String:
      Result := TGUID.Create('{' + AReader.ReadString + '}')
  else
    raise EgoBsonSerializerError.Create('Unsupported GUID deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeInt32(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): Int32;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Double:
      Result := Trunc(AReader.ReadDouble);

    TgoBsonType.Int32:
      Result := AReader.ReadInt32;

    TgoBsonType.Int64:
      Result := AReader.ReadInt64;

    TgoBsonType.String:
      Result := StrToInt(AReader.ReadString);
  else
    raise EgoBsonSerializerError.Create('Unsupported Int32 deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeInt64(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): Int64;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Double:
      Result := Trunc(AReader.ReadDouble);

    TgoBsonType.Int32:
      Result := AReader.ReadInt32;

    TgoBsonType.Int64:
      Result := AReader.ReadInt64;

    TgoBsonType.String:
      Result := StrToInt64(AReader.ReadString);
  else
    raise EgoBsonSerializerError.Create('Unsupported Int64 deserialization type');
  end;
end;

class procedure TgoBsonSerializer.DeserializeObject(const AInfo: TInfo;
  var AValue: TObject; const AReader: IgoBsonBaseReader);
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Null:
      { Even though AValue may be assigned, we do not free it }
      AReader.ReadNull;

    TgoBsonType.Document:
      begin
        Assert(Assigned(AInfo.Serializer));
        Assert(AInfo.Serializer is TClassSerializer);
        TClassSerializer(AInfo.Serializer).Deserialize(AValue, AReader);
      end;
  else
    raise EgoBsonSerializerError.Create('Unsupported Object deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeObjectId(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): TgoObjectId;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.ObjectId:
      Result := AReader.ReadObjectId;

    TgoBsonType.String:
      Result := TgoObjectId.Parse(AReader.ReadString);
  else
    raise EgoBsonSerializerError.Create('Unsupported ObjectId deserialization type');
  end;
end;

class procedure TgoBsonSerializer.DeserializeRecord(const AInfo: TInfo;
  const AValue: Pointer; const AReader: IgoBsonBaseReader);
begin
  Assert(Assigned(AInfo.Serializer));
  if (AReader.GetCurrentBsonType = TgoBsonType.Null) then
    AReader.ReadNull
  else if (AInfo.Serializer.IsCustomSerializer) then
    TCustomSerializer(AInfo.Serializer).Deserialize(AReader, AValue^)
  else
  begin
    Assert(AInfo.Serializer is TRecordSerializer);
    TRecordSerializer(AInfo.Serializer).Deserialize(AValue, AReader);
  end;
end;

class function TgoBsonSerializer.DeserializeSet(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): UInt32;
var
  S: String;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Int32:
      Result := UInt32(AReader.ReadInt32);

    TgoBsonType.Int64:
      Result := AReader.ReadInt64;

    TgoBsonType.String:
      begin
        S := AReader.ReadString;
        if (S = '') then
          Result := 0
        else
          Result := StringToSet(AInfo.&Type, S);
      end
  else
    raise EgoBsonSerializerError.Create('Unsupported Set deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeString(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): String;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.String:
      Exit(AReader.ReadString);

    TgoBsonType.Symbol:
      Exit(AReader.ReadSymbol);

    TgoBsonType.ObjectId:
      if (AInfo.Representation = TgoBsonRepresentation.ObjectId) then
        Exit(AReader.ReadObjectId.ToString);

    TgoBsonType.Null:
      begin
        AReader.ReadNull;
        Exit('');
      end;
  end;
  raise EgoBsonSerializerError.Create('Unsupported String deserialization type');
end;

class function TgoBsonSerializer.DeserializeTBytes(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): TBytes;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Binary:
      Result := AReader.ReadBytes;

    TgoBsonType.String:
      Result := goParseHexString(AReader.ReadString);
  else
    raise EgoBsonSerializerError.Create('Unsupported TBytes deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeUInt32(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): UInt32;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Double:
      Result := Trunc(AReader.ReadDouble);

    TgoBsonType.Int32:
      Result := UInt32(AReader.ReadInt32);

    TgoBsonType.Int64:
      Result := UInt32(AReader.ReadInt64);

    TgoBsonType.String:
      Result := StrToInt64(AReader.ReadString);
  else
    raise EgoBsonSerializerError.Create('Unsupported UInt32 deserialization type');
  end;
end;

class function TgoBsonSerializer.DeserializeUInt64(const AInfo: TInfo;
  const AReader: IgoBsonBaseReader): UInt64;
begin
  case AReader.GetCurrentBsonType of
    TgoBsonType.Double:
      Result := Trunc(AReader.ReadDouble);

    TgoBsonType.Int32:
      Result := UInt32(AReader.ReadInt32);

    TgoBsonType.Int64:
      Result := UInt64(AReader.ReadInt64);

    TgoBsonType.String:
      Result := StrToUInt64(AReader.ReadString);
  else
    raise EgoBsonSerializerError.Create('Unsupported UInt32 deserialization type');
  end;
end;

class destructor TgoBsonSerializer.Destroy;
begin
  FreeAndNil(FRegisteredSerializers);
  FreeAndNil(FDiscriminatedTypes);
  FreeAndNil(FDiscriminatedTypesByName);
  FreeAndNil(FLock);
end;

class function TgoBsonSerializer.GetOrAddSerializer(const ATypeInfo: PTypeInfo): TSerializer;
var
  Serializer: TSerializer;
begin
  if (ATypeInfo = nil) then
    raise EgoBsonSerializerError.Create('Type info is missing for serialization');

  Assert(Assigned(FLock));
  Assert(Assigned(FRegisteredSerializers));
  FLock.Enter;
  try
    if (FRegisteredSerializers.TryGetValue(ATypeInfo, Result)) then
      Exit;
  finally
    FLock.Leave;
  end;

  case ATypeInfo.Kind of
    tkClass   : Result := TClassSerializer.Create(ATypeInfo);
    tkRecord  : Result := TRecordSerializer.Create(ATypeInfo);
    {$IF (RTLVersion >= 34)}
    tkMRecord : Result := TRecordSerializer.Create(ATypeInfo);
    {$ENDIF}
    tkDynArray: Result := TArraySerializer.Create(ATypeInfo);
  else
    raise EgoBsonSerializerError.Create('Only class and record types can be serialized');
  end;

  { Another thread may already have registered the same type in the meantime.
    In that case, ignore this one and use the existing type. }
  Assert(Assigned(FLock));
  Assert(Assigned(FRegisteredSerializers));
  FLock.Enter;
  try
    if (FRegisteredSerializers.TryGetValue(ATypeInfo, Serializer)) then
    begin
      FreeAndNil(Result);
      Result := Serializer;
    end
    else
      FRegisteredSerializers.Add(ATypeInfo, Result);

    { Setup serializer AFTER saving it to FRegisteredSerializers. This prevents
      an eternal loop in case type ATypeInfo has a field of the same type,
      which would call GetOrAddSerializer until the stack overflows.
      Thanks to Ludwig Behm for pointing this out! }
    Result.Setup;
  finally
    FLock.Leave;
  end;
end;

class function TgoBsonSerializer.GetOrAddSerializer<T>: TSerializer;
begin
  Result := GetOrAddSerializer(TypeInfo(T));
end;

class procedure TgoBsonSerializer.RegisterCustomSerializer(
  const AForType: PTypeInfo; const ASerializerClass: TCustomSerializerClass);
begin
  Assert(Assigned(FLock));
  Assert(Assigned(FRegisteredSerializers));
  FLock.Enter;
  try
    if (not FRegisteredSerializers.ContainsKey(AForType)) then
      FRegisteredSerializers.Add(AForType, ASerializerClass.Create(AForType));
  finally
    FLock.Leave;
  end;
end;

class procedure TgoBsonSerializer.RegisterCustomSerializer<T>(
  const ASerializerClass: TCustomSerializerClass);
begin
  RegisterCustomSerializer(TypeInfo(T), ASerializerClass);
end;

class procedure TgoBsonSerializer.RegisterSubClass(const ASubClass: TClass);
var
  Serializer: TSerializer;
  SubClassSerializer: TClassSerializer absolute Serializer;
begin
  if (ASubClass = nil) then
    Exit;

  FLock.Enter;
  try
    if FDiscriminatedTypes.Contains(ASubClass.ClassInfo) then
      Exit;
  finally
    FLock.Leave;
  end;

  Serializer := GetOrAddSerializer(ASubClass.ClassInfo);
  Assert(Serializer is TClassSerializer);

  FLock.Enter;
  try
    FDiscriminatedTypes.AddOrSet(ASubClass.ClassInfo);
    FDiscriminatedTypesByName.AddOrSetValue(SubClassSerializer.FDiscriminator, ASubClass.ClassInfo);
  finally
    FLock.Leave;
  end;

  RegisterSubClass(ASubClass.ClassParent);
end;

class procedure TgoBsonSerializer.RegisterSubClasses(
  const ASubClasses: array of TClass);
var
  I: Integer;
begin
  for I := 0 to Length(ASubClasses) - 1 do
    RegisterSubClass(ASubClasses[I]);
end;

class procedure TgoBsonSerializer.Serialize<T>(const AValue: T;
  const ASettings: TgoJsonWriterSettings; out AJson: String);
var
  Writer: IgoJsonWriter;
begin
  Writer := TgoJsonWriter.Create(ASettings);
  Serialize<T>(AValue, Writer);
  AJson := Writer.ToJson;
end;

class procedure TgoBsonSerializer.Serialize<T>(const AValue: T;
  out AJson: String);
begin
  Serialize<T>(AValue, TgoJsonWriterSettings.Default, AJson);
end;

class procedure TgoBsonSerializer.Serialize<T>(const AValue: T;
  out ABson: TBytes);
var
  Writer: IgoBsonWriter;
begin
  Writer := TgoBsonWriter.Create;
  Serialize<T>(AValue, Writer);
  ABson := Writer.ToBson;
end;

class procedure TgoBsonSerializer.Serialize<T>(const AValue: T;
  out ADocument: TgoBsonDocument);
var
  Writer: IgoBsonDocumentWriter;
begin
  ADocument := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(ADocument);
  Serialize<T>(AValue, Writer);
end;

class procedure TgoBsonSerializer.Serialize<T>(const AValue: T;
  const AWriter: IgoBsonBaseWriter);
var
  Serializer: TSerializer;
  RecordSerializer: TRecordSerializer absolute Serializer;
  ClassSerializer: TClassSerializer absolute Serializer;
  ArraySerializer: TArraySerializer absolute Serializer;
  CustomSerializer: TCustomSerializer absolute Serializer;
begin
  Serializer := GetOrAddSerializer<T>;
  if (Serializer.IsCustomSerializer) then
  begin
    CustomSerializer.Serialize(AValue, AWriter);
    Exit;
  end;

  case Serializer.TypeKind of
    tkRecord {$IF (RTLVersion >= 34)},tkMRecord{$ENDIF}:
      begin
        Assert(Serializer is TRecordSerializer);
        RecordSerializer.Serialize(@AValue, AWriter);
      end;
    tkClass:
      begin
        Assert(Serializer is TClassSerializer);
        ClassSerializer.Serialize(PObject(@AValue)^, AWriter, ClassSerializer.TypeInfo);
      end;
    tkDynArray:
      begin
        Assert(Serializer is TArraySerializer);
        ArraySerializer.Serialize(PPointer(@AValue)^, AWriter, TgoBsonRepresentation.Default);
      end;
  else
    raise EgoBsonSerializerError.Create('Only class, record and dynamic array types can be serialized');
  end;
end;

class procedure TgoBsonSerializer.SerializeArray(const AInfo: TInfo;
  const AValue: Pointer; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (AValue = nil) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  Assert(Assigned(AInfo.Serializer));
  Assert(AInfo.Serializer is TArraySerializer);
  TArraySerializer(AInfo.Serializer).Serialize(AValue, AWriter, AInfo.Representation);
end;

class procedure TgoBsonSerializer.SerializeBoolean(
  const AInfo: TInfo; const AValue: Boolean;
  const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (AValue = AInfo.DefaultValue.FAsBoolean) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Boolean:
      AWriter.WriteBoolean(AValue);

    TgoBsonRepresentation.Double:
      AWriter.WriteDouble(Ord(AValue));

    TgoBsonRepresentation.Int32:
      AWriter.WriteInt32(Ord(AValue));

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(Ord(AValue));

    TgoBsonRepresentation.String:
      if (AValue) then
        AWriter.WriteString('true')
      else
        AWriter.WriteString('false');
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeChar(const AInfo: TInfo;
  const AValue: Char; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (AValue = #0) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.String:
      AWriter.WriteString(AValue);

    TgoBsonRepresentation.Int32:
      AWriter.WriteInt32(Ord(AValue));

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(Ord(AValue));
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeDateTime(const AInfo: TInfo;
  const AValue: TDateTime; const AWriter: IgoBsonBaseWriter);
var
  MS: Int64;
  S: String;
begin
  if (AInfo.IgnoreIfDefault) and (AValue = 0) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.DateTime:
      begin
        MS := goDateTimeToMillisecondsSinceEpoch(AValue, True);
        AWriter.WriteDateTime(MS);
      end;

    TgoBsonRepresentation.Document:
      begin
        MS := goDateTimeToMillisecondsSinceEpoch(AValue, True);
        AWriter.WriteStartDocument;
        AWriter.WriteDateTime('DateTime', MS);
        AWriter.WriteInt64('Ticks', goDateTimeToTicks(AValue, True));
        AWriter.WriteEndDocument;
      end;

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(goDateTimeToTicks(AValue, True));

    TgoBsonRepresentation.String:
      begin
        S := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', AValue, goUSFormatSettings);
        MS := MilliSecondOf(AValue);
        if (MS <> 0) then
          S := S + '.' + IntToStr(MS * 10000);
        AWriter.WriteString(S);
      end
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeDouble(const AInfo: TInfo;
  const AValue: Double; const AWriter: IgoBsonBaseWriter);
var
  S: String;
begin
  if (AInfo.IgnoreIfDefault) and (AValue = 0) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Double:
      AWriter.WriteDouble(AValue);

    TgoBsonRepresentation.Int32:
      AWriter.WriteInt32(Trunc(AValue));

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(Trunc(AValue));

    TgoBsonRepresentation.String:
      begin
        S := FloatToStr(AValue, goUSFormatSettings);
        if (S = 'NAN') then
          S := 'NaN'
        else if (S = 'INF') then
          S := 'Infinity'
        else if (S = '-INF') then
          S := '-Infinity';
        AWriter.WriteString(S);
      end
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeEnum(const AInfo: TInfo;
  const AValue: UInt32; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (Integer(AValue) = AInfo.DefaultValue.FAsInt32) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Int32:
      AWriter.WriteInt32(AValue);

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(AValue);

    TgoBsonRepresentation.String:
      begin
        if (Integer(AValue) <= AInfo.&Type.TypeData.MaxValue) then
          AWriter.WriteString(GetEnumName(AInfo.&Type, AValue))
        else
          AWriter.WriteString(AValue.ToString);
      end;
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeGuid(const AInfo: TInfo;
  const AValue: TGUID; const AWriter: IgoBsonBaseWriter);
var
  V: TgoBsonValue;
  S: String;
begin
  if (AInfo.IgnoreIfDefault) and (AValue = TGUID.Empty) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Binary:
      begin
        V := AValue;
        AWriter.WriteBinaryData(V.AsBsonBinaryData);
      end;

    TgoBsonRepresentation.String:
      begin
        S := AValue.ToString;
        S := S.Substring(1, S.Length - 2);
        AWriter.WriteString(S.ToLower);
      end;
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeInt32(const AInfo: TInfo;
  const AValue: Int32; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (AValue = AInfo.DefaultValue.FAsInt32) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Double:
      AWriter.WriteDouble(AValue);

    TgoBsonRepresentation.Int32:
      AWriter.WriteInt32(AValue);

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(AValue);

    TgoBsonRepresentation.String:
      AWriter.WriteString(IntToStr(AValue));
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeInt64(const AInfo: TInfo;
  const AValue: Int64; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (AValue = AInfo.DefaultValue.FAsInt64) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Double:
      AWriter.WriteDouble(AValue);

    TgoBsonRepresentation.Int32:
      AWriter.WriteInt32(Int32(AValue));

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(AValue);

    TgoBsonRepresentation.String:
      AWriter.WriteString(IntToStr(AValue));
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeObject(const AInfo: TInfo;
  const AValue: TObject; const AWriter: IgoBsonBaseWriter);
var
  ClassSerializer: TClassSerializer;
begin
  if (AInfo.IgnoreIfDefault) and (AValue = nil) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  if (AValue = nil) then
    AWriter.WriteNull
  else
  begin
    Assert(Assigned(AInfo.Serializer));
    Assert(AInfo.Serializer is TClassSerializer);
    ClassSerializer := TClassSerializer(AInfo.Serializer);
    ClassSerializer.Serialize(AValue, AWriter, ClassSerializer.TypeInfo);
  end;
end;

class procedure TgoBsonSerializer.SerializeObjectId(const AInfo: TInfo;
  const AValue: TgoObjectId; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (AValue.IsEmpty) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.ObjectId:
      AWriter.WriteObjectId(AValue);

    TgoBsonRepresentation.String:
      AWriter.WriteString(AValue.ToString);
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeRecord(const AInfo: TInfo;
  const AValue: Pointer; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  Assert(Assigned(AInfo.Serializer));
  if (AInfo.Serializer.IsCustomSerializer) then
    TCustomSerializer(AInfo.Serializer).Serialize(AValue^, AWriter)
  else
  begin
    Assert(AInfo.Serializer is TRecordSerializer);
    TRecordSerializer(AInfo.Serializer).Serialize(AValue, AWriter);
  end;
end;

class procedure TgoBsonSerializer.SerializeSet(const AInfo: TInfo;
  const AValue: UInt32; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (AValue = 0) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Int32:
      AWriter.WriteInt32(AValue);

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(AValue);

    TgoBsonRepresentation.String:
      begin
        if (AValue = 0) then
          AWriter.WriteString('')
        else
          AWriter.WriteString(SetToString(AInfo.&Type, AValue));
      end;
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeString(const AInfo: TInfo;
  const AValue: String; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (AValue = AInfo.DefaultValue.FAsString) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.String:
      AWriter.WriteString(AValue);

    TgoBsonRepresentation.Symbol:
      AWriter.WriteSymbol(AValue);

    TgoBsonRepresentation.ObjectId:
      AWriter.WriteObjectId(TgoObjectId.Parse(AValue));
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeTBytes(const AInfo: TInfo;
  const AValue: TBytes; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (AValue = nil) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Binary:
      AWriter.WriteBytes(AValue);

    TgoBsonRepresentation.String:
      AWriter.WriteString(goToHexString(AValue));
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeUInt32(const AInfo: TInfo;
  const AValue: UInt32; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (Int32(AValue) = AInfo.DefaultValue.FAsInt32) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Double:
      AWriter.WriteDouble(AValue);

    TgoBsonRepresentation.Int32:
      AWriter.WriteInt32(Int32(AValue));

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(AValue);

    TgoBsonRepresentation.String:
      AWriter.WriteString(IntToStr(AValue));
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.SerializeUInt64(const AInfo: TInfo;
  const AValue: UInt64; const AWriter: IgoBsonBaseWriter);
begin
  if (AInfo.IgnoreIfDefault) and (Int64(AValue) = AInfo.DefaultValue.FAsInt64) then
    Exit;

  if (AInfo.Name <> '') then
    AWriter.WriteName(AInfo.Name);

  case AInfo.Representation of
    TgoBsonRepresentation.Double:
      AWriter.WriteDouble(AValue);

    TgoBsonRepresentation.Int32:
      AWriter.WriteInt32(Int32(AValue));

    TgoBsonRepresentation.Int64:
      AWriter.WriteInt64(AValue);

    TgoBsonRepresentation.String:
      AWriter.WriteString(UIntToStr(AValue));
  else
    Assert(False);
  end;
end;

class function TgoBsonSerializer.TryDeserialize<T>(const ABson: TBytes;
  var AValue: T): Boolean;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Create(ABson);
  Result := TryDeserialize<T>(Reader, AValue);
end;

class function TgoBsonSerializer.TryDeserialize<T>(const AJson: String;
  var AValue: T): Boolean;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Create(AJson);
  Result := TryDeserialize<T>(Reader, AValue);
end;

class function TgoBsonSerializer.TryDeserialize<T>(
  const ADocument: TgoBsonDocument; var AValue: T): Boolean;
var
  Reader: IgoBsonDocumentReader;
begin
  Reader := TgoBsonDocumentReader.Create(ADocument);
  Result := TryDeserialize<T>(Reader, AValue);
end;

class function TgoBsonSerializer.TryDeserialize<T>(
  const AReader: IgoBsonBaseReader; var AValue: T): Boolean;
begin
  try
    Deserialize(AReader, AValue);
    Result := True;
  except
    Result := False;
  end;
end;

class function TgoBsonSerializer.TrySerialize<T>(const AValue: T;
  out ABson: TBytes): Boolean;
var
  Writer: IgoBsonWriter;
begin
  Writer := TgoBsonWriter.Create;
  Result := TrySerialize<T>(AValue, Writer);
  if (Result) then
    ABson := Writer.ToBson
  else
    ABson := nil;
end;

class function TgoBsonSerializer.TrySerialize<T>(const AValue: T;
  out AJson: String): Boolean;
begin
  Result := TrySerialize<T>(AValue, TgoJsonWriterSettings.Default, AJson);
end;

class function TgoBsonSerializer.TrySerialize<T>(const AValue: T;
  const ASettings: TgoJsonWriterSettings; out AJson: String): Boolean;
var
  Writer: IgoJsonWriter;
begin
  Writer := TgoJsonWriter.Create(ASettings);
  Result := TrySerialize<T>(AValue, Writer);
  if (Result) then
    AJson := Writer.ToJson
  else
    AJson := '';
end;

class function TgoBsonSerializer.TrySerialize<T>(const AValue: T;
  const AWriter: IgoBsonBaseWriter): Boolean;
begin
  try
    Serialize(AValue, AWriter);
    Result := True;
  except
    Result := False;
  end;
end;

class function TgoBsonSerializer.TrySerialize<T>(const AValue: T;
  out ADocument: TgoBsonDocument): Boolean;
var
  Writer: IgoBsonDocumentWriter;
begin
  ADocument := TgoBsonDocument.Create;
  Writer := TgoBsonDocumentWriter.Create(ADocument);
  Result := TrySerialize<T>(AValue, Writer);
end;

{ TgoBsonSerializer.TSerializer }

constructor TgoBsonSerializer.TSerializer.Create(const ATypeInfo: PTypeInfo);
begin
  Assert(Assigned(ATypeInfo));
  inherited Create;
  FTypeInfo := ATypeInfo;
end;

function TgoBsonSerializer.TSerializer.GetTypeKind: TTypeKind;
begin
  Result := FTypeInfo.Kind;
end;

procedure TgoBsonSerializer.TSerializer.Setup;
begin
  { No default implementation }
end;

{ TgoBsonSerializer.TStructSerializer }

destructor TgoBsonSerializer.TStructSerializer.Destroy;
begin
  FInfoByName.DisposeOf;
  inherited;
end;

procedure TgoBsonSerializer.TStructSerializer.Initialize(
  const AStructType: TRttiType);
begin
  { No default implementation }
end;

procedure TgoBsonSerializer.TStructSerializer.MapFields(
  const AStructType: TRttiType);
var
  StructType: TRttiType;
  Fields: TArray<TRttiField>;
  FieldInfos: TArray<TFieldInfo>;
  Field: TRttiField;
  FieldCount: Integer;
  Attrs: TArray<TCustomAttribute>;
  Attr: TCustomAttribute;
  Info: TFieldInfo;
  IncludeField: Boolean;
begin
  StructType := AStructType;
  FFields := nil;
  while Assigned(StructType) do
  begin
    Fields := StructType.GetDeclaredFields;
    FieldCount := 0;
    SetLength(FieldInfos, Length(Fields));
    for Field in Fields do
    begin
      if (Field.Visibility >= mvPublic) then
      begin
        Attrs := Field.GetAttributes;
        IncludeField := True;
        for Attr in Attrs do
        begin
          if (Attr is BsonIgnoreAttribute) then
          begin
            IncludeField := False;
            Break;
          end;
        end;

        if (IncludeField) then
        begin
          Info := TFieldInfo.Create(StructType, Field, Attrs);

          Assert(FieldCount < Length(FieldInfos));
          FieldInfos[FieldCount] := Info;
          Inc(FieldCount);

          FInfoByName.Add(Info.Name, Info);
        end;
      end;
    end;
    SetLength(FieldInfos, FieldCount);
    FFields := FieldInfos + FFields; // Fields of base classes come first
    StructType := StructType.BaseType;
  end;
end;

procedure TgoBsonSerializer.TStructSerializer.SerializeFields(
  const ABaseAddress: PByte; const AWriter: IgoBsonBaseWriter);
var
  I: Integer;
  Info: TFieldInfo;
begin
  for I := 0 to Length(FFields) - 1 do
  begin
    Info := FFields[I];
    Info.SerializeProc(Info, ABaseAddress + Info.Offset, AWriter);
  end;
end;

procedure TgoBsonSerializer.TStructSerializer.Setup;
var
  Context: TRttiContext;
  Typ: TRttiType;
begin
  Context := TRttiContext.Create;
  Context.KeepContext;
  try
    Typ := Context.GetType(FTypeInfo);
    if (Typ = nil) then
      raise EgoBsonSerializerError.CreateFmt('Unable to get type information for type "%s"',
        [FTypeInfo.NameFld.ToString]);

    FInfoByName := TObjectDictionary<String, TInfo>.Create([doOwnsValues]);
    MapFields(Typ);
    Initialize(Typ);
  finally
    Context.DropContext;
  end;
end;

{ TgoBsonSerializer.TRecordSerializer }

procedure TgoBsonSerializer.TRecordSerializer.Deserialize(
  const ABaseAddress: PByte; const AReader: IgoBsonBaseReader);
var
  Name: String;
  Info: TInfo;
  FieldInfo: TFieldInfo absolute Info;
begin
  AReader.ReadStartDocument;
  while (AReader.ReadBsonType <> TgoBsonType.EndOfDocument) do
  begin
    Name := AReader.ReadName;
    if (FInfoByName.TryGetValue(Name, Info)) then
    begin
      Assert(Info is TFieldInfo);
      FieldInfo.DeserializeProc(FieldInfo, ABaseAddress + FieldInfo.Offset, AReader);
    end
    else if (FErrorOnExtraElements) then
      raise EgoBsonSerializerError.CreateFmt('Element "%s" does not match any field of record %s.',
        [Name, FTypeInfo.NameFld.ToString])
    else
      AReader.SkipValue;
  end;
  AReader.ReadEndDocument;
end;

procedure TgoBsonSerializer.TRecordSerializer.Initialize(
  const AStructType: TRttiType);
begin
  inherited;
  MapInitialize(AStructType);
end;

procedure TgoBsonSerializer.TRecordSerializer.MapInitialize(
  const AStructType: TRttiType);
var
  Method: TRttiMethod;
begin
  for Method in AStructType.GetMethods do
  begin
    if (SameText(Method.Name, 'Initialize'))
      and (Method.MethodKind = mkProcedure)
      and (Method.CallingConvention = ccReg)
      and (Length(Method.GetParameters) = 0) then
    begin
      FInitializeProc := Method.CodeAddress;
      Exit;
    end;
  end;
end;

procedure TgoBsonSerializer.TRecordSerializer.Serialize(
  const ABaseAddress: PByte; const AWriter: IgoBsonBaseWriter);
begin
  AWriter.WriteStartDocument;
  SerializeFields(ABaseAddress, AWriter);
  AWriter.WriteEndDocument;
end;

{ TgoBsonSerializer.TClassSerializer }

procedure TgoBsonSerializer.TClassSerializer.Deserialize(
  var AInstance: TObject; const AReader: IgoBsonBaseReader);
var
  Name: String;
  Info: TInfo;
  FieldInfo: TFieldInfo absolute Info;
  PropInfo: TPropertyInfo absolute Info;
  ActualType: PTypeInfo;
  ActualSerializer: TSerializer;
  AllocatedInstance: Boolean;
  {$IFNDEF MSWINDOWS}
  InstanceValue: TValue;
  {$ENDIF}
begin
  ActualType := GetActualType(AReader, FTypeInfo);
  if (ActualType <> FTypeInfo) then
  begin
    ActualSerializer := TgoBsonSerializer.GetOrAddSerializer(ActualType);
    Assert(ActualSerializer is TClassSerializer);
    TClassSerializer(ActualSerializer).Deserialize(AInstance, AReader);
    Exit;
  end;

  AllocatedInstance := False;
  if (AInstance = nil) then
  begin
    {$IFDEF MSWINDOWS}
    { This is faster than using Invoke, but only works on Windows }
    Assert(Assigned(FConstructorProc));
    AInstance := FConstructorProc(FClass, 1); // Pass 1 to allocate object
    {$ELSE}
    Assert(Assigned(FConstructorAddress));
    Assert(Length(FConstructorArgs) = 2);
    InstanceValue := Invoke(FConstructorAddress, FConstructorArgs, ccReg,
      FClass.ClassInfo, False, True);
    AInstance := InstanceValue.AsObject;
    {$ENDIF}
    AllocatedInstance := True;
  end;

  try
    AReader.ReadStartDocument;
    while (AReader.ReadBsonType <> TgoBsonType.EndOfDocument) do
    begin
      Name := AReader.ReadName;
      if (FInfoByName.TryGetValue(Name, Info)) then
      begin
        if (Info.IsProperty) then
        begin
          Assert(Info is TPropertyInfo);
          { Read-only properties don't have a DeserializeProc }
          if Assigned(PropInfo.DeserializeProc) then
            PropInfo.DeserializeProc(PropInfo, AInstance, AReader)
          else
            AReader.SkipValue;
        end
        else
        begin
          Assert(Info is TFieldInfo);
          FieldInfo.DeserializeProc(FieldInfo, PByte(AInstance) + FieldInfo.Offset, AReader);
        end;
      end
      else if (Name = TClassSerializer.NAME_DISCRIMINATOR) then
        AReader.SkipValue
      else if (FErrorOnExtraElements) then
        raise EgoBsonSerializerError.CreateFmt('Element "%s" does not match any field or property of class %s.',
          [Name, FTypeInfo.NameFld.ToString])
      else
        AReader.SkipValue;
    end;
    AReader.ReadEndDocument;
  except
    if AllocatedInstance then
      FreeAndNil(AInstance);
    raise;
  end;
end;

function TgoBsonSerializer.TClassSerializer.GetActualType(
  const AReader: IgoBsonBaseReader; const ANominalType: PTypeInfo): PTypeInfo;
var
  Bookmark: IgoBsonReaderBookmark;
  Value: TgoBsonValue;
  ActualTypeName: String;
  ActualType: PTypeInfo;
  I: Integer;
begin
  Result := ANominalType;
  if (AReader.GetCurrentBsonType = TgoBsonType.Document) then
  begin
    if (TgoBsonSerializer.FDiscriminatedTypes.Contains(ANominalType)) then
    begin
      Bookmark := AReader.GetBookmark;
      AReader.ReadStartDocument;

      { The "_t" element should be the first or second element }
      for I := 0 to 1 do
      begin
        if (AReader.ReadBsonType = TgoBsonType.EndOfDocument) then
          Break;

        if (AReader.ReadName = NAME_DISCRIMINATOR) then
        begin
          Value := AReader.ReadValue;
          if (Value.IsString) then
          begin
            ActualTypeName := Value;
            if FDiscriminatedTypesByName.TryGetValue(ActualTypeName, ActualType) then
              Result := ActualType
            else
              raise EgoBsonSerializerError.CreateFmt('Unknown discriminator "%s" for type "%s"',
                [ActualTypeName, ANominalType.NameFld.ToString]);
          end;
          Break;
        end;
      end;

      AReader.ReturnToBookmark(Bookmark);
    end;
  end;
end;

procedure TgoBsonSerializer.TClassSerializer.Initialize(
  const AStructType: TRttiType);
begin
  inherited;
  MapConstructor(AStructType);
  MapProperties(AStructType);
  FDiscriminator := FClass.ClassName;
  MapAttributes(AStructType);
end;

procedure TgoBsonSerializer.TClassSerializer.MapAttributes(
  const AStructType: TRttiType);
var
  Attr: TCustomAttribute;
  DiscriminatorAttribute: BsonDiscriminatorAttribute absolute Attr;
  ErrorOnExtraElementsAttribute: BsonErrorOnExtraElementsAttribute absolute Attr;
  BaseType: TRttiType;
  Handled: Boolean;
begin
  Handled := False;
  for Attr in AStructType.GetAttributes do
  begin
    if (Attr is BsonDiscriminatorAttribute) then
    begin
      FDiscriminatorRequired := DiscriminatorAttribute.Required;

      { Only use the name for the actual class (do not use name from base class) }
      if (AStructType.Handle = FTypeInfo) and (DiscriminatorAttribute.Discriminator <> '') then
        FDiscriminator := DiscriminatorAttribute.Discriminator;

      Handled := True;
    end
    else if (Attr is BsonErrorOnExtraElementsAttribute) then
      FErrorOnExtraElements := True;
  end;

  { Use discriminator attribute from base class, if any }
  if (not Handled) then
  begin
    BaseType := AStructType.BaseType;
    if Assigned(BaseType) then
      MapAttributes(BaseType);
  end;
end;

procedure TgoBsonSerializer.TClassSerializer.MapConstructor(
  const AStructType: TRttiType);
var
  StructType: TRttiType;
  Method: TRttiMethod;
begin
  FClass := AStructType.AsInstance.MetaclassType;
  StructType := AStructType;
  while Assigned(StructType) do
  begin
    for Method in StructType.GetDeclaredMethods do
    begin
      if (Method.IsConstructor)
        and (not Method.IsClassMethod)
        and (Method.CallingConvention = ccReg)
        and (Length(Method.GetParameters) = 0) then
      begin
        {$IFDEF MSWINDOWS}
        FConstructorProc := Method.CodeAddress;
        {$ELSE}
        FConstructorAddress := Method.CodeAddress;
        SetLength(FConstructorArgs, 2);
        FConstructorArgs[0] := FClass;
        FConstructorArgs[1] := True; // Means to allocate object
        {$ENDIF}
        Exit;
      end;
    end;
    StructType := StructType.BaseType;
  end;

  Assert(False, 'There should always be a parameterless constructor (down to TObject)');
end;

procedure TgoBsonSerializer.TClassSerializer.MapProperties(
  const AStructType: TRttiType);
var
  StructType: TRttiType;
  Props: TArray<TRttiProperty>;
  PropInfos: TArray<TPropertyInfo>;
  Prop: TRttiProperty;
  PropCount: Integer;
  Info: TPropertyInfo;
  Attrs: TArray<TCustomAttribute>;
  Attr: TCustomAttribute;
  IncludeProperty: Boolean;
begin
  StructType := AStructType;
  FProperties := nil;
  while Assigned(StructType) do
  begin
    Props := StructType.GetDeclaredProperties;
    SetLength(PropInfos, Length(Props));
    PropCount := 0;
    for Prop in Props do
    begin
      if (Prop.Visibility >= mvPublic) and (Prop.IsReadable) then
      begin
        { Only include read/write properties, unless the type is a class or a
          BsonElement attribute is specified. }
        IncludeProperty := (Prop.IsWritable) or (Prop.PropertyType.IsInstance);

        Attrs := Prop.GetAttributes;
        for Attr in Attrs do
        begin
          if (Attr is BsonElementAttribute) then
            IncludeProperty := True
          else if (Attr is BsonIgnoreAttribute) then
            IncludeProperty := False;
        end;

        if (IncludeProperty) then
        begin
          Info := TPropertyInfo.Create(StructType, Prop);

          Assert(PropCount < Length(PropInfos));
          PropInfos[PropCount] := Info;
          Inc(PropCount);

          FInfoByName.Add(Info.Name, Info);
        end;
      end;
    end;
    SetLength(PropInfos, PropCount);
    FProperties := PropInfos + FProperties; // Properties of base classes come first
    StructType := StructType.BaseType;
  end;
end;

procedure TgoBsonSerializer.TClassSerializer.Serialize(const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter; const ANominalType: PTypeInfo);
var
  ActualType: PTypeInfo;
  ActualSerializer: TSerializer;
begin
  ActualType := AInstance.ClassInfo;
  if (ActualType = FTypeInfo) then
  begin
    AWriter.WriteStartDocument;

    { If ANominalType is TAnimal, but actual type is TDog, then we should write
      a discriminator so we know on deserialization that we need to deserialize
      an instance of type TDog }
    if ShouldSerializeDiscriminator(ANominalType) then
      SerializeDiscriminator(AWriter);

    SerializeFields(Pointer(AInstance), AWriter);
    SerializeProperties(AInstance, AWriter);
    AWriter.WriteEndDocument;
  end
  else
  begin
    { If this class serializes type TAnimal, but actual type is TDog, then we
      want to serialize a TDog }
    ActualSerializer := TgoBsonSerializer.GetOrAddSerializer(ActualType);
    Assert(ActualSerializer is TClassSerializer);
    TClassSerializer(ActualSerializer).Serialize(AInstance, AWriter, ANominalType);
  end;
end;

procedure TgoBsonSerializer.TClassSerializer.SerializeDiscriminator(
  const AWriter: IgoBsonBaseWriter);
begin
  Assert(Assigned(FClass));
  AWriter.WriteString(NAME_DISCRIMINATOR, FDiscriminator);
end;

procedure TgoBsonSerializer.TClassSerializer.SerializeProperties(
  const AInstance: TObject; const AWriter: IgoBsonBaseWriter);
var
  I: Integer;
  Info: TPropertyInfo;
begin
  for I := 0 to Length(FProperties) - 1 do
  begin
    Info := FProperties[I];
    Info.SerializeProc(Info, AInstance, AWriter);
  end;
end;

function TgoBsonSerializer.TClassSerializer.ShouldSerializeDiscriminator(
  const ANominalType: PTypeInfo): Boolean;
begin
  Result := FDiscriminatorRequired or (ANominalType <> FTypeInfo);
end;

{ TgoBsonSerializer.TArraySerializer }

constructor TgoBsonSerializer.TArraySerializer.Create(const ATypeInfo: PTypeInfo);
var
  TypeData: PTypeData;
  ElementTypePtr: PPTypeInfo;
  ElementTypeInfo: PTypeInfo;
begin
  inherited Create(ATypeInfo);
  TypeData := ATypeInfo.TypeData;
  ElementTypePtr := TypeData.DynArrElType;
  if (ElementTypePtr = nil) or (ElementTypePtr^ = nil) then
    raise EgoBsonSerializerError.CreateFmt('Unsupported element type for array type %s', [ATypeInfo.NameFld.ToString]);
  ElementTypeInfo := ElementTypePtr^;
  FElementInfo := TVarInfo.Create(ElementTypeInfo);
  FElementSize := TypeData.elSize;
end;

function TgoBsonSerializer.TArraySerializer.Deserialize(
  const AReader: IgoBsonBaseReader): Pointer;
var
  Count, Capacity: NativeInt;
  ElementSize: Integer;
  ElementInfo: TVarInfo;
  ElementDeserializeProc: TDeserializeVarProc;
  Element: PByte;
begin
  Result := nil;
  AReader.ReadStartArray;
  Count := 0;
  Capacity := 0;
  Element := nil;
  ElementSize := FElementSize;
  ElementInfo := FElementInfo;
  ElementDeserializeProc := ElementInfo.DeserializeProc;
  try
    while (AReader.ReadBsonType <> TgoBsonType.EndOfDocument) do
    begin
      if (Count >= Capacity) then
      begin
        if (Capacity > 64) then
          Inc(Capacity, Capacity div 4)
        else if (Capacity > 8) then
          Inc(Capacity, 16)
        else
          Inc(Capacity, 4);
        DynArraySetLength(Result, FTypeInfo, 1, @Capacity);
        Element := PByte(Result) + (Count * ElementSize);
      end;

      Inc(Count);
      ElementDeserializeProc(ElementInfo, Element, AReader);
      Inc(Element, ElementSize);
    end;
    if (Count > 0) then
      DynArraySetLength(Result, FTypeInfo, 1, @Count);

    AReader.ReadEndArray;
  except
    { Issue #32: clear array in case of exception }
    if (Result <> nil) then
      DynArrayClear(Result, FTypeInfo);
    raise;
  end;
end;

destructor TgoBsonSerializer.TArraySerializer.Destroy;
begin
  FElementInfo.Free;
  inherited;
end;

procedure TgoBsonSerializer.TArraySerializer.Serialize(const AArray: Pointer;
  const AWriter: IgoBsonBaseWriter;
  const AElementRepresentation: TgoBsonRepresentation);
var
  I, Length, ElementSize: Integer;
  ElementInfo: TVarInfo;
  ElementSerializeProc: TSerializeVarProc;
  Element: PByte;
  OrigRepresentation: TgoBsonRepresentation;
begin
  AWriter.WriteStartArray;
  if Assigned(AArray) then
  begin
    Element := AArray;
    ElementSize := FElementSize;
    ElementInfo := FElementInfo;
    ElementSerializeProc := ElementInfo.SerializeProc;

    OrigRepresentation := ElementInfo.FRepresentation;
    if (AElementRepresentation <> TgoBsonRepresentation.Default) then
      ElementInfo.FRepresentation := AElementRepresentation;

    Length := DynArraySize(AArray);
    for I := 0 to Length - 1 do
    begin
      ElementSerializeProc(ElementInfo, Element, AWriter);
      Inc(Element, ElementSize);
    end;

    ElementInfo.FRepresentation := OrigRepresentation;
  end;
  AWriter.WriteEndArray;
end;

{ TgoBsonSerializer.TCustomSerializer }

constructor TgoBsonSerializer.TCustomSerializer.Create(
  const ATypeInfo: PTypeInfo);
begin
  inherited Create(ATypeInfo);
  FIsCustomSerializer := True;
end;

{ TgoBsonSerializer.TVarInfo }

constructor TgoBsonSerializer.TVarInfo.Create(const AType: PTypeInfo);
begin
  inherited Create;
  if (AType = nil) then
    raise EgoBsonSerializerError.Create('Unable to get serialization type');

  FType := AType;
  GetSerializationProcs(AType);

  if (not Assigned(FSerializeProc)) or (not Assigned(FDeserializeProc)) then
    raise EgoBsonSerializerError.CreateFmt('Unsupported type "%s"', [AType.NameFld.ToString]);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeArray(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PPointer(AAddress)^ := TgoBsonSerializer.DeserializeArray(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeBoolean(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PBoolean(AAddress)^ := TgoBsonSerializer.DeserializeBoolean(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeChar(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PChar(AAddress)^ := TgoBsonSerializer.DeserializeChar(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeDateTime(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PDateTime(AAddress)^ := TgoBsonSerializer.DeserializeDateTime(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeDouble(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PDouble(AAddress)^ := TgoBsonSerializer.DeserializeDouble(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeEnum16(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt16(AAddress)^ := TgoBsonSerializer.DeserializeEnum(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeEnum32(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt32(AAddress)^ := TgoBsonSerializer.DeserializeEnum(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeEnum8(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt8(AAddress)^ := TgoBsonSerializer.DeserializeEnum(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeGuid(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PGUID(AAddress)^ := TgoBsonSerializer.DeserializeGuid(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeInt16(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PInt16(AAddress)^ := TgoBsonSerializer.DeserializeInt32(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeInt32(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PInt32(AAddress)^ := TgoBsonSerializer.DeserializeInt32(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeInt64(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PInt64(AAddress)^ := TgoBsonSerializer.DeserializeInt64(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeInt8(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PInt8(AAddress)^ := TgoBsonSerializer.DeserializeInt32(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeObject(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  TgoBsonSerializer.DeserializeObject(AVar, PObject(AAddress)^, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeObjectId(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PgoObjectId(AAddress)^ := TgoBsonSerializer.DeserializeObjectId(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeRecord(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  TgoBsonSerializer.DeserializeRecord(AVar, AAddress, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeSet16(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt16(AAddress)^ := TgoBsonSerializer.DeserializeSet(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeSet32(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt32(AAddress)^ := TgoBsonSerializer.DeserializeSet(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeSet8(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt8(AAddress)^ := TgoBsonSerializer.DeserializeSet(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeSingle(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PSingle(AAddress)^ := TgoBsonSerializer.DeserializeDouble(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeString(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUnicodeString(AAddress)^ := TgoBsonSerializer.DeserializeString(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeTBytes(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PBytes(AAddress)^ := TgoBsonSerializer.DeserializeTBytes(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeUInt16(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt16(AAddress)^ := TgoBsonSerializer.DeserializeInt32(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeUInt32(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt32(AAddress)^ := TgoBsonSerializer.DeserializeUInt32(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeUInt64(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt64(AAddress)^ := TgoBsonSerializer.DeserializeUInt64(AVar, AReader);
end;

class procedure TgoBsonSerializer.TVarInfo.DeserializeUInt8(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AReader: IgoBsonBaseReader);
begin
  PUInt8(AAddress)^ := TgoBsonSerializer.DeserializeInt32(AVar, AReader);
end;

procedure TgoBsonSerializer.TVarInfo.GetSerializationProcs(
  const AType: PTypeInfo);
var
  TypeData: PTypeData;
begin
  case AType.Kind of
    tkInteger:
      begin
        TypeData := GetTypeData(AType);
        Assert(Assigned(TypeData));
        case TypeData.OrdType of
          otSByte: begin
                     FSerializeProc := SerializeInt8;
                     FDeserializeProc := DeserializeInt8;
                     if (FRepresentation = TgoBsonRepresentation.Default) then
                       FRepresentation := TgoBsonRepresentation.Int32
                     else
                       CheckIntegerRepresentation(FRepresentation);
                   end;
          otUByte: begin
                     FSerializeProc := SerializeUInt8;
                     FDeserializeProc := DeserializeUInt8;
                     if (FRepresentation = TgoBsonRepresentation.Default) then
                       FRepresentation := TgoBsonRepresentation.Int32
                     else
                       CheckIntegerRepresentation(FRepresentation);
                   end;
          otSWord: begin
                     FSerializeProc := SerializeInt16;
                     FDeserializeProc := DeserializeInt16;
                     if (FRepresentation = TgoBsonRepresentation.Default) then
                       FRepresentation := TgoBsonRepresentation.Int32
                     else
                       CheckIntegerRepresentation(FRepresentation);
                   end;
          otUWord: begin
                     FSerializeProc := SerializeUInt16;
                     FDeserializeProc := DeserializeUInt16;
                     if (FRepresentation = TgoBsonRepresentation.Default) then
                       FRepresentation := TgoBsonRepresentation.Int32
                     else
                       CheckIntegerRepresentation(FRepresentation);
                   end;
          otSLong: begin
                     FSerializeProc := SerializeInt32;
                     FDeserializeProc := DeserializeInt32;
                     if (FRepresentation = TgoBsonRepresentation.Default) then
                       FRepresentation := TgoBsonRepresentation.Int32
                     else
                       CheckIntegerRepresentation(FRepresentation);
                   end;
          otULong: begin
                     FSerializeProc := SerializeUInt32;
                     FDeserializeProc := DeserializeUInt32;
                     if (FRepresentation = TgoBsonRepresentation.Default) then
                       FRepresentation := TgoBsonRepresentation.Int32
                     else
                       CheckIntegerRepresentation(FRepresentation);
                   end;
        else
          Assert(False);
        end;

        if (FIgnoreIfDefault) then
        begin
          case FDefaultValue.FRepresentation of
            TgoBsonRepresentation.Default:
              FDefaultValue.FRepresentation := TgoBsonRepresentation.Int32;

            TgoBsonRepresentation.Int32, TgoBsonRepresentation.Int64: ;
          else
            raise EgoBsonSerializerError.Create('Default value must be of an integer type');
          end;
        end;
      end;

    tkInt64:
      begin
        TypeData := GetTypeData(AType);
        Assert(Assigned(TypeData));
        if (TypeData.MinInt64Value > TypeData.MaxInt64Value) then
        begin
          FSerializeProc := SerializeUInt64;
          FDeserializeProc := DeserializeUInt64;
        end
        else
        begin
          FSerializeProc := SerializeInt64;
          FDeserializeProc := DeserializeInt64;
        end;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.Int64
        else
          CheckInt64Representation(FRepresentation);

        if (FIgnoreIfDefault) then
        begin
          case FDefaultValue.FRepresentation of
            TgoBsonRepresentation.Default:
              FDefaultValue.FRepresentation := TgoBsonRepresentation.Int64;

            TgoBsonRepresentation.Int32:
              FDefaultValue.FAsInt64 := FDefaultValue.FAsInt32;

            TgoBsonRepresentation.Int64: ;
          else
            raise EgoBsonSerializerError.Create('Default value must be of an integer type');
          end;
        end;
      end;

    tkFloat:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for floating-point types');

        if (AType = TypeInfo(TDateTime)) then
        begin
          FSerializeProc := SerializeDateTime;
          FDeserializeProc := DeserializeDateTime;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.DateTime
          else
            CheckDateTimeRepresentation(FRepresentation);
        end
        else
        begin
          TypeData := GetTypeData(AType);
          Assert(Assigned(TypeData));
          case TypeData.FloatType of
            ftSingle: begin
                        FSerializeProc := SerializeSingle;
                        FDeserializeProc := DeserializeSingle;
                      end;
            ftDouble: begin
                        FSerializeProc := SerializeDouble;
                        FDeserializeProc := DeserializeDouble;
                      end;
          end;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.Double
          else
            CheckFloatRepresentation(FRepresentation);
        end;
      end;

    tkEnumeration:
      begin
        TypeData := GetTypeData(AType);
        Assert(Assigned(TypeData));
        case TypeData.OrdType of
          otUByte,
          otSByte: begin
                     if (AType = TypeInfo(Boolean)) then
                     begin
                       FSerializeProc := SerializeBoolean;
                       FDeserializeProc := DeserializeBoolean;
                       if (FRepresentation = TgoBsonRepresentation.Default) then
                         FRepresentation := TgoBsonRepresentation.Boolean
                       else
                         CheckBooleanRepresentation(FRepresentation);

                       if (FIgnoreIfDefault) then
                       begin
                         case FDefaultValue.FRepresentation of
                           TgoBsonRepresentation.Default:
                             FDefaultValue.FRepresentation := TgoBsonRepresentation.Boolean;

                           TgoBsonRepresentation.Boolean: ;
                         else
                           raise EgoBsonSerializerError.Create('Default value must be of a boolean type');
                         end;
                       end;
                     end
                     else
                     begin
                       FSerializeProc := SerializeEnum8;
                       FDeserializeProc := DeserializeEnum8;
                     end;
                   end;
          otUWord,
          otSWord: begin
                     FSerializeProc := SerializeEnum16;
                     FDeserializeProc := DeserializeEnum16;
                   end;
          otULong,
          otSLong: begin
                     FSerializeProc := SerializeEnum32;
                     FDeserializeProc := DeserializeEnum32;
                   end;
        else
          Assert(False);
        end;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.Int32
        else if (AType <> TypeInfo(Boolean)) then
          CheckEnumRepresentation(FRepresentation);

        if (AType <> TypeInfo(Boolean)) and FIgnoreIfDefault and FHasDefaultValue then
        begin
          { Enum values can have a default value, but it MUST be of an integer
            type (the ordinal value). }
          case FDefaultValue.FRepresentation of
            TgoBsonRepresentation.Default:
              FDefaultValue.FRepresentation := TgoBsonRepresentation.Int32;

            TgoBsonRepresentation.Int32, TgoBsonRepresentation.Int64: ;
          else
            raise EgoBsonSerializerError.Create('Default value for enums must be of an integer type');
          end;
        end;
      end;

    tkSet:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for set types');

        TypeData := GetTypeData(AType);
        Assert(Assigned(TypeData));
        case TypeData.OrdType of
          otUByte,
          otSByte: begin
                     FSerializeProc := SerializeSet8;
                     FDeserializeProc := DeserializeSet8;
                   end;
          otUWord,
          otSWord: begin
                     FSerializeProc := SerializeSet16;
                     FDeserializeProc := DeserializeSet16;
                   end;
          otULong,
          otSLong: begin
                     FSerializeProc := SerializeSet32;
                     FDeserializeProc := DeserializeSet32;
                   end;
        else
          Assert(False);
        end;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.Int32
        else
          CheckEnumRepresentation(FRepresentation);
      end;

    tkWChar:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for character types');

        FSerializeProc := SerializeChar;
        FDeserializeProc := DeserializeChar;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.String
        else
          CheckCharRepresentation(FRepresentation);
      end;

    tkUString:
      begin
        FSerializeProc := SerializeString;
        FDeserializeProc := DeserializeString;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.String
        else
          CheckStringRepresentation(FRepresentation);

        if (FIgnoreIfDefault) then
        begin
          case FDefaultValue.FRepresentation of
            TgoBsonRepresentation.Default:
              FDefaultValue.FRepresentation := TgoBsonRepresentation.String;

            TgoBsonRepresentation.String: ;
          else
            raise EgoBsonSerializerError.Create('Default value must be of a string type');
          end;
        end;
      end;

    tkRecord {$IF (RTLVersion >= 34)},tkMRecord{$ENDIF}:
      begin
        if (AType = TypeInfo(TGUID)) then
        begin
          FSerializeProc := SerializeGuid;
          FDeserializeProc := DeserializeGuid;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.Binary
          else
            CheckGuidRepresentation(FRepresentation);
        end
        else if (AType = TypeInfo(TgoObjectId)) then
        begin
          FSerializeProc := SerializeObjectId;
          FDeserializeProc := DeserializeObjectId;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.ObjectId
          else
            CheckObjectIdRepresentation(FRepresentation);
        end
        else
        begin
          if FIgnoreIfDefault then
            raise EgoBsonSerializerError.Create('Default values are not supported for record types');

          FSerializeProc := SerializeRecord;
          FDeserializeProc := DeserializeRecord;
          FSerializer := TgoBsonSerializer.GetOrAddSerializer(AType);
        end;
      end;

    tkDynArray:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for array types');

        if (AType = TypeInfo(TBytes)) and (FRepresentation <> TgoBsonRepresentation.Array) then
        begin
          FSerializeProc := SerializeTBytes;
          FDeserializeProc := DeserializeTBytes;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.Binary
          else
            CheckTBytesRepresentation(FRepresentation);
        end
        else
        begin
          FSerializeProc := SerializeArray;
          FDeserializeProc := DeserializeArray;
          FSerializer := TgoBsonSerializer.GetOrAddSerializer(AType);
        end;
      end;

    tkClass:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for class types');

        FSerializeProc := SerializeObject;
        FDeserializeProc := DeserializeObject;
        FSerializer := TgoBsonSerializer.GetOrAddSerializer(AType);
      end;
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeArray(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeArray(AVar, PPointer(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeBoolean(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeBoolean(AVar, PBoolean(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeChar(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeChar(AVar, PChar(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeDateTime(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeDateTime(AVar, PDateTime(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeDouble(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeDouble(AVar, PDouble(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeEnum16(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeEnum(AVar, PUInt16(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeEnum32(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeEnum(AVar, PUInt32(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeEnum8(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeEnum(AVar, PUInt8(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeGuid(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeGuid(AVar, PGuid(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeInt16(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeInt32(AVar, PInt16(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeInt32(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeInt32(AVar, PInt32(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeInt64(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeInt64(AVar, PInt64(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeInt8(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeInt32(AVar, PInt8(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeObject(const AVar: TVarInfo;
  const AAddress: Pointer; const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeObject(AVar, PObject(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeObjectId(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeObjectId(AVar, PgoObjectId(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeRecord(const AVar: TVarInfo;
  const AAddress: Pointer; const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeRecord(AVar, AAddress, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeSet16(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeSet(AVar, PUInt16(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeSet32(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeSet(AVar, PUInt32(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeSet8(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeSet(AVar, PUInt8(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeSingle(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeDouble(AVar, PSingle(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeString(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeString(AVar, PUnicodeString(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeTBytes(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeTBytes(AVar, PBytes(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeUInt16(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeInt32(AVar, PUInt16(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeUInt32(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeUInt32(AVar, PUInt32(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeUInt64(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeUInt64(AVar, PUInt64(AAddress)^, AWriter);
end;

class procedure TgoBsonSerializer.TVarInfo.SerializeUInt8(
  const AVar: TVarInfo; const AAddress: Pointer;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeInt32(AVar, PUInt8(AAddress)^, AWriter);
end;

{ TgoBsonSerializer.TFieldInfo }

constructor TgoBsonSerializer.TFieldInfo.Create(const AStructType: TRttiType;
  const AField: TRttiField; const AAttrs: TArray<TCustomAttribute>);
var
  FieldType: TRttiType;
  FieldName: String;
  Attr: TCustomAttribute;
  RepresentationAttribute: BsonRepresentationAttribute absolute Attr;
  ElementAttribute: BsonElementAttribute absolute Attr;
  DefaultValueAttribute: BsonDefaultValueAttribute absolute Attr;
begin
  // Do NOT call inherited constructor
  FieldType := AField.FieldType;
  if (FieldType = nil) then
    raise EgoBsonSerializerError.CreateFmt('Unable to get serialization type for field %s.%s', [AStructType.Name, AField.Name]);
  FType := FieldType.Handle;

  FRepresentation := TgoBsonRepresentation.Default;
  FieldName := AField.Name;
  for Attr in AAttrs do
  begin
    if (Attr is BsonRepresentationAttribute) then
      FRepresentation := RepresentationAttribute.Representation
    else if (Attr is BsonIgnoreIfDefaultAttribute) then
      FIgnoreIfDefault := True
    else if (Attr is BsonDefaultValueAttribute) then
    begin
      FDefaultValue := DefaultValueAttribute.DefaultValue;
      FHasDefaultValue := True;
    end
    else if (Attr is BsonElementAttribute) then
    begin
      if (ElementAttribute.Name <> '') then
        FieldName := ElementAttribute.Name;
    end;
  end;

  GetSerializationProcs(FType);

  if (not Assigned(FSerializeProc)) or (not Assigned(FDeserializeProc)) then
    raise EgoBsonSerializerError.CreateFmt('Unsupported field type "%s" for field %s.%s',
      [FieldType.Name, AStructType.Name, AField.Name]);

  FName := FieldName;
  FOffset := AField.Offset;
end;

{ TgoBsonSerializer.TPropertyInfo }

constructor TgoBsonSerializer.TPropertyInfo.Create(const AStructType: TRttiType;
  const AProp: TRttiProperty);
var
  PropType: TRttiType;
  PropName: String;
  Attr: TCustomAttribute;
  RepresentationAttribute: BsonRepresentationAttribute absolute Attr;
  ElementAttribute: BsonElementAttribute absolute Attr;
  DefaultValueAttribute: BsonDefaultValueAttribute absolute Attr;
begin
  inherited Create;
  FIsProperty := True;
  PropType := AProp.PropertyType;
  if (PropType = nil) then
    raise EgoBsonSerializerError.CreateFmt('Unable to get serialization type for property %s.%s', [AStructType.Name, AProp.Name]);
  FType := PropType.Handle;

  FRepresentation := TgoBsonRepresentation.Default;
  PropName := AProp.Name;
  for Attr in AProp.GetAttributes do
  begin
    if (Attr is BsonRepresentationAttribute) then
      FRepresentation := BsonRepresentationAttribute(Attr).Representation
    else if (Attr is BsonIgnoreIfDefaultAttribute) then
      FIgnoreIfDefault := True
    else if (Attr is BsonDefaultValueAttribute) then
    begin
      FDefaultValue := DefaultValueAttribute.DefaultValue;
      FHasDefaultValue := True;
    end
    else if (Attr is BsonElementAttribute) then
    begin
      if (ElementAttribute.Name <> '') then
        PropName := ElementAttribute.Name;
    end;
  end;

  GetSerializationProcs(FType);

  if (not Assigned(FSerializeProc)) or (not Assigned(FDeserializeProc)) then
    raise EgoBsonSerializerError.CreateFmt('Unsupported field type "%s" for property %s.%s',
      [PropType.Name, AStructType.Name, AProp.Name]);

  { Only writable properties, or properties of a class-type can be deserialized }
  if (not AProp.IsWritable) and (not PropType.IsInstance) then
    FDeserializeProc := nil;

  FName := PropName;
  FInfo := (AProp as TRttiInstanceProperty).PropInfo;
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeArray(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
var
  Value: TValue;
begin
  { Note: cannot use SetDynArrayProp here because of reference count issue in
    Delphi. }
  TValue.Make(nil, AProp.Info.PropType^, Value);
  PPointer(Value.GetReferenceToRawData)^ := TgoBsonSerializer.DeserializeArray(AProp, AReader);
  SetValueProp(AInstance, AProp.Info, Value);
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeBoolean(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetOrdProp(AInstance, AProp.Info, Ord(TgoBsonSerializer.DeserializeBoolean(AProp, AReader)));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeChar(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetOrdProp(AInstance, AProp.Info, Ord(TgoBsonSerializer.DeserializeChar(AProp, AReader)));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeDateTime(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetFloatProp(AInstance, AProp.Info, TgoBsonSerializer.DeserializeDateTime(AProp, AReader));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeDouble(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetFloatProp(AInstance, AProp.Info, TgoBsonSerializer.DeserializeDouble(AProp, AReader));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeEnum(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetOrdProp(AInstance, AProp.Info, TgoBsonSerializer.DeserializeEnum(AProp, AReader));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeGuid(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetValueProp(AInstance, AProp.Info, TValue.From(TgoBsonSerializer.DeserializeGuid(AProp, AReader)));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeInt32(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetOrdProp(AInstance, AProp.Info, TgoBsonSerializer.DeserializeInt32(AProp, AReader));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeInt64(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetInt64Prop(AInstance, AProp.Info, TgoBsonSerializer.DeserializeInt64(AProp, AReader));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeObject(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
var
  Obj: TObject;
  HasObject: Boolean;
begin
  Obj := GetObjectProp(AInstance, AProp.Info);
  HasObject := Assigned(Obj);
  TgoBsonSerializer.DeserializeObject(AProp, Obj, AReader);
  if (not HasObject) and (Obj <> nil) then
  begin
    if Assigned(AProp.Info.SetProc) then
      SetObjectProp(AInstance, AProp.Info, Obj)
    else
    begin
      Obj.DisposeOf;
      raise EgoBsonSerializerError.CreateFmt('Cannot set read-only property %s.%s', [Obj.ClassName, AProp.Name]);
    end;
  end;
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeObjectId(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetValueProp(AInstance, AProp.Info, TValue.From(TgoBsonSerializer.DeserializeObjectId(AProp, AReader)));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeRecord(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
var
  Value: TValue;
begin
  TValue.Make(nil, AProp.Info.PropType^, Value);
  TgoBsonSerializer.DeserializeRecord(AProp, Value.GetReferenceToRawData, AReader);
  SetValueProp(AInstance, AProp.Info, Value);
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeSet(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetOrdProp(AInstance, AProp.Info, TgoBsonSerializer.DeserializeSet(AProp, AReader));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeString(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetStrProp(AInstance, AProp.Info, TgoBsonSerializer.DeserializeString(AProp, AReader));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeTBytes(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetDynArrayProp(AInstance, AProp.Info, TgoBsonSerializer.DeserializeTBytes(AProp, AReader));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeUInt32(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetOrdProp(AInstance, AProp.Info, Int32(TgoBsonSerializer.DeserializeUInt32(AProp, AReader)));
end;

class procedure TgoBsonSerializer.TPropertyInfo.DeserializeUInt64(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AReader: IgoBsonBaseReader);
begin
  SetInt64Prop(AInstance, AProp.Info, TgoBsonSerializer.DeserializeUInt64(AProp, AReader));
end;

procedure TgoBsonSerializer.TPropertyInfo.GetSerializationProcs(
  const AType: PTypeInfo);
var
  TypeData: PTypeData;
begin
  case AType.Kind of
    tkInteger:
      begin
        TypeData := GetTypeData(AType);
        Assert(Assigned(TypeData));
        case TypeData.OrdType of
          otSByte,
          otUByte,
          otSWord,
          otUWord,
          otSLong: begin
                     FSerializeProc := SerializeInt32;
                     FDeserializeProc := DeserializeInt32;
                     if (FRepresentation = TgoBsonRepresentation.Default) then
                       FRepresentation := TgoBsonRepresentation.Int32
                     else
                       CheckIntegerRepresentation(FRepresentation);
                   end;
          otULong: begin
                     FSerializeProc := SerializeUInt32;
                     FDeserializeProc := DeserializeUInt32;
                     if (FRepresentation = TgoBsonRepresentation.Default) then
                       FRepresentation := TgoBsonRepresentation.Int32
                     else
                       CheckIntegerRepresentation(FRepresentation);
                   end;
        end;

        if (FIgnoreIfDefault) then
        begin
          case FDefaultValue.FRepresentation of
            TgoBsonRepresentation.Default:
              FDefaultValue.FRepresentation := TgoBsonRepresentation.Int32;

            TgoBsonRepresentation.Int32, TgoBsonRepresentation.Int64: ;
          else
            raise EgoBsonSerializerError.Create('Default value must be of an integer type');
          end;
        end;
      end;

    tkInt64:
      begin
        TypeData := GetTypeData(AType);
        Assert(Assigned(TypeData));
        if (TypeData.MinInt64Value > TypeData.MaxInt64Value) then
        begin
          FSerializeProc := SerializeUInt64;
          FDeserializeProc := DeserializeUInt64;
        end
        else
        begin
          FSerializeProc := SerializeInt64;
          FDeserializeProc := DeserializeInt64;
        end;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.Int64
        else
          CheckInt64Representation(FRepresentation);

        if (FIgnoreIfDefault) then
        begin
          case FDefaultValue.FRepresentation of
            TgoBsonRepresentation.Default:
              FDefaultValue.FRepresentation := TgoBsonRepresentation.Int64;

            TgoBsonRepresentation.Int32:
              FDefaultValue.FAsInt64 := FDefaultValue.FAsInt32;

            TgoBsonRepresentation.Int64: ;
          else
            raise EgoBsonSerializerError.Create('Default value must be of an integer type');
          end;
        end;
      end;

    tkFloat:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for floating-point types');

        if (AType = TypeInfo(TDateTime)) then
        begin
          FSerializeProc := SerializeDateTime;
          FDeserializeProc := DeserializeDateTime;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.DateTime
          else
            CheckDateTimeRepresentation(FRepresentation);

        end
        else
        begin
          FSerializeProc := SerializeDouble;
          FDeserializeProc := DeserializeDouble;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.Double
          else
            CheckFloatRepresentation(FRepresentation);
        end;
      end;

    tkEnumeration:
      begin
        TypeData := GetTypeData(AType);
        Assert(Assigned(TypeData));
        case TypeData.OrdType of
          otUByte,
          otSByte: begin
                     if (AType = TypeInfo(Boolean)) then
                     begin
                       FSerializeProc := SerializeBoolean;
                       FDeserializeProc := DeserializeBoolean;
                       if (FRepresentation = TgoBsonRepresentation.Default) then
                         FRepresentation := TgoBsonRepresentation.Boolean
                       else
                         CheckBooleanRepresentation(FRepresentation);

                       if (FIgnoreIfDefault) then
                       begin
                         case FDefaultValue.FRepresentation of
                           TgoBsonRepresentation.Default:
                             FDefaultValue.FRepresentation := TgoBsonRepresentation.Boolean;

                           TgoBsonRepresentation.Boolean: ;
                         else
                           raise EgoBsonSerializerError.Create('Default value must be of a boolean type');
                         end;
                       end;
                     end
                     else
                     begin
                       FSerializeProc := SerializeEnum;
                       FDeserializeProc := DeserializeEnum;
                     end;
                   end;
        else
          FSerializeProc := SerializeEnum;
          FDeserializeProc := DeserializeEnum;
        end;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.Int32
        else if (AType <> TypeInfo(Boolean)) then
          CheckEnumRepresentation(FRepresentation);

        if (AType <> TypeInfo(Boolean)) and FIgnoreIfDefault and FHasDefaultValue then
        begin
          { Enum values can have a default value, but it MUST be of an integer
            type (the ordinal value). }
          case FDefaultValue.FRepresentation of
            TgoBsonRepresentation.Default:
              FDefaultValue.FRepresentation := TgoBsonRepresentation.Int32;

            TgoBsonRepresentation.Int32, TgoBsonRepresentation.Int64: ;
          else
            raise EgoBsonSerializerError.Create('Default value for enums must be of an integer type');
          end;
        end;
      end;

    tkSet:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for set types');

        FSerializeProc := SerializeSet;
        FDeserializeProc := DeserializeSet;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.Int32
        else
          CheckEnumRepresentation(FRepresentation);
      end;

    tkWChar:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for character types');

        FSerializeProc := SerializeChar;
        FDeserializeProc := DeserializeChar;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.String
        else
          CheckCharRepresentation(FRepresentation);
      end;

    tkUString:
      begin
        FSerializeProc := SerializeString;
        FDeserializeProc := DeserializeString;
        if (FRepresentation = TgoBsonRepresentation.Default) then
          FRepresentation := TgoBsonRepresentation.String
        else
          CheckStringRepresentation(FRepresentation);

        if (FIgnoreIfDefault) then
        begin
          case FDefaultValue.FRepresentation of
            TgoBsonRepresentation.Default:
              FDefaultValue.FRepresentation := TgoBsonRepresentation.String;

            TgoBsonRepresentation.String: ;
          else
            raise EgoBsonSerializerError.Create('Default value must be of a string type');
          end;
        end;
      end;

    tkRecord {$IF (RTLVersion >= 34)},tkMRecord{$ENDIF}:
      begin
        if (AType = TypeInfo(TGUID)) then
        begin
          FSerializeProc := SerializeGuid;
          FDeserializeProc := DeserializeGuid;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.Binary
          else
            CheckGuidRepresentation(FRepresentation);
        end
        else if (AType = TypeInfo(TgoObjectId)) then
        begin
          FSerializeProc := SerializeObjectId;
          FDeserializeProc := DeserializeObjectId;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.ObjectId
          else
            CheckObjectIdRepresentation(FRepresentation);
        end
        else
        begin
          if FIgnoreIfDefault then
            raise EgoBsonSerializerError.Create('Default values are not supported for record types');

          FSerializeProc := SerializeRecord;
          FDeserializeProc := DeserializeRecord;
          FSerializer := TgoBsonSerializer.GetOrAddSerializer(AType);
        end;
      end;

    tkDynArray:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for array types');

        if (AType = TypeInfo(TBytes)) and (FRepresentation <> TgoBsonRepresentation.Array) then
        begin
          FSerializeProc := SerializeTBytes;
          FDeserializeProc := DeserializeTBytes;
          if (FRepresentation = TgoBsonRepresentation.Default) then
            FRepresentation := TgoBsonRepresentation.Binary
          else
            CheckTBytesRepresentation(FRepresentation);
        end
        else
        begin
          FSerializeProc := SerializeArray;
          FDeserializeProc := DeserializeArray;
          FSerializer := TgoBsonSerializer.GetOrAddSerializer(AType);
        end;
      end;

    tkClass:
      begin
        if FIgnoreIfDefault and FHasDefaultValue then
          raise EgoBsonSerializerError.Create('Custom default values are not supported for class types');

        FSerializeProc := SerializeObject;
        FDeserializeProc := DeserializeObject;
        FSerializer := TgoBsonSerializer.GetOrAddSerializer(AType);
      end;
  else
    Assert(False);
  end;
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeArray(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
var
  Value: TValue;
begin
  { Note: cannot use GetDynArrayProp here because of reference count issue in
    Delphi in case the Getter returns an array that is created on-the-fly. }
  Value := GetValueProp(AInstance, AProp.Info);
  TgoBsonSerializer.SerializeArray(AProp, PPointer(Value.GetReferenceToRawData)^, AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeBoolean(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeBoolean(AProp, Boolean(GetOrdProp(AInstance, AProp.Info)), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeChar(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeChar(AProp, Chr(GetOrdProp(AInstance, AProp.Info)), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeDateTime(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeDateTime(AProp, GetFloatProp(AInstance, AProp.Info), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeDouble(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeDouble(AProp, GetFloatProp(AInstance, AProp.Info), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeEnum(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeEnum(AProp, GetOrdProp(AInstance, AProp.Info), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeGuid(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeGuid(AProp, GetValueProp(AInstance, AProp.Info).AsType<TGUID>, AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeInt32(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeInt32(AProp, GetOrdProp(AInstance, AProp.Info), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeInt64(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeInt64(AProp, GetInt64Prop(AInstance, AProp.Info), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeObject(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeObject(AProp, GetObjectProp(AInstance, AProp.Info), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeObjectId(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeObjectId(AProp, GetValueProp(AInstance, AProp.Info).AsType<TgoObjectId>, AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeRecord(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
var
  Value: TValue;
begin
  Value := GetValueProp(AInstance, AProp.Info);
  TgoBsonSerializer.SerializeRecord(AProp, Value.GetReferenceToRawData, AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeSet(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeSet(AProp, GetOrdProp(AInstance, AProp.Info), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeString(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeString(AProp, GetStrProp(AInstance, AProp.Info), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeTBytes(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeTBytes(AProp, TBytes(GetDynArrayProp(AInstance, AProp.Info)), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeUInt32(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeUInt32(AProp, UInt32(GetOrdProp(AInstance, AProp.Info)), AWriter);
end;

class procedure TgoBsonSerializer.TPropertyInfo.SerializeUInt64(
  const AProp: TPropertyInfo; const AInstance: TObject;
  const AWriter: IgoBsonBaseWriter);
begin
  TgoBsonSerializer.SerializeUInt64(AProp, UInt64(GetInt64Prop(AInstance, AProp.Info)), AWriter);
end;

end.
