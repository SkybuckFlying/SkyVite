unit Vm.Contracts.ContractsDexTrade;

interface

uses
  Common.Types.Address Common.Types.Hash Common.Types.TokenTypeId,
  Interfaces.VmDb Interfaces.Core.AccountBlock Interfaces.Core.ContractMeta,
  System.SysUtils System.Classes System.Generics.Collections,
  Vm.Abi.Abi Vm.Contracts.Abi.AbiDexTrade Vm.Contracts.Abi.AbiDexFund Vm.Contracts.Contracts Vm.Util.Util,
  VM.Contracts.Contracts,
  VM.Contracts.Contracts.Asset,
  VM.Contracts.Contracts.Dex.Fund,
  VM.Contracts.Contracts.Governance,
  VM.Contracts.Contracts.Quota,
  VM.Contracts.Contracts.Test,
  Vm.Contracts.Dex.Dex Vm.Contracts.Dex.Proto.DexProto,
  VM.Contracts.Params,
  VM.Contracts.Reward.Test;

type
  TMethodDexTradePlaceOrder = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexTradeCancelOrder = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexTradeSyncNewMarket = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexTradeClearExpiredOrders = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexTradeCancelOrderByTransactionHash = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

  TMethodDexTradeInnerCancelOrderBySendHash = class(TInterfacedObject, IBuiltinContractMethod)
  private
    FMethodName: string;
  public
    constructor Create(const MethodName: string);
    function GetFee(Block: TAccountBlock): TBigInteger;
    function GetRefundData(SendBlock: TAccountBlock; SbHeight: UInt64): TPair<TBytes, Boolean>;
    function GetSendQuota(Data: TBytes; GasTable: TQuotaTable): UInt64;
    function GetReceiveQuota(GasTable: TQuotaTable): UInt64;
    function DoSend(Db: IVmDb; Block: TAccountBlock): Exception;
    function DoReceive(Db: IVmDb; Block: TAccountBlock; SendBlock: TAccountBlock; Vm: IVmEnvironment): TArray<TAccountBlock>;
  end;

function OnPlaceOrderFailed(Db: IVmDb; Order: TDexOrder; MarketInfo: TDexMarketInfo): TArray<TAccountBlock>;
function HandleCancelOrderById(Db: IVmDb; OrderId: TBytes; Operator: TAddress; const Method: string; Block, SendBlock: TAccountBlock): TArray<TAccountBlock>;
function HandleSettleActions(Db: IVmDb; Block: TAccountBlock; FundSettles: TDictionary<TAddress, TDictionary<Boolean, TDexProtoAccountSettle>>; FeeSettles: TDictionary<TAddress, TDexProtoFeeSettle>; MarketInfo: TDexMarketInfo): TArray<TAccountBlock>;

implementation

uses
  System.Math;

var
  TradeLogger: ILogger;

function OnPlaceOrderFailed(Db: IVmDb; Order: TDexOrder; MarketInfo: TDexMarketInfo): TArray<TAccountBlock>;
var
  AccountSettle: TDexProtoAccountSettle;
  FundSettle: TDexProtoFundSettle;
  SettleActions: TDexProtoSettleActions;
  SettleData: TBytes;
  DexSettleBlockData: TBytes;
  SettleMethod: string;
  SendBlockItem: TAccountBlock;
begin
  AccountSettle := TDexProtoAccountSettle.Create;
  case Order.Side of
    False: // buy
      begin
        AccountSettle.IsTradeToken := False;
        AccountSettle.ReleaseLocked := TBigInteger.Add(Order.Amount, Order.LockedBuyFee);
      end;
    True: // sell
      begin
        AccountSettle.IsTradeToken := True;
        AccountSettle.ReleaseLocked := Order.Quantity;
      end;
  end;

  FundSettle := TDexProtoFundSettle.Create;
  FundSettle.Address := Order.Address;
  FundSettle.AccountSettles := FundSettle.AccountSettles + [AccountSettle];

  SettleActions := TDexProtoSettleActions.Create;
  SettleActions.FundActions := SettleActions.FundActions + [FundSettle];
  SettleActions.TradeToken := MarketInfo.TradeToken;
  SettleActions.QuoteToken := MarketInfo.QuoteToken;

  SettleData := SettleActions.Serialize;

  SettleMethod := MethodNameDexFundSettleOrdersV2;
  if not Dex.IsLeafFork(Db) then
    SettleMethod := MethodNameDexFundSettleOrders;

  DexSettleBlockData := ABIDataDexFund.PackMethod(SettleMethod, [SettleData]);

  SendBlockItem.AccountAddress := AddressDexTrade;
  SendBlockItem.ToAddress := AddressDexFund;
  SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
  SendBlockItem.TokenId := ViteTokenId;
  SendBlockItem.Amount := TBigInteger.Create(0);
  SendBlockItem.Data := DexSettleBlockData;
  Result := [SendBlockItem];
end;

function HandleCancelOrderById(Db: IVmDb; OrderId: TBytes; Operator: TAddress; const Method: string; Block, SendBlock: TAccountBlock): TArray<TAccountBlock>;
var
  Order: TDexOrder;
  MarketId: Integer;
  Matcher: TDexMatcher;
  AppendBlocks: TArray<TAccountBlock>;
