unit Vm.Contracts.Dex.DexFundHelper;

interface

uses
  Common.Types.Address Common.Types.Hash Common.Types.TokenTypeId Common.Helper Common.Upgrade,
  Interfaces.VmDb Interfaces.Core.AccountBlock Interfaces.Core.ContractMeta,
  System.SysUtils System.Classes System.Generics.Collections,
  Vm.Abi.Abi Vm.Contracts.Abi.AbiAsset Vm.Contracts.Abi.AbiDexFund Vm.Contracts.Abi.AbiDexTrade,
  Vm.Contracts.Contracts Vm.Util.Util Vm.Quota.Quota,
  VM.Contracts.Dex.Account,
  VM.Contracts.Dex.Calculator,
  Vm.Contracts.Dex.DexErrors Vm.Contracts.Dex.DexAccount Vm.Contracts.Dex.DexCalculator,
  VM.Contracts.Dex.Errors,
  VM.Contracts.Dex.Events,
  VM.Contracts.Dex.Fund.Dividend,
  VM.Contracts.Dex.Fund.Event,
  VM.Contracts.Dex.Fund.Finish.Pendings,
  VM.Contracts.Dex.Fund.Helper.Test,
  VM.Contracts.Dex.Fund.Mine,
  VM.Contracts.Dex.Fund.Settle,
  VM.Contracts.Dex.Fund.Stake,
  VM.Contracts.Dex.Fund.Storage,
  VM.Contracts.Dex.Fund.Verifier,
  VM.Contracts.Dex.Leveldb.Book,
  VM.Contracts.Dex.Matcher,
  VM.Contracts.Dex.Matcher.Test,
  VM.Contracts.Dex.Order,
  Vm.Contracts.Dex.Proto.DexProto Vm.Contracts.Dex.DexFundStorage Vm.Contracts.Dex.DexEvents,
  VM.Contracts.Dex.Trade.Helper,
  VM.Contracts.Dex.Utils,
  VM.Contracts.Dex.Utils.Test;

const
  NewMarketFeeAmount = 1000000000000000000; // 1 VITE
  NewMarketFeeMineAmount = 100000000000000000; // 0.1 VITE
  NewMarketFeeBurnAmount = 900000000000000000; // 0.9 VITE

  PriceIntMaxLen = 12;
  PriceDecimalMaxLen = 12;

type
  TParamOpenNewMarket = record
    TradeToken: TTokenTypeId;
    QuoteToken: TTokenTypeId;
  end;

  TParamPlaceOrder = record
    TradeToken: TTokenTypeId;
    QuoteToken: TTokenTypeId;
    Side: Boolean;
    OrderType: Byte;
    Price: string;
    Quantity: TBigInteger;
  end;

  TParamSerializedData = record
    Data: TBytes;
  end;

  TParamTriggerPeriodJob = record
    PeriodId: UInt64;
    BizType: Byte;
  end;

  TParamStakeForMining = record
    ActionType: Byte;
    Amount: TBigInteger;
  end;

  TParamStakeForVIP = record
    ActionType: Byte;
  end;

  TParamTransferTokenOwnership = record
    Token: TTokenTypeId;
    NewOwner: TAddress;
  end;

  TParamNotifyTime = record
    Timestamp: Int64;
  end;

  TParamCancelOrderByHash = record
    SendHash: THash;
    Principal: TAddress;
    TradeToken: TTokenTypeId;
    QuoteToken: TTokenTypeId;
  end;

  TParamCommonAdminConfig = record
    OperationCode: Byte;
    TradeToken: TTokenTypeId;
    QuoteToken: TTokenTypeId;
    Enable: Boolean;
    Value: Int32;
    Amount: TBigInteger;
    Address: TAddress;
  end;

  TParamTransferConfig = record
    Target: TAddress;
    Token: TTokenTypeId;
    Amount: TBigInteger;
  end;

  TParamAssignedWithdraw = record
    Target: TAddress;
    Token: TTokenTypeId;
    Amount: TBigInteger;
    Label: TBytes;
  end;

  TParamConfigMarketAgents = record
    ActionType: Byte;
    Agent: TAddress;
    TradeTokens: TArray<TTokenTypeId>;
    QuoteTokens: TArray<TTokenTypeId>;
  end;

  TParamPlaceAgentOrder = record
    Principal: TAddress;
    ParamPlaceOrder: TParamPlaceOrder;
  end;

  TParamLockVxForDividend = record
    ActionType: Byte;
    Amount: TBigInteger;
  end;

  TParamSwitchConfig = record
    SwitchType: Byte;
    Enable: Boolean;
  end;

  TAmountWithToken = record
    Token: TTokenTypeId;
    Amount: TBigInteger;
    Deleted: Boolean;
  end;

