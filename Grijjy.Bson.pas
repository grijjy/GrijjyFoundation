unit Grijjy.Bson;
(*< A light-weight and fast BSON and JSON object model, with support for
  efficiently parsing and writing in JSON and BSON format.

  The code in this unit is fully compatible with the BSON and JSON used by
  MongoDB. It supports all JSON extensions used by MongoDB.

  However, this unit does @bold(not) have any dependencies on the MongoDB units
  and can be used as a stand-alone BSON/JSON library. It is therefore also
  suitable as a general purpose JSON library.

  @bold(Quick Start)

  <source>
  var
    Doc: TgoBsonDocument;
    A: TgoBsonArray;
    Json: String;
    Bson: TBytes;
  begin
    Doc := TgoBsonDocument.Create;
    Doc.Add('Hello', 'World');

    A := TgoBsonArray.Create(['awesome', 5.05, 1986]);
    Doc.Add('BSON', A);

    Json := Doc.ToJson; // Returns:
    // { "hello" : "world",
    //   "BSON": ["awesone", 5.05, 1986] }

    Bson := Doc.ToBson; // Saves to binary BSON

    Doc := TgoBsonDocument.Parse('{ "Answer" : 42 }');
    WriteLn(Doc['Answer']); // Outputs 42
    Doc['Answer'] := 'Unknown';
    Doc['Pi'] := 3.14;
    WriteLn(Doc.ToJson); // Outputs { "Answer" : "Unknown", "Pi" : 3.14 }
  end;
  </source>

  @bold(Object Model)

  The root type in the BSON object model is TgoBsonValue. TgoBsonValue is a
  record type which can hold any type of BSON value. Some implicit class
  operators make it easy to assign basic types:

  <source>
  var
    Value: TgoBsonValue;
  begin
    Value := True;                           // Creates a Boolean value
    Value := 1;                              // Creates an Integer value
    Value := 3.14;                           // Creates a Double value
    Value := 'Foo';                          // Creates a String value
    Value := TBytes.Create(1, 2, 3);         // Creates a binary (TBytes) value
    Value := TgoObjectId.GenerateNewId;      // Creates an ObjectId value
  end;
  </source>

  Note that you can change the type later by assigning a value of another type.
  You can also go the other way around:

  <source>
  var
    Value: TgoBsonValue;
    FloatVal: Double;
  begin
    Value := 3.14;              // Creates a Double value
    FloatVal := Value;          // Uses implicit cast
    FloatVal := Value.AsDouble; // Or more explicit cast
    Value := 42;                // Creates an Integer value
    FloatVal := Value;          // Converts an Integer BSON value to a Double
    FloatVal := Value.AsDouble; // Raises exception because types don't match exactly

    if (Value.BsonType = TgoBsonType.Double) then
      FloatVal := Value.AsDouble; // Now it is safe to cast

    // Or identical:
    if (Value.IsDouble) then
      FloatVal := Value.AsDouble;
  end;
  </source>

  Note that the implicit operators will try to convert if the types don't match
  exactly. For example, a BSON value containing an Integer value can be
  implicitly converted to a Double. If the conversion fails, it returns a zero
  value (or empty string).

  The "As*" methods however will raise an exception if the types don't match
  exactly. You should use these methods if you know that the type you request
  matches the value's type exactly. These methods are a bit more efficient than
  the implicit operators.

  You can check the value type using the BsonType-property or one of the "Is*"
  methods.

  For non-basic types, there are value types that are "derived" from
  TgoBsonValue:
  * TgoBsonNull: the special "null" value
  * TgoBsonArray: an array of other BSON values.
  * TgoBsonDocument: a document containing key/value pairs, where the key is a
    string and the value can be any BSON value. This is usually the main
    starting point in Mongo, since all database "records" are represented as
    BSON documents in Mongo. A document is similar to a dictionary in many
    programming languages, or the "object" type in JSON.
  * TgoBsonBinaryData: arbitrary binary data. Is also used to store GUID's (but
    not ObjectId's).
  * TgoBsonDateTime: a date/time value with support for conversion to and from
    UTC (Universal) time. Is always stored in UTC format (as the number of UTC
    milliseconds since the Unix epoch).
  * TgoBsonRegularExpression: a regular expression with options.
  * TgoBsonJavaScript: a piece of JavaScript code.
  * TgoBsonJavaScriptWithScope: a piece of JavaScript code with a scope (a set
    of variables with values, as defined in another document).
  * TgoBsonTimestamp: special internal type used by MongoDB replication and
    sharding.
  * TgoBsonMaxKey: special type which compares higher than all other possible
    BSON element values.
  * TgoBsonMinKey: special type which compares lower than all other possible
    BSON element values.
  * TgoBsonUndefined: an undefined value (deprecated by BSON)
  * TgoBsonSymbol: a symbol from a lookup table (deprecated by BSON)

  Note that these are not "real" derived types, since they are implemented as
  Delphi records (which do not support inheritance). But the implicit operators
  make it possible to treat each of these types as a TgoBsonValue. For example

  <source>
  var
    MyArray: TgoBsonArray;
    Value: TgoBsonValue;
  begin
    MyArray := TgoBsonArray.Create([1, 3.14, 'Foo', False]);
    Value := MyArray; // "subtypes" are compatible with TgoBsonValue

    // Or shorter:
    Value := TgoBsonArray.Create([1, 3.14, 'Foo', False]);
  end;
  </source>

  @Bold(Arrays)

  The example above also shows that arrays can be created very easily. An array
  contains a collection of BSON values of any type. Since BSON values can be
  implicitly created from basic types, you can pass multiple types in the
  array constructor. In the example above, 4 BSON values will be added to the
  array of types Integer, Double, String and Boolean.

  You can also add items using the Add or AddRange methods:

  <source>
  MyArray := TgoBsonArray.Create;
  MyArray.Add(1);
  MyArray.Add(3.14);
  MyArray.Add('Foo');
  </source>

  Some methods return the array (or document) itself, so they can be used for
  chaining (aka as a "fluent interface"). The example above is equivalent to:

  <source>
  MyArray := TgoBsonArray.Create;
  MyArray.Add(1).Add(3.14).Add('Foo');
  </source>

  You can change values (and types) like this:

  <source>
  // Changes entry 1 from Double to Boolean
  MyArray[1] := True;
  </source>

  @Bold(Documents)

  Documents (or dictionaries) can also be created easily:

  <source>
  var
    Doc: TgoBsonDocument;
  begin
    Doc := TgoBsonDocument.Create('Answer', 42);
  end;
  </source>

  This creates a document with a single entry called 'Answer' with a value of
  42. Keep in mind that the value can be any BSON type:

  <source>
  Doc := TgoBsonDocument.Create('Answer', TgoBsonArray.Create([42, False]));
  </source>

  You can Add, Remove and Delete (Adds can be fluent):

  <source>
  Doc := TgoBsonDocument.Create;
  Doc.Add('Answer', 42);
  Doc.Add('Pi', 3.14).Add('Pie', 'Yummi');

  // Deletes second item (Pi):
  Doc.Delete(1);

  // Removes first item (Answer):
  Doc.Remove('Answer');
  </source>

  Like Delphi dictionaries, the Add method will raise an exception if an item
  with the given name already exists. Unlike Delphi dictionaries however, you
  can easily set an item using its default accessor:

  <source>
  // Adds Answer:
  Doc['Answer'] := 42;

  // Adds Pi:
  Doc['Pi'] := 3.14;

  // Updates Answer:
  Doc['Answer'] := 'Everything';
  </source>

  This adds the item if it does not yet exists, or replaces it otherwise (there
  is no (need for an) AddOrSet method).

  Also unlike Delphi dictionaries, documents maintain insertion order and you
  can also access the items by index:

  <source>
  // Returns item by name:
  V := Doc['Pi'];

  // Returns item by index:
  V := Doc.Values[1];
  </source>

  Documents can be easily parsed from JSON:

  <source>
  Doc := TgoBsonDocument.Parse('{ "Answer" : 42 }');
  </source>

  The parser understands standard JSON as well as the MongoDB JSON extensions.

  You can also load a document from a BSON byte array:

  <source>
  Bytes := LoadSomeBSONData();
  Doc := TgoBsonDocument.Load(Bytes);
  </source>

  These methods will raise exceptions if the JSON or BSON data is invalid.

  @bold(Memory Management)

  All memory management in this library is automatic. You never need to (and you
  never must) destroy any objects yourself.

  The object model types (TgoBsonValue and friends) are all Delphi records. The
  actual implementations of these records use interfaces to manage memory.

  There is no concept of ownership in the object model. An array does @bold(not)
  own its elements and a document does @bold(not) own its elements. So you are
  free to add the same value to multiple arrays and/or documents without
  ownership concerns:

  <source>
  var
    Array1, Array2, SubArray, Doc1, Doc2: TgoBsonValue;
  begin
    SubArray := TgoBsonArray.Create([42, 'Foo', True]);
    Array1 := TgoBsonArray.Create;
    Array2 := TgoBsonArray.Create([123, 'Abc']);
    Doc1 := TgoBsonDocument.Create;
    Doc2 := TgoBsonDocument.Create('Pi', 3.14);

    Array1.Add(SubArray);
    Array2.Add(SubArray);      // Add same value to other container
    Doc1.Add('Bar', SubArray); // And again
    Doc2.Add('Baz', SubArray); // And again
  end;
  </source>

  Non-object model types are defined as interfaces, so their memory is managed
  automatically as well. For example JSON/BSON readers and writer are
  interfaces:

  <source>
  var
    Reader: IgoJsonReader;
    Value: TgoBsonValue;
  begin
    Reader := TgoJsonReader.Create('{ "Pi" : 3.14 }');
    Value := Reader.ReadValue;
    Assert(Value.IsDocument);
    Assert(Value.AsDocument['Pi'] = 3.14);
  end;
  </source>

  Just keep in mind that you must always declare your variable (Reader) as an
  interface type (IgoJsonReader), but you construct it using the class type
  (TgoJsonReader).

  @bold(JSON and BSON reading and writing)

  For easy storing, all BSON values have methods called ToJson and ToBson to
  store its value into JSON or BSON format:

  <source>
  var
    A: TgoBsonValue;
    B: TBytes;
  begin
    A := 42;
    WriteLn(A.ToJson); // Outputs '42'

    A := 'Foo';
    WriteLn(A.ToJson); // Outputs '"Foo"'

    A := TgoBsonArray.Create([1, 'Foo', True]);
    WriteLn(A.ToJson); // Outputs '[1, "Foo", true]'

    A := TgoBsonDocument.Create('Pi', 3.14);
    WriteLn(A.ToJson); // Outputs '{ "Pi" : 3.14 }'
    B := A.ToBson;     // Outputs document in BSON format
  end;
  </source>

  When outputting to JSON, you can optionally supply a settings record to
  customize the output:
  * Whether to pretty-print the output
  * What strings to use for indentation and line breaks
  * Whether to output standard JSON or use the MongoDB shell syntax extension

  If you don's supply any settings, then output will be in Strict JSON format
  without pretty printing.

  Easy loading is only supported at the Value, Document and Array level, using
  the Parse and Load methods:

  <source>
  var
    Doc: TgoBsonDocument;
    Bytes: TBytes;
  begin
    Doc := TgoBsonDocument.Parse('{ "Pi" : 3.14 }');
    Bytes := LoadSomeBSONData();
    Doc := TgoBsonDocument.Load(Bytes);
  end;
  </source>

  You can load other types using the IgoJsonReader and IgoBsonReader
  interfaces:

  <source>
  var
    Reader: IgoBsonReader;
    Value: TgoBsonValue;
    Bytes: TBytes;
  begin
    Bytes := LoadSomeBSONData();
    Reader := TgoBsonReader.Create(Bytes);
    Value := Reader.ReadValue;
  end;
  </source>

  The JSON reader and writer supports both the "strict" JSON syntax, as well as
  the "Mongo Shell" syntax (see https://docs.mongodb.org/manual/reference/mongodb-extended-json/).
  Extended JSON is supported for both reading and writing. This library supports
  all the current extensions, as well as some deprecated legacy extensions.
  The JSON reader accepts both key names with double quotes (as per JSON spec)
  as without quotes.

  @bold(Manual reading and writing)

  For all situations, the methods ToJson, ToBson, Parse and Load can take care
  of reading and writing any kind of JSON and BSON data.

  However, you can use the reading and writing interfaces directly if you want
  for some reason. One reason may be that you want the fastest performance when
  creating BSON payloads, without the overhead of creating a document object
  model in memory.

  For information, see the unit Grijjy.Data.Bson.IO

  @bold(Serialization)

  For even easier reading and writing, you can use serialization to directory
  store a Delphi record or object in JSON or BSON format (or convert it to a
  TgoBsonDocument).

  For information, see the unit Grijjy.Data.Bson.Serialization *)

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.Classes,
  System.SysUtils,
  System.SyncObjs,
  System.Generics.Collections;

type
  { Supported BSON types. As returned by TgoBsonValue.BsonType.
    Tech note: Ordinal values must match BSON spec (http://bsonspec.org) }
  TgoBsonType = (
    { Not a real BSON type. Used to signal the end of a document. }
    EndOfDocument       = $00,

    { A BSON double }
    Double              = $01,

    { A BSON string }
    &String             = $02,

    { A BSON document (see TgoBsonDocument) }
    Document            = $03,

    { A BSON array (see TgoBsonArray) }
    &Array              = $04,

    { BSON binary data (see TgoBsonBinaryData) }
    Binary              = $05,

    { A BSON undefined value (see TgoBsonUndefined) }
    Undefined           = $06,

    { A ObjectId, generally used with MongoDB (see TgoObjectId) }
    ObjectId            = $07,

    { A BSON boolean }
    Boolean             = $08,

    { A BSON DateTime (see TgoBsonDateTime) }
    DateTime            = $09,

    { A BSON null value (see TgoBsonNull) }
    Null                = $0A,

    { A BSON regular expression (see TgoBsonRegularExpression) }
    RegularExpression   = $0B,

    { BSON JavaScript code (see TgoBsonJavaScript) }
    JavaScript          = $0D,

    { A BSON Symbol (see TgoBsonSymbol, deprecated) }
    Symbol              = $0E,

    { BSON JavaScript code with a scope (see TgoBsonJavaScriptWithScope) }
    JavaScriptWithScope = $0F,

    { A BSON 32-bit integer }
    Int32               = $10,

    { A BSON Timestamp (see TgoBsonTimestamp) }
    Timestamp           = $11,

    { A BSON 64-bit integer }
    Int64               = $12,

    { A BSON MaxKey value (see TgoBsonMaxKey) }
    MaxKey              = $7F,

    { A BSON MinKey value (see TgoBsonMinKey) }
    MinKey              = $FF);

type
  { Supported BSON binary sub types.
    As returned by TgoBsonBinaryData.SubType.
    Tech note: Ordinal values must match BSON spec (http://bsonspec.org) }
  TgoBsonBinarySubType = (
    { Binary data in an arbitrary format }
    Binary       = $00,

    { A function }
    &Function    = $01,

    { Obsolete binary type }
    OldBinary    = $02,

    { A UUID/GUID in driver dependent legacy byte order }
    UuidLegacy   = $03,

    { A UUID/GUID in standard network byte order (big endian) }
    UuidStandard = $04,

    { A MD5 hash }
    MD5          = $05,

    { User defined type }
    UserDefined  = $80);

type
  { The output mode of a IgoJsonWriter, as set using TgoJsonWriterSettings. }
  TgoJsonOutputMode = (
    { Outputs strict JSON }
    Strict,

    { Outputs a format that can be used by the MongoDB shell }
    Shell);

type
  { Settings for a IgoJsonWriter }
  TgoJsonWriterSettings = record
  {$REGION 'Internal Declarations'}
  private class var
    FDefault: TgoJsonWriterSettings;
    FShell: TgoJsonWriterSettings;
    FPretty: TgoJsonWriterSettings;
  private
    FPrettyPrint: Boolean;
    FIndent: String;
    FLineBreak: String;
    FOutputMode: TgoJsonOutputMode;
  public
    { @exclude }
    class constructor Create;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a settings record using the default settings:
      * PrettyPrint: False
      * OutputMode: Strict
      * Indent: 2 spaces (not used unless PrettyPrint is set to True later)
      * LineBreak: CR+LF (not used unless PrettyPrint is set to True later)

      Returns:
        The settings }
    class function Create: TgoJsonWriterSettings; overload; static;

    { Creates a settings record:

      Parameters:
        APrettyPrint: whether to use indentation (see Indent) and line breaks
          (see LineBreak).
        AOutputMode: (optional) output mode. Defaults to Strict.

      Returns:
        The settings }
    class function Create(const APrettyPrint: Boolean;
      const AOutputMode: TgoJsonOutputMode = TgoJsonOutputMode.Strict): TgoJsonWriterSettings; overload; static;

    { Creates a settings record:

      Parameters:
        AIndent: the string to use for indentation. Should only contain
          whitespace characters to create valid output.
        ALineBreak: the string to use for line breaks. Should only contain
          whitespace characters to create valid output.
        AOutputMode: (optional) output mode. Defaults to Strict.

      Returns:
        The settings.

      @bold(Note): this constructor sets PrettyPrint to True. }
    class function Create(const AIndent, ALineBreak: String;
      const AOutputMode: TgoJsonOutputMode = TgoJsonOutputMode.Strict): TgoJsonWriterSettings; overload; static;

    { Creates a settings record:

      Parameters:
        AOutputMode: output mode to use.

      Returns:
        The settings

      @bold(Note): this constructor sets PrettyPrint to False. }
    class function Create(const AOutputMode: TgoJsonOutputMode): TgoJsonWriterSettings; overload; static;

    { The default settings:
      * PrettyPrint: False
      * OutputMode: Strict
      * Indent: 2 spaces (not used unless PrettyPrint is set to True later)
      * LineBreak: CR+LF (not used unless PrettyPrint is set to True later) }
    class property Default: TgoJsonWriterSettings read FDefault;

    { "Shell" settings for outputing JSON with MongoDB shell extensions.
      * PrettyPrint: False
      * OutputMode: Shell
      * Indent: 2 spaces (not used unless PrettyPrint is set to True later)
      * LineBreak: CR+LF (not used unless PrettyPrint is set to True later) }
    class property Shell: TgoJsonWriterSettings read FShell;

    { Settings for outputing JSON compliant JSON in a pretty format.
      * PrettyPrint: True
      * OutputMode: Strict
      * Indent: 2 spaces
      * LineBreak: CR+LF }
    class property Pretty: TgoJsonWriterSettings read FPretty;

    { Whether to use indentation (see Indent) and line breaks (see LineBreak).
      Default False. }
    property PrettyPrint: Boolean read FPrettyPrint write FPrettyPrint;

    { String to use for indentation. Should only contain whitespace characters
      to create valid output. Not used unless PrettyPrint is True.
      Defaults to 2 spaces }
    property Indent: String read FIndent write FIndent;

    { String to use for line breaks. Should only contain whitespace characters
      to create valid output. Not used unless PrettyPrint is True.
      Defaults to CR+LF }
    property LineBreak: String read FLineBreak write FLineBreak;

    { Output mode to use.
      Defaults to Strict }
    property OutputMode: TgoJsonOutputMode read FOutputMode write FOutputMode;
  end;

type
  { Represents an ObjectId. This is a 12-byte (96-bit) value that is regularly
    used for (unique) primary keys in MongoDB databases.

    Internally, an ObjectId is composed of:
    * A 4-byte value containing the number of seconds since the Unix epoch.
    * A 3-byte machine identifier
    * A 2-byte process identifier
    * A 3-byte counter, starting from a random value

    This makes ObjectId's fairly unique (but not as unique as GUID's though) }
  TgoObjectId = record
  {$REGION 'Internal Declarations'}
  private class var
    FIncrement: Integer;
    FMachine: Integer;
    FPid: UInt16;
    FInitialized: Boolean;
  private
    function GetIsEmpty: Boolean;
    function GetTimestamp: Integer;
    function GetMachine: Integer;
    function GetPid: UInt16;
    function GetIncrement: Integer;
    function GetCreationTime: TDateTime;
  private
    class procedure Initialize; static;
    class function GetTimestampFromDateTime(const ATimestamp: TDateTime;
      const ATimestampIsUTC: Boolean): Integer; static;
  private
    procedure FromByteArray(const ABytes: TBytes);
  public
    { @exclude }
    class constructor Create;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates an ObjectId from a byte array.

      Parameters:
        ABytes: the array of bytes to use for the ObjectId.
          Must be 12 bytes long.

      Returns:
        The ObjectId.

      Raises:
        EArgumentException if ABytes is not 12 bytes long }
    class function Create(const ABytes: TBytes): TgoObjectId; overload; static;

    { Creates an ObjectId from a byte array.

      Parameters:
        ABytes: the array of bytes to use for the ObjectId.
          Must be 12 bytes long.

      Returns:
        The ObjectId.

      Raises:
        EArgumentException if ABytes is not 12 bytes long }
    class function Create(const ABytes: array of Byte): TgoObjectId; overload; static;

    { Creates an ObjectId from its components.

      Parameters:
        ATimestamp: 32-bit number of seconds since Unix epoch.
        AMachine: 24-bit machine identifier. Must be >= 0 and < $01000000.
        APid: 16-bit process identifier.
        AIncrement: 24-bit counter. Must be >= 0 and < $01000000.

      Returns:
        The ObjectId.

      Raises:
        EArgumentOutOfRangeException if AMachine or AIncrement are out of range. }
    class function Create(const ATimestamp, AMachine: Integer; const APid: UInt16;
      const AIncrement: Integer): TgoObjectId; overload; static;

    { Creates an ObjectId from its components.

      Parameters:
        ATimestamp: the date/time to use as a timestamp.
        ATimestampIsUTC: whether ATimestamp is in universal time.
        AMachine: 24-bit machine identifier. Must be >= 0 and < $01000000.
        APid: 16-bit process identifier.
        AIncrement: 24-bit counter. Must be >= 0 and < $01000000.

      Returns:
        The ObjectId.

      Raises:
        EArgumentOutOfRangeException if AMachine or AIncrement are out of range. }
    class function Create(const ATimestamp: TDateTime;
      const ATimestampIsUTC: Boolean; const AMachine: Integer;
      const APid: UInt16; const AIncrement: Integer): TgoObjectId; overload; static;

    { Creates an ObjectId from its string representation (see ToString).

      Parameters:
        AString: the string representation of the ObjectId. Must contain 24
          hex digits.

      Returns:
        The ObjectId.

      Raises:
        EArgumentException if AString does not contain 24 hex digits.

      @bold(Note): this constructor is equal to the Parse method. }
    class function Create(const AString: String): TgoObjectId; overload; static;

    { Generates a new ObjectId using the current timestamp, machine, process
      and counter settings.

      Returns:
        The newly generated ObjectId.

      @bold(Note): the returned ObjectId is guaranteed to be unique on the
      current system, even if this function is called at the same time from
      the same or other processes on the machine. However, the ObjectId is not
      neccesarily globally unique since another machine with the same hostname
      or computer name can theoretically generate the same Id. }
    class function GenerateNewId: TgoObjectId; overload; static;

    { Generates a new ObjectId using a given timestamp and the current machine,
      process and counter settings.

      Parameters:
        ATimestamp: the date/time to use as a timestamp.
        ATimestampIsUTC: whether ATimestamp is in universal time.

      Returns:
        The newly generated ObjectId.

      @bold(Note): the returned ObjectId is guaranteed to be unique on the
      current system, even if this function is called at the same time from
      the same or other processes on the machine. However, the ObjectId is not
      neccesarily globally unique since another machine with the same hostname
      or computer name can theoretically generate the same Id. }
    class function GenerateNewId(const ATimestamp: TDateTime;
      const ATimestampIsUTC: Boolean): TgoObjectId; overload; static;

    { Generates a new ObjectId using a given timestamp and the current machine,
      process and counter settings.

      Parameters:
        ATimestamp: 32-bit number of seconds since Unix epoch.

      Returns:
        The newly generated ObjectId.

      @bold(Note): the returned ObjectId is guaranteed to be unique on the
      current system, even if this function is called at the same time from
      the same or other processes on the machine. However, the ObjectId is not
      neccesarily globally unique since another machine with the same hostname
      or computer name can theoretically generate the same Id. }
    class function GenerateNewId(const ATimestamp: Integer): TgoObjectId; overload; static;

    { Parses an ObjectId from its string representation (see ToString).

      Parameters:
        AString: the string representation of the ObjectId. Must contain 24
          hex digits.

      Returns:
        The ObjectId.

      Raises:
        EArgumentException if AString does not contain 24 hex digits }
    class function Parse(const AString: String): TgoObjectId; overload; static;

    { Tries to parse an ObjectId from its string representation (see ToString).

      Parameters:
        AString: the string representation of the ObjectId. Must contain 24
          hex digits.
        AObjectId: is set to the parsed ObjectId, or all zeros if AString could
          not be parsed.

      Returns:
        True if AString could be successfully parsed. }
    class function TryParse(const AString: String;
      out AObjectId: TgoObjectId): Boolean; overload; static;

    { Returns an empty ObjectId (with all zeros)

      Returns:
        The empty ObjectId. }
    class function Empty: TgoObjectId; static;

    { Implicitly converts a string to an ObjectId. The string @bold(must)
      contain 24 hex digits. An EArgumentException will be raised if this is not
      the case }
    class operator Implicit(const A: String): TgoObjectId;

    { Implicitly convers an ObjectId to a string }
    class operator Implicit(const A: TgoObjectId): String;

    { Tests 2 ObjectId's for equality }
    class operator Equal(const A, B: TgoObjectId): Boolean; static;

    { Tests 2 ObjectId's for inequality }
    class operator NotEqual(const A, B: TgoObjectId): Boolean; static;

    { Compares 2 ObjectId's using the ">" operator }
    class operator GreaterThan(const A, B: TgoObjectId): Boolean; static;

    { Compares 2 ObjectId's using the ">=" operator }
    class operator GreaterThanOrEqual(const A, B: TgoObjectId): Boolean; static;

    { Compares 2 ObjectId's using the "<" operator }
    class operator LessThan(const A, B: TgoObjectId): Boolean; static;

    { Compares 2 ObjectId's using the "<=" operator }
    class operator LessThanOrEqual(const A, B: TgoObjectId): Boolean; static;

    { Converts the ObjectId to an array of 12 bytes.

      Returns:
        The ObjectId as 12 bytes. }
    function ToByteArray: TBytes; overload;

    { Converts the ObjectId to an array of bytes.

      Parameters:
        ADestination: byte array to store the ObjectId into.
        AOffset: starting offset in ADestination to use.

      Raises:
        EArgumentException if ADestination does not have room enough to store
        (AOffset+12) bytes. }
    procedure ToByteArray(const ADestination: TBytes; const AOffset: Integer); overload;

    { Converts the ObjectId to its string representation. This is a string
      containing 24 hex digits.

      Returns:
        The string representation of the ObjectId. }
    function ToString: String;

    { Compare this ObjectId to another one.

      Parameters:
        AOther: the other ObjectId.

      Returns:
        * -1 if Self < AOther
        * 0 if Self = AOther
        * 1 if Self > AOther }
    function CompareTo(const AOther: TgoObjectId): Integer;

    { Returns True if this ObjectId is empty (all zeros) }
    property IsEmpty: Boolean read GetIsEmpty;

    { Timestamp component of the ObjectId.
      If the 32-bit number of seconds since Unix epoch. }
    property Timestamp: Integer read GetTimestamp;

    { Machine component of the ObjectId.
      Is a 24-bit machine identifier. }
    property Machine: Integer read GetMachine;

    { Process component of the ObjectId.
      Is a 16-bit process identifier. }
    property Pid: UInt16 read GetPid;

    { Counter component of the ObjectId.
      Is a 32-bit increment. }
    property Increment: Integer read GetIncrement;

    { The creation time of the ObjectId, as stored inside its Timestamp
      component. The time is in UTC. }
    property CreationTime: TDateTime read GetCreationTime;
  {$REGION 'Internal Declarations'}
  private
    case Byte of
      0: (FData: array [0..2] of UInt32);
      1: (FBytes: array [0..11] of Byte);
  {$ENDREGION 'Internal Declarations'}
  end;
  PgoObjectId = ^TgoObjectId;

type
  { The base "class" for all BSON values. It is implemented as a record type
    which can hold any type of BSON value. }
  TgoBsonValue = record
  {$REGION 'Internal Declarations'}
  public type
    { @exclude }
    _IValue = interface
    ['{290B24D7-1D64-4F76-93C8-1B9D92658018}']
      function GetBsonType: TgoBsonType;
      function AsBoolean: Boolean;
      function AsInteger: Integer;
      function AsInt64: Int64;
      function AsDouble: Double;
      function AsString: String;
      function AsArray: TArray<TgoBsonValue>;
      function AsByteArray: TBytes;
      function AsGuid: TGUID;
      function AsObjectId: TgoObjectId;

      function ToBoolean(const ADefault: Boolean): Boolean;
      function ToDouble(const ADefault: Double): Double;
      function ToInteger(const ADefault: Integer): Integer;
      function ToInt64(const ADefault: Int64): Int64;
      function ToString(const ADefault: String): String;
      function ToLocalTime: TDateTime;
      function ToUniversalTime: TDateTime;
      function ToByteArray: TBytes;
      function ToGuid: TGUID;
      function ToObjectId: TgoObjectId;

      function Equals(const AOther: _IValue): Boolean;

      function Clone: _IValue;
      function DeepClone: _IValue;

      property BsonType: TgoBsonType read GetBsonType;
    end;
  private
    FImpl: _IValue;
    function GetBsonType: TgoBsonType; inline;
    function GetIsBoolean: Boolean; inline;
    function GetIsBsonArray: Boolean; inline;
    function GetIsBsonBinaryData: Boolean; inline;
    function GetIsBsonDateTime: Boolean; inline;
    function GetIsBsonDocument: Boolean; inline;
    function GetIsBsonJavaScript: Boolean; inline;
    function GetIsBsonJavaScriptWithScope: Boolean; inline;
    function GetIsBsonMaxKey: Boolean; inline;
    function GetIsBsonMinKey: Boolean; inline;
    function GetIsBsonNull: Boolean; inline;
    function GetIsBsonRegularExpression: Boolean; inline;
    function GetIsBsonSymbol: Boolean; inline;
    function GetIsBsonTimestamp: Boolean; inline;
    function GetIsBsonUndefined: Boolean; inline;
    function GetIsDateTime: Boolean; inline;
    function GetIsDouble: Boolean; inline;
    function GetIsGuid: Boolean; inline;
    function GetIsInt32: Boolean; inline;
    function GetIsInt64: Boolean; inline;
    function GetIsNumeric: Boolean; inline;
    function GetIsObjectId: Boolean; inline;
    function GetIsString: Boolean; inline;
  public
    { @exclude }
    class operator Implicit(const A: TgoBsonValue): Int8; static;
    { @exclude }
    class operator Implicit(const A: TgoBsonValue): UInt8; static;
    { @exclude }
    class operator Implicit(const A: TgoBsonValue): Int16; static;
    { @exclude }
    class operator Implicit(const A: TgoBsonValue): UInt16; static;
    { @exclude }
    class operator Implicit(const A: TgoBsonValue): UInt32; static;
    { @exclude }
    class operator Implicit(const A: TgoBsonValue): Single; static;

    { @exclude }
    class operator Implicit(const A: UInt32): TgoBsonValue; static;
    { @exclude }
    class operator Implicit(const A: UInt64): TgoBsonValue; static;
    { @exclude }
    class operator Implicit(const A: Single): TgoBsonValue; static;

    { @exclude }
    property _Impl: _IValue read FImpl write FImpl;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a BSON value by paring a JSON string.

      Parameters:
        AJson: the JSON string to parse.

      Returns:
        The BSON value

      Raises:
        EgoJsonParserError or EInvalidOperation on parse errors }
    class function Parse(const AJson: String): TgoBsonValue; static;

    { Tries to parse a JSON string to a BSON value.

      Parameters:
        AJson: the JSON string to parse.
        AArray: is set to the parsed JSON on success.

      Returns:
        True if the JSON string could be successfully parsed. }
    class function TryParse(const AJson: String; out AValue: TgoBsonValue): Boolean; static;

    { Creates a BSON value from a BSON byte array.

      Parameters:
        ABson: the BSON byte array to load.

      Returns:
        The BSON value

      Raises:
        EInvalidOperation if BSON data is invalid }
    class function Load(const ABson: TBytes): TgoBsonValue; static;

    { Tries to load a BSON value from a BSON byte array.

      Parameters:
        ABson: the BSON byte array to load.
        AValue: is set to the loaded BSON on success.

      Returns:
        True if the BSON value could be successfully loaded. }
    class function TryLoad(const ABson: TBytes; out AValue: TgoBsonValue): Boolean; static;

    { Loads a BSON value from a JSON file.

      Parameters:
        AFilename: the name of the JSON file

      Returns:
        The BSON value

      Raises:
        EgoJsonParserError or EInvalidOperation on parse errors }
    class function LoadFromJsonFile(const AFilename: String): TgoBsonValue; static;

    { Loads a BSON value from a JSON stream.

      Parameters:
        AStream: the JSON stream

      Returns:
        The BSON value

      Raises:
        EgoJsonParserError or EInvalidOperation on parse errors }
    class function LoadFromJsonStream(const AStream: TStream): TgoBsonValue; static;

    { Loads a BSON value from a BSON file.

      Parameters:
        AFilename: the name of the BSON file

      Returns:
        The BSON value

      Raises:
        EInvalidOperation when the BSON file is invalid }
    class function LoadFromBsonFile(const AFilename: String): TgoBsonValue; static;

    { Loads a BSON value from a BSON stream.

      Parameters:
        AStream: the BSON stream

      Returns:
        The BSON value

      Raises:
        EInvalidOperation when the BSON file is invalid }
    class function LoadFromBsonStream(const AStream: TStream): TgoBsonValue; static;

    { Saves the BSON value to a JSON file.

      Parameters:
        AFilename: the name of the JSON file. }
    procedure SaveToJsonFile(const AFilename: String); overload;

    { Saves the BSON value to a JSON file, using specified settings.

      Parameters:
        AFilename: the name of the JSON file.
        ASettings: the output settings to use, such as pretty-printing and
          Strict vs Shell mode. }
    procedure SaveToJsonFile(const AFilename: String;
      const ASettings: TgoJsonWriterSettings); overload;

    { Saves the BSON value to a JSON stream.

      Parameters:
        AStream: the JSON stream }
    procedure SaveToJsonStream(const AStream: TStream); overload;

    { Saves the BSON value to a JSON stream.

      Parameters:
        AStream: the JSON stream
        ASettings: the output settings to use, such as pretty-printing and
          Strict vs Shell mode. }
    procedure SaveToJsonStream(const AStream: TStream;
      const ASettings: TgoJsonWriterSettings); overload;

    { Saves the BSON value to a BSON file.

      Parameters:
        AFilename: the name of the BSON file. }
    procedure SaveToBsonFile(const AFilename: String);

    { Saves the BSON value to a BSON stream.

      Parameters:
        AStream: the BSON stream }
    procedure SaveToBsonStream(const AStream: TStream);

    { Implicitly converts a Boolean to a BSON value }
    class operator Implicit(const A: Boolean): TgoBsonValue; static;

    { Implicitly converts an Integer to a BSON value }
    class operator Implicit(const A: Integer): TgoBsonValue; static;

    { Implicitly converts an Int64 to a BSON value }
    class operator Implicit(const A: Int64): TgoBsonValue; static;

    { Implicitly converts a Double to a BSON value }
    class operator Implicit(const A: Double): TgoBsonValue; static;

    { Implicitly converts an Extended to a BSON value }
    class operator Implicit(const A: Extended): TgoBsonValue; static;

    { Implicitly converts a TDateTime a BSON value of type TgoBsonDateTime.
      The TDateTime value @bold(must) be UTC format. }
    class operator Implicit(const A: TDateTime): TgoBsonValue; static;

    { Implicitly converts a String to a BSON value }
    class operator Implicit(const A: String): TgoBsonValue; static;

    { Implicitly converts an array of bytes to a BSON value of type
      TgoBsonBinaryData with sub type Binary. }
    class operator Implicit(const A: TBytes): TgoBsonValue; static;

    { Implicitly converts a GUID to a BSON value of type TgoBsonBinaryData with
      sub type UuidStandard. }
    class operator Implicit(const A: TGUID): TgoBsonValue; static;

    { Implicitly converts an ObjectId to a BSON value }
    class operator Implicit(const A: TgoObjectId): TgoBsonValue; static;

    { Tries to implicitly convert a BSON value to a Boolean.
      Depending on the BsonType, one of the following will be returned:
      * Boolean: the value
      * Double: True if the value isn't 0 or NaN
      * Integer: True if the value isn't 0
      * Null: False
      * String: True if the value isn't an empty string
      * Otherwise: True }
    class operator Implicit(const A: TgoBsonValue): Boolean; static;

    { Tries to implicitly convert a BSON value to an Integer.
      Depending on the BsonType, one of the following will be returned:
      * Boolean: 0 if False, 1 if True
      * Double: truncated value
      * Integer: the value
      * String: String converted to Integer, if possible
      * Otherwise: 0 }
    class operator Implicit(const A: TgoBsonValue): Integer; static;

    { Tries to implicitly convert a BSON value to an Int64.
      Depending on the BsonType, one of the following will be returned:
      * Boolean: 0 if False, 1 if True
      * Double: truncated value
      * Integer: the value
      * String: String converted to Int64, if possible
      * Otherwise: 0 }
    class operator Implicit(const A: TgoBsonValue): Int64; static;

    { Tries to implicitly convert a BSON value to an UInt64.
      Depending on the BsonType, one of the following will be returned:
      * Boolean: 0 if False, 1 if True
      * Double: truncated value
      * Integer: the value
      * String: String converted to UInt64, if possible
      * Otherwise: 0 }
    class operator Implicit(const A: TgoBsonValue): UInt64; static;

    { Tries to implicitly convert a BSON value to an Double.
      Depending on the BsonType, one of the following will be returned:
      * Boolean: 0 if False, 1 if True
      * Double: the value
      * Integer: the value
      * String: String (in US format) converted to Double, if possible
      * Otherwise: 0 }
    class operator Implicit(const A: TgoBsonValue): Double; static;

    { Tries to implicitly convert a BSON value to an Extended.
      Depending on the BsonType, one of the following will be returned:
      * Boolean: 0 if False, 1 if True
      * Double: the value
      * Integer: the value
      * String: String (in US format) converted to Double, if possible
      * Otherwise: 0 }
    class operator Implicit(const A: TgoBsonValue): Extended; static;

    { Tries to implicitly convert a BSON value to a TDateTime in UTC format.
      Depending on the BsonType, one of the following will be returned:
      * DateTime: the value in UTC format
      * Otherwise: 0

      @bold(Note): see ToLocalTime and ToUniversalTime for more control over
      the output. }
    class operator Implicit(const A: TgoBsonValue): TDateTime; static;

    { Tries to implicitly convert a BSON value to a String.
      Depending on the BsonType, one of the following will be returned:
      * Boolean: 'false' or 'true'
      * Double: the value converted to a String (in US format)
      * Integer: the value converted to an Integer
      * String: the value
      * DateTime: UTC value in ISO8601 format
      * ObjectId: string representation of the ObjectId
      * Null: 'null'
      * Undefined: 'undefined'
      * MinKey: 'MinKey'
      * MaxKey: 'MaxKey'
      * Symbol: name of the symbol
      * Otherwise: '' (empty string) }
    class operator Implicit(const A: TgoBsonValue): String; static;

    { Tries to implicitly convert a BSON value to a byte array.
      Depending on the BsonType, one of the following will be returned:
      * Binary: the value
      * Otherwise: nil (empty array) }
    class operator Implicit(const A: TgoBsonValue): TBytes; static;

    { Tries to implicitly convert a BSON value to a GUID.
      Depending on the BsonType, one of the following will be returned:
      * Binary of sub type UuidLegacy or UuidStandard: the value
      * Otherwise: TGUID.Empty }
    class operator Implicit(const A: TgoBsonValue): TGUID; static;

    { Tries to implicitly convert a BSON value to an ObjectId.
      Depending on the BsonType, one of the following will be returned:
      * ObjectId: the value
      * Otherwise: TgoObjectId.Empty }
    class operator Implicit(const A: TgoBsonValue): TgoObjectId; static;

    { Tries to implicitly convert a BSON value to a TDateTime in local time.
      Depending on the BsonType, one of the following will be returned:
      * DateTime: the value in local time
      * Otherwise: 0 }
    function ToLocalTime: TDateTime; inline;

    { Tries to implicitly convert a BSON value to a TDateTime in universal time.
      Depending on the BsonType, one of the following will be returned:
      * DateTime: the value in universal time (UTC)
      * Otherwise: 0 }
    function ToUniversalTime: TDateTime; inline;

    { Tests 2 BSON values for equality. BSON values are equal if their types
      and contents match exactly. }
    class operator Equal(const A, B: TgoBsonValue): Boolean; static;

    { Tests 2 BSON values for inequality }
    class operator NotEqual(const A, B: TgoBsonValue): Boolean; static;

    { Checks if the BSON value has been assigned.

      Returns:
        True if value hasn't been assigned yet.

      @bold(Note): does @bold(not) return True if the value is a NULL value
      (see IsBsonNull/AsBsonNull) }
    function IsNil: Boolean; inline;

    { Unassigns the BSON value (like setting an object to nil).
      IsNil will return True afterwards. }
    procedure SetNil; inline;

    { Tries to convert the value to a Boolean.

      Parameters:
        ADefault: (optional) value to return if value cannot be converted.
          Defaults to False. }
    function ToBoolean(const ADefault: Boolean = False): Boolean; inline;

    { Tries to convert the value to a 32-bit integer.

      Parameters:
        ADefault: (optional) value to return if value cannot be converted.
          Defaults to 0. }
    function ToInteger(const ADefault: Integer = 0): Integer; inline;

    { Tries to convert the value to a 64-bit integer.

      Parameters:
        ADefault: (optional) value to return if value cannot be converted.
          Defaults to 0. }
    function ToInt64(const ADefault: Int64 = 0): Int64; inline;

    { Tries to convert the value to a floating-point number.

      Parameters:
        ADefault: (optional) value to return if value cannot be converted.
          Defaults to 0.0. }
    function ToDouble(const ADefault: Double = 0): Double; inline;

    { Tries to convert the value to a string.

      Parameters:
        ADefault: (optional) value to return if value cannot be converted.
          Defaults to ''. }
    function ToString(const ADefault: String = ''): String; inline;

    { Tries to convert the value to a GUID.
      Returns an empty GUID if the value cannot be converted. }
    function ToGuid: TGUID; inline;

    { Tries to convert the value to an ObjectId.
      Returns an empty ObjectId if the value cannot be converted. }
    function ToObjectId: TgoObjectId; inline;

    { Returns the value as a Boolean.

      Raises:
        EIntfCastError if this value isn't a Boolean }
    function AsBoolean: Boolean; inline;

    { Returns the value as a 32-bit integer.

      Raises:
        EIntfCastError if this value isn't a 32-bit integer }
    function AsInteger: Integer; inline;

    { Returns the value as a 64-bit integer.

      Raises:
        EIntfCastError if this value isn't a 64-bit integer }
    function AsInt64: Int64; inline;

    { Returns the value as a Double.

      Raises:
        EIntfCastError if this value isn't a Double }
    function AsDouble: Double; inline;

    { Returns the value as a String.

      Raises:
        EIntfCastError if this value isn't a String }
    function AsString: String; inline;

    { Returns the value as a Delphi array of BSON values.

      Raises:
        EIntfCastError if this value isn't a BSON array }
    function AsArray: TArray<TgoBsonValue>; inline;

    { Returns the value as an array of bytes.

      Raises:
        EIntfCastError if this value isn't a Binary value }
    function AsByteArray: TBytes; inline;

    { Returns the value as a GUID.

      Raises:
        EIntfCastError if this value isn't a Binary value of sub type
        UuidLegacy or UuidStandard. }
    function AsGuid: TGUID; inline;

    { Returns the value as an ObjectId.

      Raises:
        EIntfCastError if this value isn't an ObjectId }
    function AsObjectId: TgoObjectId; inline;

    { Creates shallow clone of the value.

      Returns:
        The shallow clone

      @bold(Note): a shallow clone copies the value, but not any sub-values.
      For example, if the value is an array, then the array reference is copied,
      but not the individual elements. }
    function Clone: TgoBsonValue; inline;

    { Creates deep clone of the value.

      Returns:
        The deep clone

      @bold(Note): a deep clone copies the value and any sub-values it may hold.
      For example, if the value is an array, then the array reference is copied,
      and its individual elements are copied as well. Any sub-values of those
      elements are also copied, etc... }
    function DeepClone: TgoBsonValue; inline;

    { Saves the value to a BSON-compliant byte stream.

      Returns:
        The BSON byte stream. }
    function ToBson: TBytes; inline;

    { Saves the value to a string in JSON format.

      Returns:
        The value in JSON format.

      @bold(Note): the value is saved using the default writer settings. That
      is, without any pretty printing, and in Strict mode. Use the other overload
      of this function to specify output settings. }
    function ToJson: String; overload; inline;

    { Saves the value to a string in JSON format, using specified settings.

      Parameters:
        ASettings: the output settings to use, such as pretty-printing and
          Strict vs Shell mode.

      Returns:
        The value in JSON format. }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The type of this value. }
    property BsonType: TgoBsonType read GetBsonType;

    { Whether this value represents a Boolean. }
    property IsBoolean: Boolean read GetIsBoolean;

    { Whether this value represents a BSON array. }
    property IsBsonArray: Boolean read GetIsBsonArray;

    { Whether this value represents a BSON binary value. }
    property IsBsonBinaryData: Boolean read GetIsBsonBinaryData;

    { Whether this value represents a BSON DateTime. }
    property IsBsonDateTime: Boolean read GetIsBsonDateTime;

    { Whether this value represents a BSON Document (aka Dictionary or Object). }
    property IsBsonDocument: Boolean read GetIsBsonDocument;

    { Whether this value represents a JavaScript script. }
    property IsBsonJavaScript: Boolean read GetIsBsonJavaScript;

    { Whether this value represents a JavaScript script with scope. }
    property IsBsonJavaScriptWithScope: Boolean read GetIsBsonJavaScriptWithScope;

    { Whether this value represents a BSON MaxKey value. }
    property IsBsonMaxKey: Boolean read GetIsBsonMaxKey;

    { Whether this value represents a BSON MinKey value. }
    property IsBsonMinKey: Boolean read GetIsBsonMinKey;

    { Whether this value represents a BSON Null value. }
    property IsBsonNull: Boolean read GetIsBsonNull;

    { Whether this value represents a regular expression. }
    property IsBsonRegularExpression: Boolean read GetIsBsonRegularExpression;

    { Whether this value represents a (deprectated) BSON symbol. }
    property IsBsonSymbol: Boolean read GetIsBsonSymbol;

    { Whether this value represents a BSON timestamp. }
    property IsBsonTimestamp: Boolean read GetIsBsonTimestamp;

    { Whether this value represents a BSON Undefined value. }
    property IsBsonUndefined: Boolean read GetIsBsonUndefined;

    { Whether this value represents a DateTime value. }
    property IsDateTime: Boolean read GetIsDateTime;

    { Whether this value represents a Double. }
    property IsDouble: Boolean read GetIsDouble;

    { Whether this value represents a GUID. }
    property IsGuid: Boolean read GetIsGuid;

    { Whether this value represents a 32-bit integer. }
    property IsInt32: Boolean read GetIsInt32;

    { Whether this value represents a 64-bit integer. }
    property IsInt64: Boolean read GetIsInt64;

    { Whether this value represents a numeric value (Integer or Double). }
    property IsNumeric: Boolean read GetIsNumeric;

    { Whether this value represents an ObjectId. }
    property IsObjectId: Boolean read GetIsObjectId;

    { Whether this value represents a String. }
    property IsString: Boolean read GetIsString;
  end;

type
  { An array of other BSON values }
  TgoBsonArray = record
  {$REGION 'Internal Declarations'}
  public type
    { @exclude }
    _IArray = interface(TgoBsonValue._IValue)
    ['{968AA4B3-4569-4676-B85D-0DF953DC6D26}']
      function GetCount: Integer;
      procedure GetItem(const AIndex: Integer; out AValue: TgoBsonValue._IValue);
      procedure SetItem(const AIndex: Integer; const AValue: TgoBsonValue._IValue);

      procedure Add(const AValue: TgoBsonValue._IValue);
      procedure AddRange(const AValues: array of TgoBsonValue); overload;
      procedure AddRange(const AValues: TArray<TgoBsonValue>); overload;
      procedure AddRange(const AValues: TgoBsonArray); overload;
      procedure Delete(const AIndex: Integer);
      function Remove(const AValue: TgoBsonValue): Boolean;
      procedure Clear;
      function Contains(const AValue: TgoBsonValue): Boolean;
      function IndexOf(const AValue: TgoBsonValue): Integer;

      property Count: Integer read GetCount;
    end;
  private type
    TEnumerator = record
    private
      FImpl: _IArray;
      FIndex: Integer;
      FHigh: Integer;
      function GetCurrent: TgoBsonValue;
    public
      constructor Create(const AImpl: _IArray);
      function MoveNext: Boolean;

      property Current: TgoBsonValue read GetCurrent;
    end;
  private
    FImpl: _IArray;
    function GetCount: Integer; inline;
    function GetItem(const AIndex: Integer): TgoBsonValue; inline;
    procedure SetItem(const AIndex: Integer; const AValue: TgoBsonValue); inline;
  public
    { @exclude }
    property _Impl: _IArray read FImpl;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates an empty BSON array.

      Parameters:
        ACapacity: (optional) initial capacity of the array. You can reduce
          memory reallocations if you know in advance the (approximate) number
          of values the array is going to hold.

      Returns:
        The empty BSON array }
    class function Create(const ACapacity: Integer = 0): TgoBsonArray; overload; static;

    { Creates a BSON array an populates it with a Delphi array of values.

      Parameters:
        AValues: the Delphi array of values to populate the BSON array with.

      Returns:
        The BSON array

      Raises:
        EArgumentNilException if any of the values in the array has not been
        assigned (if their IsNil returns True for those). }
    class function Create(const AValues: array of TgoBsonValue): TgoBsonArray; overload; static;

    { Creates a BSON array an populates it with a Delphi array of values.

      Parameters:
        AValues: the Delphi array of values to populate the BSON array with.

      Returns:
        The BSON array

      Raises:
        EArgumentNilException if any of the values in the array has not been
        assigned (if their IsNil returns True for those). }
    class function Create(const AValues: TArray<TgoBsonValue>): TgoBsonArray; overload; static;

    { See TgoBsonValue.Parse }
    class function Parse(const AJson: String): TgoBsonArray; static;

    { See TgoBsonValue.TryParse }
    class function TryParse(const AJson: String; out AArray: TgoBsonArray): Boolean; static;

    { See TgoBsonValue.Load }
    class function Load(const ABson: TBytes): TgoBsonArray; static;

    { See TgoBsonValue.TryLoad }
    class function TryLoad(const ABson: TBytes; out AArray: TgoBsonArray): Boolean; static;

    { See TgoBsonValue.LoadFromJsonFile }
    class function LoadFromJsonFile(const AFilename: String): TgoBsonArray; static;

    { See TgoBsonValue.LoadFromJsonStream }
    class function LoadFromJsonStream(const AStream: TStream): TgoBsonArray; static;

    { See TgoBsonValue.LoadFromBsonFile }
    class function LoadFromBsonFile(const AFilename: String): TgoBsonArray; static;

    { See TgoBsonValue.LoadFromBsonStream }
    class function LoadFromBsonStream(const AStream: TStream): TgoBsonArray; static;

    { See TgoBsonValue.SaveToJsonFile }
    procedure SaveToJsonFile(const AFilename: String); overload;

    { See TgoBsonValue.SaveToJsonFile }
    procedure SaveToJsonFile(const AFilename: String;
      const ASettings: TgoJsonWriterSettings); overload;

    { See TgoBsonValue.SaveToJsonStream }
    procedure SaveToJsonStream(const AStream: TStream); overload;

    { See TgoBsonValue.SaveToJsonStream }
    procedure SaveToJsonStream(const AStream: TStream;
      const ASettings: TgoJsonWriterSettings); overload;

    { See TgoBsonValue.SaveToBsonFile }
    procedure SaveToBsonFile(const AFilename: String);

    { See TgoBsonValue.SaveToBsonStream }
    procedure SaveToBsonStream(const AStream: TStream);

    { Implicitly casts a BSON array to a BSON value. }
    class operator Implicit(const A: TgoBsonArray): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonArray): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonArray): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.SetNil }
    procedure SetNil; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonArray; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonArray; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { Adds a value to the array.

      Parameters:
        AValue: the value to add.

      Returns:
        The array itself, so you can use it for chaining.

      Raises:
        EArgumentNilException if AValue has not been assigned (if IsNil returns
        True). }
    function Add(const AValue: TgoBsonValue): TgoBsonArray; inline;

    { Adds a range of values to the array.

      Parameters:
        AValues: the Delphi array of values to add to the array.


      Returns:
        The array itself, so you can use it for chaining.

      Raises:
        EArgumentNilException if any of the values in the array has not been
        assigned (if their IsNil returns True for those). }
    function AddRange(const AValues: array of TgoBsonValue): TgoBsonArray; overload;

    { Adds a range of values to the array.

      Parameters:
        AValues: the Delphi array of values to add to the array.


      Returns:
        The array itself, so you can use it for chaining.

      Raises:
        EArgumentNilException if any of the values in the array has not been
        assigned (if their IsNil returns True for those). }
    function AddRange(const AValues: TArray<TgoBsonValue>): TgoBsonArray; overload; inline;

    { Adds a range of values from another BSON array to this array.

      Parameters:
        AValues: the BSON array of values to add to this array.


      Returns:
        The array itself, so you can use it for chaining.

      Raises:
        EArgumentNilException if AValues has not been assigned or any of the
        values in the array has not been assigned (if their IsNil returns True
        for those). }
    function AddRange(const AValues: TgoBsonArray): TgoBsonArray; overload; inline;

    { Deletes a value from the array by index.

      Parameters:
        AIndex: the index of the value to delete.

      Raises:
        EArgumentOutOfRangeException in AIndex is out of bounds. }
    procedure Delete(const AIndex: Integer); inline;

    { Removes a value from the array.

      Parameters:
        AValue: the value to remove.

      Returns:
        True if the value was removed. False if the array does not contain the
        value.

      Raises:
        EArgumentNilException if AValue has not been assigned (if IsNil returns
        True).

      @bold(Note): the Equal operator of AValue is used to check if the value
      is in the array. }
    function Remove(const AValue: TgoBsonValue): Boolean; inline;

    { Clears the array.

      Returns:
        The array itself, so you can use it for chaining. }
    function Clear: TgoBsonArray; inline;

    { Checks if the array contains a given value.

      Parameters:
        AValue: the value to look for.

      Returns:
        True if the array contains the value.

      @bold(Note): the Equal operator of AValue is used to check if the value
      is in the array. }
    function Contains(const AValue: TgoBsonValue): Boolean; inline;

    { Returns the index of a value in the array.

      Parameters:
        AValue: the value to look for.

      Returns:
        The index of the value in the array, or -1 if the array does not contain
        the value.

      @bold(Note): the Equal operator of AValue is used to check if the value
      is in the array. }
    function IndexOf(const AValue: TgoBsonValue): Integer; inline;

    { Returns the values in the array as a Delphi array of values.

      Returns:
        The Delphi array of BSON values }
    function ToArray: TArray<TgoBsonValue>; inline;

    { Allow <tt>for..in</tt> enumeration of the values in the array. }
    function GetEnumerator: TEnumerator; inline;

    { Number of items in the array }
    property Count: Integer read GetCount;

    { The items in the array.

      Parameters:
        AIndex: the index of the item to get or set.

      Raises:
        EArgumentOutOfRangeException in AIndex is out of bounds.
        EArgumentNilException when setting the item and AValue is not assigned
        (IsNil returns True) }
    property Items[const AIndex: Integer]: TgoBsonValue read GetItem write SetItem; default;
  end;

type
  { An element in a TgoBsonDocument }
  TgoBsonElement = record
  {$REGION 'Internal Declarations'}
  private
    FName: String;
    FImpl: TgoBsonValue._IValue;
    function GetValue: TgoBsonValue; inline;
  public
    { @exclude }
    property _Impl: TgoBsonValue._IValue read FImpl;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a document element.

      Parameters:
        AName: the name of the element.
        AValue: the value of the element.

      Raises:
        EArgumentNilException if AValue has not been assigned (if IsNil returns
        True). }
    class function Create(const AName: String; const AValue: TgoBsonValue): TgoBsonElement; static;

    { Tests 2 document elements for equality. Elements are equal if both their
      names (case-sensitive) and values are equal. }
    class operator Equal(const A, B: TgoBsonElement): Boolean; static;

    { Tests 2 document elements for inequality. }
    class operator NotEqual(const A, B: TgoBsonElement): Boolean; inline; static;

    { Creates a shallow clone of the element. The returned element will contain
      a reference to the existing value.

      Returns:
        The clone }
    function Clone: TgoBsonElement;

    { Creates a deep clone of the element. The returned element will contain
      a deep clone of the existing value.

      Returns:
        The deep clone }
    function DeepClone: TgoBsonElement;

    { Name of the element }
    property Name: String read FName;

    { Value of the element }
    property Value: TgoBsonValue read GetValue;
  end;

type
  { A BSON document. A BSON document contains key/value pairs, where the key is
    a String and the value can be any BSON value. It is similar to a Delphi
    dictionary or a JSON object. However, unlike Delphi dictionaries, a
    documents maintains insertion order and you can access values both by name
    and by index. }
  TgoBsonDocument = record
  {$REGION 'Internal Declarations'}
  public type
    { @exclude }
    _IDocument = interface(TgoBsonValue._IValue)
    ['{9E13B024-904D-44F6-BE16-33D81A0F057F}']
      function GetCount: Integer;
      function GetAllowDuplicateNames: Boolean;
      procedure SetAllowDuplicateNames(const Value: Boolean);
      function GetElement(const AIndex: Integer): TgoBsonElement;
      procedure GetValue(const AIndex: Integer; out AValue: TgoBsonValue._IValue);
      procedure SetValue(const AIndex: Integer; const AValue: TgoBsonValue._IValue);
      procedure GetValueByName(const AName: String; out AValue: TgoBsonValue._IValue);
      procedure SetValueByName(const AName: String; const AValue: TgoBsonValue._IValue);

      procedure Add(const AName: String; const AValue: TgoBsonValue._IValue);
      procedure Get(const AName: String; const ADefault: TgoBsonValue._IValue;
        out AValue: TgoBsonValue._IValue);
      function IndexOfName(const AName: String): Integer;
      function Contains(const AName: String): Boolean;
      function ContainsValue(const AValue: TgoBsonValue): Boolean;
      function TryGetElement(const AName: String; out AElement: TgoBsonElement): Boolean;
      function TryGetValue(const AName: String; out AValue: TgoBsonValue._IValue): Boolean;
      procedure Remove(const AName: String);
      procedure Delete(const AIndex: Integer);
      procedure Clear;
      procedure Merge(const AOtherDocument: TgoBsonDocument;
        const AOverwriteExistingElements: Boolean);
      function ToArray: TArray<TgoBsonElement>;

      property AllowDuplicateNames: Boolean read GetAllowDuplicateNames write SetAllowDuplicateNames;
      property Count: Integer read GetCount;
      property Elements[const AIndex: Integer]: TgoBsonElement read GetElement;
    end;
  private type
    TEnumerator = record
    private
      FImpl: _IDocument;
      FIndex: Integer;
      FHigh: Integer;
      function GetCurrent: TgoBsonElement;
    public
      constructor Create(const AImpl: _IDocument);
      function MoveNext: Boolean;

      property Current: TgoBsonElement read GetCurrent;
    end;
  private
    FImpl: _IDocument;
    function GetCount: Integer; inline;
    function GetElement(const AIndex: Integer): TgoBsonElement; inline;
    function GetValue(const AIndex: Integer): TgoBsonValue; inline;
    procedure SetValue(const AIndex: Integer; const AValue: TgoBsonValue); inline;
    function GetValueByName(const AName: String): TgoBsonValue; inline;
    procedure SetValueByName(const AName: String; const AValue: TgoBsonValue); inline;
    function GetAllowDuplicateNames: Boolean; inline;
    procedure SetAllowDuplicateNames(const AValue: Boolean); inline;
  public
    { @exclude }
    property _Impl: _IDocument read FImpl;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates an empty BSON document.

      Returns:
        The empty BSON document }
    class function Create: TgoBsonDocument; overload; static;

    { Creates an empty BSON document.

      Parameters:
        AAllowDuplicateNames: whether to allow duplicate names in the document.
          This should generally be False.

      Returns:
        The empty BSON document }
    class function Create(const AAllowDuplicateNames: Boolean): TgoBsonDocument; overload; static;

    { Creates a BSON document with a single element.

      Parameters:
        AElement: the element to add to the document.

      Returns:
        The BSON document

      Raises:
        EArgumentNilException if AElement.Value has not been assigned (if IsNil
        returns True) }
    class function Create(const AElement: TgoBsonElement): TgoBsonDocument; overload; static;

    { Creates a BSON document with a single element.

      Parameters:
        AName: the name of the element to add to the document.
        AValue: the value of the element.

      Returns:
        The BSON document

      Raises:
        EArgumentNilException if AValue has not been assigned (if IsNil returns
        True) }
    class function Create(const AName: String; const AValue: TgoBsonValue): TgoBsonDocument; overload; static;

    { See TgoBsonValue.Parse }
    class function Parse(const AJson: String; AllowDuplicateNames : Boolean = false): TgoBsonDocument; static;

    { See TgoBsonValue.TryParse }
    class function TryParse(const AJson: String; out ADocument: TgoBsonDocument; AllowDuplicateNames : Boolean = false): Boolean; static;

    { See TgoBsonValue.Load }
    class function Load(const ABson: TBytes): TgoBsonDocument; static;

    { See TgoBsonValue.TryLoad }
    class function TryLoad(const ABson: TBytes; out ADocument: TgoBsonDocument): Boolean; static;

    { See TgoBsonValue.LoadFromJsonFile }
    class function LoadFromJsonFile(const AFilename: String): TgoBsonDocument; static;

    { See TgoBsonValue.LoadFromJsonStream }
    class function LoadFromJsonStream(const AStream: TStream): TgoBsonDocument; static;

    { See TgoBsonValue.LoadFromBsonFile }
    class function LoadFromBsonFile(const AFilename: String): TgoBsonDocument; static;

    { See TgoBsonValue.LoadFromBsonStream }
    class function LoadFromBsonStream(const AStream: TStream): TgoBsonDocument; static;

    { See TgoBsonValue.SaveToJsonFile }
    procedure SaveToJsonFile(const AFilename: String); overload;

    { See TgoBsonValue.SaveToJsonFile }
    procedure SaveToJsonFile(const AFilename: String;
      const ASettings: TgoJsonWriterSettings); overload;

    { See TgoBsonValue.SaveToJsonStream }
    procedure SaveToJsonStream(const AStream: TStream); overload;

    { See TgoBsonValue.SaveToJsonStream }
    procedure SaveToJsonStream(const AStream: TStream;
      const ASettings: TgoJsonWriterSettings); overload;

    { See TgoBsonValue.SaveToBsonFile }
    procedure SaveToBsonFile(const AFilename: String);

    { See TgoBsonValue.SaveToBsonStream }
    procedure SaveToBsonStream(const AStream: TStream);

    { Implicitly casts a BSON document to a BSON value. }
    class operator Implicit(const A: TgoBsonDocument): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonDocument): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonDocument): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.SetNil }
    procedure SetNil; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonDocument; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonDocument; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { Adds an element to the document.

      Parameters:
        AName: the name of the element to add to the document.
        AValue: the value of the element.

      Returns:
        The document itself, so you can use it for chaining.

      Raises:
        EArgumentNilException if AValue has not been assigned (IsNil returns
          True).
        EInvalidOperation if AllowDuplicateNames = False and document already
          contains element with given name.

      @bold(Note): Names are case-sensitive }
    function Add(const AName: String; const AValue: TgoBsonValue): TgoBsonDocument; overload; inline;

    { Adds an element to the document.

      Parameters:
        AElement: the element to add to the document.

      Returns:
        The document itself, so you can use it for chaining.

      Raises:
        EArgumentNilException if AElement.Value has not been assigned (IsNil
          returns True).
        EInvalidOperation if AllowDuplicateNames = False and document already
          contains element with given name.

      @bold(Note): Names are case-sensitive }
    function Add(const AElement: TgoBsonElement): TgoBsonDocument; overload; inline;

    { Gets a value from the document by name, or a default value if the document
      does not contain an element with the given name.

      Parameters:
        AName: the name of the value to get.
        ADefault: the default value to return in case the document does not
          contain an element named AName.

      Returns:
        The value associated with AName, or ADefault in case the document does
        not contain an element named AName. }
    function Get(const AName: String; const ADefault: TgoBsonValue): TgoBsonValue;

    { Returns the index of the element with a given name.

      Parameters:
        AName: the name of the element to find.

      Returns:
        The index of the element, or -1 of the document does not contain an
        element with the given name.

      @bold(Note): Names are case-sensitive }
    function IndexOfName(const AName: String): Integer; inline;

    { Checks whether the document contains an element with a given name.

      Parameters:
        AName: the name of the element to find.

      Returns:
        True if the document contains an element with the given name.

      @bold(Note): Names are case-sensitive }
    function Contains(const AName: String): Boolean; inline;

    { Checks whether the document contains an element with a given value.

      Parameters:
        AValue: the value of the element to find.

      Returns:
        True if the document contains an element with the given value.

      @bold(Note): the Equal operator of AValue is used to check if the value
      is in the document. }
    function ContainsValue(const AValue: TgoBsonValue): Boolean; inline;

    { Tries to retrieve an element by name.

      Parameters:
        AName: the name of the element to find.
        AELement: is set to the corresponding element if found.

      Returns:
        True if the document contains an element with the given name. }
    function TryGetElement(const AName: String; out AElement: TgoBsonElement): Boolean; inline;

    { Tries to retrieve a value by name.

      Parameters:
        AName: the name of the value to find.
        AValue: is set to the corresponding value if found.

      Returns:
        True if the document contains an element with the given name. }
    function TryGetValue(const AName: String; out AValue: TgoBsonValue): Boolean; inline;

    { Removes an element by name.

      Parameters:
        AName: the name of the element to remove.

      @bold(Note):
        In case AllowDuplicateNames = True, then all elements with this name are
        removed. The method does nothing if the document does not contain an
        element with the given name. }
    procedure Remove(const AName: String); inline;

    { Deletes an element by index.

      Parameters:
        AIndex: the index of the element to delete.

      Raises:
        EArgumentOutOfRangeException in AIndex is out of bounds. }
    procedure Delete(const AIndex: Integer); inline;

    { Clears the document }
    procedure Clear; inline;

    { Merges another document into this one.

      Parameters:
        AOtherDocument: the other document to merge with this one.
        AOverwriteExistingElements: whether to overwrite existing element.

      Returns:
        The document itself, so you can use it for chaining.

      Raises:
        EArgumentNilException if AOtherDocument has not been assigned (IsNil
          returns True). }
    function Merge(const AOtherDocument: TgoBsonDocument;
      const AOverwriteExistingElements: Boolean): TgoBsonDocument;

    { Returns the elements in then document as an array.

      Returns:
        The array of elements }
    function ToArray: TArray<TgoBsonElement>; inline;

    { Allow <tt>for..in</tt> enumeration of the elements in the document. }
    function GetEnumerator: TEnumerator; inline;

    { Whether duplicate element names are allowed.
      Should generally be False (the default). }
    property AllowDuplicateNames: Boolean read GetAllowDuplicateNames write SetAllowDuplicateNames;

    { Number of elements in the document.
      Could be larger than the number of names in the document in case
      AllowDuplicateNames = True }
    property Count: Integer read GetCount;

    { The elements in the document by index.

      Parameters:
        AIndex: the index of the element to get.

      Raises:
        EArgumentOutOfRangeException in AIndex is out of bounds. }
    property Elements[const AIndex: Integer]: TgoBsonElement read GetElement;

    { The values in the document by index.

      Parameters:
        AIndex: the index of the value to get or set.

      Raises:
        EArgumentOutOfRangeException in AIndex is out of bounds.
        EArgumentNilException when setting the value and AValue is not assigned
        (IsNil returns True) }
    property Values[const AIndex: Integer]: TgoBsonValue read GetValue write SetValue;

    { The values in the document by name.

      Parameters:
        AName: the name of the value to get or set.

      Raises:
        EArgumentNilException when setting the value and AValue is not assigned
        (IsNil returns True)

      @bold(Note): when getting a value and the name is not found, a TgoBsonNull
      value is returned.

      @bold(Note): when setting a value, it will replace an existing value with
      the same name if found, or otherwise add it. }
    property ValuesByName[const AName: String]: TgoBsonValue read GetValueByName write SetValueByName; default;
  end;

type
  { A blob of binary data }
  TgoBsonBinaryData = record
  {$REGION 'Internal Declarations'}
  private type
    { @exclude }
    _IBinaryData = interface(TgoBsonValue._IValue)
    ['{8C7D00D2-6C0F-444F-A4A8-79F366BBA9A1}']
      function GetSubType: TgoBsonBinarySubType;
      function GetCount: Integer;
      function GetByte(const AIndex: Integer): Byte;
      procedure SetByte(const AIndex: Integer; const AValue: Byte);
      function GetAsBytes: TBytes;

      property SubType: TgoBsonBinarySubType read GetSubType;
      property Count: Integer read GetCount;
      property Bytes[const AIndex: Integer]: Byte read GetByte write SetByte; default;
      property AsBytes: TBytes read GetAsBytes;
    end;
  private
    FImpl: _IBinaryData;
    function GetSubType: TgoBsonBinarySubType; inline;
    function GetCount: Integer; inline;
    function GetByte(const AIndex: Integer): Byte; inline;
    procedure SetByte(const AIndex: Integer; const AValue: Byte); inline;
    function GetAsBytes: TBytes; inline;
  public
    { @exclude }
    property _Impl: _IBinaryData read FImpl;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates an empty BSON binary.

      Returns:
        The empty BSON binary }
    class function Create: TgoBsonBinaryData; overload; static;

    { Creates a BSON binary from a byte array.

      Parameters:
        AData: the bytes to populate the binary with.

      Returns:
        The BSON binary }
    class function Create(const AData: TBytes): TgoBsonBinaryData; overload; static;

    { Creates a BSON binary from a byte array.

      Parameters:
        AData: the bytes to populate the binary with.
        ASubType: the type of binary data in AData.

      Returns:
        The BSON binary }
    class function Create(const AData: TBytes;
      const ASubType: TgoBsonBinarySubType): TgoBsonBinaryData; overload; static;

    { Implicitly casts a BSON binary to a BSON value. }
    class operator Implicit(const A: TgoBsonBinaryData): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonBinaryData): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonBinaryData): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.SetNil }
    procedure SetNil; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonBinaryData; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonBinaryData; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The type of binary data this object contains }
    property SubType: TgoBsonBinarySubType read GetSubType;

    { Number of bytes in the binary data }
    property Count: Integer read GetCount;

    { The bytes in the binary data.

      Parameters:
        AIndex: the index of the byte to get or set.

      Raises:
        EArgumentOutOfRangeException in AIndex is out of bounds. }
    property Bytes[const AIndex: Integer]: Byte read GetByte write SetByte; default;

    { Returns the binary as a byte array }
    property AsBytes: TBytes read GetAsBytes;
  end;

