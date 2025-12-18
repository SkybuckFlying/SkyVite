unit Common.Helper.Math.Test;

interface

uses
  Common.Helper.Common,
  Common.Helper.Common.Test,
  Common.Helper.Math.Big,
  Common.Helper.Math.Integer,
  Common.Helper.Rand,
  Common.Helper.Rand.Test,
  Common.Helper.Slice,
  DUnitX.TestFramework;

type
  [TestFixture]
  TMathHelperTests = class
  public
    [Test]
    procedure TestMin;
    [Test]
    procedure TestMax;
    [Test]
    procedure TestSafeAdd;
    [Test]
    procedure TestSafeMul;
    [Test]
    procedure TestBigPow;
    [Test]
    procedure TestReadBits;
    [Test]
    procedure TestU256;
  end;

implementation

uses
  System.SysUtils,
  System.Math.BigInts,
  Common.Helper.Math;

{ TMathHelperTests }

procedure TMathHelperTests.TestMin;
type
  TTestData = record
    X, Y, Result: UInt64;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
begin
  vTests := [
    (X: 1; Y: 2; Result: 1),
    (X: 1; Y: 1; Result: 1),
    (X: 2; Y: 1; Result: 1)
  ];
  for vTest in vTests do
  begin
    Assert.AreEqual(vTest.Result, Min(vTest.X, vTest.Y));
  end;
end;

procedure TMathHelperTests.TestMax;
type
  TTestData = record
    X, Y, Result: UInt64;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
begin
  vTests := [
    (X: 1; Y: 2; Result: 2),
    (X: 1; Y: 1; Result: 1),
    (X: 2; Y: 1; Result: 2)
  ];
  for vTest in vTests do
  begin
    Assert.AreEqual(vTest.Result, Max(vTest.X, vTest.Y));
  end;
end;

procedure TMathHelperTests.TestSafeAdd;
type
  TTestData = record
    X, Y, Result: UInt64;
    Overflow: Boolean;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
  vResult: UInt64;
  vOverflow: Boolean;
begin
  vTests := [
    (X: 1; Y: 2; Result: 3; Overflow: False),
    (X: High(UInt64) - 1; Y: 1; Result: High(UInt64); Overflow: False),
    (X: High(UInt64); Y: 1; Result: 0; Overflow: True),
    (X: High(UInt64); Y: 2; Result: 1; Overflow: True)
  ];
  for vTest in vTests do
  begin
    SafeAdd(vTest.X, vTest.Y, vResult, vOverflow);
    Assert.AreEqual(vTest.Result, vResult);
    Assert.AreEqual(vTest.Overflow, vOverflow);
  end;
end;

procedure TMathHelperTests.TestSafeMul;
type
  TTestData = record
    X, Y, Result: UInt64;
    Overflow: Boolean;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
  vResult: UInt64;
  vOverflow: Boolean;
begin
  vTests := [
    (X: 1; Y: 0; Result: 0; Overflow: False),
    (X: 0; Y: 1; Result: 0; Overflow: False),
    (X: 1; Y: 2; Result: 2; Overflow: False),
    (X: High(UInt64); Y: 2; Result: High(UInt64) - 1; Overflow: True),
    (X: High(UInt64) div 2; Y: 2; Result: High(UInt64) - 1; Overflow: False)
  ];
  for vTest in vTests do
  begin
    SafeMul(vTest.X, vTest.Y, vResult, vOverflow);
    Assert.AreEqual(vTest.Result, vResult);
    Assert.AreEqual(vTest.Overflow, vOverflow);
  end;
end;

procedure TMathHelperTests.TestBigPow;
type
  TTestData = record
    X, Y: Int64;
    Result: TBigInteger;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
begin
  vTests := [
    (X: 0; Y: 0; Result: TBigInteger.One),
    (X: 0; Y: 2; Result: TBigInteger.Zero),
    (X: 2; Y: 0; Result: TBigInteger.One),
    (X: 2; Y: 4; Result: TBigInteger.Create(16)),
    (X: 2; Y: 33; Result: TBigInteger.Create(8589934592)),
    (X: 2; Y: 66; Result: TBigInteger.Create(8589934592) * TBigInteger.Create(8589934592))
  ];
  for vTest in vTests do
  begin
    Assert.AreEqual(vTest.Result, BigPow(vTest.X, vTest.Y));
  end;
end;

procedure TMathHelperTests.TestReadBits;
type
  TTestData = record
    Data: TBigInteger;
    Buf, Result: TBytes;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
begin
  // Tt256m1 needs to be initialized from Common.Helper.Math
  InitializeMathConstants;
  vTests := [
    (Data: Tt256m1; Buf: TBytes.Create(); Result: TBytes.Create($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF)),
    (Data: Tt256m1; Buf: TBytes.Create(); Result: TBytes.Create($00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF)),
    (Data: Tt256m1; Buf: TBytes.Create(); Result: TBytes.Create($FF, $FF)),
    (Data: TBigInteger.Zero; Buf: TBytes.Create(); Result: TBytes.Create($00, $00)),
    (Data: TBigInteger.Zero; Buf: TBytes.Create(); Result: TBytes.Create($00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00))
  ];
  for vTest in vTests do
  begin
    SetLength(vTest.Buf, Length(vTest.Result));
    ReadBits(vTest.Data, vTest.Buf);
    Assert.IsTrue(TBytes.Equals(vTest.Result, vTest.Buf));
  end;
end;

procedure TMathHelperTests.TestU256;
type
  TTestData = record
    Input, Result: TBigInteger;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
begin
  InitializeMathConstants;
  vTests := [
    (Input: TBigInteger.Zero; Result: TBigInteger.Zero),
    (Input: TBigInteger.One; Result: TBigInteger.One),
    (Input: Tt256m1; Result: Tt256m1),
    (Input: Tt256; Result: TBigInteger.Zero),
    (Input: Tt256 + TBigInteger.One; Result: TBigInteger.One)
  ];
  for vTest in vTests do
  begin
    Assert.AreEqual(vTest.Result, U256(vTest.Input));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMathHelperTests);
end.
