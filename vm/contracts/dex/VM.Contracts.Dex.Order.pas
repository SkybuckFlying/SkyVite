unit VM.Contracts.Dex.Order;

interface

uses
  System.SysUtils,
  VM.Contracts.Dex.Proto;

const
  Pending = 0;
  PartialExecuted = 1;
  FullyExecuted = 2;
  Cancelled = 3;
  NewFailed = 4;

  CancelledByUser = 0;
  CancelledByMarket = 1;
  CancelledOnTimeout = 2;
  PartialExecutedUserCancelled = 3;
  PartialExecutedCancelledByMarket = 4;
  PartialExecutedCancelledOnTimeout = 5;
  UnknownCancelledOnTimeout = 6;
  CancelledByPostOnlyMatched = 7;
  CancelledByFillOrKillNotFilled = 8;
  CancelledByExceedMarketOrderAmtThreshold = 9;

  Limited = 0;
  Market = 1;
  PostOnly = 2;
  FillOrKill = 3;
  ImmediateOrCancel = 4;

  OrderIdBytesLength = 22;

type
  TOrder = class(TProtoOrder)
  public
    function Serialize: TBytes;
    procedure DeSerialize(const AOrderData: TBytes);
    function SerializeCompact: TBytes;
    procedure DeSerializeCompact(const AOrderData, AOrderId: TBytes);
    procedure RenderOrderById(const AOrderId: TBytes);
  end;

function PriceCompare(const A, B: TBytes): Integer;

implementation

uses
  VM.Contracts.Dex.Utils;

{ TOrder }

function TOrder.Serialize: TBytes;
begin
  Self.MarketId := 0;
  Self.Side := False;
  Self.Price := nil;
  Self.Timestamp := 0;
  Result := Self.ToBytes;
end;

procedure TOrder.DeSerialize(const AOrderData: TBytes);
var
  LOrder: TProtoOrder;
begin
  LOrder := TProtoOrder.FromBytes(AOrderData);
  Self.Assign(LOrder);
  RenderOrderById(Self.Id);
end;

function TOrder.SerializeCompact: TBytes;
begin
  Self.Id := nil;
  Result := Serialize;
end;

procedure TOrder.DeSerializeCompact(const AOrderData, AOrderId: TBytes);
var
  LOrder: TProtoOrder;
begin
  LOrder := TProtoOrder.FromBytes(AOrderData);
  Self.Assign(LOrder);
  Self.Id := AOrderId;
  RenderOrderById(AOrderId);
end;

procedure TOrder.RenderOrderById(const AOrderId: TBytes);
var
  LMarketId: Int32;
  LSide: Boolean;
  LPriceBytes: TBytes;
  LTimestamp: Int64;
begin
  DeComposeOrderId(AOrderId, LMarketId, LSide, LPriceBytes, LTimestamp);
  Self.MarketId := LMarketId;
  Self.Side := LSide;
  Self.Price := LPriceBytes;
  Self.Timestamp := LTimestamp;
end;

function PriceCompare(const A, B: TBytes): Integer;
begin
  Result := CompareMem(A, B, Min(Length(A), Length(B)));
  if Result = 0 then
    Result := Length(A) - Length(B);
end;

end.
