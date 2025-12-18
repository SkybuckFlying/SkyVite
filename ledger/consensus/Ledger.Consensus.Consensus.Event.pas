unit Ledger.Consensus.Event;

interface

uses
  Common.Types,
  GoToDelphi.Helpers.TChannel,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
  Ledger.Consensus.Config,
  Ledger.Consensus.Consensus,
  Ledger.Consensus.Consensus.Contract,
  Ledger.Consensus.Consensus.Contract.Dpos,
  Ledger.Consensus.Consensus.Contract.Dpos.Test,
  Ledger.Consensus.Consensus.Impl,
  Ledger.Consensus.Consensus.Point.Array,
  Ledger.Consensus.Consensus.Point.Array.Test,
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Simple.Test,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.Core,
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
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  System.Classes,
  System.SysUtils,
  System.Threading,
  V2.Interfaces.Core;

type
  TSubscribeEvent = class
  private
    mAddr: TAddress;
    mGid: TGid;
    mFn: TEventFunc;
    procedure TriggerAll(ParaCtx: ICancelable; ParaResult: IElectionResult; ParaVoteTime: TDateTime);
    procedure TriggerAddr(ParaCtx: ICancelable; ParaResult: IElectionResult; ParaVoteTime: TDateTime);
  public
    constructor Create(const ParaAddr: TAddress; const ParaGid: TGid; ParaFn: TEventFunc);
    procedure Trigger(ParaCtx: ICancelable; ParaResult: IElectionResult; ParaVoteTime: TDateTime);
  end;

  TProducerSubscribeEvent = class
  private
    mGid: TGid;
    mFn: TProducersEventFunc;
  public
    constructor Create(const ParaGid: TGid; ParaFn: TProducersEventFunc);
    procedure Trigger(ParaCtx: ICancelable; ParaResult: IElectionResult; ParaVoteTime: TDateTime);
  end;

function NewConsensusEvent(ParaR: IElectionResult; ParaP: IMemberPlan; const ParaGid: TGid; ParaVoteTime: TDateTime): TEvent;

implementation

uses
  System.DateUtils;

{ TSubscribeEvent }

constructor TSubscribeEvent.Create(const ParaAddr: TAddress; const ParaGid: TGid; ParaFn: TEventFunc);
begin
  mAddr := ParaAddr;
  mGid := ParaGid;
  mFn := ParaFn;
end;

procedure TSubscribeEvent.Trigger(ParaCtx: ICancelable; ParaResult: IElectionResult; ParaVoteTime: TDateTime);
begin
  if mAddr = nil then
  begin
    TriggerAll(ParaCtx, ParaResult, ParaVoteTime);
  end
  else
  begin
    TriggerAddr(ParaCtx, ParaResult, ParaVoteTime);
  end;
end;

procedure TSubscribeEvent.TriggerAll(ParaCtx: ICancelable; ParaResult: IElectionResult; ParaVoteTime: TDateTime);
var
  vP: IMemberPlan;
  vNow: TDateTime;
  vSub: TTimeSpan;
  vTimer: TChannel<Boolean>;
begin
  for vP in ParaResult.Plans do
  begin
    vNow := Now;
    vSub := vP.STime - vNow;
    if vSub.TotalSeconds < -1 then
    begin
      Continue;
    end;
    if vSub.TotalMilliseconds > 10 then
    begin
      vTimer := TChannel<Boolean>.Create;
      TTask.Run(procedure
      begin
        Sleep(vSub.TotalMilliseconds);
        vTimer.Send(True);
      end);
      TChannel.Select([ParaCtx.AsChannel, vTimer], procedure(ParaValue: TValue; ParaChannel: TChannel)
      begin
        if ParaChannel = ParaCtx.AsChannel then
        begin
          Exit;
        end;
      end);
    end;
    mFn(NewConsensusEvent(ParaResult, vP, mGid, ParaVoteTime));
  end;
end;

procedure TSubscribeEvent.TriggerAddr(ParaCtx: ICancelable; ParaResult: IElectionResult; ParaVoteTime: TDateTime);
var
  vP: IMemberPlan;
  vNow: TDateTime;
  vSub: TTimeSpan;
  vTimer: TChannel<Boolean>;
begin
  for vP in ParaResult.Plans do
  begin
    if vP.Member = mAddr then
    begin
      vNow := Now;
      vSub := vP.STime - vNow;
      if vSub.TotalSeconds < -1 then
      begin
        Continue;
      end;
      if vSub.TotalMilliseconds > 10 then
      begin
        vTimer := TChannel<Boolean>.Create;
        TTask.Run(procedure
        begin
          Sleep(vSub.TotalMilliseconds);
          vTimer.Send(True);
        end);
        TChannel.Select([ParaCtx.AsChannel, vTimer], procedure(ParaValue: TValue; ParaChannel: TChannel)
        begin
          if ParaChannel = ParaCtx.AsChannel then
          begin
            Exit;
          end;
        end);
      end;
      mFn(NewConsensusEvent(ParaResult, vP, mGid, ParaVoteTime));
    end;
  end;
end;

{ TProducerSubscribeEvent }

constructor TProducerSubscribeEvent.Create(const ParaGid: TGid; ParaFn: TProducersEventFunc);
begin
  mGid := ParaGid;
  mFn := ParaFn;
end;

procedure TProducerSubscribeEvent.Trigger(ParaCtx: ICancelable; ParaResult: IElectionResult; ParaVoteTime: TDateTime);
var
  vR: TArray<TAddress>;
  vV: IMemberPlan;
  vProducersEvent: TProducersEvent;
begin
  SetLength(vR, 0);
  for vV in ParaResult.Plans do
  begin
    vR := Concat(vR, [vV.Member]);
  end;
  vProducersEvent.Addrs := vR;
  vProducersEvent.Index := ParaResult.Index;
  vProducersEvent.Gid := mGid;
  mFn(vProducersEvent);
end;

function NewConsensusEvent(ParaR: IElectionResult; ParaP: IMemberPlan; const ParaGid: TGid; ParaVoteTime: TDateTime): TEvent;
begin
  Result.Gid := ParaGid;
  Result.Address := ParaP.Member;
  Result.Stime := ParaP.STime;
  Result.Etime := ParaP.ETime;
  Result.Timestamp := ParaP.STime;
  Result.VoteTime := ParaVoteTime;
  Result.PeriodStime := ParaR.STime;
  Result.PeriodEtime := ParaR.ETime;
end;

end.
