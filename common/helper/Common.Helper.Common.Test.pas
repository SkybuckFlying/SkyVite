unit Common.Helper.Common.Test;

interface

uses
  Common.Helper.Common,
  Common.Helper.Math.Big,
  Common.Helper.Math.Integer,
  Common.Helper.Math.Test,
  Common.Helper.Rand,
  Common.Helper.Rand.Test,
  Common.Helper.Slice,
  DUnitX.TestFramework;

type
  [TestFixture]
  TCommonHelperTests = class
  public
    [Test]
    procedure TestToWordSize;
    [Test]
    procedure TestBigUint64;
    [Test]
    procedure TestRightPadBytes;
    [Test]
    procedure TestLeftPadBytes;
    [Test]
    procedure TestGetDataBig;
    [Test]
    procedure TestBytesToString;
  end;

implementation

uses
  System.SysUtils,
  System.Math.BigInts,
  Common.Helper.Common;

{ TCommonHelperTests }

procedure TCommonHelperTests.TestToWordSize;
type
  TTestData = record
    ByteSize: UInt64;
    WordSize: UInt64;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
  vWordSize: UInt64;
begin
  vTests := [
    (ByteSize: 0; WordSize: 0),
    (ByteSize: 1; WordSize: 1),
    (ByteSize: 32; WordSize: 1),
    (ByteSize: 33; WordSize: 2),
    (ByteSize: High(UInt64) - 31; WordSize: High(UInt64) div 32),
    (ByteSize: High(UInt64) - 30; WordSize: High(UInt64) div 32 + 1),
    (ByteSize: High(UInt64); WordSize: High(UInt64) div 32 + 1)
  ];

  for vTest in vTests do
  begin
    vWordSize := ToWordSize(vTest.ByteSize);
    Assert.AreEqual(vTest.WordSize, vWordSize,
      Format('calculate word size from byte size fail, byte size: %d', [vTest.ByteSize]));
  end;
end;

procedure TCommonHelperTests.TestBigUint64;
type
  TTestData = record
    Input: TBigInteger;
    Result: UInt64;
    OK: Boolean;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
  vResult: UInt64;
  vOK: Boolean;
begin
  vTests := [
    (Input: TBigInteger.Create(0); Result: 0; OK: False),
    (Input: TBigInteger.Create(High(UInt64)); Result: High(UInt64); OK: False),
    (Input: TBigInteger.Create(High(UInt64)) + TBigInteger.One; Result: 0; OK: True),
    (Input: TBigInteger.Create(High(UInt64)) + TBigInteger.Create(2); Result: 1; OK: True)
  ];

  for vTest in vTests do
  begin
    BigUInt64(vTest.Input, vResult, vOK);
    Assert.AreEqual(vTest.Result, vResult, Format('get uint64 from big int fail: %s', [vTest.Input.ToString]));
    Assert.AreEqual(vTest.OK, vOK, Format('get uint64 from big int fail: %s', [vTest.Input.ToString]));
  end;
end;

procedure TCommonHelperTests.TestRightPadBytes;
type
  TTestData = record
    Input: TBytes;
    Len: Integer;
    Result: TBytes;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
  vResult: TBytes;
begin
  vTests := [
    (Input: []; Len: 8; Result: [0, 0, 0, 0, 0, 0, 0, 0]),
    (Input: [1, 2, 3]; Len: 8; Result: [1, 2, 3, 0, 0, 0, 0, 0]),
    (Input: [1, 2, 3, 4, 5, 6, 7, 8]; Len: 8; Result: [1, 2, 3, 4, 5, 6, 7, 8]),
    (Input: [1, 2, 3, 4, 5, 6, 7, 8, 9]; Len: 8; Result: [1, 2, 3, 4, 5, 6, 7, 8, 9])
  ];
  for vTest in vTests do
  begin
    vResult := RightPadBytes(vTest.Input, vTest.Len);
    Assert.IsTrue(TBytes.Equals(vTest.Result, vResult), 'right pad bytes fail');
  end;
end;

procedure TCommonHelperTests.TestLeftPadBytes;
type
  TTestData = record
    Input: TBytes;
    Len: Integer;
    Result: TBytes;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
  vResult: TBytes;
begin
  vTests := [
    (Input: []; Len: 8; Result: [0, 0, 0, 0, 0, 0, 0, 0]),
    (Input: [1, 2, 3]; Len: 8; Result: [0, 0, 0, 0, 0, 1, 2, 3]),
    (Input: [1, 2, 3, 4, 5, 6, 7, 8]; Len: 8; Result: [1, 2, 3, 4, 5, 6, 7, 8]),
    (Input: [1, 2, 3, 4, 5, 6, 7, 8, 9]; Len: 8; Result: [1, 2, 3, 4, 5, 6, 7, 8, 9])
  ];
  for vTest in vTests do
  begin
    vResult := LeftPadBytes(vTest.Input, vTest.Len);
    Assert.IsTrue(TBytes.Equals(vTest.Result, vResult), 'left pad bytes fail');
  end;
end;

procedure TCommonHelperTests.TestGetDataBig;
type
  TTestData = record
    Input: TBytes;
    Start: TBigInteger;
    Size: TBigInteger;
    Result: TBytes;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
  vResult: TBytes;
begin
  vTests := [
    (Input: [1, 2, 3, 4, 5, 6, 7, 8]; Start: TBigInteger.Create(0); Size: TBigInteger.Create(1); Result: [1]),
    (Input: [1, 2, 3, 4, 5, 6, 7, 8]; Start: TBigInteger.Create(0); Size: TBigInteger.Create(2); Result: [1, 2]),
    (Input: [1, 2, 3, 4, 5, 6, 7, 8]; Start: TBigInteger.Create(7); Size: TBigInteger.Create(1); Result: [8]),
    (Input: [1, 2, 3, 4, 5, 6, 7, 8]; Start: TBigInteger.Create(8); Size: TBigInteger.Create(1); Result: [0]),
    (Input: [1, 2, 3, 4, 5, 6, 7, 8]; Start: TBigInteger.Create(7); Size: TBigInteger.Create(2); Result: [8, 0])
  ];
  for vTest in vTests do
  begin
    vResult := GetDataBig(vTest.Input, vTest.Start, vTest.Size);
    Assert.IsTrue(TBytes.Equals(vTest.Result, vResult), 'get data big fail');
  end;
end;

procedure TCommonHelperTests.TestBytesToString;
type
  TTestData = record
    Input: TBytes;
    Result: string;
  end;
var
  vTests: TArray<TTestData>;
  vTest: TTestData;
  vResult: string;
begin
  vTests := [
    (Input: [116, 101, 115, 116]; Result: 'test'),
    (Input: [116, 101, 0, 115, 116]; Result: 'te'),
    (Input: [0, 116, 101, 115, 116]; Result: ''),
    (Input: [116, 101, 115, 116, 0, 0, 0, 0]; Result: 'test')
  ];
  for vTest in vTests do
  begin
    vResult := BytesToString(vTest.Input);
    Assert.AreEqual(vTest.Result, vResult, 'get string from byte array fail');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCommonHelperTests);
end.
