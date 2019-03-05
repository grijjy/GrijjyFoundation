unit Grijjy.Scram;
{ Routines for handling Salted Challenge Response Authentication Mechanism (SCRAM) }

{ https://tools.ietf.org/html/rfc5802
  Currently supports SCRAM-SHA-1 and SCRAM-SHA-256 }

{$INCLUDE 'Grijjy.inc'}

interface

uses
  System.SysUtils,
  Grijjy.System;

const
  { GS2 header }
  SCRAM_GS2_HEADER = 'n,,';

type
  { Scram mechanism }
  TgoScramMechanism = (SCRAM_SHA_1, SCRAM_SHA_256);

  { Scram authentication helper class }
  TgoScram = class
  private
    FNonce: String;
    FScramGs2Header: String;
    FMechanism: TgoScramMechanism;
    FUsername: String;
    FPassword: String;

    { Step 1 }
    FClientFirstMsg: String;
    FConversationId: Integer;
    FServerFirstMsg: String;
    FServerNonce, FServerSalt: String;
    FServerIterations: Integer;

    { Step 2 }
    FSaltedPassword: TBytes;
    FAuthMessage: String;
    FServerSecondMsg: String;
    FActualServerSignature, FExpectedServerSignature: String;
    FClientFinalMsg: String;
  protected
    function PBKDF2(const APassword: TBytes; const ASalt: TBytes; const ACount: Integer;
      const AKeylength: Integer): TBytes;
  public
    constructor Create(const AMechanism: TgoScramMechanism; const AUsername, APassword: String);
    destructor Destroy; override;
  public
    { Creates the first client to server message }
    procedure CreateFirstMsg;

    { Processes the first server to client response message }
    procedure HandleServerFirstMsg(const AConversationId: Integer; const AServerFirstMsg: String);

    { Processes the second server to client response message }
    procedure HandleServerSecondMsg(const AServerSecondMsg: String);

    { Returns True if the expected server signature matches the actual signature }
    function ValidSignature: Boolean;
  public
    { Client random nonce }
    property Nonce: String read FNonce;

    { Client first message }
    property ClientFirstMsg: String read FClientFirstMsg;

    { Client conversation id }
    property ConversationId: Integer read FConversationId;

    { Client final message }
    property ClientFinalMsg: String read FClientFinalMsg;
  end;

implementation

uses
  System.Math,
  System.Hash,
  System.Generics.Collections,
  Grijjy.BinaryCoding;

function CreateNonce: String;
var
  Index: Integer;
const
  Charset: String = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
