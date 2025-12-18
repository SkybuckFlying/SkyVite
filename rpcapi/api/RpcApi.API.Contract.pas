unit RpcApi.Api.Contract;

interface

uses
  Common.Helper,
  Common.Types,
  GoToDelphi.Helpers.BigInt,
  Ledger.Chain,
  Ledger.Consensus,
  Log15,
  RpcApi.API.Common.Error,
  RpcApi.API.Contract.V2,
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
  System.SysUtils,
  Vm,
  Vm.Abi,
  Vm.Db,
  Vm.Util;

type
  TCallOffChainMethodParam = record
    mSelfAddr: TAddress;
    mAddr: TAddress;
    mOffChainCode: string;
    mOffChainCodeBytes: TBytes;
    mCode: TBytes;
    mData: TBytes;
    mHeight: PUInt64;
    mSnapshotHash: PHash;
  end;

  TContractInfo = record
    mCode: TBytes;
    mGid: TGid;
    mConfirmTime: Byte;
    mResponseLatency: Byte;
    mSeedCount: Byte;
    mRandomDegree: Byte;
    mQuotaRatio: Byte;
    mQuotaMultiplier: Byte;
  end;

  TQueryParam = record
    mAddr: PAddress;
    mData: TBytes;
    mHeight: PUInt64;
    mSnapshotHash: PHash;
  end;

  TQuotaInfo = record
    mCurrentQuota: string;
    mMaxQuota: string;
    mStakeAmount: string;
  end;

  TStakeInfo = record
    mAmount: string;
    mBeneficiary: TAddress;
    mExpirationHeight: string;
    mExpirationTime: Int64;
    mIsDelegated: Boolean;
    mDelegateAddress: TAddress;
    mStakeAddress: TAddress;
    mBid: Byte;
    mId: PHash;
  end;

  TStakeInfoList = record
    mStakeAmount: string;
    mCount: Integer;
    mStakeList: TArray<TStakeInfo>;
  end;

  TStakeInfoListBySearchKey = record
    mStakingInfoList: TArray<TStakeInfo>;
    mLastKey: string;
  end;

  TStakeQueryParams = record
    mStakeAddress: TAddress;
    mDelegateAddress: TAddress;
    mBeneficiary: TAddress;
    mBid: Byte;
  end;

  TSBPInfo = record
    mName: string;
    mBlockProducingAddress: TAddress;
    mRewardWithdrawAddress: TAddress;
    mStakeAddr: TAddress;
    mStakeAmount: string;
    mExpirationHeight: string;
    mExpirationTime: Int64;
    mRevokeTime: Int64;
  end;

  TSBPReward = record
    mBlockReward: string;
    mVoteReward: string;
    mTotalReward: string;
    mBlockNum: string;
    mExpectedBlockNum: string;
    mDrained: Boolean;
  end;

  TSBPRewardInfo = record
    mRewardMap: TDictionary<string, TSBPReward>;
    mStartTime: Int64;
    mEndTime: Int64;
    mCycle: string;
  end;

  TSBPVoteInfo = record
    mName: string;
    mBlockProducingAddress: TAddress;
    mVoteNum: string;
  end;

  TVotedSBPInfo = record
    mName: string;
    mNodeStatus: Byte;
    mBalance: string;
  end;

  TVoteDetail = record
    mName: string;
    mVoteNum: string;
    mCurrentAddr: TAddress;
    mHistoryAddrList: TArray<TAddress>;
    mVoteMap: TDictionary<TAddress, string>;
  end;

  TRpcTokenInfo = record
    mTokenName: string;
    mTokenSymbol: string;
    mTotalSupply: string;
    mDecimals: Byte;
    mOwner: TAddress;
    mTokenId: TTokenTypeId;
    mMaxSupply: string;
    mIsReissuable: Boolean;
    mIsOwnerBurnOnly: Boolean;
    mIndex: Word;
  end;

  TTokenInfoList = record
    mCount: Integer;
    mList: TArray<TRpcTokenInfo>;
  end;

  TCreateContractDataParam = record
    mGid: TGid;
    mConfirmTime: Byte;
    mSeedCount: Byte;
    mQuotaRatio: Byte;
    mHexCode: string;
    mParams: TBytes;
  end;

  TContractApi = class
  private
    mChain: IChain;
    mVite: TVite;
    mCs: IConsensus;
    mLog: ILogger;
  public
    constructor Create(ParaVite: TVite);
    function GetCreateContractParams(const ParaAbiStr: string; const ParaParams: TArray<string>): TBytes;
    function GetCreateContractData(const ParaParam: TCreateContractDataParam): TBytes;
    function GetCallContractData(const ParaAbiStr: string; const ParaMethodName: string; const ParaParams: TArray<string>): TBytes;
    function GetCallOffChainData(const ParaAbiStr: string; const ParaOffChainName: string; const ParaParams: TArray<string>): TBytes;
    function GetCreateContractToAddress(const ParaSelfAddr: TAddress; const ParaHeightStr: string; const ParaPrevHash: THash): TAddress;
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

