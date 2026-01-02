unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.MessageReflect;

interface

uses
  System.SysUtils, System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  TMessageInfoHelper = class helper for TMessageInfo
  public
    procedure MakeReflectFuncs(T: TRttiType; const SI: TStructInfo);
    procedure MakeKnownFieldsFunc(const SI: TStructInfo);
    procedure MakeFieldTypes(const SI: TStructInfo);
  end;

  TExtensionMap = class(TDictionary<Int32, TExtensionField>)
  public
    procedure Range(const F: TFunc<IFieldDescriptor, TValue, Boolean>);
    function Has(XT: IExtensionType): Boolean;
    procedure Clear(XT: IExtensionType);
    function Get(XT: IExtensionType): TValue;
    procedure Set_(XT: IExtensionType; const V: TValue);
    function Mutable(XT: IExtensionType): TValue;
  end;

implementation

{ TMessageInfoHelper }

procedure TMessageInfoHelper.MakeReflectFuncs(T: TRttiType; const SI: TStructInfo);
begin
  Self.MakeKnownFieldsFunc(SI);
  // Self.MakeUnknownFieldsFunc(T, SI);
  // Self.MakeExtensionFieldsFunc(T, SI);
  Self.MakeFieldTypes(SI);
end;

procedure TMessageInfoHelper.MakeKnownFieldsFunc(const SI: TStructInfo);
var
  FDS: IFieldDescriptors;
  I: Integer;
  FD: IFieldDescriptor;
  FS: TFieldInfo;
  IsOneof: Boolean;
  FI: TFieldInfo_; // Avoiding name conflict with TFieldInfo
begin
  FDS := Self.Desc.Fields;
  for I := 0 to FDS.Len - 1 do
  begin
    FD := FDS.Get(I);
    FS := SI.FieldsByNumber[FD.Number];
    IsOneof := (FD.ContainingOneof <> nil) and not FD.ContainingOneof.IsSynthetic;
    // switch-case logic for field info creation...
  end;
end;

procedure TMessageInfoHelper.MakeFieldTypes(const SI: TStructInfo);
begin
  // Implementation of MakeFieldTypes
end;

{ TExtensionMap }

procedure TExtensionMap.Range(const F: TFunc<IFieldDescriptor, TValue, Boolean>);
var
  X: TExtensionField;
  XD: IFieldDescriptor;
begin
  for X in Self.Values do
  begin
    XD := X.Type_.TypeDescriptor;
    if not F(XD, X.Value) then break;
  end;
end;

function TExtensionMap.Has(XT: IExtensionType): Boolean;
var
  X: TExtensionField;
begin
  if not Self.TryGetValue(Int32(XT.TypeDescriptor.Number), X) then Exit(False);
  Result := True; // Simplified
end;

procedure TExtensionMap.Clear(XT: IExtensionType);
begin
  Self.Remove(Int32(XT.TypeDescriptor.Number));
end;

function TExtensionMap.Get(XT: IExtensionType): TValue;
var
  X: TExtensionField;
begin
  if Self.TryGetValue(Int32(XT.TypeDescriptor.Number), X) then
    Exit(X.Value);
  Result := XT.Zero;
end;

procedure TExtensionMap.Set_(XT: IExtensionType; const V: TValue);
var
  X: TExtensionField;
begin
  X.Set_(XT, V);
  Self.AddOrSetValue(Int32(XT.TypeDescriptor.Number), X);
end;

function TExtensionMap.Mutable(XT: IExtensionType): TValue;
begin
  // Implementation of Mutable
  Result := TValue.Empty;
end;

end.
