unit Ledger.Consensus.ConsensusSnapshot;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  System.DateUtils,
  Common.Types,
  Interfaces.Core,
  Ledger.Consensus.CDB,
  Ledger.Consensus.Core,
  Ledger.Consensus.ChainRw,
  Log15;

type
  TSnapshotCs = class
  private
    mGroupInfo: IGroupInfo;
    mRw: TChainRw;
    mAlgo: IAlgo;
    mLog: ILogger;
    function GetBaseStats(const ParaGenesisHash: THash; ParaArray: ILinkedArray; ParaStartIndex, ParaEndIndex: UInt64): TArray<IBaseStats>;
    function DayVoteStat(ParaB: Byte; ParaIndex: UInt64; const ParaProofHash: THash): IVoteContent;
    function GenSnapshotProofTimeIndx(ParaIdx: UInt64): TTuple<TDateTime, UInt64>;
    function VerifyProducerInternal(ParaT: TDateTime; const ParaAddress: TAddress; ParaResult: IElectionResult): Boolean;
  public
    constructor Create(ParaRw: TChainRw; ParaLog: ILogger);
    function GetSuccessRateByHour(ParaIndex: UInt64): TDictionary<TAddress, Single>;
    function GetInfo: IGroupInfo;
    function HourStats(ParaStartIndex, ParaEndIndex: UInt64): TArray<IHourStats>;
    function GetHourTimeIndex: ITimeIndex;
    function PeriodStats(ParaStartIndex, ParaEndIndex: UInt64): TArray<IPeriodStats>;
    function GetNodeCount: Integer;
    function GetPeriodTimeIndex: ITimeIndex;
    function GetDayTimeIndex: ITimeIndex;
    function DayStats(ParaStartIndex, ParaEndIndex: UInt64): TArray<IDayStats>;
    function ElectionTime(ParaT: TDateTime): IElectionResult;
    function ElectionIndex(ParaIndex: UInt64): IElectionResult;
    function CalVotes(ParaProofBlock: ISnapshotBlock; ParaIndex: UInt64): TArray<TAddress>;
    procedure TriggerLoad(ParaProofBlock: ISnapshotBlock);
    function LoadVotes(ParaProofBlock: ISnapshotBlock): TArray<TAddress>;
    function GenProofTime(ParaIdx: UInt64): TDateTime;
    function VoteDetailsBeforeTime(ParaT: TDateTime): TTuple<TArray<IVoteDetails>, IHashHeight>;
    function VerifySnapshotProducer(ParaHeader: ISnapshotBlock): Boolean;
    function VerifyProducer(const ParaAddress: TAddress; ParaT: TDateTime): Boolean;
    function VerifyProducerAndSeed(ParaBlock: ISnapshotBlock): Boolean;
  end;

implementation

{ TSnapshotCs }

constructor TSnapshotCs.Create(ParaRw: TChainRw; ParaLog: ILogger);
var
  vInfo: IGroupInfo;
begin
  mRw := ParaRw;
  mLog := ParaLog.New('gid', 'snapshot');
  try
    vInfo := ParaRw.GetMemberInfo(SNAPSHOT_GID);
    mAlgo := TAlgo.Create(vInfo);
    mGroupInfo := vInfo;
  except
    on E: Exception do
      raise;
  end;
end;

function TSnapshotCs.GetSuccessRateByHour(ParaIndex: UInt64): TDictionary<TAddress, Single>;
begin
  Result := mRw.GetSuccessRateByHour(ParaIndex);
end;

function TSnapshotCs.GetInfo: IGroupInfo;
begin
  Result := mGroupInfo;
end;

function TSnapshotCs.HourStats(ParaStartIndex, ParaEndIndex: UInt64): TArray<IHourStats>;
var
  vGenesis: ISnapshotBlock;
  vStats: TArray<IBaseStats>;
  vResultList: TArray<IHourStats>;
  vK: Integer;
  vV: IBaseStats;