begin
  MarketId := Dex.DeComposeOrderId(OrderId).Item1;
  Matcher := Dex.NewMatcher(Db, MarketId);
  Order := Matcher.GetOrderById(OrderId);

  if Order.Address.Bytes = nil then // Check if Order is valid
    Exit(HandleDexReceiveErr(TradeLogger, Method, EDexInvalidOrderHash.Create('invalid order hash'), SendBlock));

  if (Operator.Compare(BytesToAddress(Order.Address)) <> 0) and (Operator.Compare(BytesToAddress(Order.Agent)) <> 0) then
    Exit(HandleDexReceiveErr(TradeLogger, Method, EDexCancelOrderOwnerInvalid.Create('cancel order owner invalid'), SendBlock));

  if (Order.Status <> Dex.Pending) and (Order.Status <> Dex.PartialExecuted) then
    Exit(HandleDexReceiveErr(TradeLogger, Method, EDexCancelOrderInvalidStatus.Create('cancel order invalid status'), SendBlock));

  Matcher.CancelOrderById(Order);
  AppendBlocks := HandleSettleActions(Db, Block, Matcher.GetFundSettles, nil, Matcher.MarketInfo);
  if Length(AppendBlocks) > 0 then
    Result := AppendBlocks
  else
    Exit(HandleDexReceiveErr(TradeLogger, Method, Exception.Create('HandleSettleActions failed'), SendBlock));
end;

function HandleSettleActions(Db: IVmDb; Block: TAccountBlock; FundSettles: TDictionary<TAddress, TDictionary<Boolean, TDexProtoAccountSettle>>; FeeSettles: TDictionary<TAddress, TDexProtoFeeSettle>; MarketInfo: TDexMarketInfo): TArray<TAccountBlock>;
var
  SettleActions: TDexProtoSettleActions;
  FundActions: TArray<TDexProtoFundSettle>;
  Address: TAddress;
  AccountSettleMap: TDictionary<Boolean, TDexProtoAccountSettle>;
  AccountSettles: TArray<TDexProtoAccountSettle>;
  AccountSettle: TDexProtoAccountSettle;
  UserFundSettle: TDexProtoFundSettle;
  FeeActions: TArray<TDexProtoFeeSettle>;
  FeeSettle: TDexProtoFeeSettle;
  SettleData: TBytes;
  DexSettleBlockData: TBytes;
  SettleMethod: string;
  SendBlockItem: TAccountBlock;
begin
  if (FundSettles.Count = 0) and (FeeSettles.Count = 0) then
  begin
    Result := nil;
    Exit;
  end;

  SettleActions := TDexProtoSettleActions.Create;
  if FundSettles.Count > 0 then
  begin
    SetLength(FundActions, 0);
    for Address in FundSettles.Keys do
    begin
      AccountSettleMap := FundSettles[Address];
      SetLength(AccountSettles, 0);
      for AccountSettle in AccountSettleMap.Values do
        AccountSettles := AccountSettles + [AccountSettle];
      TArray.Sort<TDexProtoAccountSettle>(AccountSettles, TComparer<TDexProtoAccountSettle>.Construct(function(const L, R: TDexProtoAccountSettle): Integer
      begin
        Result := L.Compare(R);
      end));

      UserFundSettle := TDexProtoFundSettle.Create;
      UserFundSettle.Address := Address.Bytes;
      UserFundSettle.AccountSettles := AccountSettles;
      FundActions := FundActions + [UserFundSettle];
    end;
    TArray.Sort<TDexProtoFundSettle>(FundActions, TComparer<TDexProtoFundSettle>.Construct(function(const L, R: TDexProtoFundSettle): Integer
    begin
      Result := L.Compare(R);
    end));
    SettleActions.FundActions := FundActions;
  end;

  if FeeSettles.Count > 0 then
  begin
    SetLength(FeeActions, 0);
    for FeeSettle in FeeSettles.Values do
      FeeActions := FeeActions + [FeeSettle];
    TArray.Sort<TDexProtoFeeSettle>(FeeActions, TComparer<TDexProtoFeeSettle>.Construct(function(const L, R: TDexProtoFeeSettle): Integer
    begin
      Result := L.Compare(R);
    end));
    SettleActions.FeeActions := FeeActions;
  end;

  SettleActions.TradeToken := MarketInfo.TradeToken;
  SettleActions.QuoteToken := MarketInfo.QuoteToken;

  SettleData := SettleActions.Serialize;

  SettleMethod := MethodNameDexFundSettleOrdersV2;
  if not Dex.IsLeafFork(Db) then
    SettleMethod := MethodNameDexFundSettleOrders;

  DexSettleBlockData := ABIDataDexFund.PackMethod(SettleMethod, [SettleData]);

  SendBlockItem.AccountAddress := Block.AccountAddress;
  SendBlockItem.ToAddress := AddressDexFund;
  SendBlockItem.BlockType := Common.VitePb.AccountBlock.TBlockType.SendCall;
  SendBlockItem.TokenId := ViteTokenId;
  SendBlockItem.Amount := TBigInteger.Create(0);
  SendBlockItem.Data := DexSettleBlockData;
  Result := [SendBlockItem];
end;

initialization
  TradeLogger := TLogger.Create;

end.
