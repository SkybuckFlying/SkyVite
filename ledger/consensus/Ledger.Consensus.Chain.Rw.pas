unit Ledger.Consensus.ChainRw;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  System.SyncObjs,
  Go.leveldb,
  Go.lru,
  V2.Interfaces,
  V2.Interfaces.Core,
  Common.Types,
  Ledger.Consensus.CDB,
  Ledger.Consensus.Core,
  Ledger.Pool.Lock,
  Log15,
  GoToDelphi.Helpers.TChannel;

type
  IChain = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B3D}']
    function GetGenesisSnapshotBlock: ISnapshotBlock;
    function GetLatestSnapshotBlock: ISnapshotBlock;
    procedure Register(ParaListener: IEventListener);
    procedure UnRegister(ParaListener: IEventListener);
    function GetConsensusGroupList(const ParaSnapshotHash: THash): TArray<IConsensusGroupInfo>;
    function GetRegisterList(const ParaSnapshotHash: THash; const ParaGid: TGid): TArray<IRegistration>;
    function GetAllRegisterList(const ParaSnapshotHash: THash; const ParaGid: TGid): TArray<IRegistration>;
    function GetVoteList(const ParaSnapshotHash: THash; const ParaGid: TGid): TArray<IVoteInfo>;
    function GetConfirmedBalanceList(const ParaAddrList: TArray<TAddress>; const ParaTokenID: TTokenTypeId; const ParaSbHash: THash): TDictionary<TAddress, TBigInteger>;
    function GetSnapshotHeaderBeforeTime(ParaTimestamp: TDateTime): ISnapshotBlock;
    function GetContractMeta(const ParaContractAddress: TAddress): IContractMeta;
    function GetSnapshotBlockByHeight(ParaHeight: TUInt64): ISnapshotBlock;
    function GetSnapshotBlockByHash(const ParaHash: THash): ISnapshotBlock;
    function GetSnapshotHeadersAfterOrEqualTime(const ParaEndHashHeight: IHashHeight; ParaStartTime: TDateTime; const ParaProducer: TAddress): TArray<ISnapshotBlock>;
    function IsGenesisSnapshotBlock(const ParaHash: THash): Boolean;
    function GetRandomSeed(const ParaSnapshotHash: THash; ParaN: Integer): TUInt64;
    function GetLastUnpublishedSeedSnapshotHeader(const ParaProducer: TAddress; ParaBeforeTime: TDateTime): ISnapshotBlock;
    function NewDb(const ParaDbDir: string): TLevelDB;
  end;

  // VoteDetails is an extension for core.Vote
  TVoteDetails = record
    Vote: IVote;
    CurrentAddr: TAddress;
    RegisterList: TArray<TAddress>;
    Addr: TDictionary<TAddress, TBigInteger>;
  end;

  // ByBalance sorts a slice of VoteDetails in decreasing order.
  // Sorts by name for equal balance
  TByBalance = class(TComparer<TVoteDetails>)
  public
    function Compare(const ParaLeft, ParaRight: TVoteDetails): Integer; override;
  end;

  TChainRw = class
  private
    mGenesisTime: TDateTime;
    mRw: IChain;
    mRollbackLock: IChainRollback;
    mHourPoints: ILinkedArray;
    mDayPoints: ILinkedArray;
    mPeriodPoints: TPeriodLinkedArray;
    mDbCache: TConsensusDB;
    mLruCache: TLruCache;
    mStarted: TChannel<Boolean>;
    mSnapshotLoadCh: TChannel<ISnapshotBlock>;
    mWg: TCountdownEvent;
    mLog: ILogger;
    mSnapshot: TSnapshotCs;
    function GenLruKey(const ParaGid: TGid; const ParaHash: THash): TBytes;
    procedure DoStart;
  public
    constructor Create(ParaRw: IChain; ParaLog: ILogger; ParaRollbackLock: IChainRollback);
    destructor Destroy; override;
    procedure Init(ParaCs: TSnapshotCs);
    procedure Start;
    procedure Stop;
    function GetSnapshotBeforeTime(ParaT: TDateTime): ISnapshotBlock;
    function GetSeedsBeforeHashH(const ParaHash: THash): TUInt64;
    function CalVotes(ParaInfo: IGroupInfo; const ParaHashH: IHashHeight): TArray<IVote>;
    function CalVoteDetails(const ParaGid: TGid; ParaInfo: IGroupInfo; const ParaBlock: IHashHeight): TArray<TVoteDetails>;
    function GenVoteDetails(const ParaSnapshotHash: THash; ParaRegistration: IRegistration; const ParaInfos: TArray<IVoteInfo>; const ParaId: TTokenTypeId): TVoteDetails;
    function GetMemberInfo(const ParaGid: TGid): IGroupInfo;
    function GetGid(ParaBlock: IAccountBlock): TGid;
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function CheckSnapshotHashValid(ParaStartHeight: TUInt64; const ParaStartHash, ParaActual: THash; ParaVoteTime: TDateTime): string;
    function GetSuccessRateByHour(ParaIndex: TUInt64): TDictionary<TAddress, Single>;
    function GetSuccessRateByHour2(ParaIndex: TUInt64): TTuple<TDictionary<TAddress, IContent>, Exception>;
    function GetSnapshotVoteCache(const ParaHashes: THash): TTuple<TArray<TAddress>, Boolean>;
    procedure UpdateSnapshotVoteCache(const ParaHashes: THash; const ParaAddresses: TArray<TAddress>);
    function GetVoteLRUCache(const ParaGid: TGid; const ParaHashes: THash): TTuple<TArray<TAddress>, Boolean>;
    procedure UpdateVoteLRUCache(const ParaGid: TGid; const ParaHashes: THash; const ParaAddrArr: TArray<TAddress>);
  end;

