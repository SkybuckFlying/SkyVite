unit VM.VM.Run.Test;

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
  VM.VM.Test;

type
	TVMRunTestCase = record
		SbHeight : UInt64;
		SbTime : Int64;
		SbHash : string;
		// ... many fields
	end;

procedure TestVM_RunV2;

implementation

procedure TestVM_RunV2;
begin
	// VM data-driven tests...
end;

end.