function CheckMarketParam(MarketParam: TParamOpenNewMarket): Exception;
function RenderMarketInfo(Db: IVmDb; MarketInfo: TDexMarketInfo; TradeToken, QuoteToken: TTokenTypeId; TradeTokenInfo: TDexTokenInfo; Creator: TAddress): Exception;
function OnNewMarketValid(Db: IVmDb; Reader: IConsensusReader; MarketInfo: TDexMarketInfo; TradeToken, QuoteToken: TTokenTypeId; Address: TAddress): TArray<TAccountBlock>;
function OnNewMarketPending(Db: IVmDb; Param: TParamOpenNewMarket; MarketInfo: TDexMarketInfo): TBytes;
function OnNewMarketGetTokenInfoSuccess(Db: IVmDb; Reader: IConsensusReader; TradeTokenId: TTokenTypeId; TokenInfoRes: TDexParamGetTokenInfoCallback): TArray<TAccountBlock>;
function OnNewMarketGetTokenInfoFailed(Db: IVmDb; TradeTokenId: TTokenTypeId): Exception;
function OnSetQuoteTokenPending(Db: IVmDb; Token: TTokenTypeId; QuoteTokenType: Byte): TBytes;
function OnSetQuoteGetTokenInfoSuccess(Db: IVmDb; TokenInfoRes: TDexParamGetTokenInfoCallback): Exception;
function OnSetQuoteGetTokenInfoFailed(Db: IVmDb; TokenId: TTokenTypeId): Exception;
function OnTransferTokenOwnerPending(Db: IVmDb; Token: TTokenTypeId; Origin, New: TAddress): TBytes;
function OnTransferOwnerGetTokenInfoSuccess(Db: IVmDb; Param: TDexParamGetTokenInfoCallback): Exception;
function OnTransferOwnerGetTokenInfoFailed(Db: IVmDb; TradeTokenId: TTokenTypeId): Exception;
function PreCheckOrderParam(OrderParam: TParamPlaceOrder; IsStemFork: Boolean): Exception;
function DoPlaceOrder(Db: IVmDb; Param: TParamPlaceOrder; AccountAddress, Agent: TAddress; SendHash: THash): TArray<TAccountBlock>;
function RenderOrder(Order: TDexOrder; Param: TParamPlaceOrder; Db: IVmDb; AccountAddress, Agent: TAddress; SendHash: THash; EnrichOrderFork: Boolean): TPair<TDexMarketInfo, Exception>;
function CheckSettleActions(Actions: TDexProtoSettleActions): Exception;
function CheckAndLockFundForNewOrder(Db: IVmDb; DexFund: TDexFund; Order: TDexOrder; MarketInfo: TDexMarketInfo; EnrichOrderFork: Boolean): Exception;
function RenderMarketBuyOrderAmountAndFee(Order: TDexOrder);
function NewTokenInfoFromCallback(Db: IVmDb; Param: TDexParamGetTokenInfoCallback): TDexTokenInfo;
function CheckCancelAgentOrder(Db: IVmDb; Sender: TAddress; Param: TParamCancelOrderByHash): TAddress;
function DoCancelOrder(SendHash: THash; Owner: TAddress): TArray<TAccountBlock>;
function ValidPrice(const Price: string; IsFork: Boolean): Boolean;
function MaxTotalFeeRate(Order: TDexOrder): Int32;
function GenerateHeightPoint(Db: IVmDb): TUpgradePoint;
function IsDexFeeFork(Db: IVmDb): Boolean;
function IsStemFork(Db: IVmDb): Boolean;
function IsLeafFork(Db: IVmDb): Boolean;
function IsEarthFork(Db: IVmDb): Boolean;
function IsDexMiningFork(Db: IVmDb): Boolean;
function IsDexRobotFork(Db: IVmDb): Boolean;
function IsDexStableMarketFork(Db: IVmDb): Boolean;
function IsVersion10Upgrade(Db: IVmDb): Boolean;
function IsVersion11AddTransferAssetEvent(Db: IVmDb): Boolean;
function IsVersion11EnrichOrderFork(Db: IVmDb): Boolean;
function IsVersion11DeprecateClearingExpiredOrder(Db: IVmDb): Boolean;
function IsVersion12Upgrade(Db: IVmDb): Boolean;
function ValidOperatorFeeRate(FeeRate: Int32): Boolean;
function CheckPriceChar(const Price: string): Boolean;
function GetDexTokenSymbol(TokenInfo: TDexTokenInfo): string;
function IsAdvancedLimitOrder(Order: TDexOrder; EnrichOrderFork: Boolean): Boolean;
function IsMarketOrder(Order: TDexOrder; EnrichOrderFork: Boolean): Boolean;
function MapToAmountWithTokens(FeeSumMap: TDictionary<TTokenTypeId, TBigInteger>): TArray<TAmountWithToken>;

implementation

uses
  System.Math, System.RegularExpressions;

function CheckMarketParam(MarketParam: TParamOpenNewMarket): Exception;
begin
  if MarketParam.TradeToken.Compare(MarketParam.QuoteToken) = 0 then
    Result := EDexTradeMarketInvalidTokenPair.Create('trade market invalid token pair')
  else
    Result := nil;
end;

function RenderMarketInfo(Db: IVmDb; MarketInfo: TDexMarketInfo; TradeToken, QuoteToken: TTokenTypeId; TradeTokenInfo: TDexTokenInfo; Creator: TAddress): Exception;
var
  QuoteTokenInfo: TDexTokenInfo;
  Ok: Boolean;
  TradeTokenExists: Boolean;