implementation

uses
  System.Threading,
  System.DateUtils;

const
  Period = 1;
  Hour = 48 * Period;
  Day = 24 * Hour;

{ TByBalance }

function TByBalance.Compare(const ParaLeft, ParaRight: TVoteDetails): Integer;
var
  vR: Integer;
begin
  vR := ParaRight.Vote.Balance.CompareTo(ParaLeft.Vote.Balance);
  if vR = 0 then
  begin
    Result := TComparer<string>.Default.Compare(ParaLeft.Vote.Name, ParaRight.Vote.Name);
  end
  else
  begin
    Result := vR;
  end;
end;

{ TChainRw }

constructor TChainRw.Create(ParaRw: IChain; ParaLog: ILogger; ParaRollbackLock: IChainRollback);
var
  vDb: TLevelDB;
begin
  mRw := ParaRw;
  mGenesisTime := ParaRw.GetGenesisSnapshotBlock.Timestamp;
  try
    vDb := ParaRw.NewDb('consensus');
    mDbCache := TConsensusDB.Create(vDb);
  except
    on E: Exception do
    begin
      raise Exception.Create('Failed to create consensus DB: ' + E.Message);
    end;
  end;
  try
    mLruCache := TLruCache.Create(1024 * 10);
  except
    on E: Exception do
    begin
      raise Exception.Create('Failed to create LRU cache: ' + E.Message);
    end;
  end;
  mLog := ParaLog;
  mRollbackLock := ParaRollbackLock;
end;

destructor TChainRw.Destroy;
begin
  mDbCache.Free;
  mLruCache.Free;
  inherited;
end;

procedure TChainRw.Init(ParaCs: TSnapshotCs);
var
  vProof: TRollbackProof;
