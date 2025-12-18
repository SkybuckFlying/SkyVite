unit VM.Abi.Method;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  VM.ABI.ABI,
  VM.ABI.ABI.Test,
  VM.Abi.Argument,
  VM.ABI.Error,
  VM.ABI.Event,
  VM.ABI.Event.Test,
  VM.ABI.Numbers,
  VM.ABI.Numbers.Test,
  VM.ABI.Pack,
  VM.ABI.Pack.Test,
  VM.ABI.Reflect,
  VM.ABI.Type,
  VM.ABI.Type.Test,
  VM.ABI.Unpack,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable,
  VM.ABI.Variable.Test;

type
  TMethod = record
    Name: string;
    Id: TBytes;
    Inputs: TArguments;
    Outputs: TArguments;
    function Sig: string;
    function ToString: string;
  end;

function NewMethod(const ParaName: string; const ParaInputs, ParaOutputs: TArguments): TMethod;

implementation

uses
  System.StrUtils,
  Common.Types.Hash;

function NewMethod(const ParaName: string; const ParaInputs, ParaOutputs: TArguments): TMethod;
var
  vMethod: TMethod;
begin
  vMethod.Name := ParaName;
  vMethod.Inputs := ParaInputs;
  vMethod.Outputs := ParaOutputs;
  vMethod.Id := Copy(TDataHash.Hash(TEncoding.UTF8.GetBytes(vMethod.Sig)), 0, 4);
  Result := vMethod;
end;

{ TMethod }

function TMethod.Sig: string;
var
  vTypes: TArray<string>;
  vIndex: Integer;
  vInput: TArgument;
begin
  SetLength(vTypes, Length(Self.Inputs));
  for vIndex := 0 to Length(Self.Inputs) - 1 do
  begin
    vInput := Self.Inputs[vIndex];
    vTypes[vIndex] := vInput.Type.ToString;
  end;
  Result := Format('%s(%s)', [Self.Name, TStringHelper.Join(',', vTypes)]);
end;

function TMethod.ToString: string;
var
  vInputs: TArray<string>;
  vIndex: Integer;
  vInput: TArgument;
begin
  SetLength(vInputs, Length(Self.Inputs));
  for vIndex := 0 to Length(Self.Inputs) - 1 do
  begin
    vInput := Self.Inputs[vIndex];
    vInputs[vIndex] := Format('%s %s', [vInput.Type.ToString, vInput.Name]);
  end;
  Result := Format('onMessage %s(%s)', [Self.Name, TStringHelper.Join(',', vInputs)]);
end;

end.
