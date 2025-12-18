unit VM.Contract.Test;

interface

uses
  DUnitX.TestFramework,
  GoToDelphi.Helpers.BigInt,
  System.SysUtils,
  Vite.Common.Types,
  Vite.Interfaces.Core,
  VM,
  VM.Contract,
  VM.Contract.Test.Cases,
  VM.Contracts.Dex.Fund.Test,
  VM.Contracts.Dex.Trade.Test,
  VM.Contracts.Test,
  VM.Database,
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
  VM.Util,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  [TestFixture]
  TTestContract = class
  public
    [Test]
    [TestCase('TestRun', ContractTestCases[0])]
    [TestCase('TestRun', ContractTestCases[1])]
    [TestCase('TestRun', ContractTestCases[2])]
    [TestCase('TestRun', ContractTestCases[3])]
    [TestCase('TestRun', ContractTestCases[4])]
    [TestCase('TestRun', ContractTestCases[5])]
    [TestCase('TestRun', ContractTestCases[6])]
    procedure TestRun(const ATestCase: TContractTestCase);
  end;

implementation

uses
  System.Classes,
  Vite.Ledger;

procedure TTestContract.TestRun(const ATestCase: TContractTestCase);
var
  vm: IVM;
  sendCallBlock: IAccountBlock;
  receiveCallBlock: IAccountBlock;
  db: IVmDb;
  c: IContract;
  ret: TBytes;
  err: Exception;
begin
  // initEmptyFork; // This is not implemented in Delphi yet

  vm := TVM.Create(nil);
  vm.Interpreter := TInterpreter.Create(1, False);
  vm.GasTable := TQuotaTable.GetQuotaTableByHeight(1);

  sendCallBlock := TAccountBlock.Create;
  sendCallBlock.AccountAddress := TAddress.Empty;
  sendCallBlock.ToAddress := TAddress.Empty;
  sendCallBlock.BlockType := TBlockType.SendCall;
  sendCallBlock.Data := ATestCase.Input;
  sendCallBlock.Amount := TBigInt.Create(10);
  sendCallBlock.Fee := TBigInt.Create(0);
  sendCallBlock.TokenId := ViteTokenId;

  receiveCallBlock := TAccountBlock.Create;
  receiveCallBlock.AccountAddress := TAddress.Empty;
  receiveCallBlock.ToAddress := TAddress.Empty;
  receiveCallBlock.BlockType := TBlockType.Receive;

  db := TNoDatabase.Create;
  c := NewContract(receiveCallBlock, db, sendCallBlock, sendCallBlock.Data, 1000000);
  c.SetCallCode(TAddress.Empty, ATestCase.Input);

  err := nil;
  try
    ret := c.Run(vm);
  except
    on E: Exception do
      err := E;
  end;

  Assert.AreEqual<TBytes>(ATestCase.Result, ret, 'unexpected return value for ' + ATestCase.Summary);
  Assert.AreEqual(ATestCase.QuotaLeft, c.GetQuotaLeft, 'unexpected quota left for ' + ATestCase.Summary);

  if ATestCase.Err <> nil then
  begin
    Assert.IsNotNull(err, 'expected error for ' + ATestCase.Summary);
    Assert.AreEqual(ATestCase.Err, err.ClassType, 'unexpected error type for ' + ATestCase.Summary);
    if ATestCase.ErrMsg <> '' then
      Assert.AreEqual(ATestCase.ErrMsg, err.Message, 'unexpected error message for ' + ATestCase.Summary);
  end
  else
  begin
    Assert.IsNull(err, 'unexpected error for ' + ATestCase.Summary);
  end;
end;

initialization
  RegisterTestFixture(TTestContract);
end.
