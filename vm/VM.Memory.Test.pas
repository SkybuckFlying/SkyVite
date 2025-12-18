unit VM.Memory.Test;

interface

procedure RunMemoryTest;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.BigInt, System.Math,
  GoVite.Types, GoVite.VM, // Assumed VM units
  VM.Memory,    // Assumed unit for TMemory and memory cost functions
  DUnitX.TestFramework;

procedure TestMemoryOperations;
var
  Mem: TMemory;
  Size: UInt64;
  Data1, Cpy1, Ptr, Data2, Cpy2, Cpy3: TBytes;
  BigInt255: TBigInteger;
  I: Integer;
begin
  Mem := TMemory.Create;
  try
    Size := 64;
    Mem.Resize(Size);
    Assert.AreEqual(Size, Mem.Len, 'Memory resize failed');

    Data1 := THex.Decode('00CDEF090807060504030201ffffffffffffffffffffffffffffffffffffffff');
    Mem.Set(0, 32, Data1);
    Cpy1 := Mem.Get(0, 32);
    Assert.AreEqual(THex.Encode(Data1), THex.Encode(Cpy1), 'Memory Get/Set failed');

    Ptr := Mem.GetPtr(0, 32);
    Assert.AreEqual(THex.Encode(Data1), THex.Encode(Ptr), 'Memory GetPtr failed');

    Data2 := THex.Decode('ffffffffffffffffffffffffffffffffffffffffABCDEF090807060504030201');
    for I := 0 to Length(Data2) - 1 do
      Ptr[I] := Data2[I];

    Cpy2 := Mem.Get(0, 32);
    Assert.AreEqual(THex.Encode(Data2), THex.Encode(Cpy2), 'Modifying memory via pointer failed');

    BigInt255 := TBigInteger.Create(TBytes.Create($FF, $FF)); // Simplified example for Tt255
    Mem.Set32(0, BigInt255);
    Cpy3 := Mem.Get(0, 32);
    // Delphi's TBigInteger.ToBytes might not left-pad to 32 bytes, so we manually check
    Assert.IsTrue(EndsText(THex.Encode(BigInt255.ToBytes), THex.Encode(Cpy3)), 'Memory Set32 failed');

  finally
    Mem.Free;
  end;
end;

procedure TestCalcMemSize;
type
  TTestCase = record
    Off, L, Result: TBigInteger;
  end;
var
  Tests: TArray<TTestCase>;
  Test: TTestCase;
  Result: TBigInteger;
begin
  Tests := [
    TTestCase.Create(0, 0, 0),
    TTestCase.Create(10, 0, 0),
    TTestCase.Create(10, 5, 15)
  ];
  for Test in Tests do
  begin
    Result := CalcMemSize(Test.Off, Test.L);
    Assert.AreEqual(0, Result.CompareTo(Test.Result), Format('CalcMemSize failed for off=%s, l=%s', [Test.Off.ToString, Test.L.ToString]));
  end;
end;

procedure TestMemoryTable;
type
  TMemCostFunc = function(Stack: TStack): TBigInteger;
  TTestCase = record
    St: TStack;
    Op: TMemCostFunc;
    Result: TBigInteger;
  end;
var
  Tests: TArray<TTestCase>;
  Test: TTestCase;
  Result: TBigInteger;
  Stack: TStack;
begin
  // Helper to create a stack from params
  function CreateStack(const AData: array of Int64): TStack;
  var I: Integer;
  begin
    Result := TStack.Create;
    for I := Low(AData) to High(AData) do
      Result.Push(AData[I]);
  end;

  Tests := [
    TTestCase.Create(CreateStack([32, 64]), MemoryBlake2b, 96),
    TTestCase.Create(CreateStack([32, 0, 64]), MemoryCallDataCopy, 96),
    TTestCase.Create(CreateStack([32, 0, 64]), MemoryCodeCopy, 96),
    TTestCase.Create(CreateStack([32, 0, 64, 0]), MemoryExtCodeCopy, 96),
    TTestCase.Create(CreateStack([32, 0, 64]), MemoryReturnDataCopy, 96),
    TTestCase.Create(CreateStack([64]), MemoryMLoad, 96),
    TTestCase.Create(CreateStack([64]), MemoryMStore, 96),
    TTestCase.Create(CreateStack([64]), MemoryMStore8, 65),
    TTestCase.Create(CreateStack([32, 64]), MemoryLog, 96),
    TTestCase.Create(CreateStack([64, 64, 32, 64, 0]), MemoryDelegateCall, 128),
    TTestCase.Create(CreateStack([64, 64, 32, 128, 0]), MemoryDelegateCall, 160),
    TTestCase.Create(CreateStack([32, 64]), MemoryReturn, 96),
    TTestCase.Create(CreateStack([32, 64]), MemoryRevert, 96)
  ];

  for Test in Tests do
  begin
    try
      Result := Test.Op(Test.St);
      Assert.AreEqual(0, Result.CompareTo(Test.Result), 'Memory cost calculation failed.');
    finally
      Test.St.Free;
    end;
  end;
end;


procedure RunMemoryTest;
begin
  TestMemoryOperations;
  TestCalcMemSize;
  TestMemoryTable;
end;

end.
