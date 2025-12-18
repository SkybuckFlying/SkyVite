unit VM.Abi.Argument;

interface

uses
  Common.HexUtil,
  Common.Types.Address,
  Common.Types.Gid,
  Common.Types.TokenTypeId,
  GoToDelphi.Helpers.BigInt,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.Rtti,
  System.SysUtils,
  VM.ABI.ABI,
  VM.ABI.ABI.Test,
  VM.Abi.Error,
  VM.ABI.Event,
  VM.ABI.Event.Test,
  VM.ABI.Method,
  VM.ABI.Numbers,
  VM.ABI.Numbers.Test,
  VM.ABI.Pack,
  VM.ABI.Pack.Test,
  VM.ABI.Reflect,
  VM.Abi.Type,
  VM.ABI.Type.Test,
  VM.ABI.Unpack,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable,
  VM.ABI.Variable.Test;

type
  TArgument = record
    Name: string;
    Type: TAbiType;
    Indexed: Boolean;
    function UnmarshalJSON(ParaData: TBytes): Boolean;
  end;

  TArguments = TArray<TArgument>;

  TArgumentsHelper = record helper for TArguments
    function IsTuple: Boolean;
    procedure Unpack(ParaValue: Pointer; const ParaData: TBytes);
    function DirectUnpack(const ParaData: TBytes): TArray<TValue>;
    procedure UnpackTuple(ParaValue: TValue; const ParaMarshalledValues: TArray<TValue>);
    procedure UnpackAtomic(ParaValue: TValue; const ParaMarshalledValues: TArray<TValue>);
    function UnpackValues(const ParaData: TBytes): TArray<TValue>;
    function PackValues(const ParaArgs: TArray<TValue>): TBytes;
    function Pack(const ParaArgs: array of TValue): TBytes;
  end;

function Capitalise(const ParaInput: string): string;
function PackNum(const ParaValue: TValue): TBytes;
function ToGoType(ParaOffset: Integer; ParaType: TAbiType; const ParaData: TBytes): TValue;

implementation

uses
  System.Math,
  System.BigNumbers,
  System.TypInfo,
  VM.Abi.Reflect;

const
  GWordSize = 32;

function Capitalise(const ParaInput: string): string;
var
  vInput: string;
begin
  vInput := ParaInput;
  while (Length(vInput) > 0) and (vInput[1] = '_') do
  begin
    vInput := Copy(vInput, 2, Length(vInput) - 1);
  end;
  if Length(vInput) = 0 then
  begin
    Result := '';
    Exit;
  end;
  Result := UpperCase(vInput[1]) + Copy(vInput, 2, Length(vInput) - 1);
end;

function PackNum(const ParaValue: TValue): TBytes;
var
  vBigInt: TBigInteger;
begin
  case ParaValue.Kind of
    tkInteger, tkInt64:
      vBigInt := TBigInteger.Create(ParaValue.AsInt64);
    tkEnumeration, tkChar, tkWChar, tkLString, tkWString, tkString:
      vBigInt := TBigInteger.Create(ParaValue.AsInteger);
  else
    raise EArgumentException.Create('Unsupported type for PackNum');
  end;
  Result := U256(vBigInt);
end;

{ TArgument }

function TArgument.UnmarshalJSON(ParaData: TBytes): Boolean;
var
  vJson: string;
  vExtArg: record
    Name: string;
    Type: string;
    Indexed: Boolean;
  end;
  vJsonObj: TJSONObject;
begin
  Result := False;
  vJson := TEncoding.UTF8.GetString(ParaData);
  vJsonObj := TJSONObject.ParseJSONValue(vJson) as TJSONObject;
  try
    vExtArg.Name := vJsonObj.GetValue<string>('Name');
    vExtArg.Type := vJsonObj.GetValue<string>('Type');
    vExtArg.Indexed := vJsonObj.GetValue<Boolean>('Indexed');

    Self.Type := NewType(vExtArg.Type);
    Self.Name := vExtArg.Name;
    Self.Indexed := vExtArg.Indexed;
    Result := True;
  finally
    vJsonObj.Free;
  end;