uses
  System.StrUtils,
  System.NetEncoding,
  System.JSON,
  Vm.Contracts,
  Vm.Contracts.Abi;

function ConvertToBool(const ParaParam: string): Boolean;
begin
  if ParaParam = 'true' then
    Result := True
  else
    Result := False;
end;

function ConvertToInt(const ParaParam: string; ParaSize: Integer): TValue;
var
  vBigInt: TBigInt;
begin
  vBigInt := TBigInt.Parse(ParaParam);
  if vBigInt.BitCount > ParaSize - 1 then
    raise Exception.Create(ParaParam + ' convert to int failed');

  case ParaSize of
    8: Result := TValue.From<Int8>(vBigInt.AsInt64);
    16: Result := TValue.From<Int16>(vBigInt.AsInt64);
    32: Result := TValue.From<Int32>(vBigInt.AsInt64);
    64: Result := TValue.From<Int64>(vBigInt.AsInt64);
  else
    Result := TValue.From<TBigInt>(vBigInt);
  end;
end;

function ConvertToUint(const ParaParam: string; ParaSize: Integer): TValue;
var
  vBigInt: TBigInt;
begin
  vBigInt := TBigInt.Parse(ParaParam);
  if vBigInt.BitCount > ParaSize then
    raise Exception.Create(ParaParam + ' convert to uint failed');

  case ParaSize of
    8: Result := TValue.From<Byte>(vBigInt.AsUInt64);
    16: Result := TValue.From<UInt16>(vBigInt.AsUInt64);
    32: Result := TValue.From<UInt32>(vBigInt.AsUInt64);
    64: Result := TValue.From<UInt64>(vBigInt.AsUInt64);
  else
    Result := TValue.From<TBigInt>(vBigInt);
  end;
end;

function ConvertToFixedBytes(const ParaParam: string; ParaSize: Integer): TBytes;
begin
  if Length(ParaParam) <> ParaSize * 2 then
    raise Exception.Create(ParaParam + ' is not valid bytes');
  Result := TNetEncoding.Base16.Decode(ParaParam);
end;

function ConvertToDynamicBytes(const ParaParam: string): TBytes;
begin
  Result := TNetEncoding.Base16.Decode(ParaParam);
end;

function ConvertToBoolArray(const ParaParam: string): TArray<Boolean>;
var
  vJson: TJSONValue;
  vJsonArray: TJSONArray;
  vIndex: Integer;
begin
  vJson := TJSONObject.ParseJSONValue(ParaParam);
  try
    vJsonArray := vJson as TJSONArray;
    SetLength(Result, vJsonArray.Count);
    for vIndex := 0 to vJsonArray.Count - 1 do
      Result[vIndex] := vJsonArray.Items[vIndex].AsBoolean;
  finally
    vJson.Free;
  end;
end;

function ConvertToIntArray(const ParaParam: string; const ParaType: TAbiType): TValue;
var
  vJson: TJSONValue;
  vJsonArray: TJSONArray;
  vIndex: Integer;
  vInt8Array: TArray<Int8>;
  vInt16Array: TArray<Int16>;
  vInt32Array: TArray<Int32>;
  vInt64Array: TArray<Int64>;
  vBigIntArray: TArray<TBigInt>;
