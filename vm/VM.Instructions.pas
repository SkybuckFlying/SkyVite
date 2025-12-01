unit VM.Instructions;

interface

uses
  System.SysUtils,
  System.Classes,
  GoToDelphi.Helpers.BigInt,
  Vite.Common.Helper,
  Vite.Common.Types,
  Vite.Crypto,
  Vite.Interfaces.Core,
  Vite.VM.Util,
  VM.Memory,
  VM.Stack,
  VM.Vm;

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