begin
  vGenesis := mRw.Rw.GetGenesisSnapshotBlock;
  try
    vStats := GetBaseStats(vGenesis.Hash, mRw.HourPoints, ParaStartIndex, ParaEndIndex);
  except
    on E: Exception do
      raise;
  end;

  SetLength(vResultList, Length(vStats));
  for vK := 0 to High(vStats) do
  begin
    vV := vStats[vK];
    vResultList[vK] := THourStats.Create(vV);
  end;
  Result := vResultList;
end;

function TSnapshotCs.GetHourTimeIndex: ITimeIndex;
begin
  Result := mRw.HourPoints;
end;

function TSnapshotCs.PeriodStats(ParaStartIndex, ParaEndIndex: UInt64): TArray<IPeriodStats>;
var
  vGenesis: ISnapshotBlock;
  vStats: TArray<IBaseStats>;
  vResultList: TArray<IPeriodStats>;
  vK: Integer;
  vV: IBaseStats;
begin
  vGenesis := mRw.Rw.GetGenesisSnapshotBlock;
  try
    vStats := GetBaseStats(vGenesis.Hash, mRw.PeriodPoints, ParaStartIndex, ParaEndIndex);
  except
    on E: Exception do
      raise;
  end;

  SetLength(vResultList, Length(vStats));
  for vK := 0 to High(vStats) do
  begin
    vV := vStats[vK];
    vResultList[vK] := TPeriodStats.Create(vV);
  end;
  Result := vResultList;
end;

function TSnapshotCs.GetNodeCount: Integer;
begin
  Result := mGroupInfo.NodeCount;
end;

function TSnapshotCs.GetPeriodTimeIndex: ITimeIndex;
begin
  Result := mRw.PeriodPoints;
end;

function TSnapshotCs.GetBaseStats(const ParaGenesisHash: THash; ParaArray: ILinkedArray; ParaStartIndex, ParaEndIndex: UInt64): TArray<IBaseStats>;
var
  vPoints: TDictionary<UInt64, IPoint>;
  vProofHash: THash;
  vI: UInt64;
  vPoint: IPoint;
  vResultList: TArray<IBaseStats>;
  vP: IPoint;
  vStats: IBaseStats;
  vK: TAddress;
  vV: IContent;
  vSbp: ISbpStats;
begin
  vPoints := TDictionary<UInt64, IPoint>.Create;
  vProofHash := nil;
  for vI := ParaEndIndex downto ParaStartIndex do
  begin
    if (vProofHash <> nil) and (vProofHash = ParaGenesisHash) then
    begin
      Break;
    end;
    try
      if vProofHash = nil then
      begin
        vPoint := ParaArray.GetByIndex(vI)
      end
      else
      begin
        vPoint := ParaArray.GetByIndexWithProof(vI, vProofHash);
      end;
    except
      on E: Exception do
        raise;
    end;

    if vPoint.IsEmpty then
    begin
      Continue;
    end;
    vPoints.Add(vI, vPoint);
    vProofHash := vPoint.PrevHash;
  end;

  if vPoints.Count = 0 then
  begin
    Exit(nil);
  end;

  SetLength(vResultList, 0);
  for vI := ParaStartIndex to ParaEndIndex do
  begin
    if not vPoints.TryGetValue(vI, vP) or vP.IsEmpty then
    begin
      Continue;
    end;

    vStats := TBaseStats.Create(TDictionary<TAddress, ISbpStats>.Create, vI);
    for vK in vP.Sbps.Keys do
    begin
      vV := vP.Sbps[vK];
      vSbp := TSbpStats.Create(vI, vV.FactualNum, vV.ExpectedNum);
      vStats.Stats.Add(vK, vSbp);
    end;
    vResultList := Concat(vResultList, [vStats]);
  end;
  Result := vResultList;
end;

function TSnapshotCs.GetDayTimeIndex: ITimeIndex;
begin
  Result := mRw.DayPoints;
end;