begin
  vJson := TJSONObject.ParseJSONValue(ParaParam);
  try
    vJsonArray := vJson as TJSONArray;
    case ParaType.Size of
      8:
        begin
          SetLength(vInt8Array, vJsonArray.Count);
          for vIndex := 0 to vJsonArray.Count - 1 do
            vInt8Array[vIndex] := StrToInt8(vJsonArray.Items[vIndex].Value);
          Result := TValue.From<TArray<Int8>>(vInt8Array);
        end;
      16:
        begin
          SetLength(vInt16Array, vJsonArray.Count);
          for vIndex := 0 to vJsonArray.Count - 1 do
            vInt16Array[vIndex] := StrToInt16(vJsonArray.Items[vIndex].Value);
          Result := TValue.From<TArray<Int16>>(vInt16Array);
        end;
      32:
        begin
          SetLength(vInt32Array, vJsonArray.Count);
          for vIndex := 0 to vJsonArray.Count - 1 do
            vInt32Array[vIndex] := StrToInt32(vJsonArray.Items[vIndex].Value);
          Result := TValue.From<TArray<Int32>>(vInt32Array);
        end;
      64:
        begin
          SetLength(vInt64Array, vJsonArray.Count);
          for vIndex := 0 to vJsonArray.Count - 1 do
            vInt64Array[vIndex] := StrToInt64(vJsonArray.Items[vIndex].Value);
          Result := TValue.From<TArray<Int64>>(vInt64Array);
        end;
    else
      begin
        SetLength(vBigIntArray, vJsonArray.Count);
        for vIndex := 0 to vJsonArray.Count - 1 do
          vBigIntArray[vIndex] := TBigInt.Parse(vJsonArray.Items[vIndex].Value);
        Result := TValue.From<TArray<TBigInt>>(vBigIntArray);
      end;
    end;
  finally
    vJson.Free;
  end;
end;

function ConvertToUintArray(const ParaParam: string; const ParaType: TAbiType): TValue;
var
  vJson: TJSONValue;
  vJsonArray: TJSONArray;
  vIndex: Integer;
  vUInt8Array: TArray<Byte>;
  vUInt16Array: TArray<UInt16>;
  vUInt32Array: TArray<UInt32>;
  vUInt64Array: TArray<UInt64>;
  vBigIntArray: TArray<TBigInt>;
begin
  vJson := TJSONObject.ParseJSONValue(ParaParam);
  try
    vJsonArray := vJson as TJSONArray;
    case ParaType.Size of
      8:
        begin
          SetLength(vUInt8Array, vJsonArray.Count);
          for vIndex := 0 to vJsonArray.Count - 1 do
            vUInt8Array[vIndex] := StrToUInt8(vJsonArray.Items[vIndex].Value);
          Result := TValue.From<TArray<Byte>>(vUInt8Array);
        end;
      16:
        begin
          SetLength(vUInt16Array, vJsonArray.Count);
          for vIndex := 0 to vJsonArray.Count - 1 do
            vUInt16Array[vIndex] := StrToUInt16(vJsonArray.Items[vIndex].Value);
          Result := TValue.From<TArray<UInt16>>(vUInt16Array);
        end;
      32:
        begin
          SetLength(vUInt32Array, vJsonArray.Count);
          for vIndex := 0 to vJsonArray.Count - 1 do
            vUInt32Array[vIndex] := StrToUInt32(vJsonArray.Items[vIndex].Value);
          Result := TValue.From<TArray<UInt32>>(vUInt32Array);
        end;
      64:
        begin
          SetLength(vUInt64Array, vJsonArray.Count);
          for vIndex := 0 to vJsonArray.Count - 1 do
            vUInt64Array[vIndex] := StrToUInt64(vJsonArray.Items[vIndex].Value);
          Result := TValue.From<TArray<UInt64>>(vUInt64Array);
        end;
    else
      begin
        SetLength(vBigIntArray, vJsonArray.Count);
        for vIndex := 0 to vJsonArray.Count - 1 do
          vBigIntArray[vIndex] := TBigInt.Parse(vJsonArray.Items[vIndex].Value);
        Result := TValue.From<TArray<TBigInt>>(vBigIntArray);
      end;
    end;
  finally
    vJson.Free;
  end;
end;

function ConvertToAddressArray(const ParaParam: string): TArray<TAddress>;
var
  vJson: TJSONValue;
  vJsonArray: TJSONArray;
  vIndex: Integer;
begin
  vJson := TJSONObject.ParseJSONValue(ParaParam);
  try
    vJsonArray := vJson as TJSONArray;
    SetLength(Result, vJsonArray.Count);
    for vIndex := 0 to vJsonArray.Count - 1 do
      Result[vIndex] := TAddress.FromHex(vJsonArray.Items[vIndex].Value);
  finally
    vJson.Free;
  end;
end;

function ConvertToTokenIdArray(const ParaParam: string): TArray<TTokenTypeId>;
var
  vJson: TJSONValue;
  vJsonArray: TJSONArray;
  vIndex: Integer;
begin
  vJson := TJSONObject.ParseJSONValue(ParaParam);
  try
    vJsonArray := vJson as TJSONArray;
    SetLength(Result, vJsonArray.Count);
    for vIndex := 0 to vJsonArray.Count - 1 do
      Result[vIndex] := TTokenTypeId.FromHex(vJsonArray.Items[vIndex].Value);
  finally
    vJson.Free;
  end;
