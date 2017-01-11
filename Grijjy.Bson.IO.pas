unit Grijjy.Bson.IO;
(*< JSON and BSON reading and writing.

  @bold(Quick Start)

  Consider this JSON document:

  @preformatted(
    { "x" : 1,
      "y" : 2,
      "z" : [ 3.14, true] }
  )

  You can serialize it manually to BSON like this:

  <source>
  var
    Writer: IgoBsonWriter;
    Bson: TBytes;
  begin
    Writer := TgoBsonWriter.Create;
    Writer.WriteStartDocument;

    Writer.WriteName('x');
    Writer.WriteInt32(1);

    Writer.WriteInt32('y', 2); // Writes name and value in single call

    Writer.WriteName('z');
    Writer.WriteStartArray;
    Writer.WriteDouble(3.14);
    Writer.WriteBoolean(True);
    Writer.WriteEndArray;

    Writer.WriteEndDocument;

    Bson := Writer.ToBson;
  end;
  </source>

  Likewise, you can serialize to JSON by using the IgoJsonWriter interface
  instead.

  You can also manually deserialize by using the IgoBsonReader and IgoJsonReader
  interfaces. However, these are a bit more complicated to use since you don't
  know the deserialized BSON types in advance.

  You can look at the unit tests in the unit Tests.Grijjy.Bson.IO
  for examples of manual serialization and deserialization. *)

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.Classes,
  System.SysUtils,
  Grijjy.Bson;

type
  { Type of exception that is raised when parsing an invalid JSON source. }
  EgoJsonParserError = class(Exception)
  {$REGION 'Internal Declarations'}
  private
    FLineNumber: Integer;
    FColumnNumber: Integer;
    FPosition: Integer;
  {$WARNINGS OFF}
  private
    constructor Create(const AMsg: String; const ALineNumber,
      AColumnNumber, APosition: Integer);
  {$WARNINGS ON}
  {$ENDREGION 'Internal Declarations'}
  public
    { The line number of the error in the source text, starting at 1. }
    property LineNumber: Integer read FLineNumber;

    { The column number of the error in the source text, starting at 1. }
    property ColumnNumber: Integer read FColumnNumber;

    { The position of the error in the source text, starting at 0.
      The position is the offset (in characters) from the beginning of the
      text. }
    property Position: Integer read FPosition;
  end;

type
  { State of a IgoBsonBaseWriter }
  TgoBsonWriterState = (
    { Initial state }
    Initial,

    { The writer is positioned to write a name }
    Name,

    { The writer is positioned to write a value }
    Value,

    { The writer is positioned to write a scope document (call
      WriteStartDocument to start writing the scope document). }
    ScopeDocument,

    { The writer is done }
    Done,

    { The writer is closed }
    Closed);

type
  { State of a IgoBsonBaseReader }
  TgoBsonReaderState = (
    { Initial state }
    Initial,

    { The reader is positioned at the type of an element or value }
    &Type,

    { The reader is positioned at the name of an element }
    Name,

    { The reader is positioned at the value }
    Value,

    { The reader is positioned at a scope document }
    ScopeDocument,

    { The reader is positioned at the end of a document }
    EndOfDocument,

    { The reader is positioned at the end of an array }
    EndOfArray,

    { The reader has finished reading a document }
    Done,

    { The reader is closed }
    Closed);

type
  { Used internally by BSON/JSON readers and writers to represent the current
    context. }
  TgoBsonContextType = (
    { The top level of a BSON document }
    TopLevel,

    { A (possible embedded) BSON document }
    Document,

    { A BSON array }
    &Array,

    { A JavaScript w/Scope BSON value }
    JavaScriptWithScope,

    { The scope document of a JavaScript w/Scope BSON value }
    ScopeDocument);

type
  { Base interface for IgoBsonWriter, IgoJsonWriter and IgoBsonDocumentWriter }
  IgoBsonBaseWriter = interface
  ['{4525DC0D-C54E-47B2-85BE-4C09A8F5DF54}']
    {$REGION 'Internal Declarations'}
    function GetState: TgoBsonWriterState;
    {$ENDREGION 'Internal Declarations'}

    { Writes a BSON value.

      Parameters:
        AValue: the BSON value to write.

      Raises:
        EArgumentNilException if AValue has not been assigned (IsNil returns
        True). }
    procedure WriteValue(const AValue: TgoBsonValue);

    { Writes a BSON binary.

      Parameters:
        AValue: the BSON binary to write.

      Raises:
        EArgumentNilException if AValue has not been assigned (IsNil returns
        True). }
    procedure WriteBinaryData(const AValue: TgoBsonBinaryData);

    { Writes a BSON Regular Expression.

      Parameters:
        AValue: the BSON Regular Expression to write.

      Raises:
        EArgumentNilException if AValue has not been assigned (IsNil returns
        True). }
    procedure WriteRegularExpression(const AValue: TgoBsonRegularExpression); overload;

    { Writes both an element name and a BSON Regular Expression.

      Parameters:
        AName: the element name.
        AValue: the BSON Regular Expression to write.

      Raises:
        EArgumentNilException if AValue has not been assigned (IsNil returns
        True). }
    procedure WriteRegularExpression(const AName: String; const AValue: TgoBsonRegularExpression); overload;

    { Writes the name of an element.

      Parameters:
        AName: the element name. }
    procedure WriteName(const AName: String);

    { Writes a Boolean value.

      Parameters:
        AValue: the Boolean value. }
    procedure WriteBoolean(const AValue: Boolean); overload;

    { Writes a name/value pair with a Boolean value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        AValue: the Boolean value. }
    procedure WriteBoolean(const AName: String; const AValue: Boolean); overload;

    { Writes a 32-bit Integer value.

      Parameters:
        AValue: the Integer value. }
    procedure WriteInt32(const AValue: Integer); overload;

    { Writes a name/value pair with a 32-bit Integer value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        AValue: the Integer value. }
    procedure WriteInt32(const AName: String; const AValue: Integer); overload;

    { Writes a 64-bit Integer value.

      Parameters:
        AValue: the Integer value. }
    procedure WriteInt64(const AValue: Int64); overload;

    { Writes a name/value pair with a 64-bit Integer value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        AValue: the Integer value. }
    procedure WriteInt64(const AName: String; const AValue: Int64); overload;

    { Writes a Double value.

      Parameters:
        AValue: the Double value. }
    procedure WriteDouble(const AValue: Double); overload;

    { Writes a name/value pair with a Double value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        AValue: the Double value. }
    procedure WriteDouble(const AName: String; const AValue: Double); overload;

    { Writes a String value.

      Parameters:
        AValue: the String value. }
    procedure WriteString(const AValue: String); overload;

    { Writes a name/value pair with a String value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        AValue: the String value. }
    procedure WriteString(const AName, AValue: String); overload;

    { Writes a DateTime value.

      Parameters:
        AMillisecondsSinceEpoch: the number of UTC milliseconds since the
          Unix epoch }
    procedure WriteDateTime(const AMillisecondsSinceEpoch: Int64); overload;

    { Writes a name/value pair with a DateTime value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        AMillisecondsSinceEpoch: the number of UTC milliseconds since the
          Unix epoch }
    procedure WriteDateTime(const AName: String; const AMillisecondsSinceEpoch: Int64); overload;

    { Writes a byte array as binary data of sub type Binary

      Parameters:
        ABytes: the bytes to write }
    procedure WriteBytes(const AValue: TBytes); overload;

    { Writes a name/value pair with binary date.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        ABytes: the bytes to write }
    procedure WriteBytes(const AName: String; const AValue: TBytes); overload;

    { Writes a Timestamp value.

      Parameters:
        AValue: the Timestamp value. }
    procedure WriteTimestamp(const AValue: Int64); overload;

    { Writes a name/value pair with a Timestamp value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        AValue: the Timestamp value. }
    procedure WriteTimestamp(const AName: String; const AValue: Int64); overload;

    { Writes an ObjectId value.

      Parameters:
        AValue: the ObjectId value. }
    procedure WriteObjectId(const AValue: TgoObjectId); overload;

    { Writes a name/value pair with an ObjectId value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        AValue: the ObjectId value. }
    procedure WriteObjectId(const AName: String; const AValue: TgoObjectId); overload;

    { Writes a JavaScript.

      Parameters:
        ACode: the JavaScript code. }
    procedure WriteJavaScript(const ACode: String); overload;

    { Writes a name/value pair with a JavaScript.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        ACode: the JavaScript code. }
    procedure WriteJavaScript(const AName, ACode: String); overload;

    { Writes a JavaScript with scope.

      Parameters:
        ACode: the JavaScript code.

      @bold(Note): call WriteStartDocument to start writing the scope. }
    procedure WriteJavaScriptWithScope(const ACode: String); overload;

    { Writes a name/value pair with a JavaScript with scope.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        ACode: the JavaScript code.

      @bold(Note): call WriteStartDocument to start writing the scope. }
    procedure WriteJavaScriptWithScope(const AName, ACode: String); overload;

    { Writes a BSON Null value }
    procedure WriteNull; overload;

    { Writes a name/value pair with a BSON Null value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name. }
    procedure WriteNull(const AName: String); overload;

    { Writes a BSON Undefined value. }
    procedure WriteUndefined; overload;

    { Writes a name/value pair with a BSON Undefined value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name. }
    procedure WriteUndefined(const AName: String); overload;

    { Writes a BSON MaxKey value }
    procedure WriteMaxKey; overload;

    { Writes a name/value pair with a BSON MaxKey value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name. }
    procedure WriteMaxKey(const AName: String); overload;

    { Writes a BSON MinKey value }
    procedure WriteMinKey; overload;

    { Writes a name/value pair with a BSON MinKey value.
      Can only be used when inside a document.

      Parameters:
        AName: the element name. }
    procedure WriteMinKey(const AName: String); overload;

    { Writes a BSON Symbol.

      Parameters:
        AValue: the symbol. }
    procedure WriteSymbol(const AValue: String); overload;

    { Writes a name/value pair with a BSON Symbol.
      Can only be used when inside a document.

      Parameters:
        AName: the element name.
        AValue: the symbol. }
    procedure WriteSymbol(const AName, AValue: String); overload;

    { Writes the start of a BSON Array }
    procedure WriteStartArray; overload;

    { Writes a name/value pair, where the value starts a BSON Array.
      Can only be used when inside a document.

      Parameters:
        AName: the element name. }
    procedure WriteStartArray(const AName: String); overload;

    { Writes the end of a BSON Array }
    procedure WriteEndArray;

    { Writes the start of a BSON Document }
    procedure WriteStartDocument; overload;

    { Writes a name/value pair, where the value starts a BSON Document.
      Can only be used when inside a document.

      Parameters:
        AName: the element name. }
    procedure WriteStartDocument(const AName: String); overload;

    { Writes the end of a BSON Document }
    procedure WriteEndDocument;

    { The current state of the writer }
    property State: TgoBsonWriterState read GetState;
  end;

type
  { Interface for writing BSON values to binary BSON format.
    See TgoBsonWriter for the stock implementation of this interface. }
  IgoBsonWriter = interface(IgoBsonBaseWriter)
  ['{6B413B69-018F-48AD-8D81-140C1078AFA1}']
    { Returns the currently written data as a byte array.

      Returns:
        The data in BSON format.

      @bold(Note): you usually call this method when you have finished writing
      a BSON Document or value }
    function ToBson: TBytes;

    { Writes a raw BSON document.

      Parameters:
        AValue: the raw BSON document to write.

      @bold(Note): no BSON validity checking is performed. The value will be
      written as-is, and generate invalid BSON of not used carefully. }
    procedure WriteRawBsonDocument(const ADocument: TBytes);
  end;

type
  { Interface for writing BSON values to JSON format.
    See TgoJsonWriter for the stock implementation of this interface. }
  IgoJsonWriter = interface(IgoBsonBaseWriter)
  ['{92F5BA20-02C9-401C-8403-B51F8898E692}']
    { Returns the currently written data as a JSON string.

      Returns:
        The data in JSON format.

      @bold(Note): you usually call this method when you have finished writing
      a BSON Document or value }
    function ToJson: String;

    { Inserts a raw value into the current JSON string.

      Parameters:
        AValue: the value to write.

      @bold(Note): no JSON syntax checking is performed. The value will be
      written as-is, and generate invalid JSON of not used carefully. You
      usually never call this method yourself. }
    procedure WriteRaw(const AValue: String);
  end;

type
  { Interface for writing BSON values to a BSON document.
    See TgoBsonDocumentWriter for the stock implementation of this interface. }
  IgoBsonDocumentWriter = interface(IgoBsonBaseWriter)
  ['{4A410F7E-69FA-46A0-ACE2-317AF5DEA2B8}']
    {$REGION 'Internal Declarations'}
    function GetDocument: TgoBsonDocument;
    {$ENDREGION 'Internal Declarations'}

    { The document the writer writes to }
    property Document: TgoBsonDocument read GetDocument;
  end;

type
  { A bookmark that can be used to return a reader to the current position and
    state. }
  IgoBsonReaderBookmark = interface
  ['{7324A2DE-20F6-4FF2-9973-FD861F6833EB}']
    {$REGION 'Internal Declarations'}
    function GetState: TgoBsonReaderState;
    function GetCurrentBsonType: TgoBsonType;
    function GetCurrentName: String;
    {$ENDREGION 'Internal Declarations'}

    { The current state of the reader }
    property State: TgoBsonReaderState read GetState;

    { The current BsonType }
    property CurrentBsonType: TgoBsonType read GetCurrentBsonType;

    { The name of the current element }
    property CurrentName: String read GetCurrentName;
  end;

type
  { Base interface for IgoBsonReader, IgoJsonReader and IgoBsonDocumentReader }
  IgoBsonBaseReader = interface
  ['{A0592C3C-5E24-4424-9662-EA7F33BB1B9A}']
    {$REGION 'Internal Declarations'}
    function GetState: TgoBsonReaderState;
    {$ENDREGION 'Internal Declarations'}

    { Whether the reader is at the end of the stream.

      Returns:
        True if at end of stream }
    function EndOfStream: Boolean;

    { Gets the current BSON type in the stream.

      Returns:
        The current BSON type.

       @bold(Note): calls ReadBsonType if necessary. }
    function GetCurrentBsonType: TgoBsonType;

    { Gets a bookmark to the reader's current position and state.

      Returns:
        A bookmark.

      You can use the returned bookmark to restore the state using
      ReturnToBookmark. }
    function GetBookmark: IgoBsonReaderBookmark;

    { Returns the reader to previously bookmarked position and state.

      AParameters:
        ABookmark: the bookmark to return to. This value has previously been
          acquired using GetBookmark. }
    procedure ReturnToBookmark(const ABookmark: IgoBsonReaderBookmark);

    { Reads a BSON Document from the stream.

      Returns:
        The read BSON Document.

      Raises:
        An exception if the current position in the stream does not contain
        a BSON Document, or the stream is invalid. }
    function ReadDocument: TgoBsonDocument;

    { Reads a BSON Array from the stream.

      Returns:
        The read BSON Array.

      Raises:
        An exception if the current position in the stream does not contain
        a BSON Array, or the stream is invalid. }
    function ReadArray: TgoBsonArray;

    { Reads a BSON value from the stream.

      Returns:
        The read BSON value.

      Raises:
        An exception if the current position in the stream does not contain
        a BSON value, or the stream is invalid. }
    function ReadValue: TgoBsonValue;

    { Reads a BSON Binary from the stream.

      Returns:
        The read BSON Binary.

      Raises:
        An exception if the current position in the stream does not contain
        a BSON Binary, or the stream is invalid. }
    function ReadBinaryData: TgoBsonBinaryData;

    { Reads a BSON Regular Expression from the stream.

      Returns:
        The read BSON Regular Expression.

      Raises:
        An exception if the current position in the stream does not contain
        a BSON Regular Expression, or the stream is invalid. }
    function ReadRegularExpression: TgoBsonRegularExpression;

    { Reads a BSON type from the stream.

      Returns:
        The read BSON type.

      Raises:
        An exception if the current position in the stream does not contain
        a BSON type, or the stream is invalid. }
    function ReadBsonType: TgoBsonType;

    { Reads the name of an element from the stream.

      Returns:
        The read element name.

      Raises:
        An exception if the current position in the stream does not contain
        an element name, or the stream is invalid. }
    function ReadName: String;

    { Skips the name of an element.

      Raises:
        An exception if the current position in the stream does not contain
        an element name, or the stream is invalid. }
    procedure SkipName;

    { Skips the value of an element.

      Raises:
        An exception if the current position in the stream does not contain
        an element value, or the stream is invalid. }
    procedure SkipValue;

    { Reads a Boolean value from the stream.

      Returns:
        The read Boolean value.

      Raises:
        An exception if the current position in the stream does not contain
        a Boolean value, or the stream is invalid. }
    function ReadBoolean: Boolean;

    { Reads a 32-bit Integer value from the stream.

      Returns:
        The read Integer value.

      Raises:
        An exception if the current position in the stream does not contain
        a 32-bit Integer value, or the stream is invalid. }
    function ReadInt32: Integer;

    { Reads a 64-bit Integer value from the stream.

      Returns:
        The read Integer value.

      Raises:
        An exception if the current position in the stream does not contain
        a 64-bit Integer value, or the stream is invalid. }
    function ReadInt64: Int64;

    { Reads a Double value from the stream.

      Returns:
        The read Double value.

      Raises:
        An exception if the current position in the stream does not contain
        a Double value, or the stream is invalid. }
    function ReadDouble: Double;

    { Reads a String value from the stream.

      Returns:
        The read String value.

      Raises:
        An exception if the current position in the stream does not contain
        a String value, or the stream is invalid. }
    function ReadString: String;

    { Reads a DateTime value from the stream.

      Returns:
        The read DateTime value as the number of UTC milliseconds since the
        Unix epoch.

      Raises:
        An exception if the current position in the stream does not contain
        a DateTime value, or the stream is invalid. }
    function ReadDateTime: Int64;

    { Reads a Timestamp value from the stream.

      Returns:
        The read Timestamp value.

      Raises:
        An exception if the current position in the stream does not contain
        a Timestamp value, or the stream is invalid. }
    function ReadTimestamp: Int64;

    { Reads an ObjectId value from the stream.

      Returns:
        The read ObjectId value.

      Raises:
        An exception if the current position in the stream does not contain
        a ObjectId value, or the stream is invalid. }
    function ReadObjectId: TgoObjectId;

    { Reads a Binary value from the stream as a byte array.

      Returns:
        The read Binary value.

      Raises:
        An exception if the current position in the stream does not contain
        a BSON Binary, or the stream is invalid. }
    function ReadBytes: TBytes;

    { Reads a JavaScript from the stream.

      Returns:
        The read JavaScript.

      Raises:
        An exception if the current position in the stream does not contain
        a JavaScript, or the stream is invalid. }
    function ReadJavaScript: String;

    { Reads a JavaScript with scope from the stream.

      Returns:
        The read JavaScript.

      Raises:
        An exception if the current position in the stream does not contain
        a JavaScript with Scope, or the stream is invalid.

      @bold(Note): call ReadStartDocument next to read the scope. }
    function ReadJavaScriptWithScope: String;

    { Reads a BSON Null value from the stream.

      Raises:
        An exception if the current position in the stream does not contain
        a Null value, or the stream is invalid. }
    procedure ReadNull;

    { Reads a BSON Undefined value from the stream.

      Raises:
        An exception if the current position in the stream does not contain
        a Undefined value, or the stream is invalid. }
    procedure ReadUndefined;

    { Reads a BSON MaxKey value from the stream.

      Raises:
        An exception if the current position in the stream does not contain
        a MaxKey value, or the stream is invalid. }
    procedure ReadMaxKey;

    { Reads a BSON MinKey value from the stream.

      Raises:
        An exception if the current position in the stream does not contain
        a MinKey value, or the stream is invalid. }
    procedure ReadMinKey;

    { Reads a BSON Symbol from the stream.

      Returns:
        The read Symbol name.

      Raises:
        An exception if the current position in the stream does not contain
        a Symbol, or the stream is invalid. }
    function ReadSymbol: String;

    { Reads the start of a BSON Array from the stream.

      Raises:
        An exception if the current position in the stream does not contain
        the start of a BSON Array, or the stream is invalid. }
    procedure ReadStartArray;

    { Reads the end of a BSON Array from the stream.

      Raises:
        An exception if the current position in the stream does not contain
        the end of a BSON Array, or the stream is invalid. }
    procedure ReadEndArray;

    { Reads the start of a BSON Document from the stream.

      Raises:
        An exception if the current position in the stream does not contain
        the start of a BSON Document, or the stream is invalid. }
    procedure ReadStartDocument;

    { Reads the end of a BSON Document from the stream.

      Raises:
        An exception if the current position in the stream does not contain
        the end of a BSON Document, or the stream is invalid. }
    procedure ReadEndDocument;

    { The current state of the reader }
    property State: TgoBsonReaderState read GetState;
  end;

type
  { Interface for reading BSON values from binary BSON format.
    See TgoBsonReader for the stock implementation of this interface. }
  IgoBsonReader = interface(IgoBsonBaseReader)
  ['{773A4BBE-A4D9-4DDA-A937-C865ADC0A5B8}']
  end;

type
  { Interface for reading BSON values from JSON format.
    See TgoJsonReader for the stock implementation of this interface. }
  IgoJsonReader = interface(IgoBsonBaseReader)
  ['{F579A93F-760C-463D-9B54-64AAF527F514}']
  end;

type
  { Interface for reading BSON values from a BSON Document.
    See TgoBsonDocumentReader for the stock implementation of this interface. }
  IgoBsonDocumentReader = interface(IgoBsonBaseReader)
  ['{1D4F90C4-C790-491C-844A-C7FFCF58F2E8}']
  end;

type
  { Abstract base class of TgoBsonWriter and TgoJsonWriter.
    Implements the IgoBsonBaseWriter interface. }
  TgoBsonBaseWriter = class abstract(TInterfacedObject, IgoBsonBaseWriter)
  {$REGION 'Internal Declarations'}
  private
    FState: TgoBsonWriterState;
    FName: String;
  private
    procedure WriteArray(const AArray: TgoBsonArray);
    procedure WriteDocument(const ADocument: TgoBsonDocument);
    procedure DoWriteJavaScriptWithScope(const AValue: TgoBsonJavaScriptWithScope);
  protected
    { IgoBsonBaseWriter }
    procedure WriteName(const AName: String); virtual;
    procedure WriteValue(const AValue: TgoBsonValue);
    function GetState: TgoBsonWriterState;
    procedure WriteBoolean(const AValue: Boolean); overload; virtual; abstract;
    procedure WriteBoolean(const AName: String; const AValue: Boolean); overload;
    procedure WriteInt32(const AValue: Integer); overload; virtual; abstract;
    procedure WriteInt32(const AName: String; const AValue: Int32); overload;
    procedure WriteInt64(const AValue: Int64); overload; virtual; abstract;
    procedure WriteInt64(const AName: String; const AValue: Int64); overload;
    procedure WriteDouble(const AValue: Double); overload; virtual; abstract;
    procedure WriteDouble(const AName: String; const AValue: Double); overload;
    procedure WriteString(const AValue: String); overload; virtual; abstract;
    procedure WriteString(const AName, AValue: String); overload;
    procedure WriteDateTime(const AMillisecondsSinceEpoch: Int64); overload; virtual; abstract;
    procedure WriteDateTime(const AName: String; const AMillisecondsSinceEpoch: Int64); overload;
    procedure WriteBytes(const AValue: TBytes); overload;
    procedure WriteBytes(const AName: String; const AValue: TBytes); overload;
    procedure WriteTimestamp(const AValue: Int64); overload; virtual; abstract;
    procedure WriteTimestamp(const AName: String; const AValue: Int64); overload;
    procedure WriteObjectId(const AValue: TgoObjectId); overload; virtual; abstract;
    procedure WriteObjectId(const AName: String; const AValue: TgoObjectId); overload;
    procedure WriteJavaScript(const ACode: String); overload; virtual; abstract;
    procedure WriteJavaScript(const AName, ACode: String); overload;
    procedure WriteJavaScriptWithScope(const ACode: String); overload; virtual; abstract;
    procedure WriteJavaScriptWithScope(const AName, ACode: String); overload;
    procedure WriteNull; overload; virtual; abstract;
    procedure WriteNull(const AName: String); overload;
    procedure WriteUndefined; overload; virtual; abstract;
    procedure WriteUndefined(const AName: String); overload;
    procedure WriteMaxKey; overload; virtual; abstract;
    procedure WriteMaxKey(const AName: String); overload;
    procedure WriteMinKey; overload; virtual; abstract;
    procedure WriteMinKey(const AName: String); overload;
    procedure WriteSymbol(const AValue: String); overload; virtual; abstract;
    procedure WriteSymbol(const AName, AValue: String); overload;
    procedure WriteStartArray; overload; virtual; abstract;
    procedure WriteStartArray(const AName: String); overload;
    procedure WriteEndArray; virtual; abstract;
    procedure WriteStartDocument; overload; virtual; abstract;
    procedure WriteStartDocument(const AName: String); overload;
    procedure WriteEndDocument; virtual; abstract;
    procedure WriteBinaryData(const AValue: TgoBsonBinaryData); virtual; abstract;
    procedure WriteRegularExpression(const AValue: TgoBsonRegularExpression); overload; virtual; abstract;
    procedure WriteRegularExpression(const AName: String; const AValue: TgoBsonRegularExpression); overload;
  protected
    property State: TgoBsonWriterState read FState write FState;
    property Name: String read FName;
  {$ENDREGION 'Internal Declarations'}
  end;

