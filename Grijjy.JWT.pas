unit Grijjy.JWT;

{ Java Web Tokens }

interface

uses
  System.SysUtils;

const
  { RSA with SHA256 }
  JWT_RS256 = '{"alg":"RS256","typ":"JWT"}';

  { TODO: Added HMAC with SHA256 token support }

{ Creates a Java Web Token using the provided private key in PEM format }
function JavaWebToken(const APrivateKey: TBytes; const AHeader, APayload: String; out AJWT: String): Boolean;

implementation

uses
  Grijjy.OpenSSL,
  Grijjy.BinaryCoding;

function JavaWebToken(const APrivateKey: TBytes; const AHeader, APayload: String; out AJWT: String): Boolean;
var
  Data: TBytes;
  JWS: TBytes;
begin
  Data := goBase64Encode(BytesOf(AHeader)) + [Ord('.')] + goBase64Encode(BytesOf(APayload));
  if TgoSSLHelper.Sign_RSASHA256(Data, APrivateKey, JWS) then
  begin
    AJWT := StringOf(Data) + '.' + StringOf(goBase64Encode(JWS));
    Result := True;
  end
  else
    Result := False;
end;

end.
