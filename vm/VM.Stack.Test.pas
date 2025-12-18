unit VM.Stack.Test;

interface

procedure RunStackTest;

implementation

uses
  System.SysUtils, System.Generics.Collections, System.BigInt,
  GoVite.VM,      // Assumed unit for TStack
  VM.Opcodes,     // Assumed unit for TStackValidationProc and MakeStackFunc
  DUnitX.TestFramework;

procedure TestStackOperations;
var
  St: TStack;
  Data1, Cpy1: TBigInteger;
begin
  St := TStack.Create;
  try
    Data1 := 1;
    St.Push(Data1);
    Assert.AreEqual(1, St.Len, 'Stack push failed: length incorrect');
    Assert.AreEqual(0, St.Peek.CompareTo(Data1), 'Stack push failed: peek value incorrect');

    St.Peek.Add(1); // Modify the big integer in place
    Assert.AreEqual(0, St.Peek.CompareTo(2), 'Stack peek should return a reference');

    Cpy1 := St.Pop;
    Assert.AreEqual(0, Cpy1.CompareTo(2), 'Stack pop failed: value incorrect');
    Assert.AreEqual(0, St.Len, 'Stack pop failed: length incorrect');

    St.Push(1);
    Assert.IsTrue(St.Require(1), 'Stack require(1) failed');
    Assert.IsFalse(St.Require(2), 'Stack require(2) should have failed');

    St.Push(2);
    Assert.AreEqual(0, St.Back(0).CompareTo(2), 'Stack Back(0) failed');
    Assert.AreEqual(0, St.Back(1).CompareTo(1), 'Stack Back(1) failed');

    St.Dup(2); // Dup the item at index 1 (value 1)
    Assert.AreEqual(3, St.Len, 'Stack Dup failed: length incorrect');
    Assert.AreEqual(0, St.Peek.CompareTo(1), 'Stack Dup failed: peek value incorrect');

    St.Swap(2); // Swap top (value 1) with item at index 2 (original value 2)
    Assert.AreEqual(0, St.Back(0).CompareTo(2), 'Stack Swap failed: Back(0) incorrect');
    Assert.AreEqual(0, St.Back(2).CompareTo(1), 'Stack Swap failed: Back(2) incorrect');

  finally
    St.Free;
  end;
end;

procedure TestStackTable;
type
  TTestCase = record
    St: TStack;
    Pop, Push: Integer;
    ExpectError: Boolean;
  end;
var
  Tests: TArray<TTestCase>;
  Test: TTestCase;
  StackFunc: TStackValidationProc;
  DidRaise: Boolean;
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
    TTestCase.Create(CreateStack([1]), 1, 1, False),
    TTestCase.Create(CreateStack([]), 1, 1, True), // Stack underflow
    TTestCase.Create(CreateStack([]), 0, 2, False),
    TTestCase.Create(CreateStack([1]), 0, 2, False),
    TTestCase.Create(TStack.Create(1023), 0, 2, True), // Stack overflow (1023+2 > 1024)
    TTestCase.Create(TStack.Create(1023), 1, 2, False), // OK (1023-1+2 = 1024)
    TTestCase.Create(TStack.Create(1024), 1, 1, False), // OK (1024-1+1=1024)
    TTestCase.Create(TStack.Create(1024), 1, 2, True)  // Stack overflow (1024-1+2 > 1024)
  ];

  for Test in Tests do
  begin
    try
      StackFunc := MakeStackFunc(Test.Pop, Test.Push);
      DidRaise := False;
      try
        StackFunc(Test.St);
      except
        on E: Exception do
          DidRaise := True;
      end;
      Assert.AreEqual(Test.ExpectError, DidRaise, Format('Stack validation failed for Pop=%d, Push=%d, StackSize=%d', [Test.Pop, Test.Push, Test.St.Len]));
    finally
      Test.St.Free;
    end;
  end;
end;

procedure RunStackTest;
begin
  TestStackOperations;
  TestStackTable;
end;

end.