type
  { Stock implementation of the IgoBsonWriter interface. }
  TgoBsonWriter = class(TgoBsonBaseWriter, IgoBsonWriter)
  {$REGION 'Internal Declarations'}
  private type
    TOutput = record
    private const
      TEMP_BYTES_LENGTH = 128;
    private
      FBuffer: TBytes;
      FSize: Integer;
      FCapacity: Integer;
      FTempBytes: TBytes;
    private
    public
      procedure Initialize;

      procedure Write(const AValue; const ASize: Integer);
      procedure WriteBsonType(const ABsonType: TgoBsonType); inline;
      procedure WriteBinarySubType(const ASubType: TgoBsonBinarySubType); inline;
      procedure WriteByte(const AValue: Byte); inline;
      procedure WriteBoolean(const AValue: Boolean); inline;
      procedure WriteInt32(const AValue: Int32); inline;
      procedure WriteInt32At(const APosition, AValue: Int32); inline;
      procedure WriteInt64(const AValue: Int64); inline;
      procedure WriteDouble(const AValue: Double); inline;
      procedure WriteCString(const AValue: String); overload;
      procedure WriteCString(const AValue: TBytes); overload;
      procedure WriteString(const AValue: String);
      procedure WriteObjectId(const AValue: TgoObjectId);

      function ToBytes: TBytes;

      property Position: Integer read FSize;
    end;
  private type
    PContext = ^TContext;
    TContext = record
    private
      FStartPosition: Integer;
      FIndex: Integer;
      FContextType: TgoBsonContextType;
    public
      procedure Initialize(const AContextType: TgoBsonContextType;
        const AStartPosition: Integer); inline;

      property StartPosition: Integer read FStartPosition;
      property Index: Integer read FIndex write FIndex;
      property ContextType: TgoBsonContextType read FContextType;
    end;
  protected type
    TArrayElementNameAccelerator = record
    private class var
      FCachedElementNames: array [0..999] of TBytes;
    private
      class function CreateElementNameBytes(const AIndex: Integer): TBytes; static;
    public
      class constructor Create;
    public
      class function GetElementNameBytes(const AIndex: Integer): TBytes; static;
    end;
  private
    FOutput: TOutput;
    FContextStack: TArray<TContext>;
    FContextIndex: Integer;
    FContext: PContext;
  private
    function GetNextState: TgoBsonWriterState;
    procedure PushContext(const AContextType: TgoBsonContextType;
      const AStartPosition: Integer);
    procedure PopContext;
    procedure WriteNameHelper;
    procedure BackpatchSize;
  protected
    { IgoBsonBaseWriter }
    procedure WriteBoolean(const AValue: Boolean); override;
    procedure WriteInt32(const AValue: Integer); override;
    procedure WriteInt64(const AValue: Int64); override;
    procedure WriteDouble(const AValue: Double); override;
    procedure WriteString(const AValue: String); override;
    procedure WriteDateTime(const AMillisecondsSinceEpoch: Int64); override;
    procedure WriteTimestamp(const AValue: Int64); override;
    procedure WriteObjectId(const AValue: TgoObjectId); override;
    procedure WriteJavaScript(const ACode: String); override;
    procedure WriteJavaScriptWithScope(const ACode: String); override;
    procedure WriteNull; override;
    procedure WriteUndefined; override;
    procedure WriteMaxKey; override;
    procedure WriteMinKey; override;
    procedure WriteSymbol(const AValue: String); override;
    procedure WriteStartArray; override;
    procedure WriteEndArray; override;
    procedure WriteStartDocument; override;
    procedure WriteEndDocument; override;
    procedure WriteBinaryData(const AValue: TgoBsonBinaryData); override;
    procedure WriteRegularExpression(const AValue: TgoBsonRegularExpression); override;
  protected
    { IgoBsonWriter }
    function ToBson: TBytes;
    procedure WriteRawBsonDocument(const ADocument: TBytes);
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a binary BSON writer }
    constructor Create;
  end;

type
  { Stock implementation of the IgoJsonWriter interface. }
  TgoJsonWriter = class(TgoBsonBaseWriter, IgoJsonWriter)
  {$REGION 'Internal Declarations'}
  private type
    PContext = ^TContext;
    TContext = record
    private
      FIndentation: String;
      FContextType: TgoBsonContextType;
      FHasElements: Boolean;
    public
      procedure Initialize(const AParentContext: PContext;
        const AContextType: TgoBsonContextType;
        const AIndentString: String);

      property Indentation: String read FIndentation;
      property ContextType: TgoBsonContextType read FContextType;
      property HasElements: Boolean read FHasElements write FHasElements;
    end;
  private
    FSettings: TgoJsonWriterSettings;
    FOutput: TStringBuilder;
    FContextStack: TArray<TContext>;
    FContextIndex: Integer;
    FContext: PContext;
  private
    function GetNextState: TgoBsonWriterState;
    procedure PushContext(const AContextType: TgoBsonContextType;
      const AIndentString: String);
    procedure PopContext;
    procedure WriteNameHelper(const AName: String);
    procedure WriteQuotedString(const AValue: String);
    procedure WriteEscapedString(const AValue: String);
    class function GuidToString(const ABytes: TBytes;
      const ASubType: TgoBsonBinarySubType): String; static;
  protected
    { IgoBsonBaseWriter }
    procedure WriteBoolean(const AValue: Boolean); override;
    procedure WriteInt32(const AValue: Integer); override;
    procedure WriteInt64(const AValue: Int64); override;
    procedure WriteDouble(const AValue: Double); override;
    procedure WriteString(const AValue: String); override;
    procedure WriteDateTime(const AMillisecondsSinceEpoch: Int64); override;
    procedure WriteTimestamp(const AValue: Int64); override;
    procedure WriteObjectId(const AValue: TgoObjectId); override;
    procedure WriteJavaScript(const ACode: String); override;
    procedure WriteJavaScriptWithScope(const ACode: String); override;
    procedure WriteNull; override;
    procedure WriteUndefined; override;
    procedure WriteMaxKey; override;
    procedure WriteMinKey; override;
    procedure WriteSymbol(const AValue: String); override;
    procedure WriteStartArray; override;
    procedure WriteEndArray; override;
    procedure WriteStartDocument; override;
    procedure WriteEndDocument; override;
    procedure WriteBinaryData(const AValue: TgoBsonBinaryData); override;
    procedure WriteRegularExpression(const AValue: TgoBsonRegularExpression); override;
  protected
    { IgoJsonWriter }
    function ToJson: String;
    procedure WriteRaw(const AValue: String);
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a JSON writer using the default settings. }
    constructor Create; overload;

    { Creates a JSON writer.

      Parameters:
        ASettings: the writer settings to use. }
    constructor Create(const ASettings: TgoJsonWriterSettings); overload;

    { Destructor }
    destructor Destroy; override;
  end;

type
  { Stock implementation of the IgoBsonDocumentWriter interface. }
  TgoBsonDocumentWriter = class(TgoBsonBaseWriter, IgoBsonDocumentWriter)
  {$REGION 'Internal Declarations'}
  private type
    PContext = ^TContext;
    TContext = record
    private
      FContextType: TgoBsonContextType;
      FDocument: TgoBsonDocument;
      FArray: TgoBsonArray;
      FName: String;
      FCode: String;
    public
      procedure Initialize(const AContextType: TgoBsonContextType;
        const ADocument: TgoBsonDocument); overload;
      procedure Initialize(const AContextType: TgoBsonContextType;
        const AArray: TgoBsonArray); overload;
      procedure Initialize(const AContextType: TgoBsonContextType;
        const ACode: String); overload;

      property ContextType: TgoBsonContextType read FContextType;
      property Document: TgoBsonDocument read FDocument;
      property &Array: TgoBsonArray read FArray;
      property Name: String read FName write FName;
      property Code: String read FCode;
    end;
  private
    FDocument: TgoBsonDocument;
    FContextStack: TArray<TContext>;
    FContextIndex: Integer;
    FContext: PContext;
  private
    function GetNextState: TgoBsonWriterState;
    procedure PushContext(const AContextType: TgoBsonContextType;
      const ADocument: TgoBsonDocument); overload;
    procedure PushContext(const AContextType: TgoBsonContextType;
      const AArray: TgoBsonArray); overload;
    procedure PushContext(const AContextType: TgoBsonContextType;
      const ACode: String); overload;
    procedure PopContext;
    procedure AddValue(const AValue: TgoBsonValue);
  protected
    { IgoBsonBaseWriter }
    procedure WriteName(const AName: String); override;
    procedure WriteBoolean(const AValue: Boolean); override;
    procedure WriteInt32(const AValue: Integer); override;
    procedure WriteInt64(const AValue: Int64); override;
    procedure WriteDouble(const AValue: Double); override;
    procedure WriteString(const AValue: String); override;
    procedure WriteDateTime(const AMillisecondsSinceEpoch: Int64); override;
    procedure WriteTimestamp(const AValue: Int64); override;
    procedure WriteObjectId(const AValue: TgoObjectId); override;
    procedure WriteJavaScript(const ACode: String); override;
    procedure WriteJavaScriptWithScope(const ACode: String); override;
    procedure WriteNull; override;
    procedure WriteUndefined; override;
    procedure WriteMaxKey; override;
    procedure WriteMinKey; override;
    procedure WriteSymbol(const AValue: String); override;
    procedure WriteStartArray; override;
    procedure WriteEndArray; override;
    procedure WriteStartDocument; override;
    procedure WriteEndDocument; override;
    procedure WriteBinaryData(const AValue: TgoBsonBinaryData); override;
    procedure WriteRegularExpression(const AValue: TgoBsonRegularExpression); override;
  protected
    { IgoBsonDocumentWriter }
    function GetDocument: TgoBsonDocument;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a BSON Document writer.

      Parameters:
        ADocument: the BSON Document to write to. }
    constructor Create(const ADocument: TgoBsonDocument);
  end;

type
  { Abstract base class of TgoBsonReader and TgoJsonReader.
    Implements the IgoBsonBaseReader interface. }
  TgoBsonBaseReader = class abstract(TInterfacedObject, IgoBsonBaseReader)
  {$REGION 'Internal Declarations'}
  private type
    TBookmark = class abstract(TInterfacedObject, IgoBsonReaderBookmark)
    private
      FState: TgoBsonReaderState;
      FCurrentBsonType: TgoBsonType;
      FCurrentName: String;
    protected
      { IgoBsonReaderBookmark }
      function GetState: TgoBsonReaderState;
      function GetCurrentBsonType: TgoBsonType;
      function GetCurrentName: String;
    public
      constructor Create(const AState: TgoBsonReaderState;
        const ACurrentBsonType: TgoBsonType; const ACurrentName: String);

      property State: TgoBsonReaderState read FState;
      property CurrentBsonType: TgoBsonType read FCurrentBsonType;
      property CurrentName: String read FCurrentName;
    end;
  private
    FState: TgoBsonReaderState;
    FCurrentBsonType: TgoBsonType;
    FCurrentName: String;
  private
    function DoReadJavaScriptWithScope: TgoBsonValue;
  protected
    { IgoBsonBaseReader }
    function GetState: TgoBsonReaderState;
    function GetCurrentBsonType: TgoBsonType;
    function ReadDocument: TgoBsonDocument;
    function ReadArray: TgoBsonArray;
    function ReadValue: TgoBsonValue;
    function GetBookmark: IgoBsonReaderBookmark; virtual; abstract;
    procedure ReturnToBookmark(const ABookmark: IgoBsonReaderBookmark); virtual; abstract;
    function EndOfStream: Boolean; virtual; abstract;
    function ReadBsonType: TgoBsonType; virtual; abstract;
    function ReadName: String; virtual; abstract;
    procedure SkipName; virtual; abstract;
    procedure SkipValue; virtual; abstract;
    function ReadBoolean: Boolean; virtual; abstract;
    function ReadInt32: Integer; virtual; abstract;
    function ReadInt64: Int64; virtual; abstract;
    function ReadDouble: Double; virtual; abstract;
    function ReadString: String; virtual; abstract;
    function ReadDateTime: Int64; virtual; abstract;
    function ReadTimestamp: Int64; virtual; abstract;
    function ReadObjectId: TgoObjectId; virtual; abstract;
    function ReadBytes: TBytes; virtual; abstract;
    function ReadJavaScript: String; virtual; abstract;
    function ReadJavaScriptWithScope: String; virtual; abstract;
    procedure ReadNull; virtual; abstract;
    procedure ReadUndefined; virtual; abstract;
    procedure ReadMaxKey; virtual; abstract;
    procedure ReadMinKey; virtual; abstract;
    function ReadSymbol: String; virtual; abstract;
    procedure ReadStartArray; virtual; abstract;
    procedure ReadEndArray; virtual; abstract;
    procedure ReadStartDocument; virtual; abstract;
    procedure ReadEndDocument; virtual; abstract;
    function ReadBinaryData: TgoBsonBinaryData; virtual; abstract;
    function ReadRegularExpression: TgoBsonRegularExpression; virtual; abstract;
  protected
    procedure EnsureBsonTypeEquals(const ABsonType: TgoBsonType);
    procedure VerifyBsonType(const ARequiredBsonType: TgoBsonType);

    property State: TgoBsonReaderState read FState write FState;
    property CurrentBsonType: TgoBsonType read FCurrentBsonType write FCurrentBsonType;
    property CurrentName: String read FCurrentName write FCurrentName;
  {$ENDREGION 'Internal Declarations'}
  end;

type
  { Stock implementation of the IgoBsonReader interface. }
  TgoBsonReader = class(TgoBsonBaseReader, IgoBsonReader)
  {$REGION 'Internal Declarations'}
  private type
    TInput = record
    private const
      TEMP_BYTES_LENGTH = 128;
    private class var
      FValidBsonTypes: array [0..255] of Boolean;
    private
      FBuffer: TBytes;
      FSize: Integer;
      FPosition: Integer;
      FTempBytes: TBytes;
    public
      class constructor Create;
    public
      procedure Initialize(const ABuffer: TBytes); inline;
      procedure Skip(const ANumBytes: Integer);

      procedure Read(out AData; const ASize: Integer);
      function ReadBsonType: TgoBsonType; inline;
      function ReadBinarySubType: TgoBsonBinarySubType; inline;
      function ReadByte: Byte; inline;
      function ReadBytes(const ASize: Integer): TBytes;
      function ReadBoolean: Boolean; inline;
      function ReadInt32: Int32; inline;
      function ReadInt64: Int64; inline;
      function ReadDouble: Double; inline;
      function ReadCString: String;
      procedure SkipCString;
      function ReadString: String;
      function ReadObjectId: TgoObjectId;

      property Size: Integer read FSize;
      property Position: Integer read FPosition write FPosition;
    end;
  private type
    PContext = ^TContext;
    TContext = record
    private
      FStartPosition: Integer;
      FSize: Integer;
      FCurrentArrayIndex: Integer;
      FCurrentElementName: String;
      FContextType: TgoBsonContextType;
    public
      procedure Initialize(const AContextType: TgoBsonContextType;
        const AStartPosition, ASize: Integer); inline;

      property ContextType: TgoBsonContextType read FContextType;
      property CurrentArrayIndex: Integer read FCurrentArrayIndex write FCurrentArrayIndex;
      property CurrentElementName: String read FCurrentElementName write FCurrentElementName;
    end;
  private type
    TBsonBookmark = class(TBookmark)
    private
      FContextIndex: Integer;
      FPosition: Integer;
    public
      constructor Create(const AState: TgoBsonReaderState;
        const ACurrentBsonType: TgoBsonType; const ACurrentName: String;
        const AContextIndex, APosition: Integer);

      property ContextIndex: Integer read FContextIndex;
      property Position: Integer read FPosition;
    end;
  private
    FInput: TInput;
    FContextStack: TArray<TContext>;
    FContextIndex: Integer;
    FContext: PContext;
  private
    function GetNextState: TgoBsonReaderState;
    procedure PushContext(const AContextType: TgoBsonContextType;
      const AStartPosition, ASize: Integer);
    procedure PopContext(const APosition: Integer);
    function ReadSize: Integer;
  protected
    { IgoBsonBaseReader }
    function GetBookmark: IgoBsonReaderBookmark; override;
    procedure ReturnToBookmark(const ABookmark: IgoBsonReaderBookmark); override;
    function EndOfStream: Boolean; override;
    function ReadBsonType: TgoBsonType; override;
    function ReadName: String; override;
    procedure SkipName; override;
    procedure SkipValue; override;
    function ReadBoolean: Boolean; override;
    function ReadInt32: Integer; override;
    function ReadInt64: Int64; override;
    function ReadDouble: Double; override;
    function ReadString: String; override;
    function ReadDateTime: Int64; override;
    function ReadTimestamp: Int64; override;
    function ReadObjectId: TgoObjectId; override;
    function ReadBytes: TBytes; override;
    function ReadJavaScript: String; override;
    function ReadJavaScriptWithScope: String; override;
    procedure ReadNull; override;
    procedure ReadUndefined; override;
    procedure ReadMaxKey; override;
    procedure ReadMinKey; override;
    function ReadSymbol: String; override;
    procedure ReadStartArray; override;
    procedure ReadEndArray; override;
    procedure ReadStartDocument; override;
    procedure ReadEndDocument; override;
    function ReadBinaryData: TgoBsonBinaryData; override;
    function ReadRegularExpression: TgoBsonRegularExpression; override;
  protected
    { IgoBsonReader }
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a BSON binary reader.

      Parameters:
        ABson: the binary BSON data to read from. }
    constructor Create(const ABson: TBytes);

    { Creates a BSON binary reader from a file.

      Parameters:
        AFilename: the name of the file containing the BSON data. }
    class function Load(const AFilename: String): IgoBsonReader; overload; static;

    { Creates a BSON binary reader from a stream.

      Parameters:
        AStream: the stream containing the BSON data. }
    class function Load(const AStream: TStream): IgoBsonReader; overload; static;
  end;

type
  { Stock implementation of the IgoJsonReader interface. }
  TgoJsonReader = class(TgoBsonBaseReader, IgoJsonReader)
  {$REGION 'Internal Declarations'}
  private type
    PContext = ^TContext;
    TContext = record
    private
      FContextType: TgoBsonContextType;
    public
      procedure Initialize(const AContextType: TgoBsonContextType); inline;

      property ContextType: TgoBsonContextType read FContextType;
    end;
  private type
    TBuffer = record
    private
      FJson: String;
      FBuffer: PChar;
      FCurrent: PChar;
      FErrorPos: PChar;
      FLineNumber: Integer;
      FLineStart: PChar;
      FPrevLineStart: PChar;
      FEof: Boolean;
    public
      class function Create(const AJson: String): TBuffer; static;
      function Read: Char; inline;
      procedure Unread(const AChar: Char);
      procedure MarkErrorPos; inline;
      procedure ClearErrorPos; inline;

      function ParseError(const AMsg: PResStringRec): EgoJsonParserError; overload;
      function ParseError(const AMsg: String): EgoJsonParserError; overload;
      function ParseError(const AMsg: PResStringRec; const AArgs: array of const): EgoJsonParserError; overload;
      function ParseError(const AMsg: String; const AArgs: array of const): EgoJsonParserError; overload;

      property Current: PChar read FCurrent write FCurrent;
    end;
  private type
    TTokenType = (Invalid, BeginArray, BeginObject, EndArray, LeftParen,
      RightParen, EndObject, Colon, Comma, DateTime, Double, Int32, Int64,
      ObjectId, RegularExpression, &String, UnquotedString, EndOfFile);
  private type
    TToken = record
    {$REGION 'Internal Declarations'}
    private type
      TTokenValue = record
      case Byte of
        0: (Int32Value: Int32);
        1: (Int64Value: Int64);
        2: (DoubleValue: Double);
      end;
    private
      FTokenType: TTokenType;
      FLexeme: String;
      FStringValue: String;
      FRegExValue: TgoBsonRegularExpression;
      FValue: TTokenValue;
    {$ENDREGION 'Internal Declarations'}
    public
      procedure Initialize(const ATokenType: TTokenType;
        const ALexeme: String); overload; inline;
      procedure Initialize(const ATokenType: TTokenType;
        const ALexeme, AStringValue: String); overload; inline;
      procedure Initialize(const ALexeme: String;
        const AInt32Value: Int32); overload; inline;
      procedure Initialize(const ALexeme: String;
        const AInt64Value: Int64); overload; inline;
      procedure Initialize(const ALexeme: String;
        const ADoubleValue: Double); overload; inline;
      procedure Initialize(const ALexeme: String;
        const ARegExValue: TgoBsonRegularExpression); overload; inline;

      property TokenType: TTokenType read FTokenType;
      property Lexeme: String read FLexeme;
      property StringValue: String read FStringValue;
      property Int32Value: Int32 read FValue.Int32Value;
      property Int64Value: Int64 read FValue.Int64Value;
      property DoubleValue: Double read FValue.DoubleValue;
      property RegExValue: TgoBsonRegularExpression read FRegExValue;
    end;
  private type
    TScanner = record
    private type
      TNumberState = (SawLeadingMinus, SawLeadingZero, SawIntegerDigits,
        SawDecimalPoint, SawFractionDigits, SawExponentLetter, SawExponentSign,
        SawExponentDigits, SawMinusI, Done, Invalid);
    private type
      TRegularExpressionState = (InPattern, InEscapeSequence, InOptions,
        Done, Invalid);
    private
      class function IsWhitespace(const AChar: Char): Boolean; inline; static;
      class procedure GetStringToken(const ABuffer: TBuffer;
        const AQuoteCharacter: Char; out AToken: TToken); static;
      class procedure GetUnquotedStringToken(
        const ABuffer: TBuffer; out AToken: TToken); static;
      class procedure GetNumberToken(const ABuffer: TBuffer;
        const AFirstChar: Char; out AToken: TToken); static;
      class procedure GetRegularExpressionToken(
        const ABuffer: TBuffer; out AToken: TToken); static;
    public
      class procedure GetNextToken(const ABuffer: TBuffer; out AToken: TToken); static;
    end;
  private type
    TJsonBookmark = class(TBookmark)
    private
      FContextIndex: Integer;
      FCurrentToken: TToken;
      FCurrentValue: TgoBsonValue;
      FPushedToken: TToken;
      FCurrent: PChar;
      FHasPushedToken: Boolean;
    public
      constructor Create(const AState: TgoBsonReaderState;
        const ACurrentBsonType: TgoBsonType; const ACurrentName: String;
        const AContextIndex: Integer; const ACurrentToken: TToken;
        const ACurrentValue: TgoBsonValue; const APushedToken: TToken;
        const AHasPushedToken: Boolean; const ACurrent: PChar);

      property ContextIndex: Integer read FContextIndex;
      property CurrentToken: TToken read FCurrentToken;
      property CurrentValue: TgoBsonValue read FCurrentValue;
      property PushedToken: TToken read FPushedToken;
      property HasPushedToken: Boolean read FHasPushedToken write FHasPushedToken;
      property Current: PChar read FCurrent;
    end;
  private
    FBuffer: TBuffer;
    FCurrentToken: TToken;
    FCurrentValue: TgoBsonValue;
    FPushedToken: TToken;
    FHasPushedToken: Boolean;
    FContextStack: TArray<TContext>;
    FContextIndex: Integer;
    FContext: PContext;
  private
    function GetNextState: TgoBsonReaderState;
    procedure PushContext(const AContextType: TgoBsonContextType);
    procedure PopContext;
    procedure PushToken(const AToken: TToken);
    procedure PopToken(out AToken: TToken);
    function ParseExtendedJson: TgoBsonType;
    function ParseExtendedJsonBinaryData: TgoBsonValue;
    function ParseExtendedJsonDateTime: TgoBsonValue;
    function ParseExtendedJsonNumberLong: TgoBsonValue;
    function ParseExtendedJsonJavaScript(out AValue: TgoBsonValue): TgoBsonType;
    function ParseExtendedJsonMaxKey: TgoBsonValue;
    function ParseExtendedJsonMinKey: TgoBsonValue;
    function ParseExtendedJsonUndefined: TgoBsonValue;
    function ParseExtendedJsonObjectId: TgoBsonValue;
    function ParseExtendedJsonRegularExpression: TgoBsonValue;
    function ParseExtendedJsonSymbol: TgoBsonValue;
    function ParseExtendedJsonTimestamp: TgoBsonValue;
    function ParseExtendedJsonTimestampNew: TgoBsonValue;
    function ParseExtendedJsonTimestampOld(const AValueToken: TToken): TgoBsonValue;
    function ParseConstructorBinaryData: TgoBsonValue;
    function ParseConstructorDateTime(const AWithNew: Boolean): TgoBsonValue;
    function ParseConstructorHexData: TgoBsonValue;
    function ParseConstructorISODateTime: TgoBsonValue;
    function ParseConstructorNumber: TgoBsonValue;
    function ParseConstructorNumberLong: TgoBsonValue;
    function ParseConstructorObjectId: TgoBsonValue;
    function ParseConstructorRegularExpression: TgoBsonValue;
    function ParseConstructorTimestamp: TgoBsonValue;
    function ParseConstructorUUID(const AConstructorName: String): TgoBsonValue;
    function ParseNew(out AValue: TgoBsonValue): TgoBsonType;
    procedure VerifyToken(const AExpectedLexeme: String);
    procedure VerifyString(const AExpectedString: String);
    class function FormatJavaScriptDateTimeString(const ALocalDateTime: TDateTime): String; static;
  protected
    { IgoBsonBaseReader }
    function GetBookmark: IgoBsonReaderBookmark; override;
    procedure ReturnToBookmark(const ABookmark: IgoBsonReaderBookmark); override;
    function EndOfStream: Boolean; override;
    function ReadBsonType: TgoBsonType; override;
    function ReadName: String; override;
    procedure SkipName; override;
    procedure SkipValue; override;
    function ReadBoolean: Boolean; override;
    function ReadInt32: Integer; override;
    function ReadInt64: Int64; override;
    function ReadDouble: Double; override;
    function ReadString: String; override;
    function ReadDateTime: Int64; override;
    function ReadTimestamp: Int64; override;
    function ReadObjectId: TgoObjectId; override;
    function ReadBytes: TBytes; override;
    function ReadJavaScript: String; override;
    function ReadJavaScriptWithScope: String; override;
    procedure ReadNull; override;
    procedure ReadUndefined; override;
    procedure ReadMaxKey; override;
    procedure ReadMinKey; override;
    function ReadSymbol: String; override;
    procedure ReadStartArray; override;
    procedure ReadEndArray; override;
    procedure ReadStartDocument; override;
    procedure ReadEndDocument; override;
    function ReadBinaryData: TgoBsonBinaryData; override;
    function ReadRegularExpression: TgoBsonRegularExpression; override;
  protected
    { IgoBsonReader }
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a JSON reader.

      Parameters:
        AJson: the JSON string to parse. }
    constructor Create(const AJson: String);

    { Creates a JSON reader from a file.

      Parameters:
        AFilename: the name of the file containing the JSON data. }
    class function Load(const AFilename: String): IgoJsonReader; overload; static;

    { Creates a JSON reader from a stream.

      Parameters:
        AStream: the stream containing the JSON data. }
    class function Load(const AStream: TStream): IgoJsonReader; overload; static;
  end;

