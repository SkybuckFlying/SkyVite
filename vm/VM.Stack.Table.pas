unit Vm.StackTable;

interface

uses
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
  Vm.Stack Vm.Params Vm.Util,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  TStackValidationFunc = reference to function(Stack: IStack): Exception;

function MakeStackFunc(Pop, Push: Integer): TStackValidationFunc;
function MakeDupStackFunc(N: Integer): TStackValidationFunc;
function MakeSwapStackFunc(N: Integer): TStackValidationFunc;

implementation

function MakeStackFunc(Pop, Push: Integer): TStackValidationFunc;
begin
  Result := function(Stack: IStack): Exception
  begin
    if not Stack.Require(Pop) then
      Exit(ErrStackUnderflow);

    if (Stack.Len + Push - Pop) > StackLimit then
      Exit(ErrStackLimitReached);

    Result := nil;
  end;
end;

function MakeDupStackFunc(N: Integer): TStackValidationFunc;
begin
  Result := MakeStackFunc(N, N + 1);
end;

function MakeSwapStackFunc(N: Integer): TStackValidationFunc;
begin
  Result := MakeStackFunc(N, N);
end;

end.
