unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecGen;

interface

uses
  System.SysUtils, System.Math,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

// This is a truncated version of the generated file for demonstration
// The full file would contain all the scalar type coders.

function SizeBool(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer;
function AppendBool(B: TBytes; P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): TBytes;
function ConsumeBool(B: TBytes; P: TPointer; WTyp: TWireType; F: PCoderFieldInfo; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;

var
  CoderBool: TPointerCoderFuncs;

implementation

function SizeBool(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer;
var
  V: Boolean;
begin
  V := P.Bool^;
  Result := F.Tagsize + TProtowire.SizeVarint(TProtowire.EncodeBool(V));
end;

function AppendBool(B: TBytes; P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): TBytes;
var
  V: Boolean;
begin
  V := P.Bool^;
  B := TProtowire.AppendVarint(B, F.Wiretag);
  Result := TProtowire.AppendVarint(B, TProtowire.EncodeBool(V));
end;

function ConsumeBool(B: TBytes; P: TPointer; WTyp: TWireType; F: PCoderFieldInfo; const Opts: TUnmarshalOptions; out Out_: TUnmarshalOutput): Error;
var
  V: UInt64;
  N: Integer;
begin
  if WTyp <> TWireType.VarintType then Exit(ErrUnknown);
  if (Length(B) >= 1) and (B[0] < $80) then
  begin
    V := B[0];
    N := 1;
  end
  else if (Length(B) >= 2) and (B[1] < 128) then
  begin
    V := (B[0] and $7F) or (UInt64(B[1]) shl 7);
    N := 2;
  end
  else
    V := TProtowire.ConsumeVarint(B, N);

  if N < 0 then Exit(ErrDecode);
  P.Bool^ := TProtowire.DecodeBool(V);
  Out_.N := N;
  Result := nil;
end;

initialization
  CoderBool.Size := SizeBool;
  CoderBool.Marshal := AppendBool;
  CoderBool.Unmarshal := ConsumeBool;
  // CoderBool.Merge := MergeBool;

end.
