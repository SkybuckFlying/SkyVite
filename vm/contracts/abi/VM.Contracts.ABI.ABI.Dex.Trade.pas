unit Vm.Contracts.Abi.AbiDexTrade;

interface

uses
  System.SysUtils System.Classes,
  Vm.Abi.Abi,
  VM.Contracts.ABI.ABI.Asset,
  VM.Contracts.ABI.ABI.Dex.Fund,
  VM.Contracts.ABI.ABI.Dex.Fund.Test,
  VM.Contracts.ABI.ABI.Gonvernance,
  VM.Contracts.ABI.ABI.Quota,
  VM.Contracts.ABI.ABI.Test,
  VM.Contracts.ABI.Util;

const
  MethodNameDexTradeNewOrder = 'DexTradeNewOrder';
  MethodNameDexTradeCancelOrder = 'DexTradeCancelOrder';
  MethodNameDexTradeNotifyNewMarket = 'DexTradeNotifyNewMarket';
  MethodNameDexTradeCleanExpireOrders = 'DexTradeCleanExpireOrders';
  MethodNameDexTradeCancelOrderByHash = 'DexTradeCancelOrderByHash';

  MethodNameDexTradePlaceOrder = 'PlaceOrder';
  MethodNameDexTradeCancelOrderV2 = 'CancelOrder';
  MethodNameDexTradeSyncNewMarket = 'SyncNewMarket';
  MethodNameDexTradeClearExpiredOrders = 'ClearExpiredOrders';
  MethodNameDexTradeCancelOrderByTransactionHash = 'CancelOrderByTransactionHash';

  MethodNameDexTradeInnerCancelOrderBySendHash = 'InnerCancelOrderBySendHash';

var
  ABIDataDexTrade: TAbiContract;

implementation

initialization
  ABIDataDexTrade := TAbiContract.JSONToABIContract(TStringStream.Create(
    '[' +
    '{"type":"function","name":"DexTradeNewOrder", "inputs":[{"name":"data","type":"bytes"}]},' +
    '{"type":"function","name":"DexTradeCancelOrder", "inputs":[{"name":"orderId","type":"bytes"}]},' +
    '{"type":"function","name":"DexTradeNotifyNewMarket", "inputs":[{"name":"data","type":"bytes"}]},' +
    '{"type":"function","name":"DexTradeCleanExpireOrders", "inputs":[{"name":"data","type":"bytes"}]},' +
    '{"type":"function","name":"DexTradeCancelOrderByHash", "inputs":[{"name":"sendHash","type":"bytes32"}]},' +
    '{"type":"function","name":"PlaceOrder", "inputs":[{"name":"data","type":"bytes"}]},' +
    '{"type":"function","name":"CancelOrder", "inputs":[{"name":"orderId","type":"bytes"}]},' +
    '{"type":"function","name":"SyncNewMarket", "inputs":[{"name":"data","type":"bytes"}]},' +
    '{"type":"function","name":"ClearExpiredOrders", "inputs":[{"name":"data","type":"bytes"}]},' +
    '{"type":"function","name":"CancelOrderByTransactionHash", "inputs":[{"name":"sendHash","type":"bytes32"}]},' +
    '{"type":"function","name":"InnerCancelOrderBySendHash", "inputs":[{"name":"sendHash","type":"bytes32"}, {"name":"owner","type":"address"}]}' +
    ']'));
end.
