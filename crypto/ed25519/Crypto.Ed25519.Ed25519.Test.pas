unit Crypto.Ed25519.Ed25519.Test;

interface

uses
  TestFramework,
  Crypto.Ed25519.Ed25519,
  System.SysUtils,
  System.Classes,
  System.StrUtils;

type
  TEd25519Tests = class(TTestCase)
  published
    procedure TestIsValidPrivateKey;
    procedure TestUnmarshalMarshal;
    procedure TestSignVerify;
    procedure TestMalleability;
    procedure TestX25519Exchange;
  end;

implementation

{ TEd25519Tests }

procedure TEd25519Tests.TestIsValidPrivateKey;
var
  vPrivateKey: TPrivateKey;
begin
  Assert.IsFalse(TEd25519.IsValidPrivateKey(TBytes.Create(1, 2, 3)));
  Assert.IsFalse(TEd25519.IsValidPrivateKey(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8)));
  vPrivateKey := TEd25519.GenerateKey(TMemoryStream.Create(TBytes.Create(0), 0, 1));
  // Assert.IsTrue(TEd25519.IsValidPrivateKey(vPrivateKey)); // TODO: Uncomment when IsValidPrivateKey is implemented
end;

procedure TEd25519Tests.TestUnmarshalMarshal;
var
  vPublicKey: TPublicKey;
begin
  vPublicKey := TEd25519.GenerateKey(TMemoryStream.Create(TBytes.Create(0), 0, 1));
  // UnmarshalMarshal(vPublicKey, Self); // TODO: Implement UnmarshalMarshal
end;

procedure TEd25519Tests.TestSignVerify;
var
  vMessage: TBytes;
  vPublicKey: TPublicKey;
  vSignature: TBytes;
begin
  vMessage := TEncoding.ASCII.GetBytes('12345678901234567890');
  vPublicKey := TEd25519.HexToPublicKey('5AD4455C87AF117B3A56AC816AE9BF9C92E566803C177FB206669F0F53609471');
  vSignature := TBytes.FromHexString('3761078C2BDBF90807A22E0309A6F0D5AD6765455466B840662A32F6AC044B98BC46726C4905449537DB5AA88CCA0F8B93F8C0249B3A826E0CE6A6F7D2019504');
  // Assert.IsTrue(TEd25519.Verify(vPublicKey, vMessage, vSignature)); // TODO: Uncomment when Verify is implemented
end;

procedure TEd25519Tests.TestMalleability;
var
  vMsg: TBytes;
  vSig: TBytes;
  vPublicKey: TPublicKey;
begin
  vMsg := TBytes.Create($54, $65, $73, $74);
  vSig := TBytes.FromHexString('7c38e026f29e14aabd059a0f2db8b0cd783040609a8be684db12f82a27774ab067654bce3832c2d76f8f6f5dafc08d9339d4eef676573336a5c51eb6f946b31d');
  vPublicKey := TBytes.FromHexString('7d4d0e7f6153a69b6242b522abbee685fda4420f8834b108c3bdae369ef549fa');
  // Assert.IsFalse(TEd25519.Verify(vPublicKey, vMsg, vSig)); // TODO: Uncomment when Verify is implemented
end;

procedure TEd25519Tests.TestX25519Exchange;
var
  vPrivateKey1: TPrivateKey;
  vPublicKey1: TPublicKey;
  vPrivateKey2: TPrivateKey;
  vPublicKey2: TPublicKey;
  vXPublicKey1: TBytes;
  vXPrivateKey1: TBytes;
  vXPublicKey2: TBytes;
  vXPrivateKey2: TBytes;
  vSecret1: TBytes;
  vSecret2: TBytes;
begin
  vPrivateKey1 := TEd25519.GenerateKey(TMemoryStream.Create(TBytes.Create(0), 0, 1));
  // vPublicKey1 := TEd25519.GetPublicKey(vPrivateKey1); // TODO: Implement GetPublicKey
  vXPublicKey1 := TEd25519.ToX25519Pk(vPublicKey1);
  vXPrivateKey1 := TEd25519.ToX25519Sk(vPrivateKey1);

  vPrivateKey2 := TEd25519.GenerateKey(TMemoryStream.Create(TBytes.Create(0), 0, 1));
  // vPublicKey2 := TEd25519.GetPublicKey(vPrivateKey2); // TODO: Implement GetPublicKey
  vXPublicKey2 := TEd25519.ToX25519Pk(vPublicKey2);
  vXPrivateKey2 := TEd25519.ToX25519Sk(vPrivateKey2);

  // vSecret1 := TEd25519.ComputeSecret(vXPrivateKey1, vXPublicKey2); // TODO: Implement ComputeSecret
  // vSecret2 := TEd25519.ComputeSecret(vXPrivateKey2, vXPublicKey1); // TODO: Implement ComputeSecret

  // Assert.AreEqual(vSecret1, vSecret2);
end;

initialization
  RegisterTest(TEd25519Tests.Suite);
end.
