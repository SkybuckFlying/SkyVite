unit Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect.Proto;

{$MODE DELPHIUNICODE}

interface

uses
  System.SysUtils,
  System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire;

type
  // Forward declarations
  IDescriptor = interface;
  IFileDescriptor = interface;
  IMessageDescriptor = interface;
  IFieldDescriptor = interface;
  IOneofDescriptor = interface;
  IEnumDescriptor = interface;
  IEnumValueDescriptor = interface;
  IServiceDescriptor = interface;
  IMethodDescriptor = interface;
  
  IFileImports = interface;
  IFieldDescriptors = interface;
  IOneofDescriptors = interface;
  IEnumDescriptors = interface;
  IEnumValueDescriptors = interface;
  IServiceDescriptors = interface;
  IMethodDescriptors = interface;
  
  IMessageType = interface;
  IEnumType = interface;
  IExtensionType = interface;
  
  IProtoMessage = interface;
  IMessage = interface;
  IList = interface;
  IMap = interface;

  // Basic types
  TSyntax = (Proto2 = 2, Proto3 = 3);
  TCardinality = (Optional = 1, Required = 2, Repeated = 3);
  TProtoKind = (
    pkBool = 8, pkEnum = 14, pkInt32 = 5, pkSint32 = 17, pkUint32 = 13,
    pkInt64 = 3, pkSint64 = 18, pkUint64 = 4, pkSfixed32 = 15, pkFixed32 = 7,
    pkFloat = 2, pkSfixed64 = 16, pkFixed64 = 6, pkDouble = 1,
    pkString = 9, pkBytes = 12, pkMessage = 11, pkGroup = 10
  );
  
  TFieldNumber = TProtowireNumber;
  TEnumNumber = Integer;
  TName = string;
  TFullName = string;

  // Value struct (Union)
  TProtoValueType = (pvtNil, pvtBool, pvtInt32, pvtInt64, pvtUint32, pvtUint64, pvtFloat32, pvtFloat64, pvtString, pvtBytes, pvtEnum, pvtIface);

  TProtoValue = record
  private
    FType: TProtoValueType;
    FNum: UInt64;
    FStr: string;
    FBytes: TBytes;
    FIface: IInterface;
  public
    function IsValid: Boolean;
    function Interface_: IInterface; // Renamed from Interface
    
    function Bool: Boolean;
    function Int: Int64;
    function Uint: UInt64;
    function Float: Double;
    function String_: string; // Renamed from String
    function Bytes: TBytes;
    function Enum: TEnumNumber;
    function Message: IMessage;
    function List: IList;
    function Map_: IMap; // Renamed from Map
    
    // Constructors (Static methods in Delphi record)
    class function OfBool(ParaV: Boolean): TProtoValue; static;
    class function OfInt32(ParaV: Int32): TProtoValue; static;
    class function OfInt64(ParaV: Int64): TProtoValue; static;
    // ... others
  end;

  // MapKey
  TProtoMapKey = record
    Value: TProtoValue; // Wraps Value
    function Interface_: IInterface;
    function Bool: Boolean;
    function Int: Int64;
    function Uint: UInt64;
    function String_: string;
  end;

  // Interfaces
  IDescriptor = interface
    ['{10000000-0000-0000-0000-000000000001}']
    function ParentFile: IFileDescriptor;
    function Parent: IDescriptor;
    function Index: Integer;
    function Syntax: TSyntax;
    function Name: TName;
    function FullName: TFullName;
    function IsPlaceholder: Boolean;
    function Options: IProtoMessage;
  end;

  IFileDescriptor = interface(IDescriptor)
    ['{10000000-0000-0000-0000-000000000002}']
    function Path: string;
    function Package_: TFullName; // Renamed from Package
    function Imports: IFileImports;
    function Enums: IEnumDescriptors;
    function Messages: IMessageDescriptors;
    function Extensions: IExtensionDescriptors;
    function Services: IServiceDescriptors;
    // SourceLocations
  end;

  IMessageDescriptor = interface(IDescriptor)
    ['{10000000-0000-0000-0000-000000000003}']
    function IsMapEntry: Boolean;
    function Fields: IFieldDescriptors;
    function Oneofs: IOneofDescriptors;
    function ReservedNames: IInterface; // Names interface
    // ...
  end;

  IFieldDescriptor = interface(IDescriptor)
    ['{10000000-0000-0000-0000-000000000004}']
    function Number: TFieldNumber;
    function Cardinality: TCardinality;
    function Kind: TProtoKind;
    function HasJSONName: Boolean;
    function JSONName: string;
    function TextName: string;
    function HasPresence: Boolean;
    function IsExtension: Boolean;
    function HasOptionalKeyword: Boolean;
    function IsWeak: Boolean;
    function IsPacked: Boolean;
    function IsList: Boolean;
    function IsMap: Boolean;
    function MapKey: IFieldDescriptor;
    function MapValue: IFieldDescriptor;
    function HasDefault: Boolean;
    function Default: TProtoValue;
    function DefaultEnumValue: IEnumValueDescriptor;
    function ContainingOneof: IOneofDescriptor;
    function ContainingMessage: IMessageDescriptor;
    function Enum: IEnumDescriptor;
    function Message: IMessageDescriptor;
  end;

  // ... Other descriptors definition (Extension, Enum, Service, Method) ...
  // Simplified for brevity in this step, but assuming they exist for the system to compile.
  IOneofDescriptor = interface(IDescriptor) end;
  IEnumDescriptor = interface(IDescriptor) end;
  IEnumValueDescriptor = interface(IDescriptor) end;
  IServiceDescriptor = interface(IDescriptor) end;
  IMethodDescriptor = interface(IDescriptor) 
    function Input: IMessageDescriptor;
    function Output: IMessageDescriptor;
    function IsStreamingClient: Boolean;
    function IsStreamingServer: Boolean;
  end;
  
  IExtensionDescriptor = IFieldDescriptor;

  // Lists
  IFieldDescriptors = interface
    function Len: Integer;
    function Get(ParaI: Integer): IFieldDescriptor;
    function ByName(ParaS: TName): IFieldDescriptor;
    function ByNumber(ParaN: TFieldNumber): IFieldDescriptor;
  end;
  
  IOneofDescriptors = interface
    function Len: Integer;
    function Get(ParaI: Integer): IOneofDescriptor;
  end;
  
  IEnumDescriptors = interface
    function Len: Integer;
    function Get(ParaI: Integer): IEnumDescriptor;
  end;
  
  IEnumValueDescriptors = interface
    function Len: Integer;
    function Get(ParaI: Integer): IEnumValueDescriptor;
  end;
  
  IMessageDescriptors = interface
    function Len: Integer;
    function Get(ParaI: Integer): IMessageDescriptor;
  end;
  
  IExtensionDescriptors = interface
    function Len: Integer;
    function Get(ParaI: Integer): IExtensionDescriptor;
  end;
  
  IServiceDescriptors = interface
    function Len: Integer;
    function Get(ParaI: Integer): IServiceDescriptor;
  end;
  
  IMethodDescriptors = interface
    function Len: Integer;
    function Get(ParaI: Integer): IMethodDescriptor;
  end;
  
  IFileImports = interface
    function Len: Integer;
    // Get(i) FileImport
  end;

  // Reflection Interfaces
  IProtoMessage = interface
    ['{20000000-0000-0000-0000-000000000001}']
    function ProtoReflect: IMessage;
  end;

  IMessage = interface
    ['{20000000-0000-0000-0000-000000000002}']
    function Descriptor: IMessageDescriptor;
    function Type_: IMessageType; // Renamed from Type
    function New: IMessage;
    function Interface_: IProtoMessage; // Renamed from Interface
    procedure Range(const ParaF: TFunc<IFieldDescriptor, TProtoValue, Boolean>);
    function Has(ParaFd: IFieldDescriptor): Boolean;
    procedure Clear(ParaFd: IFieldDescriptor);
    function Get(ParaFd: IFieldDescriptor): TProtoValue;
    procedure Set_(ParaFd: IFieldDescriptor; ParaV: TProtoValue); // Renamed from Set
    function Mutable(ParaFd: IFieldDescriptor): TProtoValue;
    function NewField(ParaFd: IFieldDescriptor): TProtoValue;
    function WhichOneof(ParaOd: IOneofDescriptor): IFieldDescriptor;
    function GetUnknown: TBytes;
    procedure SetUnknown(ParaB: TBytes);
    function IsValid: Boolean;
    // ProtoMethods method?
  end;

  IList = interface
    ['{20000000-0000-0000-0000-000000000003}']
    function Len: Integer;
    function Get(ParaI: Integer): TProtoValue;
    procedure Set_(ParaI: Integer; ParaV: TProtoValue);
    procedure Append(ParaV: TProtoValue);
    function AppendMutable: TProtoValue;
    procedure Truncate(ParaLen: Integer);
    function NewElement: TProtoValue;
    function IsValid: Boolean;
  end;

  IMap = interface
    ['{20000000-0000-0000-0000-000000000004}']
    function Len: Integer;
    procedure Range(const ParaF: TFunc<TProtoMapKey, TProtoValue, Boolean>);
    function Has(ParaKey: TProtoMapKey): Boolean;
    procedure Clear(ParaKey: TProtoMapKey);
    function Get(ParaKey: TProtoMapKey): TProtoValue;
    procedure Set_(ParaKey: TProtoMapKey; ParaV: TProtoValue);
    function Mutable(ParaKey: TProtoMapKey): TProtoValue;
    function NewValue: TProtoValue;
    function IsValid: Boolean;
  end;

  IMessageType = interface
    function New: IMessage;
    function Zero: IMessage;
    function Descriptor: IMessageDescriptor;
  end;

