unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecExtension;

interface

uses
  System.SysUtils, System.SyncObjs, System.SyncWait,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  PExtensionFieldInfo = ^TExtensionFieldInfo;
  TExtensionFieldInfo = record
    Wiretag: UInt64;
    Tagsize: Integer;
    UnmarshalNeedsValue: Boolean;
    Funcs: TValueCoderFuncs;
    Validation: TValidationInfo;
  end;

  TLazyExtensionValue = class
  private
    FAtomicOnce: UInt32;
    FMu: TCriticalSection;
    FXi: PExtensionFieldInfo;
    FValue: TValue;
    FB: TBytes;
    FFn: TFunc<TValue>;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TExtensionField = record
    Typ: IExtensionType;
    Value: TValue;
    Lazy: TLazyExtensionValue;
    procedure AppendLazyBytes(XT: IExtensionType; XI: PExtensionFieldInfo; Num: TFieldNumber; WTyp: TWireType; B: TBytes);
    function CanLazy(XT: IExtensionType): Boolean;
    procedure LazyInit;
    procedure Set_(T: IExtensionType; V: TValue);
    procedure SetLazy(T: IExtensionType; Fn: TFunc<TValue>);
    function GetValue: TValue;
    function GetType: IExtensionType;
    function IsSet: Boolean;
  end;

function GetExtensionFieldInfo(XT: IExtensionType): PExtensionFieldInfo;
function LegacyLoadExtensionFieldInfo(XT: IExtensionType): PExtensionFieldInfo;
function MakeExtensionFieldInfo(XD: IExtensionDescriptor): PExtensionFieldInfo;
function IsLazy(M: IMessage; FD: IFieldDescriptor): Boolean;

implementation

var
  LegacyExtensionFieldInfoCache: TSyncMap;

function GetExtensionFieldInfo(XT: IExtensionType): PExtensionFieldInfo;
var
  XI: TExtensionInfo;
begin
  if XT is TExtensionInfo then
  begin
    XI := TExtensionInfo(XT);
    XI.LazyInit;
    Result := XI.Info;
    Exit;
  end;
  Result := LegacyLoadExtensionFieldInfo(XT);
end;

function LegacyLoadExtensionFieldInfo(XT: IExtensionType): PExtensionFieldInfo;
var
  V: TValue;
  E: PExtensionFieldInfo;
begin
  if LegacyExtensionFieldInfoCache.Load(XT, V) then
    Exit(V.AsPointer);
  E := MakeExtensionFieldInfo(XT.TypeDescriptor);
  if LegacyExtensionFieldInfoCache.LoadOrStore(XT, TValue.From<Pointer>(E), V) then
  begin
    // Free E? The Go code doesn't seem to worry about the leak if LoadOrStore fails
    Exit(V.AsPointer);
  end;
  Result := E;
end;

function MakeExtensionFieldInfo(XD: IExtensionDescriptor): PExtensionFieldInfo;
var
  Wiretag: UInt64;
begin
  if not XD.IsPacked then
    Wiretag := TProtowire.EncodeTag(XD.Number, WireTypes[XD.Kind])
  else
    Wiretag := TProtowire.EncodeTag(XD.Number, TWireType.BytesType);

  New(Result);
  Result.Wiretag := Wiretag;
  Result.Tagsize := TProtowire.SizeVarint(Wiretag);
  Result.Funcs := EncoderFuncsForValue(XD);

  case XD.Kind of
    TKind.MessageKind, TKind.GroupKind, TKind.EnumKind:
      Result.UnmarshalNeedsValue := True;
  else
    if XD.Cardinality = TCardinality.Repeated then
      Result.UnmarshalNeedsValue := True;
  end;
end;

{ TLazyExtensionValue }

constructor TLazyExtensionValue.Create;
begin
  FMu := TCriticalSection.Create;
end;

destructor TLazyExtensionValue.Destroy;
begin
  FMu.Free;
  inherited;
end;

{ TExtensionField }

procedure TExtensionField.AppendLazyBytes(XT: IExtensionType; XI: PExtensionFieldInfo; Num: TFieldNumber; WTyp: TWireType; B: TBytes);
begin
  if Lazy = nil then
    Lazy := TLazyExtensionValue.Create;
  Typ := XT;
  Lazy.FXi := XI;
  Lazy.FB := TProtowire.AppendTag(Lazy.FB, Num, WTyp);
  Lazy.FB := Lazy.FB + B;
