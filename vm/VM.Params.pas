unit Vm.Params;

interface

uses
  System.Math.BigInteger;

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
