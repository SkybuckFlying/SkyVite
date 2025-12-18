unit Ledger.Consensus.Dpos;

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
  Ledger.Consensus.ConsensusContract,
  Ledger.Consensus.Core,
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
  Log15,
  System.Classes,
  System.SysUtils;

type
  IDposReader = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B44}']
    function ElectionIndex(ParaIndex: UInt64): TTuple<IElectionResult, Exception>;
    function GetInfo: IGroupInfo;
    function Time2Index(ParaT: TDateTime): UInt64;
    function Index2Time(ParaI: UInt64): TTuple<TDateTime, TDateTime>;
    function GenProofTime(ParaT: UInt64): TDateTime;
    function VerifyProducer(const ParaAddress: TAddress; ParaT: TDateTime): TTuple<Boolean, Exception>;
  end;

  IDposVerifier = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B45}']
  end;

  TdposReader = class
  private
    FSnapshot: IDposReader;
    FContracts: TContractsCs;
    FLog: ILogger;
  public
    constructor Create(ParaSnapshot: IDposReader; ParaContracts: TContractsCs; ParaLog: ILogger);
    function GetDposConsensus(const ParaGid: TGid): TTuple<IDposReader, Exception>;
  end;

implementation

{ TdposReader }

constructor TdposReader.Create(ParaSnapshot: IDposReader; ParaContracts: TContractsCs; ParaLog: ILogger);
begin
  FSnapshot := ParaSnapshot;
  FContracts := ParaContracts;
  FLog := ParaLog;
end;

function TdposReader.GetDposConsensus(const ParaGid: TGid): TTuple<IDposReader, Exception>;
begin
  if ParaGid = SNAPSHOT_GID then
    Result := TTuple<IDposReader, Exception>.Create(FSnapshot, nil)
  else
    Result := FContracts.GetOrLoadGid(ParaGid);
end;

end.
