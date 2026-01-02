unit Vendor.Google.Golang.Org.Protobuf.Proto.ProtoReflect;

{$MODE DELPHIUNICODE}

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

const
  ConstHasProtoMethods = False;

function ProtoMethods(ParaM: IProtoMessage): PProtoMethods;

implementation

function ProtoMethods(ParaM: IProtoMessage): PProtoMethods;
begin
  Result := nil;
end;

end.
