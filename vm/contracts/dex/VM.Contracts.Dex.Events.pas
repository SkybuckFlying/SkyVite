unit Vm.Contracts.Dex.DexEvents;

interface

uses
  System.SysUtils, System.Classes,
  Common.Types.Hash, Vm.Contracts.Dex.Proto.DexProto;

type
  IDexEvent = interface
    ['{A7E4E2D8-338A-462E-A41E-2722816945F0}']
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TNewOrderEvent = record
    NewOrderInfo: TDexProtoNewOrderInfo;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TOrderUpdateEvent = record
    OrderUpdateInfo: TDexProtoOrderUpdateInfo;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TTransactionEvent = record
    Transaction: TDexProtoTransaction;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TTokenEvent = record
    TokenInfo: TDexProtoTokenInfo;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TMarketEvent = record
    MarketInfo: TDexProtoMarketInfo;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TPeriodJobWithBizEvent = record
    PeriodJobForBiz: TDexProtoPeriodJobForBiz;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TFeeDividendEvent = record
    FeeDividendForVxHolder: TDexProtoFeeDividendForVxHolder;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TOperatorFeeDividendEvent = record
    OperatorFeeDividend: TDexProtoOperatorFeeDividend;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TMinedVxForTradeFeeEvent = record
    MinedVxForFee: TDexProtoMinedVxForFee;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TMinedVxForInviteeFeeEvent = record
    MinedVxForFee: TDexProtoMinedVxForFee;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TMinedVxForStakingEvent = record
    MinedVxForStaking: TDexProtoMinedVxForStaking;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TMinedVxForOperationEvent = record
    MinedVxForOperation: TDexProtoMinedVxForOperation;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TInviteRelationEvent = record
    InviteRelation: TDexProtoInviteRelation;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TSettleMakerMinedVxEvent = record
    SettleMakerMinedVx: TDexProtoSettleMakerMinedVx;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TGrantMarketToAgentEvent = record
    MarketAgentRelation: TDexProtoMarketAgentRelation;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TRevokeMarketFromAgentEvent = record
    MarketAgentRelation: TDexProtoMarketAgentRelation;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TBurnViteEvent = record
    BurnVite: TDexProtoBurnVite;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TTransferAssetEvent = record
    TransferAsset: TDexProtoTransferAsset;
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

  TErrEvent = class(Exception, IDexEvent)
  private
    FError: Exception;
  public
    constructor Create(const Msg: string);
    function GetTopicId: THash;
    function ToDataBytes: TBytes;
    function FromBytes(Data: TBytes): Exception;
  end;

function FromNameToHash(const Name: string): THash;

implementation

uses
  Common.Helper;

const
  NewOrderEventName = 'newOrderEvent';
  OrderUpdateEventName = 'orderUpdateEvent';
  TxEventName = 'txEvent';
  TokenEventName = 'tokenEvent';
  MarketEventName = 'marketEvent';
  PeriodJobWithBizEventName = 'periodWithBizEvent';
  FeeDividendForVxHolderEventName = 'feeDividendForVxHolderEvent';
  OperatorFeeDividendEventName = 'brokerFeeDividendEvent';
  MinedVxForTradeFeeEventName = 'minedVxForTradeFeeEvent';
  MinedVxForInviteeFeeEventName = 'minedVxForInviteeFeeEvent';
  MinedVxForStakingEventName = 'minedVxForPledgeEvent';
  MinedVxForOperationEventName = 'minedVxForOperation';
  InviteRelationEventName = 'inviteRelationEvent';
  SettleMakerMinedVxEventName = 'settleMakerMinedVxEvent';
  GrantMarketToAgentEventName = 'grantMarketToAgentEvent';
  RevokeMarketFromAgentEventName = 'revokeMarketFromAgentEvent';
  BurnViteEventName = 'burnViteEvent';
  TransferAssetEventName = 'transferAssetEvent';
  ErrEventName = 'errEvent';

function FromNameToHash(const Name: string): THash;
var
  Hs: THash;
begin
  Hs.SetBytes(RightPadBytes(TEncoding.UTF8.GetBytes(Name), HashSize));
  Result := Hs;
end;

{ TNewOrderEvent }

function TNewOrderEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(NewOrderEventName);
end;

function TNewOrderEvent.ToDataBytes: TBytes;
begin
  Result := NewOrderInfo.Serialize;
end;

function TNewOrderEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  NewOrderInfo.Deserialize(Data);
end;

{ TOrderUpdateEvent }

function TOrderUpdateEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(OrderUpdateEventName);
end;

function TOrderUpdateEvent.ToDataBytes: TBytes;
begin
  Result := OrderUpdateInfo.Serialize;
end;

function TOrderUpdateEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  OrderUpdateInfo.Deserialize(Data);
end;

{ TTransactionEvent }

function TTransactionEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(TxEventName);
end;

function TTransactionEvent.ToDataBytes: TBytes;
begin
  Result := Transaction.Serialize;
end;

function TTransactionEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  Transaction.Deserialize(Data);
end;

{ TTokenEvent }

function TTokenEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(TokenEventName);
end;

function TTokenEvent.ToDataBytes: TBytes;
begin
  Result := TokenInfo.Serialize;
end;

function TTokenEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  TokenInfo.Deserialize(Data);
end;

{ TMarketEvent }

function TMarketEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(MarketEventName);
end;

