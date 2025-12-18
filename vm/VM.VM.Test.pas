unit VM.VM.Test;

interface

uses
  Common.Types,
  Interfaces,
  Interfaces.Core,
  System.Classes,
  System.JSON,
  System.Math,
  System.SysUtils,
  unit_GoLang_Compatibility_version_006,
  VM.Contract,
  VM.Contract.Test,
  VM.Contracts.Dex.Fund.Test,
  VM.Contracts.Dex.Trade.Test,
  VM.Contracts.Test,
  VM.Database.Memory.Test,
  VM.Database.Test,
  VM.Destination,
  VM.Destination.Test,
  VM.Gas.Table,
  VM.Gas.Table.Test,
  VM.Instructions,
  VM.Instructions.Test,
  VM.Interpreter,
  VM.Jump.Table,
  VM.Memory,
  VM.Memory.Table,
  VM.Memory.Test,
  VM.Mock.DB,
  VM.Opcodes,
  VM.Params,
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test;

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