type
  { Stock implementation of the IgoBsonDocumentReader interface. }
  TgoBsonDocumentReader = class(TgoBsonBaseReader, IgoBsonDocumentReader)
  {$REGION 'Internal Declarations'}
  private type
    PContext = ^TContext;
    TContext = record
    private
      FContextType: TgoBsonContextType;
      FDocument: TgoBsonDocument;
      FArray: TgoBsonArray;
      FIndex: Integer;
    public
      procedure Initialize(const AContextType: TgoBsonContextType;
        const ADocument: TgoBsonDocument); overload; inline;
      procedure Initialize(const AContextType: TgoBsonContextType;
        const AArray: TgoBsonArray); overload; inline;

      function TryGetNextElement(out AElement: TgoBsonElement): Boolean;
      function TryGetNextValue(out AValue: TgoBsonValue): Boolean;

      property ContextType: TgoBsonContextType read FContextType;
      property Document: TgoBsonDocument read FDocument;
      property Index: Integer read FIndex write FIndex;
    end;
  private type
    TDocumentBookmark = class(TBookmark)
    private
      FContextIndex: Integer;
      FContextIndexIndex: Integer;
      FCurrentValue: TgoBsonValue;
    public
      constructor Create(const AState: TgoBsonReaderState;
        const ACurrentBsonType: TgoBsonType; const ACurrentName: String;
        const AContextIndex, AContextIndexIndex: Integer; const ACurrentValue: TgoBsonValue);

      property ContextIndex: Integer read FContextIndex;
      property ContextIndexIndex: Integer read FContextIndexIndex;
      property CurrentValue: TgoBsonValue read FCurrentValue;
    end;
  private
    FCurrentValue: TgoBsonValue;
    FContextStack: TArray<TContext>;
    FContextIndex: Integer;
    FContext: PContext;
  private
    function GetNextState: TgoBsonReaderState;
    procedure PushContext(const AContextType: TgoBsonContextType;
      const ADocument: TgoBsonDocument); overload;
    procedure PushContext(const AContextType: TgoBsonContextType;
      const AArray: TgoBsonArray); overload;
    procedure PopContext;
  protected
    { IgoBsonBaseReader }
    function GetBookmark: IgoBsonReaderBookmark; override;
    procedure ReturnToBookmark(const ABookmark: IgoBsonReaderBookmark); override;
    function EndOfStream: Boolean; override;
    function ReadBsonType: TgoBsonType; override;
    function ReadName: String; override;
    procedure SkipName; override;
    procedure SkipValue; override;
    function ReadBoolean: Boolean; override;
    function ReadInt32: Integer; override;
    function ReadInt64: Int64; override;
    function ReadDouble: Double; override;
    function ReadString: String; override;
    function ReadDateTime: Int64; override;
    function ReadTimestamp: Int64; override;
    function ReadObjectId: TgoObjectId; override;
    function ReadBytes: TBytes; override;
    function ReadJavaScript: String; override;
    function ReadJavaScriptWithScope: String; override;
    procedure ReadNull; override;
    procedure ReadUndefined; override;
    procedure ReadMaxKey; override;
    procedure ReadMinKey; override;
    function ReadSymbol: String; override;
    procedure ReadStartArray; override;
    procedure ReadEndArray; override;
    procedure ReadStartDocument; override;
    procedure ReadEndDocument; override;
    function ReadBinaryData: TgoBsonBinaryData; override;
    function ReadRegularExpression: TgoBsonRegularExpression; override;
  protected
    { IgoBsonDocumentReader }
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a BSON Document reader.

      Parameters:
        ADocument: the BSON Document to read from. }
    constructor Create(const ADocument: TgoBsonDocument);
  end;

resourcestring
  RS_BSON_NOT_SUPPORTED = 'Unsupported feature';
  RS_BSON_INVALID_WRITER_STATE = 'Cannot write Bson/Json element in current state';
  RS_BSON_INVALID_READER_STATE = 'Cannot read Bson/Json element in current state';
  RS_BSON_INVALID_DATA = 'Bson/Json data is invalid';
  RS_BSON_INT_EXPECTED = 'Integer value expected';
  RS_BSON_UNEXPECTED_TOKEN = 'Unexpected token';
  RS_BSON_TOKEN_EXPECTED = 'Expected token with value "%s" but got "%s"';
  RS_BSON_STRING_EXPECTED = 'String value expected';
  RS_BSON_STRING_WITH_VALUE_EXPECTED = 'Expected string with value "%s" but got "%s"';
  RS_BSON_INT_OR_STRING_EXPECTED = 'Integer or string value expected';
  RS_BSON_COLON_EXPECTED = 'Colon (":") expected';
  RS_BSON_COMMA_EXPECTED = 'Comma (",") expected';
  RS_BSON_QUOTE_EXPECTED = 'Double quotes (") expected';
  RS_BSON_CLOSE_BRACKET_EXPECTED = 'Close bracket ("]") expected';
  RS_BSON_CLOSE_BRACE_EXPECTED = 'Curly close brace ("}") expected';
  RS_BSON_COMMA_OR_CLOSE_BRACE_EXPECTED = 'Comma (",") or curly close brace ("}") expected';
  RS_BSON_STRING_OR_CLOSE_BRACE_EXPECTED = 'String or curly close brace ("}") expected';
  RS_BSON_INVALID_NUMBER = 'Invalid number';
  RS_BSON_INVALID_STRING = 'Invalid character string';
  RS_BSON_INVALID_DATE = 'Invalid date value';
  RS_BSON_INVALID_GUID = 'Invalid GUID value';
  RS_BSON_INVALID_NEW_STATEMENT = 'Invalid "new" statement';
  RS_BSON_INVALID_EXTENDED_JSON = 'Invalid extended JSON';
  RS_BSON_INVALID_BINARY_TYPE = 'Invalid binary type';
  RS_BSON_INVALID_REGEX = 'Invalid regular expression';
  RS_BSON_INVALID_UNICODE_CODEPOINT = 'Invalid Unicode codepoint';
  RS_BSON_JS_DATETIME_STRING_NOT_SUPPORTED = 'JavaScript date/time strings are not supported';

implementation

uses
  System.Math,
  System.Types,
  System.Character,
  System.RTLConsts,
  System.DateUtils,
  {$IF Defined(IOS)}
  Macapi.CoreFoundation,
  {$ENDIF}
  Grijjy.SysUtils,
  Grijjy.DateUtils,
  Grijjy.BinaryCoding;

{ EgoJsonParserError }

constructor EgoJsonParserError.Create(const AMsg: String;
  const ALineNumber, AColumnNumber, APosition: Integer);
begin
  inherited CreateFmt('(%d:%d) %s', [ALineNumber, AColumnNumber, AMsg]);
  FLineNumber := ALineNumber;
  FColumnNumber := AColumnNumber;
  FPosition := APosition;
end;

{ TgoBsonBaseWriter }

procedure TgoBsonBaseWriter.DoWriteJavaScriptWithScope(
  const AValue: TgoBsonJavaScriptWithScope);
begin
  WriteJavaScriptWithScope(AValue.Code);
  WriteDocument(AValue.Scope);
end;

function TgoBsonBaseWriter.GetState: TgoBsonWriterState;
begin
  Result := FState;
end;

procedure TgoBsonBaseWriter.WriteArray(const AArray: TgoBsonArray);
var
  I: Integer;
begin
  WriteStartArray;

  for I := 0 to AArray.Count - 1 do
    WriteValue(AArray[I]);

  WriteEndArray;
end;

procedure TgoBsonBaseWriter.WriteBoolean(const AName: String;
  const AValue: Boolean);
begin
  WriteName(AName);
  WriteBoolean(AValue);
end;

procedure TgoBsonBaseWriter.WriteBytes(const AValue: TBytes);
begin
  WriteBinaryData(TgoBsonBinaryData.Create(AValue));
end;

procedure TgoBsonBaseWriter.WriteBytes(const AName: String;
  const AValue: TBytes);
begin
  WriteName(AName);
  WriteBytes(AValue);
end;

procedure TgoBsonBaseWriter.WriteDateTime(const AName: String;
  const AMillisecondsSinceEpoch: Int64);
begin
  WriteName(AName);
  WriteDateTime(AMillisecondsSinceEpoch);
end;

procedure TgoBsonBaseWriter.WriteDocument(const ADocument: TgoBsonDocument);
var
  I: Integer;
  Element: TgoBsonElement;
begin
  WriteStartDocument;

  for I := 0 to ADocument.Count - 1 do
  begin
    Element := ADocument.Elements[I];
    WriteName(Element.Name);
    WriteValue(Element.Value);
  end;

  WriteEndDocument;
end;

procedure TgoBsonBaseWriter.WriteDouble(const AName: String;
  const AValue: Double);
begin
  WriteName(AName);
  WriteDouble(AValue);
end;

procedure TgoBsonBaseWriter.WriteInt32(const AName: String;
  const AValue: Int32);
begin
  WriteName(AName);
  WriteInt32(AValue);
end;

procedure TgoBsonBaseWriter.WriteInt64(const AName: String;
  const AValue: Int64);
begin
  WriteName(AName);
  WriteInt64(AValue);
end;

procedure TgoBsonBaseWriter.WriteJavaScript(const AName, ACode: String);
begin
  WriteName(AName);
  WriteJavaScript(ACode);
end;

procedure TgoBsonBaseWriter.WriteJavaScriptWithScope(const AName,
  ACode: String);
begin
  WriteName(AName);
  WriteJavaScriptWithScope(ACode);
end;

procedure TgoBsonBaseWriter.WriteMaxKey(const AName: String);
begin
  WriteName(AName);
  WriteMaxKey;
end;

procedure TgoBsonBaseWriter.WriteMinKey(const AName: String);
begin
  WriteName(AName);
  WriteMinKey;
end;

procedure TgoBsonBaseWriter.WriteName(const AName: String);
begin
  if (State <> TgoBsonWriterState.Name) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FName := AName;
  FState := TgoBsonWriterState.Value;
end;

procedure TgoBsonBaseWriter.WriteNull(const AName: String);
begin
  WriteName(AName);
  WriteNull;
end;

procedure TgoBsonBaseWriter.WriteObjectId(const AName: String;
  const AValue: TgoObjectId);
begin
  WriteName(AName);
  WriteObjectId(AValue);
end;

procedure TgoBsonBaseWriter.WriteRegularExpression(const AName: String;
  const AValue: TgoBsonRegularExpression);
begin
  WriteName(AName);
  WriteRegularExpression(AValue);
end;

procedure TgoBsonBaseWriter.WriteStartArray(const AName: String);
begin
  WriteName(AName);
  WriteStartArray;
end;

procedure TgoBsonBaseWriter.WriteStartDocument(const AName: String);
begin
  WriteName(AName);
  WriteStartDocument;
end;

procedure TgoBsonBaseWriter.WriteString(const AName, AValue: String);
begin
  WriteName(AName);
  WriteString(AValue);
end;

procedure TgoBsonBaseWriter.WriteSymbol(const AName, AValue: String);
begin
  WriteName(AName);
  WriteSymbol(AValue);
end;

procedure TgoBsonBaseWriter.WriteTimestamp(const AName: String;
  const AValue: Int64);
begin
  WriteName(AName);
  WriteTimestamp(AValue);
end;

procedure TgoBsonBaseWriter.WriteUndefined(const AName: String);
begin
  WriteName(AName);
  WriteUndefined;
end;

procedure TgoBsonBaseWriter.WriteValue(const AValue: TgoBsonValue);
begin
  if (AValue.IsNil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);

  case AValue.BsonType of
    TgoBsonType.EndOfDocument      : ;
    TgoBsonType.Double             : WriteDouble(AValue.AsDouble);
    TgoBsonType.&String            : WriteString(AValue.AsString);
    TgoBsonType.Document           : WriteDocument(AValue.AsBsonDocument);
    TgoBsonType.&Array             : WriteArray(AValue.AsBsonArray);
    TgoBsonType.Binary             : WriteBinaryData(AValue.AsBsonBinaryData);
    TgoBsonType.Undefined          : WriteUndefined;
    TgoBsonType.ObjectId           : WriteObjectId(AValue.AsObjectId);
    TgoBsonType.Boolean            : WriteBoolean(AValue.AsBoolean);
    TgoBsonType.DateTime           : WriteDateTime(AValue.AsBsonDateTime.MillisecondsSinceEpoch);
    TgoBsonType.Null               : WriteNull;
    TgoBsonType.RegularExpression  : WriteRegularExpression(AValue.AsBsonRegularExpression);
    TgoBsonType.JavaScript         : WriteJavaScript(AValue.AsBsonJavaScript.Code);
    TgoBsonType.Symbol             : WriteSymbol(AValue.AsBsonSymbol.Name);
    TgoBsonType.JavaScriptWithScope: DoWriteJavaScriptWithScope(AValue.AsBsonJavaScriptWithScope);
    TgoBsonType.Int32              : WriteInt32(AValue.AsInteger);
    TgoBsonType.Timestamp          : WriteTimestamp(AValue.AsBsonTimestamp.Value);
    TgoBsonType.Int64              : WriteInt64(AValue.AsInt64);
    TgoBsonType.MaxKey             : WriteMaxKey;
    TgoBsonType.MinKey             : WriteMinKey;
  else
    Assert(False);
  end;
end;

{ TgoBsonWriter }

procedure TgoBsonWriter.BackpatchSize;
var
  Size: Integer;
begin
  Assert(Assigned(FContext));
  Size := FOutput.Position - FContext.StartPosition;
  FOutput.WriteInt32At(FContext.StartPosition, Size);
end;

constructor TgoBsonWriter.Create;
begin
  inherited Create;
  FOutput.Initialize;
  FContextIndex := -1;
end;

function TgoBsonWriter.GetNextState: TgoBsonWriterState;
begin
  Assert(Assigned(FContext));
  if (FContext.ContextType = TgoBsonContextType.&Array) then
    Result := TgoBsonWriterState.Value
  else
    Result := TgoBsonWriterState.Name;
end;

procedure TgoBsonWriter.PopContext;
begin
  Dec(FContextIndex);
  if (FContextIndex < 0) then
  begin
    FContext := nil;
    FContextIndex := -1;
  end
  else
    FContext := @FContextStack[FContextIndex];
end;

procedure TgoBsonWriter.PushContext(const AContextType: TgoBsonContextType;
  const AStartPosition: Integer);
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);
  FContextStack[FContextIndex].Initialize(AContextType, AStartPosition);
  FContext := @FContextStack[FContextIndex];
end;

function TgoBsonWriter.ToBson: TBytes;
begin
  Result := FOutput.ToBytes;
end;

procedure TgoBsonWriter.WriteBinaryData(const AValue: TgoBsonBinaryData);
var
  Bytes: TBytes;
  SubType: TgoBsonBinarySubType;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  Bytes := AValue.AsBytes;
  SubType := AValue.SubType;
  if (SubType = TgoBsonBinarySubType.OldBinary) then
    SubType := TgoBsonBinarySubType.Binary;

  FOutput.WriteBsonType(TgoBsonType.Binary);
  WriteNameHelper;

  FOutput.WriteInt32(Length(Bytes));
  FOutput.WriteBinarySubType(SubType);
  FOutput.Write(Bytes[0], Length(Bytes));
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteBoolean(const AValue: Boolean);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.Boolean);
  WriteNameHelper;
  FOutput.WriteBoolean(AValue);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteDateTime(const AMillisecondsSinceEpoch: Int64);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.DateTime);
  WriteNameHelper;
  FOutput.WriteInt64(AMillisecondsSinceEpoch);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteDouble(const AValue: Double);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.Double);
  WriteNameHelper;
  FOutput.WriteDouble(AValue);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteEndArray;
begin
  Assert(Assigned(FContext));
  if (State <> TgoBsonWriterState.Value) or (FContext.ContextType <> TgoBsonContextType.&Array) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteByte(0);
  BackpatchSize;

  PopContext;
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteEndDocument;
begin
  Assert(Assigned(FContext));
  if (State <> TgoBsonWriterState.Name) or
    (not (FContext.ContextType in [TgoBsonContextType.Document, TgoBsonContextType.ScopeDocument]))
  then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteByte(0);
  BackpatchSize;

  PopContext;
  if (FContext = nil) then
    State := TgoBsonWriterState.Done
  else
  begin
    if (FContext.ContextType = TgoBsonContextType.JavaScriptWithScope) then
    begin
      BackpatchSize;
      PopContext;
    end;
    State := GetNextState;
  end;
end;

procedure TgoBsonWriter.WriteInt32(const AValue: Integer);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.Int32);
  WriteNameHelper;
  FOutput.WriteInt32(AValue);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteInt64(const AValue: Int64);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.Int64);
  WriteNameHelper;
  FOutput.WriteInt64(AValue);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteJavaScript(const ACode: String);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.JavaScript);
  WriteNameHelper;
  FOutput.WriteString(ACode);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteJavaScriptWithScope(const ACode: String);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.JavaScriptWithScope);
  WriteNameHelper;
  PushContext(TgoBsonContextType.JavaScriptWithScope, FOutput.Position);
  FOutput.WriteInt32(0);  // Reserve space
  FOutput.WriteString(ACode);
  State := TgoBsonWriterState.ScopeDocument;
end;

procedure TgoBsonWriter.WriteMaxKey;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.MaxKey);
  WriteNameHelper;
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteMinKey;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.MinKey);
  WriteNameHelper;
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteNameHelper;
var
  Index: Integer;
begin
  Assert(Assigned(FContext));
  if (FContext.ContextType = TgoBsonContextType.&Array) then
  begin
    Index := FContext.Index;
    FContext.Index := Index + 1;
    FOutput.WriteCString(TArrayElementNameAccelerator.GetElementNameBytes(Index));
  end
  else
    FOutput.WriteCString(Name);
end;

procedure TgoBsonWriter.WriteNull;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.Null);
  WriteNameHelper;
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteObjectId(const AValue: TgoObjectId);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.ObjectId);
  WriteNameHelper;
  FOutput.WriteObjectId(AValue);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteRawBsonDocument(const ADocument: TBytes);
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value,
    TgoBsonWriterState.ScopeDocument, TgoBsonWriterState.Done]))
  then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  if (State = TgoBsonWriterState.Value) then
  begin
    FOutput.WriteBsonType(TgoBsonType.Document);
    WriteNameHelper;
  end;

  FOutput.Write(ADocument[0], Length(ADocument));

  if (FContext = nil) then
    State := TgoBsonWriterState.Done
  else
  begin
    if (FContext.ContextType = TgoBsonContextType.JavaScriptWithScope) then
    begin
      BackpatchSize;
      PopContext;
    end;
    State := GetNextState;
  end;
end;

procedure TgoBsonWriter.WriteRegularExpression(
  const AValue: TgoBsonRegularExpression);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.RegularExpression);
  WriteNameHelper;

  FOutput.WriteCString(AValue.Pattern);
  FOutput.WriteCString(AValue.Options);

  State := GetNextState;
end;

procedure TgoBsonWriter.WriteStartArray;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.&Array);
  WriteNameHelper;

  PushContext(TgoBsonContextType.&Array, FOutput.Position);
  FOutput.WriteInt32(0); // Reserve space for size
  State := TgoBsonWriterState.Value;
end;

