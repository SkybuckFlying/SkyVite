unit V2.Ledger.Pool.SnapshotPool.Test;

interface

uses
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Bc.Pool,
  Ledger.Pool.Blacklist,
  Ledger.Pool.Blacklist.Test,
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
  Ledger.Pool.Tools,
  Ledger.Pool.Tools.Chain,
  Ledger.Pool.Tools.Fetcher,
  Ledger.Pool.Tools.Verifier,
  Ledger.Pool.Worker,
  System.Classes,
  System.SysUtils,
  TestFramework,
  V2.Common,
  V2.Ledger.Pool,
  V2.Ledger.Pool.Mock // Assuming mock objects are in a shared unit,
  V2.Log15;

type
  [TestFixture]
  TSnapshotPoolTest = class(TObject)
  public
    [Test]
    procedure TestNewSnapshotPool;
    // TODO: Add more comprehensive tests for adding blocks and forking logic
  end;

implementation

{ TSnapshotPoolTest }

procedure TSnapshotPoolTest.TestNewSnapshotPool;
var
  Version: TVersion;
  Verifier: TSnapshotVerifier;
  Syncer: TSnapshotSyncer;
  ChainDB: TSnapshotCh;
  Blacklist: IBlacklist;
  Cond: TCondTimer;
  Logger: ILogger;
  Pool: TSnapshotPool;
  Tools: TTools;
  ParentPool: TPool;
begin
  Version := TVersion.Create;
  Logger := TLogger.Create('module', 'mock');
  // These would be mocks in a real test scenario
  Verifier := TSnapshotVerifier.Create(nil);
  Syncer := TSnapshotSyncer.Create(nil, Logger);
  ChainDB := TSnapshotCh.Create(nil, Version);
  Blacklist, _ := TBlacklist.Create;
  Cond := TCondTimer.Create;

  Pool := TSnapshotPool.Create('snapshot', Version, Verifier, Syncer, ChainDB, Blacklist, Cond, Logger);
  Assert.IsNotNull(Pool, 'Failed to create snapshot pool');

  // Mock the parent pool and tools for Init
  ParentPool := TPool.Create(nil, nil, nil, nil);
  Tools := TTools.Create(nil);

  Assert.WillNotRaise(procedure
    begin
      Pool.Init(Tools, ParentPool);
      Pool.Start;
      Pool.Stop;
    end, 'SnapshotPool lifecycle methods should not raise exceptions');

  Pool.Free;
  ParentPool.Free;
  Tools.Free;
  Cond.Free;
  ChainDB.Free;
  Syncer.Free;
  Verifier.Free;
  Version.Free;
end;

initialization
  RegisterTest(TSnapshotPoolTest.Suite);
end.
