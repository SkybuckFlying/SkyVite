unit RpcApi.Api.DexFund;

interface

uses
  Common.BigInt,
  Common.Types,
  Ledger.Chain,
  Log15,
  RpcApi.API.Common.Error,
  RpcApi.API.Contract,
  RpcApi.API.Contract.V2,
  RpcApi.API.Dashboard,
  RpcApi.API.Data,
  RpcApi.API.Debug,
  RpcApi.Api.Dex,
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
  Vite,
  Vm,
  Vm.Contracts.Dex,
  Vm.Db;

type
  TDexFundApi = class
  private
    mVite: TVite;
    mChain: IChain;
    mLog: ILogger;
  public
    constructor Create(ParaVite: TVite);
    function GetString: string;
    function GetAccountFundInfo(const ParaAddr: TAddress; ParaTokenId: PTokenTypeId): TDictionary<TTokenTypeId, TAccountBalanceInfo>;
    function GetTokenInfo(const ParaToken: TTokenTypeId): TRpcDexTokenInfo;
    function GetMarketInfo(const ParaTradeToken, ParaQuoteToken: TTokenTypeId): TRpcMarketInfo;
    function GetAllTradePairs: TArray<TNewRpcMarketInfo>;
    function GetCurrentDividendPools: TDictionary<TTokenTypeId, TDividendPoolInfo>;
    function IsPledgeVip(const ParaAddress: TAddress): Boolean;
    function IsPledgeSuperVip(const ParaAddress: TAddress): Boolean;
    function IsViteXStopped: Boolean;
    function GetInviterCode(const ParaAddress: TAddress): UInt32;
    function GetInviteeCode(const ParaAddress: TAddress): UInt32;
    function IsMarketGrantedToAgent(const ParaPrincipal, ParaAgent: TAddress; const ParaTradeToken, ParaQuoteToken: TTokenTypeId): Boolean;
    function GetCurrentVxMineInfo: TRpcVxMineInfo;
    function GetCurrentFeesForMine: TDictionary<Integer, string>;
    function GetCurrentPledgeForVxSum: string;
  end;

implementation

uses
  System.StrUtils;

function GetVmDb(ParaChain: IChain; ParaAddr: TAddress): IVmDb;
begin
  Result := TVmDb.Create(ParaChain, @ParaAddr, nil, nil);
end;

{ TDexFundApi }

constructor TDexFundApi.Create(ParaVite: TVite);
begin
  inherited Create;
  mVite := ParaVite;
  mChain := ParaVite.Chain;
  mLog := TLog.New('module', 'rpc_api/dexfund_api');
end;

function TDexFundApi.GetString: string;
begin
  Result := 'DexFundApi';
end;

function TDexFundApi.GetAccountFundInfo(const ParaAddr: TAddress; ParaTokenId: PTokenTypeId): TDictionary<TTokenTypeId, TAccountBalanceInfo>;
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

function TDexFundApi.GetTokenInfo(const ParaToken: TTokenTypeId): TRpcDexTokenInfo;
var
  vDb: IVmDb;
  vTokenInfo: TDexTokenInfo;
  vOk: Boolean;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  vOk := TDex.GetTokenInfo(vDb, ParaToken, vTokenInfo);
  if vOk then
  begin
    Result := TokenInfoToRpc(vTokenInfo, ParaToken);
  end
  else
  begin
    raise Exception.Create(SInvalidTokenErr);
  end;
end;

function TDexFundApi.GetMarketInfo(const ParaTradeToken, ParaQuoteToken: TTokenTypeId): TRpcMarketInfo;
var
  vDb: IVmDb;
  vMarketInfo: TMarketInfo;
  vOk: Boolean;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  vOk := TDex.GetMarketInfo(vDb, ParaTradeToken, ParaQuoteToken, vMarketInfo);
  if vOk then
  begin
    Result := MarketInfoToRpc(vMarketInfo);
  end
  else
  begin
    raise Exception.Create(STradeMarketNotExistsErr);
  end;
end;

