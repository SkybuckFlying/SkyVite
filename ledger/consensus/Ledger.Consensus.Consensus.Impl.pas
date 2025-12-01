unit Ledger.Consensus.ConsensusImpl;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  Common.Types,
  V2.Interfaces.Core,
  Ledger.Consensus.Consensus,
  Common.Lifecycle,
  GoToDelphi.Helpers.TChannel;

type
  TConsensusImpl = class(TInterfacedObject, IConsensus)
  private
    FConsensus: TConsensus;
  public
    constructor Create(ParaCh: IChain; ParaRollback: IChainRollback);
    destructor Destroy; override;

    function VerifySnapshotProducer(ParaBlock: ISnapshotBlock): Exception;
    function VerifyABsProducer(const ParaAbs: TDictionary<TGid, TArray<IAccountBlock>>): TArray<IAccountBlock>;
    function VerifyAccountProducer(ParaBlock: IAccountBlock): Exception;

    procedure Subscribe(const ParaGid: TGid; const ParaId: string; const ParaAddr: TAddress; ParaFn: TEventFunc);
    procedure UnSubscribe(const ParaGid: TGid; const ParaId: string);
    procedure SubscribeProducers(const ParaGid: TGid; const ParaId: string; ParaFn: TProducersEventFunc);
    function TriggerMineEvent(const ParaAddr: TAddress): Exception;

    function ReadByIndex(const ParaGid: TGid; ParaIndex: UInt64): TTuple<TArray<TEvent>, UInt64, Exception>;
    function VoteTimeToIndex(const ParaGid: TGid; ParaT2: TDateTime): TTuple<UInt64, Exception>;
    function VoteIndexToTime(const ParaGid: TGid; ParaI: UInt64): TTuple<TDateTime, TDateTime, Exception>;

    procedure Start;
    procedure Init(ParaCfg: TConsensusCfg);
    procedure Stop;

    function API: IAPIReader;
    function SBPReader: ISBPStatReader;
  end;

implementation

{ TConsensusImpl }

constructor TConsensusImpl.Create(ParaCh: IChain; ParaRollback: IChainRollback);
begin
  FConsensus := TConsensus.Create(ParaCh, ParaRollback);
end;

destructor TConsensusImpl.Destroy;
begin
  FConsensus.Free;
  inherited;
end;

function TConsensusImpl.VerifySnapshotProducer(ParaBlock: ISnapshotBlock): Exception;
begin
  Result := FConsensus.VerifySnapshotProducer(ParaBlock);
end;

function TConsensusImpl.VerifyABsProducer(const ParaAbs: TDictionary<TGid, TArray<IAccountBlock>>): TArray<IAccountBlock>;
begin
  Result := FConsensus.VerifyABsProducer(ParaAbs);
end;

function TConsensusImpl.VerifyAccountProducer(ParaBlock: IAccountBlock): Exception;
begin
  Result := FConsensus.VerifyAccountProducer(ParaBlock);
end;

procedure TConsensusImpl.Subscribe(const ParaGid: TGid; const ParaId: string; const ParaAddr: TAddress; ParaFn: TEventFunc);
begin
  FConsensus.Subscribe(ParaGid, ParaId, ParaAddr, ParaFn);
end;

procedure TConsensusImpl.UnSubscribe(const ParaGid: TGid; const ParaId: string);
begin
  FConsensus.UnSubscribe(ParaGid, ParaId);
end;

procedure TConsensusImpl.SubscribeProducers(const ParaGid: TGid; const ParaId: string; ParaFn: TProducersEventFunc);
begin
  FConsensus.SubscribeProducers(ParaGid, ParaId, ParaFn);
end;

function TConsensusImpl.TriggerMineEvent(const ParaAddr: TAddress): Exception;
begin
  Result := FConsensus.TriggerMineEvent(ParaAddr);
end;

function TConsensusImpl.ReadByIndex(const ParaGid: TGid; ParaIndex: UInt64): TTuple<TArray<TEvent>, UInt64, Exception>;
begin
  Result := FConsensus.ReadByIndex(ParaGid, ParaIndex);
end;

function TConsensusImpl.VoteTimeToIndex(const ParaGid: TGid; ParaT2: TDateTime): TTuple<UInt64, Exception>;
begin
  Result := FConsensus.VoteTimeToIndex(ParaGid, ParaT2);
end;

function TConsensusImpl.VoteIndexToTime(const ParaGid: TGid; ParaI: UInt64): TTuple<TDateTime, TDateTime, Exception>;
begin
  Result := FConsensus.VoteIndexToTime(ParaGid, ParaI);
end;

procedure TConsensusImpl.Init(ParaCfg: TConsensusCfg);
begin
  FConsensus.Init(ParaCfg);
end;

procedure TConsensusImpl.Start;
begin
  FConsensus.Start;
end;

procedure TConsensusImpl.Stop;
begin
  FConsensus.Stop;
end;

function TConsensusImpl.API: IAPIReader;
begin
  Result := FConsensus.API;
end;

function TConsensusImpl.SBPReader: ISBPStatReader;
begin
  Result := FConsensus.SBPReader;
end;

end.