begin
  if ParaCs = nil then
  begin
    raise Exception.Create('snapshot cs is nil.');
  end;
  vProof := TRollbackProof.Create(mRw);
  mPeriodPoints := TPeriodLinkedArray.Create(mRw, ParaCs, vProof, mLog);
  mHourPoints := THourLinkedArray.Create(mPeriodPoints, mDbCache, vProof, Round(ParaCs.GetInfo.PlanInterval * 1000), mGenesisTime, mLog);
  mDayPoints := TDayLinkedArray.Create(mHourPoints, mDbCache, vProof, ParaCs.DayVoteStat, mGenesisTime, mLog);
  mSnapshot := ParaCs;
  mSnapshotLoadCh := TChannel<ISnapshotBlock>.Create;
end;

procedure TChainRw.DoStart;
var
  vTicker: TTimer;
  vBlock: ISnapshotBlock;
  vTime: TDateTime;
  vIndex, vLastIdx: TUInt64;
  vPoint: IPoint;
  vStop: Boolean;
begin
  try
    vTicker := TTimer.Create(nil);
    try
      vTicker.Interval := 30000;
      vTicker.OnTimer := procedure(Sender: TObject)
      begin
        vBlock := GetLatestSnapshotBlock;
        vTime := vBlock.Timestamp;
        vIndex := mDayPoints.Time2Index(vTime);
        try
          vPoint := mDayPoints.GetByIndex(vIndex);
          mLog.Info('get day by info index', 'index', vIndex, 'time', vTime, 'point', vPoint.Json);
        except
          on E: Exception do
          begin
            mLog.Error('can''t get day info by index', 'index', vIndex, 'time', vTime);
          end;
        end;
        if vIndex > 0 then
        begin
          vLastIdx := vIndex - 1;
          try
            vPoint := mDayPoints.GetByIndex(vLastIdx);
            mLog.Info('get day by info last index', 'index', vLastIdx, 'time', vTime, 'point', vPoint.Json);
          except
            on E: Exception do
            begin
              mLog.Error('can''t get day info by last index', 'index', vLastIdx, 'time', vTime);
            end;
          end;
        end;
      end;
      vTicker.Enabled := True;
      while True do
      begin
        TChannel.Select(
          [mStarted, mSnapshotLoadCh],
          procedure(ParaValue: TValue; ParaChannel: TChannel)
          begin
            if ParaChannel = mStarted then
            begin
              vStop := True;
            end
            else if ParaChannel = mSnapshotLoadCh then
            begin
              vBlock := ParaValue.AsType<ISnapshotBlock>;
              mSnapshot.LoadVotes(vBlock);
            end;
          end
        );
        if vStop then
        begin
          Break;
        end;
      end;
    finally
      vTicker.Free;
    end;
  finally
    mWg.Signal;
  end;
end;

procedure TChainRw.Start;
begin
  mStarted := TChannel<Boolean>.Create;
  mWg := TCountdownEvent.Create(1);
  TTask.Run(procedure
  begin
    DoStart;
  end);
end;

procedure TChainRw.Stop;
begin
  mStarted.Close;
  mWg.Wait;
end;

function TChainRw.GetSnapshotBeforeTime(ParaT: TDateTime): ISnapshotBlock;
begin
  try
    Result := mRw.GetSnapshotHeaderBeforeTime(ParaT);
    if Result = nil then
    begin
      raise Exception.Create('before time[' + DateTimeToStr(ParaT) + '] block not exist');
    end;
  except
    on E: Exception do
    begin
      raise E;
    end;
  end;
end;

function TChainRw.GetSeedsBeforeHashH(const ParaHash: THash): TUInt64;
begin
  Result := mRw.GetRandomSeed(ParaHash, 25);
end;

function TChainRw.CalVotes(ParaInfo: IGroupInfo; const ParaHashH: IHashHeight): TArray<IVote>;
begin
  Result := TConsensusCore.CalVotes(ParaInfo.ConsensusGroupInfo, ParaHashH.Hash, mRw);
end;