type
  { Represents the BSON Null value }
  TgoBsonNull = record
  {$REGION 'Internal Declarations'}
  private type
    _INull = interface(TgoBsonValue._IValue)
    ['{112081EC-BB01-4974-948C-59CE64077420}']
    end;
  private class var
    FImpl: TgoBsonNull;
  private
    FValue: _INull;
  public
    { @exclude }
    class constructor Create;

    { @exclude }
    property _Value: _INull read FValue;
  {$ENDREGION 'Internal Declarations'}
  public
    { Implicitly casts a BSON Null to a BSON value. }
    class operator Implicit(const A: TgoBsonNull): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonNull): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonNull): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonNull; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonNull; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The Null value singleton }
    class property Value: TgoBsonNull read FImpl;
  end;

type
  { Represents the BSON Undefined value }
  TgoBsonUndefined = record
  {$REGION 'Internal Declarations'}
  private type
    { @exclude }
    _IUndefined = interface(TgoBsonValue._IValue)
    ['{7410572B-2559-4036-B79A-A6237C0B2679}']
    end;
  private class var
    FImpl: TgoBsonUndefined;
  private
    FValue: _IUndefined;
  public
    { @exclude }
    class constructor Create;

    { @exclude }
    property _Value: _IUndefined read FValue;
  {$ENDREGION 'Internal Declarations'}
  public
    { Implicitly casts a BSON Undefined to a BSON value. }
    class operator Implicit(const A: TgoBsonUndefined): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonUndefined): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonUndefined): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonUndefined; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonUndefined; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The Undefined value singleton }
    class property Value: TgoBsonUndefined read FImpl;
  end;

