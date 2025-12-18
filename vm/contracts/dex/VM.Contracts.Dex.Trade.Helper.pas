unit VM.Contracts.Dex.Trade.Helper;

interface

uses
  System.SysUtils, System.Generics.Collections,
  GoVite.Types, GoVite.Interfaces,
  VM.Contracts.Dex.Proto, VM.Contracts.Dex.Storage, VM.Contracts.Dex.Matcher;

const
  CleanExpireOrdersMaxCount = 200;

var
  marketByMarketIdPrefix: TBytes;
  tradeTimestampKey: TBytes;
  sendHashMapOrderIdPrefixKey: TBytes;

function CleanExpireOrders(const ADB: IVmDb; const AOrderIds: TBytes): TTuple<TDictionary<TAddress, TDictionary<Boolean, TAccountSettle>>, TMarketInfo>;
function GetMarketInfoById(const ADB: IVmDb; AMarketId: Int32): TMarketInfo;
procedure SaveMarketInfoById(const ADB: IVmDb; AMarketInfo: TMarketInfo);
function GetMarketInfoKeyById(AMarketId: Int32): TBytes;
procedure SetTradeTimestamp(const ADB: IVmDb; ATimestamp: Int64);
function GetTradeTimestamp(const ADB: IVmDb): Int64;
procedure SaveHashMapOrderId(const ADB: IVmDb; const ASendHash, AOrderId: TBytes);
function GetOrderIdByHash(const ADB: IVmDb; const ASendHash: TBytes): TBytes;
procedure DeleteHashMapOrderId(const ADB: IVmDb; const ASendHash: TBytes);
function GetHashMapOrderIdKey(const ASendHash: TBytes): TBytes;
procedure TryUpdateTimestamp(const ADB: IVmDb; ATimestamp: Int64; APreHash: THash);

implementation

uses
  VM.Contracts.Dex.Order, VM.Contracts.Dex.Utils;

initialization
  marketByMarketIdPrefix := TEncoding.UTF8.GetBytes('mkIf:');
  tradeTimestampKey := TEncoding.UTF8.GetBytes('ttmsp:');
  sendHashMapOrderIdPrefixKey := TEncoding.UTF8.GetBytes('hmId:');

function CleanExpireOrders(const ADB: IVmDb; const AOrderIds: TBytes): TTuple<TDictionary<TAddress, TDictionary<Boolean, TAccountSettle>>, TMarketInfo>;
var
  LMatcher: TMatcher;
  LMarketId: Int32;
  LCurrentTime: Int64;
  LExpiredMakers: TList<TOrder>;
  LOrderId: TBytes;
  LMkId: Int32;
  LOrder: TOrder;
begin
  LCurrentTime := GetTradeTimestamp(ADB);
  if LCurrentTime = 0 then
    raise Exception.Create(NotSetTimestampErr);

  LMarketId := 0;
  LExpiredMakers := TList<TOrder>.Create;
  try
    LMatcher := nil;
    try
      for var I := 0 to (Length(AOrderIds) div OrderIdBytesLength) - 1 do
      begin
        LOrderId := Copy(AOrderIds, I * OrderIdBytesLength + 1, OrderIdBytesLength);
        DeComposeOrderId(LOrderId, LMkId);
        if LMarketId = 0 then
          LMarketId := LMkId
        else if LMkId <> LMarketId then
          raise Exception.Create(MultiMarketsInOneActionErr);

        if not Assigned(LMatcher) then
          LMatcher := TMatcher.Create(ADB, LMarketId);

        try
          LOrder := LMatcher.GetOrderById(LOrderId);
        except
          on E: Exception do
            if E.Message = OrderNotExistsErr then
              Continue
            else
              raise;
        end;

        if FilterTimeout(ADB, LOrder) then
          LExpiredMakers.Add(LOrder);
      end;

      if Assigned(LMatcher) and (LExpiredMakers.Count > 0) then
      begin
        LMatcher.HandleModifiedMakers(LExpiredMakers);
        Result := TTuple<TDictionary<TAddress, TDictionary<Boolean, TAccountSettle>>, TMarketInfo>.Create(LMatcher.GetFundSettles, LMatcher.MarketInfo);
      end
      else
      begin
        Result := Default(TTuple<TDictionary<TAddress, TDictionary<Boolean, TAccountSettle>>, TMarketInfo>);
      end;
    finally
      if Assigned(LMatcher) then
        LMatcher.Free;
    end;
  finally
    LExpiredMakers.Free;
  end;
end;
// ... more implementations ...
end.
