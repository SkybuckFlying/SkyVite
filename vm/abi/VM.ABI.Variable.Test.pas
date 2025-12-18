unit VM.ABI.Variable.Test;

interface

uses
  Common.Types,
  System.Classes,
  System.JSON,
  System.Rtti,
  System.SysUtils,
  unit_GoLang_Compatibility_version_006,
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
  VM.ABI.Type,
  VM.ABI.Type.Test,
  VM.ABI.Unpack,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable;

procedure TestVariableMultiValueWithArray;
procedure TestVariableTuple;
procedure TestVariableUnpackIndexed;
procedure TestVariableIndexedWithArrayUnpack;

implementation

procedure TestVariableMultiValueWithArray;
begin
	// variable array tests...
end;

procedure TestVariableTuple;
begin
	// variable tuple tests...
end;

procedure TestVariableUnpackIndexed;
begin
	// variable indexed tests...
end;

procedure TestVariableIndexedWithArrayUnpack;
begin
	// variable indexed array tests...
end;

end.
