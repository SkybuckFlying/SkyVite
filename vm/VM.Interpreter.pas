unit Vm.Interpreter;

interface

uses
  System.SysUtils System.Classes System.SyncObjs,
  Vite.Common.Helper Vite.Common.Upgrade Vite.Vm.Util,
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
  VM.VM,
  Vm.Vm Vm.Contract Vm.Memory Vm.Stack Vm.Opcodes,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  IOperation = interface
    ['{A7E0F5B8-3D2C-4B1A-9E0F-3B6C1E5D7F6A}']
    function GetValid: Boolean;
    function GetValidateStack: TValidateStackFunc;
    function GetMemorySize: TMemorySizeFunc;
    function GetGasCost: TGasFunc;
    function GetExecute: TExecutionFunc;
    function GetReturns: Boolean;
    function GetHalts: Boolean;
    function GetReverts: Boolean;
    function GetJumps: Boolean;
    function GetWrites: Boolean;
  end;

  IInterpreter = interface
    ['{B8F1A3B6-C1E5-4D7F-8A0B-4A3D2C1E5D7F}']
    function RunLoop(Vm: IVM; C: IContract): TBytes;
  end;

  TInterpreter = class(TInterfacedObject, IInterpreter)
  private
    FInstructionSet: array[0..255] of IOperation;
  public
    constructor Create(const AInstructionSet: array of IOperation);
    function RunLoop(Vm: IVM; C: IContract): TBytes;
  end;

function NewInterpreter(BlockHeight: UInt64; OffChain: Boolean): IInterpreter;

var
  SimpleInterpreter: IInterpreter;
  OffchainSimpleInterpreter: IInterpreter;
  RandInterpreter: IInterpreter;
  OffchainRandInterpreter: IInterpreter;
  EarthInterpreter: IInterpreter;
  OffchainEarthInterpreter: IInterpreter;

implementation

uses
  System.NetEncoding,
  Vite.Vm.Instructions;

{ TInterpreter }

constructor TInterpreter.Create(const AInstructionSet: array of IOperation);
var
  I: Integer;
begin
  for I := 0 to 255 do
    FInstructionSet[I] := AInstructionSet[I];
end;

function TInterpreter.RunLoop(Vm: IVM; C: IContract): TBytes;
var
  Op: TOpCode;
  Mem: IMemory;
  St: IStack;
  Pc: UInt64;
  Cost, MemorySize: UInt64;
  Flag, Overflow: Boolean;
  Err: Exception;
  Operation: IOperation;
  Res: TBytes;
  CurrentPc: UInt64;
  CurrentCode: string;
  StorageMap: TDictionary<string, TBytes>;
begin
  C.ReturnData := nil;
  Mem := NewMemory;
  St := NewStack;
  Pc := 0;

  while TInterlocked.Read(Vm.Abort) = 0 do
  begin
    CurrentPc := Pc;
    Op := C.GetOp(Pc);
    Operation := FInstructionSet[Ord(Op)];

    if not Operation.Valid then
      raise EInvalidOpCode.CreateFmt('invalid opcode: %d', [Ord(Op)]);

    Operation.ValidateStack(St);

    if Operation.MemorySize <> nil then
    begin
      MemorySize := BigToUInt64(Operation.MemorySize(St), Overflow);
      if Overflow then
        raise EMemSizeOverflow.Create('');
      MemorySize := SafeMul(ToWordSize(MemorySize), WordSize, Overflow);
      if Overflow then
        raise EMemSizeOverflow.Create('');
    end
    else
      MemorySize := 0;

    Cost := Operation.GasCost(Vm, C, St, Mem, MemorySize, Flag, Err);
    if Err <> nil then
      raise Err;
    C.QuotaLeft := UseQuotaWithFlag(C.QuotaLeft, Cost, Flag);

    if MemorySize > 0 then
      Mem.Resize(MemorySize);

    Res := Operation.Execute(@Pc, Vm, C, Mem, St, Err);

    if NodeConfig.IsDebug then
    begin
      CurrentCode := '';
      if CurrentPc < Length(C.Code) then
        CurrentCode := TNetEncoding.Base64.EncodeBytesToString(Copy(C.Code, CurrentPc, Length(C.Code) - CurrentPc));
      StorageMap := C.Db.DebugGetStorage;
      NodeConfig.InterpreterLog.Info('vm step', ['blockType', Ord(C.Block.BlockType), 'address', C.Block.AccountAddress.ToString, 'height', C.Block.Height, 'fromHash', C.Block.FromBlockHash.ToString, #13#10'current code', CurrentCode, #13#10'op', OpCodeToString[Op], 'pc', CurrentPc, 'quotaLeft', C.QuotaLeft, #13#10'stack', St.Print, #13#10'memory', Mem.Print, #13#10'storage', PrintMap(StorageMap)]);
    end;

    if Operation.Returns then
      C.ReturnData := Res;

    if Err <> nil then
      raise Err;
    if Operation.Halts then
      Exit(Res);
    if Operation.Reverts then
      raise EExecutionReverted.Create(TEncoding.UTF8.GetString(Res));
    if not Operation.Jumps then
      Inc(Pc);
  end;
  raise EExecutionCanceled.Create('');
end;

function NewInterpreter(BlockHeight: UInt64; OffChain: Boolean): IInterpreter;
begin
  if IsEarthUpgrade(BlockHeight) then
  begin
    if OffChain then
      Result := OffchainEarthInterpreter
    else
      Result := EarthInterpreter;
  end
  else if IsSeedUpgrade(BlockHeight) then
  begin
    if OffChain then
      Result := OffchainRandInterpreter
    else
      Result := RandInterpreter;
  end
  else
  begin
    if OffChain then
      Result := OffchainSimpleInterpreter
    else
      Result := SimpleInterpreter;
  end;
end;

initialization
  SimpleInterpreter := TInterpreter.Create(SimpleInstructionSet);
  OffchainSimpleInterpreter := TInterpreter.Create(OffchainSimpleInstructionSet);
  RandInterpreter := TInterpreter.Create(RandInstructionSet);
  OffchainRandInterpreter := TInterpreter.Create(OffchainRandInstructionSet);
  EarthInterpreter := TInterpreter.Create(EarthInstructionSet);
  OffchainEarthInterpreter := TInterpreter.Create(OffchainEarthInstructionSet);
end.