end;

function ConvertToGidArray(const ParaParam: string): TArray<TGid>;
var
  vJson: TJSONValue;
  vJsonArray: TJSONArray;
  vIndex: Integer;
begin
  vJson := TJSONObject.ParseJSONValue(ParaParam);
  try
    vJsonArray := vJson as TJSONArray;
    SetLength(Result, vJsonArray.Count);
    for vIndex := 0 to vJsonArray.Count - 1 do
      Result[vIndex] := TGid.FromHex(vJsonArray.Items[vIndex].Value);
  finally
    vJson.Free;
  end;
end;

function ConvertToStringArray(const ParaParam: string): TArray<string>;
var
  vJson: TJSONValue;
  vJsonArray: TJSONArray;
  vIndex: Integer;
begin
  vJson := TJSONObject.ParseJSONValue(ParaParam);
  try
    vJsonArray := vJson as TJSONArray;
    SetLength(Result, vJsonArray.Count);
    for vIndex := 0 to vJsonArray.Count - 1 do
      Result[vIndex] := vJsonArray.Items[vIndex].Value;
  finally
    vJson.Free;
  end;
end;

function ConvertToArray(const ParaParam: string; const ParaType: TAbiType): TValue;
var
  vTypeString: string;
begin
  if ParaType.Elem.Elem <> nil then
    raise Exception.Create(ParaType.ToString + ' type not supported');

  vTypeString := ParaType.Elem.ToString;
  if vTypeString = 'bool' then
    Result := TValue.From<TArray<Boolean>>(ConvertToBoolArray(ParaParam))
  else if vTypeString.StartsWith('int') then
    Result := ConvertToIntArray(ParaParam, ParaType.Elem)
  else if vTypeString.StartsWith('uint') then
    Result := ConvertToUintArray(ParaParam, ParaType.Elem)
  else if vTypeString = 'address' then
    Result := TValue.From<TArray<TAddress>>(ConvertToAddressArray(ParaParam))
  else if vTypeString = 'tokenId' then
    Result := TValue.From<TArray<TTokenTypeId>>(ConvertToTokenIdArray(ParaParam))
  else if vTypeString = 'gid' then
    Result := TValue.From<TArray<TGid>>(ConvertToGidArray(ParaParam))
  else if vTypeString = 'string' then
    Result := TValue.From<TArray<string>>(ConvertToStringArray(ParaParam))
  else
    raise Exception.Create(vTypeString + ' array type not supported');
end;

function ConvertOne(const ParaParam: string; const ParaType: TAbiType): TValue;
var
  vTypeString: string;
begin
  vTypeString := ParaType.ToString;
  if vTypeString.Contains('[') then
    Result := ConvertToArray(ParaParam, ParaType)
  else if vTypeString = 'bool' then
    Result := TValue.From<Boolean>(ConvertToBool(ParaParam))
  else if vTypeString.StartsWith('int') then
    Result := ConvertToInt(ParaParam, ParaType.Size)
  else if vTypeString.StartsWith('uint') then
    Result := ConvertToUint(ParaParam, ParaType.Size)
  else if vTypeString = 'address' then
    Result := TValue.From<TAddress>(TAddress.FromHex(ParaParam))
  else if vTypeString = 'tokenId' then
    Result := TValue.From<TTokenTypeId>(TTokenTypeId.FromHex(ParaParam))
  else if vTypeString = 'gid' then
    Result := TValue.From<TGid>(TGid.FromHex(ParaParam))
  else if vTypeString = 'string' then
    Result := TValue.From<string>(ParaParam)
  else if vTypeString = 'bytes' then
    Result := TValue.From<TBytes>(ConvertToDynamicBytes(ParaParam))
  else if vTypeString.StartsWith('bytes') then
    Result := TValue.From<TBytes>(ConvertToFixedBytes(ParaParam, ParaType.Size))
  else
    raise Exception.Create('unknown type ' + vTypeString);
end;

function Convert(const ParaParams: TArray<string>; const ParaArguments: TAbiArguments): TArray<TValue>;
var
  vIndex: Integer;
begin
  if Length(ParaParams) <> Length(ParaArguments) then
    raise Exception.Create('argument size not match');

  SetLength(Result, Length(ParaParams));
  for vIndex := 0 to High(ParaParams) do
  begin
    Result[vIndex] := ConvertOne(ParaParams[vIndex], ParaArguments[vIndex].Type);
  end;
end;

