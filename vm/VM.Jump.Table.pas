unit Vm.JumpTable;

interface

uses
  System.SysUtils, System.Classes, System.Math.BigInteger,
  Vm.Vm, Vm.Contract, Vm.Memory, Vm.Stack, Vm.Opcodes, Vm.Instructions,
  Vm.GasTable, Vm.MemoryTable, Vm.StackTable;

type
  TOperation = class(TInterfacedObject, IOperation)
  private
    FValid: Boolean;
    FValidateStack: TStackValidationFunc;
    FMemorySize: TMemorySizeFunc;
    FGasCost: TGasFunc;
    FExecute: TExecutionFunc;
    FReturns: Boolean;
    FHalts: Boolean;
    FReverts: Boolean;
    FJumps: Boolean;
    FWrites: Boolean;
  public
    constructor Create(AValid: Boolean; AValidateStack: TStackValidationFunc; AMemorySize: TMemorySizeFunc; AGasCost: TGasFunc; AExecute: TExecutionFunc; AReturns, AHalts, AReverts, AJumps, AWrites: Boolean);
    function GetValid: Boolean;
    function GetValidateStack: TStackValidationFunc;
    function GetMemorySize: TMemorySizeFunc;
    function GetGasCost: TGasFunc;
    function GetExecute: TExecutionFunc;
    function GetReturns: Boolean;
    function GetHalts: Boolean;
    function GetReverts: Boolean;
    function GetJumps: Boolean;
    function GetWrites: Boolean;
  end;

var
  SimpleInstructionSet: array[0..255] of IOperation;
  OffchainSimpleInstructionSet: array[0..255] of IOperation;
  RandInstructionSet: array[0..255] of IOperation;
  OffchainRandInstructionSet: array[0..255] of IOperation;
  EarthInstructionSet: array[0..255] of IOperation;
  OffchainEarthInstructionSet: array[0..255] of IOperation;

procedure NewEarthInstructionSet(var InstructionSet: array of IOperation);
procedure NewEarthOffchainInstructionSet(var InstructionSet: array of IOperation);
procedure NewRandInstructionSet(var InstructionSet: array of IOperation);
procedure NewRandOffchainInstructionSet(var InstructionSet: array of IOperation);
procedure NewSimpleInstructionSet(var InstructionSet: array of IOperation);
procedure NewOffchainSimpleInstructionSet(var InstructionSet: array of IOperation);
procedure NewBaseInstructionSet(var InstructionSet: array of IOperation);

implementation

{ TOperation }

constructor TOperation.Create(AValid: Boolean; AValidateStack: TStackValidationFunc; AMemorySize: TMemorySizeFunc; AGasCost: TGasFunc; AExecute: TExecutionFunc; AReturns, AHalts, AReverts, AJumps, AWrites: Boolean);
begin
  FValid := AValid;
  FValidateStack := AValidateStack;
  FMemorySize := AMemorySize;
  FGasCost := AGasCost;
  FExecute := AExecute;
  FReturns := AReturns;
  FHalts := AHalts;
  FReverts := AReverts;
  FJumps := AJumps;
  FWrites := AWrites;
end;

function TOperation.GetValid: Boolean; begin Result := FValid; end;
function TOperation.GetValidateStack: TStackValidationFunc; begin Result := FValidateStack; end;
function TOperation.GetMemorySize: TMemorySizeFunc; begin Result := FMemorySize; end;
function TOperation.GetGasCost: TGasFunc; begin Result := FGasCost; end;
function TOperation.GetExecute: TExecutionFunc; begin Result := FExecute; end;
function TOperation.GetReturns: Boolean; begin Result := FReturns; end;
function TOperation.GetHalts: Boolean; begin Result := FHalts; end;
function TOperation.GetReverts: Boolean; begin Result := FReverts; end;
function TOperation.GetJumps: Boolean; begin Result := FJumps; end;
function TOperation.GetWrites: Boolean; begin Result := FWrites; end;

procedure NewEarthInstructionSet(var InstructionSet: array of IOperation);
begin
  NewRandInstructionSet(InstructionSet);
  InstructionSet[Ord(TOpCode.CALL2)] := TOperation.Create(True, MakeStackFunc(5, 1), nil, GasCall2, OpCall2, False, False, False, False, False);
end;

procedure NewEarthOffchainInstructionSet(var InstructionSet: array of IOperation);
begin
  NewRandOffchainInstructionSet(InstructionSet);
  InstructionSet[Ord(TOpCode.CALL2)] := TOperation.Create(True, MakeStackFunc(5, 1), nil, GasCall2, OpOffchainCall2, False, False, False, False, False);
end;

procedure NewRandInstructionSet(var InstructionSet: array of IOperation);
begin
  NewSimpleInstructionSet(InstructionSet);
  InstructionSet[Ord(TOpCode.RANDOM)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasRandom, OpRandom, False, False, False, False, False);
