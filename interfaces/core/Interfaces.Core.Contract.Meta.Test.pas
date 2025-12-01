unit Interfaces.Core.ContractMeta.Test;

interface

uses
  DUnitX.TestFramework,
  Common.Types,
  Interfaces.Core.ContractMeta;

type
  [TestFixture]
  TContractMetaTests = class
  public
    [Test]
    procedure TestSerializeDeserialize;
  end;

implementation

uses
  System.SysUtils;

const
  LengthBeforeSeedFork = TGidSize + 1 + THashSize + 1;

procedure TContractMetaTests.TestSerializeDeserialize;
var
  vHashtmp: THash;
  vCm, vCmNew: TContractMeta;
  vByteBuf: TBytes;
  vError: Exception;
begin
  vHashtmp := THash.FromHexString('db7a03be03372c499ed6a211f5b5d8ba5fd6469869f6e4415b2e58e5dd321636', vError);
  Assert.IsNull(vError);

  vCm.Gid := DELEGATE_GID;
  vCm.SendConfirmedTimes := 1;
  vCm.CreateBlockHash := vHashtmp;
  vCm.QuotaRatio := 10;
  vCm.SeedConfirmedTimes := 2;

  vByteBuf := vCm.Serialize(vError);
  Assert.IsNull(vError);
  Assert.AreEqual(LengthBeforeSeedFork + 1, Length(vByteBuf));

  vError := vCmNew.Deserialize(vByteBuf);
  Assert.IsNull(vError);
  Assert.IsTrue(vCm.Gid.Equal(vCmNew.Gid));
  Assert.AreEqual(vCm.SendConfirmedTimes, vCmNew.SendConfirmedTimes);
  Assert.IsTrue(vCm.CreateBlockHash.Equal(vCmNew.CreateBlockHash));
  Assert.AreEqual(vCm.QuotaRatio, vCmNew.QuotaRatio);
  Assert.AreEqual(vCm.SeedConfirmedTimes, vCmNew.SeedConfirmedTimes);

  // Case 2
  vCmNew := vCm;
  vCmNew.SeedConfirmedTimes := vCmNew.SendConfirmedTimes;
  SetLength(vByteBuf, LengthBeforeSeedFork);
  vByteBuf := vCm.Serialize(vError);
  Assert.IsNull(vError);
  SetLength(vByteBuf, LengthBeforeSeedFork);
  vError := vCmNew.Deserialize(vByteBuf);
  Assert.IsNull(vError);
  Assert.IsTrue(vCm.Gid.Equal(vCmNew.Gid));
  Assert.AreEqual(vCm.SendConfirmedTimes, vCmNew.SendConfirmedTimes);
  Assert.IsTrue(vCm.CreateBlockHash.Equal(vCmNew.CreateBlockHash));
  Assert.AreEqual(vCm.QuotaRatio, vCmNew.QuotaRatio);
  Assert.AreEqual(vCm.SendConfirmedTimes, vCmNew.SeedConfirmedTimes);

  // Case 3
  vCm.SeedConfirmedTimes := 0;
  vByteBuf := vCm.Serialize(vError);
  Assert.IsNull(vError);
  Assert.AreEqual(LengthBeforeSeedFork + 1, Length(vByteBuf));
  vError := vCmNew.Deserialize(vByteBuf);
  Assert.IsNull(vError);
  Assert.IsTrue(vCm.Gid.Equal(vCmNew.Gid));
  Assert.AreEqual(vCm.SendConfirmedTimes, vCmNew.SendConfirmedTimes);
  Assert.IsTrue(vCm.CreateBlockHash.Equal(vCmNew.CreateBlockHash));
  Assert.AreEqual(vCm.QuotaRatio, vCmNew.QuotaRatio);
  Assert.AreEqual(0, vCmNew.SeedConfirmedTimes);
end;

end.
