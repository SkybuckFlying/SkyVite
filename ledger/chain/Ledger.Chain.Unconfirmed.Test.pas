unit Ledger.Chain.Unconfirmed.Test;

interface

uses
  DUnitX.TestFramework,
  Ledger.Chain.Account,
  Ledger.Chain.Account.Block,
  Ledger.Chain.Account.Block.Test,
  Ledger.Chain.Account.Test,
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
  Ledger.Chain.Unconfirmed;

type
  [TestFixture]
  TUnconfirmedTests = class
  public
    [Test]
    procedure TestUnconfirmed;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Ledger.Chain,
  Common.Types,
  Interfaces.Core;

procedure GetUnconfirmedBlocks(const AChain: TChain; const AAccounts: TDictionary<TAddress, TAccount>);
var
  vQueryUnconfirmedBlocks: TArray<TAccountBlock>;
  vCount: Integer;
begin
  vQueryUnconfirmedBlocks := AChain.Cache.GetUnconfirmedBlocks;

  for var Block in vQueryUnconfirmedBlocks do
  begin
    var Account := AAccounts[Block.AccountAddress];
    Assert.IsTrue(Account.UnconfirmedBlocks.ContainsKey(Block.Hash));
  end;

  vCount := 0;
  for var KVP in AAccounts do
  begin
    var Addr := KVP.Key;
    var Account := KVP.Value;
    vCount := vCount + Account.UnconfirmedBlocks.Count;

    var QueryBlocks := AChain.GetUnconfirmedBlocks(Addr);
    Assert.AreEqual(Length(QueryBlocks), Account.UnconfirmedBlocks.Count,
      Format('snapshot: %d, addr: %s', [AChain.GetLatestSnapshotBlock.Height, Addr.ToString]));

    for var QueryBlock in QueryBlocks do
    begin
      Assert.IsTrue(Account.UnconfirmedBlocks.ContainsKey(QueryBlock.Hash));
    end;
  end;

  Assert.AreEqual(Length(vQueryUnconfirmedBlocks), vCount);
end;

procedure TUnconfirmedTests.TestUnconfirmed;
var
  vChainInstance: TChain;
  vAccounts: TDictionary<TAddress, TAccount>;
  vSnapshotBlocks: TArray<TAccountBlock>;
begin
  SetUp(vChainInstance, vAccounts, vSnapshotBlocks, 2, 30, 100);
  try
    GetUnconfirmedBlocks(vChainInstance, vAccounts);
  finally
    TearDown(vChainInstance);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TUnconfirmedTests);
end.
