unit Ledger.Consensus.Result;

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
  Ledger.Consensus.Core,
  Ledger.Consensus.Dpos,
  Ledger.Consensus.Mock.Ch,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  System.Classes,
  System.SysUtils;

type
  IElectionResult = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B46}']
    function GetPlans: TArray<IMemberPlan>;
    function GetSTime: TDateTime;
    function GetETime: TDateTime;
    function GetIndex: UInt64;
  end;

  TElectionResult = class(TInterfacedObject, IElectionResult)
  private
    FPlans: TArray<IMemberPlan>;
    FSTime: TDateTime;
    FETime: TDateTime;
    FIndex: UInt64;
    function GetPlans: TArray<IMemberPlan>;
    function GetSTime: TDateTime;
    function GetETime: TDateTime;
    function GetIndex: UInt64;
  public
    constructor Create(ParaInfo: IGroupInfo; ParaIndex: UInt64; const ParaMembers: TArray<TAddress>);
  end;

function GenElectionResult(ParaInfo: IGroupInfo; ParaIndex: UInt64; const ParaMembers: TArray<TAddress>): IElectionResult;

implementation

{ TElectionResult }

constructor TElectionResult.Create(ParaInfo: IGroupInfo; ParaIndex: UInt64; const ParaMembers: TArray<TAddress>);
begin
  FSTime, FETime := ParaInfo.Index2Time(ParaIndex);
  FPlans := ParaInfo.GenPlanByAddress(ParaIndex, ParaMembers);
  FIndex := ParaIndex;
end;

function TElectionResult.GetPlans: TArray<IMemberPlan>;
begin
  Result := FPlans;
end;

function TElectionResult.GetSTime: TDateTime;
begin
  Result := FSTime;
end;

function TElectionResult.GetETime: TDateTime;
begin
  Result := FETime;
end;

function TElectionResult.GetIndex: UInt64;
begin
  Result := FIndex;
end;

function GenElectionResult(ParaInfo: IGroupInfo; ParaIndex: UInt64; const ParaMembers: TArray<TAddress>): IElectionResult;
begin
  Result := TElectionResult.Create(ParaInfo, ParaIndex, ParaMembers);
end;

end.
