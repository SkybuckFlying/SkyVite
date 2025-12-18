unit Ledger.Pool.Batch.Executor;

interface

uses
  Common.Types,
  Ledger.Pool.Batch,
  Ledger.Pool.Batch.Batch,
  Ledger.Pool.Batch.Batch.Impl,
  Ledger.Pool.Batch.Batch.Test,
  Ledger.Pool.Batch.Bucket,
  Ledger.Pool.Batch.Example.Test,
  Ledger.Pool.Batch.Level,
  Ledger.Pool.Batch.Level.Account,
  Ledger.Pool.Batch.Level.Snapshot,
  Ledger.Pool.Batch.Mock.Chain,
  Ledger.Pool.Batch.Mock.Item,
  System.SysUtils System.Classes System.Generics.Collections;

type
  TBatchExecutor = class
  private
    FP: IBatch;
    FSnapshotFn: TBucketExecutorFn;
    FAccountFn: TBucketExecutorFn;
    FMaxParallel: Integer;
    FLog: ILogger;
    function InsertLevel(l: ILevel): Exception;
    function InsertSnapshotLevel(l: ILevel): Exception;
    function InsertAccountLevel(l: ILevel): Exception;
  public
    constructor Create(p: IBatch; snapshotFn, accountFn: TBucketExecutorFn);
    function Execute: Exception;
  end;

implementation

uses
  System.Threading, System.Diagnostics;

{ TBatchExecutor }

constructor TBatchExecutor.Create(p: IBatch; snapshotFn, accountFn: TBucketExecutorFn);
begin
  inherited Create;
  FP := p;
  FSnapshotFn := snapshotFn;
  FAccountFn := accountFn;
  FLog := TLogger.Create('module', 'pool/batch', 'batchId', p.Id);
  FMaxParallel := 5;
end;

function TBatchExecutor.Execute: Exception;
var
  vLevels: TArray<ILevel>;
  vLevel: ILevel;
  vError: Exception;
begin
  Result := nil;
  vLevels := FP.Levels;
  for vLevel in vLevels do
  begin
    if vLevel = nil then
      Continue;
    FLog.Info(Format('insert queue level[%d][%s] insert.', [vLevel.Index, BoolToStr(vLevel.Snapshot, True)]));
    vError := InsertLevel(vLevel);
    if vError <> nil then
      Exit(vError);
    vLevel.Done;
  end;
end;

function TBatchExecutor.InsertLevel(l: ILevel): Exception;
begin
  if l.Snapshot then
    Result := InsertSnapshotLevel(l)
  else
    Result := InsertAccountLevel(l);
end;

function TBatchExecutor.InsertSnapshotLevel(l: ILevel): Exception;
var
  vNum: Integer;
  vBucket: IBucket;
  vVersion: TUInt64;
  vStopwatch: TStopwatch;
begin
  vNum := 0;
  vStopwatch := TStopwatch.StartNew;
  try
    vVersion := FP.Version;
    for vBucket in l.Buckets do
    begin
      vNum := vNum + Length(vBucket.Items);
      FSnapshotFn(FP, l, vBucket, vVersion);
    end;
  finally
    vStopwatch.Stop;
    FLog.Info(Format('level[%d][%d][%s][%d]->%dS', [l.Index, -1, vStopwatch.Elapsed, vNum, vNum]));
  end;
  Result := nil;
end;

function TBatchExecutor.InsertAccountLevel(l: ILevel): Exception;
var
  vVersion: TUInt64;
  vBuckets: TArray<IBucket>;
  vLenBuckets: Integer;
  vN: Integer;
  vBucketCh: TChannel<IBucket>;
  vWg: TCountdownEvent;
  vNum: Integer;
  vGlobalErr: Exception;
  vStopwatch: TStopwatch;
  vLevelInfo: string;
  vBucket: IBucket;
begin
  vVersion := FP.Version;
  vBuckets := l.Buckets;
  vLenBuckets := Length(vBuckets);
  if vLenBuckets = 0 then
    Exit(nil);

  vN := Min(vLenBuckets, FMaxParallel);
  vBucketCh := TChannel<IBucket>.Create(vLenBuckets);
  vWg := TCountdownEvent.Create(vN);
  vNum := 0;
  vGlobalErr := nil;
  vStopwatch := TStopwatch.StartNew;

  for var i := 0 to vN - 1 do
  begin
    TTask.Run(procedure
      var
        vB: IBucket;
      begin
        try
          while vBucketCh.TryReceive(vB) do
          begin
            if vGlobalErr <> nil then
              Exit;
            try
              FAccountFn(FP, l, vB, vVersion);
              Interlocked.Add(vNum, Length(vB.Items));
            except
              on E: Exception do
              begin
                vGlobalErr := E;
                FLog.Info(Format('error[%s] for insert account block.', [E.Message]));
                Exit;
              end;
            end;
          end;
        finally
          vWg.Signal;
        end;
      end);
  end;

  vLevelInfo := '';
  for vBucket in vBuckets do
  begin
    vLevelInfo := vLevelInfo + '|' + IntToStr(Length(vBucket.Items));
    if vBucket.Owner = nil then
      vLevelInfo := vLevelInfo + 'S';
    vBucketCh.Add(vBucket);
  end;
  vBucketCh.Close;
  vWg.Wait;
  vStopwatch.Stop;

  if vGlobalErr <> nil then
    vLevelInfo := Format('level[%d][%d][%s][%d]->%s, %s', [l.Index, -1, vStopwatch.Elapsed, vNum, vLevelInfo, vGlobalErr.Message])
  else
    vLevelInfo := Format('level[%d][%d][%s][%d]->%s', [l.Index, -1, vStopwatch.Elapsed, vNum, vLevelInfo]);
  FLog.Info(vLevelInfo);

  Result := vGlobalErr;
end;

end.
