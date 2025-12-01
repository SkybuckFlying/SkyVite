unit VM.Abi.Error;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.BigNumbers,
  VM.Abi.Type;

type
  EAbiException = class(Exception);

  EAbiBadBool = class(EAbiException);
  EAbiEmptyInput = class(EAbiException);
  EAbiCouldNotLocateNamedMethod = class(EAbiException);
  EAbiCouldNotLocateNamedEvent = class(EAbiException);
  EAbiCouldNotLocateNamedVariable = class(EAbiException);
  EAbiMethodIdNotSpecified = class(EAbiException);
  EAbiInvalidEmptyVariableInput = class(EAbiException);
  EAbiInvalidZeroVariableSize = class(EAbiException);
  EAbiInvalidArrayTypeFormatting = class(EAbiException);
  EAbiPackFailed = class(EAbiException);
  EAbiPureUnderscoredOutput = class(EAbiException);
  EAbiInvalidlFixedBytesType = class(EAbiException);
  EAbiInvalidlArrayType = class(EAbiException);

function ErrArgumentJson(const E: Exception): EAbiException;
function ErrMethodNotFound(const Name: string): EAbiException;
function ErrNoMethodId(const SigData: TBytes): EAbiException;
function ErrCallbackNotFound(const Name: string): EAbiException;
function ErrOffchainNotFound(const Name: string): EAbiException;
function ErrVariableNotFound(const Name: string): EAbiException;
function ErrEventNotFound(const Name: string): EAbiException;
function ErrType(const Expected, Got: TValue): EAbiException;
function ErrParsingVariableSize(const E: Exception): EAbiException;
function ErrUnsupportedArgType(const T: string): EAbiException;
function ErrUnknownType(const T: TAbiType): EAbiException;
function ErrWrongPackedLength(const MarshalledValues: TArray<TValue>): EAbiException;
function ErrArgLengthMismatch(const Args: TArray<TValue>; const AbiArgs: TArray<TValue>): EAbiException;
function ErrInvalidStruct(const V: TValue): EAbiException;
function ErrInsufficientArgumentSize(const Arguments: TArray<TValue>; const Value: TValue): EAbiException;
function ErrInsufficientElementSize(MinLen: Integer; const V: TValue): EAbiException;
function ErrUnmarshalTypeFailed(const Src, Dst: TValue): EAbiException;
function ErrInvalidTuple(const Typ: TRttiType): EAbiException;
function ErrEmptyTagName(const StructFieldName: string): EAbiException;
function ErrTagAlreadyMapped(const StructFieldName: string): EAbiException;
function ErrTagNotFound(const TagName: string): EAbiException;
function ErrMultipleVariable(const AbiFieldName: string): EAbiException;
function ErrMultipleOutput(const StructFieldName: string): EAbiException;
function ErrNegativeInputSize(Size: Integer): EAbiException;
function ErrArrayOffsetOverflow(const Output: TBytes; Start, Size: Integer): EAbiException;
function ErrInsufficientLength(const OutputSize: TBytes; Index: Integer): EAbiException;
function ErrBigSliceOffsetOverflow(const BigOffsetEnd, OutputLength: TBigInteger): EAbiException;
function ErrBigOffsetOverflow(const BigOffsetEnd: TBigInteger): EAbiException;
function ErrBigLengthOverflow(const TotalSize: TBigInteger): EAbiException;
function ErrInsufficientBigLength(const OutputLength, TotalSize: TBigInteger): EAbiException;

procedure SliceTypeCheck(const T: TAbiType; const Val: TValue);
procedure TypeCheck(const T: TAbiType; const Value: TValue);

implementation

uses
  System.StrUtils,
  System.TypInfo,
  Common.HexUtil;

function FormatSliceString(const Kind: TTypeKind; SliceSize: Integer): string;
begin
  if SliceSize = -1 then
    Result := Format('[]%s', [GetEnumName(TypeInfo(TTypeKind), Ord(Kind))])
  else
    Result := Format('[%d]%s', [SliceSize, GetEnumName(TypeInfo(TTypeKind), Ord(Kind))]);
end;

procedure SliceTypeCheck(const T: TAbiType; const Val: TValue);
var
  ElemKind: TTypeKind;
begin
  if not (Val.Kind in [tkArray, tkDynArray]) then
    raise ErrType(TValue.From<string>(FormatSliceString(T.Kind, T.Size)), Val);

  if (T.T = TAbiTypeKind.ArrayTy) and (Val.GetArrayLength <> T.Size) then
    raise ErrType(TValue.From<string>(FormatSliceString(T.Elem.Kind, T.Size)), TValue.From<string>(FormatSliceString(Val.TypeInfo.TypeData.ElementType^.Kind, Val.GetArrayLength)));

  if T.Elem.T = TAbiTypeKind.SliceTy then
  begin
    if Val.GetArrayLength > 0 then
      SliceTypeCheck(T.Elem, Val.GetArrayElement(0));
  end
  else if T.Elem.T = TAbiTypeKind.ArrayTy then
  begin
    SliceTypeCheck(T.Elem, Val.GetArrayElement(0));
  end;

  ElemKind := Val.TypeInfo.TypeData.ElementType^.Kind;
  if ((not (ElemKind in [tkArray, tkDynArray])) and (ElemKind <> T.Elem.Kind)) or
     ((ElemKind in [tkArray, tkDynArray]) and not (T.Elem.Kind in [tkArray, tkDynArray])) or
     (not (ElemKind in [tkArray, tkDynArray]) and (T.Elem.Kind = TAbiTypeKind.ArrayTy)) then
    raise ErrType(TValue.From<string>(FormatSliceString(T.Elem.Kind, T.Size)), Val);