procedure TgoBsonWriter.WriteStartDocument;
var
  ContextType: TgoBsonContextType;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value,
    TgoBsonWriterState.ScopeDocument, TgoBsonWriterState.Done]))
  then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  if (State = TgoBsonWriterState.Value) then
  begin
    FOutput.WriteBsonType(TgoBsonType.Document);
    WriteNameHelper;
  end;

  if (State = TgoBsonWriterState.ScopeDocument) then
    ContextType := TgoBsonContextType.ScopeDocument
  else
    ContextType := TgoBsonContextType.Document;

  PushContext(ContextType, FOutput.Position);
  FOutput.WriteInt32(0); // Reserve space for size

  State := TgoBsonWriterState.Name;
end;

procedure TgoBsonWriter.WriteString(const AValue: String);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.String);
  WriteNameHelper;
  FOutput.WriteString(AValue);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteSymbol(const AValue: String);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.Symbol);
  WriteNameHelper;
  FOutput.WriteString(AValue);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteTimestamp(const AValue: Int64);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.Timestamp);
  WriteNameHelper;
  FOutput.WriteInt64(AValue);
  State := GetNextState;
end;

procedure TgoBsonWriter.WriteUndefined;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.WriteBsonType(TgoBsonType.Undefined);
  WriteNameHelper;
  State := GetNextState;
end;

{ TgoBsonWriter.TOutput }

procedure TgoBsonWriter.TOutput.Initialize;
begin
  SetLength(FBuffer, 256);
  FCapacity := 256;
  FSize := 0;
  SetLength(FTempBytes, TEMP_BYTES_LENGTH);
end;

function TgoBsonWriter.TOutput.ToBytes: TBytes;
begin
  SetLength(FBuffer, FSize);
  Result := FBuffer;
end;

procedure TgoBsonWriter.TOutput.Write(const AValue; const ASize: Integer);
begin
  if (ASize > 0) then
  begin
    if ((FSize + ASize) > FCapacity) then
    begin
      FCapacity := FSize + ASize + 256;
      SetLength(FBuffer, FCapacity);
    end;
    Move(AValue, FBuffer[FSize], ASize);
    Inc(FSize, ASize);
  end;
end;

procedure TgoBsonWriter.TOutput.WriteBinarySubType(
  const ASubType: TgoBsonBinarySubType);
begin
  Write(ASubType, 1);
end;

procedure TgoBsonWriter.TOutput.WriteBoolean(const AValue: Boolean);
begin
  Write(AValue, 1);
end;

procedure TgoBsonWriter.TOutput.WriteBsonType(const ABsonType: TgoBsonType);
begin
  Write(ABsonType, 1);
end;

procedure TgoBsonWriter.TOutput.WriteByte(const AValue: Byte);
begin
  Write(AValue, 1);
end;

procedure TgoBsonWriter.TOutput.WriteCString(const AValue: String);
var
  CharCount, Utf8Count: Integer;
  Bytes: TBytes;
begin
  CharCount := AValue.Length;
  if (TEncoding.UTF8.GetMaxByteCount(CharCount) <= TEMP_BYTES_LENGTH) then
  begin
    Bytes := FTempBytes;
    Utf8Count := TEncoding.UTF8.GetBytes(AValue, Low(AValue), CharCount, Bytes, 0);
  end
  else
  begin
    Bytes := TEncoding.UTF8.GetBytes(AValue);
    Utf8Count := Length(Bytes);
  end;
  Write(Bytes[0], Utf8Count);
  WriteByte(0);
end;

procedure TgoBsonWriter.TOutput.WriteCString(const AValue: TBytes);
begin
  Write(AValue[0], Length(AValue));
  WriteByte(0);
end;

procedure TgoBsonWriter.TOutput.WriteDouble(const AValue: Double);
begin
  Write(AValue, 8);
end;

procedure TgoBsonWriter.TOutput.WriteInt32(const AValue: Int32);
begin
  Write(AValue, 4);
end;

procedure TgoBsonWriter.TOutput.WriteInt32At(const APosition, AValue: Int32);
begin
  Move(AValue, FBuffer[APosition], 4);
end;

procedure TgoBsonWriter.TOutput.WriteInt64(const AValue: Int64);
begin
  Write(AValue, 8);
end;

procedure TgoBsonWriter.TOutput.WriteObjectId(const AValue: TgoObjectId);
begin
  AValue.ToByteArray(FTempBytes, 0);
  Write(FTempBytes[0], 12);
end;

procedure TgoBsonWriter.TOutput.WriteString(const AValue: String);
var
  CharCount, Utf8Count: Integer;
  Bytes: TBytes;
begin
  CharCount := AValue.Length;
  if (TEncoding.UTF8.GetMaxByteCount(CharCount) <= TEMP_BYTES_LENGTH) then
  begin
    Bytes := FTempBytes;
    Utf8Count := TEncoding.UTF8.GetBytes(AValue, Low(AValue), CharCount, Bytes, 0);
  end
  else
  begin
    Bytes := TEncoding.UTF8.GetBytes(AValue);
    Utf8Count := Length(Bytes);
  end;
  WriteInt32(Utf8Count + 1);
  Write(Bytes[0], Utf8Count);
  WriteByte(0);
end;

{ TgoBsonWriter.TContext }

procedure TgoBsonWriter.TContext.Initialize(const AContextType: TgoBsonContextType;
  const AStartPosition: Integer);
begin
  FStartPosition := AStartPosition;
  FIndex := 0;
  FContextType := AContextType;
end;

{ TgoBsonWriter.TArrayElementNameAccelerator }

class constructor TgoBsonWriter.TArrayElementNameAccelerator.Create;
var
  I: Integer;
begin
  for I := 0 to Length(FCachedElementNames) - 1 do
    FCachedElementNames[I] := CreateElementNameBytes(I);
end;

class function TgoBsonWriter.TArrayElementNameAccelerator.CreateElementNameBytes(
  const AIndex: Integer): TBytes;
const
  ASCII_ZERO = 48;
var
  A, B, C, D, E, N: Integer;
begin
  N := AIndex;
  A := ASCII_ZERO + (N mod 10);
  B := ASCII_ZERO;
  C := ASCII_ZERO;
  D := ASCII_ZERO;
  E := ASCII_ZERO;
  N := N div 10;
  if (N > 0) then
  begin
    Inc(B, N mod 10);
    N := N div 10;
    if (N > 0) then
    begin
      Inc(C, N mod 10);
      N := N div 10;
      if (N > 0) then
      begin
        Inc(D, N mod 10);
        N := N div 10;
        if (N > 0) then
        begin
          Inc(E, N mod 10);
          N := N div 10;
        end;
      end;
    end;
  end;

  if (N = 0) then
  begin
    if (E <> ASCII_ZERO) then
      Exit(TBytes.Create(E, D, C, B, A));

    if (D <> ASCII_ZERO) then
      Exit(TBytes.Create(D, C, B, A));

    if (C <> ASCII_ZERO) then
      Exit(TBytes.Create(C, B, A));

    if (B <> ASCII_ZERO) then
      Exit(TBytes.Create(B, A));

    Exit(TBytes.Create(A));
  end;

  Result := BytesOf(AIndex.ToString);
end;

class function TgoBsonWriter.TArrayElementNameAccelerator.GetElementNameBytes(
  const AIndex: Integer): TBytes;
begin
  Assert(AIndex >= 0);
  if (AIndex < Length(FCachedElementNames)) then
    Result := FCachedElementNames[AIndex]
  else
    Result := CreateElementNameBytes(AIndex);
end;

{ TgoJsonWriter }

constructor TgoJsonWriter.Create;
begin
  Create(TgoJsonWriterSettings.Default);
end;

constructor TgoJsonWriter.Create(const ASettings: TgoJsonWriterSettings);
begin
  inherited Create;
  FSettings := ASettings;
  FOutput := TStringBuilder.Create;
  FContextIndex := -1;
  PushContext(TgoBsonContextType.TopLevel, '');
end;

destructor TgoJsonWriter.Destroy;
begin
  FOutput.Free;
  inherited;
end;

function TgoJsonWriter.GetNextState: TgoBsonWriterState;
begin
  Assert(Assigned(FContext));
  if (FContext.ContextType in [TgoBsonContextType.TopLevel, TgoBsonContextType.&Array]) then
    Result := TgoBsonWriterState.Value
  else
    Result := TgoBsonWriterState.Name;
end;

class function TgoJsonWriter.GuidToString(const ABytes: TBytes;
  const ASubType: TgoBsonBinarySubType): String;
var
  Guid: TGUID;
  S: String;
begin
  if (Length(ABytes) <> 16) then
    raise EArgumentOutOfRangeException.CreateRes(@SArgumentOutOfRange);

  if (ASubType = TgoBsonBinarySubType.UuidLegacy) then
  begin
    // We only support output to C# legacy
    Result := 'CSUUID("';
    Guid := TGuid.Create(ABytes, TEndian.Little);
  end
  else
  begin
    Result := 'UUID("';
    Guid := TGuid.Create(ABytes, TEndian.Big);
  end;

  S := Guid.ToString.ToLower; // Include '{' and '}'
  Result := Result + S.Substring(1, S.Length - 2) + '")';
end;

procedure TgoJsonWriter.PopContext;
begin
  Dec(FContextIndex);
  if (FContextIndex < 0) then
  begin
    FContext := nil;
    FContextIndex := -1;
  end
  else
    FContext := @FContextStack[FContextIndex];
end;

procedure TgoJsonWriter.PushContext(const AContextType: TgoBsonContextType;
  const AIndentString: String);
var
  ParentContext: PContext;
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);

  if (FContextIndex > 0) then
    ParentContext := @FContextStack[FContextIndex - 1]
  else
    ParentContext := nil;

  FContextStack[FContextIndex].Initialize(ParentContext, AContextType, AIndentString);
  FContext := @FContextStack[FContextIndex];
end;

function TgoJsonWriter.ToJson: String;
begin
  Result := FOutput.ToString;
end;

procedure TgoJsonWriter.WriteBinaryData(const AValue: TgoBsonBinaryData);
var
  SubType: TgoBsonBinarySubType;
  Bytes: TBytes;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  SubType := AValue.SubType;
  Bytes := AValue.AsBytes;
  WriteNameHelper(Name);

  if (FSettings.OutputMode = TgoJsonOutputMode.Strict) then
  begin
    FOutput.Append('{ "$binary" : "');
    FOutput.Append(TEncoding.ANSI.GetString(goBase64Encode(Bytes)));
    FOutput.AppendFormat('", "$type" : "%.2x" }', [Ord(SubType)]);
  end
  else if (SubType in [TgoBsonBinarySubType.UuidLegacy, TgoBsonBinarySubType.UuidStandard]) then
    FOutput.Append(GuidToString(Bytes, SubType))
  else
  begin
    FOutput.Append('new BinData(');
    FOutput.Append(Ord(SubType));
    FOutput.Append(', "');
    FOutput.Append(TEncoding.ANSI.GetString(goBase64Encode(Bytes)));
    FOutput.Append('")');
  end;

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteBoolean(const AValue: Boolean);
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);
  if (AValue) then
    FOutput.Append('true')
  else
    FOutput.Append('false');
  State := GetNextState;
end;

procedure TgoJsonWriter.WriteDateTime(const AMillisecondsSinceEpoch: Int64);
var
  DateTime: TDateTime;
  S: String;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);
  if (FSettings.OutputMode = TgoJsonOutputMode.Strict) then
  begin
    FOutput.Append('{ "$date" : ');
    FOutput.Append(AMillisecondsSinceEpoch);
    FOutput.Append(' }');
  end
  else
  begin
    if (AMillisecondsSinceEpoch >= MIN_MILLISECONDS_SINCE_EPOCH) and
       (AMillisecondsSinceEpoch <= MAX_MILLISECONDS_SINCE_EPOCH) then
    begin
      DateTime := goToDateTimeFromMillisecondsSinceEpoch(AMillisecondsSinceEpoch, True);
      FOutput.Append('ISODate("');
      S := DateToISO8601(DateTime, True);
      if (S.EndsWith('.000Z')) then
        { Only include milliseconds if not 0 }
        S := S.Remove(S.Length - 5, 4);
      FOutput.Append(S);
      FOutput.Append('")');
    end
    else
    begin
      FOutput.Append('new Date(');
      FOutput.Append(AMillisecondsSinceEpoch);
      FOutput.Append(')');
    end;
  end;

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteDouble(const AValue: Double);
var
  S: String;
  I: Int64;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);

  S := FloatToStr(AValue, goUSFormatSettings);
  if (S = 'NAN') then
    S := 'NaN' // JSON compliant
  else if (S = 'INF') then
    S := 'Infinity'
  else if (S = '-INF') then
    S := '-Infinity'
  else if (TryStrToInt64(S, I)) then
    { If S looks like an integer, then add ".0" }
    S := S + '.0';

  FOutput.Append(S);

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteEndArray;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  FOutput.Append(']');
  PopContext;
  State := GetNextState;
end;

procedure TgoJsonWriter.WriteEndDocument;
begin
  if (State <> TgoBsonWriterState.Name) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  Assert(Assigned(FContext));
  if (FSettings.PrettyPrint) and (FContext.HasElements) then
  begin
    FOutput.Append(FSettings.LineBreak);
    if (FContextIndex > 0) then
      FOutput.Append(FContextStack[FContextIndex - 1].Indentation);
    FOutput.Append('}');
  end
  else
    FOutput.Append(' }');

  if (FContext.ContextType = TgoBsonContextType.ScopeDocument) then
  begin
    PopContext;
    WriteEndDocument;
  end
  else
    PopContext;

  if (FContext = nil) then
    State := TgoBsonWriterState.Done
  else
    State := GetNextState;
end;

procedure TgoJsonWriter.WriteEscapedString(const AValue: String);
var
  C: Char;
begin
  for C in AValue do
  begin
    case C of
      '"', '\':
        begin
          FOutput.Append('\');
          FOutput.Append(C);
        end;

       #8: FOutput.Append('\b');
       #9: FOutput.Append('\t');
      #10: FOutput.Append('\n');
      #12: FOutput.Append('\f');
      #13: FOutput.Append('\r');
    else
      if (C < ' ') or (C >= #$0080) then
      begin
        FOutput.Append('\u');
        FOutput.Append(IntToHex(Ord(C), 4).ToLower);
      end
      else
        FOutput.Append(C);
    end;
  end;
end;

procedure TgoJsonWriter.WriteInt32(const AValue: Integer);
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);
  FOutput.Append(AValue);
  State := GetNextState;
end;

procedure TgoJsonWriter.WriteInt64(const AValue: Int64);
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);

  if (FSettings.OutputMode = TgoJsonOutputMode.Strict) then
    FOutput.Append(AValue)
  else
  begin
    if (AValue >= Integer.MinValue) and (AValue <= Integer.MaxValue) then
    begin
      FOutput.Append('NumberLong(');
      FOutput.Append(AValue);
      FOutput.Append(')');
    end
    else
    begin
      FOutput.Append('NumberLong("');
      FOutput.Append(AValue);
      FOutput.Append('")');
    end;
  end;

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteJavaScript(const ACode: String);
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);
  FOutput.Append('{ "$code" : "');
  WriteEscapedString(ACode);
  FOutput.Append('" }');
  State := GetNextState;
end;

procedure TgoJsonWriter.WriteJavaScriptWithScope(const ACode: String);
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteStartDocument;
  WriteName('$code');
  WriteString(ACode);
  WriteName('$scope');

  State := TgoBsonWriterState.ScopeDocument;
end;

procedure TgoJsonWriter.WriteMaxKey;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);

  if (FSettings.OutputMode = TgoJsonOutputMode.Strict) then
    FOutput.Append('{ "$maxKey" : 1 }')
  else
    FOutput.Append('MaxKey');

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteMinKey;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);

  if (FSettings.OutputMode = TgoJsonOutputMode.Strict) then
    FOutput.Append('{ "$minKey" : 1 }')
  else
    FOutput.Append('MinKey');

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteNameHelper(const AName: String);
begin
  Assert(Assigned(FContext));
  case FContext.ContextType of
    TgoBsonContextType.&Array:
      begin
        if (FContext.HasElements) then
          FOutput.Append(', ');
      end;

    TgoBsonContextType.Document,
    TgoBsonContextType.ScopeDocument:
      begin
        if (FContext.HasElements) then
          FOutput.Append(',');

        if (FSettings.PrettyPrint) then
        begin
          FOutput.Append(FSettings.LineBreak);
          FOutput.Append(FContext.Indentation);
        end
        else
          FOutput.Append(' ');

        WriteQuotedString(AName);
        FOutput.Append(' : ');
      end;

    TgoBsonContextType.TopLevel: ;
  else
    Assert(False);
  end;
  FContext.HasElements := True;
end;

procedure TgoJsonWriter.WriteNull;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);
  FOutput.Append('null');
  State := GetNextState;
end;

procedure TgoJsonWriter.WriteObjectId(const AValue: TgoObjectId);
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);

  if (FSettings.OutputMode = TgoJsonOutputMode.Strict) then
  begin
    FOutput.Append('{ "$oid" : "');
    FOutput.Append(AValue.ToString);
    FOutput.Append('" }');
  end
  else
  begin
    FOutput.Append('ObjectId("');
    FOutput.Append(AValue.ToString);
    FOutput.Append('")');
  end;

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteQuotedString(const AValue: String);
begin
  FOutput.Append('"');
  WriteEscapedString(AValue);
  FOutput.Append('"');
end;

procedure TgoJsonWriter.WriteRaw(const AValue: String);
begin
  FOutput.Append(AValue)
end;

procedure TgoJsonWriter.WriteRegularExpression(
  const AValue: TgoBsonRegularExpression);
var
  Pattern, Options: String;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  Pattern := AValue.Pattern;
  Options := AValue.Options;

  WriteNameHelper(Name);

  if (FSettings.OutputMode = TgoJsonOutputMode.Strict) then
  begin
    FOutput.Append('{ "$regex" : "');
    WriteEscapedString(Pattern);
    FOutput.Append('", "$options" : "');
    WriteEscapedString(Options);
    FOutput.Append('" }');
  end
  else
  begin
    if (Pattern = '') then
      Pattern := '(?:)'
    else
      Pattern := Pattern.Replace('/', '\/', [rfReplaceAll]);
    FOutput.Append('/');
    FOutput.Append(Pattern);
    FOutput.Append('/');
    FOutput.Append(Options);
  end;

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteStartArray;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);
  FOutput.Append('[');

  PushContext(TgoBsonContextType.&Array, FSettings.Indent);
  State := TgoBsonWriterState.Value;
end;

procedure TgoJsonWriter.WriteStartDocument;
var
  ContextType: TgoBsonContextType;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value, TgoBsonWriterState.ScopeDocument])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  if (State in [TgoBsonWriterState.Value, TgoBsonWriterState.ScopeDocument]) then
    WriteNameHelper(Name);

  FOutput.Append('{');

  if (State = TgoBsonWriterState.ScopeDocument) then
    ContextType := TgoBsonContextType.ScopeDocument
  else
    ContextType := TgoBsonContextType.Document;

  PushContext(ContextType, FSettings.Indent);
  State := TgoBsonWriterState.Name;
end;

procedure TgoJsonWriter.WriteString(const AValue: String);
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);
  WriteQuotedString(AValue);
  State := GetNextState;
end;

procedure TgoJsonWriter.WriteSymbol(const AValue: String);
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);

  FOutput.Append('{ "$symbol" : "');
  WriteEscapedString(AValue);
  FOutput.Append('" }');

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteTimestamp(const AValue: Int64);
var
  SecondsSinceEpoch, Increment: Integer;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  SecondsSinceEpoch := AValue shr 32;
  Increment := AValue and $FFFFFFFF;

  WriteNameHelper(Name);

  if (FSettings.OutputMode = TgoJsonOutputMode.Strict) then
  begin
    FOutput.Append('{ "$timestamp" : { "t" : ');
    FOutput.Append(SecondsSinceEpoch);
    FOutput.Append(', "i" : ');
    FOutput.Append(Increment);
    FOutput.Append(' } }');
  end
  else
  begin
    FOutput.Append('Timestamp(');
    FOutput.Append(SecondsSinceEpoch);
    FOutput.Append(', ');
    FOutput.Append(Increment);
    FOutput.Append(')');
  end;

  State := GetNextState;
end;

procedure TgoJsonWriter.WriteUndefined;
begin
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  WriteNameHelper(Name);

  if (FSettings.OutputMode = TgoJsonOutputMode.Strict) then
    FOutput.Append('{ "$undefined" : true }')
  else
    FOutput.Append('undefined');

  State := GetNextState;
end;

{ TgoJsonWriter.TContext }

procedure TgoJsonWriter.TContext.Initialize(const AParentContext: PContext;
  const AContextType: TgoBsonContextType;
  const AIndentString: String);
begin
  if Assigned(AParentContext) then
    FIndentation := AParentContext.FIndentation + AIndentString
  else
    FIndentation := AIndentString;
  FContextType := AContextType;
  FHasElements := False;
end;

{ TgoBsonDocumentWriter }

procedure TgoBsonDocumentWriter.AddValue(const AValue: TgoBsonValue);
begin
  Assert(Assigned(FContext));
  if (FContext.ContextType = TgoBsonContextType.&Array) then
    FContext.&Array.Add(AValue)
  else
    FContext.Document.Add(FContext.Name, AValue);
end;

constructor TgoBsonDocumentWriter.Create(const ADocument: TgoBsonDocument);
begin
  inherited Create;
  FDocument := ADocument;
  FContextIndex := -1;
end;

function TgoBsonDocumentWriter.GetDocument: TgoBsonDocument;
begin
  Result := FDocument;
end;

function TgoBsonDocumentWriter.GetNextState: TgoBsonWriterState;
begin
  Assert(Assigned(FContext));
  if (FContext.ContextType = TgoBsonContextType.&Array) then
    Result := TgoBsonWriterState.Value
  else
    Result := TgoBsonWriterState.Name;
end;

procedure TgoBsonDocumentWriter.PopContext;
begin
  Dec(FContextIndex);
  if (FContextIndex < 0) then
  begin
    FContext := nil;
    FContextIndex := -1;
  end
  else
    FContext := @FContextStack[FContextIndex];
end;

procedure TgoBsonDocumentWriter.PushContext(
  const AContextType: TgoBsonContextType; const ACode: String);
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);
  FContextStack[FContextIndex].Initialize(AContextType, ACode);
  FContext := @FContextStack[FContextIndex];
end;

procedure TgoBsonDocumentWriter.PushContext(
  const AContextType: TgoBsonContextType; const AArray: TgoBsonArray);
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);
  FContextStack[FContextIndex].Initialize(AContextType, AArray);
  FContext := @FContextStack[FContextIndex];
end;

procedure TgoBsonDocumentWriter.PushContext(
  const AContextType: TgoBsonContextType; const ADocument: TgoBsonDocument);
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);
  FContextStack[FContextIndex].Initialize(AContextType, ADocument);
  FContext := @FContextStack[FContextIndex];
end;

procedure TgoBsonDocumentWriter.WriteBinaryData(
  const AValue: TgoBsonBinaryData);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(AValue);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteBoolean(const AValue: Boolean);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(AValue);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteDateTime(
  const AMillisecondsSinceEpoch: Int64);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(TgoBsonDateTime.Create(AMillisecondsSinceEpoch));
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteDouble(const AValue: Double);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(AValue);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteEndArray;
var
  A: TgoBsonArray;
begin
  Assert(Assigned(FContext));
  if (State <> TgoBsonWriterState.Value) or (FContext.ContextType <> TgoBsonContextType.&Array) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  A := FContext.&Array;
  PopContext;
  AddValue(A);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteEndDocument;
var
  Document: TgoBsonDocument;
  Code: String;