type
  { A BSON DateTime value }
  TgoBsonDateTime = record
  {$REGION 'Internal Declarations'}
  private type
    _IDateTime = interface(TgoBsonValue._IValue)
      ['{87332312-C7B7-4E45-B778-569166ACA2D2}']
      function GetMillisecondsSinceEpoch: Int64;

      property MillisecondsSinceEpoch: Int64 read GetMillisecondsSinceEpoch;
    end;
  private
    FImpl: _IDateTime;
    function GetMillisecondsSinceEpoch: Int64; inline;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a BSON DateTime value from a Delphi DateTime value.

      Parameters:
        ADateTime: the (Delphi) date time value
        ADateTimeIsUTC: whether ADateTime is in universal time

      Returns:
        The BSON DateTime value }
    class function Create(const ADateTime: TDateTime; const ADateTimeIsUTC: Boolean): TgoBsonDateTime; overload; static;

    { Creates a BSON DateTime value.

      Parameters:
        AMillisecondsSinceEpoch: the number of milliseconds since the Unix epoch.

      Returns:
        The BSON DateTime value }
    class function Create(const AMillisecondsSinceEpoch: Int64): TgoBsonDateTime; overload; static;

    { Implicitly casts a BSON DateTime value to a BSON value. }
    class operator Implicit(const A: TgoBsonDateTime): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonDateTime): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonDateTime): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.SetNil }
    procedure SetNil; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonDateTime; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonDateTime; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { Converts the DateTime value to a Delphi DateTime value in local time }
    function ToLocalTime: TDateTime; inline;

    { Converts the DateTime value to a Delphi DateTime value in universal time }
    function ToUniversalTime: TDateTime; inline;

    { The number of milliseconds since the Unix epoch }
    property MillisecondsSinceEpoch: Int64 read GetMillisecondsSinceEpoch;
  end;

type
  { A BSON Timestamp. Mostly used internally for MongoDB replication and
    sharding. }
  TgoBsonTimestamp = record
  {$REGION 'Internal Declarations'}
  private type
    { @exclude }
    _ITimestamp = interface(TgoBsonValue._IValue)
    ['{212644B0-BF5F-4F16-AF96-50437C404DCA}']
      function GetIncrement: Integer;
      function GetTimestamp: Integer;
      function GetValue: Int64;

      property Value: Int64 read GetValue;
      property Timestamp: Integer read GetTimestamp;
      property Increment: Integer read GetIncrement;
    end;
  private
    FImpl: _ITimestamp;
    function GetIncrement: Integer; inline;
    function GetTimestamp: Integer; inline;
    function GetValue: Int64; inline;
  public
    { @exclude }
    property _Impl: _ITimestamp read FImpl;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a BSON Timestamp.

      Parameters:
        ATimestamp: the timestamp
        AIncrement: the increment

      Returns:
        The BSON Timestamp }
    class function Create(const ATimestamp, AIncrement: Integer): TgoBsonTimestamp; overload; static;

    { Creates a BSON Timestamp.

      Parameters:
        AValue: the combined timestamp/increment value

      Returns:
        The BSON Timestamp }
    class function Create(const AValue: Int64): TgoBsonTimestamp; overload; static;

    { Implicitly casts a BSON Timestamp to a BSON value. }
    class operator Implicit(const A: TgoBsonTimestamp): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonTimestamp): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonTimestamp): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.SetNil }
    procedure SetNil; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonTimestamp; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonTimestamp; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The timestamp }
    property Timestamp: Integer read GetTimestamp;

    { The increment }
    property Increment: Integer read GetIncrement;

    { The combined timestamp/increment value }
    property Value: Int64 read GetValue;
  end;

type
  { A BSON Regular Expression }
  TgoBsonRegularExpression = record
  {$REGION 'Internal Declarations'}
  private type
    { @exclude }
    _IRegularExpression = interface(TgoBsonValue._IValue)
    ['{C1283C00-6071-4DB7-82CD-5A53A00A7399}']
      function GetOptions: String;
      function GetPattern: String;

      property Pattern: String read GetPattern;
      property Options: String read GetOptions;
    end;
  private
    FImpl: _IRegularExpression;
    function GetOptions: String; inline;
    function GetPattern: String; inline;
  public
    { @exclude }
    property _Impl: _IRegularExpression read FImpl;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a BSON Regular Expression.

      Parameters:
        APattern: the regex pattern

      Returns:
        The BSON Regular Expression }
    class function Create(const APattern: String): TgoBsonRegularExpression; overload; static;

    { Creates a BSON Regular Expression.

      Parameters:
        APattern: the regex pattern
        AOptions: the regex options

      Returns:
        The BSON Regular Expression }
    class function Create(const APattern, AOptions: String): TgoBsonRegularExpression; overload; static;

    { Implicitly converts a regex pattern String to a BSON Regular Expression }
    class operator Implicit(const A: String): TgoBsonRegularExpression; static;

    { Implicitly casts a BSON Regular Expression to a BSON value. }
    class operator Implicit(const A: TgoBsonRegularExpression): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonRegularExpression): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonRegularExpression): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.SetNil }
    procedure SetNil; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonRegularExpression; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonRegularExpression; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The regex pattern }
    property Pattern: String read GetPattern;

    { The regex options }
    property Options: String read GetOptions;
  end;

type
  { A piece of JavaScript code }
  TgoBsonJavaScript = record
  {$REGION 'Internal Declarations'}
  private type
    { @exclude }
    _IJavaScript = interface(TgoBsonValue._IValue)
    ['{8659A4B1-171B-4C44-BBFC-109E14DE27FC}']
      function GetCode: String;

      property Code: String read GetCode;
    end;
  private
    FImpl: _IJavaScript;
    function GetCode: String; inline;
  public
    { @exclude }
    property _Impl: _IJavaScript read FImpl;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a BSON JavaScript.

      Parameters:
        ACode: the JavaScript code.

      Returns:
        The BSON JavaScript }
    class function Create(const ACode: String): TgoBsonJavaScript; static;

    { Implicitly casts a BSON JavaScript to a BSON value. }
    class operator Implicit(const A: TgoBsonJavaScript): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonJavaScript): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonJavaScript): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.SetNil }
    procedure SetNil; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonJavaScript; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonJavaScript; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The JavaScript code }
    property Code: String read GetCode;
  end;

type
  { A piece of JavaScript code with a scope (a set of variables with values, as
    defined in another document).}
  TgoBsonJavaScriptWithScope = record
  {$REGION 'Internal Declarations'}
  private type
    { @exclude }
    _IJavaScriptWithScope = interface(TgoBsonJavaScript._IJavaScript)
    ['{17B4EFE0-6FEE-4972-A2E5-1CAC276649D4}']
      function GetScope: TgoBsonDocument;

      property Scope: TgoBsonDocument read GetScope;
    end;
  private
    FImpl: _IJavaScriptWithScope;
    function GetCode: String; inline;
    function GetScope: TgoBsonDocument; inline;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a BSON JavaScript w/scope.

      Parameters:
        ACode: the JavaScript code.
        AScope: the scope document containing the variables with values.

      Returns:
        The BSON JavaScript w/scope

      Raises:
        EArgumentNilException if AScope has not been assigned (IsNil returns True) }
    class function Create(const ACode: String;
      const AScope: TgoBsonDocument): TgoBsonJavaScriptWithScope; static;

    { Implicitly casts a BSON JavaScript w/scope to a BSON value. }
    class operator Implicit(const A: TgoBsonJavaScriptWithScope): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonJavaScriptWithScope): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonJavaScriptWithScope): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.SetNil }
    procedure SetNil; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonJavaScriptWithScope; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonJavaScriptWithScope; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The JavaScript code }
    property Code: String read GetCode;

    { The scope document containing the variables with values. }
    property Scope: TgoBsonDocument read GetScope;
  end;

type
  { A symbol from a lookup table (deprecated by BSON).
    You create symbols using TgoBsonSymbolTable.Lookup. }
  TgoBsonSymbol = record
  {$REGION 'Internal Declarations'}
  private type
    { @exclude }
    _ISymbol = interface(TgoBsonValue._IValue)
    ['{B63F0297-6A95-4A74-98DF-6E355E8E83B4}']
      function GetName: String;

      property Name: String read GetName;
    end;
  private
    FImpl: _ISymbol;
    function GetName: String; inline;
  public
    { @exclude }
    property _Impl: _ISymbol read FImpl;
  {$ENDREGION 'Internal Declarations'}
  public
    { Implicitly casts a BSON Symbol to a BSON value. }
    class operator Implicit(const A: TgoBsonSymbol): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonSymbol): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonSymbol): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.SetNil }
    procedure SetNil; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonSymbol; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonSymbol; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The name of the symbol }
    property Name: String read GetName;
  end;

type
  { A table used to lookup TgoBsonSymbol values }
  TgoBsonSymbolTable = record
  {$REGION 'Internal Declarations'}
  private class var
    FTable: TDictionary<String, TgoBsonSymbol>;
    FLock: TCriticalSection;
  public
    { @exclude }
    class constructor Create;

    { @exclude }
    class destructor Destroy;
  {$ENDREGION 'Internal Declarations'}
  public
    { Looks up a symbol.

      Parameters:
        AName: the name of the symbol the lookup.

      Returns:
        A symbol with the given name.

      If the table already contains a symbol with the given name, then that
      symbol is returned. Otherwise, a new symbol is added to the table. }
    class function Lookup(const AName: String): TgoBsonSymbol; static;
  end;

type
  { Represents the BSON MaxKey value }
  TgoBsonMaxKey = record
  {$REGION 'Internal Declarations'}
  private type
    { @exclude }
    _IMaxKey = interface(TgoBsonValue._IValue)
    ['{A6013802-3E77-4A53-B167-9EC4F0EDE896}']
    end;
  private class var
    FImpl: TgoBsonMaxKey;
  private
    FValue: _IMaxKey;
  public
    { @exclude }
    class constructor Create;

    { @exclude }
    property _Value: _IMaxKey read FValue;
  {$ENDREGION 'Internal Declarations'}
  public
    { Implicitly casts a BSON MaxKey to a BSON value. }
    class operator Implicit(const A: TgoBsonMaxKey): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonMaxKey): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonMaxKey): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonMaxKey; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonMaxKey; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The MaxKey value singleton }
    class property Value: TgoBsonMaxKey read FImpl;
  end;

type
  { Represents the BSON MinKey value }
  TgoBsonMinKey = record
  {$REGION 'Internal Declarations'}
  private type
    { @exclude }
    _IMinKey = interface(TgoBsonValue._IValue)
    ['{539D88D8-5E9F-4FA0-8304-A81FA89D8934}']
    end;
  private class var
    FImpl: TgoBsonMinKey;
  private
    FValue: _IMinKey;
  public
    { @exclude }
    class constructor Create;

    { @exclude }
    property _Value: _IMinKey read FValue;
  {$ENDREGION 'Internal Declarations'}
  public
    { Implicitly casts a BSON MinKey to a BSON value. }
    class operator Implicit(const A: TgoBsonMinKey): TgoBsonValue; static;

    { See TgoBsonValue.Equal }
    class operator Equal(const A, B: TgoBsonMinKey): Boolean; static;

    { See TgoBsonValue.NotEqual }
    class operator NotEqual(const A, B: TgoBsonMinKey): Boolean; static;

    { See TgoBsonValue.IsNil }
    function IsNil: Boolean; inline;

    { See TgoBsonValue.Clone }
    function Clone: TgoBsonMinKey; inline;

    { See TgoBsonValue.DeepClone }
    function DeepClone: TgoBsonMinKey; inline;

    { See TgoBsonValue.ToBson }
    function ToBson: TBytes; inline;

    { See TgoBsonValue.ToJson }
    function ToJson: String; overload; inline;

    { See TgoBsonValue.ToJson }
    function ToJson(const ASettings: TgoJsonWriterSettings): String; overload; inline;

    { The MinKey value singleton }
    class property Value: TgoBsonMinKey read FImpl;
  end;