function TDexFundApi.GetAllTradePairs: TArray<TNewRpcMarketInfo>;
var
  vDb: IVmDb;
  vMarketInfos: TArray<TMarketInfo>;
  vOk: Boolean;
  vMarkets: TArray<TNewRpcMarketInfo>;
  vMarket: TMarketInfo;
  vRpcMarketInfo: TNewRpcMarketInfo;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  vOk := TDex.GetMarkets(vDb, vMarketInfos);
  if vOk then
  begin
    SetLength(vMarkets, Length(vMarketInfos));
    for vMarket in vMarketInfos do
    begin
      vRpcMarketInfo := MarketInfoToNewRpc(vMarket);
      vMarkets := vMarkets + [vRpcMarketInfo];
    end;
    Result := vMarkets;
  end
  else
  begin
    raise Exception.Create(STradeMarketsErr);
  end;
end;

function TDexFundApi.GetCurrentDividendPools: TDictionary<TTokenTypeId, TDividendPoolInfo>;
var
  vDb: IVmDb;
  vPools: TDictionary<TTokenTypeId, TDividendPoolInfo>;
  vDexFeesByPeriod: TDexFeesByPeriod;
  vOk: Boolean;
  vPool: TFeeForDividend;
  vTk: TTokenTypeId;
  vTokenInfo: TDexTokenInfo;
  vAmt: TBigInteger;
  vPoolInfo: TDividendPoolInfo;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  vOk := TDex.GetCurrentDexFees(vDb, GetConsensusReader(mVite), vDexFeesByPeriod);
  if not vOk then
  begin
    Exit;
  end;

  vPools := TDictionary<TTokenTypeId, TDividendPoolInfo>.Create;
  for vPool in vDexFeesByPeriod.FeesForDividend do
  begin
    vTk := TTokenTypeId.FromBytes(vPool.Token);
    vOk := TDex.GetTokenInfo(vDb, vTk, vTokenInfo);
    if not vOk then
    begin
      raise Exception.Create(SInvalidTokenErr);
    end;
    vAmt := TBigInteger.Create(vPool.DividendPoolAmount);
    vPoolInfo.Amount := vAmt.ToString;
    vPoolInfo.QuoteTokenType := vTokenInfo.QuoteTokenType;
    vPoolInfo.TokenInfo := TokenInfoToRpc(vTokenInfo, vTk);
    vPools.Add(vTk, vPoolInfo);
  end;
  Result := vPools;
end;

function TDexFundApi.IsPledgeVip(const ParaAddress: TAddress): Boolean;
var
  vDb: IVmDb;
  vVipStaking: TVIPStaking;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  Result := TDex.GetVIPStaking(vDb, ParaAddress, vVipStaking);
end;

function TDexFundApi.IsPledgeSuperVip(const ParaAddress: TAddress): Boolean;
var
  vDb: IVmDb;
  vSuperVIPStaking: TSuperVIPStaking;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  Result := TDex.GetSuperVIPStaking(vDb, ParaAddress, vSuperVIPStaking);
end;

function TDexFundApi.IsViteXStopped: Boolean;
var
  vDb: IVmDb;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  Result := TDex.IsDexStopped(vDb);
end;

function TDexFundApi.GetInviterCode(const ParaAddress: TAddress): UInt32;
var
  vDb: IVmDb;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  Result := TDex.GetCodeByInviter(vDb, ParaAddress);
end;

function TDexFundApi.GetInviteeCode(const ParaAddress: TAddress): UInt32;
var
  vDb: IVmDb;
  vInviter: TAddress;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  try
    vInviter := TDex.GetInviterByInvitee(vDb, ParaAddress);
    Result := TDex.GetCodeByInviter(vDb, vInviter);
  except
    on E: Exception do
    begin
      if E.Message = SNotBindInviterErr then
      begin
        Result := 0;
      end
      else
      begin
        raise;
      end;
    end;
  end;
end;

function TDexFundApi.IsMarketGrantedToAgent(const ParaPrincipal, ParaAgent: TAddress; const ParaTradeToken, ParaQuoteToken: TTokenTypeId): Boolean;
var
  vDb: IVmDb;
  vMarketInfo: TMarketInfo;
  vOk: Boolean;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  vOk := TDex.GetMarketInfo(vDb, ParaTradeToken, ParaQuoteToken, vMarketInfo);
  if not vOk then
  begin
    raise Exception.Create(STradeMarketNotExistsErr);
  end;
  Result := TDex.IsMarketGrantedToAgent(vDb, ParaPrincipal, ParaAgent, vMarketInfo.MarketId);
end;

