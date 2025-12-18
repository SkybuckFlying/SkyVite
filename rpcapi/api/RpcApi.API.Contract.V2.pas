unit RpcApi.Api.ContractV2;

interface

uses
  Common.Helper,
  Common.Types,
  GoToDelphi.Helpers.BigInt,
  Ledger.Chain,
  Ledger.Consensus,
  Log15,
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Dashboard,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.API.Dex,
  RpcApi.API.Dex.Fund,
  RpcApi.API.Dex.Trade,
  RpcApi.API.Error.Table,
  RpcApi.API.Health,
  RpcApi.API.Ledger,
  RpcApi.API.Ledger.Debug,
  RpcApi.API.Ledger.Model,
  RpcApi.API.Ledger.V2,
  RpcApi.API.Ledger.V2.Test,
  RpcApi.API.Mintage,
  RpcApi.API.Net,
  RpcApi.API.Onroad,
  RpcApi.API.Pow,
  RpcApi.API.Quota,
  RpcApi.API.Register,
  RpcApi.API.Stats,
  RpcApi.API.Tx,
  RpcApi.API.Tx.Test,
  RpcApi.API.Util,
  RpcApi.API.Utils,
  RpcApi.API.Utils.Test,
  RpcApi.API.Virtual,
  RpcApi.API.Vote,
  RpcApi.API.Wallet,
  RpcApi.API.Wallet.V2,
  System.Classes,
  System.Generics.Collections,
  System.NetEncoding,
  System.StrUtils,
  System.SysUtils,
  Vm,
  Vm.Abi,
  Vm.Contracts,
  Vm.Contracts.Abi,
  Vm.Db,
  Vm.Quota,
  Vm.Util;

type
  TContractApiV2 = class
  private
    mChain: IChain;
    mVite: TVite;
    mCs: IConsensus;
    mLog: ILogger;
  public
    constructor Create(ParaVite: TVite);
    function GetString: string;
    function CreateContractAddress(const ParaAddress: TAddress; const ParaHeight: string; const ParaPreviousHash: THash): TAddress;
    function GetContractInfo(const ParaAddr: TAddress): TContractInfo;
    function CallOffChainMethod(const ParaParam: TCallOffChainMethodParam): TBytes;
    function Query(const ParaParam: TQueryParam): TBytes;
    function GetContractStorage(const ParaAddr: TAddress; const ParaPrefix: string): TDictionary<string, string>;
    function GetQuotaByAccount(const ParaAddr: TAddress): TQuotaInfo;
    function GetStakeList(const ParaAddress: TAddress; ParaPageIndex: Integer; ParaPageSize: Integer): TStakeInfoList;
    function GetStakeListBySearchKey(const ParaSnapshotHash: THash; const ParaLastKey: string; ParaSize: UInt64): TStakeInfoListBySearchKey;
    function GetRequiredStakeAmount(const ParaQStr: string): PString;
    function GetDelegatedStakeInfo(const ParaParams: TStakeQueryParams): TStakeInfo;
    function GetSBPList(const ParaStakeAddress: TAddress): TArray<TSBPInfo>;
    function GetSBPRewardPendingWithdrawal(const ParaName: string): TSBPReward;
    function GetSBPRewardByTimestamp(ParaTimestamp: Int64): TSBPRewardInfo;
    function GetSBPRewardByCycle(const ParaCycle: string): TSBPRewardInfo;
    function GetSBP(const ParaName: string): TSBPInfo;
    function GetSBPVoteList: TArray<TSBPVoteInfo>;
    function GetVotedSBP(const ParaAddr: TAddress): TVotedSBPInfo;
    function GetSBPVoteDetailsByCycle(const ParaCycle: string): TArray<TVoteDetail>;
    function GetTokenInfoList(ParaPageIndex: Integer; ParaPageSize: Integer): TTokenInfoList;
    function GetTokenInfoById(const ParaTokenId: TTokenTypeId): TRpcTokenInfo;
    function GetTokenInfoListByOwner(const ParaOwner: TAddress): TArray<TRpcTokenInfo>;
  end;

