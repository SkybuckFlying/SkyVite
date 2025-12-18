unit VM.Abi.Type;

interface

uses
  System.Generics.Collections,
  System.Rtti,
  System.SysUtils,
  VM.ABI.ABI,
  VM.ABI.ABI.Test,
  VM.ABI.Argument,
  VM.ABI.Error,
  VM.ABI.Event,
  VM.ABI.Event.Test,
  VM.ABI.Method,
  VM.ABI.Numbers,
  VM.ABI.Numbers.Test,
  VM.ABI.Pack,
  VM.ABI.Pack.Test,
  VM.ABI.Reflect,
  VM.ABI.Type.Test,
  VM.ABI.Unpack,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable,
  VM.ABI.Variable.Test;

type
  TAbiTypeKind = (
    IntTy,
    UintTy,
    BoolTy,
    StringTy,
    SliceTy,
    ArrayTy,
    AddressTy,
    GidTy,
    TokenIdTy,
    FixedBytesTy,
    BytesTy
  );

  TAbiType = record
    Elem: ^TAbiType;
    Kind: TTypeKind;
    RttiType: PTypeInfo;
    Size: Integer;
    T: TAbiTypeKind;
    StringKind: string;
    function ToString: string;
    function Pack(const ParaValue: TValue): TBytes;
    function RequiresLengthPrefix: Boolean;
  end;

function NewType(const ParaT: string): TAbiType;

implementation

uses
  System.TypInfo,
  System.RegularExpressions,
  System.BigNumbers,
  VM.Abi.Error,
  VM.Abi.Reflect,
  Common.Types.Address,
  Common.Types.Gid,
  Common.Types.TokenTypeId;

var
  TypeRegex: TRegEx;

function NewType(const ParaT: string): TAbiType;
var
  vMatch: TMatch;
  vEmbeddedType: TAbiType;
  vSliced: string;
  vIntz: TMatchCollection;
  vSize: Integer;
  vParsedType: TMatch;
  vVarSize: Integer;
  vVarType: string;
  vPair: TPair<TTypeKind, PTypeInfo>;
begin
  if (ParaT = 'uint') or (ParaT = 'int') then
    raise ErrUnsupportedArgType(ParaT);

  if (ParaT.CountChar('[') <> ParaT.CountChar(']')) or (ParaT.CountChar('[') > 1) then
    raise ErrUnsupportedArgType(ParaT);

  Result.StringKind := ParaT;

  if ParaT.CountChar('[') <> 0 then
  begin
    var i := ParaT.LastIndexOf('[');
    vEmbeddedType := NewType(ParaT.Substring(0, i));
    vSliced := ParaT.Substring(i);
    vIntz := TRegEx.Matches(vSliced, '[0-9]+');

    if vIntz.Count = 0 then
    begin
      Result.T := TAbiTypeKind.SliceTy;
      Result.Kind := tkDynArray;
      Result.Elem := @vEmbeddedType;
      Result.RttiType := vEmbeddedType.RttiType;
    end
    else if vIntz.Count = 1 then
    begin
      vSize := StrToInt(vIntz[0].Value);
      if vSize = 0 then
        raise ErrInvalidZeroVariableSize;
      Result.T := TAbiTypeKind.ArrayTy;
      Result.Kind := tkArray;
      Result.Elem := @vEmbeddedType;
      Result.Size := vSize;
      // How to create array type with RTTI?
    end
    else
      raise ErrInvalidArrayTypeFormatting;
    Exit;
  end;

  vParsedType := TypeRegex.Match(ParaT);
  if vParsedType.Groups.Count > 2 then
  begin
    if vParsedType.Groups[2].Value <> '' then
    begin
      vVarSize := StrToInt(vParsedType.Groups[2].Value);
      if vVarSize = 0 then
        raise ErrInvalidZeroVariableSize;
    end;
  end;

  vVarType := vParsedType.Groups[1].Value;
  case vVarType of
    'int':
      begin
        vPair := ReflectIntKindAndType(False, vVarSize);
        Result.Kind := vPair.Key;
        Result.RttiType := vPair.Value;
        Result.Size := vVarSize;
        Result.T := TAbiTypeKind.IntTy;
      end;
    'uint':
      begin
        vPair := ReflectIntKindAndType(True, vVarSize);
        Result.Kind := vPair.Key;
        Result.RttiType := vPair.Value;
        Result.Size := vVarSize;
        Result.T := TAbiTypeKind.UintTy;
      end;
    'bool':
      begin
        Result.Kind := tkBool;
        Result.T := TAbiTypeKind.BoolTy;
        Result.RttiType := TypeInfo(Boolean);
      end;
    'address':
      begin
        Result.Kind := tkArray;
        Result.RttiType := TypeInfo(TAddress);
        Result.Size := ConstAddressSize;
        Result.T := TAbiTypeKind.AddressTy;
      end;
    'gid':
      begin
        Result.Kind := tkArray;
        Result.RttiType := TypeInfo(TGid);
        Result.Size := ConstGidSize;
        Result.T := TAbiTypeKind.GidTy;
      end;
    'tokenId':
      begin
        Result.Kind := tkArray;
        Result.RttiType := TypeInfo(TTokenTypeId);
        Result.Size := ConstTokenTypeIdSize;
        Result.T := TAbiTypeKind.TokenIdTy;
      end;
    'string':
      begin
        Result.Kind := tkString;
        Result.RttiType := TypeInfo(string);
        Result.T := TAbiTypeKind.StringTy;
      end;
    'bytes':
      begin
        if vVarSize = 0 then
        begin
          Result.T := TAbiTypeKind.BytesTy;
          Result.Kind := tkDynArray;
          Result.RttiType := TypeInfo(TBytes);
        end
        else
        begin
          Result.T := TAbiTypeKind.FixedBytesTy;
          Result.Kind := tkArray;
          Result.Size := vVarSize;
          // How to create array type with RTTI?
        end;
      end;
  else
    raise ErrUnsupportedArgType(ParaT);
  end;
end;

{ TAbiType }

function TAbiType.ToString: string;
begin
  Result := Self.StringKind;
end;

function TAbiType.Pack(const ParaValue: TValue): TBytes;
var
  vPacked: TBytes;
  I: Integer;
  vVal: TBytes;
begin
  var v := Indirect(ParaValue);
  TypeCheck(Self, v);

  if (Self.T = TAbiTypeKind.SliceTy) or (Self.T = TAbiTypeKind.ArrayTy) then
  begin
    SetLength(vPacked, 0);
    for I := 0 to v.GetArrayLength - 1 do
    begin
      vVal := Self.Elem.Pack(v.GetArrayElement(I));
      vPacked := vPacked + vVal;
    end;

    if Self.T = TAbiTypeKind.SliceTy then
      Result := PackBytesSlice(vPacked, v.GetArrayLength)
    else if Self.T = TAbiTypeKind.ArrayTy then
      Result := vPacked;
  end
  else
    Result := PackElement(Self, v);
end;

function TAbiType.RequiresLengthPrefix: Boolean;
begin
  Result := Self.T in [TAbiTypeKind.StringTy, TAbiTypeKind.BytesTy, TAbiTypeKind.SliceTy];
end;

initialization
  TypeRegex := TRegEx.Create('([a-zA-Z]+)([0-9]+)?');
end.