begin
  Assert(Assigned(FContext));
  if (State <> TgoBsonWriterState.Name) or (not (FContext.ContextType in [TgoBsonContextType.Document, TgoBsonContextType.ScopeDocument])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  Document := FContext.Document;
  if (FContext.ContextType = TgoBsonContextType.ScopeDocument) then
  begin
    PopContext;
    Assert(Assigned(FContext));
    Code := FContext.Code;
    PopContext;
    AddValue(TgoBsonJavaScriptWithScope.Create(Code, Document));
  end
  else
  begin
    PopContext;
    if (FContext <> nil) then
      AddValue(Document);
  end;

  if (FContext = nil) then
    State := TgoBsonWriterState.Done
  else
    State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteInt32(const AValue: Integer);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(AValue);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteInt64(const AValue: Int64);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(AValue);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteJavaScript(const ACode: String);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(TgoBsonJavaScript.Create(ACode));
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteJavaScriptWithScope(const ACode: String);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  PushContext(TgoBsonContextType.JavaScriptWithScope, ACode);
  State := TgoBsonWriterState.ScopeDocument;
end;

procedure TgoBsonDocumentWriter.WriteMaxKey;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(TgoBsonMaxKey.Value);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteMinKey;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(TgoBsonMinKey.Value);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteName(const AName: String);
begin
  inherited;
  Assert(Assigned(FContext));
  FContext.Name := AName;
end;

procedure TgoBsonDocumentWriter.WriteNull;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(TgoBsonNull.Value);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteObjectId(const AValue: TgoObjectId);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(AValue);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteRegularExpression(
  const AValue: TgoBsonRegularExpression);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(AValue);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteStartArray;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  PushContext(TgoBsonContextType.&Array, TgoBsonArray.Create);
  State := TgoBsonWriterState.Value;
end;

procedure TgoBsonDocumentWriter.WriteStartDocument;
begin
  case State of
    TgoBsonWriterState.Initial,
    TgoBsonWriterState.Done:
      PushContext(TgoBsonContextType.Document, FDocument);

    TgoBsonWriterState.Value:
      PushContext(TgoBsonContextType.Document, TgoBsonDocument.Create);

    TgoBsonWriterState.ScopeDocument:
      PushContext(TgoBsonContextType.ScopeDocument, TgoBsonDocument.Create);
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  end;
  State := TgoBsonWriterState.Name;
end;

procedure TgoBsonDocumentWriter.WriteString(const AValue: String);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(AValue);
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteSymbol(const AValue: String);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(TgoBsonSymbolTable.Lookup(AValue));
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteTimestamp(const AValue: Int64);
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(TgoBsonTimestamp.Create(AValue));
  State := GetNextState;
end;

procedure TgoBsonDocumentWriter.WriteUndefined;
begin
  if (State <> TgoBsonWriterState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);
  AddValue(TgoBsonUndefined.Value);
  State := GetNextState;
end;

{ TgoBsonDocumentWriter.TContext }

procedure TgoBsonDocumentWriter.TContext.Initialize(
  const AContextType: TgoBsonContextType; const ADocument: TgoBsonDocument);
begin
  FContextType := AContextType;
  FDocument := ADocument;
end;

procedure TgoBsonDocumentWriter.TContext.Initialize(
  const AContextType: TgoBsonContextType; const AArray: TgoBsonArray);
begin
  FContextType := AContextType;
  FArray := AArray;
end;

procedure TgoBsonDocumentWriter.TContext.Initialize(
  const AContextType: TgoBsonContextType; const ACode: String);
begin
  FContextType := AContextType;
  FCode := ACode;
end;

{ TgoBsonBaseReader }

function TgoBsonBaseReader.DoReadJavaScriptWithScope: TgoBsonValue;
var
  Code: String;
  Scope: TgoBsonDocument;
begin
  Code := ReadJavaScriptWithScope;
  Scope := ReadDocument;
  Result := TgoBsonJavaScriptWithScope.Create(Code, Scope);
end;

procedure TgoBsonBaseReader.EnsureBsonTypeEquals(const ABsonType: TgoBsonType);
begin
  if (GetCurrentBsonType <> ABsonType) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);
end;

function TgoBsonBaseReader.GetCurrentBsonType: TgoBsonType;
begin
  if (FState in [TgoBsonReaderState.Initial, TgoBsonReaderState.ScopeDocument, TgoBsonReaderState.&Type]) then
    ReadBsonType;

  if (FState <> TgoBsonReaderState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  Result := FCurrentBsonType;
end;

function TgoBsonBaseReader.GetState: TgoBsonReaderState;
begin
  Result := FState;
end;

function TgoBsonBaseReader.ReadArray: TgoBsonArray;
var
  Item: TgoBsonValue;
begin
  EnsureBsonTypeEquals(TgoBsonType.&Array);

  ReadStartArray;
  Result := TgoBsonArray.Create;
  while (ReadBsonType <> TgoBsonType.EndOfDocument) do
  begin
    Item := ReadValue;
    Result.Add(Item);
  end;
  ReadEndArray;
end;

function TgoBsonBaseReader.ReadDocument: TgoBsonDocument;
var
  Name: String;
  Value: TgoBsonValue;
begin
  EnsureBsonTypeEquals(TgoBsonType.Document);

  ReadStartDocument;

  Result := TgoBsonDocument.Create;
  while (ReadBsonType <> TgoBsonType.EndOfDocument) do
  begin
    Name := ReadName;
    Value := ReadValue;
    Result.Add(Name, Value)
  end;

  ReadEndDocument;
end;

function TgoBsonBaseReader.ReadValue: TgoBsonValue;
begin
  case GetCurrentBsonType of
    TgoBsonType.EndOfDocument: ;
    TgoBsonType.Double: Result := ReadDouble;
    TgoBsonType.&String: Result := ReadString;
    TgoBsonType.Document: Result := ReadDocument;
    TgoBsonType.&Array: Result := ReadArray;
    TgoBsonType.Binary: Result := ReadBinaryData;
    TgoBsonType.Undefined: begin ReadUndefined; Result := TgoBsonUndefined.Value end;
    TgoBsonType.ObjectId: Result := ReadObjectId;
    TgoBsonType.Boolean: Result := ReadBoolean;
    TgoBsonType.DateTime: Result := TgoBsonDateTime.Create(ReadDateTime);
    TgoBsonType.Null: begin ReadNull; Result := TgoBsonNull.Value end;
    TgoBsonType.RegularExpression: Result := ReadRegularExpression;
    TgoBsonType.JavaScript: Result := TgoBsonJavaScript.Create(ReadJavaScript);
    TgoBsonType.Symbol: Result := TgoBsonSymbolTable.Lookup(ReadSymbol);
    TgoBsonType.JavaScriptWithScope: Result := DoReadJavaScriptWithScope;
    TgoBsonType.Int32: Result := ReadInt32;
    TgoBsonType.Timestamp: Result := TgoBsonTimestamp.Create(ReadTimestamp);
    TgoBsonType.Int64: Result := ReadInt64;
    TgoBsonType.MaxKey: begin ReadMaxKey; Result := TgoBsonMaxKey.Value end;
    TgoBsonType.MinKey: begin ReadMinKey; Result := TgoBsonMinKey.Value end;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

procedure TgoBsonBaseReader.VerifyBsonType(
  const ARequiredBsonType: TgoBsonType);
begin
  if (FState in [TgoBsonReaderState.Initial, TgoBsonReaderState.ScopeDocument, TgoBsonReaderState.&Type]) then
    ReadBsonType;

  if (FState = TgoBsonReaderState.Name) then
    SkipName;

  if (FState <> TgoBsonReaderState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  if (FCurrentBsonType <> ARequiredBsonType) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);
end;

{ TgoBsonBaseReader.TBookmark }

constructor TgoBsonBaseReader.TBookmark.Create(const AState: TgoBsonReaderState;
  const ACurrentBsonType: TgoBsonType; const ACurrentName: String);
begin
  inherited Create;
  FState := AState;
  FCurrentBsonType := ACurrentBsonType;
  FCurrentName := ACurrentName;
end;

function TgoBsonBaseReader.TBookmark.GetCurrentBsonType: TgoBsonType;
begin
  Result := FCurrentBsonType;
end;

function TgoBsonBaseReader.TBookmark.GetCurrentName: String;
begin
  Result := FCurrentName;
end;

function TgoBsonBaseReader.TBookmark.GetState: TgoBsonReaderState;
begin
  Result := FState;
end;

{ TgoBsonReader }

constructor TgoBsonReader.Create(const ABson: TBytes);
begin
  inherited Create;
  FInput.Initialize(ABson);
  PushContext(TgoBsonContextType.TopLevel, 0, 0);
end;

function TgoBsonReader.EndOfStream: Boolean;
begin
  Result := (FInput.Position >= FInput.Size);
end;

function TgoBsonReader.GetBookmark: IgoBsonReaderBookmark;
begin
  Result := TBsonBookmark.Create(State, CurrentBsonType, CurrentName,
    FContextIndex, FInput.Position);
end;

function TgoBsonReader.GetNextState: TgoBsonReaderState;
begin
  Assert(Assigned(FContext));
  case FContext.ContextType of
    TgoBsonContextType.&Array,
    TgoBsonContextType.Document,
    TgoBsonContextType.ScopeDocument:
      Result := TgoBsonReaderState.&Type;

    TgoBsonContextType.TopLevel:
      Result := TgoBsonReaderState.Initial;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

class function TgoBsonReader.Load(const AFilename: String): IgoBsonReader;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    Result := Load(Stream);
  finally
    Stream.Free;
  end;
end;

class function TgoBsonReader.Load(const AStream: TStream): IgoBsonReader;
var
  Bson: TBytes;
begin
  SetLength(Bson, AStream.Size - AStream.Position);
  AStream.ReadBuffer(Bson[0], Length(Bson));
  Result := TgoBsonReader.Create(Bson);
end;

procedure TgoBsonReader.PopContext(const APosition: Integer);
var
  ActualSize: Integer;
begin
  Assert(Assigned(FContext));
  ActualSize := APosition - FContext.FStartPosition;
  if (ActualSize <> FContext.FSize) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);

  Dec(FContextIndex);
  if (FContextIndex < 0) then
  begin
    FContext := nil;
    FContextIndex := -1;
  end
  else
    FContext := @FContextStack[FContextIndex];
end;

procedure TgoBsonReader.PushContext(const AContextType: TgoBsonContextType;
  const AStartPosition, ASize: Integer);
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);
  FContextStack[FContextIndex].Initialize(AContextType, AStartPosition, ASize);
  FContext := @FContextStack[FContextIndex];
end;

function TgoBsonReader.ReadBinaryData: TgoBsonBinaryData;
var
  Size, Size2: Integer;
  SubType: TgoBsonBinarySubType;
  Bytes: TBytes;
begin
  VerifyBsonType(TgoBsonType.Binary);
  Size := ReadSize;

  SubType := FInput.ReadBinarySubType;
  if (SubType = TgoBsonBinarySubType.OldBinary) then
  begin
    Size2 := ReadSize;
    if (Size2 <> (Size - 4)) then
      raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);

    Size := Size2;
    SubType := TgoBsonBinarySubType.Binary;
  end;

  SetLength(Bytes, Size);
  FInput.Read(Bytes[0], Size);
  State := GetNextState;

  Result := TgoBsonBinaryData.Create(Bytes, SubType);
end;

function TgoBsonReader.ReadBoolean: Boolean;
begin
  VerifyBsonType(TgoBsonType.Boolean);
  State := GetNextState;
  Result := FInput.ReadBoolean;
end;

function TgoBsonReader.ReadBsonType: TgoBsonType;
begin
  if (State in [TgoBsonReaderState.Initial, TgoBsonReaderState.ScopeDocument]) then
  begin
    CurrentBsonType := TgoBsonType.Document;
    State := TgoBsonReaderState.Value;
    Exit(CurrentBsonType);
  end;

  if (State <> TgoBsonReaderState.&Type) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  Assert(Assigned(FContext));
  if (FContext.ContextType = TgoBsonContextType.&Array) then
    Inc(FContext.FCurrentArrayIndex);

  CurrentBsonType := FInput.ReadBsonType;

  if (CurrentBsonType = TgoBsonType.EndOfDocument) then
  begin
    case FContext.ContextType of
      TgoBsonContextType.&Array:
        State := TgoBsonReaderState.EndOfArray;

      TgoBsonContextType.Document,
      TgoBsonContextType.ScopeDocument:
        State := TgoBsonReaderState.EndOfDocument;
    else
      raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);
    end;
  end
  else
  begin
    case FContext.ContextType of
      TgoBsonContextType.&Array:
        begin
          FInput.SkipCString;
          State := TgoBsonReaderState.Value;
        end;

      TgoBsonContextType.Document,
      TgoBsonContextType.ScopeDocument:
        State := TgoBsonReaderState.Name;
    else
      raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
    end;
  end;
  Result := CurrentBsonType;
end;

function TgoBsonReader.ReadBytes: TBytes;
var
  Size: Integer;
  SubType: TgoBsonBinarySubType;
begin
  VerifyBsonType(TgoBsonType.Binary);

  Size := ReadSize;
  SubType := FInput.ReadBinarySubType;
  if (not (SubType in [TgoBsonBinarySubType.Binary, TgoBsonBinarySubType.OldBinary])) then
      raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);

  State := GetNextState;
  Result := FInput.ReadBytes(Size);
end;

function TgoBsonReader.ReadDateTime: Int64;
begin
  VerifyBsonType(TgoBsonType.DateTime);
  State := GetNextState;
  Result := FInput.ReadInt64;
end;

function TgoBsonReader.ReadDouble: Double;
begin
  VerifyBsonType(TgoBsonType.Double);
  State := GetNextState;
  Result := FInput.ReadDouble;
end;

procedure TgoBsonReader.ReadEndArray;
begin
  Assert(Assigned(FContext));
  if (FContext.ContextType <> TgoBsonContextType.&Array) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  if (State = TgoBsonReaderState.&Type) then
    ReadBsonType;

  if (State <> TgoBsonReaderState.EndOfArray) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  PopContext(FInput.Position);
  case FContext.ContextType of
    TgoBsonContextType.&Array,
    TgoBsonContextType.Document:
      State := TgoBsonReaderState.&Type;

    TgoBsonContextType.TopLevel:
      State := TgoBsonReaderState.Initial;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

procedure TgoBsonReader.ReadEndDocument;
begin
  Assert(Assigned(FContext));
  if (not (FContext.ContextType in [TgoBsonContextType.Document, TgoBsonContextType.ScopeDocument])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  if (State = TgoBsonReaderState.&Type) then
    ReadBsonType;

  if (State <> TgoBsonReaderState.EndOfDocument) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  PopContext(FInput.Position);
  Assert(Assigned(FContext));
  if (FContext.ContextType = TgoBsonContextType.JavaScriptWithScope) then
  begin
    PopContext(FInput.Position);
    Assert(Assigned(FContext));
  end;

  case FContext.ContextType of
    TgoBsonContextType.&Array,
    TgoBsonContextType.Document:
      State := TgoBsonReaderState.&Type;

    TgoBsonContextType.TopLevel:
      State := TgoBsonReaderState.Initial;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

function TgoBsonReader.ReadInt32: Integer;
begin
  VerifyBsonType(TgoBsonType.Int32);
  State := GetNextState;
  Result := FInput.ReadInt32;
end;

function TgoBsonReader.ReadInt64: Int64;
begin
  VerifyBsonType(TgoBsonType.Int64);
  State := GetNextState;
  Result := FInput.ReadInt64;
end;

function TgoBsonReader.ReadJavaScript: String;
begin
  VerifyBsonType(TgoBsonType.JavaScript);
  State := GetNextState;
  Result := FInput.ReadString;
end;

function TgoBsonReader.ReadJavaScriptWithScope: String;
var
  StartPosition, Size: Integer;
begin
  VerifyBsonType(TgoBsonType.JavaScriptWithScope);

  StartPosition := FInput.Position;
  Size := ReadSize;

  PushContext(TgoBsonContextType.JavaScriptWithScope, StartPosition, Size);
  Result := FInput.ReadString;

  State := TgoBsonReaderState.ScopeDocument;
end;

procedure TgoBsonReader.ReadMaxKey;
begin
  VerifyBsonType(TgoBsonType.MaxKey);
  State := GetNextState;
end;

procedure TgoBsonReader.ReadMinKey;
begin
  VerifyBsonType(TgoBsonType.MinKey);
  State := GetNextState;
end;

function TgoBsonReader.ReadName: String;
begin
  if (FState = TgoBsonReaderState.&Type) then
    ReadBsonType;

  if (FState <> TgoBsonReaderState.Name) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  CurrentName := FInput.ReadCString;
  State := TgoBsonReaderState.Value;

  Assert(Assigned(FContext));
  if (FContext.ContextType = TgoBsonContextType.Document) then
    FContext.CurrentElementName := CurrentName;

  Result := CurrentName;
end;

procedure TgoBsonReader.ReadNull;
begin
  VerifyBsonType(TgoBsonType.Null);
  State := GetNextState;
end;

function TgoBsonReader.ReadObjectId: TgoObjectId;
begin
  VerifyBsonType(TgoBsonType.ObjectId);
  State := GetNextState;
  Result := FInput.ReadObjectId;
end;

function TgoBsonReader.ReadRegularExpression: TgoBsonRegularExpression;
var
  Pattern, Options: String;
begin
  VerifyBsonType(TgoBsonType.RegularExpression);
  State := GetNextState;
  Pattern := FInput.ReadCString;
  Options := FInput.ReadCString;
  Result := TgoBsonRegularExpression.Create(Pattern, Options);
end;

function TgoBsonReader.ReadSize: Integer;
begin
  Result := FInput.ReadInt32;
  if (Result < 0) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);
end;

procedure TgoBsonReader.ReadStartArray;
var
  StartPosition, Size: Integer;
begin
  VerifyBsonType(TgoBsonType.&Array);
  StartPosition := FInput.Position;
  Size := ReadSize;
  PushContext(TgoBsonContextType.&Array, StartPosition, Size);
  State := TgoBsonReaderState.&Type;
end;

procedure TgoBsonReader.ReadStartDocument;
var
  ContextType: TgoBsonContextType;
  StartPosition, Size: Integer;
begin
  VerifyBsonType(TgoBsonType.Document);

  if (State = TgoBsonReaderState.ScopeDocument) then
    ContextType := TgoBsonContextType.ScopeDocument
  else
    ContextType := TgoBsonContextType.Document;

  StartPosition := FInput.Position;
  Size := ReadSize;

  PushContext(ContextType, StartPosition, Size);
  State := TgoBsonReaderState.&Type;
end;

function TgoBsonReader.ReadString: String;
begin
  VerifyBsonType(TgoBsonType.String);
  State := GetNextState;
  Result := FInput.ReadString;
end;

function TgoBsonReader.ReadSymbol: String;
begin
  VerifyBsonType(TgoBsonType.Symbol);
  State := GetNextState;
  Result := FInput.ReadString;
end;

function TgoBsonReader.ReadTimestamp: Int64;
begin
  VerifyBsonType(TgoBsonType.Timestamp);
  State := GetNextState;
  Result := FInput.ReadInt64;
end;

procedure TgoBsonReader.ReadUndefined;
begin
  VerifyBsonType(TgoBsonType.Undefined);
  State := GetNextState;
end;

procedure TgoBsonReader.ReturnToBookmark(
  const ABookmark: IgoBsonReaderBookmark);
var
  BM: TBsonBookmark;
begin
  Assert(Assigned(ABookmark));
  Assert(ABookmark is TBsonBookmark);
  BM := TBsonBookmark(ABookmark);
  State := BM.State;
  CurrentBsonType := BM.CurrentBsonType;
  CurrentName := BM.CurrentName;
  FContextIndex := BM.ContextIndex;
  Assert((FContextIndex >= 0) and (FContextIndex < Length(FContextStack)));
  FContext := @FContextStack[FContextIndex];
  FInput.Position := BM.Position;
end;

procedure TgoBsonReader.SkipName;
begin
  if (FState <> TgoBsonReaderState.Name) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  FInput.SkipCString;
  FCurrentName := '';
  State := TgoBsonReaderState.Value;

  Assert(Assigned(FContext));
  if (FContext.ContextType = TgoBsonContextType.Document) then
    FContext.CurrentElementName := CurrentName;
end;

procedure TgoBsonReader.SkipValue;
var
  Skip: Integer;
begin
  if (FState <> TgoBsonReaderState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  case CurrentBsonType of
    TgoBsonType.&Array: Skip := ReadSize - 4;
    TgoBsonType.Binary: Skip := ReadSize + 1;
    TgoBsonType.Boolean: Skip := 1;
    TgoBsonType.DateTime: Skip := 8;
    TgoBsonType.Document: Skip := ReadSize - 4;
    TgoBsonType.Double: Skip := 8;
    TgoBsonType.Int32: Skip := 4;
    TgoBsonType.Int64: Skip := 8;
    TgoBsonType.JavaScript: Skip := ReadSize;
    TgoBsonType.JavaScriptWithScope: Skip := ReadSize - 4;
    TgoBsonType.ObjectId: Skip := 12;
    TgoBsonType.RegularExpression:
      begin
        FInput.SkipCString;
        FInput.SkipCString;
        Skip := 0;
      end;
    TgoBsonType.String: Skip := ReadSize;
    TgoBsonType.Symbol: Skip := ReadSize;
    TgoBsonType.Timestamp: Skip := 8;
  else
    Skip := 0;
  end;
  FInput.Skip(Skip);
  State := TgoBsonReaderState.&Type;
end;

{ TgoBsonReader.TInput }

class constructor TgoBsonReader.TInput.Create;
var
  B: Integer;
begin
  FillChar(FValidBsonTypes, SizeOf(FValidBsonTypes), False);
  for B := 0 to $12 do
    FValidBsonTypes[B] := (B <> $0C);
  FValidBsonTypes[$7F] := True;
  FValidBsonTypes[$FF] := True;
end;

procedure TgoBsonReader.TInput.Initialize(const ABuffer: TBytes);
begin
  FBuffer := ABuffer;
  FSize := Length(ABuffer);
  FPosition := 0;
  SetLength(FTempBytes, TEMP_BYTES_LENGTH);
end;

procedure TgoBsonReader.TInput.Read(out AData; const ASize: Integer);
begin
  if ((FPosition + ASize) > FSize) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);
  Move(FBuffer[FPosition], AData, ASize);
  Inc(FPosition, ASize);
end;

function TgoBsonReader.TInput.ReadBinarySubType: TgoBsonBinarySubType;
var
  B: Byte absolute Result;
begin
  Read(B, 1);
end;

function TgoBsonReader.TInput.ReadBoolean: Boolean;
var
  B: Byte;
begin
  Read(B, 1);
  Result := (B <> 0);
end;

function TgoBsonReader.TInput.ReadBsonType: TgoBsonType;
var
  B: Byte absolute Result;
begin
  Read(B, 1);
  if (not (FValidBsonTypes[B])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);
end;

function TgoBsonReader.TInput.ReadByte: Byte;
begin
  Read(Result, 1);
end;

function TgoBsonReader.TInput.ReadBytes(const ASize: Integer): TBytes;
begin
  Assert(ASize >= 0);
  SetLength(Result, ASize);
  Read(Result[0], ASize);
end;

function TgoBsonReader.TInput.ReadCString: String;
var
  Bytes: TBytes;
  B: Byte;
  Index: Integer;
begin
  Index := 0;
  Bytes := nil;
  while True do
  begin
    B := ReadByte;
    if (B = 0) then
      Break;

    if (Index >= Length(Bytes)) then
      SetLength(Bytes, Index + 32);
    Bytes[Index] := B;
    Inc(Index);
  end;
  Result := TEncoding.UTF8.GetString(Bytes, 0, Index);
end;

function TgoBsonReader.TInput.ReadDouble: Double;
begin
  Read(Result, 8);
end;

function TgoBsonReader.TInput.ReadInt32: Int32;
begin
  Read(Result, 4);
end;

function TgoBsonReader.TInput.ReadInt64: Int64;
begin
  Read(Result, 8);
end;

function TgoBsonReader.TInput.ReadObjectId: TgoObjectId;
var
  Bytes: TBytes;
begin
  SetLength(Bytes, 12);
  Read(Bytes[0], 12);
  Result := TgoObjectId.Create(Bytes);
end;

function TgoBsonReader.TInput.ReadString: String;
var
  Len: Integer;
  Bytes: TBytes;
begin
  Len := ReadInt32;
  if (Len <= 0) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);

  if (Len <= TEMP_BYTES_LENGTH) then
    Bytes := FTempBytes
  else
    SetLength(Bytes, Len);
  Read(Bytes[0], Len);
  if (Bytes[Len - 1] <> 0) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);
  Result := TEncoding.UTF8.GetString(Bytes, 0, Len - 1);
