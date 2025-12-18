unit VM.Contracts.Dex.Proto.Dex.Order.PB;

interface

uses
  System.SysUtils System.Generics.Collections,
  VM.Contracts.Dex.Proto.Dex.Fund.PB;

type
  TOrder = class
  public
    Id: TBytes;
    Address: TBytes;
    MarketId: Int32;
    Side: Boolean;
    OrderType: Int32;
    Price: TBytes;
    TakerFeeRate: Int32;
    MakerFeeRate: Int32;
    TakerOperatorFeeRate: Int32;
    MakerOperatorFeeRate: Int32;
    Quantity: TBytes;
    Amount: TBytes;
    LockedBuyFee: TBytes;
    Status: Int32;
    CancelReason: Int32;
    ExecutedQuantity: TBytes;
    ExecutedAmount: TBytes;
    ExecutedBaseFee: TBytes;
    ExecutedOperatorFee: TBytes;
    RefundToken: TBytes;
    RefundQuantity: TBytes;
    Timestamp: Int64;
    Agent: TBytes;
    SendHash: TBytes;
    MarketOrderAmtThreshold: TBytes;
  end;

  TSerialNo = class
  public
    No: Int32;
    Timestamp: Int64;
  end;
  // ... and so on for all the other message types from the .proto file

implementation

end.