end;

function TExtensionField.CanLazy(XT: IExtensionType): Boolean;
begin
  if Typ = nil then
    Exit(True);
  if (Typ = XT) and (Lazy <> nil) and (TInterlocked.Read(Lazy.FAtomicOnce) = 0) then
    Exit(True);
  Result := False;
end;

procedure TExtensionField.LazyInit;
var
  B: TBytes;
  Val: TValue;
  Tag: UInt64;
  N, TagLen: Integer;
  Num: TFieldNumber;
  WTyp: TWireType;
  Out_: TUnmarshalOutput;
  Err: Error;
begin
  Lazy.FMu.Enter;
  try
    if TInterlocked.Read(Lazy.FAtomicOnce) = 1 then
      Exit;
    if Lazy.FXi <> nil then
    begin
      B := Lazy.FB;
      Val := Typ.New_;
      while Length(B) > 0 do
      begin
        if B[0] < $80 then
        begin
          Tag := B[0];
          TagLen := 1;
        end
        else if (Length(B) >= 2) and (B[1] < 128) then
        begin
          Tag := (B[0] and $7F) or (UInt64(B[1]) shl 7);
          TagLen := 2;
        end
        else
        begin
          Tag := TProtowire.ConsumeVarint(B, N);
          if N < 0 then
            raise Exception.Create('bad tag in lazy extension decoding');
          TagLen := N;
        end;
        B := Copy(B, TagLen, MaxInt);
        Num := TFieldNumber(Tag shr 3);
        WTyp := TWireType(Tag and 7);
        Val := Lazy.FXi.Funcs.Unmarshal(B, Val, Num, WTyp, LazyUnmarshalOptions, Out_, Err);
        if Err <> nil then
          raise Exception.Create('decode failure in lazy extension decoding');
        B := Copy(B, Out_.N, MaxInt);
      end;
      Lazy.FValue := Val;
    end
    else
      Lazy.FValue := Lazy.FFn();
    Lazy.FXi := nil;
    Lazy.FFn := nil;
    Lazy.FB := nil;
    TInterlocked.Exchange(Lazy.FAtomicOnce, 1);
  finally
    Lazy.FMu.Leave;
  end;
end;

procedure TExtensionField.Set_(T: IExtensionType; V: TValue);
begin
  Typ := T;
  Value := V;
  Lazy := nil;
end;

procedure TExtensionField.SetLazy(T: IExtensionType; Fn: TFunc<TValue>);
begin
  Typ := T;
  Lazy := TLazyExtensionValue.Create;
  Lazy.FFn := Fn;
end;

function TExtensionField.GetValue: TValue;
begin
  if Lazy <> nil then
  begin
    if TInterlocked.Read(Lazy.FAtomicOnce) = 0 then
      LazyInit;
    Exit(Lazy.FValue);
  end;
  Result := Value;
end;

function TExtensionField.GetType: IExtensionType;
begin
  Result := Typ;
end;

function TExtensionField.IsSet: Boolean;
begin
  Result := Typ <> nil;
end;

function IsLazy(M: IMessage; FD: IFieldDescriptor): Boolean;
var
  MI: TMessageInfo;
  P: TPointer;
  XD: IExtensionTypeDescriptor;
  XT: IExtensionType;
  Ext: PMap<Int32, TExtensionField>;
  F: TExtensionField;
begin
  if M is TMessageState then
  begin
    MI := TMessageState(M).MessageInfo;
    P := TMessageState(M).Pointer;
  end
  else if M is TMessageReflectWrapper then
  begin
    MI := TMessageReflectWrapper(M).MessageInfo;
    P := TMessageReflectWrapper(M).Pointer;
  end
  else
    Exit(False);

  if not Supports(FD, IExtensionTypeDescriptor, XD) then
    Exit(False);

  XT := XD.Type_;
  Ext := MI.ExtensionMap(P);
  if Ext = nil then
    Exit(False);

  if not Ext.TryGetValue(Int32(FD.Number), F) then
    Exit(False);

  Result := (F.Typ = XT) and (F.Lazy <> nil) and (TInterlocked.Read(F.Lazy.FAtomicOnce) = 0);
end;

initialization
  LegacyExtensionFieldInfoCache := TSyncMap.Create;

finalization
  LegacyExtensionFieldInfoCache.Free;

end.
