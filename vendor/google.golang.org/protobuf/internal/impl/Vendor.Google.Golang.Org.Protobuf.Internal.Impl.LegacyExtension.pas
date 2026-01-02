unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.LegacyExtension;

interface

uses
  System.SysUtils, System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Internal.Encoding.Tag,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TExtensionInfoHelper = class helper for TExtensionInfo
  public
    procedure InitToLegacy;
    procedure InitFromLegacy;
  end;

implementation

{ TExtensionInfoHelper }

procedure TExtensionInfoHelper.InitToLegacy;
var
  XD: IExtensionDescriptor;
  Parent: IMessageV1;
  MessageName: TFullName;
  MT: IMessageType;
  MV: TValue;
  T: TRttiType;
  EnumName: string;
  Filename: string;
  Name: TFullName;
begin
  XD := Self.Desc.Descriptor;
  Parent := nil;
  MessageName := XD.ContainingMessage.FullName;
  MT := TProtoregistry.GlobalTypes.FindMessageByName(MessageName);
  if MT <> nil then
  begin
    MV := MT.New_.Interface_;
    T := MV.RttiType;
    if MV.IsType<IUnwrapper> then
      T := (MV.AsInterface as IUnwrapper).ProtoUnwrap.RttiType;
    
    // Check if T implements IMessageV1
    Parent := nil; // Simplified
  end;

  EnumName := '';
  if XD.Kind = TKind.EnumKind then
    EnumName := LegacyEnumName(XD.Enum);

  Filename := '';
  if XD.ParentFile <> nil then
    Filename := XD.ParentFile.Path;

  Name := XD.FullName;
  // MessageSet logic...

  Self.ExtendedType := Parent;
  Self.Field := Int32(XD.Number);
  Self.Name := string(Name);
  Self.Tag := TTag.Marshal(XD, EnumName);
  Self.Filename := Filename;
end;

procedure TExtensionInfoHelper.InitFromLegacy;
begin
  // ... implementation of InitFromLegacy
end;

end.