end;

procedure NewRandOffchainInstructionSet(var InstructionSet: array of IOperation);
begin
  NewOffchainSimpleInstructionSet(InstructionSet);
  InstructionSet[Ord(TOpCode.RANDOM)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasRandom, OpOffchainRandom, False, False, False, False, False);
end;

procedure NewSimpleInstructionSet(var InstructionSet: array of IOperation);
begin
  NewBaseInstructionSet(InstructionSet);
  InstructionSet[Ord(TOpCode.FROMHASH)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasFromHash, OpFromHash, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SEED)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasSeed, OpSeed, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.CALLER)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasCaller, OpCaller, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.CALLVALUE)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasCallValue, OpCallValue, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.TIMESTAMP)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasTimestamp, OpTimestamp, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.HEIGHT)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasHeight, OpHeight, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.TOKENID)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasTokenId, OpTokenID, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SSTORE)] := TOperation.Create(True, MakeStackFunc(2, 0), nil, GasSStore, OpSStore, False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG0)] := TOperation.Create(True, MakeStackFunc(2, 0), MemoryLog, MakeGasLog(0), MakeLog(0), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG1)] := TOperation.Create(True, MakeStackFunc(3, 0), MemoryLog, MakeGasLog(1), MakeLog(1), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG2)] := TOperation.Create(True, MakeStackFunc(4, 0), MemoryLog, MakeGasLog(2), MakeLog(2), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG3)] := TOperation.Create(True, MakeStackFunc(5, 0), MemoryLog, MakeGasLog(3), MakeLog(3), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG4)] := TOperation.Create(True, MakeStackFunc(6, 0), MemoryLog, MakeGasLog(4), MakeLog(4), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.CALL)] := TOperation.Create(True, MakeStackFunc(5, 0), MemoryCall, GasCall, OpCall, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.REVERT)] := TOperation.Create(True, MakeStackFunc(2, 0), MemoryRevert, GasRevert, OpRevert, True, False, True, False, False);
end;

procedure NewOffchainSimpleInstructionSet(var InstructionSet: array of IOperation);
begin
  NewBaseInstructionSet(InstructionSet);
  InstructionSet[Ord(TOpCode.FROMHASH)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasFromHash, OpOffchainFromHash, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SEED)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasSeed, OpOffchainSeed, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.CALLER)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasCaller, OpOffchainCaller, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.CALLVALUE)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasCallValue, OpOffchainCallValue, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.TIMESTAMP)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasTimestamp, OpOffchainTimestamp, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.HEIGHT)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasHeight, OpOffchainHeight, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.TOKENID)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasTokenId, OpOffchainTokenID, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SSTORE)] := TOperation.Create(True, MakeStackFunc(2, 0), nil, GasSStore, OpOffchainSStore, False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG0)] := TOperation.Create(True, MakeStackFunc(2, 0), MemoryLog, MakeGasLog(0), MakeOffchainLog(0), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG1)] := TOperation.Create(True, MakeStackFunc(3, 0), MemoryLog, MakeGasLog(1), MakeOffchainLog(1), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG2)] := TOperation.Create(True, MakeStackFunc(4, 0), MemoryLog, MakeGasLog(2), MakeOffchainLog(2), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG3)] := TOperation.Create(True, MakeStackFunc(5, 0), MemoryLog, MakeGasLog(3), MakeOffchainLog(3), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.LOG4)] := TOperation.Create(True, MakeStackFunc(6, 0), MemoryLog, MakeGasLog(4), MakeOffchainLog(4), False, False, False, False, True);
  InstructionSet[Ord(TOpCode.CALL)] := TOperation.Create(True, MakeStackFunc(5, 0), MemoryCall, GasCall, OpOffchainCall, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.REVERT)] := TOperation.Create(True, MakeStackFunc(2, 0), MemoryRevert, GasRevert, OpOffchainRevert, False, True, False, False, False);
end;

procedure NewBaseInstructionSet(var InstructionSet: array of IOperation);
var
  I: Integer;
