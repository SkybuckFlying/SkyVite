unit Ledger.Consensus.Dpos;

interface

uses
  System.SysUtils,
  System.Classes,
  Common.Types,
  Ledger.Consensus.Core,
  Ledger.Consensus.ConsensusContract,
  Log15;

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