end;

{ TArgumentsHelper }

function TArgumentsHelper.IsTuple: Boolean;
begin
  Result := Length(Self) > 1;
end;

procedure TArgumentsHelper.Unpack(ParaValue: Pointer; const ParaData: TBytes);
var
  vMarshalledValues: TArray<TValue>;
  vRttiContext: TRttiContext;
  vValue: TValue;
begin
  vRttiContext := TRttiContext.Create;
  try
    vValue := TValue.From(ParaValue);
    if vValue.Kind <> tkPointer then
    begin
      raise ErrInvalidStruct(vValue);
    end;

    vValue := vValue.Deref;

    vMarshalledValues := UnpackValues(ParaData);

    if IsTuple then
    begin
      UnpackTuple(vValue, vMarshalledValues);
    end
    else
    begin
      UnpackAtomic(vValue, vMarshalledValues);
    end;
  finally
    vRttiContext.Free;
  end;
end;

function TArgumentsHelper.DirectUnpack(const ParaData: TBytes): TArray<TValue>;
begin
  Result := UnpackValues(ParaData);
end;

procedure TArgumentsHelper.UnpackTuple(ParaValue: TValue; const ParaMarshalledValues: TArray<TValue>);
var
  vKind: TTypeKind;
  vAbi2Struct: TDictionary<string, string>;
  vIndex: Integer;
  vArg: TArgument;
  vReflectValue: TValue;
  vStructField: string;
  vDest: TValue;
  vRttiContext: TRttiContext;
begin
  vRttiContext := TRttiContext.Create;
  try
    vKind := ParaValue.Kind;

    RequireUnpackKind(ParaValue, vRttiContext.GetType(ParaValue.TypeInfo), vKind, Self);

    if vKind = tkRecord then
    begin
      vAbi2Struct := MapAbiToStructFields(Self, ParaValue);
    end;

    for vIndex := 0 to Length(Self) - 1 do
    begin
      vArg := Self[vIndex];
      vReflectValue := ParaMarshalledValues[vIndex];

      case vKind of
        tkRecord:
          begin
            if vAbi2Struct.TryGetValue(vArg.Name, vStructField) then
            begin
              vDest := ParaValue.GetField(vStructField);
              Set(vDest, vReflectValue, vArg);
            end;
          end;
        tkArray, tkDynArray:
          begin
            if ParaValue.GetArrayLength < vIndex then
              raise ErrInsufficientArgumentSize(Self, ParaValue);
            vDest := ParaValue.GetArrayElement(vIndex);
            Set(vDest, vReflectValue, vArg);
          end;
      else
        raise ErrInvalidTuple(vRttiContext.GetType(ParaValue.TypeInfo));
      end;
    end;
  finally
    vRttiContext.Free;
  end;
end;

procedure TArgumentsHelper.UnpackAtomic(ParaValue: TValue; const ParaMarshalledValues: TArray<TValue>);
var
  vKind: TTypeKind;
  vReflectValue: TValue;
  vAbi2Struct: TDictionary<string, string>;
  vArg: TArgument;
  vStructField: string;
begin
  if Length(ParaMarshalledValues) <> 1 then
    raise ErrWrongPackedLength(ParaMarshalledValues);

  vKind := ParaValue.Kind;
  vReflectValue := ParaMarshalledValues[0];

  if vKind = tkRecord then
  begin
    vAbi2Struct := MapAbiToStructFields(Self, ParaValue);
    vArg := Self[0];
    if vAbi2Struct.TryGetValue(vArg.Name, vStructField) then
    begin
      var vDest := ParaValue.GetField(vStructField);
      Set(vDest, vReflectValue, vArg);
    end;
  end
  else
  begin
    Set(ParaValue, vReflectValue, Self[0]);
  end;
