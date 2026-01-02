unit Vendor.Google.Golang.Org.Protobuf.Proto.Decode;

interface

uses
  System.SysUtils, Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TUnmarshalOptions = record
    Merge: Boolean;
    AllowPartial: Boolean;
    DiscardUnknown: Boolean;
    Resolver: IExtensionResolver;
    function Unmarshal(B: TBytes; M: IMessage): Error;
  end;

function Unmarshal(B: TBytes; M: IMessage): Error;

implementation

function Unmarshal(B: TBytes; M: IMessage): Error;
begin
  Result := Default(TUnmarshalOptions).Unmarshal(B, M);
end;

function TUnmarshalOptions.Unmarshal(B: TBytes; M: IMessage): Error;
begin
  // Implementation of Unmarshal
  Result := nil;
end;

end.
