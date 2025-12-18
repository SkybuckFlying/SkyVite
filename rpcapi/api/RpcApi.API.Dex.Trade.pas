unit RpcApi.Api.DexTrade;

interface

uses
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
  RpcApi.API.Dex.Fund,
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
  TMarketOrderParam = record
    mTradeToken: TTokenTypeId;
    mQuoteToken: TTokenTypeId;
    mSellBegin: Integer;
    mSellEnd: Integer;
    mBuyBegin: Integer;
    mBuyEnd: Integer;
  end;

  TDexTradeApi = class
  private
    mVite: TVite;
    mChain: IChain;
    mLog: ILogger;
  public
    constructor Create(ParaVite: TVite);
    function GetString: string;
    function GetOrderById(const ParaOrderIdStr: string): TRpcOrder;
    function GetOrderBySendHash(const ParaSendHash: THash): TRpcOrder;
    function GetOrdersFromMarket(const ParaTradeToken, ParaQuoteToken: TTokenTypeId; ParaSide: Boolean; ParaBegin, ParaEnd: Integer): TOrdersRes;
    function GetMarketOrders(const ParaParam: TMarketOrderParam): TOrdersRes;
    function GetMarketInfoById(ParaMarketId: Integer): TRpcMarketInfo;
    function GetTimestamp: Int64;
  end;

implementation

uses
  System.NetEncoding;

function GetVmDb(ParaChain: IChain; ParaAddr: TAddress): IVmDb;
begin
  Result := TVmDb.Create(ParaChain, @ParaAddr, nil, nil);
end;

{ TDexTradeApi }

constructor TDexTradeApi.Create(ParaVite: TVite);
begin
  inherited Create;
  mVite := ParaVite;
  mChain := ParaVite.Chain;
  mLog := TLog.New('module', 'rpc_api/dextrade_api');
end;

function TDexTradeApi.GetString: string;
begin
  Result := 'DexTradeApi';
end;

function TDexTradeApi.GetOrderById(const ParaOrderIdStr: string): TRpcOrder;
var
  vOrderId: TBytes;
  vDb: IVmDb;
begin
  vOrderId := TNetEncoding.Base16.Decode(ParaOrderIdStr);
  vDb := GetVmDb(mChain, TAddress.DexTrade);
  Result := InnerGetOrderById(vDb, vOrderId);
end;

function TDexTradeApi.GetOrderBySendHash(const ParaSendHash: THash): TRpcOrder;
var
  vDb: IVmDb;
  vOrderId: TBytes;
  vOk: Boolean;
begin
  vDb := GetVmDb(mChain, TAddress.DexTrade);
  vOk := TDex.GetOrderIdByHash(vDb, ParaSendHash.Bytes, vOrderId);
  if not vOk then
  begin
    raise Exception.Create(SOrderNotExistsErr);
  end;
  Result := InnerGetOrderById(vDb, vOrderId);
end;

function TDexTradeApi.GetOrdersFromMarket(const ParaTradeToken, ParaQuoteToken: TTokenTypeId; ParaSide: Boolean; ParaBegin, ParaEnd: Integer): TOrdersRes;
var
  vFundDb, vTradeDb: IVmDb;
  vLatest, vLatest2: IAccountBlock;
  vMarketInfo: TMarketInfo;
  vOk: Boolean;
  vMatcher: TMatcher;
  vOds: TArray<TOrder>;
  vSize: Integer;
begin
  if ParaEnd - ParaBegin > 10000 then
  begin
    raise Exception.Create('end - begin must be less than 10000');
  end;

  vFundDb := GetVmDb(mChain, TAddress.DexFund);
  vLatest := mChain.GetLatestAccountBlock(TAddress.DexTrade);
  vOk := TDex.GetMarketInfo(vFundDb, ParaTradeToken, ParaQuoteToken, vMarketInfo);
  if not vOk then
  begin
    raise Exception.Create(STradeMarketNotExistsErr);
  end;

  vTradeDb := GetVmDb(mChain, TAddress.DexTrade);
  vMatcher := TMatcher.CreateWithMarketInfo(vTradeDb, vMarketInfo);
  vOds := vMatcher.GetOrdersFromMarket(ParaSide, ParaBegin, ParaEnd, vSize);
  vLatest2 := mChain.GetLatestAccountBlock(TAddress.DexTrade);

  Result.Orders := OrdersToRpc(vOds);
  Result.Size := vSize;
  Result.LatestHashHeight := vLatest.HashHeight;
  Result.Latest2HashHeight := vLatest2.HashHeight;
end;

function TDexTradeApi.GetMarketOrders(const ParaParam: TMarketOrderParam): TOrdersRes;
var
  vFundDb, vTradeDb: IVmDb;
  vLatest, vLatest2: IAccountBlock;
  vMarketInfo: TMarketInfo;
  vOk: Boolean;
  vObs: TArray<TRpcOrder>;
  vMatcher: TMatcher;
  vSellOds, vBuyOds: TArray<TOrder>;
  vSize: Integer;
begin
  if ParaParam.mSellEnd - ParaParam.mSellBegin > 10000 then
  begin
    raise Exception.Create('sell end - begin must be less than 10000');
  end;
  if ParaParam.mBuyEnd - ParaParam.mBuyBegin > 10000 then
  begin
    raise Exception.Create('buy end - begin must be less than 10000');
  end;

  vFundDb := GetVmDb(mChain, TAddress.DexFund);
  vLatest := mChain.GetLatestAccountBlock(TAddress.DexTrade);
  vOk := TDex.GetMarketInfo(vFundDb, ParaParam.mTradeToken, ParaParam.mQuoteToken, vMarketInfo);
  if not vOk then
  begin
    raise Exception.Create(STradeMarketNotExistsErr);
  end;

  vTradeDb := GetVmDb(mChain, TAddress.DexTrade);
  vMatcher := TMatcher.CreateWithMarketInfo(vTradeDb, vMarketInfo);

  if ParaParam.mSellEnd > ParaParam.mSellBegin then
  begin
    vSellOds := vMatcher.GetOrdersFromMarket(True, ParaParam.mSellBegin, ParaParam.mSellEnd, vSize);
    vObs := vObs + OrdersToRpc(vSellOds);
  end;

  if ParaParam.mBuyEnd > ParaParam.mBuyBegin then
  begin
    vBuyOds := vMatcher.GetOrdersFromMarket(False, ParaParam.mBuyBegin, ParaParam.mBuyEnd, vSize);
    vObs := vObs + OrdersToRpc(vBuyOds);
  end;

  vLatest2 := mChain.GetLatestAccountBlock(TAddress.DexTrade);

  Result.Orders := vObs;
  Result.Size := Length(vObs);
  Result.LatestHashHeight := vLatest.HashHeight;
  Result.Latest2HashHeight := vLatest2.HashHeight;
end;

function TDexTradeApi.GetMarketInfoById(ParaMarketId: Integer): TRpcMarketInfo;
var
  vTradeDb: IVmDb;
  vMarketInfo: TMarketInfo;
  vOk: Boolean;
begin
  vTradeDb := GetVmDb(mChain, TAddress.DexTrade);
  vOk := TDex.GetMarketInfoById(vTradeDb, ParaMarketId, vMarketInfo);
  if vOk then
  begin
    Result := MarketInfoToRpc(vMarketInfo);
  end;
end;

function TDexTradeApi.GetTimestamp: Int64;
var
  vTradeDb: IVmDb;
begin
  vTradeDb := GetVmDb(mChain, TAddress.DexTrade);
  Result := TDex.GetTradeTimestamp(vTradeDb);
end;

end.
