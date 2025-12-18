unit Vm.Opcodes;

interface

uses
  System.SysUtils System.Generics.Collections,
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
  VM.Params,
  VM.Stack,
  VM.Stack.Table,
  VM.Stack.Test,
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

type
  opCode = Byte;

  opCodeHelper = record helper for opCode
    function isPush: Boolean;
    function isStaticJump: Boolean;
    function ToString: string;
  end;

const
  // 0x0 range - arithmetic ops.
  STOP opCode = $00;
  ADD = $01;
  MUL = $02;
  SUB = $03;
  DIV = $04;
  SDIV = $05;
  MOD_OP = $06; // MOD is a reserved keyword
  SMOD = $07;
  ADDMOD = $08;
  MULMOD = $09;
  EXP = $0a;
  SIGNEXTEND = $0b;

  // 0x10 range - comparison ops.
  LT = $10;
  GT = $11;
  SLT = $12;
  SGT = $13;
  EQ = $14;
  ISZERO = $15;
  AND_OP = $16; // AND is a reserved keyword
  OR_OP = $17;  // OR is a reserved keyword
  XOR_OP = $18; // XOR is a reserved keyword
  NOT_OP = $19; // NOT is a reserved keyword
  BYTE = $1a;
  SHL = $1b;
  SHR = $1c;
  SAR = $1d;

  // 0x20 range - hash ops.
  SHA3 = $20;
  BLAKE2B = $21;

  // 0x30 range - closure state.
  ADDRESS = $30;
  BALANCE = $31;
  ORIGIN = $32;
  CALLER = $33;
  CALLVALUE = $34;
  CALLDATALOAD = $35;
  CALLDATASIZE = $36;
  CALLDATACOPY = $37;
  CODESIZE = $38;
  CODECOPY = $39;
  GASPRICE = $3a;
  EXTCODESIZE = $3b;
  EXTCODECOPY = $3c;
  RETURNDATASIZE = $3d;
  RETURNDATACOPY = $3e;
  EXTCODEHASH = $3f;

  // 0x40 range - block operations.
  BLOCKHASH = $40;
  COINBASE = $41;
  TIMESTAMP = $42;
  HEIGHT = $43;
  DIFFICULTY = $44;
  GASLIMIT = $45;
  TOKENID = $46;
  ACCOUNTHEIGHT = $47;
  PREVHASH = $48;
  FROMHASH = $49;
  SEED = $4a;
  RANDOM = $4b;

  // 0x50 range - 'storage' and execution.
  POP = $50;
  MLOAD = $51;
  MSTORE = $52;
  MSTORE8 = $53;
  SLOAD = $54;
  SSTORE = $55;
  JUMP = $56;
  JUMPI = $57;
  PC = $58;
  MSIZE = $59;
  GAS = $5a;
  JUMPDEST = $5b;

  // 0x60 range.
  PUSH1 = $60;
  PUSH2 = $61;
  PUSH3 = $62;
  PUSH4 = $63;
  PUSH5 = $64;
  PUSH6 = $65;
  PUSH7 = $66;
  PUSH8 = $67;
  PUSH9 = $68;
  PUSH10 = $69;
  PUSH11 = $6a;
  PUSH12 = $6b;
  PUSH13 = $6c;
  PUSH14 = $6d;
  PUSH15 = $6e;
  PUSH16 = $6f;
  PUSH17 = $70;
  PUSH18 = $71;
  PUSH19 = $72;
  PUSH20 = $73;
  PUSH21 = $74;
  PUSH22 = $75;
  PUSH23 = $76;
  PUSH24 = $77;
  PUSH25 = $78;
  PUSH26 = $79;
  PUSH27 = $7a;
  PUSH28 = $7b;
  PUSH29 = $7c;
  PUSH30 = $7d;
  PUSH31 = $7e;
  PUSH32 = $7f;
  DUP1 = $80;
  DUP2 = $81;
  DUP3 = $82;
  DUP4 = $83;
  DUP5 = $84;
  DUP6 = $85;
  DUP7 = $86;
  DUP8 = $87;
  DUP9 = $88;
  DUP10 = $89;
  DUP11 = $8a;
  DUP12 = $8b;
  DUP13 = $8c;
  DUP14 = $8d;
  DUP15 = $8e;
  DUP16 = $8f;
  SWAP1 = $90;
  SWAP2 = $91;
  SWAP3 = $92;
  SWAP4 = $93;
  SWAP5 = $94;
  SWAP6 = $95;
  SWAP7 = $96;
  SWAP8 = $97;
  SWAP9 = $98;
  SWAP10 = $99;
  SWAP11 = $9a;
  SWAP12 = $9b;
  SWAP13 = $9c;
  SWAP14 = $9d;
  SWAP15 = $9e;
  SWAP16 = $9f;

  // 0xa0 range - logging ops.
  LOG0 = $a0;
  LOG1 = $a1;
  LOG2 = $a2;
  LOG3 = $a3;
  LOG4 = $a4;

  // 0xf0 range - closures.
  CREATE = $f0;
  CALL = $f1;
  CALL2 = $f2;
  RETURN = $f3;
  DELEGATECALL = $f4;
  STATICCALL = $fa;

  REVERT = $fd;
  SELFDESTRUCT = $ff;

