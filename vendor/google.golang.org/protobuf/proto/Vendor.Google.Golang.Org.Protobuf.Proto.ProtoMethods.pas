unit Vendor.Google.Golang.Org.Protobuf.Proto.ProtoMethods;

{$MODE DELPHIUNICODE}

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

const
  ConstHasProtoMethods = True;

function ProtoMethods(ParaM: IProtoMessage): PProtoMethods;

implementation

function ProtoMethods(ParaM: IProtoMessage): PProtoMethods;
begin
  Result := ParaM.ProtoMethods;
end;

end.