function TChainRw.CalVoteDetails(const ParaGid: TGid; ParaInfo: IGroupInfo; const ParaBlock: IHashHeight): TArray<TVoteDetails>;
var
  vRegisterList: TArray<IRegistration>;
  vVotes: TArray<IVoteInfo>;
  vRegisters: TArray<TVoteDetails>;
  vV: IRegistration;
begin
  try
    vRegisterList := mRw.GetRegisterList(ParaBlock.Hash, ParaGid);
    vVotes := mRw.GetVoteList(ParaBlock.Hash, ParaGid);
  except
    on E: Exception do
    begin
      raise E;
    end;
  end;

  SetLength(vRegisters, 0);
  for vV in vRegisterList do
  begin
    vRegisters := Concat(vRegisters, [GenVoteDetails(ParaBlock.Hash, vV, vVotes, ParaInfo.CountingTokenId)]);
  end;
  TArray.Sort<TVoteDetails>(vRegisters, TByBalance.Create);
  Result := vRegisters;
end;

function TChainRw.GenVoteDetails(const ParaSnapshotHash: THash; ParaRegistration: IRegistration; const ParaInfos: TArray<IVoteInfo>; const ParaId: TTokenTypeId): TVoteDetails;
var
  vAddrs: TArray<TAddress>;
  vV: IVoteInfo;
  vBalanceMap: TDictionary<TAddress, TBigInteger>;
  vBalanceTotal: TBigInteger;
  vAddr: TAddress;
  vBalance: TBigInteger;
begin
  SetLength(vAddrs, 0);
  for vV in ParaInfos do
  begin
    if vV.SbpName = ParaRegistration.Name then
    begin
      vAddrs := Concat(vAddrs, [vV.VoteAddr]);
    end;
  end;
  try
    vBalanceMap := mRw.GetConfirmedBalanceList(vAddrs, ParaId, ParaSnapshotHash);
  except
    on E: Exception do
    begin
      raise E;
    end;
  end;
  vBalanceTotal := TBigInteger.Zero;
  for vAddr in vBalanceMap.Keys do
  begin
    vBalance := vBalanceMap[vAddr];
    vBalanceTotal := vBalanceTotal + vBalance;
  end;
  Result.Vote.Name := ParaRegistration.Name;
  Result.Vote.Addr := ParaRegistration.BlockProducingAddress;
  Result.Vote.Balance := vBalanceTotal;
  Result.CurrentAddr := ParaRegistration.BlockProducingAddress;
  Result.RegisterList := ParaRegistration.HisAddrList;
  Result.Addr := vBalanceMap;
end;

function TChainRw.GetMemberInfo(const ParaGid: TGid): IGroupInfo;
var
  vHead: ISnapshotBlock;
  vConsensusGroupList: TArray<IConsensusGroupInfo>;
  vV: IConsensusGroupInfo;
begin
  Result := nil;
  vHead := mRw.GetLatestSnapshotBlock;
  try
    vConsensusGroupList := mRw.GetConsensusGroupList(vHead.Hash);
  except
    on E: Exception do
    begin
      raise E;
    end;
  end;
  for vV in vConsensusGroupList do
  begin
    if vV.Gid = ParaGid then
    begin
      Result := TGroupInfo.Create(mGenesisTime, vV);
    end;
  end;
  if Result = nil then
  begin
    raise Exception.Create(Format('can''t get consensus group[%s] info by [%s-%d].', [ParaGid.ToString, vHead.Hash.ToString, vHead.Height]));
  end;
end;

function TChainRw.GetGid(ParaBlock: IAccountBlock): TGid;
var
  vMeta: IContractMeta;
begin
  try
    vMeta := mRw.GetContractMeta(ParaBlock.AccountAddress);
    Result := vMeta.Gid;
  except
    on E: Exception do
    begin
      raise E;
    end;
  end;
end;

function TChainRw.GetLatestSnapshotBlock: ISnapshotBlock;
begin
  Result := mRw.GetLatestSnapshotBlock;
