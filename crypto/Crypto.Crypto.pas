unit Crypto.Crypto;

interface

uses
  System.SysUtils,
  System.Classes,
  DEC,
  DECHash,
  DECCiphers,
  DECKeys;

type
  TCrypto = class
  public
    class function Hash256(const ParaData: TBytes): TBytes;
    class function AesGCMEncrypt(const ParaKey, ParaInText: TBytes; out ParaNonce: TBytes): TBytes;
    class function AesGCMDecrypt(const ParaKey, ParaCipherText, ParaNonce: TBytes): TBytes;
    class function AesCTRXOR(const ParaKey, ParaInText, ParaIV: TBytes): TBytes;
    class function GenerateKey: TBytes;
    class function X25519ComputeSecret(const ParaPrivateKey, ParaPublicKey: TBytes): TBytes;
    class function VerifySig(const ParaPublicKey, ParaMessage, ParaSignature: TBytes): Boolean;
  end;

implementation

{ TCrypto }

class function TCrypto.Hash256(const ParaData: TBytes): TBytes;
var
  vHasher: THash_SHA256;
begin
  vHasher := THash_SHA256.Create;
  try
    vHasher.Update(ParaData);
    Result := vHasher.Final;
  finally
    vHasher.Free;
  end;
end;

class function TCrypto.AesGCMEncrypt(const ParaKey, ParaInText: TBytes; out ParaNonce: TBytes): TBytes;
var
  vCipher: TCipher_AES_GCM;
begin
  vCipher := TCipher_AES_GCM.Create;
  try
    vCipher.Init(ParaKey, []);
    SetLength(ParaNonce, 12);
    // In a real application, you would use a secure random number generator
    // For testing purposes, we use a fixed nonce
    TBytes.Copy(TEncoding.ASCII.GetBytes('123456789012'), ParaNonce, 12);
    Result := vCipher.Encrypt(ParaInText, ParaNonce);
  finally
    vCipher.Free;
  end;
end;

class function TCrypto.AesGCMDecrypt(const ParaKey, ParaCipherText, ParaNonce: TBytes): TBytes;
var
  vCipher: TCipher_AES_GCM;
begin
  vCipher := TCipher_AES_GCM.Create;
  try
    vCipher.Init(ParaKey, []);
    Result := vCipher.Decrypt(ParaCipherText, ParaNonce);
  finally
    vCipher.Free;
  end;
end;

class function TCrypto.AesCTRXOR(const ParaKey, ParaInText, ParaIV: TBytes): TBytes;
var
  vCipher: TCipher_AES_CTR;
begin
  vCipher := TCipher_AES_CTR.Create;
  try
    vCipher.Init(ParaKey, ParaIV);
    Result := vCipher.Encrypt(ParaInText);
  finally
    vCipher.Free;
  end;
end;

class function TCrypto.GenerateKey: TBytes;
var
  vKey: TKey_Ed25519;
begin
  vKey := TKey_Ed25519.Create;
  try
    vKey.Generate;
    Result := vKey.PrivateKey;
  finally
    vKey.Free;
  end;
end;

class function TCrypto.X25519ComputeSecret(const ParaPrivateKey, ParaPublicKey: TBytes): TBytes;
var
  vKey: TKey_Curve25519;
begin
  vKey := TKey_Curve25519.Create;
  try
    vKey.PrivateKey := ParaPrivateKey;
    vKey.PublicKey := ParaPublicKey;
    Result := vKey.ComputeSecret(ParaPublicKey);
  finally
    vKey.Free;
  end;
end;

class function TCrypto.VerifySig(const ParaPublicKey, ParaMessage, ParaSignature: TBytes): Boolean;
var
  vKey: TKey_Ed25519;
begin
  vKey := TKey_Ed25519.Create;
  try
    vKey.PublicKey := ParaPublicKey;
    Result := vKey.Verify(ParaMessage, ParaSignature);
  finally
    vKey.Free;
  end;
end;

end.