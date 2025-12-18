unit consensus.trigger;

interface

uses
  consensus.dpos,
  consensus.subscriber,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
  Ledger.Consensus.Config,
  Ledger.Consensus.Consensus,
  Ledger.Consensus.Consensus.Contract,
  Ledger.Consensus.Consensus.Contract.Dpos,
  Ledger.Consensus.Consensus.Contract.Dpos.Test,
  Ledger.Consensus.Consensus.Event,
  Ledger.Consensus.Consensus.Impl,
  Ledger.Consensus.Consensus.Point.Array,
  Ledger.Consensus.Consensus.Point.Array.Test,
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Simple.Test,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.Dpos,
  Ledger.Consensus.Mock.Ch,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Unittest.Util.Test,
  log15,
  pool.lock,
  System.Classes,
  System.SysUtils,
  System.Threading,
  Vite.Common,
  Vite.Types;

type
  TTrigger = class
  private
    FLock: IChainRollback;
    FMLog: ILogger;
  public
    constructor Create(Lock: IChainRollback);
    procedure Update(Ctx: ICancelable; const Gid: TGid; T: IDposReader; Sub: ISubscribeTrigger);
  end;

function NewTrigger(Lock: IChainRollback): TTrigger;

implementation

{ TTrigger }

constructor TTrigger.Create(Lock: IChainRollback);
begin
  FLock := Lock;
  FMLog := TLogger.New('module', 'consensus/trigger');
end;

procedure TTrigger.Update(Ctx: ICancelable; const Gid: TGid; T: IDposReader; Sub: ISubscribeTrigger);
var
  Index: UInt64;
  ElectionResult: TElectionResult;
  SleepT: TTimeSpan;
begin
  Index := T.Time2Index(Now);

  while True do
  begin
    if Ctx.IsCanceled then
      Exit;

    FMLog.Info('trigger update', 'gid', Gid, 'index', Index);
    FLock.RLockRollback;
    try
      try
        ElectionResult := T.ElectionIndex(Index);
      except
        on E: Exception do
        begin
          FMLog.Error('can''t get election result. time is ' + FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', Now) + '".', 'err', E.Message);
          if Ctx.IsCanceled then
            Exit;
          Sleep(1000);
          Continue;
        end;
      end;
    finally
      FLock.RUnLockRollback;
    end;

    if ElectionResult.Index <> Index then
    begin
      FMLog.Error('can''t get Index election result. Index is ' + IntToStr(Index));
      Index := T.Time2Index(Now);
      Continue;
    end;

    Sub.TriggerEvent(Gid, procedure(E: TSubscribeEvent)
    begin
      TTask.Run(procedure
      begin
        E.Trigger(Ctx, ElectionResult, T.GenProofTime(Index));
      end);
    end);
    Sub.TriggerProducerEvent(Gid, procedure(E: TProducerSubscribeEvent)
    begin
      TTask.Run(procedure
      begin
        E.Trigger(Ctx, ElectionResult, T.GenProofTime(Index));
      end);
    end);

    SleepT := ElectionResult.ETime - Now - TTimeSpan.FromMilliseconds(500);
    FMLog.Info('trigger update sleep', 'gid', Gid, 'index', Index, 'sleepT', SleepT.ToString);
    if Ctx.IsCanceled then
      Exit;
    Sleep(SleepT.TotalMilliseconds);
    Index := ElectionResult.Index + 1;
  end;
end;

function NewTrigger(Lock: IChainRollback): TTrigger;
begin
  Result := TTrigger.Create(Lock);
end;

end.