end;

function GetArraySize(const ParaArr: TAbiType): Integer;
var
  vSize: Integer;
  vArr: TAbiType;
begin
  vSize := ParaArr.Size;
  vArr := ParaArr.Elem;
  while vArr.T = TAbiTypeKind.ArrayTy do
  begin
    vSize := vSize * vArr.Size;
    vArr := vArr.Elem;
  end;
  Result := vSize;
end;

function TArgumentsHelper.UnpackValues(const ParaData: TBytes): TArray<TValue>;
var
  vRetVal: TArray<TValue>;
  vVirtualArgs: Integer;
  vIndex: Integer;
  vArg: TArgument;
  vMarshalledValue: TValue;
begin
  SetLength(vRetVal, 0);
  vVirtualArgs := 0;

  for vIndex := 0 to Length(Self) - 1 do
  begin
    vArg := Self[vIndex];
    vMarshalledValue := ToGoType((vIndex + vVirtualArgs) * GWordSize, vArg.Type, ParaData);
    if vArg.Type.T = TAbiTypeKind.ArrayTy then
    begin
      vVirtualArgs := vVirtualArgs + GetArraySize(vArg.Type) - 1;
    end;
    vRetVal := vRetVal + [vMarshalledValue];
  end;
  Result := vRetVal;
end;

function TArgumentsHelper.PackValues(const ParaArgs: TArray<TValue>): TBytes;
begin
  Result := Pack(ParaArgs);
end;

function TArgumentsHelper.Pack(const ParaArgs: array of TValue): TBytes;
var
  vAbiArgs: TArguments;
  vVariableInput: TBytes;
  vInputOffset: Integer;
  vIndex: Integer;
  vAbiArg: TArgument;
  vPacked: TBytes;
  vOffset: Integer;
  vPackedOffset: TBytes;
  vRet: TBytes;
  vArg: TValue;
begin
  vAbiArgs := Self;
  if Length(ParaArgs) <> Length(vAbiArgs) then
  begin
    raise ErrArgLengthMismatch(ParaArgs, vAbiArgs);
  end;

  vInputOffset := 0;
  for vAbiArg in vAbiArgs do
  begin
    if vAbiArg.Type.T = TAbiTypeKind.ArrayTy then
    begin
      vInputOffset := vInputOffset + (GWordSize * vAbiArg.Type.Size);
    end
    else
    begin
      vInputOffset := vInputOffset + GWordSize;
    end;
  end;

  SetLength(vRet, 0);
  SetLength(vVariableInput, 0);
  for vIndex := 0 to High(ParaArgs) do
  begin
    vArg := ParaArgs[vIndex];
    vAbiArg := vAbiArgs[vIndex];
    vPacked := vAbiArg.Type.Pack(vArg);

    if vAbiArg.Type.RequiresLengthPrefix then
    begin
      vOffset := vInputOffset + Length(vVariableInput);
      vPackedOffset := PackNum(TValue.From<Integer>(vOffset));
      vRet := vRet + vPackedOffset;
      vVariableInput := vVariableInput + vPacked;
    end
    else
    begin
      vRet := vRet + vPacked;
    end;
  end;
  vRet := vRet + vVariableInput;
  Result := vRet;
end;

function ReadInteger(const ParaKind: TTypeKind; const ParaBytes: TBytes): TValue;
var
  vBigInt: TBigInteger;
  vBytes: TBytes;
