unit Grijjy.RemotePush.Receiver;

{$I Grijjy.inc}

interface

uses
  SysUtils,
  DateUtils,
  Messaging,
  System.PushNotification,
  {$IFDEF ANDROID}
  FMX.PushNotification.Android,
  {$ENDIF}
  {$IFDEF IOS}
  FMX.PushNotification.iOS,
  FMX.Helpers.iOS,
  iOSAPI.UIKit,
  {$ENDIF}
  FMX.Platform;

type
  { Remote notification message }
  TgoRemoteNotificationMessage = class(TMessage)
  private
    FDataKey: String;
    FJson: String;
    FActivated: Boolean;
  public
    constructor Create(const ADataKey, AJson: String; const AActivated: Boolean);
    property DataKey: String read FDataKey;
    property Json: String read FJson;

    { Whether message is activated by the user (tapping in it) }
    property Activated: Boolean read FActivated;
  end;

  { Device token change message }
  TgoDeviceTokenChangeMessage = class(TMessage)
  private
    FDeviceToken: String;
  public
    constructor Create(const ADeviceToken: String);
    property DeviceToken: String read FDeviceToken;
  end;

type
  { Remote push receiver instance }
  TgoRemotePushReceiver = class(TObject)
  private
    FPushService: TPushService;
    FPushServiceConnection: TPushServiceConnection;
    FDeviceToken: String;
    FForeground: Boolean;
    procedure CheckDeviceToken;
  private
    procedure OnChange(Sender: TObject; AChange: TPushService.TChanges);
    procedure OnReceiveNotificationEvent(Sender: TObject; const ANotification: TPushServiceNotification);
    procedure ApplicationEventHandler(const Sender: TObject;
      const Msg: TMessage);
  protected
    function GetNumber: Integer;
    procedure SetNumber(const AValue: Integer);
  public
    constructor Create(const AGCMAppId: UnicodeString);
    destructor Destroy; override;
  public
    property DeviceToken: String read FDeviceToken;
    property Number: Integer read GetNumber write SetNumber;
  end;

implementation

{ TRemoteNotificationMessage }

constructor TgoRemoteNotificationMessage.Create(const ADataKey, AJson: String; const AActivated: Boolean);
begin
  inherited Create;
  FDataKey := ADataKey;
  FJson := AJson;
  FActivated := AActivated;
end;

{ TDeviceTokenChangeMessage }

constructor TgoDeviceTokenChangeMessage.Create(const ADeviceToken: String);
begin
  inherited Create;
  FDeviceToken := ADeviceToken;
end;

{ TgoRemotePushReceiver }

constructor TgoRemotePushReceiver.Create(const AGCMAppId: UnicodeString);
begin
  FDeviceToken := '';
  FForeground := True;
  TMessageManager.DefaultManager.SubscribeToMessage(TApplicationEventMessage, ApplicationEventHandler);

  {$IFDEF ANDROID}
  FPushService := TPushServiceManager.Instance.GetServiceByName(TPushService.TServiceNames.GCM);
  { Android: When you call register, it’s often going to fail with an IOException
    containing the message SERVICE_NOT_AVAILABLE. }
  {$ENDIF}
  {$IFDEF IOS}
  FPushService := TPushServiceManager.Instance.GetServiceByName(TPushService.TServiceNames.APS);
  {$ENDIF}
  if FPushService <> nil then
  begin
    {$IFDEF ANDROID}
    FPushService.AppProps[TPushService.TAppPropNames.GCMAppID] := AGCMAppId;
    {$ENDIF}
    FPushServiceConnection := TPushServiceConnection.Create(FPushService);
    if FPushServiceConnection <> nil then
    begin
      FPushServiceConnection.OnChange := OnChange;
      FPushServiceConnection.OnReceiveNotification := OnReceiveNotificationEvent;
      FPushServiceConnection.Active := True;
    end;
  end;
end;

destructor TgoRemotePushReceiver.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TApplicationEventMessage, ApplicationEventHandler);
  if FPushServiceConnection <> nil then
    FPushServiceConnection.Free;
  if FPushService<> nil then
    FPushService.Free;
  inherited;
end;

procedure TgoRemotePushReceiver.CheckDeviceToken;
var
  DeviceTokenChangeMessage: TgoDeviceTokenChangeMessage;
  DeviceToken: String;
begin
  DeviceToken := FPushService.DeviceTokenValue[TPushService.TDeviceTokenNames.DeviceToken];
  if DeviceToken <> '' then
  begin
    FDeviceToken := DeviceToken;
    DeviceTokenChangeMessage := TgoDeviceTokenChangeMessage.Create(FDeviceToken);
    TMessageManager.DefaultManager.SendMessage(Self, DeviceTokenChangeMessage);
  end;
end;

procedure TgoRemotePushReceiver.OnChange(Sender: TObject; AChange: TPushService.TChanges);
begin
  CheckDeviceToken;
end;

procedure TgoRemotePushReceiver.OnReceiveNotificationEvent(Sender: TObject; const ANotification: TPushServiceNotification);
var
  RemoteNotificationMessage: TgoRemoteNotificationMessage;
  Activated: Boolean;
  {$IFDEF IOS}
  UIApp: UIApplication;
  {$ENDIF}
begin
  {$IFDEF IOS}
  UIApp := TUIApplication.Wrap(TUIApplication.OCClass.sharedApplication);
  Activated := Boolean(UIApp.applicationState);
  {$ELSE}
  Activated := not FForeground;
  {$ENDIF}

  { This event is received with the notification immediately if the app is already running
    or delayed when the notification is clicked and the app is launched }
  RemoteNotificationMessage := TgoRemoteNotificationMessage.Create(ANotification.DataKey, ANotification.Json.ToString, Activated);
  TMessageManager.DefaultManager.SendMessage(Self, RemoteNotificationMessage);
end;

procedure TgoRemotePushReceiver.ApplicationEventHandler(const Sender: TObject;
  const Msg: TMessage);
begin
  Assert(Assigned(Msg));
  Assert(Msg is TApplicationEventMessage);

  { For Android platforms we track the active state of the application
    to determine whether the user pressed triggered the notification.  A possible
    better solution is to implement ParsePushBroadcastReceiver }
  case TApplicationEventMessage(Msg).Value.Event of
    TApplicationEvent.WillBecomeInactive:
      FForeground := False;
    TApplicationEvent.BecameActive:
      FForeground := True;
  end;
end;

function TgoRemotePushReceiver.GetNumber: Integer;
begin
  {$IFDEF IOS}
  Result := SharedApplication.ApplicationIconBadgeNumber;
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

procedure TgoRemotePushReceiver.SetNumber(const AValue: Integer);
begin
  {$IFDEF IOS}
  SharedApplication.setApplicationIconBadgeNumber(AValue);
  {$ENDIF}
end;

end.