function TSnapshotCs.DayStats(ParaStartIndex, ParaEndIndex: UInt64): TArray<IDayStats>;
var
  vPoints: TDictionary<UInt64, IPoint>;
  vProofHash: THash;
  vI: UInt64;
  vPoint: IPoint;
  vResultList: TArray<IDayStats>;
  vRegisterMap: TDictionary<TAddress, string>;
  vLastHash: THash;
  vRegisters: TArray<IRegistration>;
  vV: IRegistration;
  vVV: TAddress;
  vP: IPoint;
  vStats: IDayStats;
  vK: string;
  vVote: TBigInteger;
  vSbp: ISbpStats;
  vAddr: TAddress;
  vContent: IContent;
  vName: string;
begin
  vPoints := TDictionary<UInt64, IPoint>.Create;
  vProofHash := nil;
  for vI := ParaEndIndex downto ParaStartIndex do
  begin
    try
      if vProofHash = nil then
      begin
        vPoint := mRw.DayPoints.GetByIndex(vI)
      end
      else
      begin
        vPoint := mRw.DayPoints.GetByIndexWithProof(vI, vProofHash);
      end;
    except
      on E: Exception do
        raise;
    end;

    if vPoint.IsEmpty then
    begin
      Continue;
    end;
    vPoints.Add(vI, vPoint);
    vProofHash := vPoint.PrevHash;
  end;

  if vPoints.Count = 0 then
  begin
    Exit(nil);
  end;

  SetLength(vResultList, 0);
  vRegisterMap := TDictionary<TAddress, string>.Create;
  vLastHash := mRw.GetLatestSnapshotBlock.Hash;
  try
    vRegisters := mRw.Rw.GetAllRegisterList(vLastHash, SNAPSHOT_GID);
  except
    on E: Exception do
      raise;
  end;
  for vV in vRegisters do
  begin
    for vVV in vV.HisAddrList do
    begin
      vRegisterMap.Add(vVV, vV.Name);
    end;
  end;

  for vI := ParaStartIndex to ParaEndIndex do
  begin
    if not vPoints.TryGetValue(vI, vP) or vP.IsEmpty or (vP.Votes = nil) then
    begin
      Continue;
    end;

    vStats := TDayStats.Create(TDictionary<string, ISbpStats>.Create, vI, TBigInt.Create(vP.Votes.Total));
    for vK in vP.Votes.Details.Keys do
    begin
      vVote := vP.Votes.Details[vK];
      vStats.Stats.Add(vK, TSbpStats.Create(vI, TBigInt.Create(vVote), vK));
    end;

    for vAddr in vP.Sbps.Keys do
    begin
      vContent := vP.Sbps[vAddr];
      vName := vRegisterMap[vAddr];
      if vStats.Stats.TryGetValue(vName, vSbp) then
      begin
        vSbp.BlockNum := vSbp.BlockNum + vContent.FactualNum;
        vSbp.ExceptedBlockNum := vSbp.ExceptedBlockNum + vContent.ExpectedNum;
      end;
      vStats.BlockTotal := vStats.BlockTotal + vContent.FactualNum;
    end;
    vResultList := Concat(vResultList, [vStats]);
  end;
  Result := vResultList;
end;

function TSnapshotCs.DayVoteStat(ParaB: Byte; ParaIndex: UInt64; const ParaProofHash: THash): IVoteContent;
var
  vVotes: TArray<IVote>;
  vTotal: TBigInteger;
  vDetails: TDictionary<string, TBigInteger>;
  vK: Integer;
  vV: IVote;
begin
  try
    vVotes := CalVotes(mGroupInfo, ParaProofHash, mRw.Rw);
    TArray.Sort<IVote>(vVotes, TComparer<IVote>.Construct(
      function(const Left, Right: IVote): Integer
      begin
        Result := Right.Balance.CompareTo(Left.Balance);
      end));

    vTotal := TBigInteger.Zero;
    vDetails := TDictionary<string, TBigInteger>.Create;
    for vK := 0 to High(vVotes) do
    begin
      vV := vVotes[vK];
      if vK >= mGroupInfo.RandRank then
      begin
        Break;
      end;
      vDetails.Add(vV.Name, vV.Balance);
      vTotal := vTotal + vV.Balance;
    end;
    Result := TVoteContent.Create(vDetails, vTotal);
  except
    on E: Exception do
      raise;
  end;
