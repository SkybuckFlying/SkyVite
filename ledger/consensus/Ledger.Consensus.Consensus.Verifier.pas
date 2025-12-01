unit Ledger.Consensus.ConsensusVerifier;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Interfaces,
  Interfaces.Core,
  Common.Types;

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