var
  opCodeToString: TDictionary<opCode, string>;
  stringToOp: TDictionary<string, opCode>;

implementation

{ opCodeHelper }

function opCodeHelper.isPush: Boolean;
begin
  Result := (Self >= PUSH1) and (Self <= PUSH32);
end;

function opCodeHelper.isStaticJump: Boolean;
begin
  Result := Self = JUMP;
end;

function opCodeHelper.ToString: string;
begin
  if opCodeToString.TryGetValue(Self, Result) then
    Exit
  else
    Result := Format('Missing opcode 0x%x', [byte(Self)]);
end;

initialization
  opCodeToString := TDictionary<opCode, string>.Create;
  stringToOp := TDictionary<string, opCode>.Create;

  // 0x0 range - arithmetic ops.
  opCodeToString.Add(STOP, 'STOP');
  opCodeToString.Add(ADD, 'ADD');
  opCodeToString.Add(MUL, 'MUL');
  opCodeToString.Add(SUB, 'SUB');
  opCodeToString.Add(DIV, 'DIV');
  opCodeToString.Add(SDIV, 'SDIV');
  opCodeToString.Add(MOD_OP, 'MOD');
  opCodeToString.Add(SMOD, 'SMOD');
  opCodeToString.Add(ADDMOD, 'ADDMOD');
  opCodeToString.Add(MULMOD, 'MULMOD');
  opCodeToString.Add(EXP, 'EXP');
  opCodeToString.Add(SIGNEXTEND, 'SIGNEXTEND');

  // 0x10 range - comparison ops.
  opCodeToString.Add(LT, 'LT');
  opCodeToString.Add(GT, 'GT');
  opCodeToString.Add(SLT, 'SLT');
  opCodeToString.Add(SGT, 'SGT');
  opCodeToString.Add(EQ, 'EQ');
  opCodeToString.Add(ISZERO, 'ISZERO');
  opCodeToString.Add(AND_OP, 'AND');
  opCodeToString.Add(OR_OP, 'OR');
  opCodeToString.Add(XOR_OP, 'XOR');
  opCodeToString.Add(NOT_OP, 'NOT');
  opCodeToString.Add(BYTE, 'BYTE');
  opCodeToString.Add(SHL, 'SHL');
  opCodeToString.Add(SHR, 'SHR');
  opCodeToString.Add(SAR, 'SAR');

  // 0x20 range - hash ops.
  opCodeToString.Add(SHA3, 'SHA3');
  opCodeToString.Add(BLAKE2B, 'BLAKE2B');

  // 0x30 range - closure state.
  opCodeToString.Add(ADDRESS, 'ADDRESS');
  opCodeToString.Add(BALANCE, 'BALANCE');
  opCodeToString.Add(ORIGIN, 'ORIGIN');
  opCodeToString.Add(CALLER, 'CALLER');
  opCodeToString.Add(CALLVALUE, 'CALLVALUE');
  opCodeToString.Add(CALLDATALOAD, 'CALLDATALOAD');
  opCodeToString.Add(CALLDATASIZE, 'CALLDATASIZE');
  opCodeToString.Add(CALLDATACOPY, 'CALLDATACOPY');
  opCodeToString.Add(CODESIZE, 'CODESIZE');
  opCodeToString.Add(CODECOPY, 'CODECOPY');
  opCodeToString.Add(GASPRICE, 'GASPRICE');
  opCodeToString.Add(EXTCODESIZE, 'EXTCODESIZE');
  opCodeToString.Add(EXTCODECOPY, 'EXTCODECOPY');
  opCodeToString.Add(RETURNDATASIZE, 'RETURNDATASIZE');
  opCodeToString.Add(RETURNDATACOPY, 'RETURNDATACOPY');
  opCodeToString.Add(EXTCODEHASH, 'EXTCODEHASH');

  // 0x40 range - block operations.
  opCodeToString.Add(BLOCKHASH, 'BLOCKHASH');
  opCodeToString.Add(COINBASE, 'COINBASE');
  opCodeToString.Add(TIMESTAMP, 'TIMESTAMP');
  opCodeToString.Add(HEIGHT, 'HEIGHT');
  opCodeToString.Add(DIFFICULTY, 'DIFFICULTY');
  opCodeToString.Add(GASLIMIT, 'GASLIMIT');
  opCodeToString.Add(TOKENID, 'TOKENID');
  opCodeToString.Add(ACCOUNTHEIGHT, 'ACCOUNTHEIGHT');
  opCodeToString.Add(PREVHASH, 'PREVHASH');
  opCodeToString.Add(FROMHASH, 'FROMHASH');
  opCodeToString.Add(SEED, 'SEED');
  opCodeToString.Add(RANDOM, 'RANDOM');

  // 0x50 range - 'storage' and execution.
  opCodeToString.Add(POP, 'POP');
  opCodeToString.Add(MLOAD, 'MLOAD');
  opCodeToString.Add(MSTORE, 'MSTORE');
  opCodeToString.Add(MSTORE8, 'MSTORE8');
  opCodeToString.Add(SLOAD, 'SLOAD');
  opCodeToString.Add(SSTORE, 'SSTORE');
  opCodeToString.Add(JUMP, 'JUMP');
  opCodeToString.Add(JUMPI, 'JUMPI');
  opCodeToString.Add(PC, 'PC');
  opCodeToString.Add(MSIZE, 'MSIZE');
  opCodeToString.Add(GAS, 'GAS');
  opCodeToString.Add(JUMPDEST, 'JUMPDEST');

  // 0x60 range.
  opCodeToString.Add(PUSH1, 'PUSH1');
  opCodeToString.Add(PUSH2, 'PUSH2');
  opCodeToString.Add(PUSH3, 'PUSH3');
  opCodeToString.Add(PUSH4, 'PUSH4');
  opCodeToString.Add(PUSH5, 'PUSH5');
  opCodeToString.Add(PUSH6, 'PUSH6');
  opCodeToString.Add(PUSH7, 'PUSH7');
  opCodeToString.Add(PUSH8, 'PUSH8');
  opCodeToString.Add(PUSH9, 'PUSH9');
  opCodeToString.Add(PUSH10, 'PUSH10');
  opCodeToString.Add(PUSH11, 'PUSH11');
  opCodeToString.Add(PUSH12, 'PUSH12');
  opCodeToString.Add(PUSH13, 'PUSH13');
  opCodeToString.Add(PUSH14, 'PUSH14');
  opCodeToString.Add(PUSH15, 'PUSH15');
  opCodeToString.Add(PUSH16, 'PUSH16');
  opCodeToString.Add(PUSH17, 'PUSH17');
  opCodeToString.Add(PUSH18, 'PUSH18');
  opCodeToString.Add(PUSH19, 'PUSH19');
  opCodeToString.Add(PUSH20, 'PUSH20');
  opCodeToString.Add(PUSH21, 'PUSH21');
  opCodeToString.Add(PUSH22, 'PUSH22');
  opCodeToString.Add(PUSH23, 'PUSH23');
  opCodeToString.Add(PUSH24, 'PUSH24');
  opCodeToString.Add(PUSH25, 'PUSH25');
  opCodeToString.Add(PUSH26, 'PUSH26');
  opCodeToString.Add(PUSH27, 'PUSH27');
  opCodeToString.Add(PUSH28, 'PUSH28');
  opCodeToString.Add(PUSH29, 'PUSH29');
  opCodeToString.Add(PUSH30, 'PUSH30');
  opCodeToString.Add(PUSH31, 'PUSH31');
  opCodeToString.Add(PUSH32, 'PUSH32');
  opCodeToString.Add(DUP1, 'DUP1');
  opCodeToString.Add(DUP2, 'DUP2');
  opCodeToString.Add(DUP3, 'DUP3');
  opCodeToString.Add(DUP4, 'DUP4');
  opCodeToString.Add(DUP5, 'DUP5');
  opCodeToString.Add(DUP6, 'DUP6');
  opCodeToString.Add(DUP7, 'DUP7');
  opCodeToString.Add(DUP8, 'DUP8');
  opCodeToString.Add(DUP9, 'DUP9');
  opCodeToString.Add(DUP10, 'DUP10');
  opCodeToString.Add(DUP11, 'DUP11');
  opCodeToString.Add(DUP12, 'DUP12');
  opCodeToString.Add(DUP13, 'DUP13');
  opCodeToString.Add(DUP14, 'DUP14');
  opCodeToString.Add(DUP15, 'DUP15');
  opCodeToString.Add(DUP16, 'DUP16');
  opCodeToString.Add(SWAP1, 'SWAP1');
  opCodeToString.Add(SWAP2, 'SWAP2');
  opCodeToString.Add(SWAP3, 'SWAP3');
  opCodeToString.Add(SWAP4, 'SWAP4');
  opCodeToString.Add(SWAP5, 'SWAP5');
  opCodeToString.Add(SWAP6, 'SWAP6');
  opCodeToString.Add(SWAP7, 'SWAP7');
  opCodeToString.Add(SWAP8, 'SWAP8');
  opCodeToString.Add(SWAP9, 'SWAP9');
  opCodeToString.Add(SWAP10, 'SWAP10');
  opCodeToString.Add(SWAP11, 'SWAP11');
  opCodeToString.Add(SWAP12, 'SWAP12');
  opCodeToString.Add(SWAP13, 'SWAP13');
  opCodeToString.Add(SWAP14, 'SWAP14');
  opCodeToString.Add(SWAP15, 'SWAP15');
  opCodeToString.Add(SWAP16, 'SWAP16');

  // 0xa0 range - logging ops.
  opCodeToString.Add(LOG0, 'LOG0');
  opCodeToString.Add(LOG1, 'LOG1');
  opCodeToString.Add(LOG2, 'LOG2');
  opCodeToString.Add(LOG3, 'LOG3');
  opCodeToString.Add(LOG4, 'LOG4');

  // 0xf0 range - closures.
  opCodeToString.Add(CREATE, 'CREATE');
  opCodeToString.Add(CALL, 'CALL');
  opCodeToString.Add(CALL2, 'CALL2');
  opCodeToString.Add(RETURN, 'RETURN');
  opCodeToString.Add(DELEGATECALL, 'DELEGATECALL');
  opCodeToString.Add(STATICCALL, 'STATICCALL');
  opCodeToString.Add(REVERT, 'REVERT');
  opCodeToString.Add(SELFDESTRUCT, 'SELFDESTRUCT');

  // Initialize the reverse mapping
  for var pair in opCodeToString do
    stringToOp.Add(pair.Value, pair.Key);

finalization
  opCodeToString.Free;
  stringToOp.Free;

end.