implementation

{ TContractApiV2 }

constructor TContractApiV2.Create(ParaVite: TVite);
begin
  mChain := ParaVite.Chain;
  mVite := ParaVite;
  mCs := ParaVite.Consensus;
  mLog := TLog.New('module', 'rpc_api/contract_api');
end;

function TContractApiV2.GetString: string;
begin
  Result := 'ContractApi';
end;

function TContractApiV2.CreateContractAddress(const ParaAddress: TAddress; const ParaHeight: string; const ParaPreviousHash: THash): TAddress;
var
  vH: UInt64;
begin
  vH := StrToUInt64(ParaHeight);
  Result := TUtil.NewContractAddress(ParaAddress, vH, ParaPreviousHash);
end;

function TContractApiV2.GetContractInfo(const ParaAddr: TAddress): TContractInfo;
var
  vCode: TBytes;
  vMeta: PContractMeta;
begin
  vCode := mChain.GetContractCode(ParaAddr);
  vMeta := mChain.GetContractMeta(ParaAddr);
  if vMeta = nil then
  begin
    Exit;
  end;
  Result.mCode := vCode;
  Result.mGid := vMeta.Gid;
  Result.mConfirmTime := vMeta.SendConfirmedTimes;
  Result.mResponseLatency := vMeta.SendConfirmedTimes;
  Result.mSeedCount := vMeta.SeedConfirmedTimes;
  Result.mRandomDegree := vMeta.SeedConfirmedTimes;
  Result.mQuotaRatio := vMeta.QuotaRatio;
  Result.mQuotaMultiplier := vMeta.QuotaRatio;
end;

function TContractApiV2.CallOffChainMethod(const ParaParam: TCallOffChainMethodParam): TBytes;
var
  vPrevHash: PHash;
  vSnapshotHash: PHash;
  vDb: IVmDb;
  vCodeBytes: TBytes;
  vAddr: TAddress;
begin
  if ParaParam.mAddr <> nil then
  begin
    vAddr := ParaParam.mAddr^;
  end
  else
  begin
    vAddr := ParaParam.mSelfAddr;
  end;

  if ParaParam.mHeight = nil then
  begin
    vPrevHash := GetPrevBlockHash(mChain, vAddr);
  end
  else
  begin
    vPrevHash := mChain.GetAccountBlockHashByHeight(vAddr, ParaParam.mHeight^);
  end;

  if ParaParam.mSnapshotHash = nil then
  begin
    vSnapshotHash := @mChain.GetLatestSnapshotBlock.Hash;
  end
  else
  begin
    vSnapshotHash := ParaParam.mSnapshotHash;
  end;

  vDb := TVmDb.Create(mChain, @vAddr, vSnapshotHash, vPrevHash);
  if ParaParam.mOffChainCode <> '' then
  begin
    vCodeBytes := TNetEncoding.Base16.Decode(ParaParam.mOffChainCode);
  end
  else if Length(ParaParam.mOffChainCodeBytes) > 0 then
  begin
    vCodeBytes := ParaParam.mOffChainCodeBytes;
  end
  else
  begin
    vCodeBytes := ParaParam.mCode;
  end;
  Result := TVM.Create(nil).OffChainReader(vDb, vCodeBytes, ParaParam.mData);
end;

function TContractApiV2.Query(const ParaParam: TQueryParam): TBytes;
var
  vPrevHash: PHash;
  vSnapshotHash: PHash;
  vDb: IVmDb;
  vCode: TBytes;
begin
  if ParaParam.mHeight = nil then
  begin
    vPrevHash := GetPrevBlockHash(mChain, ParaParam.mAddr^);
  end
  else
  begin
    vPrevHash := mChain.GetAccountBlockHashByHeight(ParaParam.mAddr^, ParaParam.mHeight^);
  end;

  if ParaParam.mSnapshotHash = nil then
  begin
    vSnapshotHash := @mChain.GetLatestSnapshotBlock.Hash;
  end
  else
  begin
    vSnapshotHash := ParaParam.mSnapshotHash;
  end;

  vDb := TVmDb.Create(mChain, ParaParam.mAddr, vSnapshotHash, vPrevHash);
  vCode := TUtil.GetContractCode(vDb, ParaParam.mAddr^, nil);
  Result := TVM.Create(nil).OffChainReader(vDb, vCode, ParaParam.mData);
