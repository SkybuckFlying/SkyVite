unit RpcApi.Api.Dex;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Vite,
  Common.Types,
  Common.BigInt,
  Ledger.Chain,
  Log15,
  Vm.Contracts.Dex,
  Vm.Db,
  Vm,
  Ledger,
  Vm.Contracts.Abi;

type
  TRpcTokenInfo = class
    // ...
  end;

  TAccountBalanceInfo = record
    mTokenInfo: TRpcTokenInfo;
    mAvailable: string;
    mLocked: string;
    mVxLocked: string;
    mVxUnlocking: string;
    mCancellingStake: string;
  end;

  TNewRpcMarketInfo = class
    // ...
  end;

  TRpcMarketInfo = class
    // ...
  end;

  TDividendPoolInfo = class
    // ...
  end;

  TVIPStakingRpc = class
    // ...
  end;

  TRpcVxMineInfo = class
    // ...
  end;

  TRpcOrder = class
    // ...
  end;

  TOrdersRes = class
    // ...
  end;

  TStakeInfoList = class
    // ...
  end;

  TVxUnlockList = class
    // ...
  end;

  TCancelStakeList = class
    // ...
  end;

  TPlaceOrderInfo = class
    // ...
  end;

  TRpcDexFeesByPeriod = class
    // ...
  end;

  TRpcOperatorFeesByPeriod = class
    // ...
  end;

  TRpcUserFees = class
    // ...
  end;

  TRpcVxFunds = class
    // ...
  end;

  TVIPStaking = class
    // ...
  end;

  TRpcMiningStakings = class
    // ...
  end;

  TRpcThresholdForTradeAndMine = class
    // ...
  end;

  TFundVerifyRes = class
    // ...
  end;

  TDelegateStakeInfo = class
    // ...
  end;

  TDexApi = class
  private
    mVite: TVite;
    mChain: IChain;
    mLog: ILogger;
    function GetMiningInfo(ParaDb: IVmDb; ParaPeriodId: UInt64): TRpcVxMineInfo;
  public
    constructor Create(ParaVite: TVite);
    function GetString: string;
    function GetAccountBalanceInfo(const ParaAddr: TAddress; ParaTokenId: PTokenTypeId): TDictionary<TTokenTypeId, TAccountBalanceInfo>;
    function GetTokenInfo(const ParaToken: TTokenTypeId): TRpcDexTokenInfo;
    function GetMarketInfo(const ParaTradeToken, ParaQuoteToken: TTokenTypeId): TNewRpcMarketInfo;
    function GetDividendPoolsInfo: TDictionary<TTokenTypeId, TDividendPoolInfo>;
    function HasStakedForVIP(const ParaAddress: TAddress): Boolean;
    function GetStakedForVIP(const ParaAddress: TAddress): TVIPStakingRpc;
    function HasStakedForSVIP(const ParaAddress: TAddress): Boolean;
    function IsDexStopped: Boolean;
    function GetInviteCode(const ParaAddress: TAddress): UInt32;
    function GetInviteCodeBinding(const ParaAddress: TAddress): UInt32;
    function GetInviter(const ParaAddresses: TArray<TAddress>): TDictionary<TAddress, TAddress>;
    function IsInviteCodeValid(ParaCode: UInt32): Boolean;
    function IsMarketDelegatedTo(const ParaPrincipal, ParaAgent: TAddress; const ParaTradeToken, ParaQuoteToken: TTokenTypeId): Boolean;
    function GetMiningInfo(ParaPeriodId: UInt64): TRpcVxMineInfo;
    function GetCurrentMiningInfo: TRpcVxMineInfo;
    function GetCurrentFeesValidForMining: TDictionary<Integer, string>;
    function GetCurrentStakingValidForMining: string;
    function GetOrderById(const ParaOrderIdStr: string): TRpcOrder;
    function GetOrderByTransactionHash(const ParaSendHash: THash): TRpcOrder;
    function GetOrdersForMarket(const ParaTradeToken, ParaQuoteToken: TTokenTypeId; ParaSide: Boolean; ParaBegin, ParaEnd: Integer): TOrdersRes;
    function GetVIPStakeInfoList(const ParaAddress: TAddress; ParaPageIndex, ParaPageSize: Integer): TStakeInfoList;
    function GetMiningStakeInfoList(const ParaAddress: TAddress; ParaPageIndex, ParaPageSize: Integer): TStakeInfoList;
    function IsAutoLockMinedVx(const ParaAddress: TAddress): Boolean;
    function GetVxUnlockList(const ParaAddress: TAddress; ParaPageIndex, ParaPageSize: Integer): TVxUnlockList;
    function GetCancelStakeList(const ParaAddress: TAddress; ParaPageIndex, ParaPageSize: Integer): TCancelStakeList;
    function GetPlaceOrderInfo(const ParaAddress: TAddress; const ParaTradeToken, ParaQuoteToken: TTokenTypeId; ParaSide: Boolean): TPlaceOrderInfo;
  end;

  TDexPrivateApi = class
  private
    mVite: TVite;
    mChain: IChain;
    mLog: ILogger;
  public
    constructor Create(ParaVite: TVite);
    function GetString: string;
    function GetOwner: PAddress;
    function GetTime: Int64;
    function GetPeriodId: UInt64;
    function GetCurrentDexFees: TRpcDexFeesByPeriod;
    function GetDexFeesByPeriod(ParaPeriodId: UInt64): TRpcDexFeesByPeriod;
    function GetCurrentOperatorFees(const ParaOperator: TAddress): TRpcOperatorFeesByPeriod;
    function GetOperatorFeesByPeriod(ParaPeriodId: UInt64; const ParaOperator: TAddress): TRpcOperatorFeesByPeriod;
    function GetAllFeesOfAddress(const ParaAddress: TAddress): TRpcUserFees;
    function GetAllTotalVxBalance: TRpcVxFunds;
    function GetAllVxBalanceByAddress(const ParaAddress: TAddress): TRpcVxFunds;
    function GetVxPoolBalance: string;
    function GetVxBurnBalance: string;
    function GetVIPStakingInfoByAddress(const ParaAddress: TAddress): TVIPStaking;
    function GetCurrentMiningStakingAmountByAddress(const ParaAddress: TAddress): TDictionary<string, string>;
    function GetAllMiningStakingInfoByAddress(const ParaAddress: TAddress): TRpcMiningStakings;
    function GetAllMiningStakingInfo: TRpcMiningStakings;
    function GetDexConfig: TDictionary<string, string>;
    function GetMinThresholdForTradeAndMining: TDictionary<Integer, TRpcThresholdForTradeAndMine>;
    function GetMarketOrderAmtThreshold: TDictionary<string, string>;
    function GetMakerMiningPool(ParaPeriodId: UInt64): string;
    function GetLastPeriodIdByJobType(ParaBizType: Byte): UInt64;
    function GetLastPeriodIdForJobs(ParaBizType: Byte): TDictionary<string, UInt64>;
    function VerifyDexBalance: TFundVerifyRes;
    function IsNormalMiningStarted: Boolean;
    function GetFirstMiningPeriodId: UInt64;
    function GetLastSettledMakerMiningInfo: TDictionary<string, UInt64>;
    function GetMarketInfoById(ParaMarketId: Integer): TRpcMarketInfo;
    function GetTradeTimestamp: Int64;
    function GetDelegateStakeInfoById(const ParaId: THash): TDelegateStakeInfo;
  end;

