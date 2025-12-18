unit Ledger.Chain.Onroad.Test;

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
  Ledger.Chain.Snapshot.Block,
  Ledger.Chain.Snapshot.Block.Test,
  Ledger.Chain.State,
  Ledger.Chain.State.Test,
  Ledger.Chain.Sync.Ledger,
  Ledger.Chain.Unconfirmed,
  Ledger.Chain.Unconfirmed.Test;

type
  [TestFixture]
  TOnRoadTests = class
  public
    [Test]
    procedure TestChain_OnRoad;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  Ledger.Chain,
  Common.Types;

procedure TestOnRoad(const AChainInstance: TChain; const AAccounts: TDictionary<TAddress, TAccount>);
begin
  for var KVP in AAccounts do
  begin
    var Addr := KVP.Key;
    var Blocks := AChainInstance.GetOnRoadBlocksByAddr(Addr, 0, 10);
    // Further assertions would go here
  end;
end;

procedure TOnRoadTests.TestChain_OnRoad;
var
  vChainInstance: TChain;
  vAccounts: TDictionary<TAddress, TAccount>;
begin
  // SetUp and TearDown are assumed to be defined elsewhere for chain testing
  SetUp(vChainInstance, vAccounts, 123, 1231, 12);
  try
    TestOnRoad(vChainInstance, vAccounts);
  finally
    TearDown(vChainInstance);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TOnRoadTests);
end.
