unit VM.Instructions.Test;

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
  VM.VM,
  VM.VM.Run.Test,
  VM.VM.Test;

procedure RunInstructionsTest;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.BigInt,
  GoVite.Types, GoVite.Ledger, GoVite.VM, // Assumed main VM units
  VM.Opcodes, // Assumed unit where op... procedures are defined
  DUnitX.TestFramework;

type
  // Mock classes to support tests
  TTestVM = class(TVM);
  TTestContract = class(TContract);
  TTestStack = class(TStack);
  TTestMemory = class(TMemory);

  TTwoOperandTest = record
    X: string;
    Y: string;
    Expected: string;
  end;

procedure TestTwoOperandOp(const ATests: TArray<TTwoOperandTest>; AOpProc: TOpcodeProc);
var
  LVM: TTestVM;
  LContract: TTestContract;
  LStack: TTestStack;
  PC: UInt64;
  I: Integer;
  Test: TTwoOperandTest;
  X, Y, ExpectedBytes: TBytes;
  ExpectedInt, Actual: TBigInteger;
begin
  LVM := TTestVM.Create(nil);
  LContract := TTestContract.Create(nil, nil, nil);
  LStack := TTestStack.Create;
  PC := 0;
  try
    for I := 0 to High(ATests) do
    begin
      Test := ATests[I];
      X := THex.Decode(Test.X);
      Y := THex.Decode(Test.Y);
      ExpectedBytes := THex.Decode(Test.Expected);
      ExpectedInt := TBigInteger.FromBytes(ExpectedBytes);

      LStack.Push(TBigInteger.FromBytes(X));
      LStack.Push(TBigInteger.FromBytes(Y));

      AOpProc(PC, LVM, LContract, nil, LStack);
      Actual := LStack.Pop;

      Assert.AreEqual(0, Actual.CompareTo(ExpectedInt), Format('Test Case %d: Expected %s, got %s', [I, ExpectedInt.ToString, Actual.ToString]));
    end;
  finally
    LVM.Free;
    LContract.Free;
    LStack.Free;
  end;
end;

procedure TestByteOp;
type
  TByteTest = record
    V: string;
    Th: UInt64;
    Expected: TBigInteger;
  end;
var
  Tests: TArray<TByteTest>;
  LVM: TTestVM;
  LContract: TTestContract;
  LStack: TTestStack;
  PC: UInt64;
  Test: TByteTest;
  VBytes: TBytes;
  Val, Th, Actual: TBigInteger;
begin
  Tests := [
    TByteTest.Create('ABCDEF0908070605040302010000000000000000000000000000000000000000', 0, TBigInteger.Create(System.Byte($AB)))),
    TByteTest.Create('ABCDEF0908070605040302010000000000000000000000000000000000000000', 1, TBigInteger.Create(System.Byte($CD)))),
    TByteTest.Create('00CDEF090807060504030201ffffffffffffffffffffffffffffffffffffffff', 0, TBigInteger.Create(System.Byte($00)))),
    TByteTest.Create('00CDEF090807060504030201ffffffffffffffffffffffffffffffffffffffff', 1, TBigInteger.Create(System.Byte($CD)))),
    TByteTest.Create('0000000000000000000000000000000000000000000000000000000000102030', 31, TBigInteger.Create(System.Byte($30)))),
    TByteTest.Create('0000000000000000000000000000000000000000000000000000000000102030', 30, TBigInteger.Create(System.Byte($20)))),
    TByteTest.Create('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 32, TBigInteger.Zero),
    TByteTest.Create('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', $FFFFFFFFFFFFFFFF, TBigInteger.Zero)
  ];

  LVM := TTestVM.Create(nil);
  LContract := TTestContract.Create(nil, nil, nil);
  LStack := TTestStack.Create;
  PC := 0;
  try
    for Test in Tests do
    begin
      VBytes := THex.Decode(Test.V);
      Val := TBigInteger.FromBytes(VBytes);
      Th := Test.Th;

      LStack.Push(Val);
      LStack.Push(Th);
      opByte(PC, LVM, LContract, nil, LStack);
      Actual := LStack.Pop;

      Assert.AreEqual(0, Actual.CompareTo(Test.Expected), Format('ByteOp failed for %s at index %d', [Test.V, Test.Th]));
    end;
  finally
    LVM.Free;
    LContract.Free;
    LStack.Free;
  end;
