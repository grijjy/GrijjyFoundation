unit Grijjy.CloudLogging.Protocol;

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.SysUtils,
  System.Messaging,
  Grijjy.ProtocolBuffers,
  PascalZMQ,
  ZMQ.ClientProtocol,
  ZMQ.Shared;

type
  { Protocol buffer that defines the message and metadata for a log message }
  TgoLogMessageProtocol = record
  public
    { The log message }
    [Serialize(1)] MessageText: String;

    { The log level (Info, Warning or Error) }
    [Serialize(2)] Level: Integer;

    { The ID of the process that send the message }
    [Serialize(3)] ProcessId: FixedUInt32;

    { The ID of the thread that send the message }
    [Serialize(4)] ThreadId: FixedUInt32;

    { The name of the application that send the message }
    [Serialize(5)] AppName: String;

    { The date and time at which the message was sent }
    [Serialize(6)] TimeStamp: TDateTime;

    { Describes the format of any optional data }
    [Serialize(7)] DataFormat: Integer;

    { Any optional data to send along with the messsage }
    [Serialize(8)] Data: TBytes;
  end;

type
  { Protocol buffer that defines a command from the log viewer }
  TgoLogCommandProtocol = record
  public
    { The command }
    [Serialize(1)] Command: Integer;

    { Serialized arguments }
    [Serialize(2)] Args: TBytes;
  end;

type
  TgoHandleArray = record
    { Array of handles }
    [Serialize(1)] Handles: TArray<THandle>;
  end;

type
  { Text alignment options for watch values }
  TgoWatchAlign = (Left, Center, Right);

type
  { A live watch as used by TgoLogLiveWatchesProtocol }
  TgoLiveWatch = record
  public
    { Name of the live watch }
    [Serialize(1)] Name: String;

    { Value of the live watch }
    [Serialize(2)] Value: String;

    { Display alignment of the value. }
    [Serialize(3)] ValueAlign: TgoWatchAlign;
  end;

type
  { Protocol buffer that defines a list of live watches }
  TgoLogLiveWatchesProtocol = record
  public
    { Array of live watches }
    [Serialize(1)] Watches: TArray<TgoLiveWatch>;
  end;

type
  { Protocol buffer that defines a memory usage report }
  TgoLogMemoryUsageProtocol = record
  public type
    { Represents a single instance }
    TInstance = record
      { Caption to use to display details about the instance in the log viewer.
        For classes derived from TComponent, this will be the name of the owner
        and name of the instance if available. Otherwise, it will be its
        ToString value. }
      [Serialize(1)] Caption: String;
    end;
  public type
    { Single entry for a class }
    TEntry = record
      { Name of this class. }
      [Serialize(1)] ClassName: String;

      { Handle of this class. This is a TClass. But since TClass cannot be
        used across process boundaries, it is typecast to a THandle. It is
        only used for identification purposes. }
      [Serialize(2)] ClassHandle: THandle;

      { Number of live instances for this class. }
      [Serialize(3)] InstanceCount: Integer;

      { Live instances for this class (if requested). }
      [Serialize(4)] Instances: TArray<TInstance>;
    end;
    PEntry = ^TEntry;
  public
    { Array of class names and its number of instances }
    [Serialize(1)] Entries: TArray<TEntry>;

    { Approximate number of bytes allocated by the current process. }
    [Serialize(2)] AllocatedBytes: Int64;
  end;

type
  TgoCloudLogger = class(TZMQClientProtocol)
  private
    { Internal }
    FBroker: String;
    FAppName: String;
    FProcessId: Cardinal;

    procedure SetBroker(const Value: String);
  private
    class function GetMemoryUsage(const AArgs: TBytes): TBytes; static;
    class function GetLiveWatches: TBytes; static;
  protected
    { Implements the DoRecv from the client protocol class }
    procedure DoRecv(const ACommand: TZMQCommand;
      var AMsg: PZMessage; var ASentFrom: PZFrame); override;
  public
    constructor Create;
    destructor Destroy; override;

    { Sends a message to the specified service, with optional data }
    procedure Send(const AService: String; const AMsg: String;
      const ALevel, ADataFormat: Integer; const AData: TBytes); reintroduce;

    property Broker: String read FBroker write SetBroker;
  end;

type
  { This message is broadcast to receive fill a TgoLogMemoryUsageProtocol
    record with information about live instances.
    The Grijjy.CloudLogging.InstanceTracker unit listens for this message. }
  TgoGetInstancesMessage = class(TMessage)
  private
    FClasses: TArray<TClass>;
  public
    constructor Create(const AClasses: TArray<TClass>);

    { Is set to an array of classes for which to receive details (instances).
      This are the classes that are expanded in the corresponding tree view in
      the log viewer. If nil, only class summaries are returned. }
    property Classes: TArray<TClass> read FClasses;
  public
    { The protocol to be filled in by the message listener. }
    Protocol: TgoLogMemoryUsageProtocol;
  end;

const
  { These constants are used internally and are shared with the Log Viewer.
    You should not use these yourself. }
  LOG_FORMAT_NONE     = 0;
  LOG_FORMAT_TSTRINGS = 1;
  LOG_FORMAT_MEMORY   = 2;
  LOG_FORMAT_OBJECT   = 3;

  LOG_FORMAT_CONNECTED    = -1;
  LOG_FORMAT_MEMORY_USAGE = -2;
  LOG_FORMAT_LIVE_WATCHES = -3;

implementation