end;

function TContractApiV2.GetContractStorage(const ParaAddr: TAddress; const ParaPrefix: string): TDictionary<string, string>;
var
  vPrefixBytes: TBytes;
  vIter: IIterator;
  vKey, vValue: TBytes;
begin
  Result := TDictionary<string, string>.Create;
  if ParaPrefix <> '' then
  begin
    vPrefixBytes := TNetEncoding.Base16.Decode(ParaPrefix);
  end;
  vIter := mChain.GetStorageIterator(ParaAddr, vPrefixBytes);
  try
    while vIter.Next do
    begin
      vKey := vIter.Key;
      vValue := vIter.Value;
      if (Length(vKey) > 0) and (Length(vValue) > 0) then
      begin
        Result.Add(TNetEncoding.Base16.Encode(vKey), TNetEncoding.Base16.Encode(vValue));
      end;
    end;
  finally
    vIter.Release;
  end;
end;

function TContractApiV2.GetQuotaByAccount(const ParaAddr: TAddress): TQuotaInfo;
var
  vAmount: TBigInt;
  vQ: TQuota;
begin
  mChain.GetStakeQuota(ParaAddr, vAmount, vQ);
  Result.mCurrentQuota := UInt64ToString(vQ.Current);
  Result.mMaxQuota := UInt64ToString(vQ.StakeQuotaPerSnapshotBlock * TUtil.QuotaAccumulationBlockCount);
  Result.mStakeAmount := BigIntToString(vAmount);
end;

function NewStakeInfo(const ParaAddr: TAddress; const ParaInfo: TStakeInfo; const ParaSnapshotBlock: ISnapshotBlock): TStakeInfo;
begin
  Result.mAmount := BigIntToString(ParaInfo.Amount);
  Result.mBeneficiary := ParaInfo.Beneficiary;
  Result.mExpirationHeight := UInt64ToString(ParaInfo.ExpirationHeight);
  Result.mExpirationTime := GetWithdrawTime(ParaSnapshotBlock.Timestamp, ParaSnapshotBlock.Height, ParaInfo.ExpirationHeight);
  Result.mIsDelegated := ParaInfo.IsDelegated;
  Result.mDelegateAddress := ParaInfo.DelegateAddress;
  Result.mStakeAddress := ParaAddr;
  Result.mBid := ParaInfo.Bid;
  Result.mId := ParaInfo.Id;
end;

function NewStakeInfo(const ParaAddr: TAddress; const ParaInfo: TStakeInfo; const ParaSnapshotBlock: ISnapshotBlock): TStakeInfo;
begin
  Result.mAmount := BigIntToString(ParaInfo.Amount);
  Result.mBeneficiary := ParaInfo.Beneficiary;
  Result.mExpirationHeight := UInt64ToString(ParaInfo.ExpirationHeight);
  Result.mExpirationTime := GetWithdrawTime(ParaSnapshotBlock.Timestamp, ParaSnapshotBlock.Height, ParaInfo.ExpirationHeight);
  Result.mIsDelegated := ParaInfo.IsDelegated;
  Result.mDelegateAddress := ParaInfo.DelegateAddress;
  Result.mStakeAddress := ParaAddr;
  Result.mBid := ParaInfo.Bid;
  Result.mId := ParaInfo.Id;
end;

function TContractApiV2.GetStakeList(const ParaAddress: TAddress; ParaPageIndex: Integer; ParaPageSize: Integer): TStakeInfoList;
var
  vDb: IVmDb;
  vList: TArray<TStakeInfo>;
  vAmount: TBigInt;
  vStartHeight, vEndHeight: Integer;
  vTargetList: TArray<TStakeInfo>;
  vSnapshotBlock: ISnapshotBlock;
  vIndex: Integer;
  vInfo: TStakeInfo;
