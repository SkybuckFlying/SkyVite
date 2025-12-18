unit Wallet.EntropyStore.CryptoStore;

interface

uses
  Classes,
  GoToDelphi.Helpers.TBytes,
  SysUtils,
  Vite.Common.Types,
  Vite.Crypto,
  Wallet.EntropyStore.Crypto.Store.Test,
  Wallet.EntropyStore.Manager,
  Wallet.EntropyStore.Manager.Test,
  Wallet.EntropyStore.Models,
  Wallet.EntropyStore.Utils,
  Wallet.HD_BIP.Derivation;

const
  StandardScryptN = 1 shl 18;
  StandardScryptP = 1;
  ScryptR = 8;
  ScryptKeyLen = 32;
  AesMode = 'aes-256-gcm';
  ScryptName = 'scrypt';

type
  TCryptoStore = class
  private
    mEntropyStoreFilename: string;
    class function ParseJson(const ParaKeyJson: TBytes; out ParaK: TEntropyJSON; out ParaKAddress: TAddress; out ParaCipherData, ParaNonce, ParaSalt: TBytes): Boolean; static;
    class procedure WriteKeyFile(const ParaFile: string; const ParaContent: TBytes); static;
  public
    constructor Create(const ParaEntropyStoreFilename: string);
    procedure ExtractSeed(const ParaPassphrase: string; out ParaSeed, ParaEntropy: TBytes);
    function ExtractEntropy(const ParaPassphrase: string): TBytes;
    procedure StoreEntropy(const ParaEntropy: TBytes; const ParaPrimaryAddr: TAddress; const ParaPassphrase: string);
    class function DecryptEntropy(const ParaEntropyJson: TBytes; const ParaPassphrase: string): TBytes; static;
    class function EncryptEntropy(const ParaSeed: TBytes; const ParaAddr: TAddress; const ParaPassphrase: string): TBytes; static;
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  System.NetEncoding,
  BIP39,
  Scrypt,
  Vite.Common.Errors;

constructor TCryptoStore.Create(const ParaEntropyStoreFilename: string);
begin
  mEntropyStoreFilename := ParaEntropyStoreFilename;
end;

procedure TCryptoStore.ExtractSeed(const ParaPassphrase: string; out ParaSeed, ParaEntropy: TBytes);
var
  vMnemonic: string;
begin
  ParaEntropy := Self.ExtractEntropy(ParaPassphrase);
  vMnemonic := TBIP39.NewMnemonic(ParaEntropy);
  ParaSeed := TBIP39.NewSeed(vMnemonic, '');
end;

function TCryptoStore.ExtractEntropy(const ParaPassphrase: string): TBytes;
var
  vKeyJson: TBytes;
begin
  vKeyJson := TFile.ReadAllBytes(mEntropyStoreFilename);
  Result := DecryptEntropy(vKeyJson, ParaPassphrase);
end;

procedure TCryptoStore.StoreEntropy(const ParaEntropy: TBytes; const ParaPrimaryAddr: TAddress; const ParaPassphrase: string);
var
  vKeyJson: TBytes;
begin
  vKeyJson := EncryptEntropy(ParaEntropy, ParaPrimaryAddr, ParaPassphrase);
  WriteKeyFile(mEntropyStoreFilename, vKeyJson);
end;

class function TCryptoStore.ParseJson(const ParaKeyJson: TBytes; out ParaK: TEntropyJSON; out ParaKAddress: TAddress; out ParaCipherData, ParaNonce, ParaSalt: TBytes): Boolean;
var
  vJsonObj: TJSONObject;
  vCryptoObj: TJSONObject;
  vScryptParamsObj: TJSONObject;
  vAddrStr: string;
begin
  Result := False;
  vJsonObj := TJSONObject.ParseJSONValue(ParaKeyJson) as TJSONObject;
  if not Assigned(vJsonObj) then
  begin
    Exit;
  end;
  try
    ParaK := TEntropyJSON.Create;
    ParaK.Version := vJsonObj.GetValue<Integer>('version');
    if ParaK.Version <> CryptoStoreVersion then
    begin
      raise Exception.CreateFmt('version number error : %v', [ParaK.Version]);
    end;

    vAddrStr := vJsonObj.GetValue<string>('primaryAddress');
    if not TViteTypes.IsValidHexAddress(vAddrStr) then
    begin
      raise Exception.CreateFmt('address invalid : %v', [vAddrStr]);
    end;
    ParaKAddress := TViteTypes.HexToAddress(vAddrStr);
    ParaK.PrimaryAddress := vAddrStr;

    vCryptoObj := vJsonObj.GetValue<TJSONObject>('crypto');
    ParaK.Crypto := TCryptoJSON.Create;
    ParaK.Crypto.CipherName := vCryptoObj.GetValue<string>('cipher');
    if ParaK.Crypto.CipherName <> AesMode then
    begin
      raise Exception.CreateFmt('cipherName error : %v', [ParaK.Crypto.CipherName]);
    end;

    ParaK.Crypto.KDF := vCryptoObj.GetValue<string>('kdf');
    if ParaK.Crypto.KDF <> ScryptName then
    begin
      raise Exception.CreateFmt('scryptName error : %v', [ParaK.Crypto.KDF]);
    end;

    ParaCipherData := TNetEncoding.Base16.Decode(vCryptoObj.GetValue<string>('ciphertext'));
    ParaNonce := TNetEncoding.Base16.Decode(vCryptoObj.GetValue<string>('nonce'));

    vScryptParamsObj := vCryptoObj.GetValue<TJSONObject>('kdfparams');
    ParaK.Crypto.ScryptParams := TScryptParams.Create;
    ParaK.Crypto.ScryptParams.N := vScryptParamsObj.GetValue<Integer>('n');
    ParaK.Crypto.ScryptParams.R := vScryptParamsObj.GetValue<Integer>('r');
    ParaK.Crypto.ScryptParams.P := vScryptParamsObj.GetValue<Integer>('p');
    ParaK.Crypto.ScryptParams.KeyLen := vScryptParamsObj.GetValue<Integer>('dklen');
    ParaSalt := TNetEncoding.Base16.Decode(vScryptParamsObj.GetValue<string>('salt'));
    Result := True;
  finally
    vJsonObj.Free;
  end;