function TMarketEvent.ToDataBytes: TBytes;
begin
  Result := MarketInfo.Serialize;
end;

function TMarketEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  MarketInfo.Deserialize(Data);
end;

{ TPeriodJobWithBizEvent }

function TPeriodJobWithBizEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(PeriodJobWithBizEventName);
end;

function TPeriodJobWithBizEvent.ToDataBytes: TBytes;
begin
  Result := PeriodJobForBiz.Serialize;
end;

function TPeriodJobWithBizEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  PeriodJobForBiz.Deserialize(Data);
end;

{ TFeeDividendEvent }

function TFeeDividendEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(FeeDividendForVxHolderEventName);
end;

function TFeeDividendEvent.ToDataBytes: TBytes;
begin
  Result := FeeDividendForVxHolder.Serialize;
end;

function TFeeDividendEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  FeeDividendForVxHolder.Deserialize(Data);
end;

{ TOperatorFeeDividendEvent }

function TOperatorFeeDividendEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(OperatorFeeDividendEventName);
end;

function TOperatorFeeDividendEvent.ToDataBytes: TBytes;
begin
  Result := OperatorFeeDividend.Serialize;
end;

function TOperatorFeeDividendEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  OperatorFeeDividend.Deserialize(Data);
end;

{ TMinedVxForTradeFeeEvent }

function TMinedVxForTradeFeeEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(MinedVxForTradeFeeEventName);
end;

function TMinedVxForTradeFeeEvent.ToDataBytes: TBytes;
begin
  Result := MinedVxForFee.Serialize;
end;

function TMinedVxForTradeFeeEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  MinedVxForFee.Deserialize(Data);
end;

{ TMinedVxForInviteeFeeEvent }

function TMinedVxForInviteeFeeEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(MinedVxForInviteeFeeEventName);
end;

function TMinedVxForInviteeFeeEvent.ToDataBytes: TBytes;
begin
  Result := MinedVxForFee.Serialize;
end;

function TMinedVxForInviteeFeeEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  MinedVxForFee.Deserialize(Data);
end;

{ TMinedVxForStakingEvent }

function TMinedVxForStakingEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(MinedVxForStakingEventName);
end;

function TMinedVxForStakingEvent.ToDataBytes: TBytes;
begin
  Result := MinedVxForStaking.Serialize;
end;

function TMinedVxForStakingEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  MinedVxForStaking.Deserialize(Data);
end;

{ TMinedVxForOperationEvent }

function TMinedVxForOperationEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(MinedVxForOperationEventName);
end;

function TMinedVxForOperationEvent.ToDataBytes: TBytes;
begin
  Result := MinedVxForOperation.Serialize;
end;

function TMinedVxForOperationEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  MinedVxForOperation.Deserialize(Data);
end;

{ TInviteRelationEvent }

function TInviteRelationEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(InviteRelationEventName);
end;

function TInviteRelationEvent.ToDataBytes: TBytes;
begin
  Result := InviteRelation.Serialize;
end;

function TInviteRelationEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  InviteRelation.Deserialize(Data);
end;

{ TSettleMakerMinedVxEvent }

function TSettleMakerMinedVxEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(SettleMakerMinedVxEventName);
end;

function TSettleMakerMinedVxEvent.ToDataBytes: TBytes;
begin
  Result := SettleMakerMinedVx.Serialize;
end;

function TSettleMakerMinedVxEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  SettleMakerMinedVx.Deserialize(Data);
end;

{ TGrantMarketToAgentEvent }

function TGrantMarketToAgentEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(GrantMarketToAgentEventName);
end;

function TGrantMarketToAgentEvent.ToDataBytes: TBytes;
begin
  Result := MarketAgentRelation.Serialize;
end;

function TGrantMarketToAgentEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  MarketAgentRelation.Deserialize(Data);
end;

{ TRevokeMarketFromAgentEvent }

function TRevokeMarketFromAgentEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(RevokeMarketFromAgentEventName);
end;

function TRevokeMarketFromAgentEvent.ToDataBytes: TBytes;
begin
  Result := MarketAgentRelation.Serialize;
end;

function TRevokeMarketFromAgentEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  MarketAgentRelation.Deserialize(Data);
end;

{ TBurnViteEvent }

function TBurnViteEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(BurnViteEventName);
end;

function TBurnViteEvent.ToDataBytes: TBytes;
begin
  Result := BurnVite.Serialize;
end;

function TBurnViteEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  BurnVite.Deserialize(Data);
end;

{ TTransferAssetEvent }

function TTransferAssetEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(TransferAssetEventName);
end;

function TTransferAssetEvent.ToDataBytes: TBytes;
begin
  Result := TransferAsset.Serialize;
end;

function TTransferAssetEvent.FromBytes(Data: TBytes): Exception;
begin
  Result := nil;
  TransferAsset.Deserialize(Data);
end;

{ TErrEvent }

constructor TErrEvent.Create(const Msg: string);
begin
  inherited Create(Msg);
  FError := Exception.Create(Msg);
end;

function TErrEvent.GetTopicId: THash;
begin
  Result := FromNameToHash(ErrEventName);
end;

function TErrEvent.ToDataBytes: TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(FError.Message);
end;

function TErrEvent.FromBytes(Data: TBytes): Exception;
begin
  FError := Exception.Create(TEncoding.UTF8.GetString(Data));
  Result := nil;
end;

end.
