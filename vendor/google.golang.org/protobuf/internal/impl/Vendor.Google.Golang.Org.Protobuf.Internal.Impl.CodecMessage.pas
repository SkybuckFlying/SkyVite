unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecMessage;

interface

uses
  System.SysUtils, System.Rtti, System.Generics.Collections, System.Generics.Defaults,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Encoding.Messageset,
  Vendor.Google.Golang.Org.Protobuf.Internal.Order,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  PCoderMessageInfo = ^TCoderMessageInfo;
  TCoderMessageInfo = record
    Methods: TMethods;
    OrderedCoderFields: TArray<PCoderFieldInfo>;
    DenseCoderFields: TArray<PCoderFieldInfo>;
    CoderFields: TDictionary<TFieldNumber, PCoderFieldInfo>;
    SizecacheOffset: TOffset;
    UnknownOffset: TOffset;
    UnknownPtrKind: Boolean;
    ExtensionOffset: TOffset;
    NeedsInitCheck: Boolean;
    IsMessageSet: Boolean;
    NumRequiredFields: UInt8;
  end;

  PCoderFieldInfo = ^TCoderFieldInfo;
  TCoderFieldInfo = record
    Funcs: TPointerCoderFuncs;
    MI: TMessageInfo;
    FT: TRttiType;
    Validation: TValidationInfo;
    Num: TFieldNumber;
    Offset: TOffset;
    Wiretag: UInt64;
    Tagsize: Integer;
    IsPointer: Boolean;
    IsRequired: Boolean;
  end;

  TMessageInfoHelper = class helper for TMessageInfo
  public
    procedure MakeCoderMethods(T: TRttiType; const SI: TStructInfo);
    function GetUnknownBytes(P: TPointer): PBytes;
    function MutableUnknownBytes(P: TPointer): PBytes;
  end;

implementation

procedure TMessageInfoHelper.MakeCoderMethods(T: TRttiType; const SI: TStructInfo);
var
  Fields: IFieldDescriptors;
  I: Integer;
  FD: IFieldDescriptor;
  FS: TFieldInfo;
  IsOneof: Boolean;
  FT: TRttiType;
  Wiretag: UInt64;
  FieldOffset: TOffset;
  Funcs: TPointerCoderFuncs;
  ChildMessage: TMessageInfo;
  CF: PCoderFieldInfo;
  OD: IOneofDescriptor;
  MaxDense: TFieldNumber;
begin
  Self.SizecacheOffset := InvalidOffset;
  Self.UnknownOffset := InvalidOffset;
  Self.ExtensionOffset := InvalidOffset;

  if SI.SizecacheOffset.IsValid and (SI.SizecacheType = SizecacheType) then
    Self.SizecacheOffset := SI.SizecacheOffset;
  if SI.UnknownOffset.IsValid and ((SI.UnknownType = UnknownFieldsAType) or (SI.UnknownType = UnknownFieldsBType)) then
  begin
    Self.UnknownOffset := SI.UnknownOffset;
    Self.UnknownPtrKind := SI.UnknownType.IsPointer;
  end;
  if SI.ExtensionOffset.IsValid and (SI.ExtensionType = ExtensionFieldsType) then
    Self.ExtensionOffset := SI.ExtensionOffset;

  Self.CoderFields := TDictionary<TFieldNumber, PCoderFieldInfo>.Create;
  Fields := Self.Desc.Fields;
  for I := 0 to Fields.Len - 1 do
  begin
    FD := Fields.Get(I);
    FS := SI.FieldsByNumber[FD.Number];
    IsOneof := (FD.ContainingOneof <> nil) and not FD.ContainingOneof.IsSynthetic;
    if IsOneof then
      FS := SI.OneofsByName[FD.ContainingOneof.Name];
    FT := FS.Type_;

    if not FD.IsPacked then
      Wiretag := TProtowire.EncodeTag(FD.Number, WireTypes[FD.Kind])
    else
      Wiretag := TProtowire.EncodeTag(FD.Number, TWireType.BytesType);

    FieldOffset := InvalidOffset;
    ChildMessage := nil;
    Funcs := Default(TPointerCoderFuncs);

    if FT = nil then
    begin
      // Skip missing fields in simplified implementation
    end
    else if IsOneof then
      FieldOffset := OffsetOf(FS, Self.Exporter)
    else if FD.IsWeak then
    begin
      FieldOffset := SI.WeakOffset;
      Funcs := MakeWeakMessageFieldCoder(FD);
    end
    else
    begin
      FieldOffset := OffsetOf(FS, Self.Exporter);
      FieldCoder(FD, FT, ChildMessage, Funcs);
    end;

    New(CF);
    CF.Num := FD.Number;
    CF.Offset := FieldOffset;
    CF.Wiretag := Wiretag;
    CF.FT := FT;
    CF.Tagsize := TProtowire.SizeVarint(Wiretag);
    CF.Funcs := Funcs;
    CF.MI := ChildMessage;
    // CF.Validation := NewFieldValidationInfo(Self, SI, FD, FT);
    CF.IsPointer := (FD.Cardinality = TCardinality.Repeated) or FD.HasPresence;
    CF.IsRequired := FD.Cardinality = TCardinality.Required;

    Self.OrderedCoderFields := Self.OrderedCoderFields + [CF];
    Self.CoderFields.Add(CF.Num, CF);
  end;

  for I := 0 to Self.Desc.Oneofs.Len - 1 do
  begin
    OD := Self.Desc.Oneofs.Get(I);
    if not OD.IsSynthetic then
      Self.InitOneofFieldCoders(OD, SI);
  end;

  if TMessageset.IsMessageSet(Self.Desc) then
  begin
    if not Self.ExtensionOffset.IsValid then
      raise Exception.CreateFmt('%s: MessageSet with no extensions field', [Self.Desc.FullName]);
    if not Self.UnknownOffset.IsValid then
      raise Exception.CreateFmt('%s: MessageSet with no unknown field', [Self.Desc.FullName]);
    Self.IsMessageSet := True;
  end;

  TArray.Sort<PCoderFieldInfo>(Self.OrderedCoderFields, TDelegatedComparer<PCoderFieldInfo>.Construct(
    function(const L, R: PCoderFieldInfo): Integer
    begin
      Result := L.Num - R.Num;
    end));

  MaxDense := 0;
  for CF in Self.OrderedCoderFields do
  begin
    if (CF.Num >= 16) and (CF.Num >= 2 * MaxDense) then
      break;
    MaxDense := CF.Num;
  end;
  SetLength(Self.DenseCoderFields, MaxDense + 1);
  for CF in Self.OrderedCoderFields do
  begin
    if CF.Num >= Length(Self.DenseCoderFields) then
      break;
    Self.DenseCoderFields[CF.Num] := CF;
  end;

  Self.NeedsInitCheck := NeedsInitCheck(Self.Desc);
  // ... rest of method flags setup
end;

function TMessageInfoHelper.GetUnknownBytes(P: TPointer): PBytes;
begin
  if Self.UnknownPtrKind then
    Result := P.Apply(Self.UnknownOffset).BytesPtr^
  else
    Result := P.Apply(Self.UnknownOffset).Bytes;
end;

function TMessageInfoHelper.MutableUnknownBytes(P: TPointer): PBytes;
var
  BP: ^PBytes;
begin
  if Self.UnknownPtrKind then
  begin
    BP := P.Apply(Self.UnknownOffset).BytesPtr;
    if BP^ = nil then
      New(BP^);
    Result := BP^;
  end
  else
    Result := P.Apply(Self.UnknownOffset).Bytes;
end;

end.
