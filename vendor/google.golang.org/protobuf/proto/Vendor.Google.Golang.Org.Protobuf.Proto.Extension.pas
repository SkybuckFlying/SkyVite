unit Vendor.Google.Golang.Org.Protobuf.Proto.Extension;

interface

uses
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

function HasExtension(M: IMessage; XT: IExtensionType): Boolean;
procedure ClearExtension(M: IMessage; XT: IExtensionType);
function GetExtension(M: IMessage; XT: IExtensionType): TValue;
procedure SetExtension(M: IMessage; XT: IExtensionType; const V: TValue);

implementation

function HasExtension(M: IMessage; XT: IExtensionType): Boolean;
begin
  if M = nil then Exit(False);
  Result := M.ProtoReflect.Has(XT.TypeDescriptor);
end;

procedure ClearExtension(M: IMessage; XT: IExtensionType);
begin
  M.ProtoReflect.Clear(XT.TypeDescriptor);
end;

function GetExtension(M: IMessage; XT: IExtensionType): TValue;
begin
  if M = nil then Exit(XT.Zero);
  Result := M.ProtoReflect.Get(XT.TypeDescriptor);
end;

procedure SetExtension(M: IMessage; XT: IExtensionType; const V: TValue);
begin
  M.ProtoReflect.Set_(XT.TypeDescriptor, V);
end;

end.
