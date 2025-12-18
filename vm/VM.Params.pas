unit Vm.Params;

interface

uses
  System.Math.BigInteger,
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
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

const
  CallDepth = 512;  // Maximum Depth of call.
  StackLimit = 1024; // Maximum size of VM stack allowed.

  MaxCodeSize = 24575; // Maximum bytecode to permit for a contract
  OffChainReaderGas = 1000000;

  SnapshotCountMin = 0;
  SnapshotCountMax = 75;
  SnapshotWithSeedCountMin = 0;
  SnapshotWithSeedCountMax = 75;

  ContractModifyStorageMax = 100;

  Retry = True;
  NoRetry = False;

var
  CreateContractFee: TBigInteger;

implementation

uses
  Vite.Common.Helper, Vite.Vm.Util;

initialization
  CreateContractFee := TBigInteger.Multiply(Big10, AttovPerVite);

end.