begin
  QuoteTokenInfo := GetTokenInfo(Db, QuoteToken);
  Ok := QuoteTokenInfo.Valid;
  if (not Ok) or (QuoteTokenInfo.QuoteTokenType <= 0) then
    Exit(EDexTradeMarketInvalidQuoteToken.Create('trade market invalid quote token'));

  MarketInfo.MarketSymbol := GetDexTokenSymbol(QuoteTokenInfo);
  MarketInfo.TradeToken := TradeToken.Bytes;
  MarketInfo.QuoteToken := QuoteToken.Bytes;
  MarketInfo.QuoteTokenType := QuoteTokenInfo.QuoteTokenType;
  MarketInfo.QuoteTokenDecimals := QuoteTokenInfo.Decimals;

  if TradeTokenInfo.Valid then
    TradeTokenExists := True
  else
    TradeTokenInfo := GetTokenInfo(Db, TradeToken);

  if TradeTokenExists then
  begin
    if TradeTokenInfo.QuoteTokenType > QuoteTokenInfo.QuoteTokenType then
      Exit(EDexTradeMarketInvalidTokenPair.Create('trade market invalid token pair'));
    if BytesToAddress(TradeTokenInfo.Owner).Compare(Creator) <> 0 then
      Exit(EDexOnlyOwnerAllow.Create('only owner allow'));
    RenderMarketInfoWithTradeTokenInfo(Db, MarketInfo, TradeTokenInfo);
  end;

  if MarketInfo.Creator.Bytes = nil then
    MarketInfo.Creator := Creator.Bytes;
  if MarketInfo.Timestamp = 0 then
    MarketInfo.Timestamp := GetTimestampInt64(Db);
  Result := nil;
end;

procedure RenderMarketInfoWithTradeTokenInfo(Db: IVmDb; MarketInfo: TDexMarketInfo; TradeTokenInfo: TDexTokenInfo);
begin
  MarketInfo.MarketSymbol := Format('%s_%s', [GetDexTokenSymbol(TradeTokenInfo), MarketInfo.MarketSymbol]);
  MarketInfo.TradeTokenDecimals := TradeTokenInfo.Decimals;
  MarketInfo.Valid := True;
  MarketInfo.Owner := TradeTokenInfo.Owner;
end;

function OnNewMarketValid(Db: IVmDb; Reader: IConsensusReader; MarketInfo: TDexMarketInfo; TradeToken, QuoteToken: TTokenTypeId; Address: TAddress): TArray<TAccountBlock>;
var
  UserFee: TDexProtoFeeSettle;
  DonateAmount: TBigInteger;
  MarketBytes: TBytes;
  SyncData: TBytes;
  BurnData: TBytes;
  SyncNewMarketMethod: string;
  SendBlockItem: TAccountBlock;
begin
  if ReduceAccount(Db, Address, ViteTokenId.Bytes, TBigInteger.Create(NewMarketFeeAmount)) <> nil then
  begin
    DeleteMarketInfo(Db, TradeToken, QuoteToken);
    AddErrEvent(Db, EDexExceedFundAvailable.Create('exceed fund available'));
    Result := nil;
    Exit;
  end;

  UserFee := TDexProtoFeeSettle.Create;
  UserFee.Address := Address.Bytes;
  UserFee.BaseFee := TBigInteger.Create(NewMarketFeeMineAmount).ToByteArray;
  DonateAmount := TBigInteger.Create(NewMarketFeeDonateAmount);
  if IsEarthFork(Db) then
    DonateAmount := TBigInteger.Add(DonateAmount, TBigInteger.Create(NewMarketFeeBurnAmount));

  SettleFeesWithTokenId(Db, Reader, True, ViteTokenId, ViteTokenDecimals, ViteTokenType, [UserFee], DonateAmount, nil);
  MarketInfo.MarketId := NewAndSaveMarketId(Db);
  SaveMarketInfo(Db, MarketInfo, TradeToken, QuoteToken);
  AddMarketEvent(Db, MarketInfo);

  MarketBytes := MarketInfo.Serialize;
  SyncNewMarketMethod := MethodNameDexTradeSyncNewMarket;
  if not IsLeafFork(Db) then
    SyncNewMarketMethod := MethodNameDexTradeNotifyNewMarket;

  SyncData := ABIDexTrade.PackMethod(SyncNewMarketMethod, [MarketBytes]);
  SendBlockItem.AccountAddress := AddressDexFund;
  SendBlockItem.ToAddress := AddressDexTrade;
  SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
  SendBlockItem.TokenId := ViteTokenId;
  SendBlockItem.Amount := TBigInteger.Create(0);
  SendBlockItem.Data := SyncData;
  Result := [SendBlockItem];

  if not IsEarthFork(Db) then
  begin
    BurnData := ABIDataAsset.PackMethod(MethodNameBurn, []);
    SendBlockItem.AccountAddress := AddressDexFund;
    SendBlockItem.ToAddress := AddressAsset;
    SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
    SendBlockItem.TokenId := ViteTokenId;
    SendBlockItem.Amount := TBigInteger.Create(NewMarketFeeBurnAmount);
    SendBlockItem.Data := BurnData;
    Result := Result + [SendBlockItem];
  end;
end;

