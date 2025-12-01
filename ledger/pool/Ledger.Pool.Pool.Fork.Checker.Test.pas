unit V2.Ledger.Pool.ForkChecker.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  V2.Common.Config,
  V2.Interfaces.Core,
  V2.Ledger.Pool,
  V2.Ledger.Test_Tools,
  V2.Ledger.Pool.Mock; // Assuming mock objects are in a shared unit

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
