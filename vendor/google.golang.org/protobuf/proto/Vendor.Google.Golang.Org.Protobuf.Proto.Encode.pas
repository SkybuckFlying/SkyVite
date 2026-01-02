unit Vendor.Google.Golang.Org.Protobuf.Proto.Encode;

interface

uses
  System.SysUtils, Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TMarshalOptions = record
    AllowPartial: Boolean;
    Deterministic: Boolean;
    UseCachedSize: Boolean;
    function Marshal(M: IMessage): TTuple<TBytes, Error>;
  end;

function Marshal(M: IMessage): TTuple<TBytes, Error>;

implementation

function Marshal(M: IMessage): TTuple<TBytes, Error>;
begin
  Result := Default(TMarshalOptions).Marshal(M);
end;

function TMarshalOptions.Marshal(M: IMessage): TTuple<TBytes, Error>;
begin
  // Implementation of Marshal
  Result := Default(TTuple<TBytes, Error>);
end;

end.
