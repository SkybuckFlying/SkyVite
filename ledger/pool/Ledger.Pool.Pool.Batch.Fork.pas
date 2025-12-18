unit Ledger.Pool.Pool.Batch.Fork;

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
  Ledger.Pool.Pool.Batch,
  Ledger.Pool.Pool.Batch.Chunk,
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
  System.SysUtils;

type
  TPoolBatchForkHelper = class helper for TPool
  public
    function InsertTo(height: TUInt64): Exception;
    function InsertQueueForFork(q: IBatch): Exception;
    function CheckTarget(height: TUInt64): Exception;
    function MakeQueueOnly: IBatch;
  end;

implementation

{ TPoolBatchForkHelper }

function TPoolBatchForkHelper.InsertTo(height: TUInt64): Exception;
var
  vError: Exception;
  vQueue: IBatch;
begin
  Result := nil;
  while True do
  begin
    vError := CheckTarget(height);
    if vError = nil then
      Exit(nil);

    vQueue := MakeQueueOnly;
    if vQueue.Size = 0 then
      Exit(CheckTarget(height));

    vError := InsertQueueForFork(vQueue);
    if vError <> nil then
    begin
      FLog.Error('insert queue err:', ['err', vError.Message]);
      FLog.Error('all queue:', ['queue', vQueue.Info]);
      // Further error handling might be needed
      Exit(CheckTarget(height));
    end;
  end;
end;

function TPoolBatchForkHelper.InsertQueueForFork(q: IBatch): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TPoolBatchForkHelper.CheckTarget(height: TUInt64): Exception;
var
  vCurHeight: TUInt64;
begin
  vCurHeight := FPendingSc.CurrentChain.TailHH.Height;
  if vCurHeight >= height then
    Result := nil
  else
    Result := Exception.CreateFmt('target fail.[%d][%d]', [height, vCurHeight]);
end;

function TPoolBatchForkHelper.MakeQueueOnly: IBatch;
begin
  // Implementation to be added
  Result := nil;
end;

end.