function OnNewMarketPending(Db: IVmDb; Param: TParamOpenNewMarket; MarketInfo: TDexMarketInfo): TBytes;
begin
  SaveMarketInfo(Db, MarketInfo, Param.TradeToken, Param.QuoteToken);
  AddToPendingNewMarkets(Db, Param.TradeToken, Param.QuoteToken);
  Result := ABIDataAsset.PackMethod(MethodNameGetTokenInfo, [Param.TradeToken, Byte(GetTokenForNewMarket)]);
end;

function OnNewMarketGetTokenInfoSuccess(Db: IVmDb; Reader: IConsensusReader; TradeTokenId: TTokenTypeId; TokenInfoRes: TDexParamGetTokenInfoCallback): TArray<TAccountBlock>;
var
  TradeTokenInfo: TDexTokenInfo;
  QuoteTokens: TArray<TBytes>;
  Qt: TBytes;
  QuoteTokenId: TTokenTypeId;
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
  Creator: TAddress;
  Blocks: TArray<TAccountBlock>;
begin
  TradeTokenInfo := NewTokenInfoFromCallback(Db, TokenInfoRes);
  SaveTokenInfo(Db, TradeTokenId, TradeTokenInfo);
  AddTokenEvent(Db, TradeTokenInfo);

  QuoteTokens := FilterPendingNewMarkets(Db, TradeTokenId);
  for Qt in QuoteTokens do
  begin
    QuoteTokenId := BytesToTokenTypeId(Qt);
    MarketInfo := GetMarketInfo(Db, TradeTokenId, QuoteTokenId);
    Ok := MarketInfo.Valid;
    if Ok and (not MarketInfo.Valid) then
    begin
      Creator := BytesToAddress(MarketInfo.Creator);
      if RenderMarketInfo(Db, MarketInfo, TradeTokenId, QuoteTokenId, TradeTokenInfo, Creator) <> nil then
      begin
        DeleteMarketInfo(Db, TradeTokenId, QuoteTokenId);
        AddErrEvent(Db, EDexTradeMarketInvalidQuoteToken.Create('trade market invalid quote token'));
      end
      else
      begin
        Blocks := OnNewMarketValid(Db, Reader, MarketInfo, TradeTokenId, QuoteTokenId, Creator);
        if Length(Blocks) > 0 then
          Result := Result + Blocks;
      end;
    end;
  end;
end;

function OnNewMarketGetTokenInfoFailed(Db: IVmDb; TradeTokenId: TTokenTypeId): Exception;
var
  QuoteTokens: TArray<TBytes>;
  Qt: TBytes;
  QuoteTokenId: TTokenTypeId;
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
begin
  QuoteTokens := FilterPendingNewMarkets(Db, TradeTokenId);
  for Qt in QuoteTokens do
  begin
    QuoteTokenId := BytesToTokenTypeId(Qt);
    MarketInfo := GetMarketInfo(Db, TradeTokenId, QuoteTokenId);
    Ok := MarketInfo.Valid;
    if Ok and (not MarketInfo.Valid) then
      DeleteMarketInfo(Db, TradeTokenId, QuoteTokenId);
  end;
  Result := nil;
end;

function OnSetQuoteTokenPending(Db: IVmDb; Token: TTokenTypeId; QuoteTokenType: Byte): TBytes;
begin
  AddToPendingSetQuotes(Db, Token, QuoteTokenType);
  Result := ABIDataAsset.PackMethod(MethodNameGetTokenInfo, [Token, Byte(GetTokenForSetQuote)]);
end;

function OnSetQuoteGetTokenInfoSuccess(Db: IVmDb; TokenInfoRes: TDexParamGetTokenInfoCallback): Exception;
var
  Action: TDexPendingSetQuote;
  TokenInfo: TDexTokenInfo;
begin
  Action := FilterPendingSetQuotes(Db, TokenInfoRes.TokenId);
  TokenInfo := NewTokenInfoFromCallback(Db, TokenInfoRes);
  TokenInfo.QuoteTokenType := Action.QuoteTokenType;
  SaveTokenInfo(Db, TokenInfoRes.TokenId, TokenInfo);
  AddTokenEvent(Db, TokenInfo);
  Result := nil;
end;

function OnSetQuoteGetTokenInfoFailed(Db: IVmDb; TokenId: TTokenTypeId): Exception;
begin
  FilterPendingSetQuotes(Db, TokenId);
  Result := nil;
end;

function OnTransferTokenOwnerPending(Db: IVmDb; Token: TTokenTypeId; Origin, New: TAddress): TBytes;
begin
  AddToPendingTransferTokenOwners(Db, Token, Origin, New);
  Result := ABIDataAsset.PackMethod(MethodNameGetTokenInfo, [Token, Byte(GetTokenForTransferOwner)]);
end;

function OnTransferOwnerGetTokenInfoSuccess(Db: IVmDb; Param: TDexParamGetTokenInfoCallback): Exception;
var
  Action: TDexPendingTransferTokenOwner;
  TokenInfo: TDexTokenInfo;
begin
  Action := FilterPendingTransferTokenOwners(Db, Param.TokenId);
  if (BytesToAddress(Action.Origin).Compare(Param.Owner) = 0) or
     ((Param.TokenId.Compare(ViteTokenId) = 0) and (BytesToAddress(Action.Origin).Compare(InitViteTokenOwner) = 0) and (Length(GetValueFromDb(Db, ViteOwnerInitiated)) = 0)) then
  begin
    TokenInfo := NewTokenInfoFromCallback(Db, Param);
    TokenInfo.Owner := Action.New;
    SaveTokenInfo(Db, Param.TokenId, TokenInfo);
    AddTokenEvent(Db, TokenInfo);
    Result := nil;
  end
  else
    Result := EDexOnlyOwnerAllow.Create('only owner allow');
