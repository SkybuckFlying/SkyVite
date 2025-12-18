unit VM.GasTable.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Vite.Common.Helper,
  VM,
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
  VM.GasTable,
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
  VM.Util,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  [TestFixture]
  TTestGasTable = class
  public
    [Test]
    procedure TestMemoryGasCost;
  end;

implementation

procedure TTestGasTable.TestMemoryGasCost;
var
  vVm: IVM;
  vSize: UInt64;
  vValue: UInt64;
  vErr: Exception;
  vTriple: TTriple<UInt64, Boolean, Exception>;
begin
  // initEmptyFork; // This is not implemented in Delphi yet

  vVm := TVM.Create(nil);
  vVm.GasTable := TQuotaTable.GetQuotaTableByHeight(1);

  vSize := $fffffffffe0;
  vTriple := MemoryGasCost(vVm, TMemory.Create, vSize);
  vErr := vTriple.Value2;
  vValue := vTriple.Key;
  Assert.IsNull(vErr, 'didn''t expect error: ' + vErr.Message);
  Assert.AreEqual(36028899963961341, vValue, 'unexpected gas cost');

  vTriple := MemoryGasCost(vVm, TMemory.Create, vSize + 1);
  vErr := vTriple.Value2;
  Assert.IsNotNull(vErr, 'expected error');

  vTriple := MemoryGasCost(vVm, TMemory.Create, MaxUInt64 - 64);
  vErr := vTriple.Value2;
  Assert.IsNotNull(vErr, 'expected error');
end;

initialization
  RegisterTestFixture(TTestGasTable);
end.
