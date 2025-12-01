unit VM.Abi.Reflect;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.Generics.Collections,
  VM.Abi.Argument,
  VM.Abi.Error,
  VM.Abi.Type;

function Indirect(const ParaValue: TValue): TValue;
function ReflectIntKindAndType(IsUnsigned: Boolean; Size: Integer): TPair<TTypeKind, PTypeInfo>;
function MustArrayToByteSlice(const ParaValue: TValue): TBytes;
procedure Set(var ParaDest, ParaSrc: TValue; const ParaOutput: TArgument);
procedure RequireAssignable(const ParaDest, ParaSrc: TValue);
procedure RequireUnpackKind(const ParaValue: TValue; const ParaType: TRttiType; ParaKind: TTypeKind; const ParaArgs: TArguments);
function MapAbiToStructFields(const ParaArgs: TArguments; const ParaValue: TValue): TDictionary<string, string>;

implementation

uses
  System.TypInfo,
  System.BigNumbers;

function Indirect(const ParaValue: TValue): TValue;
var
  vValue: TValue;
begin
  vValue := ParaValue;
  while (vValue.Kind = tkPointer) and (vValue.Deref.TypeInfo <> TypeInfo(TBigInteger)) do
  begin
    vValue := vValue.Deref;
  end;
  Result := vValue;
end;

function ReflectIntKindAndType(IsUnsigned: Boolean; Size: Integer): TPair<TTypeKind, PTypeInfo>;
begin
  case Size of
    8:
      if IsUnsigned then
        Result := TPair<TTypeKind, PTypeInfo>.Create(tkUint8, TypeInfo(Byte))
      else
        Result := TPair<TTypeKind, PTypeInfo>.Create(tkInt8, TypeInfo(ShortInt));
    16:
      if IsUnsigned then
        Result := TPair<TTypeKind, PTypeInfo>.Create(tkUint16, TypeInfo(Word))
      else
        Result := TPair<TTypeKind, PTypeInfo>.Create(tkInt16, TypeInfo(SmallInt));
    32:
      if IsUnsigned then
        Result := TPair<TTypeKind, PTypeInfo>.Create(tkUint32, TypeInfo(LongWord))
      else
        Result := TPair<TTypeKind, PTypeInfo>.Create(tkInt32, TypeInfo(Integer));
    64:
      if IsUnsigned then
        Result := TPair<TTypeKind, PTypeInfo>.Create(tkUint64, TypeInfo(UInt64))
      else
        Result := TPair<TTypeKind, PTypeInfo>.Create(tkInt64, TypeInfo(Int64));
  else
    Result := TPair<TTypeKind, PTypeInfo>.Create(tkPointer, TypeInfo(TBigInteger));
  end;
end;

function MustArrayToByteSlice(const ParaValue: TValue): TBytes;
var
  vLen: Integer;
  I: Integer;
begin
  vLen := ParaValue.GetArrayLength;
  SetLength(Result, vLen);
  for I := 0 to vLen - 1 do
  begin
    Result[I] := ParaValue.GetArrayElement(I).AsByte;
  end;
end;

procedure Set(var ParaDest, ParaSrc: TValue; const ParaOutput: TArgument);
var
  vRttiContext: TRttiContext;
  vDestType, vSrcType: TRttiType;
begin
  vRttiContext := TRttiContext.Create;
  try
    vDestType := vRttiContext.GetType(ParaDest.TypeInfo);
    vSrcType := vRttiContext.GetType(ParaSrc.TypeInfo);

    if vDestType.Handle = vSrcType.Handle then
    begin
      ParaDest := ParaSrc;
    end
    else if vDestType.Kind = tkInterface then
    begin
      ParaDest := ParaSrc;
    end
    else if vDestType.Kind = tkPointer then
    begin
      var vDeref := ParaDest.Deref;
      Set(vDeref, ParaSrc, ParaOutput);
    end
    else
    begin
      raise ErrUnmarshalTypeFailed(ParaSrc, ParaDest);
    end;
  finally
    vRttiContext.Free;
  end;
