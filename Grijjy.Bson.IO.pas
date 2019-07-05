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

  You can look at the unit tests in the unit Grijjy.Data.Bson.IO.Tests
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
    procedure WriteValueIntf(const AValue: TgoBsonValue._IValue);
    procedure WriteArray(const AArray: TgoBsonArray._IArray);
    procedure WriteDocument(const ADocument: TgoBsonDocument._IDocument);
    procedure DoWriteBinaryData(const AValue: TgoBsonValue._IValue);
    procedure DoWriteDateTime(const AValue: TgoBsonValue._IValue);
    procedure DoWriteRegularExpression(const AValue: TgoBsonValue._IValue);
    procedure DoWriteJavaScript(const AValue: TgoBsonValue._IValue);
    procedure DoWriteJavaScriptWithScope(const AValue: TgoBsonJavaScriptWithScope); overload;
    procedure DoWriteJavaScriptWithScope(const AValue: TgoBsonValue._IValue); overload;
    procedure DoWriteSymbol(const AValue: TgoBsonValue._IValue);
    procedure DoWriteTimestamp(const AValue: TgoBsonValue._IValue);
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
  private type
    TOutput = record
    private
      FBuffer: PByte;
      FSize: Integer;
      FCapacity: Integer;
    public
      procedure Initialize;
      procedure Finalize;

      procedure Append(const AValue; const ASize: Integer); overload;
      procedure Append(const AValue: Char); overload; inline;
      procedure Append(const AValue: String); overload; inline;
      procedure Append(const AValue: Integer); overload; inline;
      procedure Append(const AValue: Int64); overload; inline;
      procedure AppendFormat(const AValue: String; const AArgs: array of const); overload;

      function ToString: String; inline;
    end;
  private
    FSettings: TgoJsonWriterSettings;
    FOutput: TOutput;
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
    FAllowDuplicateNames: Boolean;
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
    function ReadDocumentIntf: TgoBsonDocument._IDocument;
    function ReadArrayIntf: TgoBsonArray._IArray;
    function ReadValueIntf: TgoBsonValue._IValue;
    function ReadBinaryDataIntf: TgoBsonValue._IValue;
    function ReadRegularExpressionIntf: TgoBsonValue._IValue;
    function ReadJavaScriptIntf: TgoBsonValue._IValue;
    function ReadJavaScriptWithScopeIntf: TgoBsonValue._IValue;
    function ReadTimeStampIntf: TgoBsonValue._IValue;
    function ReadStringIntf: TgoBsonValue._IValue;
    function ReadSymbolIntf: TgoBsonValue._IValue;
  protected
    procedure EnsureBsonTypeEquals(const ABsonType: TgoBsonType);
    procedure VerifyBsonType(const ARequiredBsonType: TgoBsonType);

    property State: TgoBsonReaderState read FState write FState;
    property CurrentBsonType: TgoBsonType read FCurrentBsonType write FCurrentBsonType;
    property CurrentName: String read FCurrentName write FCurrentName;
    property AllowDuplicateNames: Boolean read FAllowDuplicateNames write FAllowDuplicateNames;
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
    TToken = class
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
      FLexemeStart: PChar;
      FLexemeLength: Integer;
      FStringValue: String;
      FValue: TTokenValue;
    {$ENDREGION 'Internal Declarations'}
    public
      procedure Initialize(const ATokenType: TTokenType;
        const ALexemeStart: PChar; const ALexemeLength: Integer); overload; inline;
      procedure Initialize(const ATokenType: TTokenType;
        const ALexemeStart: PChar; const ALexemeLength: Integer;
        const AStringValue: String); overload; inline;
      procedure Initialize(const ALexemeStart: PChar; const ALexemeLength: Integer;
        const AInt32Value: Int32); overload; inline;
      procedure Initialize(const ALexemeStart: PChar; const ALexemeLength: Integer;
        const AInt64Value: Int64); overload; inline;
      procedure Initialize(const ALexemeStart: PChar; const ALexemeLength: Integer;
        const ADoubleValue: Double); overload; inline;
      procedure InitializeRegEx(const ALexemeStart: PChar;
        const ALexemeLength: Integer); overload; inline;

      procedure Assign(const AOther: TToken);

      function IsLexeme(const AValue: PChar; const AValueLength: Integer): Boolean; inline;
      function LexemeToString: String; inline;

      property TokenType: TTokenType read FTokenType;
      property LexemeStart: PChar read FLexemeStart;
      property LexemeLength: Integer read FLexemeLength;
      property StringValue: String read FStringValue;
      property Int32Value: Int32 read FValue.Int32Value;
      property Int64Value: Int64 read FValue.Int64Value;
      property DoubleValue: Double read FValue.DoubleValue;
    end;
  private type
    TScanner = record
    private type
      TRegularExpressionState = (InPattern, InEscapeSequence, InOptions,
        Done, Invalid);
    private type
      TCharHandler = procedure(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken);
    private class var
      FCharHandlers: array [#0..#127] of TCharHandler;
    private
      class function IsWhitespace(const AChar: Char): Boolean; inline; static;
    private
      { Character handlers }
      class procedure CharError(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharEof(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharWhitespace(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharBeginObject(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharEndObject(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharBeginArray(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharEndArray(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharLeftParen(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharRightParen(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharColon(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharComma(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharNumberToken(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharStringToken(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharStringTokenUnscape(var ABuffer: TBuffer;
        const AQuoteChar: Char; const AToken: TToken; const AStart: PChar;
        const APrefix: String); static;
      class procedure CharUnquotedStringToken(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
      class procedure CharRegularExpressionToken(var ABuffer: TBuffer; const AChar: Char;
        const AToken: TToken); static;
    public
      class procedure Initialize; static;
      class procedure GetNextToken(var ABuffer: TBuffer; const AToken: TToken); static;
    end;
  private type
    TValue = record
      StrVal: String;
      Bytes: TBytes;
      case Byte of
        0: (BoolVal: Boolean);
        1: (Int32Val: Int32);
        2: (Int64Val: Int64);
        3: (DoubleVal: Double);
        4: (ObjectIdVal: TgoObjectId);
        5: (BinarySubType: TgoBsonBinarySubType);
    end;
  private type
    TJsonBookmark = class(TBookmark)
    private
      FContextIndex: Integer;
      FCurrentToken: TToken;
      FCurrentValue: TValue;
      FPushedToken: TToken;
      FCurrent: PChar;
    public
      constructor Create(const AState: TgoBsonReaderState;
        const ACurrentBsonType: TgoBsonType; const ACurrentName: String;
        const AContextIndex: Integer; const ACurrentToken: TToken;
        const ACurrentValue: TValue; const APushedToken: TToken;
        const ACurrent: PChar);
      destructor Destroy; override;

      property ContextIndex: Integer read FContextIndex;
      property CurrentToken: TToken read FCurrentToken;
      property CurrentValue: TValue read FCurrentValue;
      property PushedToken: TToken read FPushedToken;
      property Current: PChar read FCurrent;
    end;
  private
    FBuffer: TBuffer;
    FTokenBase: TToken;
    FTokenToPush: TToken;
    FCurrentToken: TToken;
    FCurrentValue: TValue;
    FPushedToken: TToken;
    FContextStack: TArray<TContext>;
    FContextIndex: Integer;
    FContext: PContext;
  private
    function GetNextState: TgoBsonReaderState;
    procedure PushContext(const AContextType: TgoBsonContextType);
    procedure PopContext;
    procedure PushToken(const AToken: TToken);
    procedure PopToken(out AToken: TToken);
    function ParseDocumentOrExtendedJson: TgoBsonType;
    function ParseExtendedJson(const ANameToken: TToken): TgoBsonType;
    procedure ParseExtendedJsonBinaryData;
    function ParseExtendedJsonDateTime: Int64;
    function ParseExtendedJsonNumberLong: Int64;
    function ParseExtendedJsonJavaScript: TgoBsonType;
    procedure ParseExtendedJsonMaxKey;
    procedure ParseExtendedJsonMinKey;
    procedure ParseExtendedJsonUndefined;
    function ParseExtendedJsonObjectId: TgoObjectId;
    procedure ParseExtendedJsonRegularExpression;
    procedure ParseExtendedJsonSymbol;
    function ParseExtendedJsonTimestamp: Int64;
    function ParseExtendedJsonTimestampNew: Int64;
    function ParseExtendedJsonTimestampOld(const AValueToken: TToken): Int64;
    procedure ParseConstructorBinaryData;
    procedure ParseConstructorDateTime(const AWithNew: Boolean);
    procedure ParseConstructorHexData;
    procedure ParseConstructorISODateTime;
    procedure ParseConstructorNumber;
    procedure ParseConstructorNumberLong;
    procedure ParseConstructorObjectId;
    procedure ParseConstructorRegularExpression;
    procedure ParseConstructorTimestamp;
    procedure ParseConstructorUUID(const ALexemeStart: Char);
    function ParseNew: TgoBsonType;
    procedure VerifyToken(const AExpectedLexeme: Char); overload;
    procedure VerifyToken(const AExpectedLexeme: PChar;
      const AExpectedLexemeLength: Integer); overload;
    procedure VerifyString(const AExpectedString: String);
    procedure SetCurrentValueRegEx(const AToken: TToken);
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
  public
    class constructor Create;
  {$ENDREGION 'Internal Declarations'}
  public
    { Creates a JSON reader.

      Parameters:
        AJson: the JSON string to parse. }
    constructor Create(const AJson: String; AllowDuplicateNames : Boolean = false);

    { Destructor }
    destructor Destroy; override;

    { Creates a JSON reader from a file.

      Parameters:
        AFilename: the name of the file containing the JSON data. }
    class function Load(const AFilename: String; AllowDuplicateNames : Boolean = false): IgoJsonReader; overload; static;

    { Creates a JSON reader from a stream.

      Parameters:
        AStream: the stream containing the JSON data. }
    class function Load(const AStream: TStream; AllowDuplicateNames : Boolean = false): IgoJsonReader; overload; static;
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
  {$IF Defined(MACOS)}
  Macapi.CoreFoundation,
  {$ENDIF}
  Grijjy.SysUtils,
  Grijjy.DateUtils,
  Grijjy.BinaryCoding;

type
  TgoCharBuffer = record
  private const
    SIZE = 256;
  private type
    TBuffer = array [0..SIZE - 1] of Char;
    PBuffer = ^TBuffer;
  private
    FStatic: TBuffer;
    FDynamic: PBuffer;
    FCurrent: PChar;
    FCurrentEnd: PChar;
    FDynamicCount: Integer;
  public
    procedure Initialize; inline;
    procedure Release; inline;
    procedure Append(const AChar: Char); inline;
    function ToString: String; inline;
  end;

procedure TgoCharBuffer.Append(const AChar: Char);
begin
  if (FCurrent < FCurrentEnd) then
  begin
    FCurrent^ := AChar;
    Inc(FCurrent);
    Exit;
  end;

  ReallocMem(FDynamic, (FDynamicCount + 1) * SizeOf(TBuffer));
  FCurrent := PChar(FDynamic) + (FDynamicCount * SIZE);
  FCurrentEnd := FCurrent + SIZE;
  Inc(FDynamicCount);

  FCurrent^ := AChar;
  Inc(FCurrent);
end;

function TgoCharBuffer.ToString: String;
var
  I, StrIndex, TrailingLength: Integer;
  Src: PBuffer;
  Start: PChar;
begin
  if (FDynamic = nil) then
  begin
    Start := @FStatic;
    SetString(Result, Start, FCurrent - Start);
    Exit;
  end;

  TrailingLength := SIZE - (FCurrentEnd - FCurrent);
  SetLength(Result, (FDynamicCount * SIZE) + TrailingLength);
  Move(FStatic, Result[Low(String)], SizeOf(TBuffer));
  StrIndex := Low(String) + SIZE;

  Src := FDynamic;
  for I := 0 to FDynamicCount - 2 do
  begin
    Move(Src^, Result[StrIndex], SizeOf(TBuffer));
    Inc(Src);
    Inc(StrIndex, SIZE);
  end;

  Move(Src^, Result[StrIndex], TrailingLength * SizeOf(Char));
end;

procedure TgoCharBuffer.Initialize;
begin
  FDynamic := nil;
  FCurrent := @FStatic;
  FCurrentEnd := FCurrent + SIZE;
  FDynamicCount := 0;
end;

procedure TgoCharBuffer.Release;
begin
  FreeMem(FDynamic);
end;

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

procedure TgoBsonBaseWriter.DoWriteBinaryData(
  const AValue: TgoBsonValue._IValue);
var
  Value: TgoBsonBinaryData;
begin
  _goGetBinaryData(AValue, Value);
  WriteBinaryData(Value);
end;

procedure TgoBsonBaseWriter.DoWriteDateTime(const AValue: TgoBsonValue._IValue);
var
  Value: TgoBsonDateTime;
begin
  _goGetDateTime(AValue, Value);
  WriteDateTime(Value.MillisecondsSinceEpoch);
end;

procedure TgoBsonBaseWriter.DoWriteJavaScript(
  const AValue: TgoBsonValue._IValue);
var
  Value: TgoBsonJavaScript;
begin
  _goGetJavaScript(AValue, Value);
  WriteJavaScript(Value.Code);
end;

procedure TgoBsonBaseWriter.DoWriteJavaScriptWithScope(
  const AValue: TgoBsonValue._IValue);
var
  Value: TgoBsonJavaScriptWithScope;
begin
  _goGetJavaScriptWithScope(AValue, Value);
  DoWriteJavaScriptWithScope(Value);
end;

procedure TgoBsonBaseWriter.DoWriteJavaScriptWithScope(
  const AValue: TgoBsonJavaScriptWithScope);
begin
  WriteJavaScriptWithScope(AValue.Code);
  WriteDocument(AValue.Scope._Impl);
end;

procedure TgoBsonBaseWriter.DoWriteRegularExpression(
  const AValue: TgoBsonValue._IValue);
var
  Value: TgoBsonRegularExpression;
begin
  _goGetRegularExpression(AValue, Value);
  WriteRegularExpression(Value);
end;

procedure TgoBsonBaseWriter.DoWriteSymbol(const AValue: TgoBsonValue._IValue);
var
  Value: TgoBsonSymbol;
begin
  _goGetSymbol(AValue, Value);
  WriteSymbol(Value.Name);
end;

procedure TgoBsonBaseWriter.DoWriteTimestamp(const AValue: TgoBsonValue._IValue);
var
  Value: TgoBsonTimestamp;
begin
  _goGetTimestamp(AValue, Value);
  WriteTimestamp(Value.Value);
end;

function TgoBsonBaseWriter.GetState: TgoBsonWriterState;
begin
  Result := FState;
end;

procedure TgoBsonBaseWriter.WriteArray(const AArray: TgoBsonArray._IArray);
var
  I: Integer;
  Item: TgoBsonValue._IValue;
begin
  WriteStartArray;

  for I := 0 to AArray.Count - 1 do
  begin
    AArray.GetItem(I, Item);
    WriteValueIntf(Item);
  end;

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

procedure TgoBsonBaseWriter.WriteDocument(
  const ADocument: TgoBsonDocument._IDocument);
var
  I: Integer;
  Element: TgoBsonElement;
begin
  WriteStartDocument;

  for I := 0 to ADocument.Count - 1 do
  begin
    Element := ADocument.Elements[I];
    WriteName(Element.Name);
    WriteValueIntf(Element._Impl);
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
    TgoBsonType.Document           : WriteDocument(TgoBsonDocument._IDocument(AValue._Impl));
    TgoBsonType.&Array             : WriteArray(TgoBsonArray._IArray(AValue._Impl));
    TgoBsonType.Binary             : DoWriteBinaryData(AValue._Impl);
    TgoBsonType.Undefined          : WriteUndefined;
    TgoBsonType.ObjectId           : WriteObjectId(AValue.AsObjectId);
    TgoBsonType.Boolean            : WriteBoolean(AValue.AsBoolean);
    TgoBsonType.DateTime           : DoWriteDateTime(AValue._Impl);
    TgoBsonType.Null               : WriteNull;
    TgoBsonType.RegularExpression  : DoWriteRegularExpression(AValue._Impl);
    TgoBsonType.JavaScript         : DoWriteJavaScript(AValue._Impl);
    TgoBsonType.Symbol             : DoWriteSymbol(AValue._Impl);
    TgoBsonType.JavaScriptWithScope: DoWriteJavaScriptWithScope(AValue._Impl);
    TgoBsonType.Int32              : WriteInt32(AValue.AsInteger);
    TgoBsonType.Timestamp          : DoWriteTimestamp(AValue._Impl);
    TgoBsonType.Int64              : WriteInt64(AValue.AsInt64);
    TgoBsonType.MaxKey             : WriteMaxKey;
    TgoBsonType.MinKey             : WriteMinKey;
  else
    Assert(False);
  end;
end;

procedure TgoBsonBaseWriter.WriteValueIntf(const AValue: TgoBsonValue._IValue);
begin
  if (AValue = nil) then
    raise EArgumentNilException.CreateRes(@SArgumentNil);

  case AValue.BsonType of
    TgoBsonType.EndOfDocument      : ;
    TgoBsonType.Double             : WriteDouble(AValue.AsDouble);
    TgoBsonType.&String            : WriteString(AValue.AsString);
    TgoBsonType.Document           : WriteDocument(TgoBsonDocument._IDocument(AValue));
    TgoBsonType.&Array             : WriteArray(TgoBsonArray._IArray(AValue));
    TgoBsonType.Binary             : DoWriteBinaryData(AValue);
    TgoBsonType.Undefined          : WriteUndefined;
    TgoBsonType.ObjectId           : WriteObjectId(AValue.AsObjectId);
    TgoBsonType.Boolean            : WriteBoolean(AValue.AsBoolean);
    TgoBsonType.DateTime           : DoWriteDateTime(AValue);
    TgoBsonType.Null               : WriteNull;
    TgoBsonType.RegularExpression  : DoWriteRegularExpression(AValue);
    TgoBsonType.JavaScript         : DoWriteJavaScript(AValue);
    TgoBsonType.Symbol             : DoWriteSymbol(AValue);
    TgoBsonType.JavaScriptWithScope: DoWriteJavaScriptWithScope(AValue);
    TgoBsonType.Int32              : WriteInt32(AValue.AsInteger);
    TgoBsonType.Timestamp          : DoWriteTimestamp(AValue);
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
  if Assigned(Bytes) then
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
  if (FContext = nil) then
    State := TgoBsonWriterState.Done
  else
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
  if (not (State in [TgoBsonWriterState.Initial, TgoBsonWriterState.Value])) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_WRITER_STATE);

  if (State = TgoBsonWriterState.Value) then
  begin
    FOutput.WriteBsonType(TgoBsonType.&Array);
    WriteNameHelper;
  end;

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
  if ((FSize + ASize) > FCapacity) then
  begin
    repeat
      FCapacity := FCapacity shl 1;
    until (FCapacity >= (FSize + ASize));
    SetLength(FBuffer, FCapacity);
  end;
  Move(AValue, FBuffer[FSize], ASize);
  Inc(FSize, ASize);
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
  if (((CharCount + 1) * 3) <= TEMP_BYTES_LENGTH) then
  begin
    Bytes := FTempBytes;
    Utf8Count := goUtf16ToUtf8(AValue, CharCount, FTempBytes);
  end
  else
  begin
    Bytes := goUtf16ToUtf8(AValue);
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
  if (((CharCount + 1) * 3) <= TEMP_BYTES_LENGTH) then
  begin
    Bytes := FTempBytes;
    Utf8Count := goUtf16ToUtf8(AValue, CharCount, Bytes);
  end
  else
  begin
    Bytes := goUtf16ToUtf8(AValue);
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
  FOutput.Initialize;
  FContextIndex := -1;
  PushContext(TgoBsonContextType.TopLevel, '');
end;

destructor TgoJsonWriter.Destroy;
begin
  FOutput.Finalize;
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
  I: Integer;
  C: Char;
begin
  for I := Low(String) to Low(String) + Length(AValue) - 1 do
  begin
    C := AValue[I];
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
        FOutput.Append(LowerCase(IntToHex(Ord(C), 4)));
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

{ TgoJsonWriter.TOutput }

procedure TgoJsonWriter.TOutput.Append(const AValue: String);
begin
  if (AValue <> '') then
    Append(AValue[Low(String)], Length(AValue) * SizeOf(Char));
end;

procedure TgoJsonWriter.TOutput.Append(const AValue: Integer);
begin
  Append(IntToStr(AValue));
end;

procedure TgoJsonWriter.TOutput.Append(const AValue: Int64);
begin
  Append(IntToStr(AValue));
end;

procedure TgoJsonWriter.TOutput.Append(const AValue; const ASize: Integer);
begin
  if ((FSize + ASize) > FCapacity) then
  begin
    repeat
      FCapacity := FCapacity shl 1;
    until (FCapacity >= (FSize + ASize));
    ReallocMem(FBuffer, FCapacity);
  end;
  Move(AValue, FBuffer[FSize], ASize);
  Inc(FSize, ASize);
end;

procedure TgoJsonWriter.TOutput.Append(const AValue: Char);
begin
  Append(AValue, SizeOf(Char));
end;

procedure TgoJsonWriter.TOutput.AppendFormat(const AValue: String;
  const AArgs: array of const);
begin
  Append(Format(AValue, AArgs));
end;

procedure TgoJsonWriter.TOutput.Finalize;
begin
  FreeMem(FBuffer);
  FBuffer := nil;
end;

procedure TgoJsonWriter.TOutput.Initialize;
begin
  GetMem(FBuffer, 512);
  FCapacity := 512;
  FSize := 0;
end;

function TgoJsonWriter.TOutput.ToString: String;
begin
  SetString(Result, PChar(FBuffer), FSize shr 1);
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
  Item: TgoBsonValue._IValue;
  Arr: TgoBsonArray._IArray;
begin
  EnsureBsonTypeEquals(TgoBsonType.&Array);

  ReadStartArray;
  Result := TgoBsonArray.Create;
  Arr := Result._Impl;
  while (ReadBsonType <> TgoBsonType.EndOfDocument) do
  begin
    Item := ReadValueIntf;
    Arr.Add(Item);
  end;
  ReadEndArray;
end;

function TgoBsonBaseReader.ReadArrayIntf: TgoBsonArray._IArray;
var
  Item: TgoBsonValue._IValue;
begin
  EnsureBsonTypeEquals(TgoBsonType.&Array);

  ReadStartArray;
  Result := _goCreateArray;
  while (ReadBsonType <> TgoBsonType.EndOfDocument) do
  begin
    Item := ReadValueIntf;
    Result.Add(Item);
  end;
  ReadEndArray;
end;

function TgoBsonBaseReader.ReadBinaryDataIntf: TgoBsonValue._IValue;
var
  Value: TgoBsonBinaryData;
begin
  Value := ReadBinaryData;
  Result := Value._Impl;
end;

function TgoBsonBaseReader.ReadDocument: TgoBsonDocument;
var
  Doc: TgoBsonDocument._IDocument;
  Name: String;
  Value: TgoBsonValue._IValue;
begin
  EnsureBsonTypeEquals(TgoBsonType.Document);

  ReadStartDocument;

  Result := TgoBsonDocument.Create(FAllowDuplicateNames);

  Doc := Result._Impl;

  while (ReadBsonType <> TgoBsonType.EndOfDocument) do
  begin
    Name := ReadName;
    Value := ReadValueIntf;
    Doc.Add(Name, Value);
  end;

  ReadEndDocument;
end;

function TgoBsonBaseReader.ReadDocumentIntf: TgoBsonDocument._IDocument;
var
  Name: String;
  Value: TgoBsonValue._IValue;
begin
  EnsureBsonTypeEquals(TgoBsonType.Document);

  ReadStartDocument;

  Result := _goCreateDocument;
  Result.AllowDuplicateNames := FAllowDuplicateNames;

  while (ReadBsonType <> TgoBsonType.EndOfDocument) do
  begin
    Name := ReadName;
    Value := ReadValueIntf;
    Result.Add(Name, Value);
  end;

  ReadEndDocument;
end;

function TgoBsonBaseReader.ReadJavaScriptIntf: TgoBsonValue._IValue;
var
  Value: TgoBsonJavaScript;
begin
  Value := TgoBsonJavaScript.Create(ReadJavaScript);
  Result := Value._Impl;
end;

function TgoBsonBaseReader.ReadJavaScriptWithScopeIntf: TgoBsonValue._IValue;
var
  Value: TgoBsonValue;
begin
  Value := DoReadJavaScriptWithScope;
  Result := Value._Impl;
end;

function TgoBsonBaseReader.ReadRegularExpressionIntf: TgoBsonValue._IValue;
var
  Value: TgoBsonRegularExpression;
begin
  Value := ReadRegularExpression;
  Result := Value._Impl;
end;

function TgoBsonBaseReader.ReadStringIntf: TgoBsonValue._IValue;
begin
  Result := _goBsonValueFromString(ReadString);
end;

function TgoBsonBaseReader.ReadSymbolIntf: TgoBsonValue._IValue;
var
  Value: TgoBsonSymbol;
begin
  Value := TgoBsonSymbolTable.Lookup(ReadSymbol);
  Result := Value._Impl;
end;

function TgoBsonBaseReader.ReadTimeStampIntf: TgoBsonValue._IValue;
var
  Value: TgoBsonTimestamp;
begin
  Value := TgoBsonTimestamp.Create(ReadTimestamp);
  Result := Value._Impl;
end;

function TgoBsonBaseReader.ReadValue: TgoBsonValue;
begin
  Result._Impl := ReadValueIntf;
end;

function TgoBsonBaseReader.ReadValueIntf: TgoBsonValue._IValue;
begin
  case GetCurrentBsonType of
    TgoBsonType.EndOfDocument: ;
    TgoBsonType.Double: Result := _goBsonValueFromDouble(ReadDouble);
    TgoBsonType.&String: Result := ReadStringIntf;
    TgoBsonType.Document: Result := ReadDocumentIntf;
    TgoBsonType.&Array: Result := ReadArrayIntf;
    TgoBsonType.Binary: Result := ReadBinaryDataIntf;
    TgoBsonType.Undefined: begin ReadUndefined; Result := TgoBsonUndefined.Value._Value end;
    TgoBsonType.ObjectId: Result := _goBsonValueFromObjectId(ReadObjectId);
    TgoBsonType.Boolean: Result := _goBsonValueFromBoolean(ReadBoolean);
    TgoBsonType.DateTime: Result := _goBsonValueFromDateTime(ReadDateTime);
    TgoBsonType.Null: begin ReadNull; Result := TgoBsonNull.Value._Value end;
    TgoBsonType.RegularExpression: Result := ReadRegularExpressionIntf;
    TgoBsonType.JavaScript: Result := ReadJavaScriptIntf;
    TgoBsonType.Symbol: Result := ReadSymbolIntf;
    TgoBsonType.JavaScriptWithScope: Result := ReadJavaScriptWithScopeIntf;
    TgoBsonType.Int32: Result := _goBsonValueFromInt32(ReadInt32);
    TgoBsonType.Timestamp: Result := ReadTimeStampIntf;
    TgoBsonType.Int64: Result := _goBsonValueFromInt64(ReadInt64);
    TgoBsonType.MaxKey: begin ReadMaxKey; Result := TgoBsonMaxKey.Value._Value end;
    TgoBsonType.MinKey: begin ReadMinKey; Result := TgoBsonMinKey.Value._Value end;
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
  if (Result <> nil) then
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

constructor TgoJsonReader.Create(const AJson: String; AllowDuplicateNames : Boolean = false);
begin
  inherited Create;
  FAllowDuplicateNames := AllowDuplicateNames;
  FBuffer := TBuffer.Create(AJson);
  FTokenBase := TToken.Create;
  FTokenToPush := TToken.Create;
  PushContext(TgoBsonContextType.TopLevel);
end;

class constructor TgoJsonReader.Create;
begin
  TScanner.Initialize;
end;

destructor TgoJsonReader.Destroy;
begin
  FTokenBase.Free;
  FTokenToPush.Free;
  inherited;
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
    FContextIndex, FCurrentToken, FCurrentValue, FPushedToken,
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

class function TgoJsonReader.Load(const AFilename: String; AllowDuplicateNames : Boolean = false): IgoJsonReader;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    Result := Load(Stream, AllowDuplicateNames);
  finally
    Stream.Free;
  end;
end;

class function TgoJsonReader.Load(const AStream: TStream; AllowDuplicateNames : Boolean = false): IgoJsonReader;
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
  Result := TgoJsonReader.Create(Json, AllowDuplicateNames);
end;

procedure TgoJsonReader.ParseConstructorBinaryData;
{ BinData(0, "AQ==") }
var
  Token: TToken;
  Base64: TBytes;
begin
  VerifyToken('(');

  PopToken(Token);
  if (Token.TokenType <> TTokenType.Int32) then
    raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);
  FCurrentValue.BinarySubType := TgoBsonBinarySubType(Token.Int32Value);

  VerifyToken(',');

  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  Base64 := TEncoding.ANSI.GetBytes(Token.StringValue);

  VerifyToken(')');

  FCurrentValue.Bytes := goBase64Decode(Base64);
end;

procedure TgoJsonReader.ParseConstructorDateTime(
  const AWithNew: Boolean);
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
    FCurrentValue.StrVal := FormatJavaScriptDateTimeString(Now);
    Exit;
  end;

  PopToken(Token);
  if (Token.LexemeLength = 1) and (Token.LexemeStart^ = ')') then
  begin
    FCurrentValue.Int64Val := goDateTimeToMillisecondsSinceEpoch(Now, False);
    Exit;
  end;

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
      if (Token.LexemeLength = 1) and (Token.LexemeStart^ = ')') then
        Break;

      if (Token.LexemeLength <> 1) or (Token.LexemeStart^ <> ',') then
        raise FBuffer.ParseError(@RS_BSON_COMMA_EXPECTED);

      PopToken(Token);
      if (not (Token.TokenType in [TTokenType.Int32, TTokenType.Int64])) then
        raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);
    end;

    case ArgCount of
      1: FCurrentValue.Int64Val := Args[0];
      3..7:
        begin
          DateTime := EncodeDateTime(
            Args[0], Args[1] + 1, Args[2],
            Args[3], Args[3], Args[5], Args[6]);
          FCurrentValue.Int64Val := goDateTimeToMillisecondsSinceEpoch(DateTime, True);
        end
    else
      raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);
    end;
    Exit;
  end;

  raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);
end;

procedure TgoJsonReader.ParseConstructorHexData;
{ HexData(0, "123") }
var
  Token: TToken;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.Int32) then
    raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);
  FCurrentValue.BinarySubType := TgoBsonBinarySubType(Token.Int32Value);

  VerifyToken(',');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  VerifyToken(')');

  FCurrentValue.Bytes := goParseHexString(Token.StringValue);
end;

procedure TgoJsonReader.ParseConstructorISODateTime;
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

  FCurrentValue.Int64Val := goDateTimeToMillisecondsSinceEpoch(DateTime, True);
end;

procedure TgoJsonReader.ParseConstructorNumber;
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
    FCurrentValue.Int32Val := Token.Int32Value
  else if (Token.TokenType = TTokenType.String) then
    FCurrentValue.Int32Val := StrToInt(Token.StringValue)
  else
    raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);
  VerifyToken(')');
end;

procedure TgoJsonReader.ParseConstructorNumberLong;
{ NumberLong(42)
  NumberLong("42") }
var
  Token: TToken;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
    FCurrentValue.Int64Val := Token.Int64Value
  else if (Token.TokenType = TTokenType.String) then
    FCurrentValue.Int64Val := StrToInt64(Token.StringValue)
  else
    raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);
  VerifyToken(')');
end;

procedure TgoJsonReader.ParseConstructorObjectId;
// ObjectId("0102030405060708090a0b0c")
var
  Token: TToken;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  VerifyToken(')');
  FCurrentValue.ObjectIdVal := TgoObjectId.Create(Token.StringValue);
end;

procedure TgoJsonReader.ParseConstructorRegularExpression;
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
  if (Token.LexemeLength = 1) and (Token.LexemeStart^ = ',') then
  begin
    PopToken(Token);
    if (Token.TokenType <> TTokenType.String) then
      raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
    Options := Token.StringValue;
  end
  else
    PushToken(Token);

  VerifyToken(')');
  FCurrentValue.StrVal := Pattern + #1 + Options;
end;

procedure TgoJsonReader.ParseConstructorTimestamp;
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
  FCurrentValue.Int64Val := (UInt64(SecondsSinceEpoch) shl 32) or UInt32(Increment);
end;

procedure TgoJsonReader.ParseConstructorUUID(const ALexemeStart: Char);
var
  Token: TToken;
  HexString: String;
begin
  VerifyToken('(');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  VerifyToken(')');

  HexString := Token.StringValue.Replace('{', '').Replace('}', '');
  HexString := HexString.Replace('-', '', [rfReplaceAll]);
  FCurrentValue.Bytes := goParseHexString(HexString);
  if (Length(FCurrentValue.Bytes) <> 16) then
    raise FBuffer.ParseError(@RS_BSON_INVALID_GUID);
  FCurrentValue.BinarySubType := TgoBsonBinarySubType.UuidLegacy;

  if (ALexemeStart = 'C') then // C#
  begin
    // No conversion needed
    goReverseBytes(FCurrentValue.Bytes, 0, 4);
    goReverseBytes(FCurrentValue.Bytes, 4, 2);
    goReverseBytes(FCurrentValue.Bytes, 6, 2);
  end
  else
  begin
    if (ALexemeStart = 'J') then // Java
    begin
      goReverseBytes(FCurrentValue.Bytes, 0, 8);
      goReverseBytes(FCurrentValue.Bytes, 8, 8);
    end
    else if (ALexemeStart <> 'P') then // Python
      FCurrentValue.BinarySubType := TgoBsonBinarySubType.UuidStandard;
  end;
end;

function TgoJsonReader.ParseDocumentOrExtendedJson: TgoBsonType;
var
  NameToken: TToken;
begin
  PopToken(NameToken);
  if (NameToken.TokenType in [TTokenType.String, TTokenType.UnquotedString])
    and (NameToken.StringValue <> '')
  then
    Result := ParseExtendedJson(NameToken)
  else
  begin
    PushToken(NameToken);
    Result := TgoBsonType.Document;
  end;
end;

function TgoJsonReader.ParseExtendedJson(const ANameToken: TToken): TgoBsonType;
var
  S: String;
begin
  S := ANameToken.StringValue;
  Assert(S <> '');
  if (S.Chars[0] = '$') and (S.Length > 1) then
  begin
    case S.Chars[1] of
      'b': if (S = '$binary') then
           begin
             ParseExtendedJsonBinaryData;
             Exit(TgoBsonType.Binary);
           end;
      'c': if (S = '$code') then
             Exit(ParseExtendedJsonJavaScript);
      'd': if (S = '$date') then
           begin
             FCurrentValue.Int64Val := ParseExtendedJsonDateTime;
             Exit(TgoBsonType.DateTime);
           end;
      'm': if (S = '$maxkey') or (S = '$maxKey') then
           begin
             ParseExtendedJsonMaxKey;
             Exit(TgoBsonType.MaxKey);
           end
           else if (S = '$minkey') or (S = '$minKey') then
           begin
             ParseExtendedJsonMinKey;
             Exit(TgoBsonType.MinKey);
           end;
      'n': if (S = '$numberLong') then
           begin
             FCurrentValue.Int64Val := ParseExtendedJsonNumberLong;
             Exit(TgoBsonType.Int64);
           end;
      'o': if (S = '$oid') then
           begin
             FCurrentValue.ObjectIdVal := ParseExtendedJsonObjectId;
             Exit(TgoBsonType.ObjectId);
           end;
      'r': if (S = '$regex') then
           begin
             ParseExtendedJsonRegularExpression;
             Exit(TgoBsonType.RegularExpression);
           end;
      's': if (S = '$symbol') then
           begin
             ParseExtendedJsonSymbol;
             Exit(TgoBsonType.Symbol);
           end;
      't': if (S = '$timestamp') then
           begin
             FCurrentValue.Int64Val := ParseExtendedJsonTimestamp;
             Exit(TgoBsonType.Timestamp);
           end;
      'u': if (S = '$undefined') then
           begin
             ParseExtendedJsonUndefined;
             Exit(TgoBsonType.Undefined);
           end;
    end;
  end;
  PushToken(ANameToken);
  Result := TgoBsonType.Document;
end;

procedure TgoJsonReader.ParseExtendedJsonBinaryData;
(* { $binary : "AQ==", $type : 0 }
   { $binary : "AQ==", $type : "0" }
   { $binary : "AQ==", $type : "00" } *)
var
  Token: TToken;
  Base64: TBytes;
begin
  VerifyToken(':');

  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);

  Base64 := TEncoding.ANSI.GetBytes(Token.StringValue);
  FCurrentValue.Bytes := goBase64Decode(Base64);

  VerifyToken(',');
  VerifyString('$type');
  VerifyToken(':');

  PopToken(Token);
  if (Token.TokenType = TTokenType.String) then
    FCurrentValue.BinarySubType := TgoBsonBinarySubType(StrToInt('$' + Token.StringValue))
  else if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
    FCurrentValue.BinarySubType := TgoBsonBinarySubType(Token.Int32Value)
  else
    raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);

  VerifyToken('}');
end;

function TgoJsonReader.ParseExtendedJsonDateTime: Int64;
(* { $date : -9223372036854775808 }
   { $date : { $numberLong : 9223372036854775807 } }
   { $date : { $numberLong : "-9223372036854775808" } }
   { $date : "1970-01-01T00:00:00Z" }
   { $date : "1970-01-01T00:00:00.000Z" } *)
var
  Token: TToken;
  DateTime: TDateTime;
begin
  VerifyToken(':');

  PopToken(Token);
  if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
    Result := Token.Int64Value
  else if (Token.TokenType = TTokenType.String) then
  begin
    if (not TryISO8601ToDate(Token.StringValue, DateTime, True)) then
      raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);
    Result := goDateTimeToMillisecondsSinceEpoch(DateTime, True);
  end
  else if (Token.TokenType = TTokenType.BeginObject) then
  begin
    VerifyString('$numberLong');
    VerifyToken(':');
    PopToken(Token);
    if (Token.TokenType = TTokenType.String) then
    begin
      if (not TryStrToInt64(Token.StringValue, Result)) then
        raise FBuffer.ParseError(@RS_BSON_INT_EXPECTED);
    end
    else if (Token.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
      Result := Token.Int64Value
    else
      raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);
    VerifyToken('}');
  end
  else
    raise FBuffer.ParseError(@RS_BSON_INVALID_DATE);

  VerifyToken('}');
end;

function TgoJsonReader.ParseExtendedJsonJavaScript: TgoBsonType;
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
        FCurrentValue.StrVal := Code;
        Result := TgoBsonType.JavaScriptWithScope;
      end;

    TTokenType.EndObject:
      begin
        FCurrentValue.StrVal := Code;
        Result := TgoBsonType.JavaScript;
      end;
  else
    raise FBuffer.ParseError(@RS_BSON_COMMA_OR_CLOSE_BRACE_EXPECTED);
  end;
end;

procedure TgoJsonReader.ParseExtendedJsonMaxKey;
(* { $maxKey : 1 }
   { $maxkey : 1 } *)
begin
  VerifyToken(':');
  VerifyToken('1');
  VerifyToken('}');
end;

procedure TgoJsonReader.ParseExtendedJsonMinKey;
(* { $minKey : 1 }
   { $minkey : 1 } *)
begin
  VerifyToken(':');
  VerifyToken('1');
  VerifyToken('}');
end;

function TgoJsonReader.ParseExtendedJsonNumberLong: Int64;
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

function TgoJsonReader.ParseExtendedJsonObjectId: TgoObjectId;
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

procedure TgoJsonReader.ParseExtendedJsonRegularExpression;
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
  FCurrentValue.StrVal := Pattern + #1 + Options;
end;

procedure TgoJsonReader.ParseExtendedJsonSymbol;
(* { "$symbol" : "symbol" } *)
var
  Token: TToken;
begin
  VerifyToken(':');
  PopToken(Token);
  if (Token.TokenType <> TTokenType.String) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);
  VerifyToken('}');
  FCurrentValue.StrVal := Token.StringValue; // Will be converted to a TgoBsonSymbol later
end;

function TgoJsonReader.ParseExtendedJsonTimestamp: Int64;
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

function TgoJsonReader.ParseExtendedJsonTimestampNew: Int64;
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
  Result := (UInt64(SecondsSinceEpoch) shl 32) or UInt32(Increment);
end;

function TgoJsonReader.ParseExtendedJsonTimestampOld(
  const AValueToken: TToken): Int64;
(* { $timestamp : 123 }
   { $timestamp : NumberLong(123) } *)
begin

  if (AValueToken.TokenType in [TTokenType.Int32, TTokenType.Int64]) then
    Result := AValueToken.Int64Value
  else if (AValueToken.TokenType = TTokenType.UnquotedString)
    and (AValueToken.IsLexeme('NumberLong', 10)) then
  begin
    ParseConstructorNumberLong;
    Result := FCurrentValue.Int64Val;
  end
  else
    raise FBuffer.ParseError(@RS_BSON_INT_OR_STRING_EXPECTED);

  VerifyToken('}');
end;

procedure TgoJsonReader.ParseExtendedJsonUndefined;
(* { $undefined : true } *)
begin
  VerifyToken(':');
  VerifyToken('true', 4);
  VerifyToken('}');
end;

function TgoJsonReader.ParseNew: TgoBsonType;
var
  Token: TToken;
begin
  PopToken(Token);
  if (Token.TokenType <> TTokenType.UnquotedString) then
    raise FBuffer.ParseError(@RS_BSON_STRING_EXPECTED);

  Assert(Token.LexemeLength > 0);
  case Token.LexemeStart^ of
    'B': if (Token.IsLexeme('BinData', 7)) then
         begin
           ParseConstructorBinaryData;
           Exit(TgoBsonType.Binary);
         end;

    'C': if (Token.IsLexeme('CSUUID', 6)) or (Token.IsLexeme('CSGUID', 6)) then
         begin
           ParseConstructorUUID(Token.LexemeStart^);
           Exit(TgoBsonType.DateTime);
         end;

    'D': if (Token.IsLexeme('Date', 4)) then
         begin
           ParseConstructorDateTime(True);
           Exit(TgoBsonType.DateTime);
         end;

    'G': if (Token.IsLexeme('GUID', 4)) then
         begin
           ParseConstructorUUID(Token.LexemeStart^);
           Exit(TgoBsonType.DateTime);
         end;

    'H': if (Token.IsLexeme('HexData', 7)) then
         begin
           ParseConstructorHexData;
           Exit(TgoBsonType.Binary);
         end;

    'I': if (Token.IsLexeme('ISODate', 7)) then
         begin
           ParseConstructorISODateTime;
           Exit(TgoBsonType.DateTime);
         end;

    'J': if (Token.IsLexeme('JUUID', 5)) or (Token.IsLexeme('JGUID', 5)) then
         begin
           ParseConstructorUUID(Token.LexemeStart^);
           Exit(TgoBsonType.DateTime);
         end;

    'N': if (Token.IsLexeme('NumberInt', 9)) then
         begin
           ParseConstructorNumber;
           Exit(TgoBsonType.Int32);
         end
         else if (Token.IsLexeme('NumberLong', 10)) then
         begin
           ParseConstructorNumberLong;
           Exit(TgoBsonType.Int64);
         end;

    'O': if (Token.IsLexeme('ObjectId', 8)) then
         begin
           ParseConstructorObjectId;
           Exit(TgoBsonType.ObjectId);
         end;

    'P': if (Token.IsLexeme('PYUUID', 6)) or (Token.IsLexeme('PYGUID', 6)) then
         begin
           ParseConstructorUUID(Token.LexemeStart^);
           Exit(TgoBsonType.DateTime);
         end;

    'T': if (Token.IsLexeme('Timestamp', 9)) then
         begin
           ParseConstructorTimestamp;
           Exit(TgoBsonType.Timestamp);
         end;

    'U': if (Token.IsLexeme('UUID', 4)) then
         begin
           ParseConstructorUUID(Token.LexemeStart^);
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
  if (FPushedToken <> nil) then
  begin
    Assert(FPushedToken = FTokenToPush);
    AToken := FPushedToken;
    FPushedToken := nil;
  end
  else
  begin
    AToken := FTokenBase;
    TScanner.GetNextToken(FBuffer, AToken);
  end;
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
  if (FPushedToken <> nil) then
    raise EInvalidOperation.CreateRes(@RS_BSON_INVALID_READER_STATE);

  FTokenToPush.Assign(AToken);
  FPushedToken := FTokenToPush;
end;

function TgoJsonReader.ReadBinaryData: TgoBsonBinaryData;
begin
  VerifyBsonType(TgoBsonType.Binary);
  State := GetNextState;
  Result := TgoBsonBinaryData.Create(FCurrentValue.Bytes, FCurrentValue.BinarySubType);
end;

function TgoJsonReader.ReadBoolean: Boolean;
begin
  VerifyBsonType(TgoBsonType.Boolean);
  State := GetNextState;
  Result := FCurrentValue.BoolVal;
end;

function TgoJsonReader.ReadBsonType: TgoBsonType;
var
  Token: TToken;
  NoValueFound: Boolean;
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
      CurrentBsonType := ParseDocumentOrExtendedJson;

    TTokenType.Double:
      begin
        CurrentBsonType := TgoBsonType.Double;
        FCurrentValue.DoubleVal := Token.DoubleValue;
      end;

    TTokenType.EndOfFile:
      CurrentBsonType := TgoBsonType.EndOfDocument;

    TTokenType.Int32:
      begin
        CurrentBsonType := TgoBsonType.Int32;
        FCurrentValue.Int32Val := Token.Int32Value;
      end;

    TTokenType.Int64:
      begin
        CurrentBsonType := TgoBsonType.Int64;
        FCurrentValue.Int64Val := Token.Int64Value;
      end;

    TTokenType.RegularExpression:
      begin
        CurrentBsonType := TgoBsonType.RegularExpression;
        SetCurrentValueRegEx(Token);
      end;

    TTokenType.String:
      begin
        CurrentBsonType := TgoBsonType.String;
        FCurrentValue.StrVal := Token.StringValue;
      end;

    TTokenType.UnquotedString:
      begin
        Assert(Token.LexemeLength > 0);
        case Token.LexemeStart^ of
          'B': if (Token.IsLexeme('BinData', 7)) then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 ParseConstructorBinaryData;
               end
               else
                 NoValueFound := True;

          'C': if (Token.IsLexeme('CSUUID', 6)) or (Token.IsLexeme('CSGUID', 6)) then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 ParseConstructorUUID(Token.LexemeStart^);
               end
               else
                 NoValueFound := True;

          'D': if (Token.IsLexeme('Date', 4)) then
               begin
                 { This is the Date() function (without arguments).
                   It should return the current datetime (in UTC) as a
                   JavaScript formatted datetime string. }
                 CurrentBsonType := TgoBsonType.String;
                 ParseConstructorDateTime(False);
               end
               else
                 NoValueFound := True;

          'G': if (Token.IsLexeme('GUID', 4)) then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 ParseConstructorUUID(Token.LexemeStart^);
               end
               else
                 NoValueFound := True;

          'H': if (Token.IsLexeme('HexData', 7)) then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 ParseConstructorHexData;
               end
               else
                 NoValueFound := True;

          'I': if (Token.IsLexeme('Infinity', 8)) then
               begin
                 CurrentBsonType := TgoBsonType.Double;
                 FCurrentValue.DoubleVal := Infinity;
               end
               else if (Token.IsLexeme('ISODate', 7)) then
               begin
                 CurrentBsonType := TgoBsonType.DateTime;
                 ParseConstructorISODateTime;
               end
               else
                 NoValueFound := True;

          'J': if (Token.IsLexeme('JUUID', 5)) or (Token.IsLexeme('JGUID', 5)) then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 ParseConstructorUUID(Token.LexemeStart^);
               end
               else
                 NoValueFound := True;

          'M': if (Token.IsLexeme('MaxKey', 6)) then
                 CurrentBsonType := TgoBsonType.MaxKey
               else if (Token.IsLexeme('MinKey', 6)) then
                 CurrentBsonType := TgoBsonType.MinKey
               else
                 NoValueFound := True;

          'N': if (Token.IsLexeme('NaN', 3)) then
               begin
                 CurrentBsonType := TgoBsonType.Double;
                 FCurrentValue.DoubleVal := NaN;
               end
               else if (Token.IsLexeme('Number', 6)) or (Token.IsLexeme('NumberInt', 9)) then
               begin
                 CurrentBsonType := TgoBsonType.Int32;
                 ParseConstructorNumber;
               end
               else if (Token.IsLexeme('NumberLong', 10)) then
               begin
                 CurrentBsonType := TgoBsonType.Int64;
                 ParseConstructorNumberLong;
               end
               else
                 NoValueFound := True;

          'O': if (Token.IsLexeme('ObjectId', 8)) then
               begin
                 CurrentBsonType := TgoBsonType.ObjectId;
                 ParseConstructorObjectId;
               end
               else
                 NoValueFound := True;

          'P': if (Token.IsLexeme('PYUUID', 6)) or (Token.IsLexeme('PYGUID', 6)) then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 ParseConstructorUUID(Token.LexemeStart^);
               end
               else
                 NoValueFound := True;

          'R': if (Token.IsLexeme('RegExp', 6)) then
               begin
                 CurrentBsonType := TgoBsonType.RegularExpression;
                 ParseConstructorRegularExpression;
               end
               else
                 NoValueFound := True;

          'T': if (Token.IsLexeme('Timestamp', 9)) then
               begin
                 CurrentBsonType := TgoBsonType.Timestamp;
                 ParseConstructorTimestamp;
               end
               else
                 NoValueFound := True;

          'U': if (Token.IsLexeme('UUID', 4)) then
               begin
                 CurrentBsonType := TgoBsonType.Binary;
                 ParseConstructorUUID(Token.LexemeStart^);
               end
               else
                 NoValueFound := True;

          'f': if (Token.IsLexeme('false', 5)) then
               begin
                 CurrentBsonType := TgoBsonType.Boolean;
                 FCurrentValue.BoolVal := False;
               end
               else
                 NoValueFound := True;

          'n': if (Token.IsLexeme('new', 3)) then
                 CurrentBsonType := ParseNew
               else if (Token.IsLexeme('null', 4)) then
                 CurrentBsonType := TgoBsonType.Null
               else
                 NoValueFound := True;

          't': if (Token.IsLexeme('true', 4)) then
               begin
                 CurrentBsonType := TgoBsonType.Boolean;
                 FCurrentValue.BoolVal := True;
               end
               else
                 NoValueFound := True;

          'u': if (Token.IsLexeme('undefined', 9)) then
                 CurrentBsonType := TgoBsonType.Undefined
               else
                 NoValueFound := True;
        else
          NoValueFound := True;
        end;
      end;
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
begin
  VerifyBsonType(TgoBsonType.Binary);
  State := GetNextState;

  if (not (FCurrentValue.BinarySubType in [TgoBsonBinarySubType.Binary, TgoBsonBinarySubType.OldBinary])) then
    raise FBuffer.ParseError(@RS_BSON_INVALID_BINARY_TYPE);

  Result := FCurrentValue.Bytes;
end;

function TgoJsonReader.ReadDateTime: Int64;
begin
  VerifyBsonType(TgoBsonType.DateTime);
  State := GetNextState;
  Result := FCurrentValue.Int64Val;
end;

function TgoJsonReader.ReadDouble: Double;
begin
  VerifyBsonType(TgoBsonType.Double);
  State := GetNextState;
  Result := FCurrentValue.DoubleVal;
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
  Result := FCurrentValue.Int32Val;
end;

function TgoJsonReader.ReadInt64: Int64;
begin
  VerifyBsonType(TgoBsonType.Int64);
  State := GetNextState;
  Result := FCurrentValue.Int64Val;
end;

function TgoJsonReader.ReadJavaScript: String;
begin
  VerifyBsonType(TgoBsonType.JavaScript);
  State := GetNextState;
  Result := FCurrentValue.StrVal;
end;

function TgoJsonReader.ReadJavaScriptWithScope: String;
begin
  VerifyBsonType(TgoBsonType.JavaScriptWithScope);
  PushContext(TgoBsonContextType.JavaScriptWithScope);
  State := TgoBsonReaderState.ScopeDocument;
  Result := FCurrentValue.StrVal;
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
  Result := FCurrentValue.ObjectIdVal;
end;

function TgoJsonReader.ReadRegularExpression: TgoBsonRegularExpression;
var
  I: Integer;
begin
  VerifyBsonType(TgoBsonType.RegularExpression);
  State := GetNextState;
  I := FCurrentValue.StrVal.IndexOf(#1);
  if (I < 0) then
    Result := TgoBsonRegularExpression.Create(FCurrentValue.StrVal)
  else
    Result := TgoBsonRegularExpression.Create(FCurrentValue.StrVal.Substring(0, I),
      FCurrentValue.StrVal.Substring(I + 1));
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
  Result := FCurrentValue.StrVal;
end;

function TgoJsonReader.ReadSymbol: String;
begin
  VerifyBsonType(TgoBsonType.Symbol);
  State := GetNextState;
  Result := FCurrentValue.StrVal;
end;

function TgoJsonReader.ReadTimestamp: Int64;
begin
  VerifyBsonType(TgoBsonType.Timestamp);
  State := GetNextState;
  Result := FCurrentValue.Int64Val;
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

  if Assigned(BM.CurrentToken) then
    FCurrentToken.Assign(BM.CurrentToken)
  else
    FCurrentToken := nil;

  FCurrentValue := BM.CurrentValue;

  if Assigned(BM.PushedToken) then
  begin
    FTokenToPush.Assign(BM.PushedToken);
    FPushedToken := FTokenToPush;
  end
  else
    FPushedToken := nil;

  FBuffer.Current := BM.Current;
end;

procedure TgoJsonReader.SetCurrentValueRegEx(const AToken: TToken);
begin
  { Put in separate (non-inlined) method to avoid string finalization }
  FCurrentValue.StrVal := AToken.LexemeToString;
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

procedure TgoJsonReader.VerifyToken(const AExpectedLexeme: Char);
var
  Token: TToken;
begin
  PopToken(Token);
  if (Token.LexemeLength <> 1) or (Token.LexemeStart^ <> AExpectedLexeme) then
    raise FBuffer.ParseError(@RS_BSON_TOKEN_EXPECTED, [String(AExpectedLexeme), Token.LexemeToString]);
end;

procedure TgoJsonReader.VerifyToken(const AExpectedLexeme: PChar;
  const AExpectedLexemeLength: Integer);
var
  Token: TToken;
begin
  PopToken(Token);
  if (not Token.IsLexeme(AExpectedLexeme, AExpectedLexemeLength)) then
    raise FBuffer.ParseError(@RS_BSON_TOKEN_EXPECTED, [String(AExpectedLexeme), Token.LexemeToString]);
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
  Result.FBuffer := PChar(AJson);
  Result.FCurrent := Result.FBuffer;
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
  Result := FCurrent^;
  case Result of
     #0: ;
    #10: begin
           Inc(FCurrent);
           Inc(FLineNumber);
           FPrevLineStart := FLineStart;
           FLineStart := FCurrent;
         end;
  else
    Inc(FCurrent);
  end;
end;

procedure TgoJsonReader.TBuffer.Unread(const AChar: Char);
begin
  if (AChar = #0) then
    Exit;

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
end;

{ TgoJsonReader.TScanner }

var
  LEXEME_EOF         : array [0..4] of Char = '<eof>';
  LEXEME_BEGIN_OBJECT: Char = '{';
  LEXEME_END_OBJECT  : Char = '}';
  LEXEME_BEGIN_ARRAY : Char = '[';
  LEXEME_END_ARRAY   : Char = ']';
  LEXEME_LEFT_PAREN  : Char = '(';
  LEXEME_RIGHT_PAREN : Char = ')';
  LEXEME_COLON       : Char = ':';
  LEXEME_COMMA       : Char = ',';

class procedure TgoJsonReader.TScanner.CharBeginArray(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
begin
  ABuffer.MarkErrorPos;
  AToken.Initialize(TTokenType.BeginArray, @LEXEME_BEGIN_ARRAY, 1);
end;

class procedure TgoJsonReader.TScanner.CharBeginObject(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
begin
  ABuffer.MarkErrorPos;
  AToken.Initialize(TTokenType.BeginObject, @LEXEME_BEGIN_OBJECT, 1);
end;

class procedure TgoJsonReader.TScanner.CharColon(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
begin
  ABuffer.MarkErrorPos;
  AToken.Initialize(TTokenType.Colon, @LEXEME_COLON, 1);
end;

class procedure TgoJsonReader.TScanner.CharComma(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
begin
  ABuffer.MarkErrorPos;
  AToken.Initialize(TTokenType.Comma, @LEXEME_COMMA, 1);
end;

class procedure TgoJsonReader.TScanner.CharEndArray(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
begin
  ABuffer.MarkErrorPos;
  AToken.Initialize(TTokenType.EndArray, @LEXEME_END_ARRAY, 1);
end;

class procedure TgoJsonReader.TScanner.CharEndObject(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
begin
  ABuffer.MarkErrorPos;
  AToken.Initialize(TTokenType.EndObject, @LEXEME_END_OBJECT, 1);
end;

class procedure TgoJsonReader.TScanner.CharEof(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
begin
  ABuffer.MarkErrorPos;
  AToken.Initialize(TTokenType.EndOfFile, LEXEME_EOF, 5);
end;

class procedure TgoJsonReader.TScanner.CharError(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
var
  Error: EgoJsonParserError;
begin
  ABuffer.ClearErrorPos;
  Error := ABuffer.ParseError(@RS_BSON_UNEXPECTED_TOKEN);
  ABuffer.Unread(AChar);
  raise Error;
end;

class procedure TgoJsonReader.TScanner.CharLeftParen(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
begin
  ABuffer.MarkErrorPos;
  AToken.Initialize(TTokenType.LeftParen, @LEXEME_LEFT_PAREN, 1);
end;

{$IFOPT Q+}
  {$DEFINE HAS_OVERFLOWCHECKS}
  {$OVERFLOWCHECKS OFF}
{$ENDIF}
class procedure TgoJsonReader.TScanner.CharNumberToken(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
{ Lexical grammar:
    NumberLiteral: ['-'] DecimalLiteral
    DecimalLiteral: 'Inifinity'
                  | ['.'] DecimalDigits [ExponentPart]
                  | DecimalDigits '.' [DecimalDigits] [ExponentPart]
    DecimalDigits: ('0'..'9')+
    ExponentPart: ('e' | 'E') ['+' | '-'] DecimalDigits

  There are 3 special values: Inifinity, -Infinity and NaN.
  The values Infinity and NaN are handled elsewhere (in ReadBsonType), so here
  we only need to handle -Infinity. }
const
  NFINITY = 'nfinity';
var
  Current, Start: PChar;
  C: Byte;
  IsNegative, IsNegativeExponent: Boolean;
  I, Power, Exponent: Integer;
  IntegerPart: Int64;
  Value: Double;
begin
  ABuffer.ClearErrorPos;
  Current := ABuffer.Current;
  Start := Current - 1;

  { NumberLiteral: ['-'] DecimalLiteral }
  if (AChar = '-') then
  begin
    IsNegative := True;
    IntegerPart := 0;
    if (Current^ = 'I') then
    begin
      { DecimalLiteral: 'Inifinity' }
      Inc(Current);
      for I := 0 to Length(NFINITY) - 1 do
      begin
        if (Current^ <> NFINITY.Chars[I]) then
        begin
          ABuffer.Current := Current;
          raise ABuffer.ParseError(@RS_BSON_INVALID_NUMBER);
        end;
        Inc(Current);
      end;

      ABuffer.Current := Current;
      C := Byte(Current^);
      if (C in [0..32, Ord(','), Ord('}'), Ord(']'), Ord(')')]) then
        AToken.Initialize(Start, Current - Start, NegInfinity)
      else
        raise ABuffer.ParseError(@RS_BSON_INVALID_NUMBER);
      Exit;
    end;
  end
  else
  begin
    IsNegative := False;
    IntegerPart := Ord(AChar) - Ord('0');
  end;

  { Parse integer part (before optional '.') }
  while True do
  begin
    C := Byte(Current^);
    if (C in [Ord('0')..Ord('9')]) then
    begin
      IntegerPart := (IntegerPart * 10) + (C - Ord('0'));
      Inc(Current);
    end
    else
      Break;
  end;

  if (C in [0..32, Ord(','), Ord('}'), Ord(']'), Ord(')')]) then
  begin
    { Integer value.
      Cannot start with a leading 0 (unless entire number is 0) }
    ABuffer.Current := Current;
    if (IntegerPart <> 0) and (Start^ = '0') then
      raise ABuffer.ParseError(@RS_BSON_INVALID_NUMBER);

    if (IsNegative) then
      IntegerPart := -IntegerPart;

    if (IntegerPart < Integer.MinValue) or (IntegerPart > Integer.MaxValue) then
      AToken.Initialize(Start, Current - Start, IntegerPart)
    else
      AToken.Initialize(Start, Current - Start, Int32(IntegerPart));
    Exit;
  end;

  { Floating-point value }
  Value := IntegerPart;
  Power := 0;

  if (C = Ord('.')) then
  begin
    { Parse fractional part }
    Inc(Current);

    { Fractional part must start with a digit... }
    C := Byte(Current^);
    if (C in [Ord('0')..Ord('9')]) then
    begin
      Value := (Value * 10.0) + (C - Ord('0'));
      Inc(Current);
      Dec(Power);
    end
    else
    begin
      ABuffer.Current := Current;
      raise ABuffer.ParseError(@RS_BSON_INVALID_NUMBER);
    end;

    { ...followed by some more optional digits }
    while True do
    begin
      C := Byte(Current^);
      if (C in [Ord('0')..Ord('9')]) then
      begin
        Value := (Value * 10.0) + (C - Ord('0'));
        Inc(Current);
        Dec(Power);
      end
      else
        Break;
    end;
  end;

  if (C in [Ord('e'), Ord('E')]) then
  begin
    { Parse exponent }
    Exponent := 0;
    Inc(Current);
    C := Byte(Current^);
    IsNegativeExponent := False;
    if (C = Ord('-')) then
    begin
      IsNegativeExponent := True;
      Inc(Current);
      C := Byte(Current^);
    end
    else if (Current^ = '+') then
    begin
      Inc(Current);
      C := Byte(Current^);
    end;

    { Exponent must start with a digit... }
    if (C in [Ord('0')..Ord('9')]) then
    begin
      Exponent := (Exponent * 10) + (C - Ord('0'));
      Inc(Current);
    end
    else
    begin
      ABuffer.Current := Current;
      raise ABuffer.ParseError(@RS_BSON_INVALID_NUMBER);
    end;

    { ...followed by some more optional digits }
    while True do
    begin
      C := Byte(Current^);
      if (C in [Ord('0')..Ord('9')]) then
      begin
        Exponent := (Exponent * 10) + (C - Ord('0'));
        Inc(Current);
      end
      else
        Break;
    end;

    if (IsNegativeExponent) then
      Exponent := -Exponent;

    Inc(Power, Exponent);
  end;

  ABuffer.Current := Current;
  if (C in [0..32, Ord(','), Ord('}'), Ord(']'), Ord(')')]) then
  begin
    Value := Power10(Value, Power);
    if (IsNegative) then
      Value := -Value;
    AToken.Initialize(Start, Current - Start, Value);
  end
  else
    raise ABuffer.ParseError(@RS_BSON_INVALID_NUMBER);
end;
{$IFDEF HAS_OVERFLOWCHECKS}
  {$OVERFLOWCHECKS ON}
{$ENDIF}

class procedure TgoJsonReader.TScanner.CharRegularExpressionToken(
  var ABuffer: TBuffer; const AChar: Char; const AToken: TToken);
var
  Start: PChar;
  State: TRegularExpressionState;
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
          AToken.InitializeRegEx(Start, ABuffer.Current - Start);
          Exit;
        end;

      TRegularExpressionState.Invalid:
        raise ABuffer.ParseError(@RS_BSON_INVALID_REGEX);
    end;
  end;
end;

class procedure TgoJsonReader.TScanner.CharRightParen(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
begin
  ABuffer.MarkErrorPos;
  AToken.Initialize(TTokenType.RightParen, @LEXEME_RIGHT_PAREN, 1);
end;

class procedure TgoJsonReader.TScanner.CharStringToken(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
var
  Current, Start: PChar;
  C: Char;
  S: String;
begin
  ABuffer.ClearErrorPos;
  Current := ABuffer.Current;
  Start := Current - 1;
  while True do
  begin
    C := Current^;
    Inc(Current);
    case C of
      #0:
        begin
          ABuffer.Current := Current;
          raise ABuffer.ParseError(@RS_BSON_INVALID_STRING);
        end;

      '\':
        begin
          SetString(S, Start + 1, Current - Start - 2);
          ABuffer.Current := Current - 1;
          CharStringTokenUnscape(ABuffer, AChar, AToken, Start, S);
          Exit;
        end;

      '''', '"':
        if (C = AChar) then
        begin
          SetString(S, Start + 1, Current - Start - 2);
          AToken.Initialize(TTokenType.String, Start, Current - Start, S);
          ABuffer.Current := Current;
          Exit;
        end;
    end;
  end;
end;

class procedure TgoJsonReader.TScanner.CharStringTokenUnscape(
  var ABuffer: TBuffer; const AQuoteChar: Char; const AToken: TToken;
  const AStart: PChar; const APrefix: String);
var
  CharBuffer: TgoCharBuffer;
  Current: PChar;
  I: Integer;
  C: Char;
  S: String;
begin
  Current := ABuffer.Current;
  CharBuffer.Initialize;
  try
    while True do
    begin
      C := Current^;
      Inc(Current);
      case C of
        #0:
          begin
            ABuffer.Current := Current;
            raise ABuffer.ParseError(@RS_BSON_INVALID_STRING);
          end;

        '\':
          begin
            C := Current^;
            Inc(Current);
            case C of
              '''', '"', '\', '/': CharBuffer.Append(C);
              'b': CharBuffer.Append(#8);
              't': CharBuffer.Append(#9);
              'n': CharBuffer.Append(#10);
              'f': CharBuffer.Append(#12);
              'r': CharBuffer.Append(#13);
              'u': begin
                     ABuffer.Current := Current;
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
                       CharBuffer.Append(Char(I));
                     end
                     else
                       raise ABuffer.ParseError(@RS_BSON_INVALID_STRING);
                     Current := ABuffer.Current;
                   end;
            else
              ABuffer.Current := Current;
              raise ABuffer.ParseError(@RS_BSON_INVALID_STRING);
            end;
          end;

        '''', '"':
          if (C = AQuoteChar) then
          begin
            AToken.Initialize(TTokenType.String, AStart, Current - AStart,
              APrefix + CharBuffer.ToString);
            Exit;
          end
          else
            CharBuffer.Append(C);
      else
        CharBuffer.Append(C);
      end;
    end;
  finally
    CharBuffer.Release;
    ABuffer.Current := Current;
  end;
end;

class procedure TgoJsonReader.TScanner.CharUnquotedStringToken(
  var ABuffer: TBuffer; const AChar: Char; const AToken: TToken);
var
  Start: PChar;
  C: Char;
  Lexeme: String;
begin
  ABuffer.MarkErrorPos;
  Start := ABuffer.Current - 1;
  C := ABuffer.Read;
  while (C = '$') or (C = '_') or (C.IsLetterOrDigit) do
    C := ABuffer.Read;
  ABuffer.Unread(C);
  SetString(Lexeme, Start, ABuffer.Current - Start);
  AToken.Initialize(TTokenType.UnquotedString, Start, ABuffer.Current - Start, Lexeme);
end;

class procedure TgoJsonReader.TScanner.CharWhitespace(var ABuffer: TBuffer;
  const AChar: Char; const AToken: TToken);
var
  C: Char;
begin
  C := ABuffer.Read;
  if (C >= #$80) then
    CharError(ABuffer, C, AToken)
  else
    FCharHandlers[C](ABuffer, C, AToken);
end;

class procedure TgoJsonReader.TScanner.GetNextToken(var ABuffer: TBuffer;
  const AToken: TToken);
var
  C: Char;
begin
  C := ABuffer.Read;
  while (C <> #0) and (C <= ' ') do
    C := ABuffer.Read;

  if (C >= #$80) then
    CharError(ABuffer, C, AToken)
  else
    FCharHandlers[C](ABuffer, C, AToken);
end;

class procedure TgoJsonReader.TScanner.Initialize;
var
  C: Char;
begin
  for C := #0 to #127 do
    FCharHandlers[C] := CharError;

  FCharHandlers[#0] := CharEof;
  for C := #1 to #32 do
    FCharHandlers[C] := CharWhitespace;
  for C := '0' to '9' do
    FCharHandlers[C] := CharNumberToken;
  for C := 'a' to 'z' do
    FCharHandlers[C] := CharUnquotedStringToken;
  for C := 'A' to 'Z' do
    FCharHandlers[C] := CharUnquotedStringToken;

  FCharHandlers['{'] := CharBeginObject;
  FCharHandlers['}'] := CharEndObject;
  FCharHandlers['['] := CharBeginArray;
  FCharHandlers[']'] := CharEndArray;
  FCharHandlers['('] := CharLeftParen;
  FCharHandlers[')'] := CharRightParen;
  FCharHandlers[':'] := CharColon;
  FCharHandlers[','] := CharComma;
  FCharHandlers[''''] := CharStringToken;
  FCharHandlers['"'] := CharStringToken;
  FCharHandlers['/'] := CharRegularExpressionToken;
  FCharHandlers['-'] := CharNumberToken;
  FCharHandlers['$'] := CharUnquotedStringToken;
  FCharHandlers['_'] := CharUnquotedStringToken;
end;

class function TgoJsonReader.TScanner.IsWhitespace(const AChar: Char): Boolean;
begin
//  Result := AChar.IsWhitespace; // Official, but slow
  Result := (AChar <= ' ');
end;

{ TgoJsonReader.TToken }

procedure TgoJsonReader.TToken.Assign(const AOther: TToken);
begin
  if (AOther = Self) then
    Exit;

  FTokenType := AOther.FTokenType;
  FLexemeStart := AOther.FLexemeStart;
  FLexemeLength := AOther.FLexemeLength;
  FStringValue := AOther.FStringValue;
  FValue := AOther.FValue;
end;

procedure TgoJsonReader.TToken.Initialize(const ATokenType: TTokenType;
  const ALexemeStart: PChar; const ALexemeLength: Integer);
begin
  FTokenType := ATokenType;
  FLexemeStart := ALexemeStart;
  FLexemeLength := ALexemeLength;
end;

procedure TgoJsonReader.TToken.Initialize(const ATokenType: TTokenType;
  const ALexemeStart: PChar; const ALexemeLength: Integer;
  const AStringValue: String);
begin
  FTokenType := ATokenType;
  FLexemeStart := ALexemeStart;
  FLexemeLength := ALexemeLength;
  FStringValue := AStringValue;
end;

procedure TgoJsonReader.TToken.Initialize(const ALexemeStart: PChar;
  const ALexemeLength: Integer; const ADoubleValue: Double);
begin
  FTokenType := TTokenType.Double;
  FLexemeStart := ALexemeStart;
  FLexemeLength := ALexemeLength;
  FValue.DoubleValue := ADoubleValue;
end;

procedure TgoJsonReader.TToken.Initialize(const ALexemeStart: PChar;
  const ALexemeLength: Integer; const AInt32Value: Int32);
begin
  FTokenType := TTokenType.Int32;
  FLexemeStart := ALexemeStart;
  FLexemeLength := ALexemeLength;
  FValue.Int64Value := AInt32Value; // Clear upper 32 bits
end;

procedure TgoJsonReader.TToken.Initialize(const ALexemeStart: PChar;
  const ALexemeLength: Integer; const AInt64Value: Int64);
begin
  FTokenType := TTokenType.Int64;
  FLexemeStart := ALexemeStart;
  FLexemeLength := ALexemeLength;
  FValue.Int64Value := AInt64Value;
end;

procedure TgoJsonReader.TToken.InitializeRegEx(const ALexemeStart: PChar;
  const ALexemeLength: Integer);
begin
  FTokenType := TTokenType.RegularExpression;
  FLexemeStart := ALexemeStart;
  FLexemeLength := ALexemeLength;
end;

function TgoJsonReader.TToken.IsLexeme(const AValue: PChar;
  const AValueLength: Integer): Boolean;
begin
  Result := (FLexemeLength = AValueLength)
    and CompareMem(AValue, FLexemeStart, AValueLength * SizeOf(Char));
end;

function TgoJsonReader.TToken.LexemeToString: String;
begin
  SetString(Result, FLexemeStart, FLexemeLength);
end;

{ TgoJsonReader.TJsonBookmark }

constructor TgoJsonReader.TJsonBookmark.Create(const AState: TgoBsonReaderState;
  const ACurrentBsonType: TgoBsonType; const ACurrentName: String;
  const AContextIndex: Integer; const ACurrentToken: TToken;
  const ACurrentValue: TValue; const APushedToken: TToken;
  const ACurrent: PChar);
begin
  inherited Create(AState, ACurrentBsonType, ACurrentName);
  FContextIndex := AContextIndex;
  if Assigned(ACurrentToken) then
  begin
    FCurrentToken := TToken.Create;
    FCurrentToken.Assign(ACurrentToken);
  end;
  FCurrentValue := ACurrentValue;
  if Assigned(APushedToken) then
  begin
    FPushedToken := TToken.Create;
    FPushedToken.Assign(APushedToken);
  end;
  FCurrent := ACurrent;
end;

destructor TgoJsonReader.TJsonBookmark.Destroy;
begin
  FCurrentToken.Free;
  FPushedToken.Free;
  inherited;
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
  FIndex := 0;
end;

procedure TgoBsonDocumentReader.TContext.Initialize(
  const AContextType: TgoBsonContextType; const AArray: TgoBsonArray);
begin
  FContextType := AContextType;
  FArray := AArray;
  FIndex := 0;
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
