unit VM.Instructions;

interface

uses
  GoToDelphi.Helpers.BigInt,
  System.Classes,
  System.SysUtils,
  Vite.Common.Helper,
  Vite.Common.Types,
  Vite.Crypto,
  Vite.Interfaces.Core,
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
  VM.Gas.Table,
  VM.Gas.Table.Test,
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
  TExecutionFunc = function(ParaPc: PUInt64; const ParaVm: IVM; const ParaContract: IContract; const ParaMem: IMemory; const ParaStack: IStack): TPair<TBytes, Exception>;

function OpStop(ParaPc: PUInt64; const ParaVm: IVM; const ParaContract: IContract; const ParaMem: IMemory; const ParaStack: IStack): TPair<TBytes, Exception>;
// ... (declarations for all other op functions)
function MakePush(ParaSize: UInt64; ParaPushByteSize: Integer): TExecutionFunc;
function MakeDup(ParaSize: Integer): TExecutionFunc;
function MakeSwap(ParaSize: Integer): TExecutionFunc;
function MakeLog(ParaSize: Integer): TExecutionFunc;
function MakeOffchainLog(ParaSize: Integer): TExecutionFunc;

implementation

uses
  System.Math,
  System.NetEncoding,
  Vite.Crypto.Sha3,
  VM.Opcodes;

function OpStop(ParaPc: PUInt64; const ParaVm: IVM; const ParaContract: IContract; const ParaMem: IMemory; const ParaStack: IStack): TPair<TBytes, Exception>;
begin
  Result := TPair<TBytes, Exception>.Create(nil, nil);
end;

// ... (implementation of all other op functions with Para prefixes and begin/end blocks)

end.