begin
  if ParaPageSize > 1000 then
  begin
    raise Exception.Create('count must be less than 1000');
  end;
  vDb := GetVmDb(mChain, TAddressQuota);
  TAbi.GetStakeInfoList(vDb, ParaAddress, vList, vAmount);
  TArray.Sort<TStakeInfo>(vList, TComparer<TStakeInfo>.Construct(
    function(const Left, Right: TStakeInfo): Integer
    begin
      if Left.ExpirationHeight < Right.ExpirationHeight then
        Result := -1
      else if Left.ExpirationHeight > Right.ExpirationHeight then
        Result := 1
      else
        Result := 0;
    end));
  vStartHeight := ParaPageIndex * ParaPageSize;
  vEndHeight := (ParaPageIndex + 1) * ParaPageSize;
  if vStartHeight >= Length(vList) then
  begin
    Result.mStakeAmount := BigIntToString(vAmount);
    Result.mCount := Length(vList);
    Result.mStakeList := [];
    Exit;
  end;
  if vEndHeight > Length(vList) then
  begin
    vEndHeight := Length(vList);
  end;
  SetLength(vTargetList, vEndHeight - vStartHeight);
  vSnapshotBlock := vDb.LatestSnapshotBlock;
  for vIndex := 0 to High(vTargetList) do
  begin
    vInfo := vList[vStartHeight + vIndex];
    vTargetList[vIndex] := NewStakeInfo(ParaAddress, vInfo, vSnapshotBlock);
  end;
  Result.mStakeAmount := BigIntToString(vAmount);
  Result.mCount := Length(vList);
  Result.mStakeList := vTargetList;
end;

function TContractApiV2.GetStakeListBySearchKey(const ParaSnapshotHash: THash; const ParaLastKey: string; ParaSize: UInt64): TStakeInfoListBySearchKey;
var
  vLastKeyBytes: TBytes;
  vList: TArray<TStakeInfo>;
  vTargetList: TArray<TStakeInfo>;
  vSnapshotBlock: ISnapshotBlock;
  vIndex: Integer;
  vInfo: TStakeInfo;
begin
  if ParaSize > 1000 then
  begin
    raise Exception.Create('count must be less than 1000');
  end;
  vLastKeyBytes := TNetEncoding.Base16.Decode(ParaLastKey);
  mChain.GetStakeListByPage(ParaSnapshotHash, vLastKeyBytes, ParaSize, vList, vLastKeyBytes);
  SetLength(vTargetList, Length(vList));
  vSnapshotBlock := mChain.GetLatestSnapshotBlock;
  for vIndex := 0 to High(vList) do
  begin
    vInfo := vList[vIndex];
    vTargetList[vIndex] := NewStakeInfo(vInfo.StakeAddress, vInfo, vSnapshotBlock);
  end;
  Result.mStakingInfoList := vTargetList;
  Result.mLastKey := TNetEncoding.Base16.Encode(vLastKeyBytes);
end;

function TContractApiV2.GetRequiredStakeAmount(const ParaQStr: string): PString;
var
  vQ: UInt64;
  vAmount: TBigInt;
  vS: string;
begin
  vQ := StrToUInt64(ParaQStr);
  vAmount := TQuota.CalcStakeAmountByQuota(vQ);
  vS := BigIntToString(vAmount);
  Result := @vS;
end;

function TContractApiV2.GetDelegatedStakeInfo(const ParaParams: TStakeQueryParams): TStakeInfo;
var
  vDb: IVmDb;
  vSnapshotBlock: ISnapshotBlock;
  vInfo: TStakeInfo;
begin
  vDb := GetVmDb(mChain, TAddressQuota);
  vSnapshotBlock := vDb.LatestSnapshotBlock;
  vInfo := TAbi.GetStakeInfo(vDb, ParaParams.mStakeAddress, ParaParams.mBeneficiary, ParaParams.mDelegateAddress, True, ParaParams.mBid);
  if vInfo = nil then
  begin
    Exit;
  end;
  Result := NewStakeInfo(ParaParams.mStakeAddress, vInfo, vSnapshotBlock);
