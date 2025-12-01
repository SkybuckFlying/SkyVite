unit VM.Abi.Variable;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  VM.Abi.Argument;

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
