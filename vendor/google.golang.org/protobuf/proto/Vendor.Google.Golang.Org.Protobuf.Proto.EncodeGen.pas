unit Vendor.Google.Golang.Org.Protobuf.Proto.EncodeGen;

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Proto.Encode;

type
  TMarshalOptionsHelper = record helper for TMarshalOptions
  public
    function MarshalSingular(B: TBytes; FD: IFieldDescriptor; V: TValue): TTuple<TBytes, Error>;
  end;

implementation

function TMarshalOptionsHelper.MarshalSingular(B: TBytes; FD: IFieldDescriptor; V: TValue): TTuple<TBytes, Error>;
begin
  // switch-case logic for marshal singular
  Result := Default(TTuple<TBytes, Error>);
end;

end.