end;

procedure RequireAssignable(const ParaDest, ParaSrc: TValue);
begin
  if not (ParaDest.Kind in [tkPointer, tkInterface]) then
    raise ErrUnmarshalTypeFailed(ParaSrc, ParaDest);
end;

procedure RequireUnpackKind(const ParaValue: TValue; const ParaType: TRttiType; ParaKind: TTypeKind; const ParaArgs: TArguments);
begin
  case ParaKind of
    tkRecord: ; // ok
    tkArray, tkDynArray:
      if ParaValue.GetArrayLength < Length(ParaArgs) then
        raise ErrInsufficientElementSize(Length(ParaArgs), ParaValue);
  else
    raise ErrInvalidTuple(ParaType);
  end;
end;

function MapAbiToStructFields(const ParaArgs: TArguments; const ParaValue: TValue): TDictionary<string, string>;
var
  vRttiContext: TRttiContext;
  vTyp: TRttiType;
  vAbi2Struct: TDictionary<string, string>;
  vStruct2Abi: TDictionary<string, string>;
  I: Integer;
  vStructFieldName: string;
  vTag: TRttiAttribute;
  vTagName: string;
  vFound: Boolean;
  vArg: TArgument;
  vField: TRttiField;
begin
  vRttiContext := TRttiContext.Create;
  try
    vTyp := vRttiContext.GetType(ParaValue.TypeInfo);
    vAbi2Struct := TDictionary<string, string>.Create;
    vStruct2Abi := TDictionary<string, string>.Create;

    for vField in vTyp.GetFields do
    begin
      vStructFieldName := vField.Name;
      if not vField.IsPublic then
        Continue;

      vTagName := '';
      for vTag in vField.GetAttributes do
      begin
        if vTag is AbiTag then
        begin
          vTagName := (vTag as AbiTag).Name;
          Break;
        end;
      end;

      if vTagName = '' then
        Continue;

      if vTagName = '' then
        raise ErrEmptyTagName(vStructFieldName);

      vFound := False;
      for vArg in ParaArgs do
      begin
        if vArg.Name = vTagName then
        begin
          if vAbi2Struct.ContainsKey(vArg.Name) then
            raise ErrTagAlreadyMapped(vStructFieldName);
          vAbi2Struct.Add(vArg.Name, vStructFieldName);
          vStruct2Abi.Add(vStructFieldName, vArg.Name);
          vFound := True;
        end;
      end;

      if not vFound then
        raise ErrTagNotFound(vTagName);
    end;

    for vArg in ParaArgs do
    begin
      var vAbiFieldName := vArg.Name;
      var vStructFieldName := Capitalise(vAbiFieldName);

      if vStructFieldName = '' then
        raise ErrPureUnderscoredOutput;

      if vAbi2Struct.ContainsKey(vAbiFieldName) then
      begin
        if (vAbi2Struct[vAbiFieldName] <> vStructFieldName) and
           (not vStruct2Abi.ContainsKey(vStructFieldName)) and
           (vTyp.GetField(vStructFieldName) <> nil) then
          raise ErrMultipleVariable(vAbiFieldName);
        Continue;
      end;

      if vStruct2Abi.ContainsKey(vStructFieldName) then
        raise ErrMultipleOutput(vStructFieldName);

      if vTyp.GetField(vStructFieldName) <> nil then
      begin
        vAbi2Struct.Add(vAbiFieldName, vStructFieldName);
        vStruct2Abi.Add(vStructFieldName, vAbiFieldName);
      end
      else
      begin
        vStruct2Abi.Add(vStructFieldName, vAbiFieldName);
      end;
    end;

    Result := vAbi2Struct;
  finally
    vRttiContext.Free;
  end;
end;

end.
