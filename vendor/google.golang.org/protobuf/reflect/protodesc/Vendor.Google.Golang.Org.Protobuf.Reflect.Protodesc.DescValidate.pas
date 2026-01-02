unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.DescValidate;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils,
  Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc,
  Vendor.Google.Golang.Org.Protobuf.Types.Descriptorpb;

function ValidateEnumDeclarations(ParaEs: TArray<TEnum>; ParaEds: TArray<PEnumDescriptorProto>): Exception;
function ValidateMessageDeclarations(ParaMs: TArray<TMessage>; ParaMds: TArray<PDescriptorProto>): Exception;
function ValidateExtensionDeclarations(ParaXs: TArray<TExtension>; ParaXds: TArray<PFieldDescriptorProto>): Exception;

implementation

function ValidateEnumDeclarations(ParaEs: TArray<TEnum>; ParaEds: TArray<PEnumDescriptorProto>): Exception;
begin
  Result := nil;
  // Implementation
end;

function ValidateMessageDeclarations(ParaMs: TArray<TMessage>; ParaMds: TArray<PDescriptorProto>): Exception;
begin
  Result := nil;
  // Implementation
end;

function ValidateExtensionDeclarations(ParaXs: TArray<TExtension>; ParaXds: TArray<PFieldDescriptorProto>): Exception;
begin
  Result := nil;
  // Implementation
end;

end.