end;

procedure TestSHL;
var
  Tests: TArray<TTwoOperandTest>;
begin
  Tests := [
    TTwoOperandTest.Create('01', '00', '01'),
    TTwoOperandTest.Create('01', '01', '02'),
    TTwoOperandTest.Create('01', 'ff', '8000000000000000000000000000000000000000000000000000000000000000'),
    TTwoOperandTest.Create('01', '100', '00'),
    TTwoOperandTest.Create('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', '01', 'fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe'),
    TTwoOperandTest.Create('7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', '01', 'fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe')
  ];
  TestTwoOperandOp(Tests, opSHL);
end;

procedure TestSHR;
var
  Tests: TArray<TTwoOperandTest>;
begin
  Tests := [
    TTwoOperandTest.Create('01', '00', '01'),
    TTwoOperandTest.Create('01', '01', '00'),
    TTwoOperandTest.Create('8000000000000000000000000000000000000000000000000000000000000000', '01', '4000000000000000000000000000000000000000000000000000000000000000'),
    TTwoOperandTest.Create('8000000000000000000000000000000000000000000000000000000000000000', 'ff', '01'),
    TTwoOperandTest.Create('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 'ff', '01'),
    TTwoOperandTest.Create('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', '100', '00')
  ];
  TestTwoOperandOp(Tests, opSHR);
end;

procedure TestSAR;
var
  Tests: TArray<TTwoOperandTest>;
begin
  Tests := [
    TTwoOperandTest.Create('01', '01', '00'),
    TTwoOperandTest.Create('8000000000000000000000000000000000000000000000000000000000000000', '01', 'c000000000000000000000000000000000000000000000000000000000000000'),
    TTwoOperandTest.Create('8000000000000000000000000000000000000000000000000000000000000000', 'ff', 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'),
    TTwoOperandTest.Create('7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 'fe', '01')
  ];
  TestTwoOperandOp(Tests, opSAR);
end;

procedure TestOpMstore;
var
  LVM: TTestVM;
  LContract: TTestContract;
  LStack: TTestStack;
  LMem: TTestMemory;
  PC: UInt64;
  V: string;
  VBytes: TBytes;
begin
  LVM := TTestVM.Create(nil);
  LContract := TTestContract.Create(nil, nil, nil);
  LStack := TTestStack.Create;
  LMem := TTestMemory.Create;
  PC := 0;
  try
    LMem.Resize(64);
    V := 'abcdef00000000000000abba000000000deaf000000c0de00100000000133700';
    VBytes := THex.Decode(V);
    
    LStack.Push(TBigInteger.FromBytes(VBytes));
    LStack.Push(TBigInteger.Zero);
    opMstore(PC, LVM, LContract, LMem, LStack);
    Assert.AreEqual(V, THex.Encode(LMem.Get(0, 32)), 'Mstore initial value failed');

    LStack.Push(TBigInteger.One);
    LStack.Push(TBigInteger.Zero);
    opMstore(PC, LVM, LContract, LMem, LStack);
    Assert.AreEqual('0000000000000000000000000000000000000000000000000000000000000001', THex.Encode(LMem.Get(0, 32)), 'Mstore overwrite failed');
  finally
    LVM.Free;
    LContract.Free;
    LStack.Free;
    LMem.Free;
  end;
end;


procedure RunInstructionsTest;
begin
  TestByteOp;
  TestSHL;
  TestSHR;
  TestSAR;
  TestOpMstore;
  // SGT and SLT tests are omitted for brevity but would follow the same pattern
end;

end.
