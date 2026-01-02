unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.Checkinit;

interface

uses
  System.SysUtils, System.SyncObjs,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect,
  Vendor.Google.Golang.Org.Protobuf.Runtime.Protoiface;

type
  TMessageInfoHelper = class helper for TMessageInfo
  public
    function CheckInitialized(const In: TCheckInitializedInput): TCheckInitializedOutput;
    function CheckInitializedPointer(P: TPointer): Error;
    function IsInitExtensions(Ext: PMap<Int32, TExtensionField>): Error;
  end;

function NeedsInitCheck(MD: IMessageDescriptor): Boolean;
function NeedsInitCheckLocked(MD: IMessageDescriptor): Boolean;

implementation

var
  NeedsInitCheckMu: TCriticalSection;
  NeedsInitCheckMap: TSyncMap; // Assuming a thread-safe map implementation

function TMessageInfoHelper.CheckInitialized(const In: TCheckInitializedInput): TCheckInitializedOutput;
var
  P: TPointer;
  MS: TMessageState;
  MRW: TMessageReflectWrapper;
begin
  if In.Message is TMessageState then
  begin
    MS := TMessageState(In.Message);
    P := MS.Pointer;
  end
  else
  begin
    MRW := TMessageReflectWrapper(In.Message);
    P := MRW.Pointer;
  end;
  Result := Default(TCheckInitializedOutput);
  Result.Error := CheckInitializedPointer(P);
end;

function TMessageInfoHelper.CheckInitializedPointer(P: TPointer): Error;
var
  F: PCoderFieldInfo;
  E: PMap<Int32, TExtensionField>;
  FPtr: TPointer;
begin
  Self.Init;
  if not Self.NeedsInitCheck then
    Exit(nil);

  if P.IsNil then
  begin
    for F in Self.OrderedCoderFields do
    begin
      if F.IsRequired then
        Exit(TErrors.RequiredNotSet(string(Self.Desc.Fields.ByNumber(F.Num).FullName)));
    end;
    Exit(nil);
  end;

  if Self.ExtensionOffset.IsValid then
  begin
    E := P.Apply(Self.ExtensionOffset).Extensions;
    Result := IsInitExtensions(E);
    if Result <> nil then
      Exit(Result);
  end;

  for F in Self.OrderedCoderFields do
  begin
    if not F.IsRequired and (F.Funcs.IsInit = nil) then
      continue;
    FPtr := P.Apply(F.Offset);
    if F.IsPointer and FPtr.Elem.IsNil then
    begin
      if F.IsRequired then
        Exit(TErrors.RequiredNotSet(string(Self.Desc.Fields.ByNumber(F.Num).FullName)));
      continue;
    end;
    if F.Funcs.IsInit = nil then
      continue;
    Result := F.Funcs.IsInit(FPtr, F);
    if Result <> nil then
      Exit(Result);
  end;
  Result := nil;
end;

function TMessageInfoHelper.IsInitExtensions(Ext: PMap<Int32, TExtensionField>): Error;
var
  X: TExtensionField;
  EI: PExtensionFieldInfo;
  V: TValue;
begin
  if Ext = nil then
    Exit(nil);
  for X in Ext.Values do
  begin
    EI := GetExtensionFieldInfo(X.Type_);
    if EI.Funcs.IsInit = nil then
      continue;
    V := X.Value;
    if not V.IsValid then
      continue;
    Result := EI.Funcs.IsInit(V);
    if Result <> nil then
      Exit(Result);
  end;
  Result := nil;
end;

function NeedsInitCheck(MD: IMessageDescriptor): Boolean;
var
  V: TValue;
  Has: Boolean;
begin
  if NeedsInitCheckMap.Load(MD, V) then
  begin
    if V.IsType<Boolean> then
      Exit(V.AsBoolean);
  end;
  NeedsInitCheckMu.Enter;
  try
    Result := NeedsInitCheckLocked(MD);
  finally
    NeedsInitCheckMu.Leave;
  end;
end;

function NeedsInitCheckLocked(MD: IMessageDescriptor): Boolean;
var
  V: TValue;
  Has: Boolean;
  I: Integer;
  FD, FDVal: IFieldDescriptor;
  FMD: IMessageDescriptor;
begin
  if NeedsInitCheckMap.Load(MD, V) then
  begin
    if V.IsType<Boolean> then
      Exit(V.AsBoolean);
    Exit(False);
  end;
  NeedsInitCheckMap.Store(MD, TValue.Empty); // avoid cycles
  Result := False;
  try
    if MD.RequiredNumbers.Len > 0 then
    begin
      Result := True;
      Exit;
    end;
    if MD.ExtensionRanges.Len > 0 then
    begin
      Result := True;
      Exit;
    end;
    for I := 0; i < MD.Fields.Len; i++ do
    begin
      FD := MD.Fields.Get(I);
      if FD.IsMap then
        FDVal := FD.MapValue
      else
        FDVal := FD;
      FMD := FDVal.Message;
      if (FMD <> nil) and NeedsInitCheckLocked(FMD) then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    NeedsInitCheckMap.Store(MD, Result);
  end;
end;

initialization
  NeedsInitCheckMu := TCriticalSection.Create;
  NeedsInitCheckMap := TSyncMap.Create;

finalization
  NeedsInitCheckMu.Free;
  NeedsInitCheckMap.Free;

end.