end;

function TChainRw.CheckSnapshotHashValid(ParaStartHeight: TUInt64; const ParaStartHash, ParaActual: THash; ParaVoteTime: TDateTime): string;
var
  vStartB, vActualB, vHeader: ISnapshotBlock;
begin
  Result := '';
  if ParaStartHash = ParaActual then
  begin
    Exit;
  end;
  try
    vStartB := mRw.GetSnapshotBlockByHash(ParaStartHash);
    if vStartB = nil then
    begin
      Exit(Format('start snapshot block is nil. hashH:%s-%d', [ParaStartHash.ToString, ParaStartHeight]));
    end;
    vActualB := mRw.GetSnapshotBlockByHash(ParaActual);
    if vActualB = nil then
    begin
      Exit(Format('refer snapshot block is nil. hashH:%s', [ParaActual.ToString]));
    end;
  except
    on E: Exception do
    begin
      Exit(E.Message);
    end;
  end;

  vHeader := mRw.GetLatestSnapshotBlock;
  if vHeader.Timestamp < ParaVoteTime then
  begin
    Exit(Format('snapshot header time must >= voteTime, headerTime:%s, voteTime:%s, headerHash:%s:%d', [DateTimeToStr(vHeader.Timestamp), DateTimeToStr(ParaVoteTime), vHeader.Hash.ToString, vHeader.Height]));
  end;

  if vActualB.Height < vStartB.Height then
  begin
    Exit('refer snapshot block height must >= start snapshot block height');
  end;
end;

function TChainRw.GetSuccessRateByHour(ParaIndex: TUInt64): TDictionary<TAddress, Single>;
var
  vResultMap: TDictionary<TAddress, Single>;
  vHourInfos: TDictionary<TAddress, IContent>;
  vPrevHash: THash;
  vIndex: TUInt64;
  vP: IPoint;
  vTmpIndex: TUInt64;
  vInfos: TDictionary<TAddress, IContent>;
  vK: TAddress;
  vV: IContent;
  vC: IContent;
begin
  vResultMap := TDictionary<TAddress, Single>.Create;
  vHourInfos := TDictionary<TAddress, IContent>.Create;
  vPrevHash := nil;
  for vIndex := 0 to Hour - 1 do
  begin
    if vIndex > ParaIndex then
    begin
      Break;
    end;
    vTmpIndex := ParaIndex - vIndex;
    try
      if vPrevHash = nil then
      begin
        vP := mPeriodPoints.GetByIndex(vTmpIndex);
      end
      else
      begin
        vP := mPeriodPoints.GetByIndexWithProof(vTmpIndex, vPrevHash);
      end;
    except
      on E: Exception do
      begin
        raise E;
      end;
    end;
    if vP = nil then
    begin
      Break;
    end;
    vInfos := vP.Sbps;
    for vK in vInfos.Keys do
    begin
      vV := vInfos[vK];
      if vHourInfos.TryGetValue(vK, vC) then
      begin
        vC.Merge(vV);
      end
      else
      begin
        vHourInfos.Add(vK, vV.Copy);
      end;
    end;
    vPrevHash := vP.PrevHash;
  end;

  for vK in vHourInfos.Keys do
  begin
    vV := vHourInfos[vK];
    vResultMap.Add(vK, vV.Rate);
  end;
  Result := vResultMap;
end;

function TChainRw.GetSuccessRateByHour2(ParaIndex: TUInt64): TTuple<TDictionary<TAddress, IContent>, Exception>;
var
  vHourInfos: TDictionary<TAddress, IContent>;
  vIndex: TUInt64;
  vTmpIndex: TUInt64;
  vP: IPoint;
  vInfos: TDictionary<TAddress, IContent>;
  vK: TAddress;
  vV: IContent;
  vC: IContent;
  vError: Exception;
