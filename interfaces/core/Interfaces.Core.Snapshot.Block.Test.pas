unit Interfaces.Core.SnapshotBlock.Test;

interface

uses
  DUnitX.TestFramework,
  SysUtils,
  Classes,
  Generics.Collections,
  Common.Types,
  Common.Upgrade,
  Crypto,
  Crypto.Ed25519,
  Interfaces.Core.SnapshotBlock,
  Interfaces.Core.HashHeight;

type
  [TestFixture]
  TSnapshotBlockTests = class
  private
    function CreateSnapshotContent(ParaCount: Integer): TSnapshotContent;
    function CreateSnapshotBlock(ParaScCount: Integer; ParaSbHeight: UInt64): TSnapshotBlock;
  public
    [Test]
    procedure TestSignature;
    [Test]
    procedure TestForkComputeHash;
  end;

implementation

uses
  System.DateUtils,
  System.Math,
  Common.Json,
  Common.Base64;

function TSnapshotBlockTests.CreateSnapshotContent(ParaCount: Integer): TSnapshotContent;
var
  i: Integer;
  vAddr: TAddress;
  vHeight: UInt64;
  vHash: THash;
  vError: Exception;
  vPublicKey: TPublicKey;
  vPrivateKey: TPrivateKey;
begin
  Result := TSnapshotContent.Create;
  for i := 0 to ParaCount - 1 do
  begin
    vError := TEd25519.CreateKeyPair(vPublicKey, vPrivateKey);
    Assert.IsNull(vError);
    vAddr := TAddress.FromPublicKey(vPublicKey, vError);
    Assert.IsNull(vError);
    vHeight := Random(MaxInt);
    vHash := THash.Hash256(vAddr.Bytes, vError);
    Assert.IsNull(vError);
    Result.Add(vAddr, THashHeight.Create(vHeight, vHash));
  end;
end;

function TSnapshotBlockTests.CreateSnapshotBlock(ParaScCount: Integer; ParaSbHeight: UInt64): TSnapshotBlock;
var
  vPrivateKey: TPrivateKey;
  vPublicKey: TPublicKey;
  vPrevHash: THash;
  vError: Exception;
begin
  vError := TEd25519.CreateKeyPair(vPublicKey, vPrivateKey);
  Assert.IsNull(vError);
  vPrevHash := THash.Hash256(TEncoding.UTF8.GetBytes('This is prevHash'), vError);
  Assert.IsNull(vError);

  Result.PrevHash := vPrevHash;
  Result.Height := ParaSbHeight;
  Result.PublicKey := vPublicKey;
  Result.Timestamp := Now;
  Result.SnapshotContent := CreateSnapshotContent(ParaScCount);
  Result.Hash := Result.ComputeHash(vError);
  Assert.IsNull(vError);
  Result.Signature := TEd25519.Sign(vPrivateKey, Result.Hash.Bytes, vError);
  Assert.IsNull(vError);
end;

procedure TSnapshotBlockTests.TestSignature;
var
  vHash: THash;
  vPubKeyBytes, vSignatureBytes: TBytes;
  vSb: TSnapshotBlock;
  vVerified: Boolean;
  vError: Exception;
begin
  vHash := THash.FromHexString('5835374c6b5b612e5016ae04689d57f5c49e3a520412121607a28566d1c62825', vError);
  Assert.IsNull(vError);
  vPubKeyBytes := TBase64.Decode('4DxxPWO/hymiRBM36rFsv82AXo59QKHw4dMrlQSJTCU=');
  vSignatureBytes := TBase64.Decode('x/pYNm+qMGB0npHW1IIbnCKbczJLFQcjC7zyulEGA8IMvq8sxhWBbRYFd10SypubKevVhmdnrKV86UBIGovADQ==');

  vSb.Hash := vHash;
  vSb.PublicKey := vPubKeyBytes;
  vSb.Signature := vSignatureBytes;

  vVerified := vSb.VerifySignature(vError);
  Assert.IsNull(vError);
  Assert.IsTrue(vVerified);
end;

procedure TSnapshotBlockTests.TestForkComputeHash;
var
  vSnapshotBlock: TSnapshotBlock;
  vHashOld, vHashNew: THash;
  vError: Exception;
begin
  CleanupUpgradeBox;
  InitUpgradeBox(NewEmptyUpgradeBox);

  vSnapshotBlock := CreateSnapshotBlock(1, 10000000000000);
  vHashOld := vSnapshotBlock.Hash;

  CleanupUpgradeBox;
  InitUpgradeBox(NewEmptyUpgradeBox.AddPoint(1, 90));

  vHashNew := vSnapshotBlock.ComputeHash(vError);
  Assert.IsNull(vError);

  Assert.AreNotEqual(vHashOld.ToString, vHashNew.ToString);
end;

end.