end;

procedure TgoBsonReader.TInput.Skip(const ANumBytes: Integer);
begin
  if ((FPosition + ANumBytes) > FSize) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);
  Inc(FPosition, ANumBytes);
end;

procedure TgoBsonReader.TInput.SkipCString;
begin
  while (ReadByte <> 0) do ;
end;

{ TgoBsonReader.TContext }

procedure TgoBsonReader.TContext.Initialize(
  const AContextType: TgoBsonContextType; const AStartPosition, ASize: Integer);
begin
  FStartPosition := AStartPosition;
  FSize := ASize;
  FCurrentArrayIndex := -1;
  FCurrentElementName := '';
  FContextType := AContextType;
end;

{ TgoBsonReader.TBsonBookmark }

constructor TgoBsonReader.TBsonBookmark.Create(const AState: TgoBsonReaderState;
  const ACurrentBsonType: TgoBsonType; const ACurrentName: String;
  const AContextIndex, APosition: Integer);
begin
  inherited Create(AState, ACurrentBsonType, ACurrentName);
  FContextIndex := AContextIndex;
  FPosition := APosition;
end;

{ TgoJsonReader }

constructor TgoJsonReader.Create(const AJson: String);
begin
  inherited Create;
  FBuffer := TBuffer.Create(AJson);
  PushContext(TgoBsonContextType.TopLevel);
end;

function TgoJsonReader.EndOfStream: Boolean;
var
  C: Char;
begin
  while True do
  begin
    C := FBuffer.Read;
    if (C = #0) then
      Exit(True);

    if (not TScanner.IsWhitespace(C)) then
    begin
      FBuffer.Unread(C);
      Exit(False);
    end;
  end;
end;

class function TgoJsonReader.FormatJavaScriptDateTimeString(
  const ALocalDateTime: TDateTime): String;
var
  Utc, Offset: TDateTime;
  OffsetSign: String;
  H, M, S, MSec: Word;
begin
  Utc := TTimeZone.Local.ToUniversalTime(ALocalDateTime);
  Offset := ALocalDateTime - Utc;
  if (Offset < 0) then
  begin
    Offset := -Offset;
    OffsetSign := '-';
  end
  else
    OffsetSign := '+';

  DecodeTime(Offset, H, M, S, MSec);
  Result := FormatDateTime('ddd mmm dd yyyy hh:nn:ss', ALocalDateTime, goUSFormatSettings)
    + Format('GMT%s%.2d%.2d (%s)', [OffsetSign, H, M, TTimeZone.Local.DisplayName]);
end;

function TgoJsonReader.GetBookmark: IgoBsonReaderBookmark;
begin
  Result := TJsonBookmark.Create(State, CurrentBsonType, CurrentName,
    FContextIndex, FCurrentToken, FCurrentValue, FPushedToken, FHasPushedToken,
    FBuffer.FCurrent);
end;

function TgoJsonReader.GetNextState: TgoBsonReaderState;
begin
  Assert(Assigned(FContext));
  case FContext.ContextType of
    TgoBsonContextType.&Array,
    TgoBsonContextType.Document:
      Result := TgoBsonReaderState.&Type;

    TgoBsonContextType.TopLevel:
      Result := TgoBsonReaderState.Initial;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

class function TgoJsonReader.Load(const AFilename: String): IgoJsonReader;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    Result := Load(Stream);
  finally
    Stream.Free;
  end;
end;

class function TgoJsonReader.Load(const AStream: TStream): IgoJsonReader;
var
  Reader: TStreamReader;
  Json: String;
begin
  Reader := TStreamReader.Create(AStream, True);
  try
    Json := Reader.ReadToEnd;
  finally
    Reader.Free;
  end;
  Result := TgoJsonReader.Create(Json);
end;

function TgoJsonReader.ParseConstructorBinaryData: TgoBsonValue;
{ BinData(0, "AQ==") }
var
  Token: TToken;
  Base64, Bytes: TBytes;
  SubType: TgoBsonBinarySubType;
begin
  VerifyToken('(');

  PopToken(Token);
  if (Token.TokenType <> TTokenType.Int32) then
    raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);
  SubType := TgoBsonBinarySubType(Token.Int32Value);

  VerifyToken(',');

  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  Base64 := TEncoding.ANSI.GetBytes(Token.StringValue);

  VerifyToken(')');

  Bytes := goBase64Decode(Base64);
  Result := TgoBsonBinaryData.Create(Bytes, SubType);
end;

function TgoJsonReader.ParseConstructorDateTime(
  const AWithNew: Boolean): TgoBsonValue;
{ Date()
  new Date()
  new Date(9223372036854775807)
  new Date(1970, 3, 30, 11, 59, 23, 123)
  new Date("...") }
var
  Token: TToken;
  DateTime: TDateTime;
  Args: array [0..6] of Int64;
  ArgCount: Integer;
begin
  VerifyToken('(');

  if (not AWithNew) then
  begin
    VerifyToken(')');
    Result := FormatJavaScriptDateTimeString(Now);
    Exit;
  end;

  PopToken(Token);
  if (Token.Lexeme = ')') then
    Exit(TgoBsonDateTime.Create(Now, False));

  if (Token.TokenType = TTokenType.String) then
  begin
    VerifyToken(')');
    raise FBuffer.ParseError(@RS_BSON_JS_DATETIME_STRING_NOT_SUPPORTED);
  end;

  if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
  begin
    ArgCount := 0;
    FillChar(Args, SizeOf(Args), 0);
    while True do
    begin
      if (ArgCount > 6) then
        raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);
      Args[ArgCount] := Token.Int64Value;
      Inc(ArgCount);

      PopToken(Token);
      if (Token.Lexeme = ')') then
        Break;

      if (Token.Lexeme <> ',') then
        raise FBuffer.ParseError(@RS_BSON_COMMA_EXPECTED);

      PopToken(Token);
      if (not (Token.TokenType in [TTokenType.Int32, TTokenType.Int64])) then
        raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);
    end;

    case ArgCount of
      1: Result := TgoBsonDateTime.Create(Args[0]);
      3..7:
        begin
          DateTime := EncodeDateTime(
            Args[0], Args[1] + 1, Args[2],
            Args[3], Args[3], Args[5], Args[6]);
          Result := TgoBsonDateTime.Create(DateTime, True);
        end
    else
      raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);
    end;
    Exit;
  end;

  raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);
end;

function TgoJsonReader.ParseConstructorHexData: TgoBsonValue;
{ HexData(0, "123") }
var
  Token: TToken;
  SubType: TgoBsonBinarySubType;
  Bytes: TBytes;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.Int32) then
    raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);
  SubType := TgoBsonBinarySubType(Token.Int32Value);

  VerifyToken(',');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  VerifyToken(')');

  Bytes := goParseHexString(Token.StringValue);
  Result := TgoBsonBinaryData.Create(Bytes, SubType);
end;

function TgoJsonReader.ParseConstructorISODateTime: TgoBsonValue;
{ ISODate("1970-01-01T00:00:00Z")
  ISODate("1970-01-01T00:00:00.000Z") }
var
  Token: TToken;
  DateTime: TDateTime;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);

  VerifyToken(')');

  { Note: The C# drivers supports a whole range of date/time formats.
    We only support the official ISO8601 format }
  if (not TryISO8601ToDate(Token.StringValue, DateTime, True)) then
    raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);

  Result := TgoBsonDateTime.Create(DateTime, True);
end;

function TgoJsonReader.ParseConstructorNumber: TgoBsonValue;
{ Number(42)
  Number("42")
  NumberInt(42)
  NumberInt("42") }
var
  Token: TToken;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType = TTokenType.Int32) then
    Result := Token.Int32Value
  else if (Token.TokenType = TTokenType.String) then
    Result := StrToInt(Token.StringValue)
  else
    raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);
  VerifyToken(')');
end;

function TgoJsonReader.ParseConstructorNumberLong: TgoBsonValue;
{ NumberLong(42)
  NumberLong("42") }
var
  Token: TToken;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
    Result := Token.Int64Value
  else if (Token.TokenType = TTokenType.String) then
    Result := StrToInt64(Token.StringValue)
  else
    raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);
  VerifyToken(')');
end;

function TgoJsonReader.ParseConstructorObjectId: TgoBsonValue;
// ObjectId("0102030405060708090a0b0c")
var
  Token: TToken;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  VerifyToken(')');
  Result := TgoObjectId.Create(Token.StringValue);
end;

function TgoJsonReader.ParseConstructorRegularExpression: TgoBsonValue;
{ RegExp("pattern")
  RegExp("pattern", "options") }
var
  Token: TToken;
  Pattern, Options: String;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  Pattern := Token.StringValue;
  Options := '';

  PopToken(Token);
  if (Token.Lexeme = ',') then
  begin
    PopToken(Token);
    if (Token.TokenType <> TTokenType.String) then
      raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
    Options := Token.StringValue;
  end
  else
    PushToken(Token);

  VerifyToken(')');
  Result := TgoBsonRegularExpression.Create(Pattern, Options);
end;

function TgoJsonReader.ParseConstructorTimestamp: TgoBsonValue;
{ Timestamp(1, 2) }
var
  Token: TToken;
  SecondsSinceEpoch, Increment: Integer;
begin
  VerifyToken('(');

  PopToken(Token);
  if (Token.TokenType = TTokenType.Int32) then
    SecondsSinceEpoch := Token.Int32Value
  else
    raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);

  VerifyToken(',');

  PopToken(Token);
  if (Token.TokenType = TTokenType.Int32) then
    Increment := Token.Int32Value
  else
    raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);

  VerifyToken(')');
  Result := TgoBsonTimestamp.Create(SecondsSinceEpoch, Increment);
end;

function TgoJsonReader.ParseConstructorUUID(
  const AConstructorName: String): TgoBsonValue;
var
  Token: TToken;
  HexString: String;
  Bytes: TBytes;
  SubType: TgoBsonBinarySubType;
  C: Char;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  VerifyToken(')');

  HexString := Token.StringValue.Replace('{', '').Replace('}', '');
  HexString := HexString.Replace('-', '', [rfReplaceAll]);
  Bytes := goParseHexString(HexString);
  if (Length(Bytes) <> 16) then
    raise FBuffer.ParseError(@RS_BSON_INVALID_GUID);
  SubType := TgoBsonBinarySubType.UuidLegacy;

  Assert(AConstructorName <> '');
  C := AConstructorName.Chars[0];
  if (C = 'C') then // C#
  begin
    // No conversion needed
    goReverseBytes(Bytes, 0, 4);
    goReverseBytes(Bytes, 4, 2);
    goReverseBytes(Bytes, 6, 2);
  end
  else
  begin
    if (C = 'J') then // Java
    begin
      goReverseBytes(Bytes, 0, 8);
      goReverseBytes(Bytes, 8, 8);
    end
    else if (C <> 'P') then // Python
      SubType := TgoBsonBinarySubType.UuidStandard;
  end;

  Result := TgoBsonBinaryData.Create(Bytes, SubType);
end;

function TgoJsonReader.ParseExtendedJson: TgoBsonType;
var
  NameToken: TToken;
  S: String;
begin
  PopToken(NameToken);
  if (NameToken.TokenType in [TTokenType.String, TTokenType.UnquotedString]) then
  begin
    S := NameToken.StringValue;
    if (S = '') then
    begin
      PushToken(NameToken);
      Exit(TgoBsonType.Document);
    end;

    if (S.Chars[0] = '$') and (S.Length > 1) then
    begin
      case S.Chars[1] of
        'b': if (S = '$binary') then
             begin
               FCurrentValue := ParseExtendedJsonBinaryData;
               Exit(TgoBsonType.Binary);
             end;
        'c': if (S = '$code') then
               Exit(ParseExtendedJsonJavaScript(FCurrentValue));
        'd': if (S = '$date') then
             begin
               FCurrentValue := ParseExtendedJsonDateTime;
               Exit(TgoBsonType.DateTime);
             end;
        'm': if (S = '$maxkey') or (S = '$maxKey') then
             begin
               FCurrentValue := ParseExtendedJsonMaxKey;
               Exit(TgoBsonType.MaxKey);
             end
             else if (S = '$minkey') or (S = '$minKey') then
             begin
               FCurrentValue := ParseExtendedJsonMinKey;
               Exit(TgoBsonType.MinKey);
             end;
        'n': if (S = '$numberLong') then
             begin
               FCurrentValue := ParseExtendedJsonNumberLong;
               Exit(TgoBsonType.Int64);
             end;
        'o': if (S = '$oid') then
             begin
               FCurrentValue := ParseExtendedJsonObjectId;
               Exit(TgoBsonType.ObjectId);
             end;
        'r': if (S = '$regex') then
             begin
               FCurrentValue := ParseExtendedJsonRegularExpression;
               Exit(TgoBsonType.RegularExpression);
             end;
        's': if (S = '$symbol') then
             begin
               FCurrentValue := ParseExtendedJsonSymbol;
               Exit(TgoBsonType.Symbol);
             end;
        't': if (S = '$timestamp') then
             begin
               FCurrentValue := ParseExtendedJsonTimestamp;
               Exit(TgoBsonType.Timestamp);
             end;
        'u': if (S = '$undefined') then
             begin
               FCurrentValue := ParseExtendedJsonUndefined;
               Exit(TgoBsonType.Undefined);
             end;
      end;
    end;
  end;
  PushToken(NameToken);
  Result := TgoBsonType.Document;
end;

function TgoJsonReader.ParseExtendedJsonBinaryData: TgoBsonValue;
(* { $binary : "AQ==", $type : 0 }
   { $binary : "AQ==", $type : "0" }
   { $binary : "AQ==", $type : "00" } *)
var
  Token: TToken;
  Base64, Bytes: TBytes;
  SubType: TgoBsonBinarySubType;
begin
  VerifyToken(':');

  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);

  Base64 := TEncoding.ANSI.GetBytes(Token.StringValue);
  Bytes := goBase64Decode(Base64);

  VerifyToken(',');
  VerifyString('$type');
  VerifyToken(':');

  PopToken(Token);
  if (Token.TokenType = TTokenType.String) then
    SubType := TgoBsonBinarySubType(StrToInt('$' + Token.StringValue))
  else if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
    SubType := TgoBsonBinarySubType(Token.Int32Value)
  else
    raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);

  VerifyToken('}');
  Result := TgoBsonBinaryData.Create(Bytes, SubType);
end;

function TgoJsonReader.ParseExtendedJsonDateTime: TgoBsonValue;
(* { $date : -9223372036854775808 }
   { $date : { $numberLong : 9223372036854775807 } }
   { $date : { $numberLong : "-9223372036854775808" } }
   { $date : "1970-01-01T00:00:00Z" }
   { $date : "1970-01-01T00:00:00.000Z" } *)
var
  Token: TToken;
  MillisecondsSinceEpoch: Int64;
  DateTime: TDateTime;
begin
  VerifyToken(':');

  PopToken(Token);
  if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
    MillisecondsSinceEpoch := Token.Int64Value
  else if (Token.TokenType = TTokenType.String) then
  begin
    if (not TryISO8601ToDate(Token.StringValue, DateTime, True)) then
      raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);
    MillisecondsSinceEpoch := goDateTimeToMillisecondsSinceEpoch(DateTime, True);
  end
  else if (Token.TokenType = TTokenType.BeginObject) then
  begin
    VerifyString('$numberLong');
    VerifyToken(':');
    PopToken(Token);
    if (Token.TokenType = TTokenType.String) then
    begin
      if (not TryStrToInt64(Token.StringValue, MillisecondsSinceEpoch)) then
        raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);
    end
    else if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
      MillisecondsSinceEpoch := Token.Int64Value
    else
      raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);
    VerifyToken('}');
  end
  else
    raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);

  VerifyToken('}');
  Result := TgoBsonDateTime.Create(MillisecondsSinceEpoch);
end;

function TgoJsonReader.ParseExtendedJsonJavaScript(
  out AValue: TgoBsonValue): TgoBsonType;
(* { "$code" : "function f() { return 1; }" }
   { "$code" : "function f() { return 1; }" , "$scope" : {...} } *)
var
  Token: TToken;
  Code: String;
begin
  VerifyToken(':');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  Code := Token.StringValue;

  PopToken(Token);
  case Token.TokenType of
    TTokenType.Comma:
      begin
        VerifyString('$scope');
        VerifyToken(':');
        State := TgoBsonReaderState.Value;
        AValue := Code;
        Result := TgoBsonType.JavaScriptWithScope;
      end;

    TTokenType.EndObject:
      begin
        AValue := Code;
        Result := TgoBsonType.JavaScript;
      end;
  else
    raise FBuffer.ParseError(@RS_BSON_COMMA_OR_CLOSE_BRACE_EXPECTED);
  end;
end;

function TgoJsonReader.ParseExtendedJsonMaxKey: TgoBsonValue;
(* { $maxKey : 1 }
   { $maxkey : 1 } *)
begin
  VerifyToken(':');
  VerifyToken('1');
  VerifyToken('}');
  Result := TgoBsonMaxKey.Value;
end;

function TgoJsonReader.ParseExtendedJsonMinKey: TgoBsonValue;
(* { $minKey : 1 }
   { $minkey : 1 } *)
begin
  VerifyToken(':');
  VerifyToken('1');
  VerifyToken('}');
  Result := TgoBsonMinKey.Value;
end;

function TgoJsonReader.ParseExtendedJsonNumberLong: TgoBsonValue;
(* { $numberLong: 42 }
   { $numberLong: "42" } *)
var
  Token: TToken;
begin
  VerifyToken(':');
  PopToken(Token);
  if (Token.TokenType = TTokenType.String) then
    Result := StrToInt64(Token.StringValue)
  else if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
    Result := Token.Int64Value
  else
    raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);
  VerifyToken('}');
end;

function TgoJsonReader.ParseExtendedJsonObjectId: TgoBsonValue;
// { $oid : "0102030405060708090a0b0c" }
var
  Token: TToken;
begin
  VerifyToken(':');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  VerifyToken('}');
  Result := TgoObjectId.Create(Token.StringValue);
end;

function TgoJsonReader.ParseExtendedJsonRegularExpression: TgoBsonValue;
(* { $regex : "abc" }
   { $regex : "abc", $options : "i" } *)
var
  Token: TToken;
  Pattern, Options: String;
begin
  VerifyToken(':');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  Pattern := Token.StringValue;
  Options := '';

  PopToken(Token);
  if (Token.TokenType = TTokenType.Comma) then
  begin
    VerifyString('$options');
    VerifyToken(':');
    PopToken(Token);
    if (Token.TokenType <> TTokenType.String) then
      raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
    Options := Token.StringValue;
  end
  else
    PushToken(Token);

  VerifyToken('}');
  Result := TgoBsonRegularExpression.Create(Pattern, Options);
end;

function TgoJsonReader.ParseExtendedJsonSymbol: TgoBsonValue;
(* { "$symbol" : "symbol" } *)
var
  Token: TToken;
begin
  VerifyToken(':');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  VerifyToken('}');
  Result := Token.StringValue; // Will be converted to a TgoBsonSymbol later
end;

function TgoJsonReader.ParseExtendedJsonTimestamp: TgoBsonValue;
(* { $timestamp : { t : 1, i : 2 } } // New
   { $timestamp : 123 }              // Old
   { $timestamp : NumberLong(123) }  // Old *)
var
  Token: TToken;
begin
  VerifyToken(':');
  PopToken(Token);
  if (Token.TokenType = TTokenType.BeginObject) then
    Result := ParseExtendedJsonTimestampNew
  else
    Result := ParseExtendedJsonTimestampOld(Token);
end;

function TgoJsonReader.ParseExtendedJsonTimestampNew: TgoBsonValue;
(* { $timestamp : { t : 1, i : 2 } } *)
var
  Token: TToken;
  SecondsSinceEpoch, Increment: Integer;
begin
  VerifyString('t');
  VerifyToken(':');

  PopToken(Token);
  if (Token.TokenType = TTokenType.Int32) then
    SecondsSinceEpoch := Token.Int32Value
  else
    raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);

  VerifyToken(',');
  VerifyString('i');
  VerifyToken(':');

  PopToken(Token);
  if (Token.TokenType = TTokenType.Int32) then
    Increment := Token.Int32Value
  else
    raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);

  VerifyToken('}');
  VerifyToken('}');
  Result := TgoBsonTimestamp.Create(SecondsSinceEpoch, Increment);
end;

function TgoJsonReader.ParseExtendedJsonTimestampOld(
  const AValueToken: TToken): TgoBsonValue;
(* { $timestamp : 123 }
   { $timestamp : NumberLong(123) } *)
var
  Value: Int64;
begin
  if (AValueToken.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
    Value := AValueToken.Int64Value
  else if (AValueToken.TokenType = TTokenType.UnquotedString)
    and (AValueToken.Lexeme = 'NumberLong')
  then
    Value := ParseConstructorNumberLong.AsInt64
  else
    raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);

  VerifyToken('}');
  Result := TgoBsonTimestamp.Create(Value);
end;

function TgoJsonReader.ParseExtendedJsonUndefined: TgoBsonValue;
(* { $undefined : true } *)
begin
  VerifyToken(':');
  VerifyToken('true');
  VerifyToken('}');
  Result := TgoBsonUndefined.Value;
end;

function TgoJsonReader.ParseNew(out AValue: TgoBsonValue): TgoBsonType;
var
  Token: TToken;
  S: String;
begin
  PopToken(Token);
  if (Token.TokenType <> TTokenType.UnquotedString) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);

  S := Token.Lexeme;
  Assert(S <> '');
  case S.Chars[0] of
    'B': if (S = 'BinData') then
         begin
           AValue := ParseConstructorBinaryData;
           Exit(TgoBsonType.Binary);
         end;

    'C': if (S = 'CSUUID') or (S = 'CSGUID') then
         begin
           AValue := ParseConstructorUUID(S);
           Exit(TgoBsonType.DateTime);
         end;

    'D': if (S = 'Date') then
         begin
           AValue := ParseConstructorDateTime(True);
           Exit(TgoBsonType.DateTime);
         end;

    'G': if (S = 'GUID') then
         begin
           AValue := ParseConstructorUUID(S);
           Exit(TgoBsonType.DateTime);
         end;

    'H': if (S = 'HexData') then
         begin
           AValue := ParseConstructorHexData;
           Exit(TgoBsonType.Binary);
         end;

    'I': if (S = 'ISODate') then
         begin
           AValue := ParseConstructorISODateTime;
           Exit(TgoBsonType.DateTime);
         end;

    'J': if (S = 'JUUID') or (S = 'JGUID') then
         begin
           AValue := ParseConstructorUUID(S);
           Exit(TgoBsonType.DateTime);
         end;

    'N': if (S = 'NumberInt') then
         begin
           AValue := ParseConstructorNumber;
           Exit(TgoBsonType.Int32);
         end
         else if (S = 'NumberLong') then
         begin
           AValue := ParseConstructorNumberLong;
           Exit(TgoBsonType.Int64);
         end;

    'O': if (S = 'ObjectId') then
         begin
           AValue := ParseConstructorObjectId;
           Exit(TgoBsonType.ObjectId);
         end;

    'P': if (S = 'PYUUID') or (S = 'PYGUID') then
         begin
           AValue := ParseConstructorUUID(S);
           Exit(TgoBsonType.DateTime);
         end;

    'T': if (S = 'Timestamp') then
         begin
           AValue := ParseConstructorTimestamp;
           Exit(TgoBsonType.Timestamp);
         end;

    'U': if (S = 'UUID') then
         begin
           AValue := ParseConstructorUUID(S);
           Exit(TgoBsonType.DateTime);
         end;
  end;

  raise FBuffer.ParseError(@RS_BSON_INVALID_NEW_STATEMENT);
end;

procedure TgoJsonReader.PopContext;
begin
  Dec(FContextIndex);
  if (FContextIndex < 0) then
  begin
    FContext := nil;
    FContextIndex := -1;
  end
  else
    FContext := @FContextStack[FContextIndex];