type
  { Adds methods to TgoBsonValue }
  TgoBsonValueHelper = record helper for TgoBsonValue
  public
    { Returns the value as a BSON array.
      Returns an empty array of the value isn't a BSON array }
    function ToBsonArray: TgoBsonArray; inline;

    { Returns the value as a BSON array.

      Raises:
        EIntfCastError if this value isn't a BSON array }
    function AsBsonArray: TgoBsonArray; inline;

    { Returns the value as a BSON binary.

      Raises:
        EIntfCastError if this value isn't a BSON binary }
    function AsBsonBinaryData: TgoBsonBinaryData; inline;

    { Returns the value as a BSON document.
      Returns an empty document of the value isn't a BSON document }
    function ToBsonDocument: TgoBsonDocument; inline;

    { Returns the value as a BSON document.

      Raises:
        EIntfCastError if this value isn't a BSON document }
    function AsBsonDocument: TgoBsonDocument; inline;

    { Returns the value as a BSON JavaScript object.

      Raises:
        EIntfCastError if this value isn't a BSON JavaScript object }
    function AsBsonJavaScript: TgoBsonJavaScript; inline;

    { Returns the value as a BSON JavaScript-with-scope object.

      Raises:
        EIntfCastError if this value isn't a BSON JavaScript-with-scope object }
    function AsBsonJavaScriptWithScope: TgoBsonJavaScriptWithScope; inline;

    { Returns the value as a BSON MaxKey.

      Raises:
        EIntfCastError if this value isn't a BSON MaxKey }
    function AsBsonMaxKey: TgoBsonMaxKey; inline;

    { Returns the value as a BSON MinKey.

      Raises:
        EIntfCastError if this value isn't a BSON MinKey }
    function AsBsonMinKey: TgoBsonMinKey; inline;

    { Returns the value as a BSON Null.

      Raises:
        EIntfCastError if this value isn't a BSON Null }
    function AsBsonNull: TgoBsonNull; inline;

    { Returns the value as a BSON Undefined.

      Raises:
        EIntfCastError if this value isn't a BSON Undefined }
    function AsBsonUndefined: TgoBsonUndefined; inline;

    { Returns the value as a BSON Regular Expression.

      Raises:
        EIntfCastError if this value isn't a BSON Regular Expression }
    function AsBsonRegularExpression: TgoBsonRegularExpression; inline;

    { Returns the value as a BSON Symbol.

      Raises:
        EIntfCastError if this value isn't a BSON Symbol }
    function AsBsonSymbol: TgoBsonSymbol; inline;

    { Returns the value as a BSON DateTime.

      Raises:
        EIntfCastError if this value isn't a BSON DateTime }
    function AsBsonDateTime: TgoBsonDateTime; inline;

    { Returns the value as a BSON Timestamp.

      Raises:
        EIntfCastError if this value isn't a BSON Timestamp }
    function AsBsonTimestamp: TgoBsonTimestamp; inline;
  end;

{$REGION 'Internal Declarations'}
{ @exclude }
function _goBsonValueFromDouble(const AValue: Double): TgoBsonValue._IValue;

{ @exclude }
function _goBsonValueFromString(const AValue: String): TgoBsonValue._IValue;

{ @exclude }
function _goBsonValueFromObjectId(const AValue: TgoObjectId): TgoBsonValue._IValue;

{ @exclude }
function _goBsonValueFromBoolean(const AValue: Boolean): TgoBsonValue._IValue;

{ @exclude }
function _goBsonValueFromDateTime(const AValue: Int64): TgoBsonValue._IValue;

{ @exclude }
function _goBsonValueFromInt32(const AValue: Int32): TgoBsonValue._IValue;

{ @exclude }
function _goBsonValueFromInt64(const AValue: Int64): TgoBsonValue._IValue;

{ @exclude }
function _goCreateArray: TgoBsonArray._IArray;

{ @exclude }
function _goCreateDocument: TgoBsonDocument._IDocument;

{ @exclude }
procedure _goGetBinaryData(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonBinaryData);

{ @exclude }
procedure _goGetDateTime(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonDateTime);

{ @exclude }
procedure _goGetRegularExpression(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonRegularExpression);

{ @exclude }
procedure _goGetJavaScript(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonJavaScript);

{ @exclude }
procedure _goGetJavaScriptWithScope(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonJavaScriptWithScope);

{ @exclude }
procedure _goGetSymbol(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonSymbol);

{ @exclude }
procedure _goGetTimestamp(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonTimestamp);
{$ENDREGION 'Internal Declarations'}

implementation

uses
  System.Types,
  System.SysConst,
  System.RTLConsts,
  System.DateUtils,
  Grijjy.SysUtils,
  Grijjy.DateUtils,
  Grijjy.Bson.IO;

type
  TNonRefCountedInterface = record {IInterface}
  private
    FVTable: Pointer;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function Addref: Integer; stdcall;
    function Release: Integer; stdcall;
  end;

type
  TRefCountedInterface = record {IInterface}
  private
    FVTable: Pointer;
    FRefCount: Integer;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function Addref: Integer; stdcall;
    function Release: Integer; stdcall;
  end;

type
  TValue = record {TInterfacedRecord, TgoBsonValue._IValue}
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsBoolean: Boolean;
    function AsInteger: Integer;
    function AsInt64: Int64;
    function AsDouble: Double;
    function AsString: String;
    function AsArray: TArray<TgoBsonValue>;
    function AsByteArray: TBytes;
    function AsGuid: TGUID;
    function AsObjectId: TgoObjectId;

    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function ToLocalTime: TDateTime;
    function ToUniversalTime: TDateTime;
    function ToByteArray: TBytes;
    function ToGuid: TGUID;
    function ToObjectId: TgoObjectId;

    function Equals(const AOther: TgoBsonValue._IValue): Boolean;

    function Clone: TgoBsonValue._IValue;
    function DeepClone: TgoBsonValue._IValue;
  end;
  PValue = ^TValue;

type
  TInterfaceVTable = record
    QueryInterface: Pointer;
    Addref: Pointer;
    Release: Pointer;
  end;

type
  TVTableValue = record
    Intf: TInterfaceVTable;
    GetBsonType: Pointer;
    AsBoolean: Pointer;
    AsInteger: Pointer;
    AsInt64: Pointer;
    AsDouble: Pointer;
    AsString: Pointer;
    AsArray: Pointer;
    AsByteArray: Pointer;
    AsGuid: Pointer;
    AsObjectId: Pointer;

    ToBoolean: Pointer;
    ToDouble: Pointer;
    ToInteger: Pointer;
    ToInt64: Pointer;
    ToString: Pointer;
    ToLocalTime: Pointer;
    ToUniversalTime: Pointer;
    ToByteArray: Pointer;
    ToGuid: Pointer;
    ToObjectId: Pointer;

    Equals: Pointer;

    Clone: Pointer;
    DeepClone: Pointer;
  end;

type
  TValueFalse = record {TValue}
  private class var
    FValue: TgoBsonValue._IValue;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsBoolean: Boolean;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class constructor Create;
  end;

const
  VTABLE_FALSE: TVTableValue = (
    Intf:
      (QueryInterface: @TNonRefCountedInterface.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueFalse.GetBsonType;
    AsBoolean: @TValueFalse.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueFalse.ToBoolean;
    ToDouble: @TValueFalse.ToDouble;
    ToInteger: @TValueFalse.ToInteger;
    ToInt64: @TValueFalse.ToInt64;
    ToString: @TValueFalse.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueFalse.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

const
  VALUE_BOOLEAN_FALSE: Pointer = @VTABLE_FALSE;

type
  TValueTrue = record {TValue}
  private class var
    FValue: TgoBsonValue._IValue;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsBoolean: Boolean;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class constructor Create;
  end;

const
  VTABLE_TRUE: TVTableValue = (
    Intf:
      (QueryInterface: @TNonRefCountedInterface.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueTrue.GetBsonType;
    AsBoolean: @TValueTrue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueTrue.ToBoolean;
    ToDouble: @TValueTrue.ToDouble;
    ToInteger: @TValueTrue.ToInteger;
    ToInt64: @TValueTrue.ToInt64;
    ToString: @TValueTrue.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueTrue.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

const
  VALUE_BOOLEAN_TRUE: Pointer = @VTABLE_TRUE;

type
  TValueInteger = record {TValue}
  private
    FBase: TRefCountedInterface;
    FValue: Integer;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsInteger: Integer;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class function Create(const AValue: Integer): TgoBsonValue._IValue; inline; static;
  end;
  PValueInteger = ^TValueInteger;

const
  VTABLE_INTEGER: TVTableValue = (
    Intf:
      (QueryInterface: @TRefCountedInterface.QueryInterface;
       AddRef: @TRefCountedInterface.AddRef;
       Release: @TRefCountedInterface.Release);
    GetBsonType: @TValueInteger.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValueInteger.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueInteger.ToBoolean;
    ToDouble: @TValueInteger.ToDouble;
    ToInteger: @TValueInteger.ToInteger;
    ToInt64: @TValueInteger.ToInt64;
    ToString: @TValueInteger.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueInteger.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

type
  TValueIntegerConst = record {TValue}
  private const
    MIN_PRECREATED_VALUE = -100;
    MAX_PRECREATED_VALUE = 100;
  private class var
    FPrecreatedValues: array [MIN_PRECREATED_VALUE..MAX_PRECREATED_VALUE] of TgoBsonValue._IValue;
    FPrecreatedData: Pointer;
  private
    FBase: TNonRefCountedInterface;
    FValue: Integer;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsInteger: Integer;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class constructor Create;
    class destructor Destroy;
  end;
  PValueIntegerConst = ^TValueIntegerConst;

const
  VTABLE_INTEGER_CONST: TVTableValue = (
    Intf:
      (QueryInterface: @TNonRefCountedInterface.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueIntegerConst.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValueIntegerConst.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueIntegerConst.ToBoolean;
    ToDouble: @TValueIntegerConst.ToDouble;
    ToInteger: @TValueIntegerConst.ToInteger;
    ToInt64: @TValueIntegerConst.ToInt64;
    ToString: @TValueIntegerConst.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueIntegerConst.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

type
  TValueInt64 = record {TValue}
  private
    FBase: TRefCountedInterface;
    FValue: Int64;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsInt64: Int64;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class function Create(const AValue: Int64): TgoBsonValue._IValue; inline; static;
  end;
  PValueInt64 = ^TValueInt64;

const
  VTABLE_INT64: TVTableValue = (
    Intf:
      (QueryInterface: @TRefCountedInterface.QueryInterface;
       AddRef: @TRefCountedInterface.AddRef;
       Release: @TRefCountedInterface.Release);
    GetBsonType: @TValueInt64.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValueInt64.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueInt64.ToBoolean;
    ToDouble: @TValueInt64.ToDouble;
    ToInteger: @TValueInt64.ToInteger;
    ToInt64: @TValueInt64.ToInt64;
    ToString: @TValueInt64.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueInt64.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

type
  TValueInt64Const = record {TValue}
  private const
    MIN_PRECREATED_VALUE = -100;
    MAX_PRECREATED_VALUE = 100;
  private class var
    FPrecreatedValues: array [MIN_PRECREATED_VALUE..MAX_PRECREATED_VALUE] of TgoBsonValue._IValue;
    FPrecreatedData: Pointer;
  private
    FBase: TNonRefCountedInterface;
    FValue: Int64;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsInt64: Int64;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class constructor Create;
    class destructor Destroy;
  end;
  PValueInt64Const = ^TValueInt64Const;

const
  VTABLE_INT64_CONST: TVTableValue = (
    Intf:
      (QueryInterface: @TNonRefCountedInterface.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueInt64Const.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValueInt64Const.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueInt64Const.ToBoolean;
    ToDouble: @TValueInt64Const.ToDouble;
    ToInteger: @TValueInt64Const.ToInteger;
    ToInt64: @TValueInt64Const.ToInt64;
    ToString: @TValueInt64Const.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueInt64Const.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

type
  TValueDouble = record {TValue}
  private
    FBase: TRefCountedInterface;
    FValue: Double;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsDouble: Double;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class function Create(const AValue: Double): TgoBsonValue._IValue; inline; static;
  end;
  PValueDouble = ^TValueDouble;

const
  VTABLE_DOUBLE: TVTableValue = (
    Intf:
      (QueryInterface: @TRefCountedInterface.QueryInterface;
       AddRef: @TRefCountedInterface.AddRef;
       Release: @TRefCountedInterface.Release);
    GetBsonType: @TValueDouble.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValueDouble.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueDouble.ToBoolean;
    ToDouble: @TValueDouble.ToDouble;
    ToInteger: @TValueDouble.ToInteger;
    ToInt64: @TValueDouble.ToInt64;
    ToString: @TValueDouble.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueDouble.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

type
  TValueDoubleZero = record {TValue}
  private class var
    FValue: TgoBsonValue._IValue;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsDouble: Double;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class constructor Create;
  end;

const
  VTABLE_DOUBLE_ZERO: TVTableValue = (
    Intf:
      (QueryInterface: @TNonRefCountedInterface.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueDoubleZero.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValueDoubleZero.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueDoubleZero.ToBoolean;
    ToDouble: @TValueDoubleZero.ToDouble;
    ToInteger: @TValueDoubleZero.ToInteger;
    ToInt64: @TValueDoubleZero.ToInt64;
    ToString: @TValueDoubleZero.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueDoubleZero.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

const
  VALUE_DOUBLE_ZERO: Pointer = @VTABLE_DOUBLE_ZERO;

type
  TValueDateTime = record {TValue, TgoBsonDateTime._IDateTime}
  private
    FBase: TRefCountedInterface;
    FMillisecondsSinceEpoch: Int64;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function ToLocalTime: TDateTime;
    function ToUniversalTime: TDateTime;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    { TgoBsonDateTime._IDateTime }
    function GetMillisecondsSinceEpoch: Int64;
  public
    class function Create(const ADateTime: TDateTime; const ADateTimeIsUTC: Boolean): TgoBsonDateTime._IDateTime; overload; inline; static;
    class function Create(const AMillisecondsSinceEpoch: Int64): TgoBsonDateTime._IDateTime; overload; inline; static;
  end;
  PValueDateTime = ^TValueDateTime;

type
  TVTableValueDateTime = record
    Base: TVTableValue;
    GetMillisecondsSinceEpoch: Pointer;
  end;

const
  VTABLE_DATE_TIME: TVTableValueDateTime = (
    Base:
     (Intf:
       (QueryInterface: @TValueDateTime.QueryInterface;
        AddRef: @TRefCountedInterface.AddRef;
        Release: @TRefCountedInterface.Release);
      GetBsonType: @TValueDateTime.GetBsonType;
      AsBoolean: @TValue.AsBoolean;
      AsInteger: @TValue.AsInteger;
      AsInt64: @TValue.AsInt64;
      AsDouble: @TValue.AsDouble;
      AsString: @TValue.AsString;
      AsArray: @TValue.AsArray;
      AsByteArray: @TValue.AsByteArray;
      AsGuid: @TValue.AsGuid;
      AsObjectId: @TValue.AsObjectId;

      ToBoolean: @TValue.ToBoolean;
      ToDouble: @TValue.ToDouble;
      ToInteger: @TValue.ToInteger;
      ToInt64: @TValue.ToInt64;
      ToString: @TValueDateTime.ToString;
      ToLocalTime: @TValueDateTime.ToLocalTime;
      ToUniversalTime: @TValueDateTime.ToUniversalTime;
      ToByteArray: @TValue.ToByteArray;
      ToGuid: @TValue.ToGuid;
      ToObjectId: @TValue.ToObjectId;

      Equals: @TValueDateTime.Equals;

      Clone: @TValue.Clone;
      DeepClone: @TValue.DeepClone);
    GetMillisecondsSinceEpoch: @TValueDateTime.GetMillisecondsSinceEpoch);

type
  TValueString = record {TValue}
  private
    FBase: TRefCountedInterface;
    FLength: Integer;
    { Data: array of Char }
  private
    function Value: String; inline;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsString: String;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class function Create(const AValue: String): TgoBsonValue._IValue; inline; static;
  end;
  PValueString = ^TValueString;

const
  VTABLE_STRING: TVTableValue = (
    Intf:
      (QueryInterface: @TRefCountedInterface.QueryInterface;
       AddRef: @TRefCountedInterface.AddRef;
       Release: @TRefCountedInterface.Release);
    GetBsonType: @TValueString.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValueString.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueString.ToBoolean;
    ToDouble: @TValueString.ToDouble;
    ToInteger: @TValueString.ToInteger;
    ToInt64: @TValueString.ToInt64;
    ToString: @TValueString.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueString.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

type
  TValueStringEmpty = packed record {TValue}
  private class var
    FValue: TgoBsonValue._IValue;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsString: String;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class constructor Create;
  end;

const
  VTABLE_STRING_EMPTY: TVTableValue = (
    Intf:
      (QueryInterface: @TNonRefCountedInterface.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueStringEmpty.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValueStringEmpty.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueStringEmpty.ToBoolean;
    ToDouble: @TValueStringEmpty.ToDouble;
    ToInteger: @TValueStringEmpty.ToInteger;
    ToInt64: @TValueStringEmpty.ToInt64;
    ToString: @TValueStringEmpty.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueStringEmpty.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

const
  VALUE_STRING_EMPTY: Pointer = @VTABLE_STRING_EMPTY;

type
  TValueStringConstant = record {TValue}
  private
    FBase: TRefCountedInterface;
    FValue: Pointer;
  private
    function Value: String; inline;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsString: String;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToDouble(const ADefault: Double): Double;
    function ToInteger(const ADefault: Integer): Integer;
    function ToInt64(const ADefault: Int64): Int64;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class function Create(const AValue: String): TgoBsonValue._IValue; inline; static;
  end;
  PValueStringConstant = ^TValueStringConstant;

const
  VTABLE_STRING_CONSTANT: TVTableValue = (
    Intf:
      (QueryInterface: @TRefCountedInterface.QueryInterface;
       AddRef: @TRefCountedInterface.AddRef;
       Release: @TRefCountedInterface.Release);
    GetBsonType: @TValueStringConstant.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValueStringConstant.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueStringConstant.ToBoolean;
    ToDouble: @TValueStringConstant.ToDouble;
    ToInteger: @TValueStringConstant.ToInteger;
    ToInt64: @TValueStringConstant.ToInt64;
    ToString: @TValueStringConstant.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueStringConstant.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

type
  TValueArray = record {TValue, TgoBsonArray._IArray}
  private
    FBase: TRefCountedInterface;
    FItems: TArray<TgoBsonValue._IValue>;
    FCount: Integer;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsArray: TArray<TgoBsonValue>;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
    function Clone: TgoBsonValue._IValue;
    function DeepClone: TgoBsonValue._IValue;
  public
    { TgoBsonArray._IArray }
    function GetCount: Integer;
    procedure GetItem(const AIndex: Integer; out AValue: TgoBsonValue._IValue);
    procedure SetItem(const AIndex: Integer; const AValue: TgoBsonValue._IValue);
    procedure Add(const AValue: TgoBsonValue._IValue); overload;
    procedure AddRangeOpenArray(const AValues: array of TgoBsonValue); overload;
    procedure AddRangeGenArray(const AValues: TArray<TgoBsonValue>); overload;
    procedure AddRangeBsonArray(const AValues: TgoBsonArray); overload;
    procedure Delete(const AIndex: Integer);
    function Remove(const AValue: TgoBsonValue): Boolean;
    procedure Clear;
    function Contains(const AValue: TgoBsonValue): Boolean;
    function IndexOf(const AValue: TgoBsonValue): Integer;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function Release: Integer; stdcall;
  public
    class function Create(const ACapacity: Integer = 0): TgoBsonArray._IArray; overload; inline; static;
    class function Create(const AValues: array of TgoBsonValue): TgoBsonArray._IArray; overload; static;
    class function Create(const AValues: TArray<TgoBsonValue>): TgoBsonArray._IArray; overload; inline; static;
  end;
  PValueArray = ^TValueArray;

type
  TVTableValueArray = record
    Base: TVTableValue;
    GetCount: Pointer;
    GetItem: Pointer;
    SetItem: Pointer;
    Add: Pointer;
    AddRangeOpenArray: Pointer;
    AddRangeGenArray: Pointer;
    AddRangeBsonArray: Pointer;
    Delete: Pointer;
    Remove: Pointer;
    Clear: Pointer;
    Contains: Pointer;
    IndexOf: Pointer;
  end;

const
  VTABLE_ARRAY: TVTableValueArray = (
    Base:
     (Intf:
       (QueryInterface: @TValueArray.QueryInterface;
        AddRef: @TRefCountedInterface.AddRef;
        Release: @TValueArray.Release);
      GetBsonType: @TValueArray.GetBsonType;
      AsBoolean: @TValue.AsBoolean;
      AsInteger: @TValue.AsInteger;
      AsInt64: @TValue.AsInt64;
      AsDouble: @TValue.AsDouble;
      AsString: @TValue.AsString;
      AsArray: @TValueArray.AsArray;
      AsByteArray: @TValue.AsByteArray;
      AsGuid: @TValue.AsGuid;
      AsObjectId: @TValue.AsObjectId;

      ToBoolean: @TValue.ToBoolean;
      ToDouble: @TValue.ToDouble;
      ToInteger: @TValue.ToInteger;
      ToInt64: @TValue.ToInt64;
      ToString: @TValue.ToString;
      ToLocalTime: @TValue.ToLocalTime;
      ToUniversalTime: @TValue.ToUniversalTime;
      ToByteArray: @TValue.ToByteArray;
      ToGuid: @TValue.ToGuid;
      ToObjectId: @TValue.ToObjectId;

      Equals: @TValueArray.Equals;

      Clone: @TValueArray.Clone;
      DeepClone: @TValueArray.DeepClone);
    GetCount: @TValueArray.GetCount;
    GetItem: @TValueArray.GetItem;
    SetItem: @TValueArray.SetItem;
    Add: @TValueArray.Add;
    AddRangeOpenArray: @TValueArray.AddRangeOpenArray;
    AddRangeGenArray: @TValueArray.AddRangeGenArray;
    AddRangeBsonArray: @TValueArray.AddRangeBsonArray;
    Delete: @TValueArray.Delete;
    Remove: @TValueArray.Remove;
    Clear: @TValueArray.Clear;
    Contains: @TValueArray.Contains;
    IndexOf: @TValueArray.IndexOf);

type
  TValueBinaryData = record {TValue, TgoBsonBinaryData._IBinaryData}
  private
    FBase: TRefCountedInterface;
    FValue: TBytes;
    FSubType: TgoBsonBinarySubType;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsByteArray: TBytes;
    function AsGuid: TGUID;
    function ToGuid: TGUID;
    function ToByteArray: TBytes;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    { TgoBsonBinaryData._IBinaryData }
    function GetSubType: TgoBsonBinarySubType;
    function GetCount: Integer;
    function GetByte(const AIndex: Integer): Byte;
    procedure SetByte(const AIndex: Integer; const AValue: Byte);
    function GetAsBytes: TBytes;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function Release: Integer; stdcall;
  public
    class function Create: TgoBsonBinaryData._IBinaryData; overload; inline; static;
    class function Create(const AValue: TBytes;
      const ASubType: TgoBsonBinarySubType = TgoBsonBinarySubType.Binary): TgoBsonBinaryData._IBinaryData; overload; inline; static;
    class function Create(const AValue: TGUID): TgoBsonBinaryData._IBinaryData; overload; inline; static;
  end;
  PValueBinaryData = ^TValueBinaryData;

type
  TVTableValueBinaryData = record
    Base: TVTableValue;
    GetSubType: Pointer;
    GetCount: Pointer;
    GetByte: Pointer;
    SetByte: Pointer;
    GetAsBytes: Pointer;
  end;

const
  VTABLE_BINARY_DATA: TVTableValueBinaryData = (
    Base:
     (Intf:
       (QueryInterface: @TValueBinaryData.QueryInterface;
        AddRef: @TRefCountedInterface.AddRef;
        Release: @TValueBinaryData.Release);
      GetBsonType: @TValueBinaryData.GetBsonType;
      AsBoolean: @TValue.AsBoolean;
      AsInteger: @TValue.AsInteger;
      AsInt64: @TValue.AsInt64;
      AsDouble: @TValue.AsDouble;
      AsString: @TValue.AsString;
      AsArray: @TValue.AsArray;
      AsByteArray: @TValueBinaryData.AsByteArray;
      AsGuid: @TValueBinaryData.AsGuid;
      AsObjectId: @TValue.AsObjectId;

      ToBoolean: @TValue.ToBoolean;
      ToDouble: @TValue.ToDouble;
      ToInteger: @TValue.ToInteger;
      ToInt64: @TValue.ToInt64;
      ToString: @TValue.ToString;
      ToLocalTime: @TValue.ToLocalTime;
      ToUniversalTime: @TValue.ToUniversalTime;
      ToByteArray: @TValueBinaryData.ToByteArray;
      ToGuid: @TValueBinaryData.ToGuid;
      ToObjectId: @TValue.ToObjectId;

      Equals: @TValueBinaryData.Equals);
    GetSubType: @TValueBinaryData.GetSubType;
    GetCount: @TValueBinaryData.GetCount;
    GetByte: @TValueBinaryData.GetByte;
    SetByte: @TValueBinaryData.SetByte;
    GetAsBytes: @TValueBinaryData.GetAsBytes);

type
  TValueDocument = record {TValue, TgoBsonDocument._IDocument}
  private const
    { We use an FIndices dictionary to map names to indices.
      However, for small dictionaries it is faster and more memory efficient
      to just perform a linear search.
      So we only use the dictionary if the number of items reaches this value. }
    INDICES_COUNT_THRESHOLD = 12;
  private type
    TMapEntry = record
      HashCode: Integer;
      Name: String;
      Index: Integer;
    end;
    TMapEntries = TArray<TMapEntry>;
  private type
    TIndexMap = record
    private const
      EMPTY_HASH = -1;
    private
      FEntries: TMapEntries;
      FCount: Integer;
      FGrowThreshold: Integer;
    private
      procedure Resize(ANewSize: Integer);
    public
      procedure Release; inline;
      procedure Clear;
      procedure Add(const AName: String; const AIndex: Integer);
      function Get(const AName: String): Integer;
    end;
    PIndexMap = ^TIndexMap;
  private
    FBase: TRefCountedInterface;
    FAllowDuplicateNames: Boolean;
    FElements: TArray<TgoBsonElement>;
    FIndices: PIndexMap;
    FCount: Integer;
  private
    procedure RebuildIndices;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
    function Clone: TgoBsonValue._IValue;
    function DeepClone: TgoBsonValue._IValue;
  public
    { TgoBsonDocument._IDocument }
    function GetCount: Integer;
    function GetAllowDuplicateNames: Boolean;
    procedure SetAllowDuplicateNames(const AValue: Boolean);
    function GetElement(const AIndex: Integer): TgoBsonElement;
    procedure GetValue(const AIndex: Integer; out AValue: TgoBsonValue._IValue);
    procedure SetValue(const AIndex: Integer; const AValue: TgoBsonValue._IValue);
    procedure GetValueByName(const AName: String; out AValue: TgoBsonValue._IValue);
    procedure SetValueByName(const AName: String; const AValue: TgoBsonValue._IValue);
    procedure Add(const AName: String; const AValue: TgoBsonValue._IValue);
    procedure Get(const AName: String; const ADefault: TgoBsonValue._IValue;
      out AValue: TgoBsonValue._IValue);
    function IndexOfName(const AName: String): Integer;
    function Contains(const AName: String): Boolean;
    function ContainsValue(const AValue: TgoBsonValue): Boolean;
    function TryGetElement(const AName: String; out AElement: TgoBsonElement): Boolean;
    function TryGetValue(const AName: String; out AValue: TgoBsonValue._IValue): Boolean;
    procedure Remove(const AName: String);
    procedure Delete(const AIndex: Integer);
    procedure Clear;
    procedure Merge(const AOtherDocument: TgoBsonDocument;
      const AOverwriteExistingElements: Boolean);
    function ToArray: TArray<TgoBsonElement>;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function Release: Integer; stdcall;
  public
    class function Create(const AAllowDuplicateNames: Boolean = False): TgoBsonDocument._IDocument; overload; inline; static;
    class function Create(const AElement: TgoBsonElement): TgoBsonDocument._IDocument; overload; inline; static;
    class function Create(const AName: String; const AValue: TgoBsonValue): TgoBsonDocument._IDocument; overload; inline; static;
  end;
  PValueDocument = ^TValueDocument;

type
  TVTableValueDocument = record
    Base: TVTableValue;

    GetCount: Pointer;
    GetAllowDuplicateNames: Pointer;
    SetAllowDuplicateNames: Pointer;
    GetElement: Pointer;
    GetValue: Pointer;
    SetValue: Pointer;
    GetValueByName: Pointer;
    SetValueByName: Pointer;

    Add: Pointer;
    Get: Pointer;
    IndexOfName: Pointer;
    Contains: Pointer;
    ContainsValue: Pointer;
    TryGetElement: Pointer;
    TryGetValue: Pointer;
    Remove: Pointer;
    Delete: Pointer;
    Clear: Pointer;
    Merge: Pointer;
    ToArray: Pointer;
  end;

const
  VTABLE_DOCUMENT: TVTableValueDocument = (
    Base:
     (Intf:
       (QueryInterface: @TValueDocument.QueryInterface;
        AddRef: @TRefCountedInterface.AddRef;
        Release: @TValueDocument.Release);
      GetBsonType: @TValueDocument.GetBsonType;
      AsBoolean: @TValue.AsBoolean;
      AsInteger: @TValue.AsInteger;
      AsInt64: @TValue.AsInt64;
      AsDouble: @TValue.AsDouble;
      AsString: @TValue.AsString;
      AsArray: @TValue.AsArray;
      AsByteArray: @TValue.AsByteArray;
      AsGuid: @TValue.AsGuid;
      AsObjectId: @TValue.AsObjectId;

      ToBoolean: @TValue.ToBoolean;
      ToDouble: @TValue.ToDouble;
      ToInteger: @TValue.ToInteger;
      ToInt64: @TValue.ToInt64;
      ToString: @TValue.ToString;
      ToLocalTime: @TValue.ToLocalTime;
      ToUniversalTime: @TValue.ToUniversalTime;
      ToByteArray: @TValue.ToByteArray;
      ToGuid: @TValue.ToGuid;
      ToObjectId: @TValue.ToObjectId;

      Equals: @TValueDocument.Equals;

      Clone: @TValueDocument.Clone;
      DeepClone: @TValueDocument.DeepClone);

    GetCount: @TValueDocument.GetCount;
    GetAllowDuplicateNames: @TValueDocument.GetAllowDuplicateNames;
    SetAllowDuplicateNames: @TValueDocument.SetAllowDuplicateNames;
    GetElement: @TValueDocument.GetElement;
    GetValue: @TValueDocument.GetValue;
    SetValue: @TValueDocument.SetValue;
    GetValueByName: @TValueDocument.GetValueByName;
    SetValueByName: @TValueDocument.SetValueByName;

    Add: @TValueDocument.Add;
    Get: @TValueDocument.Get;
    IndexOfName: @TValueDocument.IndexOfName;
    Contains: @TValueDocument.Contains;
    ContainsValue: @TValueDocument.ContainsValue;
    TryGetElement: @TValueDocument.TryGetElement;
    TryGetValue: @TValueDocument.TryGetValue;
    Remove: @TValueDocument.Remove;
    Delete: @TValueDocument.Delete;
    Clear: @TValueDocument.Clear;
    Merge: @TValueDocument.Merge;
    ToArray: @TValueDocument.ToArray);

type
  TValueNull = record {TValue, TgoBsonNull._INull}
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  end;

const
  VTABLE_NULL: TVTableValue = (
    Intf:
      (QueryInterface: @TValueNull.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueNull.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueNull.ToBoolean;
    ToDouble: @TValue.ToDouble;
    ToInteger: @TValue.ToInteger;
    ToInt64: @TValue.ToInt64;
    ToString: @TValueNull.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueNull.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.Clone);

const
  VALUE_NULL: Pointer = @VTABLE_NULL;

type
  TValueUndefined = record {TValue, TgoBsonUndefined._IUndefined}
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function ToBoolean(const ADefault: Boolean): Boolean;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  end;

const
  VTABLE_UNDEFINED: TVTableValue = (
    Intf:
      (QueryInterface: @TValueUndefined.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueUndefined.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValueUndefined.ToBoolean;
    ToDouble: @TValue.ToDouble;
    ToInteger: @TValue.ToInteger;
    ToInt64: @TValue.ToInt64;
    ToString: @TValueUndefined.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueUndefined.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.Clone);

const
  VALUE_UNDEFINED: Pointer = @VTABLE_UNDEFINED;

type
  TValueObjectId = record {TValue}
  private
    FBase: TRefCountedInterface;
    FValue: TgoObjectId;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function AsObjectId: TgoObjectId;
    function ToObjectId: TgoObjectId;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    class function Create(const AValue: TgoObjectId): TgoBsonValue._IValue; inline; static;
  end;
  PValueObjectId = ^TValueObjectId;

const
  VTABLE_OBJECT_ID: TVTableValue = (
    Intf:
      (QueryInterface: @TRefCountedInterface.QueryInterface;
       AddRef: @TRefCountedInterface.AddRef;
       Release: @TRefCountedInterface.Release);
    GetBsonType: @TValueObjectId.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValueObjectId.AsObjectId;

    ToBoolean: @TValue.ToBoolean;
    ToDouble: @TValue.ToDouble;
    ToInteger: @TValue.ToInteger;
    ToInt64: @TValue.ToInt64;
    ToString: @TValueObjectId.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValueObjectId.ToObjectId;

    Equals: @TValueObjectId.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.DeepClone);

type
  TValueRegularExpression = record {TValue, TgoBsonRegularExpression._IRegularExpression}
  private
    FBase: TRefCountedInterface;
    FPattern: String;
    FOptions: String;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function Release: Integer; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    { TgoBsonRegularExpression._IRegularExpression }
    function GetOptions: String;
    function GetPattern: String;
  public
    class function Create(const APattern: String): TgoBsonRegularExpression._IRegularExpression; overload; inline; static;
    class function Create(const APattern, AOptions: String): TgoBsonRegularExpression._IRegularExpression; overload; inline; static;
  end;
  PValueRegularExpression = ^TValueRegularExpression;

type
  TVTableValueRegularExpression = record
    Base: TVTableValue;
    GetOptions: Pointer;
    GetPattern: Pointer;
  end;

const
  VTABLE_REGULAR_EXPRESSION: TVTableValueRegularExpression = (
    Base:
     (Intf:
       (QueryInterface: @TValueRegularExpression.QueryInterface;
        AddRef: @TRefCountedInterface.AddRef;
        Release: @TValueRegularExpression.Release);
      GetBsonType: @TValueRegularExpression.GetBsonType;
      AsBoolean: @TValue.AsBoolean;
      AsInteger: @TValue.AsInteger;
      AsInt64: @TValue.AsInt64;
      AsDouble: @TValue.AsDouble;
      AsString: @TValue.AsString;
      AsArray: @TValue.AsArray;
      AsByteArray: @TValue.AsByteArray;
      AsGuid: @TValue.AsGuid;
      AsObjectId: @TValue.AsObjectId;

      ToBoolean: @TValue.ToBoolean;
      ToDouble: @TValue.ToDouble;
      ToInteger: @TValue.ToInteger;
      ToInt64: @TValue.ToInt64;
      ToString: @TValue.ToString;
      ToLocalTime: @TValue.ToLocalTime;
      ToUniversalTime: @TValue.ToUniversalTime;
      ToByteArray: @TValue.ToByteArray;
      ToGuid: @TValue.ToGuid;
      ToObjectId: @TValue.ToObjectId;

      Equals: @TValueRegularExpression.Equals;

      Clone: @TValue.Clone;
      DeepClone: @TValue.DeepClone);

    GetOptions: @TValueRegularExpression.GetOptions;
    GetPattern: @TValueRegularExpression.GetPattern);

type
  TValueJavaScript = record {TValue, TgoBsonJavaScript._IJavaScript}
  private
    FBase: TRefCountedInterface;
    FCode: String;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function Release: Integer; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    { TgoBsonJavaScript._IJavaScript }
    function GetCode: String;
  public
    class function Create(const ACode: String): TgoBsonJavaScript._IJavaScript; inline; static;
  end;
  PValueJavaScript = ^TValueJavaScript;

type
  TVTableValueJavaScript = record
    Base: TVTableValue;
    GetCode: Pointer;
  end;

const
  VTABLE_JAVA_SCRIPT: TVTableValueJavaScript = (
    Base:
     (Intf:
       (QueryInterface: @TValueJavaScript.QueryInterface;
        AddRef: @TRefCountedInterface.AddRef;
        Release: @TValueJavaScript.Release);
      GetBsonType: @TValueJavaScript.GetBsonType;
      AsBoolean: @TValue.AsBoolean;
      AsInteger: @TValue.AsInteger;
      AsInt64: @TValue.AsInt64;
      AsDouble: @TValue.AsDouble;
      AsString: @TValue.AsString;
      AsArray: @TValue.AsArray;
      AsByteArray: @TValue.AsByteArray;
      AsGuid: @TValue.AsGuid;
      AsObjectId: @TValue.AsObjectId;

      ToBoolean: @TValue.ToBoolean;
      ToDouble: @TValue.ToDouble;
      ToInteger: @TValue.ToInteger;
      ToInt64: @TValue.ToInt64;
      ToString: @TValue.ToString;
      ToLocalTime: @TValue.ToLocalTime;
      ToUniversalTime: @TValue.ToUniversalTime;
      ToByteArray: @TValue.ToByteArray;
      ToGuid: @TValue.ToGuid;
      ToObjectId: @TValue.ToObjectId;

      Equals: @TValueJavaScript.Equals;

      Clone: @TValue.Clone;
      DeepClone: @TValue.DeepClone);

    GetCode: @TValueJavaScript.GetCode);

type
  TValueJavaScriptWithScope = record {TValueJavaScript, TgoBsonJavaScriptWithScope._IJavaScriptWithScope}
  private
    FBase: TValueJavaScript;
    FScope: TgoBsonDocument;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function Release: Integer; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
    function Clone: TgoBsonValue._IValue;
    function DeepClone: TgoBsonValue._IValue;
  public
    { TgoBsonJavaScriptWithScope._IJavaScriptWithScope }
    function GetScope: TgoBsonDocument;
  public
    class function Create(const ACode: String; const AScope: TgoBsonDocument): TgoBsonJavaScriptWithScope._IJavaScriptWithScope; inline; static;
  end;
  PValueJavaScriptWithScope = ^TValueJavaScriptWithScope;

type
  TVTableValueJavaScriptWithScope = record
    Base: TVTableValueJavaScript;
    GetScope: Pointer;
  end;

const
  VTABLE_JAVA_SCRIPT_WITH_SCOPE: TVTableValueJavaScriptWithScope = (
    Base:
     (Base:
       (Intf:
         (QueryInterface: @TValueJavaScriptWithScope.QueryInterface;
          AddRef: @TRefCountedInterface.AddRef;
          Release: @TValueJavaScriptWithScope.Release);
        GetBsonType: @TValueJavaScriptWithScope.GetBsonType;
        AsBoolean: @TValue.AsBoolean;
        AsInteger: @TValue.AsInteger;
        AsInt64: @TValue.AsInt64;
        AsDouble: @TValue.AsDouble;
        AsString: @TValue.AsString;
        AsArray: @TValue.AsArray;
        AsByteArray: @TValue.AsByteArray;
        AsGuid: @TValue.AsGuid;
        AsObjectId: @TValue.AsObjectId;

        ToBoolean: @TValue.ToBoolean;
        ToDouble: @TValue.ToDouble;
        ToInteger: @TValue.ToInteger;
        ToInt64: @TValue.ToInt64;
        ToString: @TValue.ToString;
        ToLocalTime: @TValue.ToLocalTime;
        ToUniversalTime: @TValue.ToUniversalTime;
        ToByteArray: @TValue.ToByteArray;
        ToGuid: @TValue.ToGuid;
        ToObjectId: @TValue.ToObjectId;

        Equals: @TValueJavaScriptWithScope.Equals;

        Clone: @TValueJavaScriptWithScope.Clone;
        DeepClone: @TValueJavaScriptWithScope.DeepClone);

      GetCode: @TValueJavaScript.GetCode);

    GetScope: @TValueJavaScriptWithScope.GetScope);

type
  TValueSymbol = record {TValue, TgoBsonSymbol._ISymbol}
  private
    FBase: TRefCountedInterface;
    FName: String;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function Release: Integer; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
    function ToString(const ADefault: String): String;
  public
    { TgoBsonSymbol._ISymbol }
    function GetName: String;
  public
    class function Create(const AName: String): TgoBsonSymbol._ISymbol; inline; static;
  end;
  PValueSymbol = ^TValueSymbol;

type
  TVTableValueSymbol = record
    Base: TVTableValue;
    GetName: Pointer;
  end;

const
  VTABLE_SYMBOL: TVTableValueSymbol = (
    Base:
     (Intf:
       (QueryInterface: @TValueSymbol.QueryInterface;
        AddRef: @TRefCountedInterface.AddRef;
        Release: @TValueSymbol.Release);
      GetBsonType: @TValueSymbol.GetBsonType;
      AsBoolean: @TValue.AsBoolean;
      AsInteger: @TValue.AsInteger;
      AsInt64: @TValue.AsInt64;
      AsDouble: @TValue.AsDouble;
      AsString: @TValue.AsString;
      AsArray: @TValue.AsArray;
      AsByteArray: @TValue.AsByteArray;
      AsGuid: @TValue.AsGuid;
      AsObjectId: @TValue.AsObjectId;

      ToBoolean: @TValue.ToBoolean;
      ToDouble: @TValue.ToDouble;
      ToInteger: @TValue.ToInteger;
      ToInt64: @TValue.ToInt64;
      ToString: @TValueSymbol.ToString;
      ToLocalTime: @TValue.ToLocalTime;
      ToUniversalTime: @TValue.ToUniversalTime;
      ToByteArray: @TValue.ToByteArray;
      ToGuid: @TValue.ToGuid;
      ToObjectId: @TValue.ToObjectId;

      Equals: @TValueSymbol.Equals;

      Clone: @TValue.Clone;
      DeepClone: @TValue.DeepClone);

    GetName: @TValueSymbol.GetName);

type
  TValueTimestamp = record {TValue, TgoBsonTimestamp._ITimestamp}
  private
    FBase: TRefCountedInterface;
    FValue: Int64;
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  public
    { TgoBsonTimestamp._ITimestamp }
    function GetIncrement: Integer;
    function GetTimestamp: Integer;
    function GetValue: Int64;
  public
    class function Create(const AValue: Int64): TgoBsonTimestamp._ITimestamp; overload; inline; static;
    class function Create(const ATimestamp, AIncrement: Integer): TgoBsonTimestamp._ITimestamp; overload; inline; static;
  end;
  PValueTimestamp = ^TValueTimestamp;

type
  TVTableValueTimestamp = record
    Base: TVTableValue;
    GetIncrement: Pointer;
    GetTimestamp: Pointer;
    GetValue: Pointer;
  end;

const
  VTABLE_TIMESTAMP: TVTableValueTimestamp = (
    Base:
     (Intf:
       (QueryInterface: @TValueTimestamp.QueryInterface;
        AddRef: @TRefCountedInterface.AddRef;
        Release: @TRefCountedInterface.Release);
      GetBsonType: @TValueTimestamp.GetBsonType;
      AsBoolean: @TValue.AsBoolean;
      AsInteger: @TValue.AsInteger;
      AsInt64: @TValue.AsInt64;
      AsDouble: @TValue.AsDouble;
      AsString: @TValue.AsString;
      AsArray: @TValue.AsArray;
      AsByteArray: @TValue.AsByteArray;
      AsGuid: @TValue.AsGuid;
      AsObjectId: @TValue.AsObjectId;

      ToBoolean: @TValue.ToBoolean;
      ToDouble: @TValue.ToDouble;
      ToInteger: @TValue.ToInteger;
      ToInt64: @TValue.ToInt64;
      ToString: @TValue.ToString;
      ToLocalTime: @TValue.ToLocalTime;
      ToUniversalTime: @TValue.ToUniversalTime;
      ToByteArray: @TValue.ToByteArray;
      ToGuid: @TValue.ToGuid;
      ToObjectId: @TValue.ToObjectId;

      Equals: @TValueTimestamp.Equals;

      Clone: @TValue.Clone;
      DeepClone: @TValue.DeepClone);

    GetIncrement: @TValueTimestamp.GetIncrement;
    GetTimestamp: @TValueTimestamp.GetTimestamp;
    GetValue: @TValueTimestamp.GetValue);

type
  TValueMaxKey = record {TValue, TgoBsonMaxKey._IMaxKey}
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  end;

const
  VTABLE_MAX_KEY: TVTableValue = (
    Intf:
      (QueryInterface: @TValueMaxKey.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueMaxKey.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValue.ToBoolean;
    ToDouble: @TValue.ToDouble;
    ToInteger: @TValue.ToInteger;
    ToInt64: @TValue.ToInt64;
    ToString: @TValueMaxKey.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueMaxKey.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.Clone);

const
  VALUE_MAX_KEY: Pointer = @VTABLE_MAX_KEY;

type
  TValueMinKey = record {TValue, TgoBsonMinKey._IMinKey}
  public
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  public
    { TgoBsonValue._IValue }
    function GetBsonType: TgoBsonType;
    function ToString(const ADefault: String): String;
    function Equals(const AOther: TgoBsonValue._IValue): Boolean;
  end;

const
  VTABLE_MIN_KEY: TVTableValue = (
    Intf:
      (QueryInterface: @TValueMinKey.QueryInterface;
       AddRef: @TNonRefCountedInterface.AddRef;
       Release: @TNonRefCountedInterface.Release);
    GetBsonType: @TValueMinKey.GetBsonType;
    AsBoolean: @TValue.AsBoolean;
    AsInteger: @TValue.AsInteger;
    AsInt64: @TValue.AsInt64;
    AsDouble: @TValue.AsDouble;
    AsString: @TValue.AsString;
    AsArray: @TValue.AsArray;
    AsByteArray: @TValue.AsByteArray;
    AsGuid: @TValue.AsGuid;
    AsObjectId: @TValue.AsObjectId;

    ToBoolean: @TValue.ToBoolean;
    ToDouble: @TValue.ToDouble;
    ToInteger: @TValue.ToInteger;
    ToInt64: @TValue.ToInt64;
    ToString: @TValueMinKey.ToString;
    ToLocalTime: @TValue.ToLocalTime;
    ToUniversalTime: @TValue.ToUniversalTime;
    ToByteArray: @TValue.ToByteArray;
    ToGuid: @TValue.ToGuid;
    ToObjectId: @TValue.ToObjectId;

    Equals: @TValueMinKey.Equals;

    Clone: @TValue.Clone;
    DeepClone: @TValue.Clone);

const
  VALUE_MIN_KEY: Pointer = @VTABLE_MIN_KEY;

function _goBsonValueFromDouble(const AValue: Double): TgoBsonValue._IValue;
begin
  if (not AValue.IsNan) and (AValue = 0) then
    Result := TValueDoubleZero.FValue
  else
    Result := TValueDouble.Create(AValue);
end;

function _goBsonValueFromString(const AValue: String): TgoBsonValue._IValue;
begin
  if (AValue = '') then
    Result := TValueStringEmpty.FValue
  else if (StringRefCount(AValue) < 0) then
    Result := TValueStringConstant.Create(AValue)
  else
    Result := TValueString.Create(AValue);
end;

function _goBsonValueFromObjectId(const AValue: TgoObjectId): TgoBsonValue._IValue;
begin
  Result := TValueObjectId.Create(AValue);
end;

function _goBsonValueFromBoolean(const AValue: Boolean): TgoBsonValue._IValue;
begin
  if (AValue) then
    Result := TValueTrue.FValue
  else
    Result := TValueFalse.FValue;
end;

function _goBsonValueFromDateTime(const AValue: Int64): TgoBsonValue._IValue;
begin
  Result := TValueDateTime.Create(AValue);
end;

function _goBsonValueFromInt32(const AValue: Int32): TgoBsonValue._IValue;
begin
  if (AValue >= TValueIntegerConst.MIN_PRECREATED_VALUE) and (AValue <= TValueIntegerConst.MAX_PRECREATED_VALUE) then
    Result := TValueIntegerConst.FPrecreatedValues[AValue]
  else
    Result := TValueInteger.Create(AValue);
end;

function _goBsonValueFromInt64(const AValue: Int64): TgoBsonValue._IValue;
begin
  if (AValue >= TValueInt64Const.MIN_PRECREATED_VALUE) and (AValue <= TValueInt64Const.MAX_PRECREATED_VALUE) then
    Result := TValueInt64Const.FPrecreatedValues[AValue]
  else
    Result := TValueInt64.Create(AValue);
end;

function _goCreateArray: TgoBsonArray._IArray;
begin
  Result := TValueArray.Create;
end;

function _goCreateDocument: TgoBsonDocument._IDocument;
begin
  Result := TValueDocument.Create;
end;

procedure _goGetBinaryData(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonBinaryData);
begin
  ASrc.QueryInterface(TgoBsonBinaryData._IBinaryData, ADst.FImpl);
end;

procedure _goGetDateTime(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonDateTime);
begin
  ASrc.QueryInterface(TgoBsonDateTime._IDateTime, ADst.FImpl);
end;

procedure _goGetRegularExpression(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonRegularExpression);
begin
  ASrc.QueryInterface(TgoBsonRegularExpression._IRegularExpression, ADst.FImpl);
end;

procedure _goGetJavaScript(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonJavaScript);
begin
  ASrc.QueryInterface(TgoBsonJavaScript._IJavaScript, ADst.FImpl);
end;

procedure _goGetJavaScriptWithScope(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonJavaScriptWithScope);
begin
  ASrc.QueryInterface(TgoBsonJavaScriptWithScope._IJavaScriptWithScope, ADst.FImpl);
end;

procedure _goGetSymbol(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonSymbol);
begin
  ASrc.QueryInterface(TgoBsonSymbol._ISymbol, ADst.FImpl);
end;

procedure _goGetTimestamp(const ASrc: TgoBsonValue._IValue;
  out ADst: TgoBsonTimestamp);
begin
  ASrc.QueryInterface(TgoBsonTimestamp._ITimestamp, ADst.FImpl);
end;

{ TgoJsonWriterSettings }

class constructor TgoJsonWriterSettings.Create;
begin
  FDefault := TgoJsonWriterSettings.Create;
  FShell := TgoJsonWriterSettings.Create(TgoJsonOutputMode.Shell);
  FPretty := TgoJsonWriterSettings.Create('  ', #13#10, TgoJsonOutputMode.Strict);
end;

class function TgoJsonWriterSettings.Create: TgoJsonWriterSettings;
begin
  Result.FPrettyPrint := False;
  Result.FIndent := '  ';
  Result.FLineBreak := #13#10;
  Result.FOutputMode := TgoJsonOutputMode.Strict;
end;

class function TgoJsonWriterSettings.Create(const AIndent, ALineBreak: String;
  const AOutputMode: TgoJsonOutputMode): TgoJsonWriterSettings;
begin
  Result.FPrettyPrint := True;
  Result.FIndent := AIndent;
  Result.FLineBreak := ALineBreak;
  Result.FOutputMode := AOutputMode;
end;

class function TgoJsonWriterSettings.Create(
  const AOutputMode: TgoJsonOutputMode): TgoJsonWriterSettings;
begin
  Result.FPrettyPrint := False;
  Result.FIndent := '  ';
  Result.FLineBreak := #13#10;
  Result.FOutputMode := AOutputMode;
end;

class function TgoJsonWriterSettings.Create(const APrettyPrint: Boolean;
  const AOutputMode: TgoJsonOutputMode): TgoJsonWriterSettings;
begin
  Result.FPrettyPrint := APrettyPrint;
  Result.FIndent := '  ';
  Result.FLineBreak := #13#10;
  Result.FOutputMode := AOutputMode;
end;

{ TgoObjectId }

class function TgoObjectId.Create(const ABytes: TBytes): TgoObjectId;
begin
  if (Length(ABytes) <> 12) then
    EArgumentException.CreateRes(@sArgumentInvalid);
  Result.FromByteArray(ABytes);
end;

class function TgoObjectId.Create(const ABytes: array of Byte): TgoObjectId;
var
  Bytes: TBytes;
begin
  if (Length(ABytes) <> 12) then
    EArgumentException.CreateRes(@sArgumentInvalid);
  SetLength(Bytes, 12);
  Move(ABytes[0], Bytes[0], 12);
  Result := Create(Bytes);
end;

class function TgoObjectId.Create(const ATimestamp, AMachine: Integer;
  const APid: UInt16; const AIncrement: Integer): TgoObjectId;
begin
  if ((AMachine and $FF000000) <> 0) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  if ((AIncrement and $FF000000) <> 0) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  Result.FData[0] := UInt32(ATimestamp);
  Result.FData[1] := UInt32((AMachine shl 8) or (APid shr 8));
  Result.FData[2] := UInt32((APid shl 24) or AIncrement);
end;

procedure TgoObjectId.FromByteArray(const ABytes: TBytes);
begin
  FBytes[00] := ABytes[03];
  FBytes[01] := ABytes[02];
  FBytes[02] := ABytes[01];
  FBytes[03] := ABytes[00];
  FBytes[04] := ABytes[07];
  FBytes[05] := ABytes[06];
  FBytes[06] := ABytes[05];
  FBytes[07] := ABytes[04];
  FBytes[08] := ABytes[11];
  FBytes[09] := ABytes[10];
  FBytes[10] := ABytes[09];
  FBytes[11] := ABytes[08];
end;

class function TgoObjectId.GenerateNewId: TgoObjectId;
begin
  Result := GenerateNewId(GetTimestampFromDateTime(Now, False));
end;

class function TgoObjectId.GenerateNewId(const ATimestamp: TDateTime;
  const ATimestampIsUTC: Boolean): TgoObjectId;
begin
  Result := GenerateNewId(GetTimestampFromDateTime(ATimestamp, ATimestampIsUTC));
end;

class function TgoObjectId.GenerateNewId(
  const ATimestamp: Integer): TgoObjectId;
var
  Increment: Integer;
begin
  if (not FInitialized) then
    Initialize;

  Increment := AtomicIncrement(FIncrement) and $00FFFFFF;
  Result := TgoObjectId.Create(ATimestamp, FMachine, FPid, Increment);
end;

function TgoObjectId.GetCreationTime: TDateTime;
begin
  Result := IncSecond(UnixDateDelta, Timestamp);
end;

function TgoObjectId.GetIncrement: Integer;
begin
  Result := FData[2] and $FFFFFF;
end;

function TgoObjectId.GetIsEmpty: Boolean;
begin
  Result := (FData[0] = 0) and (FData[1] = 0) and (FData[2] = 0);
end;

function TgoObjectId.GetMachine: Integer;
begin
  Result := FData[1] shr 8;
end;

function TgoObjectId.GetPid: UInt16;
begin
  Result := UInt16((FData[1] shl 8) or (FData[2] shr 24));
end;

function TgoObjectId.GetTimestamp: Integer;
begin
  Result := Int32(FData[0]);
end;

class function TgoObjectId.GetTimestampFromDateTime(
  const ATimestamp: TDateTime; const ATimestampIsUTC: Boolean): Integer;
var
  DateTime: TDateTime;
  SecondsSinceEpoch: Int64;
begin
  if (ATimestampIsUTC) then
    DateTime := ATimestamp
  else
    DateTime := TTimeZone.Local.ToUniversalTime(ATimestamp);

  SecondsSinceEpoch := SecondsBetween(DateTime, UnixDateDelta);
  if (DateTime < UnixDateDelta) then
    SecondsSinceEpoch := -SecondsSinceEpoch;

  if (SecondsSinceEpoch < Integer.MinValue) or (SecondsSinceEpoch > Integer.MaxValue) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  Result := SecondsSinceEpoch;
end;

class operator TgoObjectId.GreaterThan(const A,
  B: TgoObjectId): Boolean;
begin
  Result := (A.CompareTo(B) > 0);
end;

class operator TgoObjectId.GreaterThanOrEqual(const A,
  B: TgoObjectId): Boolean;
begin
  Result := (A.CompareTo(B) >= 0);
end;

class operator TgoObjectId.Implicit(const A: String): TgoObjectId;
begin
  Result := TgoObjectId.Create(A);
end;

class operator TgoObjectId.Implicit(const A: TgoObjectId): String;
begin
  Result := A.ToString;
end;

class procedure TgoObjectId.Initialize;
var
  MachineName: String;
begin
  FIncrement := Random($1000000);

  MachineName := goGetMachineName;
  FMachine := goMurmurHash2(MachineName[Low(String)], Length(MachineName) * SizeOf(Char)) and $00FFFFFF;
  FPid := goGetCurrentProcessId;

  FInitialized := True;
end;

class operator TgoObjectId.LessThan(const A, B: TgoObjectId): Boolean;
begin
  Result := (A.CompareTo(B) < 0);
end;

class operator TgoObjectId.LessThanOrEqual(const A,
  B: TgoObjectId): Boolean;
begin
  Result := (A.CompareTo(B) <= 0);
end;

class operator TgoObjectId.NotEqual(const A, B: TgoObjectId): Boolean;
begin
  Result := (A.FData[0] <> B.FData[0])
         or (A.FData[1] <> B.FData[1])
         or (A.FData[2] <> B.FData[2])
end;

class function TgoObjectId.Parse(const AString: String): TgoObjectId;
begin
  Result := TgoObjectId.Create(AString);
end;

function TgoObjectId.ToByteArray: TBytes;
begin
  SetLength(Result, 12);
  ToByteArray(Result, 0);
end;

procedure TgoObjectId.ToByteArray(const ADestination: TBytes;
  const AOffset: Integer);
begin
  if ((AOffset + 12) > Length(ADestination)) then
    EArgumentException.Create('Not enough room in ADestination');

  ADestination[AOffset + 00] := FBytes[03];
  ADestination[AOffset + 01] := FBytes[02];
  ADestination[AOffset + 02] := FBytes[01];
  ADestination[AOffset + 03] := FBytes[00];
  ADestination[AOffset + 04] := FBytes[07];
  ADestination[AOffset + 05] := FBytes[06];
  ADestination[AOffset + 06] := FBytes[05];
  ADestination[AOffset + 07] := FBytes[04];
  ADestination[AOffset + 08] := FBytes[11];
  ADestination[AOffset + 09] := FBytes[10];
  ADestination[AOffset + 10] := FBytes[09];
  ADestination[AOffset + 11] := FBytes[08];
end;

function TgoObjectId.ToString: String;
begin
  Result := goToHexString(ToByteArray);
end;

class function TgoObjectId.TryParse(const AString: String;
  out AObjectId: TgoObjectId): Boolean;
var
  Bytes: TBytes;
begin
  Result := (Length(AString) = 24) and goTryParseHexString(AString, Bytes);
  if (Result) then
    AObjectId := TgoObjectId.Create(Bytes)
  else
    AObjectId := Default(TgoObjectId);
end;

class function TgoObjectId.Create(const ATimestamp: TDateTime;
  const ATimestampIsUTC: Boolean; const AMachine: Integer; const APid: UInt16;
  const AIncrement: Integer): TgoObjectId;
begin
  Result := Create(GetTimestampFromDateTime(ATimestamp, ATimestampIsUTC),
    AMachine, APId, AIncrement);
end;

class function TgoObjectId.Create(const AString: String): TgoObjectId;
var
  Bytes: TBytes;
begin
  if (Length(AString) <> 24) then
    raise EArgumentException.CreateRes(@SArgumentOutOfRange);
  Bytes := goParseHexString(AString);
  Result.FromByteArray(Bytes);
end;

function TgoObjectId.CompareTo(const AOther: TgoObjectId): Integer;
begin
  if (FData[0] < AOther.FData[0]) then
    Exit(-1);
  if (FData[0] > AOther.FData[0]) then
    Exit(1);

  if (FData[1] < AOther.FData[1]) then
    Exit(-1);
  if (FData[1] > AOther.FData[1]) then
    Exit(1);

  if (FData[2] < AOther.FData[2]) then
    Exit(-1);
  if (FData[2] > AOther.FData[2]) then
    Exit(1);

  Result := 0;
end;

class function TgoObjectId.Empty: TgoObjectId;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

class operator TgoObjectId.Equal(const A, B: TgoObjectId): Boolean;
begin
  Result := (A.FData[0] = B.FData[0])
        and (A.FData[1] = B.FData[1])
        and (A.FData[2] = B.FData[2])
end;

class constructor TgoObjectId.Create;
begin
  FInitialized := False;
end;

{ TgoBsonValue }

function TgoBsonValue.AsArray: TArray<TgoBsonValue>;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsArray;
end;

function TgoBsonValue.AsBoolean: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsBoolean;
end;

function TgoBsonValue.AsByteArray: TBytes;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsByteArray;
end;

function TgoBsonValue.AsDouble: Double;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsDouble;
end;

function TgoBsonValue.AsGuid: TGUID;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsGuid;
end;

function TgoBsonValue.AsInt64: Int64;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsInt64;
end;

function TgoBsonValue.AsInteger: Integer;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsInteger;
end;

function TgoBsonValue.AsObjectId: TgoObjectId;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsObjectId;
end;

function TgoBsonValue.AsString: String;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsString;
end;

function TgoBsonValue.Clone: TgoBsonValue;
begin
  Assert(Assigned(FImpl));
  Result.FImpl := FImpl.Clone;
end;

function TgoBsonValue.DeepClone: TgoBsonValue;
begin
  Assert(Assigned(FImpl));
  Result.FImpl := FImpl.DeepClone;
end;

class operator TgoBsonValue.Equal(const A, B: TgoBsonValue): Boolean;
begin
  if (A.FImpl = nil) then
    Result := (B.FImpl = nil)
  else if (B.FImpl = nil) then
    Result := False
  else
    Result := A.FImpl.Equals(B.FImpl);
end;

function TgoBsonValue.GetBsonType: TgoBsonType;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.BsonType;
end;

function TgoBsonValue.GetIsBoolean: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Boolean);
end;

function TgoBsonValue.GetIsBsonArray: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.&Array);
end;

function TgoBsonValue.GetIsBsonBinaryData: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Binary);
end;

function TgoBsonValue.GetIsBsonDateTime: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.DateTime);
end;

function TgoBsonValue.GetIsBsonDocument: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Document);
end;

function TgoBsonValue.GetIsBsonJavaScript: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType in [TgoBsonType.JavaScript, TgoBsonType.JavaScriptWithScope]);
end;

function TgoBsonValue.GetIsBsonJavaScriptWithScope: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.JavaScriptWithScope);
end;

function TgoBsonValue.GetIsBsonMaxKey: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.MaxKey);
end;

function TgoBsonValue.GetIsBsonMinKey: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.MinKey);
end;

function TgoBsonValue.GetIsBsonNull: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Null);
end;

function TgoBsonValue.GetIsBsonRegularExpression: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.RegularExpression);
end;

function TgoBsonValue.GetIsBsonSymbol: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Symbol);
end;

function TgoBsonValue.GetIsBsonTimestamp: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Timestamp);
end;

function TgoBsonValue.GetIsBsonUndefined: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Undefined);
end;

function TgoBsonValue.GetIsDateTime: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.DateTime);
end;

function TgoBsonValue.GetIsDouble: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Double);
end;

function TgoBsonValue.GetIsGuid: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Binary)
    and (AsBsonBinaryData.SubType in [TgoBsonBinarySubType.UuidLegacy, TgoBsonBinarySubType.UuidStandard]);
end;

function TgoBsonValue.GetIsInt32: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Int32);
end;

function TgoBsonValue.GetIsInt64: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.Int64);
end;

function TgoBsonValue.GetIsNumeric: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType in [TgoBsonType.Int32, TgoBsonType.Int64, TgoBsonType.Double]);
end;

function TgoBsonValue.GetIsObjectId: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.ObjectId);
end;

function TgoBsonValue.GetIsString: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := (FImpl.BsonType = TgoBsonType.String);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): Int64;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToInt64(0);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): Double;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToDouble(0);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): Boolean;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToBoolean(False);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): Integer;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToInteger(0);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): Extended;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToDouble(0);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): TBytes;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToByteArray;
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): TGUID;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToGuid;
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): TDateTime;
begin
  Assert(Assigned(A.FImpl));
  Result := A.ToUniversalTime;
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): String;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToString('');
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): TgoObjectId;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToObjectId;
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): Single;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToDouble(0);
end;

class operator TgoBsonValue.Implicit(const A: Single): TgoBsonValue;
begin
  if (not A.IsNan) and (A = 0) then
    Result.FImpl := TValueDoubleZero.FValue
  else
    Result.FImpl := TValueDouble.Create(A);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): UInt32;
begin
  Assert(Assigned(A.FImpl));
  Result := UInt32(A.FImpl.ToInteger(0));
end;

class operator TgoBsonValue.Implicit(const A: UInt32): TgoBsonValue;
begin
  if (A <= TValueIntegerConst.MAX_PRECREATED_VALUE) then
    Result.FImpl := TValueIntegerConst.FPrecreatedValues[A]
  else
    Result.FImpl := TValueInteger.Create(Int32(A));
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): UInt16;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToInteger(0);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): Int16;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToInteger(0);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): UInt8;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToInteger(0);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): Int8;
begin
  Assert(Assigned(A.FImpl));
  Result := A.FImpl.ToInteger(0);