function TDexFundApi.GetCurrentVxMineInfo: TRpcVxMineInfo;
var
  vDb: IVmDb;
  vPeriodId: UInt64;
  vToMine, vAvailable, vTotal, vFeeMineSum: TBigInteger;
  vAmountForItems: TDictionary<Integer, TBigInteger>;
  vRateArr: TArray<Byte>;
  vSuccess: Boolean;
  vTokenType: Integer;
  vAmount: TBigInteger;
  vRateForStakingMine: Byte;
  vMakerRateArr: TArray<Byte>;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  vPeriodId := TDex.GetCurrentPeriodId(vDb, GetConsensusReader(mVite));
  vToMine := TDex.GetVxToMineByPeriodId(vDb, vPeriodId);
  vAvailable := TDex.GetVxMinePool(vDb);
  if vToMine > vAvailable then
  begin
    vToMine := vAvailable;
  end;
  if vToMine.IsZero then
  begin
    raise Exception.Create('no vx available on mine');
  end;

  vTotal := TBigInteger.Create(100000000) * TBigInteger.Create('1000000000000000000');
  vTotal := vTotal - TDex.GetVxBurnAmount(vDb);
  Result.HistoryMinedSum := (vTotal - vAvailable).ToString;
  Result.Total := vToMine.ToString;

  vRateArr := TDex.GetFeeMineRateArr(vDb);
  vSuccess := TDex.GetVxAmountsForEqualItems(vDb, vPeriodId, vAvailable, vRateArr, vAmountForItems, vAvailable);
  if vSuccess then
  begin
    Result.FeeMineDetail := TDictionary<Integer, string>.Create;
    vFeeMineSum := TBigInteger.Create(0);
    for vTokenType in vAmountForItems.Keys do
    begin
      vAmount := vAmountForItems[vTokenType];
      Result.FeeMineDetail.Add(vTokenType, vAmount.ToString);
      vFeeMineSum := vFeeMineSum + vAmount;
    end;
    Result.FeeMineTotal := vFeeMineSum.ToString;
  end
  else
  begin
    Exit;
  end;

  vRateForStakingMine := TDex.GetFeeStakingMineRate(vDb);
  vSuccess := TDex.GetVxAmountToMine(vDb, vPeriodId, vAvailable, vRateForStakingMine, vAmount, vAvailable);
  if vSuccess then
  begin
    Result.PledgeMine := vAmount.ToString;
  end
  else
  begin
    Exit;
  end;

  vMakerRateArr := TDex.GetMakerAndMaintainerArr(vDb);
  vSuccess := TDex.GetVxAmountsForEqualItems(vDb, vPeriodId, vAvailable, vMakerRateArr, vAmountForItems, vAvailable);
  if vSuccess then
  begin
    Result.MakerMine := vAmountForItems[TDex.MineForMaker].ToString;
  end;
end;

function TDexFundApi.GetCurrentFeesForMine: TDictionary<Integer, string>;
var
  vDb: IVmDb;
  vDexFeesByPeriod: TDexFeesByPeriod;
  vOk: Boolean;
  vFees: TDictionary<Integer, string>;
  vFeeForMine: TFeeForMine;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  vOk := TDex.GetCurrentDexFees(vDb, GetConsensusReader(mVite), vDexFeesByPeriod);
  if not vOk then
  begin
    Exit;
  end;

  vFees := TDictionary<Integer, string>.Create;
  for vFeeForMine in vDexFeesByPeriod.FeesForMine do
  begin
    vFees.Add(vFeeForMine.QuoteTokenType, (TBigInteger.Create(vFeeForMine.BaseAmount) + TBigInteger.Create(vFeeForMine.InviteBonusAmount)).ToString);
  end;
  Result := vFees;
end;

function TDexFundApi.GetCurrentPledgeForVxSum: string;
var
  vDb: IVmDb;
  vMiningStakings: TMiningStakings;
  vOk: Boolean;
  vPledgesLen: Integer;
begin
  vDb := GetVmDb(mChain, TAddress.DexFund);
  vOk := TDex.GetDexMiningStakings(vDb, vMiningStakings);
  if not vOk then
  begin
    Result := '0';
    Exit;
  end;

  vPledgesLen := Length(vMiningStakings.Stakings);
  if vPledgesLen = 0 then
  begin
    Result := '0';
  end
  else
  begin
    Result := TBigInteger.Create(vMiningStakings.Stakings[vPledgesLen - 1].Amount).ToString;
  end;
end;

end.
