unit V2.Ledger.Pool.ForkChecker.Test;

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
  TestFramework,
  V2.Common.Config,
  V2.Interfaces.Core,
  V2.Ledger.Pool,
  V2.Ledger.Pool.Mock // Assuming mock objects are in a shared unit,
  V2.Ledger.Test_Tools;

type
  [TestFixture]
  TForkCheckerTest = class(TObject)
  public
    [Test]
    procedure TestPool_CheckIrreversible_OnNewChain;
    // TODO: Add more comprehensive tests for forking logic
  end;

implementation

{ TForkCheckerTest }

procedure TForkCheckerTest.TestPool_CheckIrreversible_OnNewChain;
var
  Chain: IChain;
  TempDir: string;
  Vite: TMockVite;
  Pool: IPool;
  Block: ISnapshotBlock;
begin
  Chain := NewTestChainInstance('TestPool_CheckIrreversible', True, MockGenesis, TempDir);
  try
    Vite := TMockVite.Create(Chain);
    try
      Pool := TPool.Create(Vite.Net, Vite.Producer, Vite.Chain, Vite.SbpStatReader);
      Assert.IsNotNull(Pool, 'Failed to create pool');
      try
        Pool.Start;
        Block := Pool.GetIrreversibleBlock;
        Assert.IsNull(Block, 'Irreversible block should be nil on a new chain');
      finally
        Pool.Stop;
      end;
    finally
      Vite.Free;
    end;
  finally
    ClearChain(Chain, TempDir);
  end;
end;

initialization
  RegisterTest(TForkCheckerTest.Suite);
end.