end;

procedure TgoJsonReader.PopToken(out AToken: TToken);
begin
  if FHasPushedToken then
  begin
    AToken := FPushedToken;
    FHasPushedToken := False;
  end
  else
    TScanner.GetNextToken(FBuffer, AToken);
end;

procedure TgoJsonReader.PushContext(const AContextType: TgoBsonContextType);
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);
  FContextStack[FContextIndex].Initialize(AContextType);
  FContext := @FContextStack[FContextIndex];
end;

procedure TgoJsonReader.PushToken(const AToken: TToken);
begin
  if (FHasPushedToken) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  FPushedToken := AToken;
  FHasPushedToken := True;
end;

function TgoJsonReader.ReadBinaryData: TgoBsonBinaryData;
begin
  VerifyBsonType(TgoBsonType.Binary);
  State := GetNextState;
  Result := FCurrentValue.AsBsonBinaryData;
end;

function TgoJsonReader.ReadBoolean: Boolean;
begin
  VerifyBsonType(TgoBsonType.Boolean);
  State := GetNextState;
  Result := FCurrentValue.AsBoolean;
end;

function TgoJsonReader.ReadBsonType: TgoBsonType;
var
  Token: TToken;
  NoValueFound: Boolean;
  S: String;
begin
  Assert(Assigned(FContext));

  if (State in [TgoBsonReaderState.Initial, TgoBsonReaderState.ScopeDocument]) then
    State := TgoBsonReaderState.&Type;

  if (State <> TgoBsonReaderState.&Type) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  if (FContext.ContextType = TgoBsonContextType.Document) then
  begin
    PopToken(Token); // Name
    case Token.TokenType of
      TTokenType.String,
      TTokenType.UnquotedString:
        CurrentName := Token.StringValue;

      TTokenType.EndObject:
        begin
          State := TgoBsonReaderState.EndOfDocument;
          Exit(TgoBsonType.EndOfDocument);
        end;
    else
      raise FBuffer.ParseError(@RS_BSON_STRING_OR_CLOSE_BRACE_EXPECTED);
    end;

    PopToken(Token); // Colon
    if (Token.TokenType <> TTokenType.Colon) then
      raise FBuffer.ParseError(@RS_BSON_COLON_EXPECTED);
  end;

  PopToken(Token); // Value
  if (FContext.ContextType = TgoBsonContextType.&Array)
    and (Token.TokenType = TTokenType.EndArray) then
  begin
    State := TgoBsonReaderState.EndOfArray;
    Exit(TgoBsonType.EndOfDocument);
  end;

  NoValueFound := False;
  case Token.TokenType of
    TTokenType.BeginArray:
      CurrentBsonType := TgoBsonType.&Array;

    TTokenType.BeginObject:
      CurrentBsonType := ParseExtendedJson;

    TTokenType.Double:
      begin
        CurrentBsonType := TgoBsonType.Double;
        FCurrentValue := Token.DoubleValue;
      end;

    TTokenType.EndOfFile:
      CurrentBsonType := TgoBsonType.EndOfDocument;

    TTokenType.Int32:
      begin
        CurrentBsonType := TgoBsonType.Int32;
        FCurrentValue := Token.Int32Value;
      end;

    TTokenType.Int64:
      begin
        CurrentBsonType := TgoBsonType.Int64;
        FCurrentValue := Token.Int64Value;
      end;

    TTokenType.RegularExpression:
      begin
        CurrentBsonType := TgoBsonType.RegularExpression;
        FCurrentValue := Token.RegExValue;
      end;

    TTokenType.String:
      begin
        CurrentBsonType := TgoBsonType.String;
        FCurrentValue := Token.StringValue;
      end;

    TTokenType.UnquotedString:
      begin
        S := Token.Lexeme;
        Assert(S <> '');
        case S.Chars[0] of
          'B': if (S = 'BinData') then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 FCurrentValue := ParseConstructorBinaryData;
               end
               else
                 NoValueFound := True;

          'C': if (S = 'CSUUID') or (S = 'CSGUID') then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 FCurrentValue := ParseConstructorUUID(S);
               end
               else
                 NoValueFound := True;

          'D': if (S = 'Date') then
               begin
                 { This is the Date() function (without arguments).
                   It should return the current datetime (in UTC) as a
                   JavaScript formatted datetime string. }
                 CurrentBsonType := TgoBsonType.String;
                 FCurrentValue := ParseConstructorDateTime(False);
               end
               else
                 NoValueFound := True;

          'G': if (S = 'GUID') then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 FCurrentValue := ParseConstructorUUID(Token.Lexeme);
               end
               else
                 NoValueFound := True;

          'H': if (S = 'HexData') then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 FCurrentValue := ParseConstructorHexData;
               end
               else
                 NoValueFound := True;

          'I': if (S = 'Infinity') then
               begin
                 CurrentBsonType := TgoBsonType.Double;
                 FCurrentValue := Infinity;
               end
               else if (S = 'ISODate') then
               begin
                 CurrentBsonType := TgoBsonType.DateTime;
                 FCurrentValue := ParseConstructorISODateTime;
               end
               else
                 NoValueFound := True;

          'J': if (S = 'JUUID') or (S = 'JGUID') then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 FCurrentValue := ParseConstructorUUID(Token.Lexeme);
               end
               else
                 NoValueFound := True;

          'M': if (S = 'MaxKey') then
               begin
                 CurrentBsonType := TgoBsonType.MaxKey;
                 FCurrentValue := TgoBsonMaxKey.Value;
               end
               else if (S = 'MinKey') then
               begin
                 CurrentBsonType := TgoBsonType.MinKey;
                 FCurrentValue := TgoBsonMinKey.Value;
               end
               else
                 NoValueFound := True;

          'N': if (S = 'NaN') then
               begin
                 CurrentBsonType := TgoBsonType.Double;
                 FCurrentValue := NaN;
               end
               else if (S = 'Number') or (S = 'NumberInt') then
               begin
                 CurrentBsonType := TgoBsonType.Int32;
                 FCurrentValue := ParseConstructorNumber;
               end
               else if (S = 'NumberLong') then
               begin
                 CurrentBsonType := TgoBsonType.Int64;
                 FCurrentValue := ParseConstructorNumberLong;
               end
               else
                 NoValueFound := True;

          'O': if (S = 'ObjectId') then
               begin
                 CurrentBsonType := TgoBsonType.ObjectId;
                 FCurrentValue := ParseConstructorObjectId;
               end
               else
                 NoValueFound := True;

          'P': if (S = 'PYUUID') or (S = 'PYGUID') then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 FCurrentValue := ParseConstructorUUID(Token.Lexeme);
               end
               else
                 NoValueFound := True;

          'R': if (S = 'RegExp') then
               begin
                 CurrentBsonType := TgoBsonType.RegularExpression;
                 FCurrentValue := ParseConstructorRegularExpression;
               end
               else
                 NoValueFound := True;

          'T': if (S = 'Timestamp') then
               begin
                 CurrentBsonType := TgoBsonType.Timestamp;
                 FCurrentValue := ParseConstructorTimestamp;
               end
               else
                 NoValueFound := True;

          'U': if (S = 'UUID') then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 FCurrentValue := ParseConstructorUUID(Token.Lexeme);
               end
               else
                 NoValueFound := True;

          'f': if (S = 'false') then
               begin
                 CurrentBsonType := TgoBsonType.Boolean;
                 FCurrentValue := False;
               end
               else
                 NoValueFound := True;

          'n': if (S = 'new') then
                 CurrentBsonType := ParseNew(FCurrentValue)
               else if (S = 'null') then
                 CurrentBsonType := TgoBsonType.Null
               else
                 NoValueFound := True;

          't': if (S = 'true') then
               begin
                 CurrentBsonType := TgoBsonType.Boolean;
                 FCurrentValue := True;
               end
               else
                 NoValueFound := True;

          'u': if (S = 'undefined') then
                 CurrentBsonType := TgoBsonType.Undefined
               else
                 NoValueFound := True;
        else
          NoValueFound := True;
        end;
      end
  else
    NoValueFound := True;
  end;

  if (NoValueFound) then
    raise FBuffer.ParseError(@RS_BSON_INVALID_EXTENDED_JSON);

  FCurrentToken := Token;

  if (FContext.ContextType in [TgoBsonContextType.&Array, TgoBsonContextType.Document]) then
  begin
    PopToken(Token); // Comma
    if (Token.TokenType <> TTokenType.Comma) then
      PushToken(Token);
  end;

  case FContext.ContextType of
    TgoBsonContextType.Document,
    TgoBsonContextType.ScopeDocument:
      State := TgoBsonReaderState.Name;

    TgoBsonContextType.&Array,
    TgoBsonContextType.JavaScriptWithScope,
    TgoBsonContextType.TopLevel:
      State := TgoBsonReaderState.Value;
  end;

  Result := CurrentBsonType;
end;

function TgoJsonReader.ReadBytes: TBytes;
var
  BinaryData: TgoBsonBinaryData;
begin
  VerifyBsonType(TgoBsonType.Binary);
  State := GetNextState;
  BinaryData := FCurrentValue.AsBsonBinaryData;

  if (not (BinaryData.SubType in [TgoBsonBinarySubType.Binary, TgoBsonBinarySubType.OldBinary])) then
    raise FBuffer.ParseError(@RS_BSON_INVALID_BINARY_TYPE);

  Result := BinaryData.AsBytes;
end;

function TgoJsonReader.ReadDateTime: Int64;
begin
  VerifyBsonType(TgoBsonType.DateTime);
  State := GetNextState;
  Result := FCurrentValue.AsBsonDateTime.MillisecondsSinceEpoch;
end;

function TgoJsonReader.ReadDouble: Double;
begin
  VerifyBsonType(TgoBsonType.Double);
  State := GetNextState;
  Result := FCurrentValue.AsDouble;
end;

procedure TgoJsonReader.ReadEndArray;
var
  CommaToken: TToken;
begin
  Assert(Assigned(FContext));
  if (FContext.ContextType <> TgoBsonContextType.&Array) then
    raise FBuffer.ParseError(@RS_BSON_CLOSE_BRACKET_EXPECTED);

  if (State = TgoBsonReaderState.&Type) then
    ReadBsonType;

  if (State <> TgoBsonReaderState.EndOfArray) then
    raise FBuffer.ParseError(@RS_BSON_CLOSE_BRACKET_EXPECTED);

  PopContext;
  if (FContext = nil) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  case FContext.ContextType of
    TgoBsonContextType.&Array,
    TgoBsonContextType.Document:
      begin
        State := TgoBsonReaderState.&Type;
        PopToken(CommaToken);
        if (CommaToken.TokenType <> TTokenType.Comma) then
          PushToken(CommaToken);
      end;

    TgoBsonContextType.TopLevel:
      State := TgoBsonReaderState.Initial;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

procedure TgoJsonReader.ReadEndDocument;
var
  CommaToken: TToken;
begin
  Assert(Assigned(FContext));
  if (not (FContext.ContextType in [TgoBsonContextType.Document, TgoBsonContextType.ScopeDocument])) then
    raise FBuffer.ParseError(@RS_BSON_CLOSE_BRACE_EXPECTED);

  if (State = TgoBsonReaderState.&Type) then
    ReadBsonType;

  if (State <> TgoBsonReaderState.EndOfDocument) then
    raise FBuffer.ParseError(@RS_BSON_CLOSE_BRACE_EXPECTED);

  PopContext;
  if (FContext = nil) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  if (FContext.ContextType = TgoBsonContextType.JavaScriptWithScope) then
  begin
    PopContext;
    if (FContext = nil) then
      raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
    VerifyToken('}');
  end;

  case FContext.ContextType of
    TgoBsonContextType.&Array,
    TgoBsonContextType.Document:
      begin
        State := TgoBsonReaderState.&Type;
        PopToken(CommaToken);
        if (CommaToken.TokenType <> TTokenType.Comma) then
          PushToken(CommaToken);
      end;

    TgoBsonContextType.TopLevel:
      State := TgoBsonReaderState.Initial;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

function TgoJsonReader.ReadInt32: Integer;
begin
  VerifyBsonType(TgoBsonType.Int32);
  State := GetNextState;
  Result := FCurrentValue.AsInteger;
end;

function TgoJsonReader.ReadInt64: Int64;
begin
  VerifyBsonType(TgoBsonType.Int64);
  State := GetNextState;
  Result := FCurrentValue.AsInt64;
end;

function TgoJsonReader.ReadJavaScript: String;
begin
  VerifyBsonType(TgoBsonType.JavaScript);
  State := GetNextState;
  Result := FCurrentValue.AsString;
end;

function TgoJsonReader.ReadJavaScriptWithScope: String;
begin
  VerifyBsonType(TgoBsonType.JavaScriptWithScope);
  PushContext(TgoBsonContextType.JavaScriptWithScope);
  State := TgoBsonReaderState.ScopeDocument;
  Result := FCurrentValue.AsString;
end;

procedure TgoJsonReader.ReadMaxKey;
begin
  VerifyBsonType(TgoBsonType.MaxKey);
  State := GetNextState;
end;

procedure TgoJsonReader.ReadMinKey;
begin
  VerifyBsonType(TgoBsonType.MinKey);
  State := GetNextState;
end;

function TgoJsonReader.ReadName: String;
begin
  if (State = TgoBsonReaderState.&Type) then
    ReadBsonType;

  if (State <> TgoBsonReaderState.Name) then
    raise FBuffer.ParseError(@RS_BSON_QUOTE_EXPECTED);

  State := TgoBsonReaderState.Value;
  Result := CurrentName;
end;

procedure TgoJsonReader.ReadNull;
begin
  VerifyBsonType(TgoBsonType.Null);
  State := GetNextState;
end;

function TgoJsonReader.ReadObjectId: TgoObjectId;
begin
  VerifyBsonType(TgoBsonType.ObjectId);
  State := GetNextState;
  Result := FCurrentValue.AsObjectId;
end;

function TgoJsonReader.ReadRegularExpression: TgoBsonRegularExpression;
begin
  VerifyBsonType(TgoBsonType.RegularExpression);
  State := GetNextState;
  Result := FCurrentValue.AsBsonRegularExpression;
end;

procedure TgoJsonReader.ReadStartArray;
begin
  VerifyBsonType(TgoBsonType.&Array);
  PushContext(TgoBsonContextType.&Array);
  State := TgoBsonReaderState.&Type;
end;

procedure TgoJsonReader.ReadStartDocument;
begin
  VerifyBsonType(TgoBsonType.Document);
  PushContext(TgoBsonContextType.Document);
  State := TgoBsonReaderState.&Type;
end;

function TgoJsonReader.ReadString: String;
begin
  VerifyBsonType(TgoBsonType.String);
  State := GetNextState;
  Result := FCurrentValue.AsString;
end;

function TgoJsonReader.ReadSymbol: String;
begin
  VerifyBsonType(TgoBsonType.Symbol);
  State := GetNextState;
  Result := FCurrentValue.AsString;
end;

function TgoJsonReader.ReadTimestamp: Int64;
begin
  VerifyBsonType(TgoBsonType.Timestamp);
  State := GetNextState;
  Result := FCurrentValue.AsBsonTimestamp.Value;
end;

procedure TgoJsonReader.ReadUndefined;
begin
  VerifyBsonType(TgoBsonType.Undefined);
  State := GetNextState;
end;

procedure TgoJsonReader.ReturnToBookmark(
  const ABookmark: IgoBsonReaderBookmark);
var
  BM: TJsonBookmark;
begin
  Assert(Assigned(ABookmark));
  Assert(ABookmark is TJsonBookmark);
  BM := TJsonBookmark(ABookmark);
  State := BM.State;
  CurrentBsonType := BM.CurrentBsonType;
  CurrentName := BM.CurrentName;
  FContextIndex := BM.ContextIndex;
  Assert((FContextIndex >= 0) and (FContextIndex < Length(FContextStack)));
  FContext := @FContextStack[FContextIndex];
  FCurrentToken := BM.CurrentToken;
  FCurrentValue := BM.CurrentValue;
  FPushedToken := BM.PushedToken;
  FBuffer.Current := BM.Current;
  FHasPushedToken := BM.HasPushedToken;
end;

procedure TgoJsonReader.SkipName;
begin
  if (State <> TgoBsonReaderState.Name) then
    raise FBuffer.ParseError(@RS_BSON_QUOTE_EXPECTED);

  State := TgoBsonReaderState.Value;
end;

procedure TgoJsonReader.SkipValue;
begin
  if (State <> TgoBsonReaderState.Value) then
    raise FBuffer.ParseError(@RS_BSON_INVALID_READER_STATE);

  case CurrentBsonType of
    TgoBsonType.&Array:
      begin
        ReadStartArray;
        while (ReadBsonType <> TgoBsonType.EndOfDocument) do
          SkipValue;
        ReadEndArray;
      end;

    TgoBsonType.Binary: ReadBinaryData;
    TgoBsonType.Boolean: ReadBoolean;
    TgoBsonType.DateTime: ReadDateTime;

    TgoBsonType.Document:
      begin
        ReadStartDocument;
        while (ReadBsonType <> TgoBsonType.EndOfDocument) do
        begin
          SkipName;
          SkipValue;
        end;
        ReadEndDocument;
      end;

    TgoBsonType.Double: ReadDouble;
    TgoBsonType.Int32: ReadInt32;
    TgoBsonType.Int64: ReadInt64;
    TgoBsonType.JavaScript: ReadJavaScript;

    TgoBsonType.JavaScriptWithScope:
      begin
        ReadJavaScriptWithScope;
        ReadStartDocument;
        while (ReadBsonType <> TgoBsonType.EndOfDocument) do
        begin
          SkipName;
          SkipValue;
        end;
        ReadEndDocument;
      end;

    TgoBsonType.MaxKey: ReadMaxKey;
    TgoBsonType.MinKey: ReadMinKey;
    TgoBsonType.Null: ReadNull;
    TgoBsonType.ObjectId: ReadObjectId;
    TgoBsonType.RegularExpression: ReadRegularExpression;
    TgoBsonType.String: ReadString;
    TgoBsonType.Symbol: ReadSymbol;
    TgoBsonType.Timestamp: ReadTimestamp;
    TgoBsonType.Undefined: ReadUndefined;
  else
    raise FBuffer.ParseError(@RS_BSON_INVALID_READER_STATE);
  end;
end;

procedure TgoJsonReader.VerifyString(const AExpectedString: String);
var
  Token: TToken;
begin
  PopToken(Token);
  if (not (Token.TokenType in [TTokenType.String, TTokenType.UnquotedString]))
    or (Token.StringValue <> AExpectedString)
  then
    raise FBuffer.ParseError(@RS_BSON_STRING_WITH_VALUE_EXPECTED, [AExpectedString, Token.StringValue]);
end;

procedure TgoJsonReader.VerifyToken(const AExpectedLexeme: String);
var
  Token: TToken;
begin
  PopToken(Token);
  if (Token.Lexeme <> AExpectedLexeme) then
    raise FBuffer.ParseError(@RS_BSON_TOKEN_EXPECTED, [AExpectedLexeme, Token.Lexeme]);
end;

{ TgoJsonReader.TContext }

procedure TgoJsonReader.TContext.Initialize(
  const AContextType: TgoBsonContextType);
begin
  FContextType := AContextType;
end;

{ TgoJsonReader.TBuffer }

procedure TgoJsonReader.TBuffer.ClearErrorPos;
begin
  FErrorPos := nil;
end;

class function TgoJsonReader.TBuffer.Create(const AJson: String): TBuffer;
begin
  Result.FJson := AJson;
  Result.FBuffer := @Result.FJson[Low(String)];
  Result.FCurrent := Result.FBuffer;
  Result.FEof := (Result.FCurrent = nil);
  Result.FLineStart := Result.FBuffer;
  Result.FPrevLineStart := Result.FBuffer;
  Result.FLineNumber := 1;
end;

function TgoJsonReader.TBuffer.ParseError(
  const AMsg: PResStringRec): EgoJsonParserError;
begin
  Result := ParseError(LoadResString(AMsg));
end;

function TgoJsonReader.TBuffer.ParseError(const AMsg: String): EgoJsonParserError;
var
  ColumnNumber, Position: Integer;
  ErrorPos, TextStart: PWideChar;
begin
  if Assigned(FErrorPos) then
    ErrorPos := FErrorPos
  else
    ErrorPos := FCurrent;
  FErrorPos := nil;

  if (ErrorPos = nil) then
  begin
    ColumnNumber := 1;
    Position := 0;
  end
  else
  begin
    TextStart := FBuffer;
    ColumnNumber := ErrorPos - FLineStart;
    Position := ErrorPos - TextStart;
  end;
  Result := EgoJsonParserError.Create(AMsg, FLineNumber, ColumnNumber, Position);
end;

procedure TgoJsonReader.TBuffer.MarkErrorPos;
begin
  FErrorPos := FCurrent;
end;

function TgoJsonReader.TBuffer.ParseError(const AMsg: String;
  const AArgs: array of const): EgoJsonParserError;
begin
  Result := ParseError(Format(AMsg, AArgs));
end;

function TgoJsonReader.TBuffer.ParseError(const AMsg: PResStringRec;
  const AArgs: array of const): EgoJsonParserError;
begin
  Result := ParseError(Format(LoadResString(AMsg), AArgs));
end;

