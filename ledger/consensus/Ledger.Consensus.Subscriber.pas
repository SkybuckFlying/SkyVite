unit Ledger.Consensus.Subscriber;

interface

uses
  Common.Types,
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
  Ledger.Consensus.Event,
  Ledger.Consensus.Mock.Ch,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  TSubscribeEventFunc = reference to procedure(ParaEvent: TSubscribeEvent);
  TProducerSubscribeEventFunc = reference to procedure(ParaEvent: TProducerSubscribeEvent);

  ISubscribeTrigger = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B47}']
    procedure TriggerEvent(const ParaGid: TGid; ParaFn: TSubscribeEventFunc);
    procedure TriggerProducerEvent(const ParaGid: TGid; ParaFn: TProducerSubscribeEventFunc);
  end;

  TConsensusSubscriber = class(TInterfacedObject, ISubscriber, ISubscribeTrigger)
  private
    FFirstSub: TDictionary<string, TObject>;
    FSecondSub: TDictionary<string, TObject>;
    function Selected(const ParaGid: TGid): TDictionary<string, TObject>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Subscribe(const ParaGid: TGid; const ParaId: string; const ParaAddr: TAddress; ParaFn: TEventFunc);
    procedure UnSubscribe(const ParaGid: TGid; const ParaId: string);
    procedure SubscribeProducers(const ParaGid: TGid; const ParaId: string; ParaFn: TProducersEventFunc);
    procedure TriggerEvent(const ParaGid: TGid; ParaFn: TSubscribeEventFunc);
    procedure TriggerProducerEvent(const ParaGid: TGid; ParaFn: TProducerSubscribeEventFunc);
    function TriggerMineEvent(const ParaAddr: TAddress): Exception;
  end;

function NewConsensusSubscriber: TConsensusSubscriber;

implementation

{ TConsensusSubscriber }

constructor TConsensusSubscriber.Create;
begin
  FFirstSub := TDictionary<string, TObject>.Create;
  FSecondSub := TDictionary<string, TObject>.Create;
end;

destructor TConsensusSubscriber.Destroy;
begin
  FFirstSub.Free;
  FSecondSub.Free;
  inherited;
end;

function TConsensusSubscriber.Selected(const ParaGid: TGid): TDictionary<string, TObject>;
begin
  if ParaGid = SNAPSHOT_GID then
    Result := FFirstSub
  else if ParaGid = DELEGATE_GID then
    Result := FSecondSub
  else
    Result := nil;
end;

procedure TConsensusSubscriber.Subscribe(const ParaGid: TGid; const ParaId: string; const ParaAddr: TAddress; ParaFn: TEventFunc);
var
  Sub: TDictionary<string, TObject>;
begin
  Sub := Selected(ParaGid);
  if Sub <> nil then
    Sub.AddOrSetValue(ParaId, TSubscribeEvent.Create(ParaAddr, ParaGid, ParaFn));
end;

procedure TConsensusSubscriber.UnSubscribe(const ParaGid: TGid; const ParaId: string);
var
  Sub: TDictionary<string, TObject>;
begin
  Sub := Selected(ParaGid);
  if Sub <> nil then
    Sub.Remove(ParaId);
end;

procedure TConsensusSubscriber.SubscribeProducers(const ParaGid: TGid; const ParaId: string; ParaFn: TProducersEventFunc);
var
  Sub: TDictionary<string, TObject>;
begin
  Sub := Selected(ParaGid);
  if Sub <> nil then
    Sub.AddOrSetValue(ParaId, TProducerSubscribeEvent.Create(ParaGid, ParaFn));
end;

procedure TConsensusSubscriber.TriggerEvent(const ParaGid: TGid; ParaFn: TSubscribeEventFunc);
var
  Sub: TDictionary<string, TObject>;
  V: TObject;
begin
  Sub := Selected(ParaGid);
  if Sub <> nil then
    for V in Sub.Values do
      if V is TSubscribeEvent then
        ParaFn(TSubscribeEvent(V));
end;

procedure TConsensusSubscriber.TriggerProducerEvent(const ParaGid: TGid; ParaFn: TProducerSubscribeEventFunc);
var
  Sub: TDictionary<string, TObject>;
  V: TObject;
begin
  Sub := Selected(ParaGid);
  if Sub <> nil then
    for V in Sub.Values do
      if V is TProducerSubscribeEvent then
        ParaFn(TProducerSubscribeEvent(V));
end;

function TConsensusSubscriber.TriggerMineEvent(const ParaAddr: TAddress): Exception;
begin
  Result := Exception.Create('not supported');
end;

function NewConsensusSubscriber: TConsensusSubscriber;
begin
  Result := TConsensusSubscriber.Create;
end;

end.
