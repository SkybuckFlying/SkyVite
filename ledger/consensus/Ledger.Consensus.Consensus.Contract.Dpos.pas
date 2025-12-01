unit Ledger.Consensus.ConsensusContractDpos;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  V2.Interfaces.Core,
  Common.Types,
  Ledger.Consensus.Core,
  Ledger.Consensus.ChainRw,
  Log15;

type
  TContractDposCs = class
  private
    mGroupInfo: IGroupInfo;
    mRw: TChainRw;
    mAlgo: IAlgo;
    mLog: ILogger;
    function ElectionAddrsIndex(ParaIndex: TUInt64): TTuple<TArray<TAddress>, ISnapshotBlock, Exception>;
    function CalVotes(ParaBlock: ISnapshotBlock): TTuple<TArray<TAddress>, Exception>;
    function VerifyProducers(const ParaBlocks: TArray<IAccountBlock>; const ParaResult: TDictionary<TAddress, Boolean>): TArray<IAccountBlock>;
    function VerifyProducer(const ParaAddress: TAddress; ParaResult: IElectionResult): Boolean;
  public
    constructor Create(ParaInfo: IGroupInfo; ParaRw: TChainRw; ParaLog: ILogger);
    function GetInfo: IGroupInfo;
    function ElectionTime(ParaT: TDateTime): TTuple<IElectionResult, Exception>;
    function ElectionIndex(ParaIndex: TUInt64): TTuple<IElectionResult, Exception>;
    function GenProofTime(ParaIdx: TUInt64): TDateTime;
    function VerifyAccountsProducer(const ParaAccountBlocks: TArray<IAccountBlock>): TTuple<TArray<IAccountBlock>, Exception>;
    function VerifyAccountProducer(ParaAccountBlock: IAccountBlock): TTuple<Boolean, Exception>;
    function VerifyAccountProducerLevel1(ParaAccBlock: IAccountBlock): TTuple<Boolean, Exception>;
    function VerifyProducer(const ParaAddress: TAddress; ParaT: TDateTime): TTuple<Boolean, Exception>;
  end;

implementation

uses
  System.DateUtils;

{ TContractDposCs }

constructor TContractDposCs.Create(ParaInfo: IGroupInfo; ParaRw: TChainRw; ParaLog: ILogger);
begin
  mRw := ParaRw;
  mGroupInfo := ParaInfo;
  mAlgo := TAlgo.Create(ParaInfo);
  mLog := ParaLog.New('gid', Format('contract-%s', [ParaInfo.Gid.ToString]));
end;

function TContractDposCs.GetInfo: IGroupInfo;
begin
  Result := mGroupInfo;
end;

function TContractDposCs.ElectionTime(ParaT: TDateTime): TTuple<IElectionResult, Exception>;
var
  vIndex: TUInt64;
begin
  vIndex := mGroupInfo.Time2Index(ParaT);
  Result := ElectionIndex(vIndex);
end;

function TContractDposCs.ElectionIndex(ParaIndex: TUInt64): TTuple<IElectionResult, Exception>;
var
  vVoteResults: TArray<TAddress>;
  vSnapshotBlock: ISnapshotBlock;
  vErr: Exception;
begin
  TValue.Make(ElectionAddrsIndex(ParaIndex), vVoteResults, vSnapshotBlock, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<IElectionResult, Exception>.Create(nil, vErr));
  end;
  Result := TTuple<IElectionResult, Exception>.Create(GenElectionResult(mGroupInfo, ParaIndex, vVoteResults), nil);
end;

function TContractDposCs.ElectionAddrsIndex(ParaIndex: TUInt64): TTuple<TArray<TAddress>, ISnapshotBlock, Exception>;
var
  vSTime: TDateTime;
  vBlock: ISnapshotBlock;
  vVoteResults: TArray<TAddress>;
  vErr: Exception;
begin
  vSTime := GenProofTime(ParaIndex);
  vBlock := mRw.GetSnapshotBeforeTime(vSTime, vErr);
  if vErr <> nil then
  begin
    mLog.Error('geSnapshotBeferTime fail.', 'err', vErr.Message);
    Exit(TTuple<TArray<TAddress>, ISnapshotBlock, Exception>.Create(nil, nil, vErr));
  end;

  TValue.Make(CalVotes(vBlock), vVoteResults, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TArray<TAddress>, ISnapshotBlock, Exception>.Create(nil, nil, vErr));
  end;
  Result := TTuple<TArray<TAddress>, ISnapshotBlock, Exception>.Create(vVoteResults, vBlock, nil);
end;

function TContractDposCs.CalVotes(ParaBlock: ISnapshotBlock): TTuple<TArray<TAddress>, Exception>;
var
  vR: TArray<TAddress>;
  vOk: Boolean;
  vHashH: IHashHeight;
  vVotes: TArray<IVote>;
  vRandomSeed: TUInt64;
  vSeed: ISeedInfo;
  vContext: IVoteAlgoContext;
  vFinalVotes: TArray<IVote>;
  vAddress: TArray<TAddress>;
  vErr: Exception;