end;

function TSnapshotCs.ElectionTime(ParaT: TDateTime): IElectionResult;
var
  vIndex: UInt64;
begin
  vIndex := mGroupInfo.Time2Index(ParaT);
  Result := ElectionIndex(vIndex);
end;

function TSnapshotCs.ElectionIndex(ParaIndex: UInt64): IElectionResult;
var
  vProofTime: TDateTime;
  vProofIndex: UInt64;
  vProofBlock: ISnapshotBlock;
  vVoteResults: TArray<TAddress>;
begin
  TValue.Make(GenSnapshotProofTimeIndx(ParaIndex), vProofTime, vProofIndex);
  try
    vProofBlock := mRw.GetSnapshotBeforeTime(vProofTime);
  except
    on E: Exception do
    begin
      mLog.Error('geSnapshotBeferTime fail.', 'err', E.Message);
      raise;
    end;
  end;

  mLog.Debug(Format('election index:%d,%s, proofTime:%s', [ParaIndex, vProofBlock.Hash.ToString, DateTimeToStr(vProofTime)]));

  try
    vVoteResults := CalVotes(vProofBlock, ParaIndex);
  except
    on E: Exception do
      raise;
  end;

  Result := GenElectionResult(mGroupInfo, ParaIndex, vVoteResults);
end;

function TSnapshotCs.CalVotes(ParaProofBlock: ISnapshotBlock; ParaIndex: UInt64): TArray<TAddress>;
var
  vHashH: IHashHeight;
  vR: TArray<TAddress>;
  vSeed: ISeedInfo;
  vVotes: TArray<IVote>;
  vSuccessRate: TDictionary<TAddress, Single>;
  vProofIndex: UInt64;
  vAll: string;
  vV: IVote;
  vContext: IVoteAlgoContext;
  vFinalVotes: TArray<IVote>;
  vResultStr: string;
  vAddress: TArray<TAddress>;
begin
  vHashH := THashHeight.Create(ParaProofBlock.Hash, ParaProofBlock.Height);
  vR := mRw.GetSnapshotVoteCache(vHashH.Hash);
  if vR <> nil then
  begin
    Exit(vR);
  end;

  vSeed := TSeedInfo.Create(mRw.GetSeedsBeforeHashH(vHashH.Hash));
  try
    vVotes := mRw.CalVotes(mGroupInfo, vHashH);
  except
    on E: Exception do
      raise;
  end;

  vSuccessRate := nil;
  TValue.Make(GenSnapshotProofTimeIndx(mGroupInfo.Time2Index(ParaProofBlock.Timestamp)), vProofIndex);
  if vProofIndex > 0 then
  begin
    try
      vSuccessRate := mRw.GetSuccessRateByHour(vProofIndex);
    except
      on E: Exception do
        raise;
    end;
  end;

  vAll := '';
  for vV in vVotes do
  begin
    vAll := vAll + Format('[%s-%s]', [vV.Name, vV.Balance.ToString]);
  end;
  mLog.Info(Format('[%d][%d]pre success rate log: %s, %s, seed:%d', [vHashH.Height, ParaIndex, vSuccessRate.ToString, vAll, vSeed.Seed]));

  vContext := TVoteAlgoContext.Create(vVotes, vHashH, vSuccessRate, vSeed);
  vFinalVotes := mAlgo.FilterVotes(vContext);
  vFinalVotes := mAlgo.ShuffleVotes(vFinalVotes, vHashH, vSeed);

  vResultStr := Format('CalVotes result: %d:%d:%s, ', [ParaIndex, vHashH.Height, vHashH.Hash.ToString]);
  for vV in vFinalVotes do
  begin
    if Length(vV.Type) > 0 then
    begin
      vResultStr := vResultStr + Format('[%s:%s],', [vV.Name, vV.Type])
    end
    else
    begin
      vResultStr := vResultStr + Format('[%s],', [vV.Name]);
    end;
  end;
  mLog.Info(vResultStr);
  vAddress := ConvertVoteToAddress(vFinalVotes);

  mRw.UpdateSnapshotVoteCache(vHashH.Hash, vAddress);
  Result := vAddress;