function ToStakeInfo(const ParaConsensusStakeInfo: TConsensusStakeInfo): TStakeInfo;
begin
  Result.mAmount := ParaConsensusStakeInfo.Amount.ToString;
  Result.mBeneficiary := ParaConsensusStakeInfo.Beneficiary;
  Result.mExpirationHeight := ParaConsensusStakeInfo.ExpirationHeight.ToString;
  Result.mExpirationTime := ParaConsensusStakeInfo.ExpirationTime;
  Result.mIsDelegated := ParaConsensusStakeInfo.IsDelegated;
  Result.mDelegateAddress := ParaConsensusStakeInfo.DelegateAddress;
  Result.mStakeAddress := ParaConsensusStakeInfo.StakeAddress;
  Result.mBid := ParaConsensusStakeInfo.Bid;
  Result.mId := ParaConsensusStakeInfo.Id;
end;

function ToSBPInfo(const ParaConsensusSbpInfo: TConsensusSbpInfo): TSBPInfo;
begin
  Result.mName := ParaConsensusSbpInfo.Name;
  Result.mBlockProducingAddress := ParaConsensusSbpInfo.BlockProducingAddress;
  Result.mRewardWithdrawAddress := ParaConsensusSbpInfo.RewardWithdrawAddress;
  Result.mStakeAddr := ParaConsensusSbpInfo.StakeAddr;
  Result.mStakeAmount := ParaConsensusSbpInfo.StakeAmount.ToString;
  Result.mExpirationHeight := ParaConsensusSbpInfo.ExpirationHeight.ToString;
  Result.mExpirationTime := ParaConsensusSbpInfo.ExpirationTime;
  Result.mRevokeTime := ParaConsensusSbpInfo.RevokeTime;
end;

function ToSBPReward(const ParaConsensusSbpReward: TConsensusSbpReward): TSBPReward;
begin
  Result.mBlockReward := ParaConsensusSbpReward.BlockReward.ToString;
  Result.mVoteReward := ParaConsensusSbpReward.VoteReward.ToString;
  Result.mTotalReward := ParaConsensusSbpReward.TotalReward.ToString;
  Result.mBlockNum := ParaConsensusSbpReward.BlockNum.ToString;
  Result.mExpectedBlockNum := ParaConsensusSbpReward.ExpectedBlockNum.ToString;
  Result.mDrained := ParaConsensusSbpReward.Drained;
end;

function ToSBPRewardInfo(const ParaConsensusSbpRewardInfo: TConsensusSbpRewardInfo): TSBPRewardInfo;
var
  vKey: string;
  vValue: TConsensusSbpReward;
begin
  Result.mRewardMap := TDictionary<string, TSBPReward>.Create;
  for vKey in ParaConsensusSbpRewardInfo.RewardMap.Keys do
  begin
    vValue := ParaConsensusSbpRewardInfo.RewardMap[vKey];
    Result.mRewardMap.Add(vKey, ToSBPReward(vValue));
  end;
  Result.mStartTime := ParaConsensusSbpRewardInfo.StartTime;
  Result.mEndTime := ParaConsensusSbpRewardInfo.EndTime;
  Result.mCycle := ParaConsensusSbpRewardInfo.Cycle.ToString;
end;

function ToSBPVoteInfo(const ParaConsensusSbpVote: TConsensusSbpVote): TSBPVoteInfo;
begin
  Result.mName := ParaConsensusSbpVote.Name;
  Result.mBlockProducingAddress := ParaConsensusSbpVote.BlockProducingAddress;
  Result.mVoteNum := ParaConsensusSbpVote.VoteNum.ToString;
end;

function ToVotedSBPInfo(const ParaConsensusVotedSbp: TConsensusVotedSbp): TVotedSBPInfo;
begin
  Result.mName := ParaConsensusVotedSbp.Name;
  Result.mNodeStatus := ParaConsensusVotedSbp.NodeStatus;
  Result.mBalance := ParaConsensusVotedSbp.Balance.ToString;
end;

function ToVoteDetail(const ParaConsensusVoteDetail: TConsensusVoteDetail): TVoteDetail;
var
  vKey: TAddress;
  vValue: TBigInt;
begin
  Result.mName := ParaConsensusVoteDetail.Name;
  Result.mVoteNum := ParaConsensusVoteDetail.VoteNum.ToString;
  Result.mCurrentAddr := ParaConsensusVoteDetail.CurrentAddr;
  Result.mHistoryAddrList := ParaConsensusVoteDetail.HistoryAddrList;
  Result.mVoteMap := TDictionary<TAddress, string>.Create;
  for vKey in ParaConsensusVoteDetail.VoteMap.Keys do
  begin
    vValue := ParaConsensusVoteDetail.VoteMap[vKey];
    Result.mVoteMap.Add(vKey, vValue.ToString);
  end;
