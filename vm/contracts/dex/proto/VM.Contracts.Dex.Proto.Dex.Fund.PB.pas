unit VM.Contracts.Dex.Proto.Dex.Fund.PB;

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
  VM.Contracts.Dex.Proto.Dex.Order.PB;

type
  TAccount = class
  public
    Token: TBytes;
    Available: TBytes;
    Locked: TBytes;
    VxLocked: TBytes;
    VxUnlocking: TBytes;
    CancellingStake: TBytes;
  end;

  TVxUnlock = class
  public
    PeriodId: UInt64;
    Amount: TBytes;
  end;

  TVxUnlocks = class
  public
    Unlocks: TArray<TVxUnlock>;
  end;
  // ... and so on for all the other message types from the .proto file

implementation

end.
