unit Grijjy.Uri;

{ URI helper }

{$I Grijjy.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Net.URLClient;

type
  TgoURI = record
  private
    FURI: TURI;
  public
    Scheme: String;
    Username: String;
    Password: String;
    Host: String;
    Port: Integer;
    Path: String;
    Query: String;
    Params: String;
    Fragment: String;
  public
    constructor Create(const AUri: String);
    function ToString: String;
  end;

implementation

{ TgoURI }

constructor TgoURI.Create(const AUri: String);
var
  I: Integer;
begin
  FURI := TURI.Create(AUri);
  Scheme := FURI.Scheme;
  Username := FURI.Username;
  Password := FURI.Password;
  Host := FURI.Host;
  Port := FURI.Port;
  Path := FURI.Path;
  Query := FURI.Query;
  for I := 0 to Length(FURI.Params) - 1 do
    Params := Params + FURI.Params[I].Name + '=' + FURI.Params[I].Value + '&';
  Params := Params.Substring(0, Params.Length - 1);
  Fragment := FURI.Fragment;
end;

function TgoURI.ToString: String;
var
  Auth: String;
begin
  if Username <> '' then
    Auth := Username + ':' + Password + '@'
  else
    Auth := '';
  Result := Scheme + '://' + Auth + Host;
  if ((Port <> -1) and (Port <> 0)) and
     ((SameText(Scheme, 'http') and (Port <> 80)) or (SameText(Scheme, 'https') and (Port <> 443))) then
    Result := Result + ':' + IntToStr(Port);
  Result := Result + Path;
  if Length(Params) > 0 then
    Result := Result + '?' + Params;
end;

end.