end;

function NewSBPInfo(const ParaInfo: TRegistration; const ParaSb: ISnapshotBlock): TSBPInfo;
begin
  Result.mName := ParaInfo.Name;
  Result.mBlockProducingAddress := ParaInfo.BlockProducingAddress;
  Result.mRewardWithdrawAddress := ParaInfo.RewardWithdrawAddress;
  Result.mStakeAddr := ParaInfo.StakeAddress;
  Result.mStakeAmount := BigIntToString(ParaInfo.Amount);
  Result.mExpirationHeight := UInt64ToString(ParaInfo.ExpirationHeight);
  Result.mExpirationTime := GetWithdrawTime(ParaSb.Timestamp, ParaSb.Height, ParaInfo.ExpirationHeight);
  Result.mRevokeTime := ParaInfo.RevokeTime;
end;

function NewSBPInfo(const ParaInfo: TRegistration; const ParaSb: ISnapshotBlock): TSBPInfo;
begin
  Result.mName := ParaInfo.Name;
  Result.mBlockProducingAddress := ParaInfo.BlockProducingAddress;
  Result.mRewardWithdrawAddress := ParaInfo.RewardWithdrawAddress;
  Result.mStakeAddr := ParaInfo.StakeAddress;
  Result.mStakeAmount := BigIntToString(ParaInfo.Amount);
  Result.mExpirationHeight := UInt64ToString(ParaInfo.ExpirationHeight);
  Result.mExpirationTime := GetWithdrawTime(ParaSb.Timestamp, ParaSb.Height, ParaInfo.ExpirationHeight);
  Result.mRevokeTime := ParaInfo.RevokeTime;
end;

function TContractApiV2.GetSBPList(const ParaStakeAddress: TAddress): TArray<TSBPInfo>;
var
  vDb: IVmDb;
  vSb: ISnapshotBlock;
  vList, vRewardList: TArray<TRegistration>;
  vTargetList: TArray<TSBPInfo>;
  vIndex: Integer;
  vInfo: TRegistration;
begin
  vDb := GetVmDb(mChain, TAddressGovernance);
  vSb := vDb.LatestSnapshotBlock;
  TAbi.GetRegistrationList(vDb, TSnapshotGid, ParaStakeAddress, vList);
  TAbi.GetRegistrationListByRewardWithdrawAddr(vDb, TSnapshotGid, ParaStakeAddress, vRewardList);
  vList := vList + vRewardList;
  SetLength(vTargetList, Length(vList));
  if Length(vList) > 0 then
  begin
    TArray.Sort<TRegistration>(vList, TComparer<TRegistration>.Construct(
      function(const Left, Right: TRegistration): Integer
      begin
        if Left.ExpirationHeight < Right.ExpirationHeight then
          Result := -1
        else if Left.ExpirationHeight > Right.ExpirationHeight then
          Result := 1
        else
          Result := 0;
      end));
    for vIndex := 0 to High(vList) do
    begin
      vInfo := vList[vIndex];
      vTargetList[vIndex] := NewSBPInfo(vInfo, vSb);
    end;
  end;
  Result := vTargetList;
end;

function ToSBPReward(const ParaSource: TReward): TSBPReward;
begin
  if ParaSource = nil then
  begin
    Result.mTotalReward := '0';
    Result.mVoteReward := '0';
    Result.mBlockReward := '0';
    Result.mBlockNum := '0';
    Result.mExpectedBlockNum := '0';
  end
  else
  begin
    Result.mTotalReward := BigIntToString(ParaSource.TotalReward);
    Result.mVoteReward := BigIntToString(ParaSource.VoteReward);
    Result.mBlockReward := BigIntToString(ParaSource.BlockReward);
    Result.mBlockNum := UInt64ToString(ParaSource.BlockNum);
    Result.mExpectedBlockNum := UInt64ToString(ParaSource.ExpectedBlockNum);
  end;