end;

function OnTransferOwnerGetTokenInfoFailed(Db: IVmDb; TradeTokenId: TTokenTypeId): Exception;
begin
  FilterPendingTransferTokenOwners(Db, TradeTokenId);
  Result := nil;
end;

function PreCheckOrderParam(OrderParam: TParamPlaceOrder; IsStemFork: Boolean): Exception;
begin
  if OrderParam.Quantity.Sign <= 0 then
    Exit(EDexInvalidOrderQuantity.Create('invalid order quantity'));
  if (OrderParam.OrderType < Limited) or (OrderParam.OrderType > ImmediateOrCancel) then
    Exit(EDexInvalidOrderType.Create('invalid order type'));
  if (OrderParam.OrderType = Limited) or (OrderParam.OrderType = PostOnly) or (OrderParam.OrderType = FillOrKill) or (OrderParam.OrderType = ImmediateOrCancel) then
  begin
    if not ValidPrice(OrderParam.Price, IsStemFork) then
      Exit(EDexInvalidOrderPrice.Create('invalid order price format'));
  end;
  Result := nil;
end;

function DoPlaceOrder(Db: IVmDb; Param: TParamPlaceOrder; AccountAddress, Agent: TAddress; SendHash: THash): TArray<TAccountBlock>;
var
  DexFund: TDexFund;
  TradeBlockData: TBytes;
  OrderInfoBytes: TBytes;
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
  EnrichOrderFork: Boolean;
  Order: TDexOrder;
  PlaceOrderMethod: string;
  SendBlockItem: TAccountBlock;
begin
  EnrichOrderFork := False;
  if Param.OrderType <> Limited then
  begin
    EnrichOrderFork := IsVersion11EnrichOrderFork(Db);
    if not EnrichOrderFork then
      Exit(nil); // Should be EDexInvalidOrderType
  end;

  if Param.OrderType = Market then
    Param.Price := '0';

  MarketInfo := RenderOrder(Order, Param, Db, AccountAddress, Agent, SendHash, EnrichOrderFork).Item1;
  if MarketInfo.Valid then
  begin
    DexFund := GetFund(Db, AccountAddress);
    Ok := DexFund.Valid;
    if not Ok then
      Exit(nil); // Should be EDexExceedFundAvailable

    if CheckAndLockFundForNewOrder(Db, DexFund, Order, MarketInfo, EnrichOrderFork) <> nil then
      Exit(nil); // Should be EDexExceedFundAvailable

    SaveFund(Db, AccountAddress, DexFund);

    if (not Order.Side) and IsMarketOrder(Order, EnrichOrderFork) then
      RenderMarketBuyOrderAmountAndFee(Order);

    OrderInfoBytes := Order.Serialize;

    PlaceOrderMethod := MethodNameDexTradePlaceOrder;
    if not IsLeafFork(Db) then
      PlaceOrderMethod := MethodNameDexTradeNewOrder;

    TradeBlockData := ABIDexTrade.PackMethod(PlaceOrderMethod, [OrderInfoBytes]);

    SendBlockItem.AccountAddress := AddressDexFund;
    SendBlockItem.ToAddress := AddressDexTrade;
    SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
    SendBlockItem.TokenId := ViteTokenId;
    SendBlockItem.Amount := TBigInteger.Create(0);
    SendBlockItem.Data := TradeBlockData;
    Result := [SendBlockItem];
  end
  else
    Result := nil;
end;

function RenderOrder(Order: TDexOrder; Param: TParamPlaceOrder; Db: IVmDb; AccountAddress, Agent: TAddress; SendHash: THash; EnrichOrderFork: Boolean): TPair<TDexMarketInfo, Exception>;
var
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
  TotalAmount: TBigInteger;