end;

class function TCryptoStore.DecryptEntropy(const ParaEntropyJson: TBytes; const ParaPassphrase: string): TBytes;
var
  vK: TEntropyJSON;
  vKAddress: TAddress;
  vCipherData, vNonce, vSalt, vDerivedKey, vEntropy: TBytes;
  vMnemonic: string;
  vSeed: TBytes;
  vGenerateAddr: TAddress;
begin
  if not ParseJson(ParaEntropyJson, vK, vKAddress, vCipherData, vNonce, vSalt) then
  begin
    raise EWalletError.Create('Failed to parse key json');
  end;

  vDerivedKey := TScrypt.Generate(TEncoding.UTF8.GetBytes(ParaPassphrase), vSalt, vK.Crypto.ScryptParams.N, vK.Crypto.ScryptParams.R, vK.Crypto.ScryptParams.P, vK.Crypto.ScryptParams.KeyLen);

  try
    vEntropy := TAesGcm.Decrypt(Copy(vDerivedKey, 0, 32), vCipherData, vNonce);
  except
    on E: Exception do
    begin
      raise EDecryptError.Create('Failed to decrypt entropy');
    end;
  end;

  vMnemonic := TBIP39.NewMnemonic(vEntropy);
  vSeed := TBIP39.NewSeed(vMnemonic, '');
  vGenerateAddr := TDerivation.GetPrimaryAddress(vSeed);

  if not TViteTypes.BytesEqual(vGenerateAddr.Bytes, vKAddress.Bytes) then
  begin
    raise Exception.CreateFmt('address content not equal. In file it is : %s  but generated is : %s', [vK.PrimaryAddress, vGenerateAddr.ToHex]);
  end;
  Result := vEntropy;
end;

class function TCryptoStore.EncryptEntropy(const ParaSeed: TBytes; const ParaAddr: TAddress; const ParaPassphrase: string): TBytes;
var
  vN, vP: Integer;
  vPwdArray, vSalt, vDerivedKey, vEncryptKey, vCiphertext, vNonce: TBytes;
  vScryptParams: TScryptParams;
  vCryptoJSON: TCryptoJSON;
  vEncryptedKeyJSON: TEntropyJSON;
  vJsonObj: TJSONObject;
begin
  vN := StandardScryptN;
  vP := StandardScryptP;
  vPwdArray := TEncoding.UTF8.GetBytes(ParaPassphrase);
  vSalt := TViteCrypto.GetEntropyCSPRNG(32);
  vDerivedKey := TScrypt.Generate(vPwdArray, vSalt, vN, ScryptR, vP, ScryptKeyLen);
  vEncryptKey := Copy(vDerivedKey, 0, 32);

  TAesGcm.Encrypt(vEncryptKey, ParaSeed, vCiphertext, vNonce);

  vScryptParams := TScryptParams.Create;
  vScryptParams.N := vN;
  vScryptParams.R := ScryptR;
  vScryptParams.P := vP;
  vScryptParams.KeyLen := ScryptKeyLen;
  vScryptParams.Salt := TNetEncoding.Base16.EncodeBytesToString(vSalt);

  vCryptoJSON := TCryptoJSON.Create;
  vCryptoJSON.CipherName := AesMode;
  vCryptoJSON.CipherText := TNetEncoding.Base16.EncodeBytesToString(vCiphertext);
  vCryptoJSON.Nonce := TNetEncoding.Base16.EncodeBytesToString(vNonce);
  vCryptoJSON.KDF := ScryptName;
  vCryptoJSON.ScryptParams := vScryptParams;

  vEncryptedKeyJSON := TEntropyJSON.Create;
  vEncryptedKeyJSON.PrimaryAddress := ParaAddr.ToString;
  vEncryptedKeyJSON.Crypto := vCryptoJSON;
  vEncryptedKeyJSON.Version := CryptoStoreVersion;
  vEncryptedKeyJSON.Timestamp := TDateTime.UtcNow.ToUnix;

  vJsonObj := vEncryptedKeyJSON.ToJSONObject;
  try
    Result := TEncoding.UTF8.GetBytes(vJsonObj.ToJSON);
  finally
    vJsonObj.Free;
  end;
end;

class procedure TCryptoStore.WriteKeyFile(const ParaFile: string; const ParaContent: TBytes);
var
  vTempFile: string;
begin
  TDirectory.CreateDirectory(TPath.GetDirectoryName(ParaFile));
  vTempFile := TPath.GetTempFileName;
  TFile.WriteAllBytes(vTempFile, ParaContent);
  TFile.Move(vTempFile, ParaFile, TFile.Exists(ParaFile));
end;

end.
