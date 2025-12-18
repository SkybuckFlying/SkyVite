unit Wallet.Hd_Bip.Derivation.Main;

interface

uses
  SysUtils Classes common.types crypto.ed25519 common.errors System.RegularExpressions,
  Wallet.Hd.Bip.Derivation.Bip.Example,
  Wallet.Hd.Bip.Derivation.Bip.Main.Test,
  Wallet.Hd.Bip.Derivation.Main.Test;

const
  ConstViteAccountPrefix = 'm/44''/666666''';
  ConstVitePrimaryAccountPath = 'm/44''/666666''/0''';
  ConstViteAccountPathFormat = 'm/44''/666666''/%d''';
  ConstFirstHardenedIndex = 1 shl 31;
  ConstSeedModifier = 'ed25519 blake2b seed';

type
  TDerivationKey = class
  private
    mKey: TBytes;
    mChainCode: TBytes;
    function GetKey: TBytes;
    function GetChainCode: TBytes;
  public
    constructor Create(const ParaKey, ParaChainCode: TBytes);
    function Address(out ParaAddr: TAddress): Exception;
    function PublicKey(out ParaPubKey: TEd25519PublicKey): Exception;
    function PrivateKey(out ParaPrivKey: TEd25519PrivateKey): Exception;
    function SignData(const ParaMessage: TBytes; out ParaSignData: TBytes; out ParaPub: TEd25519PublicKey): Exception;
    function Derive(ParaIndex: Cardinal): TDerivationKey;
    function RawSeed: TBytes32;
    function StringPair(out ParaSeed, ParaAddress: string): Exception;
    property Key: TBytes read GetKey;
    property ChainCode: TBytes read GetChainCode;
  end;

function DeriveForPath(const ParaPath: string; const ParaSeed: TBytes; out ParaKey: TDerivationKey): Exception;
function DeriveWithIndex(ParaIndex: Cardinal; const ParaSeed: TBytes; out ParaKey: TDerivationKey): Exception;
function GetPrimaryAddress(const ParaSeed: TBytes; out ParaAddr: TAddress): Exception;
function NewMasterKey(const ParaSeed: TBytes; out ParaKey: TDerivationKey): Exception;
function IsValidPath(const ParaPath: string): Boolean;

var
  ErrInvalidPath: Exception;
  ErrNoPublicDerivation: Exception;

implementation

uses
  System.Hash, System.NetEncoding, System.IOUtils, IdGlobal;

var
  pathRegex: TRegEx;

constructor TDerivationKey.Create(const ParaKey, ParaChainCode: TBytes);
begin
  mKey := ParaKey;
  mChainCode := ParaChainCode;
end;

function TDerivationKey.GetKey: TBytes;
begin
  Result := mKey;
end;

function TDerivationKey.GetChainCode: TBytes;
begin
  Result := mChainCode;
end;

function TDerivationKey.Address(out ParaAddr: TAddress): Exception;
var
  vPubKey: TEd25519PublicKey;
  vErr: Exception;
begin
  vErr := PublicKey(vPubKey);
  if vErr <> nil then
    Exit(vErr);
  ParaAddr := TAddress.PubKeyToAddress(vPubKey);
  Result := nil;
end;

function TDerivationKey.PublicKey(out ParaPubKey: TEd25519PublicKey): Exception;
var
  vPrivKey: TEd25519PrivateKey;
  vReader: TBytesStream;
begin
  Result := nil;
  vReader := TBytesStream.Create(mKey);
  try
    try
      TEd25519.GenerateKey(vReader, vPrivKey, ParaPubKey);
    except
      on E: Exception do
        Result := E;
    end;
  finally
    vReader.Free;
  end;
end;

function TDerivationKey.PrivateKey(out ParaPrivKey: TEd25519PrivateKey): Exception;
var
  vPubKey: TEd25519PublicKey;
  vReader: TBytesStream;
begin
  Result := nil;
  vReader := TBytesStream.Create(mKey);
  try
    try
      TEd25519.GenerateKey(vReader, ParaPrivKey, vPubKey);
    except
      on E: Exception do
        Result := E;
    end;
  finally
    vReader.Free;
  end;
end;

function TDerivationKey.SignData(const ParaMessage: TBytes; out ParaSignData: TBytes; out ParaPub: TEd25519PublicKey): Exception;
var
  vPriv: TEd25519PrivateKey;
  vErr: Exception;
begin
  vErr := PrivateKey(vPriv);
  if vErr <> nil then
    Exit(vErr);
  ParaSignData := TEd25519.Sign(vPriv, ParaMessage);
  ParaPub := vPriv.PubByte;
  Result := nil;
end;

function TDerivationKey.Derive(ParaIndex: Cardinal): TDerivationKey;
var
  vIBytes: TBytes;
  vKeyBytes: TBytes;
  vData: TBytes;
  vHmac: THashSHA512;
  vSum: TBytes;
  vNewKey, vNewChainCode: TBytes;
