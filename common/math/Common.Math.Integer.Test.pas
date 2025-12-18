unit Common.Math.Integer.Test;

interface

uses
  Common.Bytes,
  Common.Math.Big,
  Common.Math.Big.Test,
  Common.Math.Integer,
  DUnitX.TestFramework,
  System.SysUtils;

type
	[TestFixture]
	TCommonMathIntegerTests = class(TObject)
	public
		[Test]
		procedure TestOverflow;
		[Test]
		procedure TestHexOrDecimal64;
		[Test]
		procedure TestMustParseUint64;
		[Test]
		procedure TestMustParseUint64Panic;
		[Test]
		procedure TestSatSub;
	end;

implementation

{ TCommonMathIntegerTests }

procedure TCommonMathIntegerTests.TestOverflow;
type
	TOperation = (opSub, opAdd, opMul);
	TOverflowTest = record
		X, Y: UInt64;
		Overflow: Boolean;
		Op: TOperation;
	end;
var
	vTests: TArray<TOverflowTest>;
	vTest: TOverflowTest;
	vOverflows: Boolean;
	vResult: UInt64;
begin
	vTests := [
		// add operations
		TOverflowTest.Create(ConstMaxUint64, 1, true, opAdd),
		TOverflowTest.Create(ConstMaxUint64 - 1, 1, false, opAdd),
		// sub operations
		TOverflowTest.Create(0, 1, true, opSub),
		TOverflowTest.Create(0, 0, false, opSub),
		// mul operations
		TOverflowTest.Create(0, 0, false, opMul),
		TOverflowTest.Create(10, 10, false, opMul),
		TOverflowTest.Create(ConstMaxUint64, 2, true, opMul),
		TOverflowTest.Create(ConstMaxUint64, 1, false, opMul)
	];

	for vTest in vTests do
	begin
		case vTest.Op of
			opSub: vOverflows := not TInteger.SafeSub(vTest.X, vTest.Y, vResult);
			opAdd: vOverflows := not TInteger.SafeAdd(vTest.X, vTest.Y, vResult);
			opMul: vOverflows := not TInteger.SafeMul(vTest.X, vTest.Y, vResult);
		end;
		Assert.AreEqual(vTest.Overflow, vOverflows, 'Overflow test failed for op ' + Ord(vTest.Op).ToString);
	end;
end;

procedure TCommonMathIntegerTests.TestHexOrDecimal64;
type
	THexOrDecimal64Test = record
		Input: string;
		Num: UInt64;
		Ok: Boolean;
	end;
var
	vTests: TArray<THexOrDecimal64Test>;
	vTest: THexOrDecimal64Test;
	vNum: THexOrDecimal64;
	vErr: Exception;
begin
	vTests := [
		THexOrDecimal64Test.Create('', 0, true),
		THexOrDecimal64Test.Create('0', 0, true),
		THexOrDecimal64Test.Create('0x0', 0, true),
		THexOrDecimal64Test.Create('12345678', 12345678, true),
		THexOrDecimal64Test.Create('0x12345678', $12345678, true),
		THexOrDecimal64Test.Create('0X12345678', $12345678, true),
		THexOrDecimal64Test.Create('0123456789', 123456789, true),
		THexOrDecimal64Test.Create('0x00', 0, true),
		THexOrDecimal64Test.Create('0x012345678abc', $012345678abc, true),
		THexOrDecimal64Test.Create('abcdef', 0, false),
		THexOrDecimal64Test.Create('0xgg', 0, false),
		THexOrDecimal64Test.Create('18446744073709551617', 0, false)
	];

	for vTest in vTests do
	begin
		vErr := nil;
		try
			vNum.UnmarshalText( TEncoding.UTF8.GetBytes( vTest.Input ) );
		except
			on E: Exception do
			begin
				vErr := E;
			end;
		end;

		Assert.AreEqual(vTest.Ok, vErr = nil, 'ParseUint64(' + vTest.Input + ')');
		if (vErr = nil) then
		begin
			Assert.AreEqual(vTest.Num, UInt64(vNum), 'ParseUint64(' + vTest.Input + ')');
		end;
	end;
end;

procedure TCommonMathIntegerTests.TestMustParseUint64;
begin
	Assert.AreEqual(UInt64(12345), TInteger.MustParseUint64('12345'));
end;

procedure TCommonMathIntegerTests.TestMustParseUint64Panic;
begin
	Assert.WillRaise(procedure
	begin
		TInteger.MustParseUint64('ggg');
	end, Exception);
end;

procedure TCommonMathIntegerTests.TestSatSub;
type
	TSatSubTest = record
		X, Y, Expected: UInt64;
	end;
var
	vTests: TArray<TSatSubTest>;
	vTest: TSatSubTest;
	vResult: UInt64;
begin
	vTests := [
		TSatSubTest.Create(10, 5, 5),
		TSatSubTest.Create(5, 10, 0),
		TSatSubTest.Create(0, 0, 0),
		TSatSubTest.Create(ConstMaxUint64, 1, ConstMaxUint64 - 1),
		TSatSubTest.Create(ConstMaxUint64, ConstMaxUint64, 0)
	];

	for vTest in vTests do
	begin
		vResult := TInteger.SatSub(vTest.X, vTest.Y);
		Assert.AreEqual(vTest.Expected, vResult, Format('SatSub(%d, %d)', [vTest.X, vTest.Y]));
	end;
end;

initialization
	TDUnitX.RegisterTestFixture(TCommonMathIntegerTests);
end.