uses
  System.Classes,
  {$IF Defined(MSWINDOWS)}
  Winapi.Windows,
  {$ELSEIF Defined(ANDROID)}
  Androidapi.Helpers,
  {$ELSEIF Defined(IOS)}
  iOSapi.Foundation,
  Macapi.Helpers,
  Macapi.ObjectiveC,
  {$ENDIF}
  {$IF Defined(POSIX)}
  Posix.Unistd,
  {$ENDIF}
  Grijjy.SysUtils,
  Grijjy.CloudLogging;

{ TgoCloudLogger }

constructor TgoCloudLogger.Create;
{$IF Defined(IOS)}
var
  AppNameKey: Pointer;
  AppBundle: NSBundle;
  NSAppName: NSString;
{$ENDIF}
begin
  inherited Create;
  {$IF Defined(IOS)}
  AppNameKey := (StrToNSStr('CFBundleName') as ILocalObject).GetObjectID;
  AppBundle := TNSBundle.Wrap(TNSBundle.OCClass.mainBundle);
  NSAppName := TNSString.Wrap(AppBundle.infoDictionary.objectForKey(AppNameKey));
  FAppName := UTF8ToString(NSAppName.UTF8String);
  {$ELSEIF Defined(Android)}
  FAppName := TAndroidHelper.ApplicationTitle;
  {$ELSE}
  FAppName := ChangeFileExt(ExtractFileName(GetModuleName(0)), '');
  {$ENDIF}

  {$IF Defined(MSWINDOWS)}
  FProcessId := GetCurrentProcessId;
  {$ELSEIF Defined(POSIX)}
  FProcessId := getpid;
  {$ENDIF}
end;

destructor TgoCloudLogger.Destroy;
begin
  inherited;
end;

{ Sends a message to the specified service, with optional userdefined and data }
procedure TgoCloudLogger.Send(const AService: String; const AMsg: String;
  const ALevel, ADataFormat: Integer; const AData: TBytes);
var
  Msg: PZMessage;
  Protocol: TgoLogMessageProtocol;
begin
  Msg := TZMessage.Create;
  try
    Protocol.MessageText := AMsg;
    Protocol.Level := ALevel;
    Protocol.ProcessId := FProcessId;
    Protocol.ThreadId := TThread.CurrentThread.ThreadID;
    Protocol.AppName := FAppName;
    Protocol.TimeStamp := Now;
    Protocol.DataFormat := ADataFormat;
    Protocol.Data := AData;
    Msg.PushProtocolBuffer<TgoLogMessageProtocol>(Protocol);

    if (AService = '') then
      inherited Send(GrijjyLog.Service, Msg)
    else
      inherited Send(AService, Msg);
  finally
    Msg.Free;
  end;
end;

procedure TgoCloudLogger.SetBroker(const Value: String);
begin
  if (Value <> FBroker) then
  begin
    FBroker := Value;
    Connect(FBroker);
  end;
end;

{ Implements the DoRecv from the client protocol class }
procedure TgoCloudLogger.DoRecv(const ACommand: TZMQCommand;
  var AMsg: PZMessage; var ASentFrom: PZFrame);
var
  Service: String;
  Protocol: TgoLogCommandProtocol;
  ReturnData: TBytes;
begin
  Service := AMsg.PopString;
  AMsg.PopProtocolBuffer(Protocol);

  ReturnData := nil;
  case Protocol.Command of
    LOG_FORMAT_MEMORY_USAGE:
      ReturnData := GetMemoryUsage(Protocol.Args);

    LOG_FORMAT_LIVE_WATCHES:
      ReturnData := GetLiveWatches;
  else
    Exit;
  end;

  Send(Service, '', Ord(TgoLogLevel.Error), Protocol.Command, ReturnData);
end;

class function TgoCloudLogger.GetLiveWatches: TBytes;
var
  Msg: TgoLiveWatchesMessage;
  Protocol: TgoLogLiveWatchesProtocol;
begin
  Msg := TgoLiveWatchesMessage.Create;
  try
    {$IFDEF CONSOLE}
    TMessageManager.DefaultManager.SendMessage(nil, Msg, False);
    {$ELSE}
    { Listeners for this message may need to access the GUI, so always send
      this message in the UI thread. }
    TThread.Synchronize(nil,
      procedure
      begin
        TMessageManager.DefaultManager.SendMessage(nil, Msg, False);
      end);
    {$ENDIF}

    Protocol.Watches := Msg.GetWatches;
    Result := TgoProtocolBuffer.Serialize(Protocol);
  finally
    Msg.Free;
  end;
end;

class function TgoCloudLogger.GetMemoryUsage(const AArgs: TBytes): TBytes;
var
  Msg: TgoGetInstancesMessage;
  Handles: TgoHandleArray;
begin
  Handles.Handles := nil;
  if Assigned(AArgs) then
    TgoProtocolBuffer.Deserialize(Handles, AArgs);

  Msg := TgoGetInstancesMessage.Create(TArray<TClass>(Handles.Handles));
  try
    TMessageManager.DefaultManager.SendMessage(nil, Msg, False);
    Msg.Protocol.AllocatedBytes := goGetAllocatedMemory;
    Result := TgoProtocolBuffer.Serialize(Msg.Protocol);
  finally
    Msg.Free;
  end;
end;

{ TgoGetInstancesMessage }

constructor TgoGetInstancesMessage.Create(const AClasses: TArray<TClass>);
begin
  inherited Create;
  FClasses := AClasses;
end;

end.
