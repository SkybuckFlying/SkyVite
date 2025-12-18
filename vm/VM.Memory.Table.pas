unit Vm.MemoryTable;

interface

uses
  System.Math.BigInteger,
  Vite.Common.Helper Vm.Stack,
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
  VM.Memory.Test,
  VM.Mock.DB,
  VM.Opcodes,
  VM.Params,
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  TMemorySizeFunc = function(Stack: IStack): TBigInteger;

function CalcMemSize(Off, L: TBigInteger): TBigInteger;
function MemorySha3(Stack: IStack): TBigInteger;
function MemoryBlake2b(Stack: IStack): TBigInteger;
function MemoryCallDataCopy(Stack: IStack): TBigInteger;
function MemoryCodeCopy(Stack: IStack): TBigInteger;
function MemoryExtCodeCopy(Stack: IStack): TBigInteger;
function MemoryReturnDataCopy(Stack: IStack): TBigInteger;
function MemoryMLoad(Stack: IStack): TBigInteger;
function MemoryMStore(Stack: IStack): TBigInteger;
function MemoryMStore8(Stack: IStack): TBigInteger;
function MemoryLog(Stack: IStack): TBigInteger;
function MemoryDelegateCall(Stack: IStack): TBigInteger;
function MemoryCall(Stack: IStack): TBigInteger;
function MemoryReturn(Stack: IStack): TBigInteger;
function MemoryRevert(Stack: IStack): TBigInteger;

implementation

uses
  System.Math;

function CalcMemSize(Off, L: TBigInteger): TBigInteger;
begin
  if L.IsZero then
    Exit(TBigInteger.Zero);
  Result := Off + L;
end;

function MemorySha3(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Stack.Back(1));
end;

function MemoryBlake2b(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Stack.Back(1));
end;

function MemoryCallDataCopy(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Stack.Back(2));
end;

function MemoryCodeCopy(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Stack.Back(2));
end;

function MemoryExtCodeCopy(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(1), Stack.Back(3));
end;

function MemoryReturnDataCopy(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Stack.Back(2));
end;

function MemoryMLoad(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Big32);
end;

function MemoryMStore(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Big32);
end;

function MemoryMStore8(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Big1);
end;

function MemoryLog(Stack: IStack): TBigInteger;
var
  MSize, MStart: TBigInteger;
begin
  MSize := Stack.Back(1);
  MStart := Stack.Back(0);
  Result := CalcMemSize(MStart, MSize);
end;

function MemoryDelegateCall(Stack: IStack): TBigInteger;
var
  X, Y: TBigInteger;
begin
  X := CalcMemSize(Stack.Back(3), Stack.Back(4));
  Y := CalcMemSize(Stack.Back(1), Stack.Back(2));
  Result := Max(X, Y);
end;

function MemoryCall(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(3), Stack.Back(4));
end;

function MemoryReturn(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Stack.Back(1));
end;

function MemoryRevert(Stack: IStack): TBigInteger;
begin
  Result := CalcMemSize(Stack.Back(0), Stack.Back(1));
end;

end.
