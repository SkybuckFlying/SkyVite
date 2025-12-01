unit consensus.trigger;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Threading,
  Vite.Common,
  Vite.Types,
  consensus.dpos,
  consensus.subscriber,
  pool.lock,
  log15;

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