end;

function ToRpcTokenInfo(const ParaTokenInfo: TTokenInfo): TRpcTokenInfo;
begin
  Result.mTokenName := ParaTokenInfo.TokenName;
  Result.mTokenSymbol := ParaTokenInfo.TokenSymbol;
  Result.mTotalSupply := ParaTokenInfo.TotalSupply.ToString;
  Result.mDecimals := ParaTokenInfo.Decimals;
  Result.mOwner := ParaTokenInfo.Owner;
  Result.mTokenId := ParaTokenInfo.TokenId;
  Result.mMaxSupply := ParaTokenInfo.MaxSupply.ToString;
  Result.mIsReissuable := ParaTokenInfo.IsReissuable;
  Result.mIsOwnerBurnOnly := ParaTokenInfo.IsOwnerBurnOnly;
  Result.mIndex := ParaTokenInfo.Index;
end;

{ TContractApi }

constructor TContractApi.Create(ParaVite: TVite);
begin
  inherited Create;
  mChain := ParaVite.Chain;
  mVite := ParaVite;
  mCs := ParaVite.Consensus;
  mLog := TLog.New('module', 'rpc_api/contract_api');
end;

function TContractApi.GetCreateContractParams(const ParaAbiStr: string; const ParaParams: TArray<string>): TBytes;
var
  vAbiContract: TAbiContract;
  vArguments: TArray<TValue>;
  vConstructorParams: TBytes;
begin
  if (ParaAbiStr.Length > 0) and (Length(ParaParams) > 0) then
  begin
    vAbiContract := TAbiContract.JsonToAbiContract(ParaAbiStr);
    vArguments := Convert(ParaParams, vAbiContract.Constructor.Inputs);
    vConstructorParams := vAbiContract.PackMethod('', vArguments);
    Result := vConstructorParams;
  end
  else
  begin
    Result := [];
  end;
end;

function TContractApi.GetCreateContractData(const ParaParam: TCreateContractDataParam): TBytes;
var
  vCode: TBytes;
  vData: TBytes;
begin
  vCode := TNetEncoding.Base16.Decode(ParaParam.mHexCode);
  if Length(ParaParam.mParams) > 0 then
  begin
    vData := TUtil.GetCreateContractData(JoinBytes(vCode, ParaParam.mParams), TUtil.SolidityPPContractType, ParaParam.mConfirmTime, ParaParam.mSeedCount, ParaParam.mQuotaRatio, ParaParam.mGid);
  end
  else
  begin
    vData := TUtil.GetCreateContractData(vCode, TUtil.SolidityPPContractType, ParaParam.mConfirmTime, ParaParam.mSeedCount, ParaParam.mQuotaRatio, ParaParam.mGid);
  end;
  Result := vData;
end;

function TContractApi.GetCallContractData(const ParaAbiStr: string; const ParaMethodName: string; const ParaParams: TArray<string>): TBytes;
var
  vAbiContract: TAbiContract;
  vMethod: TAbiMethod;
  vArguments: TArray<TValue>;
begin
  vAbiContract := TAbiContract.JsonToAbiContract(ParaAbiStr);
  if not vAbiContract.Methods.TryGetValue(ParaMethodName, vMethod) then
  begin
    raise Exception.Create('method name not found');
  end;
  vArguments := Convert(ParaParams, vMethod.Inputs);
  Result := vAbiContract.PackMethod(ParaMethodName, vArguments);
end;

function TContractApi.GetCallOffChainData(const ParaAbiStr: string; const ParaOffChainName: string; const ParaParams: TArray<string>): TBytes;
var
  vAbiContract: TAbiContract;
  vMethod: TAbiMethod;
  vArguments: TArray<TValue>;
begin
  vAbiContract := TAbiContract.JsonToAbiContract(ParaAbiStr);
  if not vAbiContract.OffChains.TryGetValue(ParaOffChainName, vMethod) then
  begin
    raise Exception.Create('offchain name not found');
  end;
  vArguments := Convert(ParaParams, vMethod.Inputs);
  Result := vAbiContract.PackOffChain(ParaOffChainName, vArguments);
end;

function TContractApi.GetCreateContractToAddress(const ParaSelfAddr: TAddress; const ParaHeightStr: string; const ParaPrevHash: THash): TAddress;
var
  vH: UInt64;