end;

class operator TgoBsonValue.Implicit(const A: UInt64): TgoBsonValue;
begin
  if (A <= TValueInt64Const.MAX_PRECREATED_VALUE) then
    Result.FImpl := TValueInt64Const.FPrecreatedValues[A]
  else
    Result.FImpl := TValueInt64.Create(A);
end;

class operator TgoBsonValue.Implicit(const A: TgoBsonValue): UInt64;
begin
  Assert(Assigned(A.FImpl));
  Result := UInt64(A.FImpl.ToInt64(0));
end;

function TgoBsonValue.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class function TgoBsonValue.Load(const ABson: TBytes): TgoBsonValue;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Create(ABson);
  Result := Reader.ReadValue;
end;

class function TgoBsonValue.LoadFromBsonFile(
  const AFilename: String): TgoBsonValue;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Load(AFilename);
  Result := Reader.ReadValue;
end;

class function TgoBsonValue.LoadFromBsonStream(
  const AStream: TStream): TgoBsonValue;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Load(AStream);
  Result := Reader.ReadValue;
end;

class function TgoBsonValue.LoadFromJsonFile(
  const AFilename: String): TgoBsonValue;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Load(AFilename);
  Result := Reader.ReadValue;
end;

class function TgoBsonValue.LoadFromJsonStream(
  const AStream: TStream): TgoBsonValue;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Load(AStream);
  Result := Reader.ReadValue;
end;

class operator TgoBsonValue.Implicit(const A: Boolean): TgoBsonValue;
begin
  if (A) then
    Result.FImpl := TValueTrue.FValue
  else
    Result.FImpl := TValueFalse.FValue;
end;

class operator TgoBsonValue.Implicit(const A: Double): TgoBsonValue;
begin
  if (not A.IsNan) and (A = 0) then
    Result.FImpl := TValueDoubleZero.FValue
  else
    Result.FImpl := TValueDouble.Create(A);
end;

class operator TgoBsonValue.Implicit(const A: Integer): TgoBsonValue;
begin
  if (A >= TValueIntegerConst.MIN_PRECREATED_VALUE) and (A <= TValueIntegerConst.MAX_PRECREATED_VALUE) then
    Result.FImpl := TValueIntegerConst.FPrecreatedValues[A]
  else
    Result.FImpl := TValueInteger.Create(A);
end;

class operator TgoBsonValue.Implicit(const A: Int64): TgoBsonValue;
begin
  if (A >= TValueInt64Const.MIN_PRECREATED_VALUE) and (A <= TValueInt64Const.MAX_PRECREATED_VALUE) then
    Result.FImpl := TValueInt64Const.FPrecreatedValues[A]
  else
    Result.FImpl := TValueInt64.Create(A);
end;

class operator TgoBsonValue.Implicit(const A: String): TgoBsonValue;
begin
  if (A = '') then
    Result.FImpl := TValueStringEmpty.FValue
  else if (StringRefCount(A) < 0) then
    Result.FImpl := TValueStringConstant.Create(A)
  else
    Result.FImpl := TValueString.Create(A);
end;

class operator TgoBsonValue.Implicit(const A: TBytes): TgoBsonValue;
begin
  Result.FImpl := TValueBinaryData.Create(A);
end;

class operator TgoBsonValue.Implicit(const A: Extended): TgoBsonValue;
var
  D: Double;
begin
  D := A;
  Result := D;
end;

class operator TgoBsonValue.Implicit(const A: TDateTime): TgoBsonValue;
begin
  Result.FImpl := TValueDateTime.Create(A, True);
end;

class operator TgoBsonValue.Implicit(const A: TGUID): TgoBsonValue;
begin
  Result.FImpl := TValueBinaryData.Create(A);
end;

class operator TgoBsonValue.Implicit(const A: TgoObjectId): TgoBsonValue;
begin
  Result.FImpl := TValueObjectId.Create(A);
end;

class operator TgoBsonValue.NotEqual(const A, B: TgoBsonValue): Boolean;
begin
  Result := not (A = B);
end;

class function TgoBsonValue.Parse(const AJson: String): TgoBsonValue;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Create(AJson);
  Result := Reader.ReadValue;
end;