begin
  vError := nil;
  vHourInfos := TDictionary<TAddress, IContent>.Create;
  for vIndex := 0 to Hour - 1 do
  begin
    if vIndex > ParaIndex then
    begin
      Break;
    end;
    vTmpIndex := ParaIndex - vIndex;
    try
      vP := mPeriodPoints.GetByIndex(vTmpIndex);
      vInfos := vP.Sbps;
      for vK in vInfos.Keys do
      begin
        vV := vInfos[vK];
        if vHourInfos.TryGetValue(vK, vC) then
        begin
          vC.Merge(vV);
        end
        else
        begin
          vHourInfos.Add(vK, vV.Copy);
        end;
      end;
    except
      on E: Exception do
      begin
        vError := E;
        break;
      end;
    end;
  end;
  Result := TTuple<TDictionary<TAddress, IContent>, Exception>.Create(vHourInfos, vError);
end;

function TChainRw.GetSnapshotVoteCache(const ParaHashes: THash): TTuple<TArray<TAddress>, Boolean>;
var
  vB: TBytes;
  vResult: TArray<TAddress>;
  vOk: Boolean;
begin
  try
    vResult := mDbCache.GetElectionResultByHash(ParaHashes, vB);
    if vB <> nil then
    begin
      Exit(TTuple<TArray<TAddress>, Boolean>.Create(nil, false));
    end;
    if vResult <> nil then
    begin
      Exit(TTuple<TArray<TAddress>, Boolean>.Create(vResult, true));
    end;
    TValue.Make(GetVoteLRUCache(TConsensusCore.SNAPSHOT_GID, ParaHashes), vResult, vOk);
    if vOk and (vResult <> nil) then
    begin
      UpdateSnapshotVoteCache(ParaHashes, vResult);
      Exit(TTuple<TArray<TAddress>, Boolean>.Create(vResult, true));
    end;
    Result := TTuple<TArray<TAddress>, Boolean>.Create(nil, false);
  except
    on E: Exception do
    begin
      Result := TTuple<TArray<TAddress>, Boolean>.Create(nil, false);
    end;
  end;
end;

procedure TChainRw.UpdateSnapshotVoteCache(const ParaHashes: THash; const ParaAddresses: TArray<TAddress>);
begin
  mDbCache.StoreElectionResultByHash(ParaHashes, ParaAddresses);
end;

function TChainRw.GetVoteLRUCache(const ParaGid: TGid; const ParaHashes: THash): TTuple<TArray<TAddress>, Boolean>;
var
  vValue: TObject;
  vOk: Boolean;
begin
  Result := TTuple<TArray<TAddress>, Boolean>.Create(nil, false);
  if mLruCache = nil then
  begin
    Exit;
  end;
  vOk := mLruCache.Get(GenLruKey(ParaGid, ParaHashes), vValue);
  if vOk then
  begin
    Result := TTuple<TArray<TAddress>, Boolean>.Create(TArray<TAddress>(vValue), vOk);
  end;
end;

procedure TChainRw.UpdateVoteLRUCache(const ParaGid: TGid; const ParaHashes: THash; const ParaAddrArr: TArray<TAddress>);
begin
  if mLruCache <> nil then
  begin
    mLog.Info(Format('store election result %s, %s', [ParaHashes.ToString, TString.Join(',', ParaAddrArr)]));
    mLruCache.Add(GenLruKey(ParaGid, ParaHashes), ParaAddrArr);
  end;
end;

function TChainRw.GenLruKey(const ParaGid: TGid; const ParaHash: THash): TBytes;
var
  vB1, vB2: TBytes;
begin
  vB1 := ParaGid.Bytes;
  vB2 := ParaHash.Bytes;
  SetLength(Result, Length(vB1) + Length(vB2));
  Move(vB1[0], Result[0], Length(vB1));
  Move(vB2[0], Result[Length(vB1)], Length(vB2));
end;

end.