begin
  vH := StrToUInt64(ParaHeightStr);
  Result := TUtil.NewContractAddress(ParaSelfAddr, vH, ParaPrevHash);
end;

function TContractApi.GetContractInfo(const ParaAddr: TAddress): TContractInfo;
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

function TContractApi.CallOffChainMethod(const ParaParam: TCallOffChainMethodParam): TBytes;
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

function TContractApi.Query(const ParaParam: TQueryParam): TBytes;
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

function TContractApi.GetContractStorage(const ParaAddr: TAddress; const ParaPrefix: string): TDictionary<string, string>;
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

function TContractApi.GetQuotaByAccount(const ParaAddr: TAddress): TQuotaInfo;
var
  vCurrentQuota: TBigInt;
  vMaxQuota: TBigInt;
  vStakeAmount: TBigInt;
begin
  vCurrentQuota := mCs.GetPledgeQuota(ParaAddr);
  vMaxQuota := mCs.GetMaxQuota(ParaAddr);
  vStakeAmount := mCs.GetPledge(ParaAddr);
  Result.mCurrentQuota := vCurrentQuota.ToString;
  Result.mMaxQuota := vMaxQuota.ToString;
  Result.mStakeAmount := vStakeAmount.ToString;
end;

function TContractApi.GetStakeList(const ParaAddress: TAddress; ParaPageIndex: Integer; ParaPageSize: Integer): TStakeInfoList;
var
  vStakeList: TArray<TConsensusStakeInfo>;
  vStakeAmount: TBigInt;
  vInfo: TConsensusStakeInfo;
  vIndex: Integer;
begin
  vStakeList := mCs.GetPledgeList(ParaAddress, ParaPageIndex, ParaPageSize);
  vStakeAmount := mCs.GetPledge(ParaAddress);
  SetLength(Result.mStakeList, Length(vStakeList));
  for vIndex := 0 to High(vStakeList) do
  begin
    vInfo := vStakeList[vIndex];
    Result.mStakeList[vIndex] := ToStakeInfo(vInfo);
  end;
  Result.mStakeAmount := vStakeAmount.ToString;
  Result.mCount := Length(Result.mStakeList);
end;

function TContractApi.GetStakeListBySearchKey(const ParaSnapshotHash: THash; const ParaLastKey: string; ParaSize: UInt64): TStakeInfoListBySearchKey;
var
  vLastKeyBytes: TBytes;
  vStakingInfoList: TArray<TConsensusStakeInfo>;
  vNewLastKey: TBytes;
  vInfo: TConsensusStakeInfo;
  vIndex: Integer;
begin
  if ParaLastKey <> '' then
  begin
    vLastKeyBytes := TNetEncoding.Base16.Decode(ParaLastKey);
  end;
  mCs.GetPledgeListBySearchKey(ParaSnapshotHash, vLastKeyBytes, ParaSize, vStakingInfoList, vNewLastKey);
  SetLength(Result.mStakingInfoList, Length(vStakingInfoList));
  for vIndex := 0 to High(vStakingInfoList) do
  begin
    vInfo := vStakingInfoList[vIndex];
    Result.mStakingInfoList[vIndex] := ToStakeInfo(vInfo);
  end;
  Result.mLastKey := TNetEncoding.Base16.Encode(vNewLastKey);
end;

function TContractApi.GetRequiredStakeAmount(const ParaQStr: string): PString;
var
  vQuota: TBigInt;
  vAmount: TBigInt;
  vResultStr: string;
begin
  vQuota := TBigInt.Create(ParaQStr);
  vAmount := mCs.GetPledgeAmount(vQuota);
  vResultStr := vAmount.ToString;
  Result := @vResultStr;
end;

function TContractApi.GetDelegatedStakeInfo(const ParaParams: TStakeQueryParams): TStakeInfo;
var
  vInfo: TConsensusStakeInfo;
begin
  vInfo := mCs.GetDelegatedPledge(ParaParams.mStakeAddress, ParaParams.mDelegateAddress, ParaParams.mBeneficiary, ParaParams.mBid);
  Result := ToStakeInfo(vInfo);
end;

function TContractApi.GetSBPList(const ParaStakeAddress: TAddress): TArray<TSBPInfo>;
var
  vSbps: TArray<TConsensusSbpInfo>;
  vSbp: TConsensusSbpInfo;
  vIndex: Integer;
begin
  vSbps := mCs.GetSbpInfos(ParaStakeAddress);
  SetLength(Result, Length(vSbps));
  for vIndex := 0 to High(vSbps) do
  begin
    vSbp := vSbps[vIndex];
    Result[vIndex] := ToSBPInfo(vSbp);
  end;
