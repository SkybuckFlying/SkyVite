unit VM.VM.Test;

interface

uses
	System.SysUtils,
	System.Classes,
	System.JSON,
	System.Math,
	Common.Types,
	Interfaces,
	Interfaces.Core,
	VM.VM,
	unit_GoLang_Compatibility_version_006;

procedure TestVmRun;
procedure TestCall;
procedure TestVmInterpreter;
procedure TestOffChainReader;

implementation

procedure TestVmRun;
begin
	// VM run tests (create/call)...
end;

procedure TestCall;
begin
	// VM call tests (contract calling contract)...
end;

procedure TestVmInterpreter;
begin
	// VM interpreter tests...
end;

procedure TestOffChainReader;
begin
	// VM off-chain reader tests...
end;

end.
