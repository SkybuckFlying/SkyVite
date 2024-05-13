unit unit_crypto;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Hash,
  System.NetEncoding,
  IdSSLOpenSSLHeaders,
  IdGlobal,
  IdHash,
  IdHMAC,
  IdHMACSHA1;

const
  gcmAdditionData = 'vite';

type
  EUnexpectedKeyType = class(Exception);

function X25519ComputeSecret(const PrivateKey, PeersPublicKey: TBytes): TBytes;
function AesCTRXOR(const Key, InText, IV: TBytes): TBytes;
function AesGCMEncrypt(const Key, InText: TBytes): TBytes;
function AesGCMDecrypt(const Key, CipherText, Nonce: TBytes): TBytes;
function GetEntropyCSPRNG(Size: Integer): TBytes;
function VerifySig(const PubKey, Message, SignData: TBytes): Boolean;

implementation

uses
  IdCrypto, IdCiphers, IdOpenSSLX509;

function CheckType(var Key: TBytes; const TypeToCheck: TBytes): Boolean;
begin
  Result := Length(TypeToCheck) = 32;
  if Result then
    Key := Copy(TypeToCheck, 0, 32);
end;

function X25519ComputeSecret(const PrivateKey, PeersPublicKey: TBytes): TBytes;
var
  Sec, Pri, Pub: TBytes;
begin
  SetLength(Pri, 32);
  SetLength(Pub, 32);
  SetLength(Sec, 32);
  if not CheckType(Pri, PrivateKey) then
    raise EUnexpectedKeyType.Create('Unexpected type of private key');
  if not CheckType(Pub, PeersPublicKey) then
    raise EUnexpectedKeyType.Create('Unexpected type of peers public key');

  // Scalar multiplication (needs actual implementation or external library)
  // Dummy implementation:
  Move(Pri[0], Sec[0], 32);

  Result := Sec;
end;

function AesCTRXOR(const Key, InText, IV: TBytes): TBytes;
var
  Cipher: TIdBlockCipher;
begin
  Cipher := TIdBlockCipherAES.Create(Key);
  try
    Result := Cipher.CTR(InText, IV);
  finally
    Cipher.Free;
  end;
end;

function AesGCMEncrypt(const Key, InText: TBytes): TBytes;
var
  Cipher: TIdBlockCipherGCM;
  Nonce: TBytes;
begin
  Cipher := TIdBlockCipherGCM.Create(Key);
  try
    Nonce := GetEntropyCSPRNG(12);
    Result := Cipher.Encrypt(InText, Nonce, TEncoding.UTF8.GetBytes(gcmAdditionData));
  finally
    Cipher.Free;
  end;
end;

function AesGCMDecrypt(const Key, CipherText, Nonce: TBytes): TBytes;
var
  Cipher: TIdBlockCipherGCM;
begin
  Cipher := TIdBlockCipherGCM.Create(Key);
  try
    Result := Cipher.Decrypt(CipherText, Nonce, TEncoding.UTF8.GetBytes(gcmAdditionData));
  finally
    Cipher.Free;
  end;
end;

function GetEntropyCSPRNG(Size: Integer): TBytes;
begin
  SetLength(Result, Size);
  if not IdSSLOpenSSLHeaders.RAND_bytes(@Result[0], Size) then
    raise Exception.Create('Failed to generate CSPRNG entropy');
end;

function VerifySig(const PubKey, Message, SignData: TBytes): Boolean;
begin
  Result := TIdHMACSHA1.VerifySignature(PubKey, Message, SignData);
end;

end.



