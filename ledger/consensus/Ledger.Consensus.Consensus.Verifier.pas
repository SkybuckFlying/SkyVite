unit Ledger.Consensus.ConsensusVerifier;

interface

uses
  Common.Types,
  Interfaces,
  Interfaces.Core,
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
  System.Generics.Collections,
  System.SysUtils;

type
  TVirtualVerifier = class(TInterfacedObject, IConsensusVerifier)
  public
    function VerifyAccountProducer(ParaBlock: IAccountBlock): TTuple<Boolean, Exception>;
    function VerifyABsProducer(const ParaAbs: TDictionary<TGid, TArray<IAccountBlock>>): TTuple<TArray<IAccountBlock>, Exception>;
    function VerifySnapshotProducer(ParaBlock: ISnapshotBlock): TTuple<Boolean, Exception>;
  end;

function NewVirtualVerifier: IConsensusVerifier;

implementation

{ TVirtualVerifier }

function TVirtualVerifier.VerifyAccountProducer(ParaBlock: IAccountBlock): TTuple<Boolean, Exception>;
begin
  Result := TTuple<Boolean, Exception>.Create(True, nil);
end;

function TVirtualVerifier.VerifyABsProducer(const ParaAbs: TDictionary<TGid, TArray<IAccountBlock>>): TTuple<TArray<IAccountBlock>, Exception>;
var
  vResultList: TArray<IAccountBlock>;
  vV: TArray<IAccountBlock>;
begin
  SetLength(vResultList, 0);
  for vV in ParaAbs.Values do
  begin
    vResultList := Concat(vResultList, vV);
  end;
  Result := TTuple<TArray<IAccountBlock>, Exception>.Create(vResultList, nil);
end;

function TVirtualVerifier.VerifySnapshotProducer(ParaBlock: ISnapshotBlock): TTuple<Boolean, Exception>;
begin
  Result := TTuple<Boolean, Exception>.Create(True, nil);
end;

function NewVirtualVerifier: IConsensusVerifier;
begin
  Result := TVirtualVerifier.Create;
end;

end.
