unit Grijjy.RemotePush.Sender;

{ Remote push notifications for iOS and Android }

{$I Grijjy.inc}

{ You should create and reuse an instance of this class to avoid creating
  multiple connections to the push notification host.  One model would be to
  perform notifications in batches based upon time. }

interface

uses
  Classes,
  SysUtils,
  Grijjy.Http,
  Grijjy.SocketPool.Win,
  Grijjy.Bson;

type
  { Remote push sender instance }
  TgoRemotePushSender = class(TObject)
  protected
    FHttp: TgoHTTPClient;
    FHttp2: TgoHTTPClient;
  private
    { Android }
    FAndroidAPIKey: String;
  private
    { iOS }
    FAPNSCertificate: TBytes;
    FAPNSKey: TBytes;
    FAPNSTopic: String;
  private
    { JSON payload format for Google }
    function GoogleCloud_Json_Payload(const ADeviceToken, ATitle, AMessage: String): String;

    { Google cloud push notification }
    function GoogleCloud_Send(const AJSON: String;
      out AResponse: String; out AStatusCode: Integer): Boolean;
  private
    { JSON payload format for Apple/iOS }
    function APNs_Json_Payload(const ATitle, AMessage: String;
      const ABadge: Integer; const ASound: String): String;

    { Apple/iOS push notification }
    function APNs_Send(const AJSON: String; const ADeviceToken: String;
      out AResponse: String; out AStatusCode: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
  public
    { Send push notification }
    function Send(const APlatform: TOSVersion.TPlatform; const ADeviceToken: String;
      const ATitle, AMessage: String): Boolean;
  public
    { Android API Key for your app }
    property AndroidAPIKey: String read FAndroidAPIKey write FAndroidAPIKey;

    { iOS Certificate }
    property APNSCertificate: TBytes read FAPNSCertificate write FAPNSCertificate;

    { iOS Key }
    property APNSKey: TBytes read FAPNSKey write FAPNSKey;

    { iOS Topic }
    property APNSTopic: String read FAPNSTopic write FAPNSTopic;
  end;

implementation

uses
  System.SyncObjs,
  DateUtils,
  System.IOUtils;

function TgoRemotePushSender.GoogleCloud_Json_Payload(const ADeviceToken: String;
  const ATitle, AMessage: String): String;
var
  Doc, DocData: TgoBsonDocument;
  Ids: TgoBsonArray;
begin
  DocData := TgoBsonDocument.Create;
  DocData['title'] := ATitle.Substring(0, 500);
  DocData['message'] := AMessage.Substring(0, 500); { limit to 500 chars }

  { append custom data to json here }

  Ids:= TgoBsonArray.Create;
  Ids.Add(ADeviceToken);

  Doc := TgoBsonDocument.Create;
  Doc['to'] := ADeviceToken;
  Doc['data'] := DocData;
  Result := Doc.ToJson; { cannot exceed 4096 bytes }
end;

function TgoRemotePushSender.GoogleCloud_Send(const AJSON: String; out AResponse: String; out AStatusCode: Integer): Boolean;
begin
  if FHttp = nil then
  begin
    FHttp := TgoHTTPClient.Create;
    FHttp.Authorization := 'key=' + FAndroidAPIKey;
    FHttp.ContentType := 'application/json';
  end;
  FHttp.RequestBody := AJSON;
  AResponse := FHttp.Post('https://gcm-http.googleapis.com/gcm/send');
  AStatusCode := FHttp.ResponseStatusCode;
  Result := AStatusCode = 200;
end;

function TgoRemotePushSender.APNs_Json_Payload(const ATitle, AMessage: String;
  const ABadge: Integer; const ASound: String): String;
var
  Doc, DocAlert, DocPayload: TgoBsonDocument;
begin
  DocAlert := TgoBsonDocument.Create;
  DocAlert['title'] := ATitle.Substring(0, 500);
  DocAlert['body'] := AMessage.Substring(0, 500); { limit to 500 chars }

  DocPayload := TgoBsonDocument.Create;
  DocPayload['alert'] := DocAlert;
  DocPayload['badge'] := ABadge;
  DocPayload['sound'] := ASound;

  Doc := TgoBsonDocument.Create;
  Doc['aps'] := DocPayload;

  { append custom data to json here }

  Result := Doc.ToJson; { cannot exceed 4096 bytes for HTTP/2 iOS 9 or later }
end;

function TgoRemotePushSender.APNs_Send(const AJSON: String; const ADeviceToken: String;
  out AResponse: String; out AStatusCode: Integer): Boolean;
begin
  if FHttp2 = nil then
  begin
    FHttp2 := TgoHTTPClient.Create(True);
    FHttp2.Certificate := FAPNSCertificate;
    FHttp2.PrivateKey := FAPNSKey;
    FHttp2.RequestHeaders.AddOrSet('apns-topic', FAPNSTopic);
//    FHttp2.RequestHeaders.AddOrSet('apns-id', '<guid>');
//    FHttp2.RequestHeaders.AddOrSet('apns-expiration', '0');
//    FHttp2.RequestHeaders.AddOrSet('apns-priority', '10');
  end;
  FHttp2.RequestBody := AJSON;
  AResponse := FHttp2.Post('https://api.push.apple.com/3/device/' + ADeviceToken);
  AStatusCode := FHttp2.ResponseStatusCode;
  Result := AStatusCode = 200;
end;

{ TgoRemotePushSender }

constructor TgoRemotePushSender.Create;
begin
  FHttp := nil;
  FHttp2 := nil;
end;

destructor TgoRemotePushSender.Destroy;
begin
  if FHttp <> nil then
    FHttp.Free;
  if FHttp2 <> nil then
    FHttp2.Free;
  inherited;
end;

function TgoRemotePushSender.Send(const APlatform: TOSVersion.TPlatform;
  const ADeviceToken, ATitle, AMessage: String): Boolean;
var
  JSON: String;
  Response: String;
  StatusCode: Integer;
begin
  case APlatform of
    TOSVersion.TPlatform.pfiOS:
    begin
      JSON := APNs_Json_Payload(ATitle, AMessage, 1, 'default');
      Result := APNs_Send(JSON, ADeviceToken, Response, StatusCode);
    end;
    TOSVersion.TPlatform.pfAndroid:
    begin
      JSON := GoogleCloud_Json_Payload(ADeviceToken, ATitle, AMessage);
      Result := GoogleCloud_Send(JSON, Response, StatusCode);
    end;
  else
    Result := False;
  end;
end;

end.