implementation

{ TProtoValue }

function TProtoValue.IsValid: Boolean;
begin
  Result := FType <> pvtNil;
end;

function TProtoValue.Interface_: IInterface;
begin
  case FType of
    pvtNil: Result := nil;
    pvtBool: Result := nil; // Boolean is not IInterface, boxing needed?
    // In Delphi TValue logic, we return generic TValue or Variant. 
    // Here we return IInterface.
    pvtIface: Result := FIface;
    else Result := nil; // Simplified
  end;
end;

function TProtoValue.Bool: Boolean;
begin
  if FType = pvtBool then Result := (FNum <> 0)
  else raise Exception.Create('type mismatch: bool');
end;

function TProtoValue.Int: Int64;
begin
  if (FType = pvtInt32) or (FType = pvtInt64) then Result := Int64(FNum)
  else raise Exception.Create('type mismatch: int');
end;

function TProtoValue.Uint: UInt64;
begin
  if (FType = pvtUint32) or (FType = pvtUint64) then Result := FNum
  else raise Exception.Create('type mismatch: uint');
end;

function TProtoValue.Float: Double;
begin
  if (FType = pvtFloat32) or (FType = pvtFloat64) then 
    Result := PDouble(@FNum)^ // Reinterpret cast bits
  else raise Exception.Create('type mismatch: float');