procedure TgoBsonValue.SaveToBsonFile(const AFilename: String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToBsonStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TgoBsonValue.SaveToBsonStream(const AStream: TStream);
var
  Bson: TBytes;
begin
  Bson := ToBson;
  AStream.Write(Bson, Length(Bson));
end;

procedure TgoBsonValue.SaveToJsonFile(const AFilename: String;
  const ASettings: TgoJsonWriterSettings);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToJsonStream(Stream, ASettings);
  finally
    Stream.Free;
  end;
end;

procedure TgoBsonValue.SaveToJsonFile(const AFilename: String);
begin
  SaveToJsonFile(AFilename, TgoJsonWriterSettings.Default);
end;

procedure TgoBsonValue.SaveToJsonStream(const AStream: TStream);
begin
  SaveToJsonStream(AStream, TgoJsonWriterSettings.Default);
end;

procedure TgoBsonValue.SaveToJsonStream(const AStream: TStream;
  const ASettings: TgoJsonWriterSettings);
var
  Writer: TStreamWriter;
  Json: String;
begin
  Json := ToJson(ASettings);
  Writer := TStreamWriter.Create(AStream);
  try
    Writer.Write(Json);
  finally
    Writer.Free;
  end;
end;

procedure TgoBsonValue.SetNil;
begin
  FImpl := nil;
end;

function TgoBsonValue.ToJson: String;
begin
  Result := ToJson(TgoJsonWriterSettings.Default);
end;

function TgoBsonValue.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToBoolean(ADefault);
end;

function TgoBsonValue.ToBson: TBytes;
var
  Writer: IgoBsonWriter;
begin
  Assert(Assigned(FImpl));
  Writer := TgoBsonWriter.Create;
  Writer.WriteValue(Self);
  Result := Writer.ToBson;
end;

function TgoBsonValue.ToDouble(const ADefault: Double): Double;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToDouble(ADefault);
end;

function TgoBsonValue.ToGuid: TGUID;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToGuid;
end;

function TgoBsonValue.ToInt64(const ADefault: Int64): Int64;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToInt64(ADefault);
end;

function TgoBsonValue.ToInteger(const ADefault: Integer): Integer;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToInteger(ADefault);
end;

function TgoBsonValue.ToJson(const ASettings: TgoJsonWriterSettings): String;
var
  Writer: IgoJsonWriter;
begin
  Assert(Assigned(FImpl));
  Writer := TgoJsonWriter.Create(ASettings);
  Writer.WriteValue(Self);
  Result := Writer.ToJson;
end;

function TgoBsonValue.ToLocalTime: TDateTime;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToLocalTime;
end;

function TgoBsonValue.ToObjectId: TgoObjectId;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToObjectId;
end;

function TgoBsonValue.ToString(const ADefault: String): String;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToString(ADefault);
end;

function TgoBsonValue.ToUniversalTime: TDateTime;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToUniversalTime;
end;

class function TgoBsonValue.TryLoad(const ABson: TBytes;
  out AValue: TgoBsonValue): Boolean;
var
  Reader: IgoBsonReader;
begin
  try
    Reader := TgoBsonReader.Create(ABson);
    AValue := Reader.ReadValue;
    Result := True;
  except
    AValue.FImpl := nil;
    Result := False;
  end;
end;

class function TgoBsonValue.TryParse(const AJson: String;
  out AValue: TgoBsonValue): Boolean;
var
  Reader: IgoJsonReader;
begin
  try
    Reader := TgoJsonReader.Create(AJson);
    AValue := Reader.ReadValue;
    Result := True;
  except
    AValue.FImpl := nil;
    Result := False;
  end;
end;

{ TgoBsonValueHelper }

function TgoBsonValueHelper.AsBsonBinaryData: TgoBsonBinaryData;
begin
  if (FImpl.QueryInterface(TgoBsonBinaryData._IBinaryData, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonBinaryData)');
end;

function TgoBsonValueHelper.AsBsonArray: TgoBsonArray;
begin
  if (FImpl.QueryInterface(TgoBsonArray._IArray, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonArray)');
end;

function TgoBsonValueHelper.AsBsonDateTime: TgoBsonDateTime;
begin
  if (FImpl.QueryInterface(TgoBsonDateTime._IDateTime, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonDateTime)');
end;

function TgoBsonValueHelper.AsBsonDocument: TgoBsonDocument;
begin
  if (FImpl.QueryInterface(TgoBsonDocument._IDocument, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonDocument)');
end;

function TgoBsonValueHelper.AsBsonJavaScript: TgoBsonJavaScript;
begin
  if (FImpl.QueryInterface(TgoBsonJavaScript._IJavaScript, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonJavaScript)');
end;

function TgoBsonValueHelper.AsBsonJavaScriptWithScope: TgoBsonJavaScriptWithScope;
begin
  if (FImpl.QueryInterface(TgoBsonJavaScriptWithScope._IJavaScriptWithScope, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonJavaScriptWithScope)');
end;

function TgoBsonValueHelper.AsBsonMaxKey: TgoBsonMaxKey;
begin
  if (FImpl.QueryInterface(TgoBsonMaxKey._IMaxKey, Result.FValue) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonMaxKey)');
end;

function TgoBsonValueHelper.AsBsonMinKey: TgoBsonMinKey;
begin
  if (FImpl.QueryInterface(TgoBsonMinKey._IMinKey, Result.FValue) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonMinKey)');
end;

function TgoBsonValueHelper.AsBsonNull: TgoBsonNull;
begin
  if (FImpl.QueryInterface(TgoBsonNull._INull, Result.FValue) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonNull)');
end;

function TgoBsonValueHelper.AsBsonRegularExpression: TgoBsonRegularExpression;
begin
  if (FImpl.QueryInterface(TgoBsonRegularExpression._IRegularExpression, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonRegularExpression)');
end;

function TgoBsonValueHelper.AsBsonSymbol: TgoBsonSymbol;
begin
  if (FImpl.QueryInterface(TgoBsonSymbol._ISymbol, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonSymbol)');
end;

function TgoBsonValueHelper.AsBsonTimestamp: TgoBsonTimestamp;
begin
  if (FImpl.QueryInterface(TgoBsonTimestamp._ITimestamp, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonTimestamp)');
end;

function TgoBsonValueHelper.AsBsonUndefined: TgoBsonUndefined;
begin
  if (FImpl.QueryInterface(TgoBsonUndefined._IUndefined, Result.FValue) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonValue.AsBsonUndefined)');
end;

function TgoBsonValueHelper.ToBsonArray: TgoBsonArray;
begin
  if (FImpl.QueryInterface(TgoBsonArray._IArray, Result.FImpl) <> S_OK) then
    Result := TgoBsonArray.Create;
end;

function TgoBsonValueHelper.ToBsonDocument: TgoBsonDocument;
begin
  if (FImpl.QueryInterface(TgoBsonDocument._IDocument, Result.FImpl) <> S_OK) then
    Result := TgoBsonDocument.Create;
end;

{ TgoBsonArray }

function TgoBsonArray.Add(const AValue: TgoBsonValue): TgoBsonArray;
begin
  Assert(Assigned(FImpl));
  FImpl.Add(AValue.FImpl);
  Result.FImpl := FImpl;
end;

function TgoBsonArray.AddRange(
  const AValues: array of TgoBsonValue): TgoBsonArray;
begin
  Assert(Assigned(FImpl));
  FImpl.AddRange(AValues);
  Result.FImpl := FImpl;
end;

function TgoBsonArray.AddRange(
  const AValues: TArray<TgoBsonValue>): TgoBsonArray;
begin
  Assert(Assigned(FImpl));
  FImpl.AddRange(AValues);
  Result.FImpl := FImpl;
end;

function TgoBsonArray.AddRange(const AValues: TgoBsonArray): TgoBsonArray;
begin
  Assert(Assigned(FImpl));
  FImpl.AddRange(AValues);
  Result.FImpl := FImpl;
end;

class function TgoBsonArray.Create(const ACapacity: Integer): TgoBsonArray;
begin
  Result.FImpl := TValueArray.Create(ACapacity);
end;

class function TgoBsonArray.Create(const AValues: array of TgoBsonValue): TgoBsonArray;
begin
  Result.FImpl := TValueArray.Create(AValues);
end;

function TgoBsonArray.Clear: TgoBsonArray;
begin
  Assert(Assigned(FImpl));
  FImpl.Clear;
  Result.FImpl := FImpl;
end;

function TgoBsonArray.Clone: TgoBsonArray;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.Clone;
  if (C.QueryInterface(TgoBsonArray._IArray, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonArray.Clone)');
end;

function TgoBsonArray.Contains(const AValue: TgoBsonValue): Boolean;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Contains(AValue);
end;

class function TgoBsonArray.Create(const AValues: TArray<TgoBsonValue>): TgoBsonArray;
begin
  Result.FImpl := TValueArray.Create(AValues);
end;

function TgoBsonArray.DeepClone: TgoBsonArray;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.DeepClone;
  if (C.QueryInterface(TgoBsonArray._IArray, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonArray.DeepClone)');
end;

procedure TgoBsonArray.Delete(const AIndex: Integer);
begin
  Assert(Assigned(FImpl));
  FImpl.Delete(AIndex);
end;

class operator TgoBsonArray.Equal(const A, B: TgoBsonArray): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

function TgoBsonArray.GetCount: Integer;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Count;
end;

function TgoBsonArray.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(FImpl);
end;

function TgoBsonArray.GetItem(const AIndex: Integer): TgoBsonValue;
begin
  FImpl.GetItem(AIndex, Result.FImpl);
end;

class operator TgoBsonArray.Implicit(const A: TgoBsonArray): TgoBsonValue;
begin
  Result.FImpl := A.FImpl;
end;

function TgoBsonArray.IndexOf(const AValue: TgoBsonValue): Integer;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.IndexOf(AValue);
end;

function TgoBsonArray.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class function TgoBsonArray.Load(const ABson: TBytes): TgoBsonArray;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Create(ABson);
  Result := Reader.ReadArray;
end;

class function TgoBsonArray.LoadFromBsonFile(
  const AFilename: String): TgoBsonArray;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Load(AFilename);
  Result := Reader.ReadArray;
end;

class function TgoBsonArray.LoadFromBsonStream(
  const AStream: TStream): TgoBsonArray;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Load(AStream);
  Result := Reader.ReadArray;
end;

class function TgoBsonArray.LoadFromJsonFile(
  const AFilename: String): TgoBsonArray;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Load(AFilename);
  Result := Reader.ReadArray;
end;

class function TgoBsonArray.LoadFromJsonStream(
  const AStream: TStream): TgoBsonArray;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Load(AStream);
  Result := Reader.ReadArray;
end;

class operator TgoBsonArray.NotEqual(const A, B: TgoBsonArray): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

class function TgoBsonArray.Parse(const AJson: String): TgoBsonArray;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Create(AJson);
  Result := Reader.ReadArray;
end;

function TgoBsonArray.Remove(const AValue: TgoBsonValue): Boolean;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Remove(AValue);
end;

procedure TgoBsonArray.SaveToBsonFile(const AFilename: String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToBsonStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TgoBsonArray.SaveToBsonStream(const AStream: TStream);
var
  Bson: TBytes;
begin
  Bson := ToBson;
  AStream.Write(Bson, Length(Bson));
end;

procedure TgoBsonArray.SaveToJsonFile(const AFilename: String;
  const ASettings: TgoJsonWriterSettings);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToJsonStream(Stream, ASettings);
  finally
    Stream.Free;
  end;
end;

procedure TgoBsonArray.SaveToJsonFile(const AFilename: String);
begin
  SaveToJsonFile(AFilename, TgoJsonWriterSettings.Default);
end;

procedure TgoBsonArray.SaveToJsonStream(const AStream: TStream);
begin
  SaveToJsonStream(AStream, TgoJsonWriterSettings.Default);
end;

procedure TgoBsonArray.SaveToJsonStream(const AStream: TStream;
  const ASettings: TgoJsonWriterSettings);
var
  Json: String;
  Writer: TStreamWriter;
begin
  Json := ToJson(ASettings);
  Writer := TStreamWriter.Create(AStream);
  try
    Writer.Write(Json);
  finally
    Writer.Free;
  end;
end;

procedure TgoBsonArray.SetItem(const AIndex: Integer;
  const AValue: TgoBsonValue);
begin
  FImpl.SetItem(AIndex, AValue.FImpl);
end;

procedure TgoBsonArray.SetNil;
begin
  FImpl := nil;
end;

function TgoBsonArray.ToArray: TArray<TgoBsonValue>;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsArray;
end;

function TgoBsonArray.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonArray.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonArray.ToJson(const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

class function TgoBsonArray.TryLoad(const ABson: TBytes;
  out AArray: TgoBsonArray): Boolean;
var
  Reader: IgoBsonReader;
begin
  try
    Reader := TgoBsonReader.Create(ABson);
    AArray := Reader.ReadArray;
    Result := True;
  except
    AArray.FImpl := nil;
    Result := False;
  end;
end;

class function TgoBsonArray.TryParse(const AJson: String;
  out AArray: TgoBsonArray): Boolean;
var
  Reader: IgoJsonReader;
begin
  try
    Reader := TgoJsonReader.Create(AJson);
    AArray := Reader.ReadArray;
    Result := True;
  except
    AArray.FImpl := nil;
    Result := False;
  end;
end;

{ TgoBsonElement }

function TgoBsonElement.Clone: TgoBsonElement;
begin
  Result.FName := FName;
  Result.FImpl := FImpl;
end;

class function TgoBsonElement.Create(const AName: String;
  const AValue: TgoBsonValue): TgoBsonElement;
begin
  if (AValue.FImpl = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);
  Result.FName := AName;
  Result.FImpl := AValue.FImpl;
end;

function TgoBsonElement.DeepClone: TgoBsonElement;
begin
  Result.FName := FName;
  Result.FImpl := FImpl.DeepClone;
end;

class operator TgoBsonElement.Equal(const A, B: TgoBsonElement): Boolean;
begin
  Result := (A.FName = B.FName);
  if (Result) then
  begin
    if (A.FImpl = nil) then
      Result := (B.FImpl = nil)
    else if (B.FImpl = nil) then
      Result := False
    else
      Result := A.FImpl.Equals(B.FImpl);
  end;
end;

function TgoBsonElement.GetValue: TgoBsonValue;
begin
  Result.FImpl := FImpl;
end;

class operator TgoBsonElement.NotEqual(const A, B: TgoBsonElement): Boolean;
begin
  Result := not (A = B);
end;

{ TgoBsonArray.TEnumerator }

constructor TgoBsonArray.TEnumerator.Create(const AImpl: _IArray);
begin
  Assert(Assigned(AImpl));
  FImpl := AImpl;
  FHigh := AImpl.Count - 1;
  FIndex := -1;
end;

function TgoBsonArray.TEnumerator.GetCurrent: TgoBsonValue;
begin
  FImpl.GetItem(FIndex, Result.FImpl);
end;

function TgoBsonArray.TEnumerator.MoveNext: Boolean;
begin
  Result := (FIndex < FHigh);
  if Result then
    Inc(FIndex);
end;

{ TgoBsonDocument }

function TgoBsonDocument.Add(const AName: String; const AValue: TgoBsonValue): TgoBsonDocument;
begin
  Assert(Assigned(FImpl));
  FImpl.Add(AName, AValue.FImpl);
  Result.FImpl := FImpl;
end;

function TgoBsonDocument.Add(const AElement: TgoBsonElement): TgoBsonDocument;
begin
  Assert(Assigned(FImpl));
  FImpl.Add(AElement.FName, AElement.FImpl);
  Result.FImpl := FImpl;
end;

procedure TgoBsonDocument.Clear;
begin
  Assert(Assigned(FImpl));
  FImpl.Clear;
end;

function TgoBsonDocument.Clone: TgoBsonDocument;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.Clone;
  if (C.QueryInterface(TgoBsonDocument._IDocument, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonDocument.Clone)');
end;

class function TgoBsonDocument.Create: TgoBsonDocument;
begin
  Result.FImpl := TValueDocument.Create;
end;

class function TgoBsonDocument.Create(
  const AElement: TgoBsonElement): TgoBsonDocument;
begin
  Result.FImpl := TValueDocument.Create(AElement);
end;

class function TgoBsonDocument.Create(
  const AAllowDuplicateNames: Boolean): TgoBsonDocument;
begin
  Result.FImpl := TValueDocument.Create(AAllowDuplicateNames);
end;

class function TgoBsonDocument.Create(const AName: String;
  const AValue: TgoBsonValue): TgoBsonDocument;
begin
  Result.FImpl := TValueDocument.Create(AName, AValue);
end;

function TgoBsonDocument.Contains(const AName: String): Boolean;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Contains(AName);
end;

function TgoBsonDocument.ContainsValue(const AValue: TgoBsonValue): Boolean;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ContainsValue(AValue);
end;

function TgoBsonDocument.DeepClone: TgoBsonDocument;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.DeepClone;
  if (C.QueryInterface(TgoBsonDocument._IDocument, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonDocument.DeepClone)');
end;

procedure TgoBsonDocument.Delete(const AIndex: Integer);
begin
  Assert(Assigned(FImpl));
  FImpl.Delete(AIndex);
end;

class operator TgoBsonDocument.Equal(const A, B: TgoBsonDocument): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

function TgoBsonDocument.Get(const AName: String;
  const ADefault: TgoBsonValue): TgoBsonValue;
begin
  Assert(Assigned(FImpl));
  FImpl.Get(AName, ADefault.FImpl, Result.FImpl);
end;

function TgoBsonDocument.GetAllowDuplicateNames: Boolean;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AllowDuplicateNames;
end;

function TgoBsonDocument.GetCount: Integer;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Count;
end;

function TgoBsonDocument.GetElement(const AIndex: Integer): TgoBsonElement;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Elements[AIndex];
end;

function TgoBsonDocument.GetEnumerator: TEnumerator;
begin
  Result := TEnumerator.Create(FImpl);
end;

function TgoBsonDocument.GetValue(const AIndex: Integer): TgoBsonValue;
begin
  Assert(Assigned(FImpl));
  FImpl.GetValue(AIndex, Result.FImpl);
end;

function TgoBsonDocument.GetValueByName(const AName: String): TgoBsonValue;
begin
  Assert(Assigned(FImpl));
  FImpl.GetValueByName(AName, Result.FImpl);
end;

class operator TgoBsonDocument.Implicit(const A: TgoBsonDocument): TgoBsonValue;
begin
  Result.FImpl := A.FImpl;
end;

function TgoBsonDocument.IndexOfName(const AName: String): Integer;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.IndexOfName(AName);
end;

function TgoBsonDocument.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class function TgoBsonDocument.Load(const ABson: TBytes): TgoBsonDocument;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Create(ABson);
  Result := Reader.ReadDocument;
end;

class function TgoBsonDocument.LoadFromBsonFile(
  const AFilename: String): TgoBsonDocument;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Load(AFilename);
  Result := Reader.ReadDocument;
end;

class function TgoBsonDocument.LoadFromBsonStream(
  const AStream: TStream): TgoBsonDocument;
var
  Reader: IgoBsonReader;
begin
  Reader := TgoBsonReader.Load(AStream);
  Result := Reader.ReadDocument;
end;

class function TgoBsonDocument.LoadFromJsonFile(
  const AFilename: String): TgoBsonDocument;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Load(AFilename);
  Result := Reader.ReadDocument;
end;

class function TgoBsonDocument.LoadFromJsonStream(
  const AStream: TStream): TgoBsonDocument;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Load(AStream);
  Result := Reader.ReadDocument;
end;

function TgoBsonDocument.Merge(const AOtherDocument: TgoBsonDocument;
  const AOverwriteExistingElements: Boolean): TgoBsonDocument;
begin
  Assert(Assigned(FImpl));
  FImpl.Merge(AOtherDocument, AOverwriteExistingElements);
  Result.FImpl := FImpl;
end;

class operator TgoBsonDocument.NotEqual(const A, B: TgoBsonDocument): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

class function TgoBsonDocument.Parse(const AJson: String; AllowDuplicateNames : Boolean = false): TgoBsonDocument;
var
  Reader: IgoJsonReader;
begin
  Reader := TgoJsonReader.Create(AJson, AllowDuplicateNames);
  Result := Reader.ReadDocument;
end;

procedure TgoBsonDocument.Remove(const AName: String);
begin
  Assert(Assigned(FImpl));
  FImpl.Remove(AName);
end;

procedure TgoBsonDocument.SaveToBsonFile(const AFilename: String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToBsonStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TgoBsonDocument.SaveToBsonStream(const AStream: TStream);
var
  Bson: TBytes;
begin
  Bson := ToBson;
  AStream.Write(Bson, Length(Bson));
end;

procedure TgoBsonDocument.SaveToJsonFile(const AFilename: String;
  const ASettings: TgoJsonWriterSettings);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmCreate);
  try
    SaveToJsonStream(Stream, ASettings);
  finally
    Stream.Free;
  end;
end;

procedure TgoBsonDocument.SaveToJsonFile(const AFilename: String);
begin
  SaveToJsonFile(AFilename, TgoJsonWriterSettings.Default);
end;

procedure TgoBsonDocument.SaveToJsonStream(const AStream: TStream);
begin
  SaveToJsonStream(AStream, TgoJsonWriterSettings.Default);
end;

procedure TgoBsonDocument.SaveToJsonStream(const AStream: TStream;
  const ASettings: TgoJsonWriterSettings);
var
  Writer: TStreamWriter;
  Json: String;
begin
  Json := ToJson(ASettings);
  Writer := TStreamWriter.Create(AStream);
  try
    Writer.Write(Json);
  finally
    Writer.Free;
  end;
end;

procedure TgoBsonDocument.SetAllowDuplicateNames(const AValue: Boolean);
begin
  Assert(Assigned(FImpl));
  FImpl.AllowDuplicateNames := AValue;
end;

procedure TgoBsonDocument.SetNil;
begin
  FImpl := nil;
end;

procedure TgoBsonDocument.SetValue(const AIndex: Integer;
  const AValue: TgoBsonValue);
begin
  Assert(Assigned(FImpl));
  FImpl.SetValue(AIndex, AValue.FImpl);
end;

procedure TgoBsonDocument.SetValueByName(const AName: String;
  const AValue: TgoBsonValue);
begin
  Assert(Assigned(FImpl));
  FImpl.SetValueByName(AName, AValue.FImpl);
end;

function TgoBsonDocument.ToArray: TArray<TgoBsonElement>;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToArray;
end;

function TgoBsonDocument.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonDocument.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonDocument.ToJson(const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

function TgoBsonDocument.TryGetElement(const AName: String;
  out AElement: TgoBsonElement): Boolean;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.TryGetElement(AName, AElement);
end;

function TgoBsonDocument.TryGetValue(const AName: String;
  out AValue: TgoBsonValue): Boolean;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.TryGetValue(AName, AValue.FImpl);
end;

class function TgoBsonDocument.TryLoad(const ABson: TBytes;
  out ADocument: TgoBsonDocument): Boolean;
var
  Reader: IgoBsonReader;
begin
  try
    Reader := TgoBsonReader.Create(ABson);
    ADocument := Reader.ReadDocument;
    Result := True;
  except
    ADocument.FImpl := nil;
    Result := False;
  end;
end;

class function TgoBsonDocument.TryParse(const AJson: String;
  out ADocument: TgoBsonDocument; AllowDuplicateNames : Boolean = false): Boolean;
var
  Reader: IgoJsonReader;
begin
  try
    Reader := TgoJsonReader.Create(AJson, AllowDuplicateNames);
    ADocument := Reader.ReadDocument;
    Result := True;
  except
    ADocument.FImpl := nil;
    Result := False;
  end;
end;

{ TgoBsonDocument.TEnumerator }

constructor TgoBsonDocument.TEnumerator.Create(const AImpl: _IDocument);
begin
  Assert(Assigned(AImpl));
  FImpl := AImpl;
  FHigh := AImpl.Count - 1;
  FIndex := -1;
end;

function TgoBsonDocument.TEnumerator.GetCurrent: TgoBsonElement;
begin
  Result := FImpl.Elements[FIndex];
end;

function TgoBsonDocument.TEnumerator.MoveNext: Boolean;
begin
  Result := (FIndex < FHigh);
  if Result then
    Inc(FIndex);
end;

{ TgoBsonBinaryData }

function TgoBsonBinaryData.Clone: TgoBsonBinaryData;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.Clone;
  if (C.QueryInterface(TgoBsonBinaryData._IBinaryData, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonBinaryData.Clone)');
end;

class function TgoBsonBinaryData.Create: TgoBsonBinaryData;
begin
  Result.FImpl := TValueBinaryData.Create;
end;

class function TgoBsonBinaryData.Create(const AData: TBytes): TgoBsonBinaryData;
begin
  Result.FImpl := TValueBinaryData.Create(AData);
end;

class function TgoBsonBinaryData.Create(const AData: TBytes;
  const ASubType: TgoBsonBinarySubType): TgoBsonBinaryData;
begin
  Result.FImpl := TValueBinaryData.Create(AData, ASubType);
end;

function TgoBsonBinaryData.DeepClone: TgoBsonBinaryData;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.DeepClone;
  if (C.QueryInterface(TgoBsonBinaryData._IBinaryData, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonArray.TgoBsonBinaryData)');
end;

class operator TgoBsonBinaryData.Equal(const A, B: TgoBsonBinaryData): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

function TgoBsonBinaryData.GetAsBytes: TBytes;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.AsBytes;
end;

function TgoBsonBinaryData.GetByte(const AIndex: Integer): Byte;
begin
  Result := FImpl[AIndex];
end;

function TgoBsonBinaryData.GetCount: Integer;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Count;
end;

function TgoBsonBinaryData.GetSubType: TgoBsonBinarySubType;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.SubType;
end;

class operator TgoBsonBinaryData.Implicit(
  const A: TgoBsonBinaryData): TgoBsonValue;
begin
  Result.FImpl := A.FImpl;
end;

function TgoBsonBinaryData.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class operator TgoBsonBinaryData.NotEqual(const A,
  B: TgoBsonBinaryData): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

procedure TgoBsonBinaryData.SetByte(const AIndex: Integer; const AValue: Byte);
begin
  FImpl[AIndex] := AValue;
end;

procedure TgoBsonBinaryData.SetNil;
begin
  FImpl := nil;
end;

function TgoBsonBinaryData.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonBinaryData.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonBinaryData.ToJson(
  const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TgoBsonNull }

function TgoBsonNull.Clone: TgoBsonNull;
begin
  Result := FImpl;
end;

class constructor TgoBsonNull.Create;
begin
  FImpl.FValue := _INull(@VALUE_NULL);
end;

function TgoBsonNull.DeepClone: TgoBsonNull;
begin
  Result := FImpl;
end;

class operator TgoBsonNull.Equal(const A, B: TgoBsonNull): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

class operator TgoBsonNull.Implicit(const A: TgoBsonNull): TgoBsonValue;
begin
  Result.FImpl := A.FValue;
end;

function TgoBsonNull.IsNil: Boolean;
begin
  Result := (FValue = nil);
end;

class operator TgoBsonNull.NotEqual(const A, B: TgoBsonNull): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

function TgoBsonNull.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonNull.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonNull.ToJson(const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TgoBsonUndefined }

function TgoBsonUndefined.Clone: TgoBsonUndefined;
begin
  Result := FImpl;
end;

class constructor TgoBsonUndefined.Create;
begin
  FImpl.FValue := _IUndefined(@VALUE_UNDEFINED);
end;

function TgoBsonUndefined.DeepClone: TgoBsonUndefined;
begin
  Result := FImpl;
end;

class operator TgoBsonUndefined.Equal(const A, B: TgoBsonUndefined): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

class operator TgoBsonUndefined.Implicit(const A: TgoBsonUndefined): TgoBsonValue;
begin
  Result.FImpl := A.FValue;
end;

function TgoBsonUndefined.IsNil: Boolean;
begin
  Result := (FValue = nil);
end;

class operator TgoBsonUndefined.NotEqual(const A, B: TgoBsonUndefined): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

function TgoBsonUndefined.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonUndefined.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonUndefined.ToJson(const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TgoBsonRegularExpression }

function TgoBsonRegularExpression.Clone: TgoBsonRegularExpression;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.Clone;
  if (C.QueryInterface(TgoBsonRegularExpression._IRegularExpression, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonRegularExpression.Clone)');
end;

class function TgoBsonRegularExpression.Create(const APattern,
  AOptions: String): TgoBsonRegularExpression;
begin
  Result.FImpl := TValueRegularExpression.Create(APattern, AOptions);
end;

class function TgoBsonRegularExpression.Create(
  const APattern: String): TgoBsonRegularExpression;
begin
  Result.FImpl := TValueRegularExpression.Create(APattern);
end;

function TgoBsonRegularExpression.DeepClone: TgoBsonRegularExpression;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.DeepClone;
  if (C.QueryInterface(TgoBsonRegularExpression._IRegularExpression, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonRegularExpression.DeepClone)');
end;

class operator TgoBsonRegularExpression.Equal(const A,
  B: TgoBsonRegularExpression): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

function TgoBsonRegularExpression.GetOptions: String;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Options;
end;

function TgoBsonRegularExpression.GetPattern: String;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Pattern;
end;

class operator TgoBsonRegularExpression.Implicit(
  const A: TgoBsonRegularExpression): TgoBsonValue;
begin
  Result.FImpl := A.FImpl;
end;

class operator TgoBsonRegularExpression.Implicit(const A: String): TgoBsonRegularExpression;
begin
  Result.FImpl := TValueRegularExpression.Create(A);
end;

function TgoBsonRegularExpression.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class operator TgoBsonRegularExpression.NotEqual(const A,
  B: TgoBsonRegularExpression): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

procedure TgoBsonRegularExpression.SetNil;
begin
  FImpl := nil;
end;

function TgoBsonRegularExpression.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonRegularExpression.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonRegularExpression.ToJson(
  const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TgoBsonJavaScript }

function TgoBsonJavaScript.Clone: TgoBsonJavaScript;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.Clone;
  if (C.QueryInterface(TgoBsonJavaScript._IJavaScript, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonJavaScript.Clone)');
end;

class function TgoBsonJavaScript.Create(const ACode: String): TgoBsonJavaScript;
begin
  Result.FImpl := TValueJavaScript.Create(ACode);
end;

function TgoBsonJavaScript.DeepClone: TgoBsonJavaScript;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.DeepClone;
  if (C.QueryInterface(TgoBsonJavaScript._IJavaScript, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonJavaScript.DeepClone)');
end;

class operator TgoBsonJavaScript.Equal(const A, B: TgoBsonJavaScript): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

function TgoBsonJavaScript.GetCode: String;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Code;
end;

class operator TgoBsonJavaScript.Implicit(
  const A: TgoBsonJavaScript): TgoBsonValue;
begin
  Result.FImpl := A.FImpl;
end;

function TgoBsonJavaScript.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class operator TgoBsonJavaScript.NotEqual(const A,
  B: TgoBsonJavaScript): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

procedure TgoBsonJavaScript.SetNil;
begin
  FImpl := nil;
end;

function TgoBsonJavaScript.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonJavaScript.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonJavaScript.ToJson(
  const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TgoBsonJavaScriptWithScope }

function TgoBsonJavaScriptWithScope.Clone: TgoBsonJavaScriptWithScope;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.Clone;
  if (C.QueryInterface(TgoBsonJavaScriptWithScope._IJavaScriptWithScope, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonJavaScriptWithScope.Clone)');
end;

class function TgoBsonJavaScriptWithScope.Create(const ACode: String;
  const AScope: TgoBsonDocument): TgoBsonJavaScriptWithScope;
begin
  Result.FImpl := TValueJavaScriptWithScope.Create(ACode, AScope);
end;

function TgoBsonJavaScriptWithScope.DeepClone: TgoBsonJavaScriptWithScope;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.DeepClone;
  if (C.QueryInterface(TgoBsonJavaScriptWithScope._IJavaScriptWithScope, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonJavaScriptWithScope.DeepClone)');
end;

class operator TgoBsonJavaScriptWithScope.Equal(const A,
  B: TgoBsonJavaScriptWithScope): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

function TgoBsonJavaScriptWithScope.GetCode: String;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Code;
end;

function TgoBsonJavaScriptWithScope.GetScope: TgoBsonDocument;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Scope;
end;

class operator TgoBsonJavaScriptWithScope.Implicit(
  const A: TgoBsonJavaScriptWithScope): TgoBsonValue;
begin
  Result.FImpl := A.FImpl;
end;

function TgoBsonJavaScriptWithScope.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class operator TgoBsonJavaScriptWithScope.NotEqual(const A,
  B: TgoBsonJavaScriptWithScope): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

procedure TgoBsonJavaScriptWithScope.SetNil;
begin
  FImpl := nil;
end;

function TgoBsonJavaScriptWithScope.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonJavaScriptWithScope.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonJavaScriptWithScope.ToJson(
  const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TgoBsonSymbol }

function TgoBsonSymbol.Clone: TgoBsonSymbol;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.Clone;
  if (C.QueryInterface(TgoBsonSymbol._ISymbol, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonSymbol.Clone)');
end;

function TgoBsonSymbol.DeepClone: TgoBsonSymbol;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.DeepClone;
  if (C.QueryInterface(TgoBsonSymbol._ISymbol, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonSymbol.DeepClone)');
end;

class operator TgoBsonSymbol.Equal(const A, B: TgoBsonSymbol): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

function TgoBsonSymbol.GetName: String;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Name;
end;

class operator TgoBsonSymbol.Implicit(const A: TgoBsonSymbol): TgoBsonValue;
begin
  Result.FImpl := A.FImpl;
end;

function TgoBsonSymbol.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class operator TgoBsonSymbol.NotEqual(const A, B: TgoBsonSymbol): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

procedure TgoBsonSymbol.SetNil;
begin
  FImpl := nil;
end;

function TgoBsonSymbol.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonSymbol.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonSymbol.ToJson(const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TgoBsonSymbolTable }

class constructor TgoBsonSymbolTable.Create;
begin
  FTable := TDictionary<String, TgoBsonSymbol>.Create;
  FLock := TCriticalSection.Create;
end;

class destructor TgoBsonSymbolTable.Destroy;
begin
  FreeAndNil(FTable);
  FreeAndNil(FLock);
end;

class function TgoBsonSymbolTable.Lookup(const AName: String): TgoBsonSymbol;
begin
  FLock.Enter;
  try
    if (not FTable.TryGetValue(AName, Result)) then
    begin
      Result.FImpl := TValueSymbol.Create(AName);
      FTable.Add(AName, Result);
    end;
  finally
    FLock.Leave;
  end;
end;

{ TgoBsonDateTime }

function TgoBsonDateTime.Clone: TgoBsonDateTime;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.Clone;
  if (C.QueryInterface(TgoBsonDateTime._IDateTime, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonDateTime.Clone)');
end;

class function TgoBsonDateTime.Create(const ADateTime: TDateTime;
  const ADateTimeIsUTC: Boolean): TgoBsonDateTime;
begin
  Result.FImpl := TValueDateTime.Create(ADateTime, ADateTimeIsUTC);
end;

class function TgoBsonDateTime.Create(
  const AMillisecondsSinceEpoch: Int64): TgoBsonDateTime;
begin
  Result.FImpl := TValueDateTime.Create(AMillisecondsSinceEpoch);
end;

function TgoBsonDateTime.DeepClone: TgoBsonDateTime;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.DeepClone;
  if (C.QueryInterface(TgoBsonDateTime._IDateTime, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonDateTime.DeepClone)');
end;

class operator TgoBsonDateTime.Equal(const A, B: TgoBsonDateTime): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

function TgoBsonDateTime.GetMillisecondsSinceEpoch: Int64;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.MillisecondsSinceEpoch;
end;

class operator TgoBsonDateTime.Implicit(const A: TgoBsonDateTime): TgoBsonValue;
begin
  Result.FImpl := A.FImpl;
end;

function TgoBsonDateTime.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class operator TgoBsonDateTime.NotEqual(const A, B: TgoBsonDateTime): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

procedure TgoBsonDateTime.SetNil;
begin
  FImpl := nil;
end;

function TgoBsonDateTime.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonDateTime.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonDateTime.ToJson(const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

function TgoBsonDateTime.ToLocalTime: TDateTime;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToLocalTime;
end;

function TgoBsonDateTime.ToUniversalTime: TDateTime;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.ToUniversalTime;
end;

{ TgoBsonTimestamp }

class function TgoBsonTimestamp.Create(const AValue: Int64): TgoBsonTimestamp;
begin
  Result.FImpl := TValueTimestamp.Create(AValue);
end;

function TgoBsonTimestamp.Clone: TgoBsonTimestamp;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.Clone;
  if (C.QueryInterface(TgoBsonTimestamp._ITimestamp, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonTimestamp.Clone)');
end;

class function TgoBsonTimestamp.Create(const ATimestamp, AIncrement: Integer): TgoBsonTimestamp;
begin
  Result.FImpl := TValueTimestamp.Create(ATimestamp, AIncrement);
end;

function TgoBsonTimestamp.DeepClone: TgoBsonTimestamp;
var
  C: TgoBsonValue._IValue;
begin
  Assert(Assigned(FImpl));
  C := FImpl.DeepClone;
  if (C.QueryInterface(TgoBsonTimestamp._ITimestamp, Result.FImpl) <> S_OK) then
    raise EIntfCastError.Create('Invalid cast (TgoBsonTimestamp.DeepClone)');
end;

class operator TgoBsonTimestamp.Equal(const A, B: TgoBsonTimestamp): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

function TgoBsonTimestamp.GetIncrement: Integer;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Increment;
end;

function TgoBsonTimestamp.GetTimestamp: Integer;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Timestamp;
end;

function TgoBsonTimestamp.GetValue: Int64;
begin
  Assert(Assigned(FImpl));
  Result := FImpl.Value;
end;

class operator TgoBsonTimestamp.Implicit(
  const A: TgoBsonTimestamp): TgoBsonValue;
begin
  Result.FImpl := A.FImpl;
end;

function TgoBsonTimestamp.IsNil: Boolean;
begin
  Result := (FImpl = nil);
end;

class operator TgoBsonTimestamp.NotEqual(const A, B: TgoBsonTimestamp): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

procedure TgoBsonTimestamp.SetNil;
begin
  FImpl := nil;
end;

function TgoBsonTimestamp.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonTimestamp.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonTimestamp.ToJson(
  const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TgoBsonMaxKey }

function TgoBsonMaxKey.Clone: TgoBsonMaxKey;
begin
  Result := FImpl;
end;

class constructor TgoBsonMaxKey.Create;
begin
  FImpl.FValue := _IMaxKey(@VALUE_MAX_KEY);
end;

function TgoBsonMaxKey.DeepClone: TgoBsonMaxKey;
begin
  Result := FImpl;
end;

class operator TgoBsonMaxKey.Equal(const A, B: TgoBsonMaxKey): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

class operator TgoBsonMaxKey.Implicit(const A: TgoBsonMaxKey): TgoBsonValue;
begin
  Result.FImpl := A.FValue;
end;

function TgoBsonMaxKey.IsNil: Boolean;
begin
  Result := (FValue = nil);
end;

class operator TgoBsonMaxKey.NotEqual(const A, B: TgoBsonMaxKey): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

function TgoBsonMaxKey.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonMaxKey.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonMaxKey.ToJson(const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TgoBsonMinKey }

function TgoBsonMinKey.Clone: TgoBsonMinKey;
begin
  Result := FImpl;
end;

class constructor TgoBsonMinKey.Create;
begin
  FImpl.FValue := _IMinKey(@VALUE_MIN_KEY);
end;

function TgoBsonMinKey.DeepClone: TgoBsonMinKey;
begin
  Result := FImpl;
end;

class operator TgoBsonMinKey.Equal(const A, B: TgoBsonMinKey): Boolean;
begin
  Result := (TgoBsonValue(A) = TgoBsonValue(B));
end;

class operator TgoBsonMinKey.Implicit(const A: TgoBsonMinKey): TgoBsonValue;
begin
  Result.FImpl := A.FValue;
end;

function TgoBsonMinKey.IsNil: Boolean;
begin
  Result := (FValue = nil);
end;

class operator TgoBsonMinKey.NotEqual(const A, B: TgoBsonMinKey): Boolean;
begin
  Result := (TgoBsonValue(A) <> TgoBsonValue(B));
end;

function TgoBsonMinKey.ToBson: TBytes;
begin
  Result := TgoBsonValue(Self).ToBson;
end;

function TgoBsonMinKey.ToJson: String;
begin
  Result := TgoBsonValue(Self).ToJson;
end;

function TgoBsonMinKey.ToJson(const ASettings: TgoJsonWriterSettings): String;
begin
  Result := TgoBsonValue(Self).ToJson(ASettings);
end;

{ TNonRefCountedInterface }

function TNonRefCountedInterface.Addref: Integer;
begin
  Result := -1;
end;

function TNonRefCountedInterface.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := E_NOINTERFACE;
end;

function TNonRefCountedInterface.Release: Integer;
begin
  Result := -1;
end;

{ TRefCountedInterface }

function TRefCountedInterface.Addref: Integer;
begin
  Result := AtomicIncrement(FRefCount);
end;

function TRefCountedInterface.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  Result := E_NOINTERFACE;
end;

function TRefCountedInterface.Release: Integer;
begin
  Result := AtomicDecrement(FRefCount);
  if (Result = 0) then
    FreeMem(@Self);
end;

{ TValue }

function TValue.AsArray: TArray<TgoBsonValue>;
begin
  raise EIntfCastError.Create('Invalid cast');
end;

function TValue.AsBoolean: Boolean;
begin
  raise EIntfCastError.Create('Invalid cast');
end;

function TValue.AsByteArray: TBytes;
begin
  raise EIntfCastError.Create('Invalid cast');
end;

function TValue.AsDouble: Double;
begin
  raise EIntfCastError.Create('Invalid cast');
end;

function TValue.AsGuid: TGUID;
begin
  raise EIntfCastError.Create('Invalid cast');
end;

function TValue.AsInt64: Int64;
begin
  raise EIntfCastError.Create('Invalid cast');
end;

function TValue.AsInteger: Integer;
begin
  raise EIntfCastError.Create('Invalid cast');
end;

function TValue.AsObjectId: TgoObjectId;
begin
  raise EIntfCastError.Create('Invalid cast');
end;

function TValue.AsString: String;
begin
  raise EIntfCastError.Create('Invalid cast');
end;

function TValue.Clone: TgoBsonValue._IValue;
begin
  Result := TgoBsonValue._IValue(@Self);
end;

function TValue.DeepClone: TgoBsonValue._IValue;
begin
  Result := TgoBsonValue._IValue(@Self);
end;

function TValue.Equals(const AOther: TgoBsonValue._IValue): Boolean;
var
  This, Other: TgoBsonValue;
begin
  This.FImpl := TgoBsonValue._IValue(@Self);
  Other.FImpl := AOther;
  Result := (This = Other);
end;

function TValue.GetBsonType: TgoBsonType;
begin
  raise EAbstractError.CreateRes(@SAbstractError);
end;

function TValue.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := ADefault;
end;

function TValue.ToByteArray: TBytes;
begin
  Result := nil;
end;

function TValue.ToDouble(const ADefault: Double): Double;
begin
  Result := ADefault;
end;

function TValue.ToGuid: TGUID;
begin
  Result := TGUID.Empty;
end;

function TValue.ToInt64(const ADefault: Int64): Int64;
begin
  Result := ADefault;
end;

function TValue.ToInteger(const ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TValue.ToLocalTime: TDateTime;
begin
  Result := 0;
end;

function TValue.ToObjectId: TgoObjectId;
begin
  Result := TgoObjectId.Empty;
end;

function TValue.ToString(const ADefault: String): String;
begin
  Result := ADefault;
end;

function TValue.ToUniversalTime: TDateTime;
begin
  Result := 0;
end;

{ TValueFalse }

function TValueFalse.AsBoolean: Boolean;
begin
  Result := False;
end;

class constructor TValueFalse.Create;
begin
  FValue := TgoBsonValue._IValue(@VALUE_BOOLEAN_FALSE);
end;

function TValueFalse.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  if (AOther.BsonType = TgoBsonType.Boolean) then
    Result := (not AOther.AsBoolean)
  else
    Result := False;
end;

function TValueFalse.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Boolean;
end;

function TValueFalse.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := False;
end;

function TValueFalse.ToDouble(const ADefault: Double): Double;
begin
  Result := 0;
end;

function TValueFalse.ToInt64(const ADefault: Int64): Int64;
begin
  Result := 0;
end;

function TValueFalse.ToInteger(const ADefault: Integer): Integer;
begin
  Result := 0;
end;

function TValueFalse.ToString(const ADefault: String): String;
begin
  Result := 'false';
end;

{ TValueTrue }

function TValueTrue.AsBoolean: Boolean;
begin
  Result := True;
end;

class constructor TValueTrue.Create;
begin
  FValue := TgoBsonValue._IValue(@VALUE_BOOLEAN_TRUE);
end;

function TValueTrue.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  if (AOther.BsonType = TgoBsonType.Boolean) then
    Result := AOther.AsBoolean
  else
    Result := False;
end;

function TValueTrue.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Boolean;
end;

function TValueTrue.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := True;
end;

function TValueTrue.ToDouble(const ADefault: Double): Double;
begin
  Result := 1;
end;

function TValueTrue.ToInt64(const ADefault: Int64): Int64;
begin
  Result := 1;
end;

function TValueTrue.ToInteger(const ADefault: Integer): Integer;
begin
  Result := 1;
end;

function TValueTrue.ToString(const ADefault: String): String;
begin
  Result := 'true';
end;

{ TValueInteger }

function TValueInteger.AsInteger: Integer;
begin
  Result := FValue;
end;

class function TValueInteger.Create(const AValue: Integer): TgoBsonValue._IValue;
var
  V: PValueInteger;
begin
  GetMem(V, SizeOf(TValueInteger));
  V.FBase.FVTable := @VTABLE_INTEGER;
  V.FBase.FRefCount := 0;
  V.FValue := AValue;
  Result := TgoBsonValue._IValue(V);
end;

function TValueInteger.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  case AOther.BsonType of
    TgoBsonType.Int32:
      Result := (FValue = AOther.AsInteger);

    TgoBsonType.Int64:
      Result := (FValue = AOther.AsInt64);

    TgoBsonType.Double:
      Result := (FValue = AOther.AsDouble);
  else
    Result := False;
  end;
end;

function TValueInteger.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Int32;
end;

function TValueInteger.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := (FValue <> 0);
end;

function TValueInteger.ToDouble(const ADefault: Double): Double;
begin
  Result := FValue;
end;

function TValueInteger.ToInt64(const ADefault: Int64): Int64;
begin
  Result := FValue;
end;

function TValueInteger.ToInteger(const ADefault: Integer): Integer;
begin
  Result := FValue;
end;

function TValueInteger.ToString(const ADefault: String): String;
begin
  Result := IntToStr(FValue);
end;

{ TValueIntegerConst }

function TValueIntegerConst.AsInteger: Integer;
begin
  Result := FValue;
end;

class constructor TValueIntegerConst.Create;
var
  I: Integer;
  P: PValueIntegerConst;
begin
  GetMem(FPrecreatedData, ((MAX_PRECREATED_VALUE - MIN_PRECREATED_VALUE) + 1) * SizeOf(TValueIntegerConst));
  P := FPrecreatedData;
  for I := MIN_PRECREATED_VALUE to MAX_PRECREATED_VALUE do
  begin
    P.FBase.FVTable := @VTABLE_INTEGER_CONST;
    P.FValue := I;
    FPrecreatedValues[I] := TgoBsonValue._IValue(P);
    Inc(P);
  end;
end;

class destructor TValueIntegerConst.Destroy;
var
  I: Integer;
begin
  for I := MIN_PRECREATED_VALUE to MAX_PRECREATED_VALUE do
    FPrecreatedValues[I] := nil;
  FreeMem(FPrecreatedData);
  FPrecreatedData := nil;
end;

function TValueIntegerConst.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  case AOther.BsonType of
    TgoBsonType.Int32:
      Result := (FValue = AOther.AsInteger);

    TgoBsonType.Int64:
      Result := (FValue = AOther.AsInt64);

    TgoBsonType.Double:
      Result := (FValue = AOther.AsDouble);
  else
    Result := False;
  end;
end;

function TValueIntegerConst.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Int32;
end;

function TValueIntegerConst.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := (FValue <> 0);
end;

function TValueIntegerConst.ToDouble(const ADefault: Double): Double;
begin
  Result := FValue;
end;

function TValueIntegerConst.ToInt64(const ADefault: Int64): Int64;
begin
  Result := FValue;
end;

function TValueIntegerConst.ToInteger(const ADefault: Integer): Integer;
begin
  Result := FValue;
end;

function TValueIntegerConst.ToString(const ADefault: String): String;
begin
  Result := IntToStr(FValue);
end;

{ TValueInt64 }

function TValueInt64.AsInt64: Int64;
begin
  Result := FValue;
end;

class function TValueInt64.Create(const AValue: Int64): TgoBsonValue._IValue;
var
  V: PValueInt64;
begin
  GetMem(V, SizeOf(TValueInt64));
  V.FBase.FVTable := @VTABLE_INT64;
  V.FBase.FRefCount := 0;
  V.FValue := AValue;
  Result := TgoBsonValue._IValue(V);
end;

function TValueInt64.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  case AOther.BsonType of
    TgoBsonType.Int32:
      Result := (FValue = AOther.AsInteger);

    TgoBsonType.Int64:
      Result := (FValue = AOther.AsInt64);

    TgoBsonType.Double:
      Result := (FValue = AOther.AsDouble);
  else
    Result := False;
  end;
end;

function TValueInt64.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Int64;
end;

function TValueInt64.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := (FValue <> 0);
end;

function TValueInt64.ToDouble(const ADefault: Double): Double;
begin
  Result := FValue;
end;

function TValueInt64.ToInt64(const ADefault: Int64): Int64;
begin
  Result := FValue;
end;

function TValueInt64.ToInteger(const ADefault: Integer): Integer;
begin
  Result := FValue;
end;

function TValueInt64.ToString(const ADefault: String): String;
begin
  Result := IntToStr(FValue);
end;

{ TValueInt64Const }

function TValueInt64Const.AsInt64: Int64;
begin
  Result := FValue;
end;

class constructor TValueInt64Const.Create;
var
  I: Integer;
  P: PValueInt64Const;
begin
  GetMem(FPrecreatedData, ((MAX_PRECREATED_VALUE - MIN_PRECREATED_VALUE) + 1) * SizeOf(TValueInt64Const));
  P := FPrecreatedData;
  for I := MIN_PRECREATED_VALUE to MAX_PRECREATED_VALUE do
  begin
    P.FBase.FVTable := @VTABLE_INT64_CONST;
    P.FValue := I;
    FPrecreatedValues[I] := TgoBsonValue._IValue(P);
    Inc(P);
  end;
end;

class destructor TValueInt64Const.Destroy;
var
  I: Integer;
begin
  for I := MIN_PRECREATED_VALUE to MAX_PRECREATED_VALUE do
    FPrecreatedValues[I] := nil;
  FreeMem(FPrecreatedData);
  FPrecreatedData := nil;
end;

function TValueInt64Const.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  case AOther.BsonType of
    TgoBsonType.Int32:
      Result := (FValue = AOther.AsInteger);

    TgoBsonType.Int64:
      Result := (FValue = AOther.AsInt64);

    TgoBsonType.Double:
      Result := (FValue = AOther.AsDouble);
  else
    Result := False;
  end;
end;

function TValueInt64Const.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Int64;
end;

function TValueInt64Const.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := (FValue <> 0);
end;

function TValueInt64Const.ToDouble(const ADefault: Double): Double;
begin
  Result := FValue;
end;

function TValueInt64Const.ToInt64(const ADefault: Int64): Int64;
begin
  Result := FValue;
end;

function TValueInt64Const.ToInteger(const ADefault: Integer): Integer;
begin
  Result := FValue;
end;

function TValueInt64Const.ToString(const ADefault: String): String;
begin
  Result := IntToStr(FValue);
end;

{ TValueDouble }

function TValueDouble.AsDouble: Double;
begin
  Result := FValue;
end;

class function TValueDouble.Create(const AValue: Double): TgoBsonValue._IValue;
var
  V: PValueDouble;
begin
  GetMem(V, SizeOf(TValueDouble));
  V.FBase.FVTable := @VTABLE_DOUBLE;
  V.FBase.FRefCount := 0;
  V.FValue := AValue;
  Result := TgoBsonValue._IValue(V);
end;

function TValueDouble.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  case AOther.BsonType of
    TgoBsonType.Int32:
      Result := (FValue = AOther.AsInteger);

    TgoBsonType.Int64:
      Result := (FValue = AOther.AsInt64);

    TgoBsonType.Double:
      Result := (FValue = AOther.AsDouble);
  else
    Result := False;
  end;
end;

function TValueDouble.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Double;
end;

function TValueDouble.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := (FValue <> 0) and (not FValue.IsNan);
end;

function TValueDouble.ToDouble(const ADefault: Double): Double;
begin
  Result := FValue;
end;

function TValueDouble.ToInt64(const ADefault: Int64): Int64;
begin
  Result := Trunc(FValue);
end;

function TValueDouble.ToInteger(const ADefault: Integer): Integer;
begin
  Result := Trunc(FValue);
end;

function TValueDouble.ToString(const ADefault: String): String;
begin
  Result := FloatToStr(FValue, goUSFormatSettings);
end;

{ TValueDoubleZero }

function TValueDoubleZero.AsDouble: Double;
begin
  Result := 0;
end;

class constructor TValueDoubleZero.Create;
begin
  FValue := TgoBsonValue._IValue(@VALUE_DOUBLE_ZERO);
end;

function TValueDoubleZero.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  case AOther.BsonType of
    TgoBsonType.Int32:
      Result := (AOther.AsInteger = 0);

    TgoBsonType.Int64:
      Result := (AOther.AsInt64 = 0);

    TgoBsonType.Double:
      Result := (AOther.AsDouble = 0);
  else
    Result := False;
  end;
end;

function TValueDoubleZero.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Double;
end;

function TValueDoubleZero.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := False;
end;

function TValueDoubleZero.ToDouble(const ADefault: Double): Double;
begin
  Result := 0;
end;

function TValueDoubleZero.ToInt64(const ADefault: Int64): Int64;
begin
  Result := 0;
end;

function TValueDoubleZero.ToInteger(const ADefault: Integer): Integer;
begin
  Result := 0;
end;

function TValueDoubleZero.ToString(const ADefault: String): String;
begin
  Result := '0';
end;

{ TValueDateTime }

class function TValueDateTime.Create(const ADateTime: TDateTime;
  const ADateTimeIsUTC: Boolean): TgoBsonDateTime._IDateTime;
begin
  Result := Create(goDateTimeToMillisecondsSinceEpoch(ADateTime, ADateTimeIsUTC));
end;

class function TValueDateTime.Create(
  const AMillisecondsSinceEpoch: Int64): TgoBsonDateTime._IDateTime;
var
  V: PValueDateTime;
begin
  GetMem(V, SizeOf(TValueDateTime));
  V.FBase.FVTable := @VTABLE_DATE_TIME;
  V.FBase.FRefCount := 0;
  V.FMillisecondsSinceEpoch := AMillisecondsSinceEpoch;
  Result := TgoBsonDateTime._IDateTime(V);
end;

function TValueDateTime.Equals(const AOther: TgoBsonValue._IValue): Boolean;
var
  Other: PValueDateTime;
begin
  if (AOther.BsonType = TgoBsonType.DateTime) then
  begin
    Other := PValueDateTime(AOther);
    Result := (FMillisecondsSinceEpoch = Other.FMillisecondsSinceEpoch);
  end
  else
    Result := False;
end;

function TValueDateTime.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.DateTime;
end;

function TValueDateTime.GetMillisecondsSinceEpoch: Int64;
begin
  Result := FMillisecondsSinceEpoch;
end;

function TValueDateTime.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonDateTime._IDateTime) then
  begin
    TgoBsonDateTime._IDateTime(Obj) := TgoBsonDateTime._IDateTime(@Self);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueDateTime.ToLocalTime: TDateTime;
begin
  Result := goToDateTimeFromMillisecondsSinceEpoch(FMillisecondsSinceEpoch, False);
end;

function TValueDateTime.ToString(const ADefault: String): String;
begin
  Result := DateToISO8601(ToLocalTime, False);
end;

function TValueDateTime.ToUniversalTime: TDateTime;
begin
  Result := goToDateTimeFromMillisecondsSinceEpoch(FMillisecondsSinceEpoch, True);
end;

{ TValueString }

function TValueString.AsString: String;
begin
  Result := Value;
end;

class function TValueString.Create(const AValue: String): TgoBsonValue._IValue;
var
  Len: Integer;
  V: PValueString;
begin
  Len := Length(AValue);
  GetMem(V, SizeOf(TValueString) + Len * SizeOf(Char));
  V.FBase.FVTable := @VTABLE_STRING;
  V.FBase.FRefCount := 0;
  V.FLength := Len;
  Result := TgoBsonValue._IValue(V);
  Inc(V);
  Move(AValue[Low(String)], V^, Len * SizeOf(Char));
end;

function TValueString.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  if (AOther.BsonType = TgoBsonType.String) then
    Result := (Value = AOther.AsString)
  else
    Result := False;
end;

function TValueString.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.String;
end;

function TValueString.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := True;
end;

function TValueString.ToDouble(const ADefault: Double): Double;
begin
  Result := StrToFloatDef(Value, ADefault, goUSFormatSettings);
end;

function TValueString.ToInt64(const ADefault: Int64): Int64;
begin
  Result := StrToInt64Def(Value, ADefault);
end;

function TValueString.ToInteger(const ADefault: Integer): Integer;
begin
  Result := StrToIntDef(Value, ADefault);
end;

function TValueString.ToString(const ADefault: String): String;
begin
  Result := Value;
end;

function TValueString.Value: String;
begin
  SetString(Result, PChar(PByte(@Self) + SizeOf(TValueString)), FLength);
end;

{ TValueStringEmpty }

function TValueStringEmpty.AsString: String;
begin
  Result := '';
end;

class constructor TValueStringEmpty.Create;
begin
  FValue := TgoBsonValue._IValue(@VALUE_STRING_EMPTY);
end;

function TValueStringEmpty.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  if (AOther.BsonType = TgoBsonType.String) then
    Result := (AOther.AsString = '')
  else
    Result := False;
end;

function TValueStringEmpty.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.String;
end;

function TValueStringEmpty.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := False;
end;

function TValueStringEmpty.ToDouble(const ADefault: Double): Double;
begin
  Result := ADefault;
end;

function TValueStringEmpty.ToInt64(const ADefault: Int64): Int64;
begin
  Result := ADefault;
end;

function TValueStringEmpty.ToInteger(const ADefault: Integer): Integer;
begin
  Result := ADefault;
end;

function TValueStringEmpty.ToString(const ADefault: String): String;
begin
  Result := '';
end;

{ TValueStringConstant }

function TValueStringConstant.AsString: String;
begin
  Result := Value;
end;

class function TValueStringConstant.Create(const AValue: String): TgoBsonValue._IValue;
var
  V: PValueStringConstant;
begin
  GetMem(V, SizeOf(TValueStringConstant));
  V.FBase.FVTable := @VTABLE_STRING_CONSTANT;
  V.FBase.FRefCount := 0;
  V.FValue := Pointer(AValue);
  Result := TgoBsonValue._IValue(V);
end;

function TValueStringConstant.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  if (AOther.BsonType = TgoBsonType.String) then
    Result := (Value = AOther.AsString)
  else
    Result := False;
end;

function TValueStringConstant.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.String;
end;

function TValueStringConstant.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := True;
end;

function TValueStringConstant.ToDouble(const ADefault: Double): Double;
begin
  Result := StrToFloatDef(Value, ADefault, goUSFormatSettings);
end;

function TValueStringConstant.ToInt64(const ADefault: Int64): Int64;
begin
  Result := StrToInt64Def(Value, ADefault);
end;

function TValueStringConstant.ToInteger(const ADefault: Integer): Integer;
begin
  Result := StrToIntDef(Value, ADefault);
end;

function TValueStringConstant.ToString(const ADefault: String): String;
begin
  Result := Value;
end;

function TValueStringConstant.Value: String;
begin
  Result := String(FValue);
end;

{ TValueArray }

procedure TValueArray.Add(const AValue: TgoBsonValue._IValue);
var
  Capacity: Integer;
begin
  if (AValue = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);

  Capacity := Length(FItems);
  if (FCount >= Capacity) then
  begin
    if (Capacity > 64) then
      Inc(Capacity, Capacity div 4)
    else if (Capacity > 8) then
      Inc(Capacity, 16)
    else
      Inc(Capacity, 4);
    SetLength(FItems, Capacity);
  end;
  FItems[FCount] := AValue;
  Inc(FCount);
end;

procedure TValueArray.AddRangeOpenArray(const AValues: array of TgoBsonValue);
var
  I: Integer;
begin
  for I := 0 to Length(AValues) - 1 do
    Add(AValues[I].FImpl);
end;

procedure TValueArray.AddRangeGenArray(const AValues: TArray<TgoBsonValue>);
var
  I: Integer;
begin
  for I := 0 to Length(AValues) - 1 do
    Add(AValues[I].FImpl);
end;

procedure TValueArray.AddRangeBsonArray(const AValues: TgoBsonArray);
var
  I: Integer;
begin
  if (AValues.FImpl = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);

  for I := 0 to AValues.Count - 1 do
    Add(AValues[I].FImpl);
end;

function TValueArray.AsArray: TArray<TgoBsonValue>;
var
  I: Integer;
begin
  SetLength(Result, FCount);
  for I := 0 to FCount - 1 do
    Result[I].FImpl := FItems[I];
end;

procedure TValueArray.Clear;
begin
  FItems := nil;
  FCount := 0;
end;

function TValueArray.Clone: TgoBsonValue._IValue;
var
  A: PValueArray;
  I: Integer;
begin
  Result := TValueArray.Create(FCount);
  A := PValueArray(Result);
  for I := 0 to FCount - 1 do
    A.Add(FItems[I]);
end;

function TValueArray.Contains(const AValue: TgoBsonValue): Boolean;
var
  I: Integer;
  Item: TgoBsonValue;
begin
  for I := 0 to FCount - 1 do
  begin
    Item.FImpl := FItems[I];
    if (Item = AValue) then
      Exit(True);
  end;
  Result := False;
end;

class function TValueArray.Create(
  const AValues: array of TgoBsonValue): TgoBsonArray._IArray;
begin
  Result := Create(Length(AValues));
  Result.AddRange(AValues);
end;

class function TValueArray.Create(
  const ACapacity: Integer): TgoBsonArray._IArray;
var
  V: PValueArray;
begin
  GetMem(V, SizeOf(TValueArray));
  V.FBase.FVTable := @VTABLE_ARRAY;
  V.FBase.FRefCount := 0;
  Pointer(V.FItems) := nil;
  SetLength(V.FItems, ACapacity);
  V.FCount := 0;
  Result := TgoBsonArray._IArray(V);
end;

class function TValueArray.Create(
  const AValues: TArray<TgoBsonValue>): TgoBsonArray._IArray;
begin
  Result := Create(Length(AValues));
  Result.AddRange(AValues);
end;

function TValueArray.DeepClone: TgoBsonValue._IValue;
var
  A: PValueArray;
  I: Integer;
begin
  Result := TValueArray.Create(FCount);
  A := PValueArray(Result);
  for I := 0 to FCount - 1 do
    A.Add(FItems[I].DeepClone);
end;

procedure TValueArray.Delete(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  FItems[AIndex] := nil;

  Dec(FCount);
  if (AIndex <> FCount) then
  begin
    Move(FItems[AIndex + 1], FItems[AIndex], (FCount - AIndex) * SizeOf(TgoBsonValue._IValue));
    FillChar(FItems[FCount], SizeOf(TgoBsonValue), 0);
  end;
end;

function TValueArray.Equals(const AOther: TgoBsonValue._IValue): Boolean;
var
  Other: TArray<TgoBsonValue>;
  Item: TgoBsonValue;
  I: Integer;
begin
  if (AOther.BsonType = TgoBsonType.&Array) then
  begin
    Other := AOther.AsArray;
    Result := (FCount = Length(Other));
    if (Result) then
    begin
      for I := 0 to FCount - 1 do
      begin
        Item.FImpl := FItems[I];
        if (Item <> Other[I]) then
          Exit(False);
      end;
    end;
  end
  else
    Result := False;
end;

function TValueArray.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.&Array;
end;

function TValueArray.GetCount: Integer;
begin
  Result := FCount;
end;

procedure TValueArray.GetItem(const AIndex: Integer;
  out AValue: TgoBsonValue._IValue);
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  AValue := FItems[AIndex];
end;

function TValueArray.IndexOf(const AValue: TgoBsonValue): Integer;
var
  I: Integer;
  Item: TgoBsonValue;
begin
  for I := 0 to FCount - 1 do
  begin
    Item.FImpl := FItems[I];
    if (Item = AValue) then
      Exit(I);
  end;
  Result := -1;
end;

function TValueArray.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonArray._IArray) then
  begin
    TgoBsonArray._IArray(Obj) := TgoBsonArray._IArray(@Self);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueArray.Release: Integer;
begin
  Result := AtomicDecrement(FBase.FRefCount);
  if (Result = 0) then
  begin
    FItems := nil;
    FreeMem(@Self);
  end;
end;

function TValueArray.Remove(const AValue: TgoBsonValue): Boolean;
var
  Index: Integer;
begin
  if (AValue.FImpl = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);
  Index := IndexOf(AValue);
  Result := (Index >= 0);
  if (Result) then
    Delete(Index);
end;

procedure TValueArray.SetItem(const AIndex: Integer;
  const AValue: TgoBsonValue._IValue);
begin
  if (AIndex < 0) or (AIndex >= FCount) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  if (AValue = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);
  FItems[AIndex] := AValue;
end;

{ TValueBinaryData }

function TValueBinaryData.AsByteArray: TBytes;
begin
  Result := FValue;
end;

function TValueBinaryData.AsGuid: TGUID;
begin
  case FSubType of
    TgoBsonBinarySubType.UuidLegacy:
      Result := TGUID.Create(FValue, TEndian.Little);

    TgoBsonBinarySubType.UuidStandard:
      Result := TGUID.Create(FValue, TEndian.Big);
  else
    raise EIntfCastError.Create('Invalid cast (AsGuid)');
  end;
end;

class function TValueBinaryData.Create(const AValue: TBytes;
  const ASubType: TgoBsonBinarySubType): TgoBsonBinaryData._IBinaryData;
var
  V: PValueBinaryData;
begin
  GetMem(V, SizeOf(TValueBinaryData));
  V.FBase.FVTable := @VTABLE_BINARY_DATA;
  V.FBase.FRefCount := 0;
  Pointer(V.FValue) := nil;
  V.FValue := AValue;
  V.FSubType := ASubType;
  Result := TgoBsonBinaryData._IBinaryData(V);
end;

class function TValueBinaryData.Create: TgoBsonBinaryData._IBinaryData;
begin
  Result := Create(nil);
end;

class function TValueBinaryData.Create(
  const AValue: TGUID): TgoBsonBinaryData._IBinaryData;
begin
  Result := Create(AValue.ToByteArray(TEndian.Big), TgoBsonBinarySubType.UuidStandard);
end;

function TValueBinaryData.Equals(const AOther: TgoBsonValue._IValue): Boolean;
var
  Other: PValueBinaryData;
begin
  if (AOther.BsonType = TgoBsonType.Binary) then
  begin
    Other := PValueBinaryData(AOther);
    Result := (FSubType = Other.FSubType)
      and (Length(FValue) = Length(Other.FValue))
      and (CompareMem(@FValue[0], @Other.FValue[0], Length(FValue)));
  end
  else
    Result := False;
end;

function TValueBinaryData.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Binary;
end;

function TValueBinaryData.GetByte(const AIndex: Integer): Byte;
begin
  if (AIndex < 0) or (AIndex >= Length(FValue)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  Result := FValue[AIndex];
end;

function TValueBinaryData.GetAsBytes: TBytes;
begin
  Result := FValue;
end;

function TValueBinaryData.GetCount: Integer;
begin
  Result := Length(FValue);
end;

function TValueBinaryData.GetSubType: TgoBsonBinarySubType;
begin
  Result := FSubType;
end;

function TValueBinaryData.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonBinaryData._IBinaryData) then
  begin
    TgoBsonBinaryData._IBinaryData(Obj) := TgoBsonBinaryData._IBinaryData(@Self);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueBinaryData.Release: Integer;
begin
  Result := AtomicDecrement(FBase.FRefCount);
  if (Result = 0) then
  begin
    FValue := nil;
    FreeMem(@Self);
  end;
end;

procedure TValueBinaryData.SetByte(const AIndex: Integer; const AValue: Byte);
begin
  if (AIndex < 0) or (AIndex >= Length(FValue)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  FValue[AIndex] := AValue;
end;

function TValueBinaryData.ToByteArray: TBytes;
begin
  Result := FValue;
end;

function TValueBinaryData.ToGuid: TGUID;
begin
  case FSubType of
    TgoBsonBinarySubType.UuidLegacy:
      Result := TGUID.Create(FValue, TEndian.Little);

    TgoBsonBinarySubType.UuidStandard:
      Result := TGUID.Create(FValue, TEndian.Big);
  else
    Result := TGUID.Empty;
  end;
end;

{ TValueDocument }

procedure TValueDocument.Add(const AName: String;
  const AValue: TgoBsonValue._IValue);
var
  IsDuplicate: Boolean;
  Capacity: Integer;
begin
  IsDuplicate := (IndexOfName(AName) >= 0);
  if (IsDuplicate) and (not FAllowDuplicateNames) then
    raise EInvalidOperation.CreateRes(@SGenericDuplicateItem);

  Capacity := Length(FElements);
  if (FCount >= Capacity) then
  begin
    if (Capacity > 64) then
      Inc(Capacity, Capacity div 4)
    else if (Capacity > 8) then
      Inc(Capacity, 16)
    else
      Inc(Capacity, 4);
    SetLength(FElements, Capacity);
  end;
  FElements[FCount].FName := AName;
  FElements[FCount].FImpl := AValue;
  Inc(FCount);

  if (not IsDuplicate) then
  begin
    if (FIndices = nil) then
      RebuildIndices
    else
      FIndices.Add(AName, FCount - 1);
  end;
end;

procedure TValueDocument.Clear;
begin
  FElements := nil;
  if (FIndices <> nil) then
  begin
    FIndices.Release;
    FIndices := nil;
  end;
  FCount := 0;
end;

function TValueDocument.Clone: TgoBsonValue._IValue;
var
  D: PValueDocument;
  I: Integer;
begin
  Result := TValueDocument.Create;
  D := PValueDocument(Result);
  for I := 0 to FCount - 1 do
    D.Add(FElements[I].FName, FElements[I].FImpl);
end;

function TValueDocument.Contains(const AName: String): Boolean;
begin
  Result := (IndexOfName(AName) <> -1);
end;

function TValueDocument.ContainsValue(const AValue: TgoBsonValue): Boolean;
var
  I: Integer;
begin
  for I := 0 to FCount - 1 do
  begin
    if (FElements[I].Value = AValue) then
      Exit(True);
  end;
  Result := False;
end;

class function TValueDocument.Create(
  const AAllowDuplicateNames: Boolean): TgoBsonDocument._IDocument;
var
  V: PValueDocument;
begin
  GetMem(V, SizeOf(TValueDocument));
  V.FBase.FVTable := @VTABLE_DOCUMENT;
  V.FBase.FRefCount := 0;
  V.FAllowDuplicateNames := AAllowDuplicateNames;
  Pointer(V.FElements) := nil;
  Pointer(V.FIndices) := nil;
  V.FCount := 0;
  Result := TgoBsonDocument._IDocument(V);
end;

class function TValueDocument.Create(
  const AElement: TgoBsonElement): TgoBsonDocument._IDocument;
begin
  Result := Create;
  Result.Add(AElement.FName, AElement.FImpl);
end;

class function TValueDocument.Create(const AName: String;
  const AValue: TgoBsonValue): TgoBsonDocument._IDocument;
begin
  Result := Create;
  Result.Add(AName, AValue.FImpl);
end;

function TValueDocument.DeepClone: TgoBsonValue._IValue;
var
  D: PValueDocument;
  I: Integer;
  E: TgoBsonElement;
begin
  Result := TValueDocument.Create;
  D := PValueDocument(Result);
  for I := 0 to FCount - 1 do
  begin
    E := FElements[I].DeepClone;
    D.Add(E.FName, E.FImpl);
  end;
end;

procedure TValueDocument.Delete(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= Length(FElements)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  FElements[AIndex] := Default(TgoBsonElement);

  Dec(FCount);
  if (AIndex <> FCount) then
  begin
    Move(FElements[AIndex + 1], FElements[AIndex], (FCount - AIndex) * SizeOf(TgoBsonElement));
    FillChar(FElements[FCount], SizeOf(TgoBsonElement), 0);
  end;
end;

function TValueDocument.Equals(const AOther: TgoBsonValue._IValue): Boolean;
var
  Other: PValueDocument;
  I: Integer;
begin
  if (AOther.BsonType = TgoBsonType.Document) then
  begin
    Other := PValueDocument(AOther);
    Result := (FCount = Other.FCount);
    for I := 0 to FCount - 1 do
    begin
      if (FElements[I] <> Other.FElements[I]) then
        Exit(False);
    end;
  end
  else
    Result := False;
end;

procedure TValueDocument.Get(const AName: String;
  const ADefault: TgoBsonValue._IValue; out AValue: TgoBsonValue._IValue);
var
  Index: Integer;
begin
  Index := IndexOfName(AName);
  if (Index < 0) then
    AValue := ADefault
  else
    AValue := FElements[Index].FImpl;
end;

function TValueDocument.GetAllowDuplicateNames: Boolean;
begin
  Result := FAllowDuplicateNames;
end;

function TValueDocument.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Document;
end;

function TValueDocument.GetCount: Integer;
begin
  Result := FCount;
end;

function TValueDocument.GetElement(const AIndex: Integer): TgoBsonElement;
begin
  if (AIndex < 0) or (AIndex >= Length(FElements)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  Result := FElements[AIndex];
end;

procedure TValueDocument.GetValue(const AIndex: Integer;
  out AValue: TgoBsonValue._IValue);
begin
  if (AIndex < 0) or (AIndex >= Length(FElements)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  AValue := FElements[AIndex].FImpl;
end;

procedure TValueDocument.GetValueByName(const AName: String;
  out AValue: TgoBsonValue._IValue);
var
  Index: Integer;
begin
  Index := IndexOfName(AName);
  if (Index < 0) then
    AValue := TgoBsonNull.Value._Value
  else
    AValue := FElements[Index].FImpl;
end;

function TValueDocument.IndexOfName(const AName: String): Integer;
var
  I: Integer;
begin
  if (FIndices = nil) then
  begin
    for I := 0 to Length(FElements) - 1 do
    begin
      if (FElements[I].Name = AName) then
        Exit(I);
    end;
    Result := -1;
  end
  else
    Result := FIndices.Get(AName);
end;

procedure TValueDocument.Merge(const AOtherDocument: TgoBsonDocument;
  const AOverwriteExistingElements: Boolean);
var
  Element: TgoBsonElement;
begin
  if (AOtherDocument.FImpl = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);

  for Element in AOtherDocument do
  begin
    if (AOverwriteExistingElements) or (not Contains(Element.Name)) then
      SetValueByName(Element.Name, Element.FImpl);
  end;
end;

function TValueDocument.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonDocument._IDocument) then
  begin
    TgoBsonDocument._IDocument(Obj) := TgoBsonDocument._IDocument(@Self);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

procedure TValueDocument.RebuildIndices;
var
  I: Integer;
begin
  if (FCount < INDICES_COUNT_THRESHOLD) then
  begin
    if (FIndices <> nil) then
    begin
      FIndices.Release;
      FIndices := nil;
    end;
    Exit;
  end;

  if (FIndices = nil) then
  begin
    GetMem(FIndices, SizeOf(TIndexMap));
    FillChar(FIndices^, SizeOf(TIndexMap), 0);
  end
  else
    FIndices.Clear;

  { Process the elements in reverse order so that in case of duplicates the
    dictionary ends up pointing at the first one }
  for I := FCount - 1 downto 0 do
    FIndices.Add(FElements[I].Name, I);
end;

function TValueDocument.Release: Integer;
begin
  Result := AtomicDecrement(FBase.FRefCount);
  if (Result = 0) then
  begin
    FElements := nil;
    if (FIndices <> nil) then
      FIndices.Release;
    FreeMem(@Self);
  end;
end;

procedure TValueDocument.Remove(const AName: String);
var
  RemovedAny: Boolean;
  I: Integer;
begin
  if (FAllowDuplicateNames) then
  begin
    RemovedAny := False;
    for I := FCount - 1 downto 0 do
    begin
      if (FElements[I].Name = AName) then
      begin
        Delete(I);
        RemovedAny := True;
      end;
    end;

    if (RemovedAny) then
      RebuildIndices;
  end
  else
  begin
    I := IndexOfName(AName);
    if (I >= 0) then
    begin
      Delete(I);
      RebuildIndices;
    end;
  end;
end;

procedure TValueDocument.SetAllowDuplicateNames(const AValue: Boolean);
begin
  FAllowDuplicateNames := AValue;
end;

procedure TValueDocument.SetValue(const AIndex: Integer;
  const AValue: TgoBsonValue._IValue);
begin
  if (AIndex < 0) or (AIndex >= Length(FElements)) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);
  if (AValue = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);
  FElements[AIndex].FImpl := AValue;
end;

procedure TValueDocument.SetValueByName(const AName: String;
  const AValue: TgoBsonValue._IValue);
var
  Index: Integer;
begin
  if (AValue = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);

  Index := IndexOfName(AName);
  if (Index < 0) then
    Add(AName, AValue)
  else
    FElements[Index].FImpl := AValue;
end;

function TValueDocument.ToArray: TArray<TgoBsonElement>;
begin
  SetLength(FElements, FCount);
  Result := FElements;
end;

function TValueDocument.TryGetElement(const AName: String;
  out AElement: TgoBsonElement): Boolean;
var
  Index: Integer;
begin
  Index := IndexOfName(AName);
  if (Index < 0) then
  begin
    AElement := Default(TgoBsonElement);
    Result := False;
  end
  else
  begin
    AElement := FElements[Index];
    Result := True;
  end;
end;

function TValueDocument.TryGetValue(const AName: String;
  out AValue: TgoBsonValue._IValue): Boolean;
var
  Index: Integer;
begin
  Index := IndexOfName(AName);
  if (Index < 0) then
  begin
    AValue := nil;
    Result := False;
  end
  else
  begin
    AValue := FElements[Index].FImpl;
    Result := True;
  end;
end;

{ TValueDocument.TIndexMap }

procedure TValueDocument.TIndexMap.Add(const AName: String;
  const AIndex: Integer);
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount >= FGrowThreshold) then
    Resize(Length(FEntries) * 2);

  HashCode := goMurmurHash2(Pointer(AName)^, Length(AName) * SizeOf(Char)) and $7FFFFFFF;
  Mask := Length(FEntries) - 1;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FEntries[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Break;

    if (HC = HashCode) and (FEntries[Index].Name = AName) then
    begin
      FEntries[Index].Index := AIndex;
      Exit;
    end;

    Index := (Index + 1) and Mask;
  end;

  FEntries[Index].HashCode := HashCode;
  FEntries[Index].Name := AName;
  FEntries[Index].Index := AIndex;
  Inc(FCount);
end;

procedure TValueDocument.TIndexMap.Clear;
begin
  FEntries := nil;
  FCount := 0;
  FGrowThreshold := 0;
end;

function TValueDocument.TIndexMap.Get(const AName: String): Integer;
var
  Mask, Index, HashCode, HC: Integer;
begin
  if (FCount = 0) then
    Exit(-1);

  Mask := Length(FEntries) - 1;
  HashCode := goMurmurHash2(Pointer(AName)^, Length(AName) * SizeOf(Char)) and $7FFFFFFF;
  Index := HashCode and Mask;

  while True do
  begin
    HC := FEntries[Index].HashCode;
    if (HC = EMPTY_HASH) then
      Exit(-1);

    if (HC = HashCode) and (FEntries[Index].Name = AName) then
      Exit(FEntries[Index].Index);

    Index := (Index + 1) and Mask;
  end;
end;

procedure TValueDocument.TIndexMap.Release;
begin
  FEntries := nil;
  FreeMem(@Self);
end;

procedure TValueDocument.TIndexMap.Resize(ANewSize: Integer);
var
  NewMask, I, NewIndex: Integer;
  OldEntries, NewEntries: TMapEntries;
begin
  if (ANewSize < 4) then
    ANewSize := 4;
  NewMask := ANewSize - 1;
  SetLength(NewEntries, ANewSize);
  for I := 0 to ANewSize - 1 do
    NewEntries[I].HashCode := EMPTY_HASH;
  OldEntries := FEntries;

  for I := 0 to Length(OldEntries) - 1 do
  begin
    if (OldEntries[I].HashCode <> EMPTY_HASH) then
    begin
      NewIndex := OldEntries[I].HashCode and NewMask;
      while (NewEntries[NewIndex].HashCode <> EMPTY_HASH) do
        NewIndex := (NewIndex + 1) and NewMask;
      NewEntries[NewIndex] := OldEntries[I];
    end;
  end;

  FEntries := NewEntries;
  FGrowThreshold := (ANewSize * 3) shr 2; // 75%
end;

{ TValueNull }

function TValueNull.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  Result := (AOther.BsonType = TgoBsonType.Null);
end;

function TValueNull.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Null;
end;

function TValueNull.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonNull._INull) then
  begin
    TgoBsonNull._INull(Obj) := TgoBsonNull._INull(@VALUE_NULL);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueNull.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := False;
end;

function TValueNull.ToString(const ADefault: String): String;
begin
  Result := 'null';
end;

{ TValueUndefined }

function TValueUndefined.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  Result := (AOther.BsonType = TgoBsonType.Undefined);
end;

function TValueUndefined.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Undefined;
end;

function TValueUndefined.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonUndefined._IUndefined) then
  begin
    TgoBsonUndefined._IUndefined(Obj) := TgoBsonUndefined._IUndefined(@VALUE_UNDEFINED);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueUndefined.ToBoolean(const ADefault: Boolean): Boolean;
begin
  Result := False;
end;

function TValueUndefined.ToString(const ADefault: String): String;
begin
  Result := 'undefined';
end;

{ TValueObjectId }

function TValueObjectId.AsObjectId: TgoObjectId;
begin
  Result := FValue;
end;

class function TValueObjectId.Create(
  const AValue: TgoObjectId): TgoBsonValue._IValue;
var
  V: PValueObjectId;
begin
  GetMem(V, SizeOf(TValueObjectId));
  V.FBase.FVTable := @VTABLE_OBJECT_ID;
  V.FBase.FRefCount := 0;
  V.FValue := AValue;
  Result := TgoBsonValue._IValue(V);
end;

function TValueObjectId.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  if (AOther.BsonType = TgoBsonType.ObjectId) then
    Result := (FValue = AOther.AsObjectId)
  else
    Result := False;
end;

function TValueObjectId.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.ObjectId;
end;

function TValueObjectId.ToObjectId: TgoObjectId;
begin
  Result := FValue;
end;

function TValueObjectId.ToString(const ADefault: String): String;
begin
  Result := FValue.ToString;
end;

{ TValueRegularExpression }

class function TValueRegularExpression.Create(
  const APattern: String): TgoBsonRegularExpression._IRegularExpression;
var
  Index: Integer;
  Escaped, Unescaped, Pattern, Options: String;
begin
  if (APattern <> '') and (APattern.Chars[0] = '/') then
  begin
    Index := APattern.LastIndexOf('/');
    Escaped := APattern.Substring(1, Index - 1);
    if (Escaped = '(?:)') then
      Unescaped := ''
    else
      Unescaped := Escaped.Replace('\/', '/', [rfReplaceAll]);
    Pattern := Unescaped;
    Options := APattern.Substring(Index + 1);
  end
  else
  begin
    Pattern := APattern;
    Options := '';
  end;
  Result := Create(Pattern, Options);
end;

class function TValueRegularExpression.Create(const APattern,
  AOptions: String): TgoBsonRegularExpression._IRegularExpression;
var
  V: PValueRegularExpression;
begin
  GetMem(V, SizeOf(TValueRegularExpression));
  V.FBase.FVTable := @VTABLE_REGULAR_EXPRESSION;
  V.FBase.FRefCount := 0;
  Pointer(V.FPattern) := nil;
  Pointer(V.FOptions) := nil;
  V.FPattern := APattern;
  V.FOptions := AOptions;
  Result := TgoBsonRegularExpression._IRegularExpression(V);
end;

function TValueRegularExpression.Equals(
  const AOther: TgoBsonValue._IValue): Boolean;
var
  Other: PValueRegularExpression;
begin
  if (AOther.BsonType = TgoBsonType.RegularExpression) then
  begin
    Other := PValueRegularExpression(AOther);
    Result := (FPattern = Other.FPattern) and (FOptions = Other.FOptions);
  end
  else
    Result := False;
end;

function TValueRegularExpression.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.RegularExpression;
end;

function TValueRegularExpression.GetOptions: String;
begin
  Result := FOptions;
end;

function TValueRegularExpression.GetPattern: String;
begin
  Result := FPattern;
end;

function TValueRegularExpression.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if (IID = TgoBsonRegularExpression._IRegularExpression) then
  begin
    TgoBsonRegularExpression._IRegularExpression(Obj) := TgoBsonRegularExpression._IRegularExpression(@Self);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueRegularExpression.Release: Integer;
begin
  Result := AtomicDecrement(FBase.FRefCount);
  if (Result = 0) then
  begin
    FPattern := '';
    FOptions := '';
    FreeMem(@Self);
  end;
end;

{ TValueJavaScript }

class function TValueJavaScript.Create(
  const ACode: String): TgoBsonJavaScript._IJavaScript;
var
  V: PValueJavaScript;
begin
  GetMem(V, SizeOf(TValueJavaScript));
  V.FBase.FVTable := @VTABLE_JAVA_SCRIPT;
  V.FBase.FRefCount := 0;
  Pointer(V.FCode) := nil;
  V.FCode := ACode;
  Result := TgoBsonJavaScript._IJavaScript(V);
end;

function TValueJavaScript.Equals(const AOther: TgoBsonValue._IValue): Boolean;
var
  Other: PValueJavaScript;
begin
  if (AOther.BsonType = TgoBsonType.JavaScript) then
  begin
    Other := PValueJavaScript(AOther);
    Result := (FCode = Other.FCode);
  end
  else
    Result := False;
end;

function TValueJavaScript.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.JavaScript;
end;

function TValueJavaScript.GetCode: String;
begin
  Result := FCode;
end;

function TValueJavaScript.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonJavaScript._IJavaScript) then
  begin
    TgoBsonJavaScript._IJavaScript(Obj) := TgoBsonJavaScript._IJavaScript(@Self);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueJavaScript.Release: Integer;
begin
  Result := AtomicDecrement(FBase.FRefCount);
  if (Result = 0) then
  begin
    FCode := '';
    FreeMem(@Self);
  end;
end;

{ TValueJavaScriptWithScope }

function TValueJavaScriptWithScope.Clone: TgoBsonValue._IValue;
begin
  Result := TValueJavaScriptWithScope.Create(FBase.FCode, FScope.Clone);
end;

class function TValueJavaScriptWithScope.Create(const ACode: String;
  const AScope: TgoBsonDocument): TgoBsonJavaScriptWithScope._IJavaScriptWithScope;
var
  V: PValueJavaScriptWithScope;
begin
  if (AScope.FImpl = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);

  GetMem(V, SizeOf(TValueJavaScriptWithScope));
  V.FBase.FBase.FVTable := @VTABLE_JAVA_SCRIPT_WITH_SCOPE;
  V.FBase.FBase.FRefCount := 0;
  Pointer(V.FBase.FCode) := nil;
  V.FBase.FCode := ACode;
  Pointer(V.FScope) := nil;
  V.FScope := AScope;

  Result := TgoBsonJavaScriptWithScope._IJavaScriptWithScope(V);
end;

function TValueJavaScriptWithScope.DeepClone: TgoBsonValue._IValue;
begin
  Result := TValueJavaScriptWithScope.Create(FBase.FCode, FScope.DeepClone);
end;

function TValueJavaScriptWithScope.Equals(
  const AOther: TgoBsonValue._IValue): Boolean;
var
  Other: PValueJavaScriptWithScope;
begin
  if (AOther.BsonType = TgoBsonType.JavaScriptWithScope) then
  begin
    Other := PValueJavaScriptWithScope(AOther);
    Result := (FBase.FCode = Other.FBase.FCode) and (FScope = Other.FScope);
  end
  else
    Result := False;
end;

function TValueJavaScriptWithScope.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.JavaScriptWithScope;
end;

function TValueJavaScriptWithScope.GetScope: TgoBsonDocument;
begin
  Result := FScope;
end;

function TValueJavaScriptWithScope.QueryInterface(const IID: TGUID;
  out Obj): HResult;
begin
  if (IID = TgoBsonJavaScript._IJavaScript)
    or (IID = TgoBsonJavaScriptWithScope._IJavaScriptWithScope) then
  begin
    TgoBsonJavaScript._IJavaScript(Obj) := TgoBsonJavaScript._IJavaScript(@Self);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueJavaScriptWithScope.Release: Integer;
begin
  Result := AtomicDecrement(FBase.FBase.FRefCount);
  if (Result = 0) then
  begin
    FBase.FCode := '';
    FScope.FImpl := nil;
    FreeMem(@Self);
  end;
end;

{ TValueSymbol }

class function TValueSymbol.Create(const AName: String): TgoBsonSymbol._ISymbol;
var
  V: PValueSymbol;
begin
  GetMem(V, SizeOf(TValueSymbol));
  V.FBase.FVTable := @VTABLE_SYMBOL;
  V.FBase.FRefCount := 0;
  Pointer(V.FName) := nil;
  V.FName := AName;
  Result := TgoBsonSymbol._ISymbol(V);
end;

function TValueSymbol.Equals(const AOther: TgoBsonValue._IValue): Boolean;
var
  Other: PValueSymbol;
begin
  if (AOther.BsonType = TgoBsonType.Symbol) then
  begin
    Other := PValueSymbol(AOther);
    Result := (FName = Other.FName);
  end
  else
    Result := False;
end;

function TValueSymbol.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Symbol;
end;

function TValueSymbol.GetName: String;
begin
  Result := FName;
end;

function TValueSymbol.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonSymbol._ISymbol) then
  begin
    TgoBsonSymbol._ISymbol(Obj) := TgoBsonSymbol._ISymbol(@Self);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueSymbol.Release: Integer;
begin
  Result := AtomicDecrement(FBase.FRefCount);
  if (Result = 0) then
  begin
    FName := '';
    FreeMem(@Self);
  end;
end;

function TValueSymbol.ToString(const ADefault: String): String;
begin
  Result := FName;
end;

{ TValueTimestamp }

class function TValueTimestamp.Create(
  const AValue: Int64): TgoBsonTimestamp._ITimestamp;
var
  V: PValueTimestamp;
begin
  GetMem(V, SizeOf(TValueTimestamp));
  V.FBase.FVTable := @VTABLE_TIMESTAMP;
  V.FBase.FRefCount := 0;
  V.FValue := AValue;
  Result := TgoBsonTimestamp._ITimestamp(V);
end;

class function TValueTimestamp.Create(const ATimestamp,
  AIncrement: Integer): TgoBsonTimestamp._ITimestamp;
begin
  Result := Create((UInt64(ATimestamp) shl 32) or UInt32(AIncrement));
end;

function TValueTimestamp.Equals(const AOther: TgoBsonValue._IValue): Boolean;
var
  Other: PValueTimestamp;
begin
  if (AOther.BsonType = TgoBsonType.Timestamp) then
  begin
    Other := PValueTimestamp(AOther);
    Result := (FValue = Other.FValue);
  end
  else
    Result := False;
end;

function TValueTimestamp.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.Timestamp;
end;

function TValueTimestamp.GetIncrement: Integer;
begin
  Result := Integer(FValue);
end;

function TValueTimestamp.GetTimestamp: Integer;
begin
  Result := Integer(FValue shr 32);
end;

function TValueTimestamp.GetValue: Int64;
begin
  Result := FValue;
end;

function TValueTimestamp.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonTimestamp._ITimestamp) then
  begin
    TgoBsonTimestamp._ITimestamp(Obj) := TgoBsonTimestamp._ITimestamp(@Self);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

{ TValueMaxKey }

function TValueMaxKey.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  Result := (AOther.BsonType = TgoBsonType.MaxKey);
end;

function TValueMaxKey.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.MaxKey;
end;

function TValueMaxKey.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonMaxKey._IMaxKey) then
  begin
    TgoBsonMaxKey._IMaxKey(Obj) := TgoBsonMaxKey._IMaxKey(@VALUE_MAX_KEY);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueMaxKey.ToString(const ADefault: String): String;
begin
  Result := 'MaxKey';
end;

{ TValueMinKey }

function TValueMinKey.Equals(const AOther: TgoBsonValue._IValue): Boolean;
begin
  Result := (AOther.BsonType = TgoBsonType.MinKey);
end;

function TValueMinKey.GetBsonType: TgoBsonType;
begin
  Result := TgoBsonType.MinKey;
end;

function TValueMinKey.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if (IID = TgoBsonMinKey._IMinKey) then
  begin
    TgoBsonMinKey._IMinKey(Obj) := TgoBsonMinKey._IMinKey(@VALUE_MIN_KEY);
    Result := S_OK;
  end
  else
    Result := E_NOINTERFACE;
end;

function TValueMinKey.ToString(const ADefault: String): String;
begin
  Result := 'MinKey';
end;

end.