end;

function ToSBPReward(const ParaSource: TReward): TSBPReward;
begin
  if ParaSource = nil then
  begin
    Result.mTotalReward := '0';
    Result.mVoteReward := '0';
    Result.mBlockReward := '0';
    Result.mBlockNum := '0';
    Result.mExpectedBlockNum := '0';
  end
  else
  begin
    Result.mTotalReward := BigIntToString(ParaSource.TotalReward);
    Result.mVoteReward := BigIntToString(ParaSource.VoteReward);
    Result.mBlockReward := BigIntToString(ParaSource.BlockReward);
    Result.mBlockNum := UInt64ToString(ParaSource.BlockNum);
    Result.mExpectedBlockNum := UInt64ToString(ParaSource.ExpectedBlockNum);
  end;
end;

function TContractApiV2.GetSBPRewardPendingWithdrawal(const ParaName: string): TSBPReward;
var
  vDb: IVmDb;
  vInfo: TRegistration;
  vSb: ISnapshotBlock;
  vReward: TReward;
  vDrained: Boolean;
  vResultReward: TSBPReward;
begin
  vDb := GetVmDb(mChain, TAddressGovernance);
  vInfo := TAbi.GetRegistration(vDb, TSnapshotGid, ParaName);
  if vInfo = nil then
  begin
    raise Exception.Create(SErrSBPNotExists);
  end;
  vSb := vDb.LatestSnapshotBlock;
  TContracts.CalcReward(TUtil.NewVMConsensusReader(mCs.SBPReader), vDb, vInfo, vSb, vReward, vDrained);
  vResultReward := ToSBPReward(vReward);
  vResultReward.Drained := TContracts.RewardDrained(vReward, vDrained);
  Result := vResultReward;
end;

function TContractApiV2.GetSBPRewardByTimestamp(ParaTimestamp: Int64): TSBPRewardInfo;
var
  vDb: IVmDb;
  vM: TDictionary<string, TReward>;
  vIndex: UInt64;
  vRewardMap: TDictionary<string, TSBPReward>;
  vName: string;
  vReward: TReward;
  vStartTime, vEndTime: TDateTime;
begin
  vDb := GetVmDb(mChain, TAddressGovernance);
  TContracts.CalcRewardByCycle(vDb, TUtil.NewVMConsensusReader(mCs.SBPReader), ParaTimestamp, vM, vIndex);
  vRewardMap := TDictionary<string, TSBPReward>.Create;
  for vName in vM.Keys do
  begin
    vReward := vM[vName];
    vRewardMap.Add(vName, ToSBPReward(vReward));
  end;
  mCs.SBPReader.GetDayTimeIndex.Index2Time(vIndex, vStartTime, vEndTime);
  Result.mRewardMap := vRewardMap;
  Result.mStartTime := Round(vStartTime);
  Result.mEndTime := Round(vEndTime);
  Result.mCycle := UInt64ToString(vIndex);
end;

function TContractApiV2.GetSBPRewardByCycle(const ParaCycle: string): TSBPRewardInfo;
var
  vIndex: UInt64;
  vDb: IVmDb;
  vM: TDictionary<string, TReward>;
  vRewardMap: TDictionary<string, TSBPReward>;
  vName: string;
  vReward: TReward;
  vStartTime, vEndTime: TDateTime;
begin
  vIndex := StrToUInt64(ParaCycle);
  vDb := GetVmDb(mChain, TAddressGovernance);
  TContracts.CalcRewardByIndex(vDb, TUtil.NewVMConsensusReader(mCs.SBPReader), vIndex, vM);
  vRewardMap := TDictionary<string, TSBPReward>.Create;
  for vName in vM.Keys do
  begin
    vReward := vM[vName];
    vRewardMap.Add(vName, ToSBPReward(vReward));
  end;
  mCs.SBPReader.GetDayTimeIndex.Index2Time(vIndex, vStartTime, vEndTime);
  Result.mRewardMap := vRewardMap;
  Result.mStartTime := Round(vStartTime);
  Result.mEndTime := Round(vEndTime);
  Result.mCycle := ParaCycle;
