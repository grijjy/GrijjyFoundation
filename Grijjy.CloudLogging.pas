unit Grijjy.CloudLogging;

interface

uses
  System.Classes,
  System.SysUtils,
  System.TypInfo,
  System.Messaging,
  System.Generics.Collections,
  Grijjy.Bson.IO,
  Grijjy.Collections,
  Grijjy.CloudLogging.Protocol;

type
  { Logging levels for the GrijjyLog.Send and GrijjyLog.SetLogLevel routines. }
  TgoLogLevel = (
    { Informational message. By default, informational messages are logged in
      DEBUG mode, but not in RELEASE mode.
      Call Grijjy.SetLogLevel(TgoLogLevel.Info) to always log
      informational messages (as well as all other message levels) }
    Info,

    { Warning message. Warning messages are logged by default, unless you call
      grSetLogLevel(TgrLogLevel.Error) to only log error messages. }
    Warning,


    { Error message. Error messages are always logged. }
    Error);

type
  { Static class that forms the main entry for logging messages. }
  GrijjyLog = class // static
  public const
    DEFAULT_BROKER = 'tcp://localhost:7337';
    DEFAULT_SERVICE = 'Default';
  {$REGION 'Internal Declarations'}
  private class var
    FLogLevel: TgoLogLevel;
    FBroker: String;
    FService: String;
    FLogger: TgoCloudLogger;
    FMaxInstancesPerClass: Integer;
  private
    class procedure Send(const AMsg: String; const ALevel: TgoLogLevel;
      const AService: String; const ADataFormat: Integer;
      const AData: TBytes); overload; static;
    class function ObjectToJson(const AObject: TObject;
      const AMinFieldVisibility: TMemberVisibility;
      const AMaxNesting: Integer): String;
    class procedure WriteObject(const ALevel: Integer; const AObject: TObject;
      const AWriter: IgoJsonWriter; const AMinFieldVisibility: TMemberVisibility;
      const AMaxNesting: Integer; const AVisitedObjects: TgoSet<TObject>);
  public
    class constructor Create;
    class destructor Destroy;
  {$ENDREGION 'Internal Declarations'}
  public
    { Connects the the broker.

      Parameters:
        ABroker: host name for the logging broker.
        AService: service name for the logging viewer.

      If you do not call this method, then the logger will automatically connect
      the first time you call one of the Send methods (using the Broker and
      Service property values). }
    class procedure Connect(const ABroker, AService: String); static;

    { Sets the log/verbosity level of messages logged with Log.

      * Info: all messages are logged.
      * Warning: only warning and error messages are logged.
      * Error: only error messages are logged.

      The default log level is Info in DEBUG mode and Warning in RELEASE mode.

      Parameters:
        ALevel: the logging level. }
    class procedure SetLogLevel(const ALevel: TgoLogLevel); static;

    { Platform-independent logging routine.

      Parameters:
        AMsg: the message to log.
        ALevel: (optional) the level of the log message. Defaults to Warning.
        AService: (optional) the service to use when sending the message with ZMQ.

      Note that logging is also enabled in RELEASE configurations, so you may
      want to surround the log call with an IFDEF DEBUG directive to only log in
      debug builds. }
    class procedure Send(const AMsg: String;
      const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; inline; static;

    { Platform-independent logging routine.

      Parameters:
        AMsg: the message to log.
        AArgs: arguments to format the message.
        ALevel: (optional) the level of the log message. Defaults to Warning.
        AService: (optional) the service to use when sending the message with ZMQ.

      Note that logging is also enabled in RELEASE configurations, so you may
      want to surround the log call with an IFDEF DEBUG directive to only log in
      debug builds. }
    class procedure Send(const AMsg: String; const AArgs: array of const;
      const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; static;

    { These Log overloads allow for logging simple values. }
    class procedure Send(const AMsg, AValue: String;
      const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; inline; static;

    class procedure Send(const AMsg: String; const AValue: Integer;
      const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; inline; static;

    class procedure Send(const AMsg: String; const AValue: Boolean;
      const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; inline; static;

    class procedure Send(const AMsg: String; const AValue: Extended;
      const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; inline; static;

    class procedure Send(const AMsg: String; const AValue: TStrings;
      const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; inline; static;

    class procedure Send(const AMsg: String; const AValue: TBytes;
      const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; inline; static;

    class procedure Send(const AMsg: String; const AValue: Pointer;
      const ASize: Integer; const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; inline; static;

    { Logs an object and all of its fields and properties.

      Parameters:
        AValue: the object whose fields and properties to log.
        AMinFieldVisibility: (optional) minimum field visibility. Defaults to
          mvPublic so only public and published fields are send. Set to
          mvProtected to also include protected fields, or mvPrivate to include
          all fields.
          Note that properties are only send if they are published!
        AMaxNesting: (optional) maximum number of levels of subobjects to send.
          Set to 1 to only send the fields and properties of this object. Higher
          values will also send fields and properties of subobjects. Defaults
          to 4 to save space and time.

      Note that this can potentially be a slow and bandwidth-intensive call since
      RTTI is used to query the object, and it may result in large data loads
      depending on the AMinVisibility and AMaxNesting parameters. }
    class procedure Send(const AMsg: String; const AValue: TObject;
      const AMinFieldVisibility: TMemberVisibility = mvPublic;
      const AMaxNesting: Integer = 4;
      const ALevel: TgoLogLevel = TgoLogLevel.Warning;
      const AService: String = ''); overload; static;

    { Logs the start of a method block. Subsequent calls to Log will be treated
      as part of this method, until ExitMethod is called.

      Parameters:
        AInstance: object instance whose method is begin entered.
        AMethodName: name of the method that is being entered.

      SeeAlso:
        ExitMethod }
    class procedure EnterMethod(const AInstance: TObject;
      const AMethodName: String; const AService: String = ''); overload; static;

    { Logs the start of a method block. Subsequent calls to Log will be treated
      as part of this method, until ExitMethod is called.

      Parameters:
        AMethodName: name of the procedure or function that is being entered.

      SeeAlso:
        ExitMethod }
    class procedure EnterMethod(const AMethodName: String;
      const AService: String = ''); overload; inline; static;

    { Logs the end of a method block, previously started with EnterMethod.

      Parameters:
        AInstance: object instance whose method is begin exited.
        AMethodName: name of the method that is being exited.

      SeeAlso:
        EnterMethod }
    class procedure ExitMethod(const AInstance: TObject;
      const AMethodName: String; const AService: String = ''); overload; static;

    { Logs the end of a method block, previously started with EnterMethod.

      Parameters:
        AMethodName: name of the procedure or function that is being exited.

      SeeAlso:
        EnterMethod }
    class procedure ExitMethod(const AMethodName: String;
      const AService: String = ''); overload; inline; static;

    { Hostname for the logging broker.
      Changing this value will reconnect to the new broker. }
    class property Broker: String read FBroker write FBroker;

    { Service name for the logging viewer.
      You can change this value at any time. }
    class property Service: String read FService write FService;

    { When the log viewer request a list of all instances of a specific class,
      this property determines the maximum number of instances returned.
      Defaults to 100 to limit traffic and memory use. }
    class property MaxInstancesPerClass: Integer read FMaxInstancesPerClass write FMaxInstancesPerClass;
  end;

type
  { When the Grijjy Log Viewer requests a list of live watches, a message
    of this type is broadcast. You can subscribe to this message type to add
    to the list of watches.

    Multiple listeners can subscribe to this message type and add their own
    watches.

    In your message handler, you can use the Add methods to add your own
    watches.

    This message is send from the UI thread. }
  TgoLiveWatchesMessage = class(TMessage)
  {$REGION 'Internal Declarations'}
  private
    FWatches: TList<TgoLiveWatch>;
  {$ENDREGION 'Internal Declarations'}
  public
    constructor Create;
    destructor Destroy; override;

    { Various methods for adding watches for different types of data.

      Parameters:
        AName: the name of the watch.
        AValue: the value of the watch.
        AValueAlign: (optional) display text alignment of the watch. Defaults
          to Right alignment for numeric values, or Left alignment otherwise. }
    procedure Add(const AName, AValue: String;
      const AValueAlign: TgoWatchAlign = TgoWatchAlign.Left); overload;
    procedure Add(const AName: String; const AValue: Integer;
      const AValueAlign: TgoWatchAlign = TgoWatchAlign.Right); overload;
    procedure Add(const AName: String; const AValue: Double;
      const ANumDecimals: Integer = 2;
      const AValueAlign: TgoWatchAlign = TgoWatchAlign.Right); overload;
    procedure Add(const AName: String; const AValue: Boolean;
      const AValueAlign: TgoWatchAlign = TgoWatchAlign.Left); overload;

    { Returns the current array of watches. Used internally. }
    function GetWatches: TArray<TgoLiveWatch>;
  end;

implementation

uses
  System.ZLib,
  System.Rtti,
  Grijjy.SysUtils;

const
  LOG_LEVEL_ENTER_METHOD = Ord(TgoLogLevel.Error) + 1;
  LOG_LEVEL_EXIT_METHOD  = LOG_LEVEL_ENTER_METHOD + 1;

{ GrijjyLog }

class procedure GrijjyLog.Connect(const ABroker, AService: String);
begin
  FBroker := ABroker;
  FService := AService;
  Send('', TgoLogLevel.Error, AService, LOG_FORMAT_CONNECTED, nil);
end;

class constructor GrijjyLog.Create;
begin
  FLogLevel := TgoLogLevel.Warning;
  FBroker := DEFAULT_BROKER;
  FService := DEFAULT_SERVICE;
  FMaxInstancesPerClass := 100;
  FLogger := nil;
end;

class destructor GrijjyLog.Destroy;
begin
  FreeAndNil(FLogger);
end;

class procedure GrijjyLog.EnterMethod(const AMethodName, AService: String);
begin
  Send(AMethodName, TgoLogLevel(LOG_LEVEL_ENTER_METHOD), AService, 0, nil);
end;

class procedure GrijjyLog.EnterMethod(const AInstance: TObject;
  const AMethodName, AService: String);
begin
  if Assigned(AInstance) then
  begin
    if (AInstance is TComponent) then
      EnterMethod(AInstance.ClassName + '(' + TComponent(AInstance).Name + ').' + AMethodName, AService)
    else
      EnterMethod(AInstance.ClassName + '.' + AMethodName, AService)
  end
  else
    EnterMethod(AMethodName, AService);
end;

class procedure GrijjyLog.ExitMethod(const AMethodName, AService: String);
begin
  Send(AMethodName, TgoLogLevel(LOG_LEVEL_EXIT_METHOD), AService, 0, nil);
end;

class function GrijjyLog.ObjectToJson(const AObject: TObject;
  const AMinFieldVisibility: TMemberVisibility;
  const AMaxNesting: Integer): String;
var
  VisitedObjects: TgoSet<TObject>;
  Writer: IgoJsonWriter;
begin
  VisitedObjects := nil;
  TRttiContext.KeepContext;
  try
    VisitedObjects := TgoSet<TObject>.Create;
    Writer := TgoJsonWriter.Create;
    WriteObject(1, AObject, Writer, AMinFieldVisibility, AMaxNesting, VisitedObjects);
    Result := Writer.ToJson;
  finally
    VisitedObjects.Free;
    TRttiContext.DropContext;
  end;
end;

class procedure GrijjyLog.ExitMethod(const AInstance: TObject;
  const AMethodName, AService: String);
begin
  if Assigned(AInstance) then
  begin
    if (AInstance is TComponent) then
      ExitMethod(AInstance.ClassName + '(' + TComponent(AInstance).Name + ').' + AMethodName, AService)
    else
      ExitMethod(AInstance.ClassName + '.' + AMethodName, AService)
  end
  else
    ExitMethod(AMethodName, AService);
end;

class procedure GrijjyLog.Send(const AMsg: String; const ALevel: TgoLogLevel;
  const AService: String; const ADataFormat: Integer; const AData: TBytes);
begin
  if (FLogger = nil) then
    FLogger := TgoCloudLogger.Create;

  FLogger.Broker := FBroker;
  FLogger.Send(AService, AMsg, Ord(ALevel), ADataFormat, AData);
end;

class procedure GrijjyLog.Send(const AMsg: String; const AValue: Integer;
  const ALevel: TgoLogLevel; const AService: String);
begin
  if (ALevel >= FLogLevel) then
    Send(AMsg + ' = ' + IntToStr(AValue), ALevel, AService, 0, nil);
end;

class procedure GrijjyLog.Send(const AMsg: String; const AValue: Boolean;
  const ALevel: TgoLogLevel; const AService: String);
begin
  if (ALevel >= FLogLevel) then
    Send(AMsg + ' = ' + BoolToStr(AValue, True), ALevel, AService, 0, nil);
end;

class procedure GrijjyLog.Send(const AMsg, AValue: String;
  const ALevel: TgoLogLevel; const AService: String);
begin
  if (ALevel >= FLogLevel) then
    Send(AMsg + ' = ' + AValue, ALevel, AService, 0, nil);
end;

class procedure GrijjyLog.Send(const AMsg: String; const ALevel: TgoLogLevel;
  const AService: String);
begin
  if (ALevel >= FLogLevel) then
    Send(AMsg, ALevel, AService, LOG_FORMAT_NONE, nil);
end;

class procedure GrijjyLog.Send(const AMsg: String; const AArgs: array of const;
  const ALevel: TgoLogLevel; const AService: String);
begin
  if (ALevel >= FLogLevel) then
    Send(Format(AMsg, AArgs, goUSFormatSettings), ALevel, AService, 0, nil);
end;

class procedure GrijjyLog.Send(const AMsg: String; const AValue: Pointer;
  const ASize: Integer; const ALevel: TgoLogLevel; const AService: String);
var
  Bytes: TBytes;
begin
  if (ALevel >= FLogLevel) and Assigned(AValue) and (ASize > 0) then
  begin
    SetLength(Bytes, ASize);
    Move(AValue^, Bytes[0], ASize);
    Send(AMsg, ALevel, AService, LOG_FORMAT_MEMORY, Bytes);
  end;
end;

class procedure GrijjyLog.Send(const AMsg: String; const AValue: TObject;
  const AMinFieldVisibility: TMemberVisibility; const AMaxNesting: Integer;
  const ALevel: TgoLogLevel; const AService: String);
var
  Json: String;
  Bytes, ZBytes: TBytes;
begin
  if (ALevel >= FLogLevel) and Assigned(AValue) then
  begin
    ZBytes := nil;
    Json := ObjectToJson(AValue, AMinFieldVisibility, AMaxNesting);
    if (Json <> '') then
    begin
      Bytes := TEncoding.UTF8.GetBytes(Json);
      ZCompress(Bytes, ZBytes);
    end;
    Send(AMsg, ALevel, AService, LOG_FORMAT_OBJECT, ZBytes);
  end;
end;

class procedure GrijjyLog.Send(const AMsg: String; const AValue: TBytes;
  const ALevel: TgoLogLevel; const AService: String);
begin
  if (ALevel >= FLogLevel) then
    Send(AMsg, ALevel, AService, LOG_FORMAT_MEMORY, AValue);
end;

class procedure GrijjyLog.Send(const AMsg: String; const AValue: Extended;
  const ALevel: TgoLogLevel; const AService: String);
begin
  if (ALevel >= FLogLevel) then
    Send(AMsg + ' = ' + FloatToStr(AValue, goUSFormatSettings), ALevel, AService, 0, nil);
end;

class procedure GrijjyLog.Send(const AMsg: String; const AValue: TStrings;
  const ALevel: TgoLogLevel; const AService: String);
var
  S: String;
  Bytes: TBytes;
begin
  if (ALevel >= FLogLevel) and Assigned(AValue) then
  begin
    S := AValue.CommaText;
    Bytes := TEncoding.UTF8.GetBytes(S);
    Send(AMsg, ALevel, AService, LOG_FORMAT_TSTRINGS, Bytes);
  end;
end;

class procedure GrijjyLog.SetLogLevel(const ALevel: TgoLogLevel);
begin
  FLogLevel := ALevel;
end;

class procedure GrijjyLog.WriteObject(const ALevel: Integer;
  const AObject: TObject; const AWriter: IgoJsonWriter;
  const AMinFieldVisibility: TMemberVisibility; const AMaxNesting: Integer;
  const AVisitedObjects: TgoSet<TObject>);
var
  Context: TRttiContext;
  ObjType: TRttiType;
  Field: TRttiField;
  Prop: TRttiProperty;
  Names: TgoSet<String>;

  procedure WriteValue(const AName: String; const AValue: TValue);
  var
    SubObject: TObject;
    TypeData: PTypeData;
    S: String;
  begin
    if (Names.Contains(AName)) then
      Exit;

    Names.Add(AName);
    case AValue.Kind of
      tkClass:
        begin
          SubObject := AValue.AsObject;
          if (SubObject = nil) then
            AWriter.WriteString(AName, '(empty)')
          else if (ALevel < AMaxNesting) then
          begin
            AWriter.WriteName(AName);
            WriteObject(ALevel + 1, SubObject, AWriter, AMinFieldVisibility,
              AMaxNesting, AVisitedObjects);
          end;
        end;

      tkSet:
        begin
          { Cannot use AValue.ToString here since it calls SetToString, and
            SetToString raises an AV when type info is insufficient. }
          S := '';
          TypeData := AValue.TypeData;
          if Assigned(TypeData) and Assigned(TypeData.CompType) then
            S := AValue.ToString;
          if (S = '') then
            S := '[???]';
          AWriter.WriteString(AName, S);
        end
    else
      AWriter.WriteString(AName, AValue.ToString);
    end;
  end;

begin
  if (AObject = nil) or (ALevel > AMaxNesting) then
    Exit;

  if (AVisitedObjects.Contains(AObject)) then
  begin
    AWriter.WriteString(Format('(%s @ %p)', [AObject.ClassName, Pointer(AObject)]));
    Exit;
  end;

  AWriter.WriteStartDocument;
  try
    AWriter.WriteString('@Class', AObject.ClassName);

    AVisitedObjects.Add(AObject);
    ObjType := Context.GetType(AObject.ClassType);
    if (ObjType = nil) then
      Exit;

    Names := TgoSet<String>.Create;
    try
      for Field in ObjType.GetFields do
      begin
        if (Field.Visibility >= AMinFieldVisibility) then
        try
          WriteValue(Field.Name, Field.GetValue(AObject));
        except
          { Ignore this field }
        end;
      end;

      for Prop in ObjType.GetProperties do
      begin
        if (Prop.Visibility = mvPublished) and (Prop.IsReadable) then
        try
          WriteValue(Prop.Name, Prop.GetValue(AObject));
        except
          { Ignore this property }
        end;
      end;
    finally
      Names.Free;
    end;
  finally
    AWriter.WriteEndDocument;
  end;
end;

{ TgoLiveWatchesMessage }

procedure TgoLiveWatchesMessage.Add(const AName, AValue: String;
  const AValueAlign: TgoWatchAlign);
var
  Watch: TgoLiveWatch;
begin
  Watch.Name := AName;
  Watch.Value := AValue;
  Watch.ValueAlign := AValueAlign;
  FWatches.Add(Watch);
end;

procedure TgoLiveWatchesMessage.Add(const AName: String; const AValue: Integer;
  const AValueAlign: TgoWatchAlign);
begin
  Add(AName, IntToStr(AValue), AValueAlign);
end;

procedure TgoLiveWatchesMessage.Add(const AName: String; const AValue: Boolean;
  const AValueAlign: TgoWatchAlign);
begin
  Add(AName, BoolToStr(AValue, True), AValueAlign);
end;

procedure TgoLiveWatchesMessage.Add(const AName: String; const AValue: Double;
  const ANumDecimals: Integer; const AValueAlign: TgoWatchAlign);
begin
  Add(AName, FloatToStrF(AValue, ffFixed, 15, ANumDecimals, goUSFormatSettings),
    AValueAlign);
end;

constructor TgoLiveWatchesMessage.Create;
begin
  inherited Create;
  FWatches := TList<TgoLiveWatch>.Create;
end;

destructor TgoLiveWatchesMessage.Destroy;
begin
  FWatches.Free;
  inherited;
end;

function TgoLiveWatchesMessage.GetWatches: TArray<TgoLiveWatch>;
begin
  Result := FWatches.ToArray;
end;

end.