begin
  if IsDexStopped(Db) then
    Exit(TPair<TDexMarketInfo, Exception>.Create(TDexMarketInfo.Create, EDexStopped.Create('dex stopped')));

  MarketInfo := GetMarketInfo(Db, Param.TradeToken, Param.QuoteToken);
  Ok := MarketInfo.Valid;
  if (not Ok) or (not MarketInfo.Valid) then
    Exit(TPair<TDexMarketInfo, Exception>.Create(TDexMarketInfo.Create, EDexTradeMarketNotExists.Create('trade market not exists')))
  else if MarketInfo.Stopped then
    Exit(TPair<TDexMarketInfo, Exception>.Create(TDexMarketInfo.Create, EDexTradeMarketStopped.Create('trade market stopped')))
  else if (Agent.Bytes <> nil) and (not IsMarketGrantedToAgent(Db, AccountAddress, Agent, MarketInfo.MarketId)) then
    Exit(TPair<TDexMarketInfo, Exception>.Create(TDexMarketInfo.Create, EDexTradeMarketNotGranted.Create('trade market not granted')));

  Order.Id := ComposeOrderId(Db, MarketInfo.MarketId, Param.Side, Param.Price);
  Order.MarketId := MarketInfo.MarketId;
  Order.Address := AccountAddress.Bytes;
  Order.Side := Param.Side;
  Order.OrderType := Param.OrderType;
  Order.Price := PriceToBytes(Param.Price);
  Order.Quantity := Param.Quantity.ToByteArray;
  RenderFeeRate(AccountAddress, Order, MarketInfo, Db);

  if (Order.OrderType = Limited) or IsAdvancedLimitOrder(Order, EnrichOrderFork) then
  begin
    Order.Amount := CalculateRawAmount(Order.Quantity, Order.Price, MarketInfo.TradeTokenDecimals - MarketInfo.QuoteTokenDecimals);
    if not Order.Side then //buy
      Order.LockedBuyFee := CalculateAmountForRate(Order.Amount, MaxTotalFeeRate(Order));
    TotalAmount := AddBigInt(Order.Amount, Order.LockedBuyFee);
    if IsAmountTooSmall(Db, TotalAmount, MarketInfo) then
      Exit(TPair<TDexMarketInfo, Exception>.Create(MarketInfo, EDexOrderAmountTooSmall.Create('order amount too small')));
  end;

  Order.Status := Pending;
  Order.ExecutedQuantity := TBigInteger.Create(0).ToByteArray;
  Order.ExecutedAmount := TBigInteger.Create(0).ToByteArray;
  Order.RefundToken := nil;
  Order.RefundQuantity := TBigInteger.Create(0).ToByteArray;
  Order.Timestamp := GetTimestampInt64(Db);

  if IsStemFork(Db) then
  begin
    if (Agent.Bytes <> nil) and (not IsDexRobotFork(Db)) then
      Order.Agent := Agent.Bytes;
    Order.SendHash := SendHash.Bytes;
  end;
  Result := TPair<TDexMarketInfo, Exception>.Create(MarketInfo, nil);
end;

function IsAmountTooSmall(Db: IVmDb; Amount: TBytes; MarketInfo: TDexMarketInfo): Boolean;
var
  TypeInfo: TDexQuoteTokenTypeInfo;
  TradeThreshold: TBigInteger;
begin
  TypeInfo := QuoteTokenTypeInfos.Items[MarketInfo.QuoteTokenType];
  TradeThreshold := GetTradeThreshold(Db, MarketInfo.QuoteTokenType);
  if TypeInfo.Decimals = MarketInfo.QuoteTokenDecimals then
    Result := TBigInteger.FromByteArray(Amount).Compare(TradeThreshold) < 0
  else
    Result := AdjustAmountForDecimalsDiff(Amount, MarketInfo.QuoteTokenDecimals - TypeInfo.Decimals).Compare(TradeThreshold) < 0;
end;

procedure RenderFeeRate(Address: TAddress; Order: TDexOrder; MarketInfo: TDexMarketInfo; Db: IVmDb);
var
  VipReduceFeeRate: Int32;
begin
  if IsDexStableMarketFork(Db) and MarketInfo.GetStableMarket then
    Exit;

  VipReduceFeeRate := 0;
  if GetSuperVIPStaking(Db, Address).StakedTimes > 0 then
    VipReduceFeeRate := BaseFeeRate
  else if GetVIPStaking(Db, Address).StakedTimes > 0 then
    VipReduceFeeRate := VipReduceFeeRate;

  Order.TakerFeeRate := BaseFeeRate - VipReduceFeeRate;
  Order.TakerOperatorFeeRate := MarketInfo.TakerOperatorFeeRate;
  Order.MakerFeeRate := BaseFeeRate - VipReduceFeeRate;
  Order.MakerOperatorFeeRate := MarketInfo.MakerOperatorFeeRate;

  if GetInviterByInvitee(Db, Address).Bytes <> nil then
  begin
    Order.TakerFeeRate := Order.TakerFeeRate * 9 div 10;
    Order.TakerOperatorFeeRate := Order.TakerOperatorFeeRate * 9 div 10;
    Order.MakerFeeRate := Order.MakerFeeRate * 9 div 10;
    Order.MakerOperatorFeeRate := Order.MakerOperatorFeeRate * 9 div 10;
  end;
end;

function CheckSettleActions(Actions: TDexProtoSettleActions): Exception;
var
  Fund: TDexProtoFundSettle;
begin
  if (Actions.FundActions = nil) and (Actions.FeeActions = nil) then
    Exit(Exception.Create('settle actions is emtpy'));

  for Fund in Actions.FundActions do
  begin
    if Length(Fund.Address) <> AddressSize then
      Exit(Exception.Create('invalid address format for settle'));
    if Length(Fund.AccountSettles) = 0 then
      Exit(Exception.Create('no user funds to settle'));
  end;
  Result := nil;
end;

function CheckAndLockFundForNewOrder(Db: IVmDb; DexFund: TDexFund; Order: TDexOrder; MarketInfo: TDexMarketInfo; EnrichOrderFork: Boolean): Exception;
var
  LockToken: TBytes;
  LockAmount: TBytes;
  LockTokenId: TTokenTypeId;
  Account: TDexProtoAccount;
  Exists: Boolean;
  Available: TBigInteger;
  LockAmountToInc: TBigInteger;
  MarketOrderAmtThreshold: TBigInteger;
  QuoteTokenAdjustedAmt: TBigInteger;
