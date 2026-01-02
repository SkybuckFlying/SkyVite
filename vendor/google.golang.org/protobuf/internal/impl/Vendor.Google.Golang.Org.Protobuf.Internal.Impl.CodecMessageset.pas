unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecMessageset;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Generics.Defaults,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Encoding.Messageset,
  Vendor.Google.Golang.Org.Protobuf.Internal.Errors,
  Vendor.Google.Golang.Org.Protobuf.Internal.Flags;

function SizeMessageSet(MI: TMessageInfo; P: TPointer; const Opts: TMarshalOptions): Integer;
function MarshalMessageSet(MI: TMessageInfo; B: TBytes; P: TPointer; const Opts: TMarshalOptions): TBytes;
function MarshalMessageSetField(MI: TMessageInfo; B: TBytes; const X: TExtensionField; const Opts: TMarshalOptions): TBytes;
function UnmarshalMessageSet(MI: TMessageInfo; B: TBytes; P: TPointer; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;

implementation

function SizeMessageSet(MI: TMessageInfo; P: TPointer; const Opts: TMarshalOptions): Integer;
var
  Ext: TMap<Int32, TExtensionField>;
  X: TExtensionField;
  XI: PExtensionFieldInfo;
  Num: TFieldNumber;
  U: PBytes;
begin
  if not TFlags.ProtoLegacy then Exit(0);

  Result := 0;
  Ext := P.Apply(MI.ExtensionOffset).Extensions^;
  for X in Ext.Values do
  begin
    XI := GetExtensionFieldInfo(X.Type_);
    if not Assigned(XI.Funcs.Size) then continue;
    Num := TProtowire.DecodeTag(XI.Wiretag);
    Result := Result + TMessageset.SizeField(Num);
    Result := Result + XI.Funcs.Size(X.Value, TProtowire.SizeTag(TMessageset.FieldMessage), Opts);
  end;

  U := MI.GetUnknownBytes(P);
  if U <> nil then
    Result := Result + TMessageset.SizeUnknown(U^);
end;

function MarshalMessageSet(MI: TMessageInfo; B: TBytes; P: TPointer; const Opts: TMarshalOptions): TBytes;
var
  Ext: TMap<Int32, TExtensionField>;
  X: TExtensionField;
  Keys: TList<Int32>;
  K: Int32;
  U: PBytes;
  Err: Error;
begin
  if not TFlags.ProtoLegacy then raise Exception.Create('no support for message_set_wire_format');

  Ext := P.Apply(MI.ExtensionOffset).Extensions^;
  if Ext.Count = 1 then
  begin
    for X in Ext.Values do
      B := MarshalMessageSetField(MI, B, X, Opts);
  end
  else if Ext.Count > 1 then
  begin
    Keys := TList<Int32>.Create;
    try
      for K in Ext.Keys do Keys.Add(K);
      Keys.Sort;
      for K in Keys do
        B := MarshalMessageSetField(MI, B, Ext[K], Opts);
    finally
      Keys.Free;
    end;
  end;

  U := MI.GetUnknownBytes(P);
  if U <> nil then
  begin
    B := TMessageset.AppendUnknown(B, U^);
  end;
  Result := B;
end;

function MarshalMessageSetField(MI: TMessageInfo; B: TBytes; const X: TExtensionField; const Opts: TMarshalOptions): TBytes;
var
  XI: PExtensionFieldInfo;
  Num: TFieldNumber;
begin
  XI := GetExtensionFieldInfo(X.Type_);
  Num := TProtowire.DecodeTag(XI.Wiretag);
  B := TMessageset.AppendFieldStart(B, Num);
  B := XI.Funcs.Marshal(B, X.Value, TProtowire.EncodeTag(TMessageset.FieldMessage, TWireType.BytesType), Opts);
  Result := TMessageset.AppendFieldEnd(B);
end;

function UnmarshalMessageSet(MI: TMessageInfo; B: TBytes; P: TPointer; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;
var
  EP: ^TMap<Int32, TExtensionField>;
  Ext: TMap<Int32, TExtensionField>;
  Initialized: Boolean;
begin
  if not TFlags.ProtoLegacy then Exit(TErrors.New('no support for message_set_wire_format'));

  EP := P.Apply(MI.ExtensionOffset).Extensions;
  if EP^ = nil then
    EP^ := TMap<Int32, TExtensionField>.Create;
  Ext := EP^;
  Initialized := True;
  Result := TMessageset.Unmarshal(B, True, function(Num: TFieldNumber; V: TBytes): Error
    var
      O: TUnmarshalOutput;
      U: PBytes;
    begin
      Result := MI.UnmarshalExtension(V, Num, TWireType.BytesType, Ext, Opts, O);
      if Result = ErrUnknown then
      begin
        U := MI.MutableUnknownBytes(P);
        U^ := TProtowire.AppendTag(U^, Num, TWireType.BytesType);
        U^ := U^ + V;
        Exit(nil);
      end;
      if not O.Initialized then
        Initialized := False;
    end);
  Out_.N := Length(B);
  Out_.Initialized := Initialized;
end;

end.
