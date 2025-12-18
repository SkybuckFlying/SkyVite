unit V2.Ledger.Pool.Blacklist.Test;

interface

uses
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Bc.Pool,
  Ledger.Pool.Blacklist,
  Ledger.Pool.Branch.Chain,
  Ledger.Pool.Chain.Pool,
  Ledger.Pool.Chain.Pool.Test,
  Ledger.Pool.Context,
  Ledger.Pool.Face,
  Ledger.Pool.Mock.Common.Block,
  Ledger.Pool.Pipeline.Pool,
  Ledger.Pool.Pool,
  Ledger.Pool.Pool.Batch,
  Ledger.Pool.Pool.Batch.Chunk,
  Ledger.Pool.Pool.Batch.Fork,
  Ledger.Pool.Pool.Fork.Checker,
  Ledger.Pool.Pool.Fork.Checker.Test,
  Ledger.Pool.Snapshot.Listener,
  Ledger.Pool.Snapshot.Pool,
  Ledger.Pool.Snapshot.Pool.Test,
  Ledger.Pool.Tools,
  Ledger.Pool.Tools.Chain,
  Ledger.Pool.Tools.Fetcher,
  Ledger.Pool.Tools.Verifier,
  Ledger.Pool.Worker,
  System.Classes,
  System.SysUtils,
  System.Threading,
  TestFramework,
  V2.Common,
  V2.Common.Types,
  V2.Ledger.Pool.Blacklist;

type
  [TestFixture]
  TBlacklistTest = class(TObject)
  public
    [Test]
    procedure TestBlacklist_AddAddTimeout;
  end;

implementation

{ TBlacklistTest }

procedure TBlacklistTest.TestBlacklist_AddAddTimeout;
var
  Blacklist: IBlacklist;
  Hash: THash;
begin
  Blacklist := TBlacklist.Create;
  Assert.IsNotNull(Blacklist, 'Failed to create blacklist');

  Hash := MockHash(10);
  Blacklist.AddAddTimeout(Hash, 5 * 1000); // 5 seconds in milliseconds

  Assert.IsTrue(Blacklist.Exists(Hash), 'Hash should exist immediately after being added');

  TThread.Sleep(7 * 1000); // Wait for 7 seconds

  Assert.IsFalse(Blacklist.Exists(Hash), 'Hash should not exist after timeout');

  // Add it again
  Blacklist.AddAddTimeout(Hash, 5 * 1000);
  Assert.IsTrue(Blacklist.Exists(Hash), 'Hash should exist again after being re-added');
end;

initialization
  RegisterTest(TBlacklistTest.Suite);
end;