end;

procedure TSnapshotCs.TriggerLoad(ParaProofBlock: ISnapshotBlock);
begin
  mRw.SnapshotLoadCh.TrySend(ParaProofBlock);
end;

function TSnapshotCs.LoadVotes(ParaProofBlock: ISnapshotBlock): TArray<TAddress>;
var
  vHashH: IHashHeight;
  vR: TArray<TAddress>;
  vSeed: ISeedInfo;
  vVotes: TArray<IVote>;
  vSuccessRate: TDictionary<TAddress, Single>;
  vProofIndex: UInt64;
  vAll: string;
  vV: IVote;
  vContext: IVoteAlgoContext;
  vFinalVotes: TArray<IVote>;
  vResultStr: string;
  vAddress: TArray<TAddress>;
begin
  mLog.Info('loadVotes ', 'hash', ParaProofBlock.Hash, 'height', ParaProofBlock.Height);
  vHashH := THashHeight.Create(ParaProofBlock.Hash, ParaProofBlock.Height);
  vR := mRw.GetVoteLRUCache(SNAPSHOT_GID, vHashH.Hash);
  if vR <> nil then
  begin
    Exit(vR);
  end;

  vSeed := TSeedInfo.Create(mRw.GetSeedsBeforeHashH(vHashH.Hash));
  try
    vVotes := mRw.CalVotes(mGroupInfo, vHashH);
  except
    on E: Exception do
      raise;
  end;

  vSuccessRate := nil;
  TValue.Make(GenSnapshotProofTimeIndx(mGroupInfo.Time2Index(ParaProofBlock.Timestamp)), vProofIndex);
  if vProofIndex > 0 then
  begin
    try
      vSuccessRate := mRw.GetSuccessRateByHour(vProofIndex);
    except
      on E: Exception do
        raise;
    end;
  end;

  vAll := '';
  for vV in vVotes do
  begin
    vAll := vAll + Format('[%s-%s]', [vV.Name, vV.Balance.ToString]);
  end;
  mLog.Info(Format('[load][%d][%d]pre success rate log: %s, %s, seed:%d', [vHashH.Height, vHashH.Hash.ToString, vSuccessRate.ToString, vAll, vSeed.Seed]));

  vContext := TVoteAlgoContext.Create(vVotes, vHashH, vSuccessRate, vSeed);
  vFinalVotes := mAlgo.FilterVotes(vContext);
  vFinalVotes := mAlgo.ShuffleVotes(vFinalVotes, vHashH, vSeed);

  vResultStr := Format('[loadpw]CalVotes result: %d:%s, ', [vHashH.Height, vHashH.Hash.ToString]);
  for vV in vFinalVotes do
  begin
    if Length(vV.Type) > 0 then
    begin
      vResultStr := vResultStr + Format('[%s:%s],', [vV.Name, vV.Type])
    end
    else
    begin
      vResultStr := vResultStr + Format('[%s],', [vV.Name]);
    end;
  end;
  mLog.Info(vResultStr);
  vAddress := ConvertVoteToAddress(vFinalVotes);

  mRw.UpdateVoteLRUCache(SNAPSHOT_GID, vHashH.Hash, vAddress);
  Result := vAddress;
end;

function TSnapshotCs.GenProofTime(ParaIdx: UInt64): TDateTime;
var
  vT: TDateTime;
  vProofIndex: UInt64;
begin
  TValue.Make(GenSnapshotProofTimeIndx(ParaIdx), vT, vProofIndex);
  Result := vT;
end;

function TSnapshotCs.GenSnapshotProofTimeIndx(ParaIdx: UInt64): TTuple<TDateTime, UInt64>;
var
  vSt, vEt: TDateTime;
