unit Ledger.Chain.AccountBlock.Test;

interface

uses
  TestFramework,
  Ledger.Chain.AccountBlock,
  Common.Types,
  Interfaces.Core,
  System.SysUtils;

type
  TAccountBlockTests = class(TTestCase)
  published
    // procedure TestChain_AccountBlock; // TODO: Implement this test
    // procedure Test_Get; // TODO: Implement this test
    // procedure TestChain_IsSeedConfirmedNTimes; // TODO: Implement this test
  end;

implementation

{ TAccountBlockTests }

// procedure TAccountBlockTests.TestChain_AccountBlock;
// var
//   vChainInstance: TChain;
//   vAccounts: TDictionary<TAddress, TAccount>;
// begin
//   // vChainInstance, vAccounts, _ := SetUp(Self, 10, 5000, 90);
//   // testAccountBlock(Self, vChainInstance, vAccounts);
//   // TearDown(vChainInstance);
// end;

// procedure TAccountBlockTests.Test_Get;
// var
//   vChainInstance: TChain;
//   vHash: THash;
//   vBlock: IAccountBlock;
// begin
//   // vChainInstance, _, _ := SetUp(0, 0, 0);
//   // vHash := THash.FromHexString('cb514e93490a3614d3833893ec3130a046915a5421f233d16f6fef9ed1dca66c');
//   // vBlock := vChainInstance.GetReceiveAbBySendAb(vHash);
//   // Assert.IsNotNull(vBlock);
// end;

// procedure TAccountBlockTests.TestChain_IsSeedConfirmedNTimes;
// var
//   vChainInstance: TChain;
//   vAccounts: TDictionary<TAddress, TAccount>;
//   vAccountBlockList: TArray<IAccountBlock>;
//   vAccountBlock: IAccountBlock;
//   vFlag: Boolean;
//   vSnapshotBlock: ISnapshotBlock;
// begin
//   // vChainInstance, vAccounts, _ := SetUp(Self, 1, 0, 0);
//   // InsertAccountBlocks(nil, vChainInstance, vAccounts, 1);
//   // vAccountBlockList := vChainInstance.GetAllUnconfirmedBlocks;
//   // Assert.AreEqual(1, Length(vAccountBlockList));
//   // vAccountBlock := vAccountBlockList[0];
//   // vFlag := vChainInstance.IsSeedConfirmedNTimes(vAccountBlock.Hash, 0);
//   // Assert.IsFalse(vFlag);
//   // vFlag := vChainInstance.IsSeedConfirmedNTimes(vAccountBlock.Hash, 1);
//   // Assert.IsFalse(vFlag);
//   // vSnapshotBlock := createSnapshotBlock(vChainInstance, true, 1);
//   // vChainInstance.InsertSnapshotBlock(vSnapshotBlock);
//   // vFlag := vChainInstance.IsSeedConfirmedNTimes(vAccountBlock.Hash, 1);
//   // Assert.IsTrue(vFlag);
//   // vFlag := vChainInstance.IsSeedConfirmedNTimes(vAccountBlock.Hash, 2);
//   // Assert.IsFalse(vFlag);
//   // vSnapshotBlock := createSnapshotBlock(vChainInstance, true, 0);
//   // vChainInstance.InsertSnapshotBlock(vSnapshotBlock);
//   // vFlag := vChainInstance.IsSeedConfirmedNTimes(vAccountBlock.Hash, 2);
//   // Assert.IsFalse(vFlag);
//   // vFlag := vChainInstance.IsSeedConfirmedNTimes(vAccountBlock.Hash, 1);
//   // Assert.IsTrue(vFlag);
//   // vSnapshotBlock := createSnapshotBlock(vChainInstance, true, 2);
//   // vChainInstance.InsertSnapshotBlock(vSnapshotBlock);
//   // vFlag := vChainInstance.IsSeedConfirmedNTimes(vAccountBlock.Hash, 2);
//   // Assert.IsTrue(vFlag);
//   // vFlag := vChainInstance.IsSeedConfirmedNTimes(vAccountBlock.Hash, 1);
//   // Assert.IsTrue(vFlag);
//   // TearDown(vChainInstance);
// end;

initialization
  RegisterTest(TAccountBlockTests.Suite);
end.