begin
  vBytes := ParaBytes;
  case ParaKind of
    tkUint8:
      Result := TValue.From<Byte>(vBytes[High(vBytes)]);
    tkUint16:
      Result := TValue.From<Word>(TBitConverter.ToUInt16(vBytes, Length(vBytes) - 2));
    tkUint32:
      Result := TValue.From<LongWord>(TBitConverter.ToUInt32(vBytes, Length(vBytes) - 4));
    tkUint64:
      Result := TValue.From<UInt64>(TBitConverter.ToUInt64(vBytes, Length(vBytes) - 8));
    tkInt8:
      Result := TValue.From<ShortInt>(ShortInt(vBytes[High(vBytes)]));
    tkInt16:
      Result := TValue.From<SmallInt>(TBitConverter.ToInt16(vBytes, Length(vBytes) - 2));
    tkInt32:
      Result := TValue.From<Integer>(TBitConverter.ToInt32(vBytes, Length(vBytes) - 4));
    tkInt64:
      Result := TValue.From<Int64>(TBitConverter.ToInt64(vBytes, Length(vBytes) - 8));
  else
    vBigInt := TBigInteger.Create(vBytes);
    Result := TValue.From<TBigInteger>(vBigInt);
  end;
end;

function ReadBool(const ParaWord: TBytes): Boolean;
var
  vIndex: Integer;
begin
  for vIndex := 0 to 30 do
  begin
    if ParaWord[vIndex] <> 0 then
      raise EArgumentException.Create('Bad bool');
  end;
  case ParaWord[31] of
    0: Result := False;
    1: Result := True;
  else
    raise EArgumentException.Create('Bad bool');
  end;
end;

function ReadFixedBytes(const ParaType: TAbiType; const ParaWord: TBytes): TValue;
var
  vRttiContext: TRttiContext;
  vRttiType: TRttiType;
  vArray: TValue;
begin
  if ParaType.T <> TAbiTypeKind.FixedBytesTy then
    raise EArgumentException.Create('Invalid fixed bytes type');

  vRttiContext := TRttiContext.Create;
  try
    vRttiType := vRttiContext.GetType(ParaType.RttiType);
    vArray := vRttiType.GetMethod('Create').Invoke(vRttiType.AsInstance.MetaclassType, []);
    TValue.Make(Copy(ParaWord, 0, ParaType.Size), vRttiType, vArray);
    Result := vArray;
  finally
    vRttiContext.Free;
  end;
end;

function ForEachUnpack(const ParaType: TAbiType; const ParaOutput: TBytes; ParaStart, ParaSize: Integer): TValue;
var
  vRefSlice: TValue;
  vRttiContext: TRttiContext;
  vRttiType: TRttiType;
  vElemSize: Integer;
  vIndex: Integer;
  vItem: TValue;
  i, j: Integer;
begin
  if ParaSize < 0 then
    raise EArgumentException.Create('Negative input size');
  if (ParaStart + GWordSize * ParaSize) > Length(ParaOutput) then
    raise EArgumentException.Create('Array offset overflow');

  vRttiContext := TRttiContext.Create;
  try
    vRttiType := vRttiContext.GetType(ParaType.RttiType);
    if ParaType.T = TAbiTypeKind.SliceTy then
    begin
      vRefSlice := TValue.CreateArray(vRttiType.AsDynamicArray.ElementType, ParaSize);
    end
    else if ParaType.T = TAbiTypeKind.ArrayTy then
    begin
      vRefSlice := TValue.CreateArray(vRttiType.AsArray.ElementType, ParaType.Size);
    end
    else
      raise EArgumentException.Create('Invalid array type');

    vElemSize := GWordSize;
    if ParaType.T = TAbiTypeKind.ArrayTy then
      vElemSize := GetFullElemSize(ParaType.Elem^);

    j := 0;
    i := ParaStart;
    while j < ParaSize do
    begin
      vItem := ToGoType(i, ParaType.Elem^, ParaOutput);
      vRefSlice.SetArrayElement(j, vItem);
      Inc(j);
      Inc(i, vElemSize);
    end;
  finally
    vRttiContext.Free;
  end;
  Result := vRefSlice;
end;

function LengthPrefixPointsTo(ParaIndex: Integer; const ParaOutput: TBytes): TTriple<Integer, Integer, Boolean>;
var
  vOffsetEnd, vLengthBig, vTotalSize, vOutputLength: TBigInteger;