begin
  for I := 0 to 255 do
    InstructionSet[I] := TOperation.Create(False, nil, nil, nil, nil, False, False, False, False, False);

  InstructionSet[Ord(TOpCode.STOP)] := TOperation.Create(True, MakeStackFunc(0, 0), nil, ConstGasFunc(0), OpStop, False, True, False, False, False);
  InstructionSet[Ord(TOpCode.ADD)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasAdd, OpAdd, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.MUL)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasMul, OpMul, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SUB)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasSub, OpSub, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DIV)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasDiv, OpDiv, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SDIV)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasSdiv, OpSdiv, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.MOD_OP)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasMod, OpMod, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SMOD)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasSmod, OpSmod, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.ADDMOD)] := TOperation.Create(True, MakeStackFunc(3, 1), nil, GasAddmod, OpAddmod, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.MULMOD)] := TOperation.Create(True, MakeStackFunc(3, 1), nil, GasMulmod, OpMulmod, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.EXP)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasExp, OpExp, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SIGNEXTEND)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasSignextend, OpSignExtend, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.LT)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasLt, OpLt, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.GT)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasGt, OpGt, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SLT)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasSlt, OpSlt, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SGT)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasSgt, OpSgt, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.EQ)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasEq, OpEq, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.ISZERO)] := TOperation.Create(True, MakeStackFunc(1, 1), nil, GasIszero, OpIszero, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.AND_OP)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasAnd, OpAnd, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.OR_OP)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasOr, OpOr, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.XOR_OP)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasXor, OpXor, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.NOT_OP)] := TOperation.Create(True, MakeStackFunc(1, 1), nil, GasNot, OpNot, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.BYTE)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasByte, OpByte, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SHL)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasShl, OpSHL, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SHR)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasShr, OpSHR, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SAR)] := TOperation.Create(True, MakeStackFunc(2, 1), nil, GasSar, OpSAR, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SHA3)] := TOperation.Create(True, MakeStackFunc(2, 1), MemorySha3, GasBlake2b, OpSha3, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.BLAKE2B)] := TOperation.Create(True, MakeStackFunc(2, 1), MemoryBlake2b, GasBlake2b, OpBlake2b, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.ADDRESS)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasAddress, OpAddress, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.CALLDATALOAD)] := TOperation.Create(True, MakeStackFunc(1, 1), nil, GasCalldataload, OpCallDataLoad, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.CALLDATASIZE)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasCalldatasize, OpCallDataSize, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.CALLDATACOPY)] := TOperation.Create(True, MakeStackFunc(3, 0), MemoryCallDataCopy, GasCallDataCopy, OpCallDataCopy, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.CODESIZE)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasCodesize, OpCodeSize, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.CODECOPY)] := TOperation.Create(True, MakeStackFunc(3, 0), MemoryCodeCopy, GasCodeCopy, OpCodeCopy, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.RETURNDATASIZE)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasReturndatasize, OpReturnDataSize, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.RETURNDATACOPY)] := TOperation.Create(True, MakeStackFunc(3, 0), MemoryReturnDataCopy, GasReturnDataCopy, OpReturnDataCopy, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.POP)] := TOperation.Create(True, MakeStackFunc(1, 0), nil, GasPop, OpPop, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.MLOAD)] := TOperation.Create(True, MakeStackFunc(1, 1), MemoryMLoad, GasMLoad, OpMload, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.MSTORE)] := TOperation.Create(True, MakeStackFunc(2, 0), MemoryMStore, GasMStore, OpMstore, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.MSTORE8)] := TOperation.Create(True, MakeStackFunc(2, 0), MemoryMStore8, GasMStore8, OpMstore8, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SLOAD)] := TOperation.Create(True, MakeStackFunc(1, 1), nil, GasSload, OpSLoad, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.JUMP)] := TOperation.Create(True, MakeStackFunc(1, 0), nil, GasJump, OpJump, False, False, False, True, False);
  InstructionSet[Ord(TOpCode.JUMPI)] := TOperation.Create(True, MakeStackFunc(2, 0), nil, GasJumpi, OpJumpi, False, False, False, True, False);
  InstructionSet[Ord(TOpCode.PC)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPc, OpPc, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.MSIZE)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasMsize, OpMsize, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.JUMPDEST)] := TOperation.Create(True, MakeStackFunc(0, 0), nil, GasJumpdest, OpJumpdest, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH1)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(1, 1), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH2)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(2, 2), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH3)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(3, 3), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH4)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(4, 4), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH5)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(5, 5), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH6)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(6, 6), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH7)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(7, 7), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH8)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(8, 8), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH9)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(9, 9), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH10)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(10, 10), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH11)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(11, 11), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH12)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(12, 12), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH13)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(13, 13), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH14)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(14, 14), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH15)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(15, 15), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH16)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(16, 16), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH17)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(17, 17), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH18)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(18, 18), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH19)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(19, 19), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH20)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(20, 20), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH21)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(21, 21), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH22)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(22, 22), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH23)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(23, 23), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH24)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(24, 24), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH25)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(25, 25), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH26)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(26, 26), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH27)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(27, 27), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH28)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(28, 28), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH29)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(29, 29), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH30)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(30, 30), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH31)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(31, 31), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PUSH32)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPush, MakePush(32, 32), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP1)] := TOperation.Create(True, MakeDupStackFunc(1), nil, GasDup, MakeDup(1), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP2)] := TOperation.Create(True, MakeDupStackFunc(2), nil, GasDup, MakeDup(2), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP3)] := TOperation.Create(True, MakeDupStackFunc(3), nil, GasDup, MakeDup(3), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP4)] := TOperation.Create(True, MakeDupStackFunc(4), nil, GasDup, MakeDup(4), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP5)] := TOperation.Create(True, MakeDupStackFunc(5), nil, GasDup, MakeDup(5), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP6)] := TOperation.Create(True, MakeDupStackFunc(6), nil, GasDup, MakeDup(6), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP7)] := TOperation.Create(True, MakeDupStackFunc(7), nil, GasDup, MakeDup(7), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP8)] := TOperation.Create(True, MakeDupStackFunc(8), nil, GasDup, MakeDup(8), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP9)] := TOperation.Create(True, MakeDupStackFunc(9), nil, GasDup, MakeDup(9), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP10)] := TOperation.Create(True, MakeDupStackFunc(10), nil, GasDup, MakeDup(10), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP11)] := TOperation.Create(True, MakeDupStackFunc(11), nil, GasDup, MakeDup(11), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP12)] := TOperation.Create(True, MakeDupStackFunc(12), nil, GasDup, MakeDup(12), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP13)] := TOperation.Create(True, MakeDupStackFunc(13), nil, GasDup, MakeDup(13), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP14)] := TOperation.Create(True, MakeDupStackFunc(14), nil, GasDup, MakeDup(14), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP15)] := TOperation.Create(True, MakeDupStackFunc(15), nil, GasDup, MakeDup(15), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.DUP16)] := TOperation.Create(True, MakeDupStackFunc(16), nil, GasDup, MakeDup(16), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP1)] := TOperation.Create(True, MakeSwapStackFunc(2), nil, GasSwap, MakeSwap(1), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP2)] := TOperation.Create(True, MakeSwapStackFunc(3), nil, GasSwap, MakeSwap(2), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP3)] := TOperation.Create(True, MakeSwapStackFunc(4), nil, GasSwap, MakeSwap(3), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP4)] := TOperation.Create(True, MakeSwapStackFunc(5), nil, GasSwap, MakeSwap(4), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP5)] := TOperation.Create(True, MakeSwapStackFunc(6), nil, GasSwap, MakeSwap(5), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP6)] := TOperation.Create(True, MakeSwapStackFunc(7), nil, GasSwap, MakeSwap(6), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP7)] := TOperation.Create(True, MakeSwapStackFunc(8), nil, GasSwap, MakeSwap(7), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP8)] := TOperation.Create(True, MakeSwapStackFunc(9), nil, GasSwap, MakeSwap(8), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP9)] := TOperation.Create(True, MakeSwapStackFunc(10), nil, GasSwap, MakeSwap(9), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP10)] := TOperation.Create(True, MakeSwapStackFunc(11), nil, GasSwap, MakeSwap(10), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP11)] := TOperation.Create(True, MakeSwapStackFunc(12), nil, GasSwap, MakeSwap(11), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP12)] := TOperation.Create(True, MakeSwapStackFunc(13), nil, GasSwap, MakeSwap(12), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP13)] := TOperation.Create(True, MakeSwapStackFunc(14), nil, GasSwap, MakeSwap(13), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP14)] := TOperation.Create(True, MakeSwapStackFunc(15), nil, GasSwap, MakeSwap(14), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP15)] := TOperation.Create(True, MakeSwapStackFunc(16), nil, GasSwap, MakeSwap(15), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.SWAP16)] := TOperation.Create(True, MakeSwapStackFunc(17), nil, GasSwap, MakeSwap(16), False, False, False, False, False);
  InstructionSet[Ord(TOpCode.RETURN)] := TOperation.Create(True, MakeStackFunc(2, 0), MemoryReturn, GasReturn, OpReturn, False, True, False, False, False);
  InstructionSet[Ord(TOpCode.BALANCE)] := TOperation.Create(True, MakeStackFunc(1, 1), nil, GasBalance, OpBalance, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.ACCOUNTHEIGHT)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasAccountheight, OpAccountHeight, False, False, False, False, False);
  InstructionSet[Ord(TOpCode.PREVHASH)] := TOperation.Create(True, MakeStackFunc(0, 1), nil, GasPrevhash, OpAccountHash, False, False, False, False, False);
end;

initialization
  NewSimpleInstructionSet(SimpleInstructionSet);
  NewOffchainSimpleInstructionSet(OffchainSimpleInstructionSet);
  NewRandInstructionSet(RandInstructionSet);
  NewRandOffchainInstructionSet(OffchainRandInstructionSet);
  NewEarthInstructionSet(EarthInstructionSet);
  NewOffchainEarthInstructionSet(OffchainEarthInstructionSet);
end.