unit Vm.StackTable;

interface

uses
  Vm.Stack, Vm.Params, Vm.Util;

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