begin
  if ParaIndex < ConstFirstHardenedIndex then
    raise ENoPublicDerivation.Create('No public derivation for ed25519');

  SetLength(vIBytes, 4);
  PInteger(vIBytes)^ := ToBigEndian(ParaIndex);

  SetLength(vKeyBytes, Length(mKey) + 1);
  vKeyBytes[0] := 0;
  Move(mKey[0], vKeyBytes[1], Length(mKey));

  vData := TBytes.Concat(vKeyBytes, vIBytes);

  vHmac := THashSHA512.Create;
  try
    vSum := vHmac.GetHMAC(vData, mChainCode);
  finally
    vHmac.Free;
  end;

  SetLength(vNewKey, 32);
  Move(vSum[0], vNewKey[0], 32);
  SetLength(vNewChainCode, 32);
  Move(vSum[32], vNewChainCode[0], 32);

  Result := TDerivationKey.Create(vNewKey, vNewChainCode);
end;

function TDerivationKey.RawSeed: TBytes32;
begin
  CopyMemory(@Result, @mKey[0], 32);
end;

function TDerivationKey.StringPair(out ParaSeed, ParaAddress: string): Exception;
var
  vPubKey: TEd25519PublicKey;
  vErr: Exception;
  vAddr: TAddress;
begin
  ParaSeed := TNetEncoding.Base16.EncodeBytesToString(mKey);
  vErr := PublicKey(vPubKey);
  if vErr <> nil then
    Exit(vErr);
  vAddr := TAddress.PubKeyToAddress(vPubKey);
  ParaAddress := vAddr.ToHex;
  Result := nil;
end;

function DeriveForPath(const ParaPath: string; const ParaSeed: TBytes; out ParaKey: TDerivationKey): Exception;
var
  vErr: Exception;
  vSegments: TArray<string>;
  vSegment: string;
  vI64: UInt64;
  vIndex: Cardinal;
begin
  if not IsValidPath(ParaPath) then
    Exit(ErrInvalidPath);

  vErr := NewMasterKey(ParaSeed, ParaKey);
  if vErr <> nil then
    Exit(vErr);

  vSegments := ParaPath.Split(['/']);
  for vSegment in vSegments do
  begin
    if vSegment = 'm' then
      Continue;
    if not TryStrToUInt64(vSegment.TrimRight(['''']), vI64) then
      Exit(ErrInvalidPath);

    vIndex := Cardinal(vI64) + ConstFirstHardenedIndex;
    ParaKey := ParaKey.Derive(vIndex);
  end;
  Result := nil;
end;

function DeriveWithIndex(ParaIndex: Cardinal; const ParaSeed: TBytes; out ParaKey: TDerivationKey): Exception;
var
  vPath: string;
begin
  vPath := Format(ConstViteAccountPathFormat, [ParaIndex]);
  Result := DeriveForPath(vPath, ParaSeed, ParaKey);
end;

function GetPrimaryAddress(const ParaSeed: TBytes; out ParaAddr: TAddress): Exception;
var
  vKey: TDerivationKey;
  vErr: Exception;
begin
  vErr := DeriveWithIndex(0, ParaSeed, vKey);
  if vErr <> nil then
    Exit(vErr);
  Result := vKey.Address(ParaAddr);
end;

function NewMasterKey(const ParaSeed: TBytes; out ParaKey: TDerivationKey): Exception;
var
  vHmac: THashSHA512;
  vSum: TBytes;
  vNewKey, vNewChainCode: TBytes;
begin
  Result := nil;
  try
    vHmac := THashSHA512.Create;
    try
      vSum := vHmac.GetHMAC(ParaSeed, TEncoding.UTF8.GetBytes(ConstSeedModifier));
    finally
      vHmac.Free;
    end;
    SetLength(vNewKey, 32);
    Move(vSum[0], vNewKey[0], 32);
    SetLength(vNewChainCode, 32);
    Move(vSum[32], vNewChainCode[0], 32);
    ParaKey := TDerivationKey.Create(vNewKey, vNewChainCode);
  except
    on E: Exception do
      Result := E;
  end;
end;

function IsValidPath(const ParaPath: string): Boolean;
var
  vSegments: TArray<string>;
  vSegment: string;
  vI64: UInt64;
begin
  if not pathRegex.IsMatch(ParaPath) then
    Exit(False);

  vSegments := ParaPath.Split(['/']);
  for vSegment in vSegments do
  begin
    if vSegment = 'm' then
      Continue;
    if not TryStrToUInt64(vSegment.TrimRight(['''']), vI64) then
      Exit(False);
  end;
  Result := True;
end;

initialization
  pathRegex := TRegEx.Create('^m(\/[0-9]+'')+$');
  ErrInvalidPath := EInvalidPath.Create('Invalid derivation path');
  ErrNoPublicDerivation := ENoPublicDerivation.Create('No public derivation for ed25519');
end.
