unit Interfaces.Core.VmLogList.Test;

interface

uses
  DUnitX.TestFramework,
  SysUtils,
  Classes,
  Generics.Collections,
  Common.Types,
  Common.Upgrade,
  Interfaces.Core.VmLogList;

type
  [TestFixture]
  TVmLogListTests = class
  public
    [Test]
    procedure TestHash;
    [Test]
    procedure TestSerialize;
  end;

implementation

procedure TVmLogListTests.TestHash;
var
  vVmLogList: TVmLogList;
  vHash1, vHash2, vPreHash: THash;
  vAddress: TAddress;
  vVmLogHash1, vVmLogHash50, vVmLogHash100, vVmLogHash95, vVmLogHash105: ^THash;
  vError: Exception;
  vVmLog: TVmLog;
begin
  vVmLogList := TVmLogList.Create;
  try
    CleanupUpgradeBox;
    InitUpgradeBox(NewEmptyUpgradeBox.AddPoint(1, 90));

    vHash1 := THash.FromHexString('0dede580455f970517210ae2b9c0fbba74d5b7eea07eb0c62725e06c45061711', vError);
    Assert.IsNull(vError);
    vHash2 := THash.FromHexString('c512660e3ee7d1dc005a6206ccaf84e6b567592d543f537566d871c2440e187e', vError);
    Assert.IsNull(vError);

    vVmLog.Topics := [vHash1, vHash2];
    vVmLog.Data := TEncoding.UTF8.GetBytes('test');
    vVmLogList.Add(vVmLog);

    vAddress := TAddress.FromHexString('vite_544faefbc5031341c9352b0b22161bc0b4e5b342dc7fe04028', vError);
    Assert.IsNull(vError);
    vPreHash := THash.FromHexString('b7a12797d132c6545b5cc15afa8bb3811ac655f7a56cf76bad68bead4dfe5a44', vError);
    Assert.IsNull(vError);

    vVmLogHash1 := vVmLogList.Hash(1, vAddress, vPreHash);
    vVmLogHash50 := vVmLogList.Hash(50, vAddress, vPreHash);
    vVmLogHash100 := vVmLogList.Hash(100, vAddress, vPreHash);

    Assert.IsTrue(vVmLogHash1.Equals(vVmLogHash50^));
    Assert.IsFalse(vVmLogHash100.Equals(vVmLogHash1^));

    CleanupUpgradeBox;
    InitUpgradeBox(NewEmptyUpgradeBox.AddPoint(1, 101));

    vVmLogHash95 := vVmLogList.Hash(95, vAddress, vPreHash);
    Assert.IsTrue(vVmLogHash50.Equals(vVmLogHash95^));

    vVmLogHash105 := vVmLogList.Hash(105, vAddress, vPreHash);
    Assert.IsTrue(vVmLogHash105.Equals(vVmLogHash100^));
  finally
    vVmLogList.Free;
  end;
end;

procedure TVmLogListTests.TestSerialize;
var
  vVmLogList, vVmLogList2: TVmLogList;
  vHash1, vHash2: THash;
  vByt: TBytes;
  vError: Exception;
  i: Integer;
  vVmLog: TVmLog;
begin
  vVmLogList := TVmLogList.Create;
  try
    vHash1 := THash.FromHexString('0dede580455f970517210ae2b9c0fbba74d5b7eea07eb0c62725e06c45061711', vError);
    Assert.IsNull(vError);
    vHash2 := THash.FromHexString('c512660e3ee7d1dc005a6206ccaf84e6b567592d543f537566d871c2440e187e', vError);
    Assert.IsNull(vError);

    vVmLog.Topics := [vHash1, vHash2];
    vVmLog.Data := TEncoding.UTF8.GetBytes('test');
    vVmLogList.Add(vVmLog);

    vByt := vVmLogList.Serialize(vError);
    Assert.IsNull(vError);

    vVmLogList2 := TVmLogList.Create;
    try
      vError := vVmLogList2.Deserialize(vByt);
      Assert.IsNull(vError);

      Assert.AreEqual(vVmLogList.Count, vVmLogList2.Count);
      for i := 0 to vVmLogList.Count - 1 do
      begin
        Assert.AreEqual(vVmLogList[i].Data, vVmLogList2[i].Data);
        Assert.AreEqual(Length(vVmLogList[i].Topics), Length(vVmLogList2[i].Topics));
        for var j := 0 to Length(vVmLogList[i].Topics) - 1 do
          Assert.IsTrue(vVmLogList[i].Topics[j].Equal(vVmLogList2[i].Topics[j]));
      end;
    finally
      vVmLogList2.Free;
    end;
  finally
    vVmLogList.Free;
  end;
end;

end.
