unit VM.GasTable.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  VM,
  VM.GasTable,
  VM.Memory,
  VM.Util,
  Vite.Common.Helper;

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
