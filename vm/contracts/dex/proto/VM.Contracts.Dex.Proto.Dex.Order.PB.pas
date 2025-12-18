unit VM.Contracts.Dex.Proto.Dex.Order.PB;

interface

uses
  System.SysUtils System.Generics.Collections,
  Vendor.Github.Com.Golang.Protobuf.Proto.Buffer,
  Vendor.Github.Com.Golang.Protobuf.Proto.Defaults,
  Vendor.Github.Com.Golang.Protobuf.Proto.Deprecated,
  Vendor.Github.Com.Golang.Protobuf.Proto.Discard,
  Vendor.Github.Com.Golang.Protobuf.Proto.Extensions,
  Vendor.Github.Com.Golang.Protobuf.Proto.Properties,
  Vendor.Github.Com.Golang.Protobuf.Proto.Proto,
  Vendor.Github.Com.Golang.Protobuf.Proto.Registry,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextDecode,
  Vendor.Github.Com.Golang.Protobuf.Proto.TextEncode,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wire,
  Vendor.Github.Com.Golang.Protobuf.Proto.Wrappers,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Methods,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Proto,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Source,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.SourceGen,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Type,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Value,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.ValuePure,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.ValueUnion,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.ValueUnsafe,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoimpl.Impl,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoimpl.Version,
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