begin
  if ParaIdx < 2 then
  begin
    Result := TTuple<TDateTime, UInt64>.Create(IncSecond(mGroupInfo.GenesisTime, 1), 0)
  end
  else
  begin
    vSt, vEt := mGroupInfo.Index2Time(ParaIdx - 2);
    Result := TTuple<TDateTime, UInt64>.Create(vEt, ParaIdx - 2);
  end;
end;

function TSnapshotCs.VoteDetailsBeforeTime(ParaT: TDateTime): TTuple<TArray<IVoteDetails>, IHashHeight>;
var
  vBlock: ISnapshotBlock;
  vHeadH: IHashHeight;
  vDetails: TArray<IVoteDetails>;
begin
  try
    vBlock := mRw.GetSnapshotBeforeTime(ParaT);
  except
    on E: Exception do
    begin
      mLog.Error('geSnapshotBeferTime fail.', 'err', E.Message);
      raise;
    end;
  end;

  vHeadH := THashHeight.Create(vBlock.Hash, vBlock.Height);
  try
    vDetails := mRw.CalVoteDetails(mGroupInfo.Gid, mGroupInfo, vHeadH);
    Result := TTuple<TArray<IVoteDetails>, IHashHeight>.Create(vDetails, vHeadH);
  except
    on E: Exception do
      raise;
  end;
end;

function TSnapshotCs.VerifySnapshotProducer(ParaHeader: ISnapshotBlock): Boolean;
var
  vElectionResult: IElectionResult;
begin
  try
    vElectionResult := ElectionTime(ParaHeader.Timestamp);
    Result := VerifyProducerInternal(ParaHeader.Timestamp, ParaHeader.Producer, vElectionResult);
  except
    on E: Exception do
      raise;
  end;
end;

function TSnapshotCs.VerifyProducer(const ParaAddress: TAddress; ParaT: TDateTime): Boolean;
var
  vElectionResult: IElectionResult;
begin
  try
    vElectionResult := ElectionTime(ParaT);
    Result := VerifyProducerInternal(ParaT, ParaAddress, vElectionResult);
  except
    on E: Exception do
      raise;
  end;
end;

function TSnapshotCs.VerifyProducerInternal(ParaT: TDateTime; const ParaAddress: TAddress; ParaResult: IElectionResult): Boolean;
var
  vPlan: IMemberPlan;
begin
  if ParaResult = nil then
  begin
    Exit(False);
  end;
  for vPlan in ParaResult.Plans do
  begin
    if (vPlan.Member = ParaAddress) and (vPlan.STime = ParaT) then
    begin
      Exit(True);
    end;
  end;
  Result := False;
end;

function TSnapshotCs.VerifyProducerAndSeed(ParaBlock: ISnapshotBlock): Boolean;
var
  vProducerTime: TDateTime;
  vElectionResult: IElectionResult;
  vSeedBlock: ISnapshotBlock;
  vHash: THash;
begin
  vProducerTime := ParaBlock.Timestamp;
  try
    vElectionResult := ElectionTime(vProducerTime);
    Result := VerifyProducerInternal(vProducerTime, ParaBlock.Producer, vElectionResult);
    if not Result then
    begin
      Exit;
    end;

    if ParaBlock.Seed <> 0 then
    begin
      vSeedBlock := mRw.Rw.GetLastUnpublishedSeedSnapshotHeader(ParaBlock.Producer, vElectionResult.STime);
      if vSeedBlock = nil then
      begin
        raise Exception.Create('get last seed snapshot header nil.');
      end;
      vHash := ComputeSeedHash(ParaBlock.Seed, vSeedBlock.PrevHash, vSeedBlock.Timestamp);
      if vHash <> vSeedBlock.SeedHash then
      begin
        raise Exception.Create(Format('seed verify fail. %s-%d', [vSeedBlock.Hash.ToString, vSeedBlock.Height]));
      end;
    end;
  except
    on E: Exception do
      raise;
  end;
end;

end.