end;

function TContractApiV2.GetSBP(const ParaName: string): TSBPInfo;
var
  vDb: IVmDb;
  vInfo: TRegistration;
  vSb: ISnapshotBlock;
begin
  vDb := GetVmDb(mChain, TAddressGovernance);
  vInfo := TAbi.GetRegistration(vDb, TSnapshotGid, ParaName);
  if vInfo = nil then
  begin
    raise Exception.Create(SErrSBPNotExists);
  end;
  vSb := vDb.LatestSnapshotBlock;
  Result := NewSBPInfo(vInfo, vSb);
end;

function TContractApiV2.GetSBPVoteList: TArray<TSBPVoteInfo>;
var
  vHead: ISnapshotBlock;
  vDetails: TArray<TVoteDetail>;
  vRes: TArray<TSBPVoteInfo>;
  vIndex: Integer;
  vVoteDetail: TVoteDetail;
begin
  vHead := mChain.GetLatestSnapshotBlock;
  mCs.API.ReadVoteMap(IncSecond(vHead.Timestamp), vDetails);
  SetLength(vRes, Length(vDetails));
  for vIndex := 0 to High(vDetails) do
  begin
    vVoteDetail := vDetails[vIndex];
    vRes[vIndex].mName := vVoteDetail.Name;
    vRes[vIndex].mBlockProducingAddress := vVoteDetail.CurrentAddr;
    vRes[vIndex].mVoteNum := BigIntToString(vVoteDetail.VoteNum);
  end;
  Result := vRes;
end;

function TContractApiV2.GetVotedSBP(const ParaAddr: TAddress): TVotedSBPInfo;
var
  vDb: IVmDb;
  vVoteInfo: TVoteInfo;
  vBalance: TBigInt;
  vActive: Boolean;
begin
  vDb := GetVmDb(mChain, TAddressGovernance);
  vVoteInfo := TAbi.GetVote(vDb, TSnapshotGid, ParaAddr);
  if vVoteInfo <> nil then
  begin
    vBalance := mChain.GetBalance(ParaAddr, TViteTokenId);
    vActive := TAbi.IsActiveRegistration(vDb, vVoteInfo.SbpName, TSnapshotGid);
    if vActive then
    begin
      Result.mName := vVoteInfo.SbpName;
      Result.mNodeStatus := NodeStatusActive;
      Result.mBalance := BigIntToString(vBalance);
    end
    else
    begin
      Result.mName := vVoteInfo.SbpName;
      Result.mNodeStatus := NodeStatusInActive;
      Result.mBalance := BigIntToString(vBalance);
    end;
  end;
end;

function TContractApiV2.GetSBPVoteDetailsByCycle(const ParaCycle: string): TArray<TVoteDetail>;
var
  vT: TDateTime;
  vIndex: UInt64;
  vEtime: TDateTime;
  vDetails: TArray<TVoteDetail>;
  vList: TArray<TVoteDetail>;
  vI: Integer;
  vDetail: TVoteDetail;
  vVoteMap: TDictionary<TAddress, string>;
  vK: TAddress;
  vV: TBigInt;
begin
  vT := Now;
  if ParaCycle <> '' then
  begin
    vIndex := StrToUInt64(ParaCycle);
    mCs.SBPReader.GetDayTimeIndex.Index2Time(vIndex, vT, vEtime);
    vT := vEtime;
  end;
  mCs.API.ReadVoteMap(vT, vDetails);
  SetLength(vList, Length(vDetails));
  for vI := 0 to High(vDetails) do
  begin
    vDetail := vDetails[vI];
    vVoteMap := TDictionary<TAddress, string>.Create;
    for vK in vDetail.VoteMap.Keys do
    begin
      vV := vDetail.VoteMap[vK];
      vVoteMap.Add(vK, BigIntToString(vV));
    end;
    vList[vI].mName := vDetail.Name;
    vList[vI].mVoteNum := BigIntToString(vDetail.VoteNum);
    vList[vI].mCurrentAddr := vDetail.CurrentAddr;
    vList[vI].mHistoryAddrList := vDetail.HistoryAddrList;
    vList[vI].mVoteMap := vVoteMap;
  end;
  Result := vList;
