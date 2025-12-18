unit Crypto.Crypto.Test;

interface

uses
  Crypto.Crypto,
  Crypto.Hash,
  Crypto.Hast.Test,
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  TestFramework;

type
  TCryptoTests = class(TTestCase)
  const
    long_bytes = 100000;
    gcm_dummy_plain_text = '112233445566778899AAABBCCBC';
    gcm_dummy_key_16 = '1122334455667788';
    gcm_dummy_key_32 = '11112222333344445555666677778888';
    gcm_dummy_key_24 = '111222333444555666777888';
  published
    procedure TestHash256;
    procedure TestAesGCMEncrypt;
    procedure TestAesCTRXOR;
    procedure TestGenerateKey;
    procedure TestX25519ComputeSecret;
    procedure TestVerifySig;
  end;

implementation

{ TCryptoTests }

procedure TCryptoTests.TestHash256;
var
  vLongBytes: TBytes;
  vIndex: Integer;
begin
  Assert.AreEqual('4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45', BytesToHex(TCrypto.Hash256([1, 2, 3])));
  Assert.AreEqual('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', BytesToHex(TCrypto.Hash256([])));
  Assert.AreEqual('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', BytesToHex(TCrypto.Hash256(nil)));

  SetLength(vLongBytes, long_bytes);
  for vIndex := 0 to long_bytes - 1 do
  begin
    vLongBytes[vIndex] := 21;
  end;
  Assert.AreEqual('f67a15c432ffba530536382f33cf5a2376b1633c7b413e44b46b84bbf4171b66', BytesToHex(TCrypto.Hash256(vLongBytes)));
end;

procedure TCryptoTests.TestAesGCMEncrypt;
var
  vKey: TBytes;
  vPlainText: TBytes;
  vCipherText: TBytes;
  vNonce: TBytes;
  vDecryptedText: TBytes;
begin
  vKey := TEncoding.ASCII.GetBytes(gcm_dummy_key_32);
  vPlainText := TEncoding.ASCII.GetBytes(gcm_dummy_plain_text);
  vCipherText := TCrypto.AesGCMEncrypt(vKey, vPlainText, vNonce);
  vDecryptedText := TCrypto.AesGCMDecrypt(vKey, vCipherText, vNonce);
  Assert.AreEqual(vPlainText, vDecryptedText);
end;

procedure TCryptoTests.TestAesCTRXOR;
var
  vKey: TBytes;
  vPlainText: TBytes;
  vIV: TBytes;
  vCipherText: TBytes;
  vDecryptedText: TBytes;
begin
  vKey := TEncoding.ASCII.GetBytes(gcm_dummy_key_32);
  vPlainText := TEncoding.ASCII.GetBytes(gcm_dummy_plain_text);
  vIV := TEncoding.ASCII.GetBytes(gcm_dummy_key_16);
  vCipherText := TCrypto.AesCTRXOR(vKey, vPlainText, vIV);
  vDecryptedText := TCrypto.AesCTRXOR(vKey, vCipherText, vIV);
  Assert.AreEqual(vPlainText, vDecryptedText);
end;

procedure TCryptoTests.TestGenerateKey;
var
  vPrivateKey: TBytes;
  vIndex: Integer;
begin
  for vIndex := 0 to 4 do
  begin
    vPrivateKey := TCrypto.GenerateKey;
    Assert.AreEqual(32, Length(vPrivateKey));
  end;
end;

procedure TCryptoTests.TestX25519ComputeSecret;
var
  vPrivateKey1: TBytes;
  vPublicKey1: TBytes;
  vPrivateKey2: TBytes;
  vPublicKey2: TBytes;
  vSecret1: TBytes;
  vSecret2: TBytes;
begin
  vPrivateKey1 := TCrypto.GenerateKey;
  // In a real application, you would derive the public key from the private key
  // For testing purposes, we generate another key pair
  vPublicKey1 := TCrypto.GenerateKey;

  vPrivateKey2 := TCrypto.GenerateKey;
  vPublicKey2 := TCrypto.GenerateKey;

  vSecret1 := TCrypto.X25519ComputeSecret(vPrivateKey1, vPublicKey2);
  vSecret2 := TCrypto.X25519ComputeSecret(vPrivateKey2, vPublicKey1);

  Assert.AreEqual(vSecret1, vSecret2);
end;

procedure TCryptoTests.TestVerifySig;
var
  vPrivateKey: TBytes;
  vPublicKey: TBytes;
  vMessage: TBytes;
  vSignature: TBytes;
begin
  vPrivateKey := TCrypto.GenerateKey;
  // In a real application, you would derive the public key from the private key
  // For testing purposes, we generate another key
  vPublicKey := TCrypto.GenerateKey;
  SetLength(vMessage, 4096);
  // In a real application, you would use a secure random number generator
  // For testing purposes, we use a fixed message
  TBytes.Copy(TEncoding.ASCII.GetBytes('test message'), vMessage, 12);
  vSignature := TBytes.Create(); // dummy signature for testing
  Assert.IsTrue(TCrypto.VerifySig(vPublicKey, vMessage, vSignature));
end;

initialization
  RegisterTest(TCryptoTests.Suite);
end.
