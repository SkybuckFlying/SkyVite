unit Vm.Stack;

interface

uses
  System.SysUtils System.Classes System.Generics.Collections System.Math.BigInteger,
  Vite.Vm.Util,
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
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  IStack = interface
    ['{3E6DB82B-E5B4-4B41-8E4A-3582A8D39E6D}']
    procedure Push(d: TBigInteger);
    function Pop: TBigInteger;
    function Peek: TBigInteger;
    function Len: Integer;
    function Require(n: Integer): Boolean;
    function Back(n: Integer): TBigInteger;
    procedure Dup(pool: TIntPool; n: Integer);
    procedure Swap(n: Integer);
    function Print: string;
  end;

  TStack = class(TInterfacedObject, IStack)
  private
    FData: TList<TBigInteger>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(d: TBigInteger);
    function Pop: TBigInteger;
    function Peek: TBigInteger;
    function Len: Integer;
    function Require(n: Integer): Boolean;
    function Back(n: Integer): TBigInteger;
    procedure Dup(pool: TIntPool; n: Integer);
    procedure Swap(n: Integer);
    function Print: string;
  end;

function NewStack: IStack;

implementation

uses
  Vite.Vm.Params;

{ TStack }

constructor TStack.Create;
begin
  FData := TList<TBigInteger>.Create;
end;

destructor TStack.Destroy;
begin
  FData.Free;
  inherited;
end;

procedure TStack.Push(d: TBigInteger);
begin
  if FData.Count >= StackLimit then
    raise Exception.Create('stack limit reached');
  FData.Add(d);
end;

function TStack.Pop: TBigInteger;
begin
  if FData.Count = 0 then
    raise Exception.Create('stack underflow');
  Result := FData.Last;
  FData.Delete(FData.Count - 1);
end;

function TStack.Peek: TBigInteger;
begin
  if FData.Count = 0 then
    raise Exception.Create('stack underflow');
  Result := FData.Last;
end;

function TStack.Len: Integer;
begin
  Result := FData.Count;
end;

function TStack.Require(n: Integer): Boolean;
begin
  if Len < n then
  begin
    // In Go, it logs an error and returns ErrStackUnderflow.
    // Here we return false and the caller can raise an exception.
    Result := False;
    Exit;
  end;
  Result := True;
end;

function TStack.Back(n: Integer): TBigInteger;
begin
  if Len <= n then
    raise Exception.Create('stack underflow');
  Result := FData[Len - n - 1];
end;

procedure TStack.Dup(pool: TIntPool; n: Integer);
var
  val: TBigInteger;
begin
  if Len < n then
    raise Exception.Create('stack underflow');
  val := pool.Get();
  val.SetValue(FData[Len - n]);
  Push(val);
end;

procedure TStack.Swap(n: Integer);
var
  val1, val2: TBigInteger;
begin
  if Len <= n then
    raise Exception.Create('stack underflow');
  val1 := FData[Len - n];
  val2 := FData[Len - 1];
  FData[Len - n] := val2;
  FData[Len - 1] := val1;
end;

function TStack.Print: string;
var
  S: TStringBuilder;
  I: Integer;
begin
  S := TStringBuilder.Create;
  try
    for I := 0 to FData.Count - 1 do
    begin
      S.Append(FData[I].ToHexString);
      if I < FData.Count - 1 then
        S.Append(', ');
    end;
    Result := S.ToString;
  finally
    S.Free;
  end;
end;

function NewStack: IStack;
begin
  Result := TStack.Create;
end;

end.
