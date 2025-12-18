unit Ledger.Chain.AccountBlock.Test;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Chain.Account,
  Ledger.Chain.Account.Block,
  Ledger.Chain.Account.Test,
  Ledger.Chain.AccountBlock,
  Ledger.Chain.Builtin.Contract,
  Ledger.Chain.Builtin.Contract.Test,
  Ledger.Chain.Chain,
  Ledger.Chain.Chain.Test,
  Ledger.Chain.Check,
  Ledger.Chain.Delete,
  Ledger.Chain.Delete.Test,
  Ledger.Chain.Event.Manager,
  Ledger.Chain.Fork,
  Ledger.Chain.Insert,
  Ledger.Chain.Insert.Test,
  Ledger.Chain.Interface,
  Ledger.Chain.Meta,
  Ledger.Chain.Onroad,
  Ledger.Chain.Onroad.Test,
  Ledger.Chain.Snapshot.Block,
  Ledger.Chain.Snapshot.Block.Test,
  Ledger.Chain.State,
  Ledger.Chain.State.Test,
  Ledger.Chain.Sync.Ledger,
  Ledger.Chain.Unconfirmed,
  Ledger.Chain.Unconfirmed.Test,
  System.SysUtils,
  TestFramework;

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