end;

function TContractApi.GetSBPRewardPendingWithdrawal(const ParaName: string): TSBPReward;
var
  vReward: TConsensusSbpReward;
begin
  vReward := mCs.GetSbpRewardPendingWithdrawal(ParaName);
  Result := ToSBPReward(vReward);
end;

function TContractApi.GetSBPRewardByTimestamp(ParaTimestamp: Int64): TSBPRewardInfo;
var
  vRewardInfo: TConsensusSbpRewardInfo;
begin
  vRewardInfo := mCs.GetSbpRewardByTimestamp(ParaTimestamp);
  Result := ToSBPRewardInfo(vRewardInfo);
end;

function TContractApi.GetSBPRewardByCycle(const ParaCycle: string): TSBPRewardInfo;
var
  vCycle: UInt64;
  vRewardInfo: TConsensusSbpRewardInfo;
begin
  vCycle := StrToUInt64(ParaCycle);
  vRewardInfo := mCs.GetSbpRewardByCycle(vCycle);
  Result := ToSBPRewardInfo(vRewardInfo);
end;

function TContractApi.GetSBP(const ParaName: string): TSBPInfo;
var
  vSbp: TConsensusSbpInfo;
begin
  vSbp := mCs.GetSbpInfo(ParaName);
  Result := ToSBPInfo(vSbp);
end;

function TContractApi.GetSBPVoteList: TArray<TSBPVoteInfo>;
var
  vSbps: TArray<TConsensusSbpVote>;
  vSbp: TConsensusSbpVote;
  vIndex: Integer;
begin
  vSbps := mCs.GetSbpVoteList;
  SetLength(Result, Length(vSbps));
  for vIndex := 0 to High(vSbps) do
  begin
    vSbp := vSbps[vIndex];
    Result[vIndex] := ToSBPVoteInfo(vSbp);
  end;
end;

function TContractApi.GetVotedSBP(const ParaAddr: TAddress): TVotedSBPInfo;
var
  vSbp: TConsensusVotedSbp;
begin
  vSbp := mCs.GetVotedSbp(ParaAddr);
  Result := ToVotedSBPInfo(vSbp);
end;

function TContractApi.GetSBPVoteDetailsByCycle(const ParaCycle: string): TArray<TVoteDetail>;
var
  vCycle: UInt64;
  vVoteDetails: TArray<TConsensusVoteDetail>;
  vDetail: TConsensusVoteDetail;
  vIndex: Integer;
begin
  vCycle := StrToUInt64(ParaCycle);
  vVoteDetails := mCs.GetSbpVoteDetailsByCycle(vCycle);
  SetLength(Result, Length(vVoteDetails));
  for vIndex := 0 to High(vVoteDetails) do
  begin
    vDetail := vVoteDetails[vIndex];
    Result[vIndex] := ToVoteDetail(vDetail);
  end;
end;

function TContractApi.GetTokenInfoList(ParaPageIndex: Integer; ParaPageSize: Integer): TTokenInfoList;
var
  vTokenInfos: TArray<TTokenInfo>;
  vTokenInfo: TTokenInfo;
  vIndex: Integer;
begin
  vTokenInfos := mChain.ListTokenInfo(ParaPageIndex, ParaPageSize);
  SetLength(Result.mList, Length(vTokenInfos));
  for vIndex := 0 to High(vTokenInfos) do
  begin
    vTokenInfo := vTokenInfos[vIndex];
    Result.mList[vIndex] := ToRpcTokenInfo(vTokenInfo);
  end;
  Result.mCount := Length(Result.mList);
end;

function TContractApi.GetTokenInfoById(const ParaTokenId: TTokenTypeId): TRpcTokenInfo;
var
  vTokenInfo: TTokenInfo;
begin
  vTokenInfo := mChain.GetTokenInfo(ParaTokenId);
  Result := ToRpcTokenInfo(vTokenInfo);
end;

function TContractApi.GetTokenInfoListByOwner(const ParaOwner: TAddress): TArray<TRpcTokenInfo>;
var
  vTokenInfos: TArray<TTokenInfo>;
  vTokenInfo: TTokenInfo;
  vIndex: Integer;
begin
  vTokenInfos := mChain.ListTokenInfoByOwner(ParaOwner);
  SetLength(Result, Length(vTokenInfos));
  for vIndex := 0 to High(vTokenInfos) do
  begin
    vTokenInfo := vTokenInfos[vIndex];
    Result[vIndex] := ToRpcTokenInfo(vTokenInfo);
  end;
end;

end.