begin
  case Order.Side of
    False: //buy
      LockToken := MarketInfo.QuoteToken;
    True: // sell
      LockToken := MarketInfo.TradeToken;
  end;

  LockTokenId := BytesToTokenTypeId(LockToken);
  Account := GetAccountByToken(DexFund, LockTokenId);
  Exists := Account.Amount <> nil;
  if not Exists then
    Exit(EDexExceedFundAvailable.Create('exceed fund available'));

  Available := TBigInteger.FromByteArray(Account.Available);

  if (Order.Side = True) or (Order.OrderType = Limited) or IsAdvancedLimitOrder(Order, EnrichOrderFork) then
    LockAmountToInc := TBigInteger.FromByteArray(LockAmount)
  else
  begin
    LockAmountToInc := Available;
    if IsAmountTooSmall(Db, LockAmountToInc.ToByteArray, MarketInfo) then
      Exit(EDexOrderAmountTooSmall.Create('order amount too small'));
    Order.Amount := LockAmountToInc.ToByteArray;
  end;

  Available := TBigInteger.Subtract(Available, LockAmountToInc);
  if Available.Sign < 0 then
    Exit(EDexExceedFundAvailable.Create('exceed fund available'));

  if Order.OrderType = Market then
  begin
    MarketOrderAmtThreshold := GetMarketOrderAmtThreshold(Db, MarketInfo.QuoteTokenType);
    QuoteTokenAdjustedAmt := AdjustAmountForDecimalsDiff(MarketOrderAmtThreshold.ToByteArray, QuoteTokenTypeInfos.Items[MarketInfo.QuoteTokenType].Decimals - MarketInfo.QuoteTokenDecimals);
    Order.MarketOrderAmtThreshold := QuoteTokenAdjustedAmt.ToByteArray;
  end;

  Account.Available := Available.ToByteArray;
  Account.Locked := TBigInteger.Add(TBigInteger.FromByteArray(Account.Locked), LockAmountToInc).ToByteArray;
  Result := nil;
end;

procedure RenderMarketBuyOrderAmountAndFee(Order: TDexOrder);
var
  FeeRate: Int32;
  AdjustedFeeRate: Int32;
begin
  FeeRate := MaxTotalFeeRate(Order);
  if FeeRate > 0 then
  begin
    AdjustedFeeRate := Trunc(FeeRate / (RateCardinalNum + FeeRate) * RateCardinalNum) + 1;
    Order.LockedBuyFee := CalculateAmountForRate(Order.Amount, AdjustedFeeRate);
    Order.Amount := SubBigIntAbs(Order.Amount, Order.LockedBuyFee);
  end;
end;

function NewTokenInfoFromCallback(Db: IVmDb; Param: TDexParamGetTokenInfoCallback): TDexTokenInfo;
var
  TokenInfo: TDexTokenInfo;
begin
  TokenInfo.TokenId := Param.TokenId.Bytes;
  TokenInfo.Decimals := Param.Decimals;
  TokenInfo.Symbol := Param.TokenSymbol;
  TokenInfo.Index := Param.Index;
  if Param.TokenId.Compare(ViteTokenId) = 0 then
  begin
    TokenInfo.Owner := InitViteTokenOwner.Bytes;
    SetValueToDb(Db, ViteOwnerInitiated, [1]);
  end
  else
    TokenInfo.Owner := Param.Owner.Bytes;
  Result := TokenInfo;
end;

function CheckCancelAgentOrder(Db: IVmDb; Sender: TAddress; Param: TParamCancelOrderByHash): TAddress;
var
  MarketInfo: TDexMarketInfo;
  Ok: Boolean;
begin
  if (Param.Principal.Compare(TAddress.Zero) <> 0) and (Param.Principal.Compare(Sender) <> 0) then
  begin
    MarketInfo := GetMarketInfo(Db, Param.TradeToken, Param.QuoteToken);
    Ok := MarketInfo.Valid;
    if not Ok then
      Exit(TAddress.Zero); // Should be EDexTradeMarketNotExists
    if not IsMarketGrantedToAgent(Db, Param.Principal, Sender, MarketInfo.MarketId) then
      Exit(TAddress.Zero); // Should be EDexTradeMarketNotGranted
    Result := Param.Principal;
  end
  else
    Result := Sender;
end;

function DoCancelOrder(SendHash: THash; Owner: TAddress): TArray<TAccountBlock>;
var
  TradeBlockData: TBytes;
  SendBlockItem: TAccountBlock;
begin
  TradeBlockData := ABIDexTrade.PackMethod(MethodNameDexTradeInnerCancelOrderBySendHash, [SendHash, Owner]);
  SendBlockItem.AccountAddress := AddressDexFund;
  SendBlockItem.ToAddress := AddressDexTrade;
  SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
  SendBlockItem.TokenId := ViteTokenId;
  SendBlockItem.Amount := TBigInteger.Create(0);
  SendBlockItem.Data := TradeBlockData;
  Result := [SendBlockItem];
end;

function ValidPrice(const Price: string; IsFork: Boolean): Boolean;
var
  Pr: Extended;
  Idx: Integer;
