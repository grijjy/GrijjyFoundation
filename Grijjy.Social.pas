unit Grijjy.Social;

{ Cross social network types and classes }

{ Note: This unit should only used by clients as it will embed social libraries and SDKs }

{$I Grijjy.inc}

interface

uses
  System.Messaging,
  {$IFDEF TWTR}
  Grijjy.TWTR,
  {$ENDIF}
  Grijjy.FBSDK;

type
  TgoSocialNetwork = (None, Facebook, Twitter);

type
  TgoSocialLogin = record
  public
    Result: Boolean;
    Network: TgoSocialNetwork;
    Id: String;
    AccessToken: String;
  public
    procedure Initialize;
  end;

  TgoSocialLoginMessage = class(TMessage<TgoSocialLogin>)
  public
    constructor Create(const ASocialLogin: TgoSocialLogin);
  end;

type
  TgoSocial = class
    class var FFacebook: TgoFacebook;
    {$IFDEF TWTR}
    class var FTwitter: TTwitter;
    {$ENDIF}
  public
    class function Facebook: TgoFacebook; static;
    {$IFDEF TWTR}
    class function Twitter: TgoTwitter; static;
    {$ENDIF}
  public
    procedure Login(const ANetwork: TgoSocialNetwork);
    procedure GetSelf(const ANetwork: TgoSocialNetwork);
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TgoSocialLogin }

procedure TgoSocialLogin.Initialize;
begin
  Result := False;
  Network := TgoSocialNetwork.None;
  Id := '';
  AccessToken := '';
end;

{ TgoSocialLoginMessage }

constructor TgoSocialLoginMessage.Create(const ASocialLogin: TgoSocialLogin);
begin
  inherited Create(ASocialLogin);
end;

{ TgoSocial }

constructor TgoSocial.Create;
begin
  {$IFDEF TWTR}
  FTwitter := nil;
  {$ENDIF}
  FFacebook := nil;
end;

destructor TgoSocial.Destroy;
begin
  {$IFDEF TWTR}
  if FTwitter <> nil then
    FTwitter.Free;
  {$ENDIF}
  if FFacebook <> nil then
    FFacebook.Free;
  inherited;
end;

{$IFDEF TWTR}
class function TgoSocial.Twitter: TgoTwitter;
begin
  if FTwitter = nil then
    FTwitter := TgoTwitter.Create;
  Result := FTwitter;
end;
{$ENDIF}

class function TgoSocial.Facebook: TgoFacebook;
begin
  if FFacebook = nil then
    FFacebook := TgoFacebook.Create;
  Result := FFacebook;
end;

procedure TgoSocial.Login(const ANetwork: TgoSocialNetwork);
begin
  case ANetwork of
    TgoSocialNetwork.Facebook: Facebook.Login;
    {$IFDEF TWTR}
    TgoSocialNetwork.Twitter: Twitter.Login;
    {$ENDIF}
  end;
end;

procedure TgoSocial.GetSelf(const ANetwork: TgoSocialNetwork);
begin
  case ANetwork of
    TgoSocialNetwork.Facebook: Facebook.GetSelf;
    {$IFDEF TWTR}
    TgoSocialNetwork.Twitter: Twitter.GetSelf;
    {$ENDIF}
  end;
end;

end.