function TgoJsonReader.TBuffer.Read: Char;
begin
  if (FEof) then
    Exit(#0);

  Result := FCurrent^;
  Inc(FCurrent);

  if (Result = #10) then
  begin
    Inc(FLineNumber);
    FPrevLineStart := FLineStart;
    FLineStart := FCurrent;
  end;

  FEof := (Result = #0);
end;

procedure TgoJsonReader.TBuffer.Unread(const AChar: Char);
begin
  if (FCurrent = FBuffer) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  if ((FCurrent - 1)^ <> AChar) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  Dec(FCurrent);

  if (AChar = #10) then
  begin
    Dec(FLineNumber);
    FLineStart := FPrevLineStart;
  end;

  FEof := False;
end;

{ TgoJsonReader.TScanner }

class procedure TgoJsonReader.TScanner.GetNextToken(const ABuffer: TBuffer;
  out AToken: TToken);
var
  C: Char;
  Error: EgoJsonParserError;
begin
  C := ABuffer.Read;
  while (C <> #0) and (IsWhitespace(C)) do
    C := ABuffer.Read;

  ABuffer.MarkErrorPos;

  if (C = #0) then
  begin
    AToken.Initialize(TTokenType.EndOfFile, '<eof>');
    Exit;
  end;

  case C of
    '{': AToken.Initialize(TTokenType.BeginObject, '{');
    '}': AToken.Initialize(TTokenType.EndObject, '}');
    '[': AToken.Initialize(TTokenType.BeginArray, '[');
    ']': AToken.Initialize(TTokenType.EndArray, ']');
    '(': AToken.Initialize(TTokenType.LeftParen, '(');
    ')': AToken.Initialize(TTokenType.RightParen, ')');
    ':': AToken.Initialize(TTokenType.Colon, ':');
    ',': AToken.Initialize(TTokenType.Comma, ',');
    '''', '"': GetStringToken(ABuffer, C, AToken);
    '/': GetRegularExpressionToken(ABuffer, AToken);
    '0'..'9','-': GetNumberToken(ABuffer, C, AToken);
    '$', '_': GetUnquotedStringToken(ABuffer, AToken);
  else
    if (C.IsLetter) then
      GetUnquotedStringToken(ABuffer, AToken)
    else
    begin
      ABuffer.ClearErrorPos;
      Error := ABuffer.ParseError(@RS_BSON_UNEXPECTED_TOKEN);
      ABuffer.Unread(C);
      raise Error;
    end;
  end;
end;

class procedure TgoJsonReader.TScanner.GetNumberToken(const ABuffer: TBuffer;
  const AFirstChar: Char; out AToken: TToken);
const
  NFINITY = 'nfinity';
var
  C: Char;
  Start: PChar;
  State: TNumberState;
  TokenType: TTokenType;
  SawMinusInfinity: Boolean;
  Lexeme: String;
  I: Integer;
  ValueDouble: Double;
  ValueInt32: Int32;
  ValueInt64: Int64;
begin
  ABuffer.ClearErrorPos;
  Start := ABuffer.Current - 1;
  case AFirstChar of
    '-': State := TNumberState.SawLeadingMinus;
    '0': State := TNumberState.SawLeadingZero;
  else
    State := TNumberState.SawIntegerDigits;
  end;

  TokenType := TTokenType.Int64;

  while True do
  begin
    C := ABuffer.Read;
    case State of
      TNumberState.SawLeadingMinus:
        case C of
          '0': State := TNumberState.SawLeadingZero;
          'I': State := TNumberState.SawMinusI;
          '1'..'9': State := TNumberState.SawIntegerDigits;
        else
          State := TNumberState.Invalid;
        end;

      TNumberState.SawLeadingZero:
        case C of
          '.': State := TNumberState.SawDecimalPoint;
          'e', 'E': State := TNumberState.SawExponentLetter;
          ',', '}', ']', ')', #0: State := TNumberState.Done;
        else
          if IsWhiteSpace(C) then
            State := TNumberState.Done
          else
            State := TNumberState.Invalid;
        end;

      TNumberState.SawIntegerDigits:
        case C of
          '.': State := TNumberState.SawDecimalPoint;
          'e', 'E': State := TNumberState.SawExponentLetter;
          ',', '}', ']', ')', #0: State := TNumberState.Done;
          '0'..'9': State := TNumberState.SawIntegerDigits;
        else
          if IsWhiteSpace(C) then
            State := TNumberState.Done
          else
            State := TNumberState.Invalid;
        end;

      TNumberState.SawDecimalPoint:
        begin
          TokenType := TTokenType.Double;
          if (C >= '0') and (C <= '9') then
            State := TNumberState.SawFractionDigits
          else
            State := TNumberState.Invalid;
        end;

      TNumberState.SawFractionDigits:
        case C of
          'e', 'E': State := TNumberState.SawExponentLetter;
          ',', '}', ']', ')', #0: State := TNumberState.Done;
          '0'..'9': State := TNumberState.SawFractionDigits;
        else
          if IsWhiteSpace(C) then
            State := TNumberState.Done
          else
            State := TNumberState.Invalid;
        end;

      TNumberState.SawExponentLetter:
        begin
          TokenType := TTokenType.Double;
          case C of
            '+', '-': State := TNumberState.SawExponentSign;
            '0'..'9': State := TNumberState.SawExponentDigits;
          else
            State := TNumberState.Invalid;
          end;
        end;

      TNumberState.SawExponentSign:
        if (C >= '0') and (C <= '9') then
          State := TNumberState.SawExponentDigits
        else
          State := TNumberState.Invalid;

      TNumberState.SawExponentDigits:
        case C of
          ',', '}', ']', ')', #0: State := TNumberState.Done;
          '0'..'9': State := TNumberState.SawExponentDigits;
        else
          if IsWhiteSpace(C) then
            State := TNumberState.Done
          else
            State := TNumberState.Invalid;
        end;

      TNumberState.SawMinusI:
        begin
          SawMinusInfinity := True;
          for I := 0 to Length(NFINITY) - 1 do
          begin
            if (C <> NFINITY.Chars[I]) then
            begin
              SawMinusInfinity := False;
              Break;
            end;
            C := ABuffer.Read;
          end;

          if (SawMinusInfinity) then
          begin
            TokenType := TTokenType.Double;
            case C of
              ',', '}', ']', ')', #0: State := TNumberState.Done;
            else
              if IsWhiteSpace(C) then
                State := TNumberState.Done
              else
                State := TNumberState.Invalid;
            end;
          end
          else
            State := TNumberState.Invalid;
        end;
    end;

    case State of
      TNumberState.Done:
        begin
          ABuffer.Unread(C);
          SetString(Lexeme, Start, ABuffer.Current - Start);
          if (TokenType = TTokenType.Double) then
          begin
            if (Lexeme = '-Infinity') then
              ValueDouble := NegInfinity
            else
              ValueDouble := StrToFloat(Lexeme, goUSFormatSettings);
            AToken.Initialize(Lexeme, ValueDouble);
          end
          else
          begin
            ValueInt64 := StrToInt64(Lexeme);
            if (ValueInt64 < Integer.MinValue) or (ValueInt64 > Integer.MaxValue) then
              AToken.Initialize(Lexeme, ValueInt64)
            else
            begin
              ValueInt32 := ValueInt64;
              AToken.Initialize(Lexeme, ValueInt32);
            end;
          end;
          Exit;
        end;

      TNumberState.Invalid:
        raise ABuffer.ParseError(@RS_BSON_INVALID_NUMBER);
    end;
  end;
end;

class procedure TgoJsonReader.TScanner.GetRegularExpressionToken(
  const ABuffer: TBuffer; out AToken: TToken);
var
  Start: PChar;
  State: TRegularExpressionState;
  Lexeme: String;
  Regex: TgoBsonRegularExpression;
  C: Char;
begin
  ABuffer.ClearErrorPos;
  Start := ABuffer.Current - 1;
  State := TRegularExpressionState.InPattern;
  while True do
  begin
    C := ABuffer.Read;
    case State of
      TRegularExpressionState.InPattern:
        case C of
          '/': State := TRegularExpressionState.InOptions;
          '\': State := TRegularExpressionState.InEscapeSequence;
        else
          State := TRegularExpressionState.InPattern;
        end;

      TRegularExpressionState.InEscapeSequence:
        State := TRegularExpressionState.InPattern;

      TRegularExpressionState.InOptions:
        case C of
          'i', 'm', 'x', 's': State := TRegularExpressionState.InOptions;
          ',', '}', ']', ')', #0: State := TRegularExpressionState.Done;
        else
          if IsWhiteSpace(C) then
            State := TRegularExpressionState.Done
          else
            State := TRegularExpressionState.Invalid;
        end;
    end;

    case State of
      TRegularExpressionState.Done:
        begin
          ABuffer.Unread(C);
          SetString(Lexeme, Start, ABuffer.Current - Start);
          Regex := TgoBsonRegularExpression.Create(Lexeme);
          AToken.Initialize(Lexeme, Regex);
          Exit;
        end;

      TRegularExpressionState.Invalid:
        raise ABuffer.ParseError(@RS_BSON_INVALID_REGEX);
    end;
  end;
end;

class procedure TgoJsonReader.TScanner.GetStringToken(const ABuffer: TBuffer;
  const AQuoteCharacter: Char; out AToken: TToken);
var
  Start: PChar;
  Value: TArray<Char>;
  Capacity, Len, I: Integer;
  C: Char;
  S, Lexeme: String;

  procedure Append(const AChar: Char);
  begin
    if (Len >= Capacity) then
    begin
      Capacity := Capacity * 2;
      SetLength(Value, Capacity);
    end;
    Value[Len] := AChar;
    Inc(Len);
  end;

begin
  ABuffer.ClearErrorPos;
  Start := ABuffer.Current - 1;
  Capacity := 16;
  SetLength(Value, 16);
  Len := 0;
  while True do
  begin
    C := ABuffer.Read;
    if (C = '\') then
    begin
      C := ABuffer.Read;
      case C of
        '''', '"', '\', '/': Append(C);
        'b': Append(#8);
        't': Append(#9);
        'n': Append(#10);
        'f': Append(#12);
        'r': Append(#13);
        'u': begin
               SetLength(S, 5);
               S[Low(String) + 0] := '$';
               S[Low(String) + 1] := ABuffer.Read;
               S[Low(String) + 2] := ABuffer.Read;
               S[Low(String) + 3] := ABuffer.Read;
               C := ABuffer.Read;
               S[Low(String) + 4] := C;
               if (C <> #0) then
               begin
                 I := StrToIntDef(S, -1);
                 if (I < 0) then
                   raise ABuffer.ParseError(@RS_BSON_INVALID_UNICODE_CODEPOINT);
                 Append(Char(I));
               end;
             end;
      else
        if (C <> #0) then
          raise ABuffer.ParseError(@RS_BSON_INVALID_STRING);
      end;
    end
    else if (C = AQuoteCharacter) then
    begin
      SetString(Lexeme, Start, ABuffer.Current - Start);
      Start := @Value[0];
      SetString(S, Start, Len);
      AToken.Initialize(TTokenType.String, Lexeme, S);
      Exit;
    end
    else if (C <> #0) then
      Append(C);

    if (C = #0) then
      raise ABuffer.ParseError(@RS_BSON_INVALID_STRING);
  end;
end;

class procedure TgoJsonReader.TScanner.GetUnquotedStringToken(
  const ABuffer: TBuffer; out AToken: TToken);
var
  Start: PChar;
  C: Char;
  Lexeme: String;
begin
  Start := ABuffer.Current - 1;
  C := ABuffer.Read;
  while (C = '$') or (C = '_') or (C.IsLetterOrDigit) do
    C := ABuffer.Read;
  ABuffer.Unread(C);
  SetString(Lexeme, Start, ABuffer.Current - Start);
  AToken.Initialize(TTokenType.UnquotedString, Lexeme, Lexeme);
end;

class function TgoJsonReader.TScanner.IsWhitespace(const AChar: Char): Boolean;
begin
//  Result := AChar.IsWhitespace; // Official, but slow
  Result := (AChar <= ' ');
end;

{ TgoJsonReader.TToken }

procedure TgoJsonReader.TToken.Initialize(const ATokenType: TTokenType;
  const ALexeme: String);
begin
  FTokenType := ATokenType;
  FLexeme := ALexeme;
end;

procedure TgoJsonReader.TToken.Initialize(const ATokenType: TTokenType;
  const ALexeme, AStringValue: String);
begin
  FTokenType := ATokenType;
  FLexeme := ALexeme;
  FStringValue := AStringValue;
end;

procedure TgoJsonReader.TToken.Initialize(const ALexeme: String;
  const ADoubleValue: Double);
begin
  FTokenType := TTokenType.Double;
  FLexeme := ALexeme;
  FValue.DoubleValue := ADoubleValue;
end;

procedure TgoJsonReader.TToken.Initialize(const ALexeme: String;
  const AInt32Value: Int32);
begin
  FTokenType := TTokenType.Int32;
  FLexeme := ALexeme;
  FValue.Int64Value := AInt32Value; // Clear upper 32 bits
end;

procedure TgoJsonReader.TToken.Initialize(const ALexeme: String;
  const AInt64Value: Int64);
begin
  FTokenType := TTokenType.Int64;
  FLexeme := ALexeme;
  FValue.Int64Value := AInt64Value;
end;

procedure TgoJsonReader.TToken.Initialize(const ALexeme: String;
  const ARegExValue: TgoBsonRegularExpression);
begin
   FTokenType := TTokenType.RegularExpression;
   FLexeme := ALexeme;
   FRegExValue := ARegExValue;
end;

{ TgoJsonReader.TJsonBookmark }

constructor TgoJsonReader.TJsonBookmark.Create(const AState: TgoBsonReaderState;
  const ACurrentBsonType: TgoBsonType; const ACurrentName: String;
  const AContextIndex: Integer; const ACurrentToken: TToken;
  const ACurrentValue: TgoBsonValue; const APushedToken: TToken;
  const AHasPushedToken: Boolean; const ACurrent: PChar);
begin
  inherited Create(AState, ACurrentBsonType, ACurrentName);
  FContextIndex := AContextIndex;
  FCurrentToken := ACurrentToken;
  FCurrentValue := ACurrentValue;
  FPushedToken := APushedToken;
  FCurrent := ACurrent;
  FHasPushedToken := AHasPushedToken;
end;

{ TgoBsonDocumentReader }

constructor TgoBsonDocumentReader.Create(const ADocument: TgoBsonDocument);
begin
  inherited Create;
  FCurrentValue := ADocument;
  FContextIndex := -1;
  PushContext(TgoBsonContextType.TopLevel, ADocument);
end;

function TgoBsonDocumentReader.EndOfStream: Boolean;
begin
  Result := (State = TgoBsonReaderState.Done);
end;

function TgoBsonDocumentReader.GetBookmark: IgoBsonReaderBookmark;
begin
  Assert(Assigned(FContext));
  Result := TDocumentBookmark.Create(State, CurrentBsonType, CurrentName,
    FContextIndex, FContext.Index, FCurrentValue);
end;

function TgoBsonDocumentReader.GetNextState: TgoBsonReaderState;
begin
  Assert(Assigned(FContext));
  case FContext.ContextType of
    TgoBsonContextType.&Array,
    TgoBsonContextType.Document:
      Result := TgoBsonReaderState.&Type;

    TgoBsonContextType.TopLevel:
      Result := TgoBsonReaderState.Done;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

procedure TgoBsonDocumentReader.PopContext;
begin
  Dec(FContextIndex);
  if (FContextIndex < 0) then
  begin
    FContext := nil;
    FContextIndex := -1;
  end
  else
    FContext := @FContextStack[FContextIndex];
end;

procedure TgoBsonDocumentReader.PushContext(
  const AContextType: TgoBsonContextType; const AArray: TgoBsonArray);
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);
  FContextStack[FContextIndex].Initialize(AContextType, AArray);
  FContext := @FContextStack[FContextIndex];
end;

procedure TgoBsonDocumentReader.PushContext(
  const AContextType: TgoBsonContextType; const ADocument: TgoBsonDocument);
begin
  Inc(FContextIndex);
  if (FContextIndex >= Length(FContextStack)) then
    SetLength(FContextStack, FContextIndex + 8);
  FContextStack[FContextIndex].Initialize(AContextType, ADocument);
  FContext := @FContextStack[FContextIndex];
end;

function TgoBsonDocumentReader.ReadBinaryData: TgoBsonBinaryData;
begin
  VerifyBsonType(TgoBsonType.Binary);
  State := GetNextState;
  Result := FCurrentValue.AsBsonBinaryData;
end;

function TgoBsonDocumentReader.ReadBoolean: Boolean;
begin
  VerifyBsonType(TgoBsonType.Boolean);
  State := GetNextState;
  Result := FCurrentValue.AsBoolean;
end;

function TgoBsonDocumentReader.ReadBsonType: TgoBsonType;
var
  CurrentElement: TgoBsonElement;
begin
  if (State in [TgoBsonReaderState.Initial, TgoBsonReaderState.ScopeDocument]) then
  begin
    CurrentBsonType := TgoBsonType.Document;
    State := TgoBsonReaderState.Value;
    Exit(CurrentBsonType);
  end;

  if (State <> TgoBsonReaderState.&Type) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  Assert(Assigned(FContext));
  case FContext.ContextType of
    TgoBsonContextType.&Array:
      begin
        if (not FContext.TryGetNextValue(FCurrentValue)) then
        begin
          State := TgoBsonReaderState.EndOfArray;
          Exit(TgoBsonType.EndOfDocument);
        end;
        State := TgoBsonReaderState.Value;
      end;

    TgoBsonContextType.Document:
      begin
        if (not FContext.TryGetNextElement(CurrentElement)) then
        begin
          State := TgoBsonReaderState.EndOfDocument;
          Exit(TgoBsonType.EndOfDocument);
        end;
        CurrentName := CurrentElement.Name;
        FCurrentValue := CurrentElement.Value;
        State := TgoBsonReaderState.Name;
      end;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;

  CurrentBsonType := FCurrentValue.BsonType;
  Result := CurrentBsonType;
end;

function TgoBsonDocumentReader.ReadBytes: TBytes;
var
  Binary: TgoBsonBinaryData;
  SubType: TgoBsonBinarySubType;
begin
  VerifyBsonType(TgoBsonType.Binary);
  State := GetNextState;
  Binary := FCurrentValue.AsBsonBinaryData;
  SubType := Binary.SubType;
  if (not (SubType in [TgoBsonBinarySubType.Binary, TgoBsonBinarySubType.OldBinary])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_DATA);
  Result := Binary.AsBytes;
end;

function TgoBsonDocumentReader.ReadDateTime: Int64;
begin
  VerifyBsonType(TgoBsonType.DateTime);
  State := GetNextState;
  Result := FCurrentValue.AsBsonDateTime.MillisecondsSinceEpoch;
end;

function TgoBsonDocumentReader.ReadDouble: Double;
begin
  VerifyBsonType(TgoBsonType.Double);
  State := GetNextState;
  Result := FCurrentValue.AsDouble;
end;

procedure TgoBsonDocumentReader.ReadEndArray;
begin
  Assert(Assigned(FContext));
  if (FContext.ContextType <> TgoBsonContextType.&Array) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  if (State = TgoBsonReaderState.&Type) then
    ReadBsonType;

  if (State <> TgoBsonReaderState.EndOfArray) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  PopContext;
  Assert(Assigned(FContext));

  case FContext.ContextType of
    TgoBsonContextType.&Array,
    TgoBsonContextType.Document:
      State := TgoBsonReaderState.&Type;

    TgoBsonContextType.TopLevel:
      State := TgoBsonReaderState.Done;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

procedure TgoBsonDocumentReader.ReadEndDocument;
begin
  Assert(Assigned(FContext));
  if (not (FContext.ContextType in [TgoBsonContextType.Document, TgoBsonContextType.ScopeDocument])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  if (State = TgoBsonReaderState.&Type) then
    ReadBsonType;

  if (State <> TgoBsonReaderState.EndOfDocument) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  PopContext;
  Assert(Assigned(FContext));

  case FContext.ContextType of
    TgoBsonContextType.&Array,
    TgoBsonContextType.Document:
      State := TgoBsonReaderState.&Type;

    TgoBsonContextType.TopLevel:
      State := TgoBsonReaderState.Done;
  else
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);
  end;
end;

function TgoBsonDocumentReader.ReadInt32: Integer;
begin
  VerifyBsonType(TgoBsonType.Int32);
  State := GetNextState;
  Result := FCurrentValue.AsInteger;
end;

function TgoBsonDocumentReader.ReadInt64: Int64;
begin
  VerifyBsonType(TgoBsonType.Int64);
  State := GetNextState;
  Result := FCurrentValue.AsInt64;
end;

function TgoBsonDocumentReader.ReadJavaScript: String;
begin
  VerifyBsonType(TgoBsonType.JavaScript);
  State := GetNextState;
  Result := FCurrentValue.AsBsonJavaScript.Code;
end;

function TgoBsonDocumentReader.ReadJavaScriptWithScope: String;
begin
  VerifyBsonType(TgoBsonType.JavaScriptWithScope);
  State := TgoBsonReaderState.ScopeDocument;
  Result := FCurrentValue.AsBsonJavaScriptWithScope.Code;
end;

procedure TgoBsonDocumentReader.ReadMaxKey;
begin
  VerifyBsonType(TgoBsonType.MaxKey);
  State := GetNextState;
end;

procedure TgoBsonDocumentReader.ReadMinKey;
begin
  VerifyBsonType(TgoBsonType.MinKey);
  State := GetNextState;
end;

function TgoBsonDocumentReader.ReadName: String;
begin
  if (FState = TgoBsonReaderState.&Type) then
    ReadBsonType;

  if (FState <> TgoBsonReaderState.Name) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  State := TgoBsonReaderState.Value;
  Result := CurrentName;
end;

procedure TgoBsonDocumentReader.ReadNull;
begin
  VerifyBsonType(TgoBsonType.Null);
  State := GetNextState;
end;

function TgoBsonDocumentReader.ReadObjectId: TgoObjectId;
begin
  VerifyBsonType(TgoBsonType.ObjectId);
  State := GetNextState;
  Result := FCurrentValue.AsObjectId;
end;

function TgoBsonDocumentReader.ReadRegularExpression: TgoBsonRegularExpression;
begin
  VerifyBsonType(TgoBsonType.RegularExpression);
  State := GetNextState;
  Result := FCurrentValue.AsBsonRegularExpression;
end;

procedure TgoBsonDocumentReader.ReadStartArray;
var
  A: TgoBsonArray;
begin
  VerifyBsonType(TgoBsonType.&Array);
  A := FCurrentValue.AsBsonArray;
  PushContext(TgoBsonContextType.&Array, A);
  State := TgoBsonReaderState.&Type;
end;

procedure TgoBsonDocumentReader.ReadStartDocument;
var
  Document: TgoBsonDocument;
begin
  VerifyBsonType(TgoBsonType.Document);

  if (FCurrentValue.IsBsonJavaScriptWithScope) then
    Document := FCurrentValue.AsBsonJavaScriptWithScope.Scope
  else
    Document := FCurrentValue.AsBsonDocument;

  PushContext(TgoBsonContextType.Document, Document);
  State := TgoBsonReaderState.&Type;
end;

function TgoBsonDocumentReader.ReadString: String;
begin
  VerifyBsonType(TgoBsonType.String);
  State := GetNextState;
  Result := FCurrentValue.AsString;
end;

function TgoBsonDocumentReader.ReadSymbol: String;
begin
  VerifyBsonType(TgoBsonType.Symbol);
  State := GetNextState;
  Result := FCurrentValue.AsBsonSymbol.Name;
end;

function TgoBsonDocumentReader.ReadTimestamp: Int64;
begin
  VerifyBsonType(TgoBsonType.Timestamp);
  State := GetNextState;
  Result := FCurrentValue.AsBsonTimestamp.Value;
end;

procedure TgoBsonDocumentReader.ReadUndefined;
begin
  VerifyBsonType(TgoBsonType.Undefined);
  State := GetNextState;
end;

procedure TgoBsonDocumentReader.ReturnToBookmark(
  const ABookmark: IgoBsonReaderBookmark);
var
  BM: TDocumentBookmark;
begin
  Assert(Assigned(ABookmark));
  Assert(ABookmark is TDocumentBookmark);
  BM := TDocumentBookmark(ABookmark);
  State := BM.State;
  CurrentBsonType := BM.CurrentBsonType;
  CurrentName := BM.CurrentName;
  FContextIndex := BM.ContextIndex;
  Assert((FContextIndex >= 0) and (FContextIndex < Length(FContextStack)));
  FContext := @FContextStack[FContextIndex];
  FContext.Index := BM.ContextIndexIndex;
  FCurrentValue := BM.CurrentValue;
end;

procedure TgoBsonDocumentReader.SkipName;
begin
  if (FState <> TgoBsonReaderState.Name) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  State := TgoBsonReaderState.Value;
end;

procedure TgoBsonDocumentReader.SkipValue;
begin
  if (FState <> TgoBsonReaderState.Value) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  State := TgoBsonReaderState.&Type;
end;

{ TgoBsonDocumentReader.TContext }

procedure TgoBsonDocumentReader.TContext.Initialize(
  const AContextType: TgoBsonContextType; const ADocument: TgoBsonDocument);
begin
  FContextType := AContextType;
  FDocument := ADocument;
end;

procedure TgoBsonDocumentReader.TContext.Initialize(
  const AContextType: TgoBsonContextType; const AArray: TgoBsonArray);
begin
  FContextType := AContextType;
  FArray := AArray;
end;

function TgoBsonDocumentReader.TContext.TryGetNextElement(
  out AElement: TgoBsonElement): Boolean;
begin
  if (FIndex < FDocument.Count) then
  begin
    AElement := FDocument.Elements[FIndex];
    Inc(FIndex);
    Result := True;
  end
  else
  begin
    AElement := Default(TgoBsonElement);
    Result := False;
  end;
end;

function TgoBsonDocumentReader.TContext.TryGetNextValue(
  out AValue: TgoBsonValue): Boolean;
begin
  if (FIndex < FArray.Count) then
  begin
    AValue := FArray[FIndex];
    Inc(FIndex);
    Result := True;
  end
  else
    Result := False;
end;

{ TgoBsonDocumentReader.TDocumentBookmark }

constructor TgoBsonDocumentReader.TDocumentBookmark.Create(
  const AState: TgoBsonReaderState; const ACurrentBsonType: TgoBsonType;
  const ACurrentName: String; const AContextIndex, AContextIndexIndex: Integer;
  const ACurrentValue: TgoBsonValue);
begin
  inherited Create(AState, ACurrentBsonType, ACurrentName);
  FContextIndex := AContextIndex;
  FContextIndexIndex := AContextIndexIndex;
  FCurrentValue := ACurrentValue;
end;

end.