begin
  if Length(Price) = 0 then
    Exit(False);

  try
    Pr := StrToFloat(Price);
    if Pr <= 0 then
      Exit(False);
  except
    Exit(False);
  end;

  if not CheckPriceChar(Price) then
    Exit(False);

  Idx := Pos('.', Price);
  if Idx > 0 then
  begin
    if Idx - 1 > PriceIntMaxLen then
      Exit(False);
    if Length(Price) - Idx > PriceDecimalMaxLen then
      Exit(False);
  end
  else if IsFork and (Length(Price) > PriceIntMaxLen) then
    Exit(False);

  Result := True;
end;

function MaxTotalFeeRate(Order: TDexOrder): Int32;
var
  TakerRate: Int32;
  MakerRate: Int32;
begin
  TakerRate := Order.TakerFeeRate + Order.TakerOperatorFeeRate;
  MakerRate := Order.MakerFeeRate + Order.MakerOperatorFeeRate;
  Result := Math.Max(TakerRate, MakerRate);
end;

function GenerateHeightPoint(Db: IVmDb): TUpgradePoint;
var
  LatestSb: TSnapshotBlock;
begin
  LatestSb := Db.LatestSnapshotBlock;
  Result := NewHeightPoint(LatestSb.Height);
end;

function IsDexFeeFork(Db: IVmDb): Boolean;
begin
  Result := IsDexFeeUpgrade(Db.LatestSnapshotBlock.Height);
end;

function IsStemFork(Db: IVmDb): Boolean;
begin
  Result := IsStemUpgrade(Db.LatestSnapshotBlock.Height);
end;

function IsLeafFork(Db: IVmDb): Boolean;
begin
  Result := IsLeafUpgrade(Db.LatestSnapshotBlock.Height);
end;

function IsEarthFork(Db: IVmDb): Boolean;
begin
  Result := IsEarthUpgrade(Db.LatestSnapshotBlock.Height);
end;

function IsDexMiningFork(Db: IVmDb): Boolean;
begin
  Result := IsDexMiningUpgrade(Db.LatestSnapshotBlock.Height);
end;

function IsDexRobotFork(Db: IVmDb): Boolean;
begin
  Result := IsDexRobotUpgrade(Db.LatestSnapshotBlock.Height);
end;

function IsDexStableMarketFork(Db: IVmDb): Boolean;
begin
  Result := IsDexStableMarketUpgrade(Db.LatestSnapshotBlock.Height);
end;

function IsVersion10Upgrade(Db: IVmDb): Boolean;
begin
  Result := CheckFork(Db, IsVersion10Upgrade);
end;

function IsVersion11AddTransferAssetEvent(Db: IVmDb): Boolean;
begin
  Result := CheckFork(Db, IsVersion11Upgrade);
end;

function IsVersion11EnrichOrderFork(Db: IVmDb): Boolean;
begin
  Result := CheckFork(Db, IsVersion11Upgrade);
end;

function IsVersion11DeprecateClearingExpiredOrder(Db: IVmDb): Boolean;
begin
  Result := CheckFork(Db, IsVersion11Upgrade);
end;

function IsVersion12Upgrade(Db: IVmDb): Boolean;
begin
  Result := CheckFork(Db, IsVersion12Upgrade);
end;

function ValidOperatorFeeRate(FeeRate: Int32): Boolean;
begin
  Result := (FeeRate >= 0) and (FeeRate <= MaxOperatorFeeRate);
end;

function CheckPriceChar(const Price: string): Boolean;
var
  C: Char;
begin
  for C in Price do
  begin
    if (C <> '.') and ((Byte(C) < Byte('0')) or (Byte(C) > Byte('9'))) then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

function GetDexTokenSymbol(TokenInfo: TDexTokenInfo): string;
var
  IndexStr: string;
begin
  if (TokenInfo.Symbol = 'VITE') or (TokenInfo.Symbol = 'VCP') or (TokenInfo.Symbol = 'VX') then
    Result := TokenInfo.Symbol
  else
  begin
    IndexStr := IntToStr(TokenInfo.Index);
    while Length(IndexStr) < 3 do
      IndexStr := '0' + IndexStr;
    Result := Format('%s-%s', [TokenInfo.Symbol, IndexStr]);
  end;
end;

function IsAdvancedLimitOrder(Order: TDexOrder; EnrichOrderFork: Boolean): Boolean;
begin
  Result := EnrichOrderFork and ((Order.OrderType = PostOnly) or (Order.OrderType = FillOrKill) or (Order.OrderType = ImmediateOrCancel));
end;

function IsMarketOrder(Order: TDexOrder; EnrichOrderFork: Boolean): Boolean;
begin
  Result := EnrichOrderFork and (Order.OrderType = Market);
end;

function MapToAmountWithTokens(FeeSumMap: TDictionary<TTokenTypeId, TBigInteger>): TArray<TAmountWithToken>;
var
  TokenId: TTokenTypeId;
  Amount: TBigInteger;
  Item: TAmountWithToken;
begin
  SetLength(Result, FeeSumMap.Count);
  var I := 0;
  for TokenId in FeeSumMap.Keys do
  begin
    Amount := FeeSumMap[TokenId];
    Item.Token := TokenId;
    Item.Amount := Amount;
    Item.Deleted := False;
    Result[I] := Item;
    Inc(I);
  end;
end;

end.
