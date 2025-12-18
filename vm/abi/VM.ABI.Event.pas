unit VM.Abi.Event;

interface

uses
  Common.Types.Hash,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.SysUtils,
  VM.ABI.ABI,
  VM.ABI.ABI.Test,
  VM.Abi.Argument,
  VM.ABI.Error,
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
  TEvent = record
    Name: string;
    Inputs: TArguments;
    IndexedInputs: TArguments;
    NonIndexedInputs: TArguments;
    function ToString: string;
    function Id: THash;
    function Pack(const ParaArgs: array of TValue): TPair<TArray<THash>, TBytes>;
    function DirectUnpack(const ParaTopics: TArray<THash>; const ParaData: TBytes): TArray<TValue>;
    procedure UnmarshalJSON(const ParaData: TBytes);
  end;

implementation

uses
  System.Rtti,
  System.TypInfo,
  Common.Helper,
  VM.Abi.Error;

function GetEventInputs(const ParaInputs: TArguments): TPair<TArguments, TArguments>;
var
  vIndexed, vNonIndexed: TArguments;
  vInput: TArgument;
begin
  SetLength(vIndexed, 0);
  SetLength(vNonIndexed, 0);
  for vInput in ParaInputs do
  begin
    if vInput.Indexed then
      vIndexed := vIndexed + [vInput]
    else
      vNonIndexed := vNonIndexed + [vInput];
  end;
  Result := TPair<TArguments, TArguments>.Create(vIndexed, vNonIndexed);
end;

{ TEvent }

function TEvent.ToString: string;
var
  vInputs: TArray<string>;
  vIndex: Integer;
  vInput: TArgument;
begin
  SetLength(vInputs, Length(Self.Inputs));
  for vIndex := 0 to Length(Self.Inputs) - 1 do
  begin
    vInput := Self.Inputs[vIndex];
    if vInput.Indexed then
      vInputs[vIndex] := Format('%s indexed %s', [vInput.Type.ToString, vInput.Name])
    else
      vInputs[vIndex] := Format('%s %s', [vInput.Type.ToString, vInput.Name]);
  end;
  Result := Format('event %s(%s)', [Self.Name, TStringHelper.Join(',', vInputs)]);
end;

function TEvent.Id: THash;
var
  vTypeList: TArray<string>;
  vIndex: Integer;
  vInput: TArgument;
begin
  SetLength(vTypeList, Length(Self.Inputs));
  for vIndex := 0 to Length(Self.Inputs) - 1 do
  begin
    vInput := Self.Inputs[vIndex];
    vTypeList[vIndex] := vInput.Type.ToString;
  end;
  Result := TDataHash.Hash(TEncoding.UTF8.GetBytes(Format('%s(%s)', [Self.Name, TStringHelper.Join(',', vTypeList)])));
end;

function TEvent.Pack(const ParaArgs: array of TValue): TPair<TArray<THash>, TBytes>;
var
  vTopics: TArray<THash>;
  vNonIndexedArgList: TArray<TValue>;
  vTopicIndex: Integer;
  vIndex: Integer;
  vTopic: TBytes;
  vData: TBytes;
begin
  if Length(ParaArgs) <> Length(Self.Inputs) then
    raise ErrArgLengthMismatch(ParaArgs, Self.Inputs);

  SetLength(vTopics, Length(Self.IndexedInputs) + 1);
  vTopics[0] := Self.Id;
  SetLength(vNonIndexedArgList, 0);
  vTopicIndex := 1;

  for vIndex := 0 to High(ParaArgs) do
  begin
    if Self.Inputs[vIndex].Indexed then
    begin
      vTopic := Self.Inputs[vIndex].Type.Pack(ParaArgs[vIndex]);
      if Length(vTopic) <= THash.Size then
        vTopics[vTopicIndex] := BytesToHash(LeftPadBytes(vTopic, THash.Size))
      else
        vTopics[vTopicIndex] := TDataHash.Hash(vTopic);
      Inc(vTopicIndex);
    end
    else
    begin
      vNonIndexedArgList := vNonIndexedArgList + [ParaArgs[vIndex]];
    end;
  end;

  if Length(vNonIndexedArgList) > 0 then
  begin
    vData := Self.NonIndexedInputs.Pack(vNonIndexedArgList);
    Result := TPair<TArray<THash>, TBytes>.Create(vTopics, vData);
  end
  else
  begin
    Result := TPair<TArray<THash>, TBytes>.Create(vTopics, nil);
  end;
end;

function TEvent.DirectUnpack(const ParaTopics: TArray<THash>; const ParaData: TBytes): TArray<TValue>;
var
  vNonIndexedParams: TArray<TValue>;
  vNonIndex, vIndex: Integer;
  vArgs: TArray<TValue>;
  vArg: TArgument;
  vGoType: TValue;
begin
  vNonIndexedParams := Self.NonIndexedInputs.DirectUnpack(ParaData);
  vNonIndex := 0;
  vIndex := 1;
  SetLength(vArgs, 0);

  for vArg in Self.Inputs do
  begin
    if vArg.Indexed then
    begin
      if vArg.Type.T in [TAbiTypeKind.ArrayTy, TAbiTypeKind.StringTy, TAbiTypeKind.SliceTy, TAbiTypeKind.BytesTy] then
      begin
        vArgs := vArgs + [TValue.From<THash>(ParaTopics[vIndex])];
      end
      else
      begin
        vGoType := ToGoType(0, vArg.Type, ParaTopics[vIndex].Bytes);
        vArgs := vArgs + [vGoType];
      end;
      Inc(vIndex);
    end
    else
    begin
      vArgs := vArgs + [vNonIndexedParams[vNonIndex]];
      Inc(vNonIndex);
    end;
  end;
  Result := vArgs;
end;

procedure TEvent.UnmarshalJSON(const ParaData: TBytes);
var
  vFields: record
    Name: string;
    Inputs: TArray<TArgument>;
  end;
  vJsonObj: TJSONObject;
  vInputs: TJSONArray;
  vIndex: Integer;
  vInput: TArgument;
  vPair: TPair<TArguments, TArguments>;
begin
  vJsonObj := TJSONObject.ParseJSONValue(ParaData) as TJSONObject;
  try
    vFields.Name := vJsonObj.GetValue<string>('name');
    vInputs := vJsonObj.GetValue<TJSONArray>('inputs');
    SetLength(vFields.Inputs, vInputs.Count);
    for vIndex := 0 to vInputs.Count - 1 do
    begin
      vInput.UnmarshalJSON(TEncoding.UTF8.GetBytes(vInputs.Items[vIndex].ToString));
      vFields.Inputs[vIndex] := vInput;
    end;
  finally
    vJsonObj.Free;
  end;

  vPair := GetEventInputs(vFields.Inputs);
  Self.Name := vFields.Name;
  Self.Inputs := vFields.Inputs;
  Self.IndexedInputs := vPair.Key;
  Self.NonIndexedInputs := vPair.Value;
end;

end.
