unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecReflect;

interface

uses
  System.SysUtils, System.Rtti,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire;

function SizeEnum(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer;
function AppendEnum(B: TBytes; P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): TBytes;
function ConsumeEnum(B: TBytes; P: TPointer; WTyp: TWireType; F: PCoderFieldInfo; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;

var
  CoderEnum: TPointerCoderFuncs;

implementation

function SizeEnum(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer;
var
  V: Int64;
begin
  V := P.V.Elem.AsInt64;
  Result := F.Tagsize + TProtowire.SizeVarint(UInt64(V));
end;

function AppendEnum(B: TBytes; P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): TBytes;
var
  V: Int64;
begin
  V := P.V.Elem.AsInt64;
  B := TProtowire.AppendVarint(B, F.Wiretag);
  Result := TProtowire.AppendVarint(B, UInt64(V));
end;

function ConsumeEnum(B: TBytes; P: TPointer; WTyp: TWireType; f: PCoderFieldInfo; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;
var
  V: UInt64;
  N: Integer;
begin
  if WTyp <> TWireType.VarintType then Exit(ErrUnknown);
  V := TProtowire.ConsumeVarint(B, N);
  if N < 0 then Exit(ErrDecode);
  P.V.Elem.Set_(TValue.From<Int64>(Int64(V)));
  Out_.N := N;
  Result := nil;
end;

initialization
  CoderEnum.Size := SizeEnum;
  CoderEnum.Marshal := AppendEnum;
  CoderEnum.Unmarshal := ConsumeEnum;
  // CoderEnum.Merge := MergeEnum;

end.