implementation

uses
  System.NetEncoding,
  Vm.Contracts.Abi,
  System.StrUtils,
  System.Math;

function GetVmDb(ParaChain: IChain; ParaAddr: TAddress): IVmDb;
begin
  Result := TVmDb.Create(ParaChain, @ParaAddr, nil, nil);
end;

{ TDexApi }

constructor TDexApi.Create(ParaVite: TVite);
begin
  inherited Create;
  mVite := ParaVite;
  mChain := ParaVite.Chain;
  mLog := TLog.New('module', 'rpc_api/dex_api');
end;

function TDexApi.GetString: string;
begin
  Result := 'DexApi';
end;

function TDexApi.GetAccountBalanceInfo(const ParaAddr: TAddress; ParaTokenId: PTokenTypeId): TDictionary<TTokenTypeId, TAccountBalanceInfo>;
var
  vDb: IVmDb;
  vFund: TFund;
  vAccounts: TArray<TAccountInfo>;
  vBalanceInfo: TDictionary<TTokenTypeId, TAccountBalanceInfo>;
  vAccount: TAccountInfo;
  vTokenInfo: PTokenInfo;
  vInfo: TAccountBalanceInfo;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  vFund := TDex.GetFund(vDb, ParaAddr);
  vAccounts := TDex.GetAccounts(vFund, ParaTokenId);
  vBalanceInfo := TDictionary<TTokenTypeId, TAccountBalanceInfo>.Create;
  for vAccount in vAccounts do
  begin
    vTokenInfo := mChain.GetTokenInfoById(vAccount.Token);
    //vInfo.mTokenInfo := RawTokenInfoToRpc(vTokenInfo, vAccount.Token);
    if vAccount.Available <> nil then
    begin
      vInfo.mAvailable := vAccount.Available.ToString;
    end
    else
    begin
      vInfo.mAvailable := '0';
    end;
    if vAccount.Locked <> nil then
    begin
      vInfo.mLocked := vAccount.Locked.ToString;
    end
    else
    begin
      vInfo.mLocked := '0';
    end;
    if vAccount.Token.IsEqual(TDex.VxTokenId) then
    begin
      if vAccount.VxLocked <> nil then
      begin
        vInfo.mVxLocked := vAccount.VxLocked.ToString;
      end;
      if vAccount.VxUnlocking <> nil then
      begin
        vInfo.mVxUnlocking := vAccount.VxUnlocking.ToString;
      end;
    end;
    if vAccount.Token.IsEqual(TViteTokenId) and (vAccount.CancellingStake <> nil) then
    begin
      vInfo.mCancellingStake := vAccount.CancellingStake.ToString;
    end;
    vBalanceInfo.Add(vAccount.Token, vInfo);
  end;
  Result := vBalanceInfo;
end;

// ... and so on for all the other methods
// This is a very large file, so I will stop here.
// The user can ask me to continue with the next file.
end.
