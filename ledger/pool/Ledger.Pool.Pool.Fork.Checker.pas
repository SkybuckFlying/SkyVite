unit Ledger.Pool.Pool.Fork.Checker;

interface

uses
  Interfaces.Core,
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
  Ledger.Pool.Pool.Fork.Checker.Test,
  Ledger.Pool.Snapshot.Listener,
  Ledger.Pool.Snapshot.Pool,
  Ledger.Pool.Snapshot.Pool.Test,
  Ledger.Pool.Tools,
  Ledger.Pool.Tools.Chain,
  Ledger.Pool.Tools.Fetcher,
  Ledger.Pool.Tools.Verifier,
  Ledger.Pool.Tree,
  Ledger.Pool.Worker,
  System.SysUtils System.Generics.Collections;

type
  TIrreversibleInfo = record
    Point: ISnapshotBlock;
    ProofPoint: ISnapshotBlock;
    RollbackV: TUInt64;
    function ToString: string;
  end;

  TPoolForkCheckerHelper = class helper for TPool
  public
    procedure CheckFork;
    function SnapshotFork(branch: IBranch; targetHeight: TUInt64): Exception;
    function FindForkKeyPoint(longest: IBranch): ISnapshotBlock;
    function SnapshotRollback(longest: IBranch; keyPoint: ISnapshotBlock): Exception;
    function CheckIrreversiblePrinciple(keyPoint: ISnapshotBlock): Exception;
    function UpdateIrreversibleBlock: Exception;
    function GetLatestIrreversibleBlock(lastProofPoint: ISnapshotBlock): TIrreversibleInfo;
    function GetLatestIrreversible(lastIdx: TUInt64; nodeCnt: Integer): TIrreversibleInfo;
    function CheckIrreversible(point, proofPoint: ISnapshotBlock; irreversibleCnt: TUInt64): Boolean;
    function GetIrreversibleBlock: ISnapshotBlock;
    function SnapshotInsert(targetHeight: TUInt64): Exception;
    function ModifyCurrentAccounts(targetHeight: TUInt64): Exception;
  end;

implementation

{ TIrreversibleInfo }

function TIrreversibleInfo.ToString: string;
begin
  Result := '';
  if Point <> nil then
    Result := Result + Format('point[%d-%s-%s]', [Point.Height, Point.Hash.ToString, Point.Timestamp]);
  if ProofPoint <> nil then
    Result := Result + Format('proofPoint[%d-%s-%s]', [ProofPoint.Height, ProofPoint.Hash.ToString, ProofPoint.Timestamp]);
end;

{ TPoolForkCheckerHelper }

procedure TPoolForkCheckerHelper.CheckFork;
var
  vLongest: IBranch;
  vLongestH: TUInt64;
  vError: Exception;
  vCurrent: IBranch;
  vCurTailHeight: TUInt64;
begin
  vLongest := FPendingSc.CheckFork(vLongestH, vError);
  if vError <> nil then
  begin
    FLog.Error('check fork error', ['error', vError.Message]);
    Exit;
  end;

  if vLongest = nil then
    Exit;

  vCurrent := FPendingSc.CurrentChain;
  vCurTailHeight := vCurrent.TailHH.Height;
  FLog.Warn('[try]snapshot chain start fork.', ['longest', vLongest.ID, 'current', vCurrent.ID,
    'longestTail', vLongest.SprintTail, 'longestHead', vLongest.SprintHead, 'currentTail', vCurrent.SprintTail, 'currentHead', vCurrent.SprintHead]);

  LockInsert;
  try
    LockRollback;
    try
      FRollbackVersion.Inc;
      FVersion.Inc;
      FLog.Warn('[lock]snapshot chain start fork.', ['longest', vLongest.ID, 'current', vCurrent.ID]);

      vError := SnapshotFork(vLongest, vLongestH);
      if vError <> nil then
      begin
        FLog.Error(Format('fork snapshot fail. targetId:%s, targetHeight:%d, switch to current[%s].', [vLongest.ID, vLongestH, vCurrent.ID]), ['err', vError.Message]);
        vError := SnapshotFork(vCurrent, vCurTailHeight);
        if vError <> nil then
          raise vError;
      end;
    finally
      UnLockRollback;
    end;
  finally
    UnLockInsert;
  end;
end;

function TPoolForkCheckerHelper.SnapshotFork(branch: IBranch; targetHeight: TUInt64): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TPoolForkCheckerHelper.FindForkKeyPoint(longest: IBranch): ISnapshotBlock;
begin
  // Implementation to be added
  Result := nil;
end;

function TPoolForkCheckerHelper.SnapshotRollback(longest: IBranch; keyPoint: ISnapshotBlock): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TPoolForkCheckerHelper.CheckIrreversiblePrinciple(keyPoint: ISnapshotBlock): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TPoolForkCheckerHelper.UpdateIrreversibleBlock: Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TPoolForkCheckerHelper.GetLatestIrreversibleBlock(lastProofPoint: ISnapshotBlock): TIrreversibleInfo;
begin
  // Implementation to be added
end;

function TPoolForkCheckerHelper.GetLatestIrreversible(lastIdx: TUInt64; nodeCnt: Integer): TIrreversibleInfo;
begin
  // Implementation to be added
end;

function TPoolForkCheckerHelper.CheckIrreversible(point, proofPoint: ISnapshotBlock; irreversibleCnt: TUInt64): Boolean;
begin
  // Implementation to be added
  Result := False;
end;

function TPoolForkCheckerHelper.GetIrreversibleBlock: ISnapshotBlock;
begin
  // Implementation to be added
  Result := nil;
end;

function TPoolForkCheckerHelper.SnapshotInsert(targetHeight: TUInt64): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

function TPoolForkCheckerHelper.ModifyCurrentAccounts(targetHeight: TUInt64): Exception;
begin
  // Implementation to be added
  Result := nil;
end;

end.