end;

procedure TypeCheck(const T: TAbiType; const Value: TValue);
begin
  if T.T in [TAbiTypeKind.SliceTy, TAbiTypeKind.ArrayTy] then
  begin
    SliceTypeCheck(T, Value);
    Exit;
  end;

  if (T.Kind <> tkArray) and (T.Kind <> Value.Kind) then
    raise ErrType(TValue.From<TTypeKind>(T.Kind), TValue.From<TTypeKind>(Value.Kind));

  if (T.T = TAbiTypeKind.FixedBytesTy) and (T.Size <> Value.GetArrayLength) then
    raise ErrType(TValue.From<TRttiType>(T.RttiType), TValue.From<TRttiType>(Value.TypeInfo));
end;

function ErrArgumentJson(const E: Exception): EAbiException;
begin
  Result := EAbiException.CreateFmt('argument json err: %s', [E.Message]);
end;

function ErrMethodNotFound(const Name: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('method ''%s'' not found', [Name]);
end;

function ErrNoMethodId(const SigData: TBytes): EAbiException;
begin
  Result := EAbiException.CreateFmt('no method with id: %#x', [Copy(SigData, 0, 4)]);
end;

function ErrCallbackNotFound(const Name: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('callback ''%s'' not found', [Name]);
end;

function ErrOffchainNotFound(const Name: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('offchain ''%s'' not found', [Name]);
end;

function ErrVariableNotFound(const Name: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('varible ''%s'' not found', [Name]);
end;

function ErrEventNotFound(const Name: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('event ''%s'' not found', [Name]);
end;

function ErrType(const Expected, Got: TValue): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: cannot use %s as type %s as argument', [Got.ToString, Expected.ToString]);
end;

function ErrParsingVariableSize(const E: Exception): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: error parsing variable size: %s', [E.Message]);
end;

function ErrUnsupportedArgType(const T: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: unsupported arg type: %s', [T]);
end;

function ErrUnknownType(const T: TAbiType): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: unknown type %s', [T.String]);
end;

function ErrWrongPackedLength(const MarshalledValues: TArray<TValue>): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: wrong length, expected single value, got %d', [Length(MarshalledValues)]);
end;

function ErrArgLengthMismatch(const Args: TArray<TValue>; const AbiArgs: TArray<TValue>): EAbiException;
begin
  Result := EAbiException.CreateFmt('argument count mismatch: %d for %d', [Length(Args), Length(AbiArgs)]);
end;

function ErrInvalidStruct(const V: TValue): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: Unpack(non-pointer %s)', [V.ToString]);
end;

function ErrInsufficientArgumentSize(const Arguments: TArray<TValue>; const Value: TValue): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: insufficient number of arguments for unpack, want %d, got %d', [Length(Arguments), Value.GetArrayLength]);
end;

function ErrInsufficientElementSize(MinLen: Integer; const V: TValue): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: insufficient number of elements in the list/array for unpack, want %d, got %d', [MinLen, V.GetArrayLength]);
end;

function ErrUnmarshalTypeFailed(const Src, Dst: TValue): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: cannot unmarshal %s in to %s', [Src.ToString, Dst.ToString]);
end;

function ErrInvalidTuple(const Typ: TRttiType): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: cannot unmarshal tuple into %s', [Typ.ToString]);
end;

function ErrEmptyTagName(const StructFieldName: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('struct: abi tag in ''%s'' is empty', [StructFieldName]);
end;

function ErrTagAlreadyMapped(const StructFieldName: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('struct: abi tag in ''%s'' already mapped', [StructFieldName]);
end;

function ErrTagNotFound(const TagName: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('struct: abi tag ''%s'' defined but not found in abi', [TagName]);
end;

function ErrMultipleVariable(const AbiFieldName: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: multiple variables maps to the same abi field ''%s''', [AbiFieldName]);
end;

function ErrMultipleOutput(const StructFieldName: string): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: multiple outputs mapping to the same struct field ''%s''', [StructFieldName]);
end;

function ErrNegativeInputSize(Size: Integer): EAbiException;
begin
  Result := EAbiException.CreateFmt('cannot marshal input to array, size is negative (%d)', [Size]);
end;

function ErrArrayOffsetOverflow(const Output: TBytes; Start, Size: Integer): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: cannot marshal in to go array: offset %d would go over slice boundary (len=%d)', [Length(Output), Start + 32 * Size]);
end;

function ErrInsufficientLength(const OutputSize: TBytes; Index: Integer): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: cannot marshal in to go type: length insufficient %d require %d', [Length(OutputSize), Index + 32]);
end;

function ErrBigSliceOffsetOverflow(const BigOffsetEnd, OutputLength: TBigInteger): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: cannot marshal in to go slice: offset %s would go over slice boundary (len=%s)', [BigOffsetEnd.ToString, OutputLength.ToString]);
end;

function ErrBigOffsetOverflow(const BigOffsetEnd: TBigInteger): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi offset larger than int64: %s', [BigOffsetEnd.ToString]);
end;

function ErrBigLengthOverflow(const TotalSize: TBigInteger): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi length larger than int64: %s', [TotalSize.ToString]);
end;

function ErrInsufficientBigLength(const OutputLength, TotalSize: TBigInteger): EAbiException;
begin
  Result := EAbiException.CreateFmt('abi: cannot marshal in to go type: length insufficient %s require %s', [OutputLength.ToString, TotalSize.ToString]);
end;

end.