begin
  Randomize;
  for Index := 0 to 31 do
    Result := Result + Charset[Random(62) + 1]; { Note: This is not considered crypto strength, use OpenSsl's Rand() instead }
end;

function SplitString(const AString: String; const ASeparator: array of String): TDictionary<String, String>;
var
  Strings: TArray<String>;
  S, Key, Value: String;
  Index: Integer;
begin
  Result := TDictionary<String, String>.Create;

  Strings := AString.Split(ASeparator);
  for S in Strings do
  begin
    Index := S.IndexOf('=');
    if Index = -1 then
      Continue;

    Key := S.Substring(0, Index);
    Value := S.Substring(Index + 1);
    Result.Add(Key, Value);
  end;
end;

function BytesToHexString(const ABytes: TBytes): String;
var
  I: Integer;
begin
  for I := Low(ABytes) to High(ABytes) do
    Result := Result + IntToHex(ABytes[I], 2);
end;

procedure XorBytes(var ADestBytes: TBytes; const ASourceBytes: TBytes);
var
  I: Integer;
begin
  for I := Low(ADestBytes) to High(ADestBytes) do
    ADestBytes[I] := ADestBytes[I] xor ASourceBytes[I];
end;

function ConcatenateBytes(const ADestBytes: TBytes; const ASourceBytes: TBytes): TBytes; inline;
begin
  SetLength(Result, Length(ADestBytes) + Length(ASourceBytes));
  if Length(ADestBytes) > 0 then
    Move(ADestBytes[Low(ADestBytes)], Result[Low(Result)], Length(ADestBytes));
  if Length(ASourceBytes) > 0 then
    Move(ASourceBytes[Low(ASourceBytes)], Result[Low(Result)+Length(ADestBytes)], Length(ASourceBytes));
end;

function SaslPrepPassword(APassword: String): String;
var
  I: Integer;
begin
  Result := APassword;
  for I := 1 to Length(APassword) do
    case Word(APassword[I]) of
      $00A0, $1680, $2000, $2001, $2002, $2003, $2004, $2005, $2006, $2007, $2008, $2009, $200A, $202F, $205F, $3000:
      begin
        Result[I] := #$0020;
      end;
    end;
end;

{ TgoScram }

constructor TgoScram.Create(const AMechanism: TgoScramMechanism; const AUsername, APassword: String);
begin
  FMechanism := AMechanism;
  FUsername := AUsername;
  FPassword := APassword;

  FNonce := CreateNonce;
  FScramGs2Header := TEncoding.Utf8.GetString(goBase64Encode(TEncoding.Utf8.GetBytes(SCRAM_GS2_HEADER)));
end;

destructor TgoScram.Destroy;
begin

  inherited;
end;

function TgoScram.PBKDF2(const APassword: TBytes; const ASalt: TBytes; const ACount: Integer;
  const AKeylength: Integer): TBytes;
var
  BlockCount: Integer;
  I: Int32;
  F: TBytes;
  U: TBytes;
  J: Integer;
  T: TBytes;
  HashLength: Integer;

  function INT_32_BE(const AValue: Int32): TBytes;
  begin
    Result := TBytes.Create(AValue shr 24, AValue shr 16, AValue shr 8, AValue);
  end;

begin
  if FMechanism = TgoScramMechanism.SCRAM_SHA_1 then
    HashLength := Length(THashSHA1.GetHMACAsBytes('',''))
  else
    HashLength := Length(THashSHA2.GetHMACAsBytes('',''));
  BlockCount := Ceil(AKeylength / HashLength);
  for I := 1 to BlockCount do
  begin
    if FMechanism = TgoScramMechanism.SCRAM_SHA_1 then
      F := THashSHA1.GetHMACAsBytes(ConcatenateBytes(ASalt, INT_32_BE(I)), APassword)
    else
      F := THashSHA2.GetHMACAsBytes(ConcatenateBytes(ASalt, INT_32_BE(I)), APassword);
    U := Copy(F);
    for J := 2 to ACount do
    begin
      if FMechanism = TgoScramMechanism.SCRAM_SHA_1 then
        U := THashSHA1.GetHMACAsBytes(U, APassword)
      else
        U := THashSHA2.GetHMACAsBytes(U, APassword);
      XorBytes(F, U);
    end;
    T := ConcatenateBytes(T, F);
  end;
  Result := Copy(T, Low(T), AKeylength);
end;

procedure TgoScram.CreateFirstMsg;
var
  Username: String;
begin
  { Convert username characters so special characters are handled properly within payloads }
  Username := FUsername.Replace('=', '=3D').Replace(',', '=2C');

  { Create the string of the client to server first message }
  FClientFirstMsg := 'n=' + Username + ',r=' + FNonce;
end;

procedure TgoScram.HandleServerFirstMsg(const AConversationId: Integer;
  const AServerFirstMsg: String);
var
  ServerMsg: TDictionary<String, String>;
  Iterations: String;
  SHA1: THashSHA1;
  SHA256: THashSHA2;
  MD5: THashMD5;
  MD5Digest: TBytes;
  HashedPassword: String;
  ClientFinalNoPf: String;
  ClientKey, StoredKey, ClientSignature, ClientProof: TBytes;
begin
  FConversationId := AConversationId;

  { ex: r=PbeWTe0x6is8tezKDg44MeIsmVWOD1cis3W4HBsbkZEKSEkj+EEGvJiwNcK11dr5,s=J5P6oNGeHYmVlWE2j5a6tw==,i=10000 }
  FServerFirstMsg := AServerFirstMsg;

  { Parse the first server message }
  ServerMsg := SplitString(FServerFirstMsg, [',']);
  try
    ServerMsg.TryGetValue('r', FServerNonce);
    ServerMsg.TryGetValue('s', FServerSalt);
    ServerMsg.TryGetValue('i', Iterations);
    FServerIterations := StrToIntDef(Iterations, 10000);
  finally
    ServerMsg.Free;
  end;

  { Step 2 }

  if FMechanism = TgoScramMechanism.SCRAM_SHA_1 then
  begin
    { Calculate a hash of the normalized password }
    MD5 := THashMD5.Create;
    MD5.Update(TEncoding.UTF8.GetBytes(FUsername + ':mongo:' + FPassword));
    MD5Digest := MD5.HashAsBytes;
    HashedPassword := BytesToHexString(MD5Digest).ToLower;

    { Calculate a Password-Based Key Derivation Function hash of the password using the server provided salt }
    FSaltedPassword := PBKDF2(TEncoding.Utf8.GetBytes(HashedPassword),
      goBase64Decode(TEncoding.Utf8.GetBytes(FServerSalt)),
      FServerIterations,
      20);
  end
  else
  begin
    { Calculate a Password-Based Key Derivation Function hash of the password using the server provided salt }
    FSaltedPassword := PBKDF2(TEncoding.Utf8.GetBytes(SaslPrepPassword(FPassword)),
      goBase64Decode(TEncoding.Utf8.GetBytes(FServerSalt)),
      FServerIterations,
      32);
  end;

  { Create the client final no proof
    Note that biws is a constant and is the just the GS2 header string 'n,,' Base64 encoded }
  { ex: "c=biws,r=fyko+d2lbbFgONRv9qkxdawLHo+Vgk7qvUOKUwuWLIWg4l/9SraGMHEE" }
  ClientFinalNoPf := 'c=' + FScramGs2Header + ',r=' + FServerNonce;

  { ex: "n=user,r=fyko+d2lbbFgONRv9qkxdawL,r=fyko+d2lbbFgONRv9qkxdawLHo+Vgk7qvUOKUwuWLIWg4l/9SraGMHEE,s=rQ9ZY3MntBeuP3E1TDVC4w==,i=10000,c=biws,r=fyko+d2lbbFgONRv9qkxdawLHo+Vgk7qvUOKUwuWLIWg4l/9SraGMHEE" }
  FAuthMessage := FClientFirstMsg + ',' + FServerFirstMsg + ',' + ClientFinalNoPf;

  { The string 'Client Key' is also constant and is used as a default message to be hashed by the (salted) password }
  { ex: 6e ca 60 b8 b0 46 77 1f c7 17 40 92 de 6e 7e 83 78 59 b3 56 }
  if FMechanism = TgoScramMechanism.SCRAM_SHA_1 then
    ClientKey := THashSHA1.GetHMACAsBytes('Client Key', FSaltedPassword)
  else
    ClientKey := THashSHA2.GetHMACAsBytes('Client Key', FSaltedPassword);

  { ex: a7 9c fa 9f b5 2d a9 ff a9 2c 19 1a 78 99 38 4f 77 81 38 e0 }
  if FMechanism = TgoScramMechanism.SCRAM_SHA_1 then
  begin
    SHA1 := THashSHA1.Create;
    SHA1.Update(ClientKey);
    StoredKey := SHA1.HashAsBytes;
  end
  else
  begin
    SHA256 := THashSHA2.Create;
    SHA256.Update(ClientKey);
    StoredKey := SHA256.HashAsBytes;
  end;

  { ex: 5e e7 f3 48 ab 9d ee 7b 9b 87 7c ae 7f 07 07 a2 20 78 73 70 }
  if FMechanism = TgoScramMechanism.SCRAM_SHA_1 then
    ClientSignature := THashSHA1.GetHMACAsBytes(FAuthMessage, StoredKey)
  else
    ClientSignature := THashSHA2.GetHMACAsBytes(FAuthMessage, StoredKey);

  { ex: 30 2d 93 f0 1b db 99 64 5c 90 3c 3c a1 69 79 21 58 21 c0 26 }
  ClientProof := ClientKey;
  XorBytes(ClientProof, ClientSignature);

  { ex: "c=biws,r=fyko+d2lbbFgONRv9qkxdawLHo+Vgk7qvUOKUwuWLIWg4l/9SraGMHEE,p=MC2T8BvbmWRckDw8oWl5IVghwCY=" }
  FClientFinalMsg := ClientFinalNoPf + ',p=' + TEncoding.Utf8.GetString(goBase64Encode(ClientProof));
end;

procedure TgoScram.HandleServerSecondMsg(const AServerSecondMsg: String);
var
  ServerMsg: TDictionary<String, String>;
  ServerKey: TBytes;
begin
  FServerSecondMsg := AServerSecondMsg;

  { Now it is our chance to validate the server and check that it also knows the user's password.
    Note the string "Server Key" is constant and is used as a default message to be hashed by the (salted) password. }
  ServerMsg := SplitString(FServerSecondMsg, [',']);
  try
    ServerMsg.TryGetValue('v', FActualServerSignature);
  finally
    ServerMsg.Free;
  end;

  { ex: 95 1a d5 1f 2a 8c 5f e3 8e a8 6b e9 72 fb fd 6a 79 40 f0 84 }
  if FMechanism = TgoScramMechanism.SCRAM_SHA_1 then
    ServerKey := THashSHA1.GetHMACAsBytes('Server Key', FSaltedPassword)
  else
    ServerKey := THashSHA2.GetHMACAsBytes('Server Key', FSaltedPassword);

  { The actual and expected signature should match }
  { ex: "UMWeI25JD1yNYZRMpZ4VHvhZ9e0=" }
  if FMechanism = TgoScramMechanism.SCRAM_SHA_1 then
    FExpectedServerSignature := TEncoding.Utf8.GetString(goBase64Encode(THashSHA1.GetHMACAsBytes(FAuthMessage, ServerKey)))
  else
    FExpectedServerSignature := TEncoding.Utf8.GetString(goBase64Encode(THashSHA2.GetHMACAsBytes(FAuthMessage, ServerKey)));
end;

function TgoScram.ValidSignature: Boolean;
begin
  Result := FExpectedServerSignature = FActualServerSignature;
end;

end.
