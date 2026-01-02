unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.DescInit;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protodesc.Types,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Internal.Filedesc,
  Vendor.Google.Golang.Org.Protobuf.Internal.Strs,
  Vendor.Google.Golang.Org.Protobuf.Types.Descriptorpb;

type
  TDescsByNameHelper = class helper for TDescsByName
  public
    function InitEnumDeclarations(ParaEds: TArray<PEnumDescriptorProto>; ParaParent: IDescriptor; ParaSb: TStrBuilder): TArray<TEnum>;
    function InitMessagesDeclarations(ParaMds: TArray<PDescriptorProto>; ParaParent: IDescriptor; ParaSb: TStrBuilder): TArray<TMessage>;
    function InitExtensionDeclarations(ParaXds: TArray<PFieldDescriptorProto>; ParaParent: IDescriptor; ParaSb: TStrBuilder): TArray<TExtension>;
    function InitServiceDeclarations(ParaSds: TArray<PServiceDescriptorProto>; ParaParent: IDescriptor; ParaSb: TStrBuilder): TArray<TService>;
    // ... other init methods
    
    function MakeBase(ParaChild, ParaParent: IDescriptor; const ParaName: string; ParaIdx: Integer; ParaSb: TStrBuilder): TBaseL0;
  end;

implementation

{ TDescsByNameHelper }

function TDescsByNameHelper.InitEnumDeclarations(ParaEds: TArray<PEnumDescriptorProto>; ParaParent: IDescriptor; ParaSb: TStrBuilder): TArray<TEnum>;
begin
  // Implementation
  SetLength(Result, 0);
end;

function TDescsByNameHelper.InitMessagesDeclarations(ParaMds: TArray<PDescriptorProto>; ParaParent: IDescriptor; ParaSb: TStrBuilder): TArray<TMessage>;
begin
  // Implementation
  SetLength(Result, 0);
end;

function TDescsByNameHelper.InitExtensionDeclarations(ParaXds: TArray<PFieldDescriptorProto>; ParaParent: IDescriptor; ParaSb: TStrBuilder): TArray<TExtension>;
begin
  // Implementation
  SetLength(Result, 0);
end;

function TDescsByNameHelper.InitServiceDeclarations(ParaSds: TArray<PServiceDescriptorProto>; ParaParent: IDescriptor; ParaSb: TStrBuilder): TArray<TService>;
begin
  // Implementation
  SetLength(Result, 0);
end;

function TDescsByNameHelper.MakeBase(ParaChild, ParaParent: IDescriptor; const ParaName: string; ParaIdx: Integer; ParaSb: TStrBuilder): TBaseL0;
begin
  // Implementation
  Result := Default(TBaseL0);
end;

end.
