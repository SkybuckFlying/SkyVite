unit Vendor.Google.Golang.Org.Protobuf.Proto.DecodeGen;

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Proto.Decode;

type
  TUnmarshalOptionsHelper = record helper for TUnmarshalOptions
  public
    function UnmarshalScalar(B: TBytes; WTyp: TWireType; FD: IFieldDescriptor): TTuple<TValue, Integer, Error>;
  end;

implementation

function TUnmarshalOptionsHelper.UnmarshalScalar(B: TBytes; WTyp: TWireType; FD: IFieldDescriptor): TTuple<TValue, Integer, Error>;
begin
  // switch-case logic for unmarshal scalar
  Result := Default(TTuple<TValue, Integer, Error>);
end;

end.