begin
  vOffsetEnd := TBigInteger.Create(Copy(ParaOutput, ParaIndex, GWordSize));
  vOffsetEnd := vOffsetEnd + GWordSize;

  vOutputLength := TBigInteger.Create(Length(ParaOutput));

  if vOffsetEnd > vOutputLength then
    raise EArgumentException.Create('Big slice offset overflow');

  if vOffsetEnd.BitLength > 63 then
    raise EArgumentException.Create('Big offset overflow');

  var vOffsetEndInt := vOffsetEnd.AsUInt64;
  vLengthBig := TBigInteger.Create(Copy(ParaOutput, vOffsetEndInt - GWordSize, GWordSize));

  vTotalSize := vOffsetEnd + vLengthBig;
  if vTotalSize.BitLength > 63 then
    raise EArgumentException.Create('Big length overflow');

  if vTotalSize > vOutputLength then
    raise EArgumentException.Create('Insufficient big length');

  Result.A := vOffsetEnd.AsInteger;
  Result.B := vLengthBig.AsInteger;
  Result.C := True;
end;

function ToGoType(ParaOffset: Integer; ParaType: TAbiType; const ParaData: TBytes): TValue;
var
  vReturnOutput: TBytes;
  vBegin, vEnd: Integer;
  vPointsTo: TTriple<Integer, Integer, Boolean>;
  vAddress: TAddress;
  vGid: TGid;
  vTokenId: TTokenTypeId;
begin
  if (ParaOffset + GWordSize) > Length(ParaData) then
    raise EArgumentException.Create('Insufficient length');

  if ParaType.RequiresLengthPrefix then
  begin
    vPointsTo := LengthPrefixPointsTo(ParaOffset, ParaData);
    if not vPointsTo.C then
      Exit; // Error
    vBegin := vPointsTo.A;
    vEnd := vPointsTo.B;
  end
  else
  begin
    vReturnOutput := Copy(ParaData, ParaOffset, GWordSize);
  end;

  case ParaType.T of
    TAbiTypeKind.SliceTy:
      Result := ForEachUnpack(ParaType, ParaData, vBegin, vEnd);
    TAbiTypeKind.ArrayTy:
      Result := ForEachUnpack(ParaType, ParaData, ParaOffset, ParaType.Size);
    TAbiTypeKind.StringTy:
      Result := TValue.From<string>(TEncoding.UTF8.GetString(Copy(ParaData, vBegin, vEnd)));
    TAbiTypeKind.IntTy, TAbiTypeKind.UintTy:
      Result := ReadInteger(ParaType.Kind, vReturnOutput);
    TAbiTypeKind.BoolTy:
      Result := TValue.From<Boolean>(ReadBool(vReturnOutput));
    TAbiTypeKind.AddressTy:
      begin
        vAddress := BytesToAddress(Copy(vReturnOutput, GWordSize - ConstAddressSize, ConstAddressSize));
        Result := TValue.From<TAddress>(vAddress);
      end;
    TAbiTypeKind.GidTy:
      begin
        vGid := BytesToGid(Copy(vReturnOutput, GWordSize - ConstGidSize, ConstGidSize));
        Result := TValue.From<TGid>(vGid);
      end;
    TAbiTypeKind.TokenIdTy:
      begin
        vTokenId := BytesToTokenTypeId(Copy(vReturnOutput, GWordSize - ConstTokenTypeIdSize, ConstTokenTypeIdSize));
        Result := TValue.From<TTokenTypeId>(vTokenId);
      end;
    TAbiTypeKind.BytesTy:
      Result := TValue.From<TBytes>(Copy(ParaData, vBegin, vEnd));
    TAbiTypeKind.FixedBytesTy:
      Result := ReadFixedBytes(ParaType, vReturnOutput);
  else
    raise EArgumentException.Create('Unknown type');
  end;
end;

end.
