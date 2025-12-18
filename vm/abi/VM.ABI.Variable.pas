unit VM.Abi.Variable;

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
  VM.ABI.Method,
  VM.ABI.Numbers,
  VM.ABI.Numbers.Test,
  VM.ABI.Pack,
  VM.ABI.Pack.Test,
  VM.ABI.Reflect,
  VM.ABI.Type,
  VM.ABI.Type.Test,
  VM.ABI.Unpack,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable.Test;

type
  TVariable = record
    Name: string;
    Inputs: TArguments;
    function ToString: string;
  end;

implementation

uses
  System.StrUtils;

{ TVariable }

function TVariable.ToString: string;
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
  Result := Format('struct %s { %s }', [Self.Name, TStringHelper.Join(',', vInputs)]);
end;

end.
