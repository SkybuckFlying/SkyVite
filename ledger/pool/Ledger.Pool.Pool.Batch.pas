unit Ledger.Pool.Pool.Batch;

interface

uses
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Batch,
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
  Ledger.Pool.Worker;

type
  TPoolBatchHelper = class helper for TPool
  public
    procedure Insert;
    function MakeQueue: IBatch;
  end;

implementation

{ TPoolBatchHelper }

procedure TPoolBatchHelper.Insert;
begin
  // Implementation to be added
end;

function TPoolBatchHelper.MakeQueue: IBatch;
begin
  // Implementation to be added
  Result := nil;
end;

end.