end;

function ByNameSort(const ParaA, ParaB: TRpcTokenInfo): Integer;
begin
  if ParaA.mTokenName = ParaB.mTokenName then
  begin
    Result := CompareStr(ParaA.mTokenId.ToString, ParaB.mTokenId.ToString);
  end
  else
  begin
    Result := CompareStr(ParaA.mTokenName, ParaB.mTokenName);
  end;
end;

function ByNameSort(const ParaA, ParaB: TRpcTokenInfo): Integer;
begin
  if ParaA.mTokenName = ParaB.mTokenName then
  begin
    Result := CompareStr(ParaA.mTokenId.ToString, ParaB.mTokenId.ToString);
  end
  else
  begin
    Result := CompareStr(ParaA.mTokenName, ParaB.mTokenName);
  end;
end;

function TContractApiV2.GetTokenInfoList(ParaPageIndex: Integer; ParaPageSize: Integer): TTokenInfoList;
var
  vDb: IVmDb;
  vTokenMap: TDictionary<TTokenTypeId, TRpcTokenInfo>;
  vListLen: Integer;
  vTokenList: TArray<TRpcTokenInfo>;
  vTokenId: TTokenTypeId;
  vTokenInfo: TRpcTokenInfo;
  vStart, vEnd: Integer;
begin
  if ParaPageSize > 1000 then
  begin
    raise Exception.Create('count must be less than 1000');
  end;
  vDb := GetVmDb(mChain, TAddressAsset);
  TAbi.GetTokenMap(vDb, vTokenMap);
  vListLen := vTokenMap.Count;
  SetLength(vTokenList, 0);
  for vTokenId in vTokenMap.Keys do
  begin
    vTokenInfo := vTokenMap[vTokenId];
    vTokenList := vTokenList + [RawTokenInfoToRpc(vTokenInfo, vTokenId)];
  end;
  TArray.Sort<TRpcTokenInfo>(vTokenList, ByNameSort);
  GetRange(ParaPageIndex, ParaPageSize, vListLen, vStart, vEnd);
  Result.mCount := vListLen;
  Result.mList := Copy(vTokenList, vStart, vEnd - vStart);
end;

function TContractApiV2.GetTokenInfoById(const ParaTokenId: TTokenTypeId): TRpcTokenInfo;
var
  vDb: IVmDb;
  vTokenInfo: TRpcTokenInfo;
begin
  vDb := GetVmDb(mChain, TAddressAsset);
  vTokenInfo := TAbi.GetTokenByID(vDb, ParaTokenId);
  if vTokenInfo <> nil then
  begin
    Result := RawTokenInfoToRpc(vTokenInfo, ParaTokenId);
  end;
end;

function TContractApiV2.GetTokenInfoListByOwner(const ParaOwner: TAddress): TArray<TRpcTokenInfo>;
var
  vDb: IVmDb;
  vTokenMap: TDictionary<TTokenTypeId, TRpcTokenInfo>;
  vTokenList: TArray<TRpcTokenInfo>;
  vTokenId: TTokenTypeId;
  vTokenInfo: TRpcTokenInfo;
begin
  vDb := GetVmDb(mChain, TAddressAsset);
  TAbi.GetTokenMapByOwner(vDb, ParaOwner, vTokenMap);
  SetLength(vTokenList, 0);
  for vTokenId in vTokenMap.Keys do
  begin
    vTokenInfo := vTokenMap[vTokenId];
    vTokenList := vTokenList + [RawTokenInfoToRpc(vTokenInfo, vTokenId)];
  end;
  Result := CheckGenesisToken(vDb, ParaOwner, mVite.Config.AssetInfo.TokenInfoMap, vTokenList);
end;

end.
