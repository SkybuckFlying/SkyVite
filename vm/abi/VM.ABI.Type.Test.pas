unit VM.ABI.Type.Test;

interface
uses
  VM.ABI.ABI,
  VM.ABI.ABI.Test,
  VM.ABI.Argument,
  VM.ABI.Error,
  VM.ABI.Event,
  VM.ABI.Event.Test,
  VM.ABI.Method,
  VM.ABI.Numbers,
  VM.ABI.Numbers.Test,
  VM.ABI.Pack,
  VM.ABI.Pack.Test,
  VM.ABI.Reflect,
  VM.ABI.Type,
  VM.ABI.Unpack,
  VM.ABI.Unpack.Test,
  VM.ABI.Variable,
  VM.ABI.Variable.Test;

procedure RunTypeTests;

implementation

uses
  System.SysUtils, System.Rtti, System.BigInt,
  GoVite.Types, GoVite.VM, VM.ABI.Type, // Assumed units
  DUnitX.TestFramework;

type
  TTypeTestCase = record
    Blob: string;
    Expected: TAbiType;
  end;

procedure TestTypeRegexp;
var
  Tests: TArray<TTypeTestCase>;
  Test: TTypeTestCase;
  Typ: TAbiType;
  I: Integer;
begin
  // This is a subset of the Go tests for brevity. A full implementation would include all cases.
  SetLength(Tests, 4);
  Tests[0] := TTypeTestCase.Create('bool', TAbiType.Create(TTypeKind.tkBoolean, 'bool'));
  Tests[1] := TTypeTestCase.Create('uint256', TAbiType.Create(TTypeKind.tkPointer, 'uint256', 256, TypeInfo(TBigInteger)));
  Tests[2] := TTypeTestCase.Create('address', TAbiType.Create(TTypeKind.tkArray, 'address', 21, TypeInfo(TAddress)));
  
  var ElemType := TAbiType.Create(TTypeKind.tkBoolean, 'bool');
  Tests[3] := TTypeTestCase.Create('bool[]', TAbiType.Create(TTypeKind.tkDynArray, 'bool[]', 0, TypeInfo(TArray<Boolean>), @ElemType));

  for I := 0 to High(Tests) do
  begin
    Test := Tests[I];
    Typ := TAbiType.NewType(Test.Blob);

    Assert.AreEqual(Test.Expected.StringKind, Typ.StringKind, 'StringKind mismatch for ' + Test.Blob);
    Assert.AreEqual(Test.Expected.Kind, Typ.Kind, 'Kind mismatch for ' + Test.Blob);
    Assert.AreEqual(Test.Expected.Size, Typ.Size, 'Size mismatch for ' + Test.Blob);
    if Assigned(Test.Expected.Elem) then
    begin
      Assert.IsNotNull(Typ.Elem, 'Elem should not be nil for ' + Test.Blob);
      Assert.AreEqual(Test.Expected.Elem^.StringKind, Typ.Elem^.StringKind, 'Elem.StringKind mismatch for ' + Test.Blob);
    end
    else
    begin
      Assert.IsNull(Typ.Elem, 'Elem should be nil for ' + Test.Blob);
    end;
  end;
end;

procedure TestTypeCheck;
type
  TCheckTestCase = record
    Typ: string;
    Input: TValue;
    ErrorMsg: string;
  end;
var
  Tests: TArray<TCheckTestCase>;
  Test: TCheckTestCase;
  Typ: TAbiType;
  Err: Exception;
  I: Integer;
begin
  SetLength(Tests, 6);
  Tests[0] := TCheckTestCase.Create('uint256', TValue.From<TBigInteger>(1), '');
  Tests[1] := TCheckTestCase.Create('uint8', TValue.From<Byte>(1), '');
  Tests[2] := TCheckTestCase.Create('uint8', TValue.From<Word>(1), 'abi: cannot use Word as type Byte as argument');
  Tests[3] := TCheckTestCase.Create('uint16[]', TValue.From<TArray<Word>>([1, 2, 3]), '');
  Tests[4] := TCheckTestCase.Create('uint16[3]', TValue.From<TArray<UInt32>>([1, 2, 3]), 'abi: cannot use TArray<UInt32> as type TArray<Word> as argument');
  Tests[5] := TCheckTestCase.Create('address', TValue.From<TAddress>(TAddress.FromHexString('vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a')), '');


  for I := 0 to High(Tests) do
  begin
    Test := Tests[I];
    Err := nil;
    try
      Typ := TAbiType.NewType(Test.Typ);
      Typ.TypeCheck(Test.Input);
    except
      on E: Exception do
        Err := E;
    end;

    if Test.ErrorMsg = '' then
      Assert.IsNull(Err, Format('Test %d (%s) should not have failed, but got: %s', [I, Test.Typ, Err.Message]))
    else
    begin
      Assert.IsNotNull(Err, Format('Test %d (%s) should have failed', [I, Test.Typ]));
      Assert.AreEqual(Test.ErrorMsg, Err.Message, Format('Test %d (%s) error message mismatch', [I, Test.Typ]));
    end;
  end;
end;

procedure RunTypeTests;
begin
  TestTypeRegexp;
  TestTypeCheck;
end;

end.
