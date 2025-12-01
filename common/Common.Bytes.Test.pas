unit Common.Bytes.Test;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  Common.Bytes,
  GoToDelphi.Helpers.BigInt;

type
  [TestFixture]
  TCommonBytesTests = class(TObject)
  public
    [Test]
    procedure TestUint64ToBytes;
    [Test]
    procedure TestBytesToUint64;
    [Test]
    procedure TestBytesToBig;
    [Test]
    procedure TestBigToBytes;
    [Test]
    procedure TestLeftPadBytes;
    [Test]
    procedure TestRightPadBytes;
    [Test]
    procedure TestIsEqualBytes;
  end;

implementation

uses
  System.Generics.Defaults;

{ TCommonBytesTests }

procedure TCommonBytesTests.TestUint64ToBytes;
var
  vValue: UInt64;
  vExpected, vResult: TBytes;
begin
  vValue := 1234567890123456789;
  vExpected := TBytes.Create($11, $22, $10, $F4, $7D, $E9, $81, $15);
  vResult := Uint64ToBytes(vValue);
  Assert.IsTrue(IsEqualBytes(vExpected, vResult), 'TestUint64ToBytes failed');
end;

procedure TCommonBytesTests.TestBytesToUint64;
var
  vValue: TBytes;
  vExpected, vResult: UInt64;
begin
  vValue := TBytes.Create($11, $22, $10, $F4, $7D, $E9, $81, $15);
  vExpected := 1234567890123456789;
  vResult := BytesToUint64(vValue);
  Assert.AreEqual(vExpected, vResult, 'TestBytesToUint64 failed');
end;

procedure TCommonBytesTests.TestBytesToBig;
var
  vValue: TBytes;
  vResult: TBigInt;
  vExpected: TBigInt;
begin
  vValue := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8);
  vResult := BytesToBig(vValue);
  vExpected := TBigInt.FromBytes(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8));
  Assert.AreEqual(vExpected.ToString, vResult.ToString, 'TestBytesToBig failed');
end;

procedure TCommonBytesTests.TestBigToBytes;
var
  vValue: TBigInt;
  vExpected, vResult: TBytes;
begin
  vValue := TBigInt.FromBytes(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8));
  vExpected := TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8);
  vResult := BigToBytes(vValue);
  Assert.IsTrue(IsEqualBytes(vExpected, vResult), 'TestBigToBytes failed');
end;

procedure TCommonBytesTests.TestLeftPadBytes;
var
  vVal1, vExp1, vRes1, vRes2: TBytes;
begin
  vVal1 := TBytes.Create(1, 2, 3, 4);
  vExp1 := TBytes.Create(0, 0, 0, 0, 1, 2, 3, 4);

  vRes1 := LeftPadBytes(vVal1, 8);
  vRes2 := LeftPadBytes(vVal1, 2);

  Assert.IsTrue(IsEqualBytes(vExp1, vRes1));
  Assert.IsTrue(IsEqualBytes(vVal1, vRes2));
end;

procedure TCommonBytesTests.TestRightPadBytes;
var
  vVal, vExp, vResStd, vResShrt: TBytes;
begin
  vVal := TBytes.Create(1, 2, 3, 4);
  vExp := TBytes.Create(1, 2, 3, 4, 0, 0, 0, 0);

  vResStd := RightPadBytes(vVal, 8);
  vResShrt := RightPadBytes(vVal, 2);

  Assert.IsTrue(IsEqualBytes(vExp, vResStd));
  Assert.IsTrue(IsEqualBytes(vVal, vResShrt));
end;

procedure TCommonBytesTests.TestIsEqualBytes;
var
  vBytes1, vBytes2, vBytes3: TBytes;
begin
  vBytes1 := TBytes.Create(1, 2, 3);
  vBytes2 := TBytes.Create(1, 2, 3);
  vBytes3 := TBytes.Create(1, 2, 4);

  Assert.IsTrue(IsEqualBytes(vBytes1, vBytes2), 'vBytes1 should be equal to vBytes2');
  Assert.IsFalse(IsEqualBytes(vBytes1, vBytes3), 'vBytes1 should not be equal to vBytes3');
end;

initialization
  TDUnitX.RegisterTestFixture(TCommonBytesTests);
end.
