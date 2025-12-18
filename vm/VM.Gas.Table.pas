unit VM.GasTable;

interface

uses
  GoToDelphi.Helpers.BigInt,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Vite.Common.Helper,
  Vite.Common.Types,
  Vite.Common.Upgrade,
  Vite.Interfaces,
  Vite.Interfaces.Core,
  Vite.VM.Contracts,
  Vite.VM.Util,
  VM.Contract,
  VM.Contract.Test,
  VM.Contracts.Dex.Fund.Test,
  VM.Contracts.Dex.Trade.Test,
  VM.Contracts.Test,
  VM.Database.Memory.Test,
  VM.Database.Test,
  VM.Destination,
  VM.Destination.Test,
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
  VM.Vm,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  TGasFunc = function(const ParaVm: IVM; const ParaContract: IContract; const ParaStack: IStack; const ParaMem: IMemory; ParaMemorySize: UInt64): TTriple<UInt64, Boolean, Exception>;

function MemoryGasCost(const ParaVm: IVM; const ParaMem: IMemory; ParaNewMemSize: UInt64): TTriple<UInt64, Boolean, Exception>;
function ConstGasFunc(ParaGas: UInt64): TGasFunc;
function GasAdd(const ParaVm: IVM; const ParaContract: IContract; const ParaStack: IStack; const ParaMem: IMemory; ParaMemorySize: UInt64): TTriple<UInt64, Boolean, Exception>;
// ... (declarations for all other gas functions)
function GasRequiredForBlock(const ParaDb: IVmDb; const ParaBlock: IAccountBlock; const ParaGasTable: IQuotaTable; ParaSbHeight: UInt64): TPair<UInt64, Exception>;
function GasRequiredForSendBlock(const ParaBlock: IAccountBlock; const ParaGasTable: IQuotaTable; ParaSbHeight: UInt64): TPair<UInt64, Exception>;
function GasSendCreate(const ParaBlock: IAccountBlock; const ParaGasTable: IQuotaTable): TPair<UInt64, Exception>;
function GasReceiveCreate(const ParaBlock: IAccountBlock; const ParaMeta: IContractMeta; const ParaGasTable: IQuotaTable): TPair<UInt64, Exception>;
function GasUserSendCall(const ParaBlock: IAccountBlock; const ParaGasTable: IQuotaTable; ParaSbHeight: UInt64): TPair<UInt64, Exception>;
function GasReceive(const ParaBlock: IAccountBlock; const ParaMeta: IContractMeta; const ParaGasTable: IQuotaTable): TPair<UInt64, Exception>;
function GasSendCall(const ParaBlock: IAccountBlock; const ParaGasTable: IQuotaTable): TPair<UInt64, Exception>;

implementation

uses
  VM.Params;

// memoryGasCosts calculates the quadratic gas for memory expansion. It does so
// only for the memory region that is expanded, not the total memory.
function MemoryGasCost(const ParaVm: IVM; const ParaMem: IMemory; ParaNewMemSize: UInt64): TTriple<UInt64, Boolean, Exception>;
var
  vNewMemSizeWords, vSquare, vLinCoef, vQuadCoef, vNewTotalFee, vFee: UInt64;
begin
  if ParaNewMemSize = 0 then
  begin
    Result := TTriple<UInt64, Boolean, Exception>.Create(0, True, nil);
    Exit;
  end;
  // The maximum that will fit in a uint64 is max_word_count - 1
  // anything above that will result in an overflow.
  // Additionally, a newMemSize which results in a
  // newMemSizeWords larger than 0x7ffffffff will cause the square operation
  // to overflow.
  // The constant ç is the highest number that can be used without
  // overflowing the gas calculation
  if ParaNewMemSize > $fffffffffe0 then
  begin
    Result := TTriple<UInt64, Boolean, Exception>.Create(0, True, ErrGasUintOverflow);
    Exit;
  end;

  vNewMemSizeWords := ToWordSize(ParaNewMemSize);
  ParaNewMemSize := vNewMemSizeWords * WordSize;

  if ParaNewMemSize > ParaMem.GetLen then
  begin
    vSquare := vNewMemSizeWords * vNewMemSizeWords;
    vLinCoef := vNewMemSizeWords * ParaVm.GasTable.MemQuota;
    vQuadCoef := vSquare div ParaVm.GasTable.MemQuotaDivision;
    vNewTotalFee := vLinCoef + vQuadCoef;

    vFee := vNewTotalFee - ParaMem.GetLastGasCost;
    ParaMem.SetLastGasCost(vNewTotalFee);

    Result := TTriple<UInt64, Boolean, Exception>.Create(vFee, True, nil);
  end
  else
  begin
    Result := TTriple<UInt64, Boolean, Exception>.Create(0, True, nil);
  end;
end;

// ... (implementation of all other gas functions with Para prefixes and begin/end blocks)

end.