end;

function TProtoValue.String_: string;
begin
  if FType = pvtString then Result := FStr
  else raise Exception.Create('type mismatch: string');
end;

function TProtoValue.Bytes: TBytes;
begin
  if FType = pvtBytes then Result := FBytes
  else raise Exception.Create('type mismatch: bytes');
end;

function TProtoValue.Enum: TEnumNumber;
begin
  if FType = pvtEnum then Result := TEnumNumber(FNum)
  else raise Exception.Create('type mismatch: enum');
end;

function TProtoValue.Message: IMessage;
begin
  if (FType = pvtIface) and Supports(FIface, IMessage, Result) then
    Exit;
  raise Exception.Create('type mismatch: message');
end;

function TProtoValue.List: IList;
begin
  if (FType = pvtIface) and Supports(FIface, IList, Result) then
    Exit;
  raise Exception.Create('type mismatch: list');
end;

function TProtoValue.Map_: IMap;
begin
  if (FType = pvtIface) and Supports(FIface, IMap, Result) then
    Exit;
  raise Exception.Create('type mismatch: map');
end;

class function TProtoValue.OfBool(ParaV: Boolean): TProtoValue;
begin
  Result.FType := pvtBool;
  if ParaV then Result.FNum := 1 else Result.FNum := 0;
end;

class function TProtoValue.OfInt32(ParaV: Int32): TProtoValue;
begin
  Result.FType := pvtInt32;
  Result.FNum := UInt64(ParaV);
end;

class function TProtoValue.OfInt64(ParaV: Int64): TProtoValue;
begin
  Result.FType := pvtInt64;
  Result.FNum := UInt64(ParaV);
end;

// ... Implement other 'Of' methods ...

{ TProtoMapKey }

function TProtoMapKey.Bool: Boolean;
begin
  Result := Value.Bool;
end;

function TProtoMapKey.Int: Int64;
begin
  Result := Value.Int;
end;

function TProtoMapKey.Uint: UInt64;
begin
  Result := Value.Uint;
end;

function TProtoMapKey.String_: string;
begin
  Result := Value.String_;
end;

function TProtoMapKey.Interface_: IInterface;
begin
  Result := Value.Interface_;
end;

end.