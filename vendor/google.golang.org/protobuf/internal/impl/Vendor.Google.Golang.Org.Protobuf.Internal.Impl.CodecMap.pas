unit Vendor.Google.Golang.Org.Protobuf.Internal.Impl.CodecMap;

interface

uses
  System.SysUtils, System.Rtti, System.Generics.Collections, System.Generics.Defaults,
  Vendor.Google.Golang.Org.Protobuf.Encoding.Protowire,
  Vendor.Google.Golang.Org.Protobuf.Internal.Genid,
  Vendor.Google.Golang.Org.Protobuf.Reflect.Protoreflect;

type
  PMapInfo = ^TMapInfo;
  TMapInfo = record
    GoType: TRttiType;
    KeyWiretag: UInt64;
    ValWiretag: UInt64;
    KeyFuncs: TValueCoderFuncs;
    ValFuncs: TValueCoderFuncs;
    KeyZero: TValue;
    KeyKind: TKind;
    Conv: TMapConverter;
  end;

function EncoderFuncsForMap(FD: IFieldDescriptor; FT: TRttiType; out ValueMessage: TMessageInfo): TPointerCoderFuncs;
function SizeMap(MapV: TValue; Mapi: PMapInfo; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer;

implementation

function EncoderFuncsForMap(FD: IFieldDescriptor; FT: TRttiType; out ValueMessage: TMessageInfo): TPointerCoderFuncs;
var
  KeyField, ValField: IFieldDescriptor;
  Mapi: PMapInfo;
begin
  KeyField := FD.MapKey;
  ValField := FD.MapValue;
  New(Mapi);
  Mapi.GoType := FT;
  Mapi.KeyWiretag := TProtowire.EncodeTag(1, WireTypes[KeyField.Kind]);
  Mapi.ValWiretag := TProtowire.EncodeTag(2, WireTypes[ValField.Kind]);
  Mapi.KeyFuncs := EncoderFuncsForValue(KeyField);
  Mapi.ValFuncs := EncoderFuncsForValue(ValField);
  Mapi.Conv := NewMapConverter(FT, FD);
  Mapi.KeyZero := KeyField.Default_;
  Mapi.KeyKind := KeyField.Kind;

  ValueMessage := nil;
  if ValField.Kind = TKind.MessageKind then
    ValueMessage := GetMessageInfo(FT.AsHasType.GetElementType);

  Result.Size := function(P: TPointer; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer
  begin
    Result := SizeMap(P.AsValueOf(FT).Elem, Mapi, F, Opts);
  end;
  // ... marshal and unmarshal implementations
end;

function SizeMap(MapV: TValue; Mapi: PMapInfo; F: PCoderFieldInfo; const Opts: TMarshalOptions): Integer;
var
  N: Integer;
  Iter: TMapIterator;
  Key, Value: TValue;
  KeySize, ValSize: Integer;
  P: TPointer;
begin
  if MapV.AsMap.Len = 0 then Exit(0);
  N := 0;
  Iter := MapRange(MapV);
  while Iter.Next do
  begin
    Key := Mapi.Conv.KeyConv.PBValueOf(Iter.Key).MapKey;
    KeySize := Mapi.KeyFuncs.Size(Key, 1, Opts);
    if F.MI = nil then
      ValSize := Mapi.ValFuncs.Size(Mapi.Conv.ValConv.PBValueOf(Iter.Value), 1, Opts)
    else
    begin
      P := TPointer.OfValue(Iter.Value);
      ValSize := 1; // mapValTagSize
      ValSize := ValSize + TProtowire.SizeBytes(F.MI.SizePointer(P, Opts));
    end;
    N := N + F.Tagsize + TProtowire.SizeBytes(KeySize + ValSize);
  end;
  Result := N;
end;

end.