begin
  TValue.Make(mRw.GetVoteLRUCache(mGroupInfo.Gid, ParaBlock.Hash), vR, vOk);
  if vOk then
  begin
    Exit(TTuple<TArray<TAddress>, Exception>.Create(vR, nil));
  end;

  vHashH := THashHeight.Create(ParaBlock.Hash, ParaBlock.Height);
  TValue.Make(mRw.CalVotes(mGroupInfo, vHashH), vVotes, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TArray<TAddress>, Exception>.Create(nil, vErr));
  end;

  vRandomSeed := mRw.GetSeedsBeforeHashH(ParaBlock.Hash);
  vSeed := TSeedInfo.Create(vRandomSeed);

  vContext := TVoteAlgoContext.Create(vVotes, vHashH, nil, vSeed);
  vFinalVotes := mAlgo.FilterVotes(vContext);
  vFinalVotes := mAlgo.ShuffleVotes(vFinalVotes, vHashH, vSeed);

  vAddress := TConsensusCore.ConvertVoteToAddress(vFinalVotes);

  mRw.UpdateVoteLRUCache(mGroupInfo.Gid, vHashH.Hash, vAddress);
  Result := TTuple<TArray<TAddress>, Exception>.Create(vAddress, nil);
end;

function TContractDposCs.GenProofTime(ParaIdx: TUInt64): TDateTime;
var
  vSTime: TDateTime;
begin
  vSTime := mGroupInfo.Index2Time(ParaIdx);
  vSTime := IncSecond(vSTime, -75);
  if vSTime < mGroupInfo.GenesisTime then
  begin
    Result := IncSecond(mGroupInfo.GenesisTime, 1);
  end
  else
  begin
    Result := vSTime;
  end;
end;

function TContractDposCs.VerifyAccountsProducer(const ParaAccountBlocks: TArray<IAccountBlock>): TTuple<TArray<IAccountBlock>, Exception>;
var
  vHead: ISnapshotBlock;
  vIndex: TUInt64;
  vResultList: TArray<TAddress>;
  vSnapshotBlock: ISnapshotBlock;
  vResultM: TDictionary<TAddress, Boolean>;
  vV: TAddress;
  vErr: Exception;
begin
  vHead := mRw.GetLatestSnapshotBlock;
  vIndex := mGroupInfo.Time2Index(vHead.Timestamp);
  TValue.Make(ElectionAddrsIndex(vIndex), vResultList, vSnapshotBlock, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TArray<IAccountBlock>, Exception>.Create(nil, vErr));
  end;
  vResultM := TDictionary<TAddress, Boolean>.Create;
  for vV in vResultList do
  begin
    vResultM.Add(vV, True);
  end;
  Result := TTuple<TArray<IAccountBlock>, Exception>.Create(VerifyProducers(ParaAccountBlocks, vResultM), nil);
end;

function TContractDposCs.VerifyProducers(const ParaBlocks: TArray<IAccountBlock>; const ParaResult: TDictionary<TAddress, Boolean>): TArray<IAccountBlock>;
var
  vInValid: TArray<IAccountBlock>;
  vV: IAccountBlock;
begin
  SetLength(vInValid, 0);
  for vV in ParaBlocks do
  begin
    if not ParaResult.ContainsKey(vV.Producer) then
    begin
      vInValid := Concat(vInValid, [vV]);
    end;
  end;
  Result := vInValid;
end;

function TContractDposCs.VerifyAccountProducer(ParaAccountBlock: IAccountBlock): TTuple<Boolean, Exception>;
var
  vHead: ISnapshotBlock;
  vElectionResult: IElectionResult;
  vErr: Exception;
begin
  if mGroupInfo.CheckLevel = 1 then
  begin
    Exit(VerifyAccountProducerLevel1(ParaAccountBlock));
  end;
  vHead := mRw.GetLatestSnapshotBlock;
  TValue.Make(ElectionTime(vHead.Timestamp), vElectionResult, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<Boolean, Exception>.Create(false, vErr));
  end;
  Result := TTuple<Boolean, Exception>.Create(VerifyProducer(ParaAccountBlock.Producer, vElectionResult), nil);
end;

function TContractDposCs.VerifyAccountProducerLevel1(ParaAccBlock: IAccountBlock): TTuple<Boolean, Exception>;
var
  vHead: ISnapshotBlock;
  vIndex: TUInt64;
  vAddrs: TArray<TAddress>;
  vSnapshotBlock: ISnapshotBlock;
  vV: TAddress;
  vErr: Exception;
begin
  vHead := mRw.GetLatestSnapshotBlock;
  vIndex := mGroupInfo.Time2Index(vHead.Timestamp);
  TValue.Make(ElectionAddrsIndex(vIndex), vAddrs, vSnapshotBlock, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<Boolean, Exception>.Create(false, vErr));
  end;
  for vV in vAddrs do
  begin
    if vV = ParaAccBlock.Producer then
    begin
      Exit(TTuple<Boolean, Exception>.Create(true, nil));
    end;
  end;
  Result := TTuple<Boolean, Exception>.Create(false, nil);
end;

function TContractDposCs.VerifyProducer(const ParaAddress: TAddress; ParaT: TDateTime): TTuple<Boolean, Exception>;
var
  vElectionResult: IElectionResult;
  vErr: Exception;
begin
  TValue.Make(ElectionTime(ParaT), vElectionResult, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<Boolean, Exception>.Create(false, vErr));
  end;
  Result := TTuple<Boolean, Exception>.Create(VerifyProducer(ParaAddress, vElectionResult), nil);
end;

function TContractDposCs.VerifyProducer(const ParaAddress: TAddress; ParaResult: IElectionResult): Boolean;
var
  vPlan: IPlan;
begin
  if ParaResult = nil then
  begin
    Exit(False);
  end;

  for vPlan in ParaResult.Plans do
  begin
    if vPlan.Member = ParaAddress then
    begin
      if mGroupInfo.CheckLevel = 1 then
      begin
        Exit(True);
      end;
    end;
  end;
  Result := False;
end;

end.