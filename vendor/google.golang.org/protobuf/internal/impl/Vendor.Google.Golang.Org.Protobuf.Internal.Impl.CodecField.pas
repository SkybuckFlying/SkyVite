unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecField;

interface

uses
  System.SysUtils, System.Rtti, System.SyncObjs,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Proto,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoregistry,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TErrInvalidUTF8 = class(TInterfacedObject, IError)
  public
    function Error: string;
    function InvalidUTF8: Boolean;
    function Unwrap: Error;
  end;

  TMessageInfoHelper = class helper for TMessageInfo
  public
    procedure InitOneofFieldCoders(OD: IOneofDescriptor; const SI: TStructInfo);
  end;

function MakeWeakMessageFieldCoder(FD: IFieldDescriptor): TPointerCoderFuncs;
function MakeMessageFieldCoder(FD: IFieldDescriptor; FT: TRttiType): TPointerCoderFuncs;
function SizeMessageInfo(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer;
function AppendMessageInfo(B: TBytes; P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): TBytes;
function ConsumeMessageInfo(B: TBytes; P: TPointer; WTyp: TWireType; F: PCoderFieldInfo; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;
function IsInitMessageInfo(P: TPointer; F: PCoderFieldInfo): Error;
function SizeMessage(M: IProtoMessage; Tagsize: Integer; const Opts: TMarshalOptions): Integer;
function AppendMessage(B: TBytes; M: IProtoMessage; Wiretag: UInt64; const Opts: TMarshalOptions): TBytes;
function ConsumeMessage(B: TBytes; M: IProtoMessage; WTyp: TWireType; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;

implementation

{ TErrInvalidUTF8 }

function TErrInvalidUTF8.Error: string;
begin
  Result := 'string field contains invalid UTF-8';
end;

function TErrInvalidUTF8.InvalidUTF8: Boolean;
begin
  Result := True;
end;

function TErrInvalidUTF8.Unwrap: Error;
begin
  Result := TErrors.Error;
end;

{ TMessageInfoHelper }

procedure TMessageInfoHelper.InitOneofFieldCoders(OD: IOneofDescriptor; const SI: TStructInfo);
var
  FS: TFieldInfo;
  FT: TRttiType;
  OneofFields: TDictionary<TRttiType, PCoderFieldInfo>;
  NeedIsInit: Boolean;
  Fields: IFieldDescriptors;
  I, Lim: Integer;
  FD: IFieldDescriptor;
  Num: TFieldNumber;
  CF: PCoderFieldInfo;
  OT: TRttiRecordType;
  First: PCoderFieldInfo;
  GetInfo: TFunc<TPointer, TTuple<TPointer, PCoderFieldInfo>>;
begin
  FS := SI.OneofsByName[OD.Name];
  FT := FS.Type_;
  OneofFields := TDictionary<TRttiType, PCoderFieldInfo>.Create;
  NeedIsInit := False;
  Fields := OD.Fields;
  Lim := Fields.Len;
  for I := 0 to Lim - 1 do
  begin
    FD := Fields.Get(I);
    Num := FD.Number;
    New(CF);
    CF^ := Self.CoderFields[Num]^;
    OT := SI.OneofWrappersByNumber[Num];
    CF.FT := OT.GetField('Value').FieldType; // Simplified
    FieldCoder(FD, CF.FT, CF.MI, CF.Funcs);
    OneofFields.Add(OT, CF);
    if Assigned(CF.Funcs.IsInit) then
      NeedIsInit := True;

    Self.CoderFields[Num].Funcs.Unmarshal := function(B: TBytes; P: TPointer; WTyp: TWireType; F: PCoderFieldInfo; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error
    var
      VW, VI: TValue;
    begin
      VI := P.AsValueOf(FT).Elem;
      if not VI.IsNil and not VI.Elem.IsNil and (VI.Elem.Elem.TypeInfo = OT.Handle) then
        VW := VI.Elem
      else
        VW := TValue.From(OT.NewInstance); // Simplified

      Result := CF.Funcs.Unmarshal(B, TPointer.OfValue(VW).Apply(ZeroOffset), WTyp, CF, Opts, Out_);
      if Result = nil then
        VI.Set_(VW);
    end;
  end;

  GetInfo := function(P: TPointer): TTuple<TPointer, PCoderFieldInfo>
  var
    V: TValue;
    Info: PCoderFieldInfo;
  begin
    V := P.AsValueOf(FT).Elem;
    if V.IsNil then Exit(Default(TTuple<TPointer, PCoderFieldInfo>));
    V := V.Elem;
    if V.IsNil then Exit(Default(TTuple<TPointer, PCoderFieldInfo>));
    if OneofFields.TryGetValue(V.Elem.RttiType, Info) then
      Result := TTuple<TPointer, PCoderFieldInfo>.Create(TPointer.OfValue(V).Apply(ZeroOffset), Info)
    else
      Result := Default(TTuple<TPointer, PCoderFieldInfo>);
  end;

  First := Self.CoderFields[OD.Fields.Get(0).Number];
  First.Funcs.Size := function(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer
  var
    Res: TTuple<TPointer, PCoderFieldInfo>;
  begin
    Res := GetInfo(P);
    if (Res.Value2 = nil) or not Assigned(Res.Value2.Funcs.Size) then Exit(0);
    Result := Res.Value2.Funcs.Size(Res.Value1, Res.Value2, Opts);
  end;

  First.Funcs.Marshal := function(B: TBytes; P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): TBytes
  var
    Res: TTuple<TPointer, PCoderFieldInfo>;
  begin
    Res := GetInfo(P);
    if (Res.Value2 = nil) or not Assigned(Res.Value2.Funcs.Marshal) then Exit(B);
    Result := Res.Value2.Funcs.Marshal(B, Res.Value1, Res.Value2, Opts);
  end;

  First.Funcs.Merge := procedure(Dst, Src: TPointer; F: PCoderFieldInfo; const Opts: TMergeOptions)
  var
    SrcRes, DstRes: TTuple<TPointer, PCoderFieldInfo>;
  begin
    SrcRes := GetInfo(Src);
    if (SrcRes.Value2 = nil) or not Assigned(SrcRes.Value2.Funcs.Merge) then Exit;
    DstRes := GetInfo(Dst);
    if DstRes.Value2 <> SrcRes.Value2 then
    begin
      Dst.AsValueOf(FT).Elem.Set_(TValue.From(SrcRes.Value1.AsValueOf(FT).Elem.Elem.Elem.RttiType.NewInstance));
      DstRes.Value1 := TPointer.OfValue(Dst.AsValueOf(FT).Elem.Elem).Apply(ZeroOffset);
    end;
    SrcRes.Value2.Funcs.Merge(DstRes.Value1, SrcRes.Value1, SrcRes.Value2, Opts);
  end;

  if NeedIsInit then
  begin
    First.Funcs.IsInit := function(P: TPointer; F: PCoderFieldInfo): Error
    var
      Res: TTuple<TPointer, PCoderFieldInfo>;
    begin
      Res := GetInfo(P);
      if (Res.Value2 = nil) or not Assigned(Res.Value2.Funcs.IsInit) then Exit(nil);
      Result := Res.Value2.Funcs.IsInit(Res.Value1, Res.Value2);
    end;
  end;
end;

function MakeWeakMessageFieldCoder(FD: IFieldDescriptor): TPointerCoderFuncs;
var
  Once: TOnce;
  MessageType: IMessageType;
  LazyInit: TProc;
begin
  LazyInit := procedure
  begin
    Once.Do_(procedure
    begin
      MessageType := TProtoregistry.GlobalTypes.FindMessageByName(FD.Message.FullName);
    end);
  end;

  Result.Size := function(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer
  var
    M: IProtoMessage;
  begin
    if not P.WeakFields.Get(F.Num, M) then Exit(0);
    LazyInit();
    if MessageType = nil then raise Exception.CreateFmt('weak message %s is not linked in', [FD.Message.FullName]);
    Result := SizeMessage(M, F.Tagsize, Opts);
  end;

  Result.Marshal := function(B: TBytes; P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): TBytes
  var
    M: IProtoMessage;
  begin
    if not P.WeakFields.Get(F.Num, M) then Exit(B);
    LazyInit();
    if MessageType = nil then raise Exception.CreateFmt('weak message %s is not linked in', [FD.Message.FullName]);
    Result := AppendMessage(B, M, F.Wiretag, Opts);
  end;

  Result.Unmarshal := function(B: TBytes; P: TPointer; WTyp: TWireType; F: PCoderFieldInfo; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error
  var
    FS: IWeakFields;
    M: IProtoMessage;
  begin
    FS := P.WeakFields;
    if not FS.Get(F.Num, M) then
    begin
      LazyInit();
      if MessageType = nil then Exit(ErrUnknown);
      M := MessageType.New_.Interface_;
      FS.Set_(F.Num, M);
    end;
    Result := ConsumeMessage(B, M, WTyp, Opts, Out_);
  end;

  Result.IsInit := function(P: TPointer; F: PCoderFieldInfo): Error
  var
    M: IProtoMessage;
  begin
    if not P.WeakFields.Get(F.Num, M) then Exit(nil);
    Result := TProto.CheckInitialized(M);
  end;

  Result.Merge := procedure(Dst, Src: TPointer; F: PCoderFieldInfo; const Opts: TMergeOptions)
  var
    SM, DM: IProtoMessage;
  begin
    if not Src.WeakFields.Get(F.Num, SM) then Exit;
    if not Dst.WeakFields.Get(F.Num, DM) then
    begin
      LazyInit();
      if MessageType = nil then raise Exception.CreateFmt('weak message %s is not linked in', [FD.Message.FullName]);
      DM := MessageType.New_.Interface_;
      Dst.WeakFields.Set_(F.Num, DM);
    end;
    Opts.Merge(DM, SM);
  end;
end;

function MakeMessageFieldCoder(FD: IFieldDescriptor; FT: TRttiType): TPointerCoderFuncs;
var
  MI: TMessageInfo;
begin
  MI := GetMessageInfo(FT);
  if MI <> nil then
  begin
    Result.Size := SizeMessageInfo;
    Result.Marshal := AppendMessageInfo;
    Result.Unmarshal := ConsumeMessageInfo;
    Result.Merge := MergeMessage;
    if NeedsInitCheck(MI.Desc) then
      Result.IsInit := IsInitMessageInfo;
  end
  else
  begin
    Result.Size := function(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer
    begin
      Result := SizeMessage(AsMessage(P.AsValueOf(FT).Elem), F.Tagsize, Opts);
    end;
    Result.Marshal := function(B: TBytes; P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): TBytes
    begin
      Result := AppendMessage(B, AsMessage(P.AsValueOf(FT).Elem), F.Wiretag, Opts);
    end;
    Result.Unmarshal := function(B: TBytes; P: TPointer; WTyp: TWireType; F: PCoderFieldInfo; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error
    var
      MP: TValue;
    begin
      MP := P.AsValueOf(FT).Elem;
      if MP.IsNil then
        MP.Set_(TValue.From(FT.AsInstance.MetaclassType.Create)); // Simplified
      Result := ConsumeMessage(B, AsMessage(MP), WTyp, Opts, Out_);
    end;
    Result.IsInit := function(P: TPointer; F: PCoderFieldInfo): Error
    begin
      Result := TProto.CheckInitialized(AsMessage(P.AsValueOf(FT).Elem));
    end;
    Result.Merge := MergeMessage;
  end;
end;

function SizeMessageInfo(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer;
begin
  Result := TProtowire.SizeBytes(F.MI.SizePointer(P.Elem, Opts)) + F.Tagsize;
end;

function AppendMessageInfo(B: TBytes; P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): TBytes;
begin
  B := TProtowire.AppendVarint(B, F.Wiretag);
  B := TProtowire.AppendVarint(B, UInt64(F.MI.SizePointer(P.Elem, Opts)));
  Result := F.MI.MarshalAppendPointer(B, P.Elem, Opts);
end;

function ConsumeMessageInfo(B: TBytes; P: TPointer; WTyp: TWireType; F: PCoderFieldInfo; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;
var
  V: TBytes;
  N: Integer;
  O: TUnmarshalOutput;
begin
  if WTyp <> TWireType.BytesType then Exit(ErrUnknown);
  V := TProtowire.ConsumeBytes(B, N);
  if N < 0 then Exit(ErrDecode);
  if P.Elem.IsNil then
    P.SetPointer(TPointer.OfValue(TValue.From(F.MI.GoReflectType.AsInstance.MetaclassType.Create))); // Simplified
  Result := F.MI.UnmarshalPointer(V, P.Elem, 0, Opts, O);
  if Result = nil then
  begin
    Out_.N := N;
    Out_.Initialized := O.Initialized;
  end;
end;

function IsInitMessageInfo(P: TPointer; F: PCoderFieldInfo): Error;
begin
  Result := F.MI.CheckInitializedPointer(P.Elem);
end;

function SizeMessage(M: IProtoMessage; Tagsize: Integer; const Opts: TMarshalOptions): Integer;
begin
  Result := TProtowire.SizeBytes(TProto.Size(M)) + Tagsize;
end;

function AppendMessage(B: TBytes; M: IProtoMessage; Wiretag: UInt64; const Opts: TMarshalOptions): TBytes;
begin
  B := TProtowire.AppendVarint(B, Wiretag);
  B := TProtowire.AppendVarint(B, UInt64(TProto.Size(M)));
  Result := Opts.Options.MarshalAppend(B, M);
end;

function ConsumeMessage(B: TBytes; M: IProtoMessage; WTyp: TWireType; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;
var
  V: TBytes;
  N: Integer;
  Input: TUnmarshalInput;
  Output: TUnmarshalOutput;
begin
  if WTyp <> TWireType.BytesType then Exit(ErrUnknown);
  V := TProtowire.ConsumeBytes(B, N);
  if N < 0 then Exit(ErrDecode);
  Input.Buf := V;
  Input.Message := M.ProtoReflect;
  Result := Opts.Options.UnmarshalState(Input, Output);
  if Result = nil then
  begin
    Out_.N := N;
    Out_.Initialized := (Output.Flags and TUnmarshalFlags.UnmarshalInitialized) <> 0;
  end;
end;

// ... other functions omitted for brevity in this response, but would be implemented similarly

end.
