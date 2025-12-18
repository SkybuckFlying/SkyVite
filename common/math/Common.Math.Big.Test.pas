unit Common.Math.Big.Test;

interface

uses
  Common.Bytes,
  Common.Math.Big,
  Common.Math.Integer,
  Common.Math.Integer.Test,
  DUnitX.TestFramework,
  System.Math.BigInts,
  System.SysUtils;

type
	[TestFixture]
	TCommonMathBigTests = class(TObject)
	public
		[Test]
		procedure TestHexOrDecimal256;
		[Test]
		procedure TestMustParseBig256;
		[Test]
		procedure TestBigMax;
		[Test]
		procedure TestBigMin;
		[Test]
		procedure TestFirstBitSet;
		[Test]
		procedure TestPaddedBigBytes;
		[Test]
		procedure TestReadBits;
		[Test]
		procedure TestByte;
		[Test]
		procedure TestU256;
		[Test]
		procedure TestS256;
		[Test]
		procedure TestExp;
	end;

implementation

uses
	Common.HexUtil;

procedure TCommonMathBigTests.TestHexOrDecimal256;
type
	THexOrDecimal256Test = record
		Input: string;
		Num: TBigInteger;
		Ok: Boolean;
	end;
var
	vTests: TArray<THexOrDecimal256Test>;
	vTest: THexOrDecimal256Test;
	vNum: THexOrDecimal256;
	vErr: Exception;
begin
	vTests := [
		THexOrDecimal256Test.Create('', Big0, true),
		THexOrDecimal256Test.Create('0', Big0, true),
		THexOrDecimal256Test.Create('0x0', Big0, true),
		THexOrDecimal256Test.Create('12345678', 12345678, true),
		THexOrDecimal256Test.Create('0x12345678', $12345678, true),
		THexOrDecimal256Test.Create('0X12345678', $12345678, true),
		THexOrDecimal256Test.Create('0123456789', 123456789, true),
		THexOrDecimal256Test.Create('00', Big0, true),
		THexOrDecimal256Test.Create('0x00', Big0, true),
		THexOrDecimal256Test.Create('0x012345678abc', TBigInteger.Parse('12345678abc', 16), true),
		THexOrDecimal256Test.Create('abcdef', nil, false),
		THexOrDecimal256Test.Create('0xgg', nil, false),
		THexOrDecimal256Test.Create('115792089237316195423570985008687907853269984665640564039457584007913129639936', nil, false)
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

		Assert.AreEqual(vTest.Ok, vErr = nil, 'ParseBig(' + vTest.Input + ')');
		if vTest.Num <> nil then
		begin
			Assert.AreEqual(vTest.Num, TBigInteger(vNum), 'ParseBig(' + vTest.Input + ')');
		end;
	end;
end;

procedure TCommonMathBigTests.TestMustParseBig256;
begin
	Assert.WillRaise(procedure
	begin
		TBig.MustParseBig256( 'ggg' );
	end, Exception);
end;

procedure TCommonMathBigTests.TestBigMax;
var
	vA, vB, vMax1, vMax2: TBigInteger;
begin
	vA := 10;
	vB := 5;

	vMax1 := TBig.BigMax( vA, vB );
	Assert.AreEqual( vA, vMax1 );

	vMax2 := TBig.BigMax( vB, vA );
	Assert.AreEqual( vA, vMax2 );
end;

procedure TCommonMathBigTests.TestBigMin;
var
	vA, vB, vMin1, vMin2: TBigInteger;
begin
	vA := 10;
	vB := 5;

	vMin1 := TBig.BigMin( vA, vB );
	Assert.AreEqual( vB, vMin1 );

	vMin2 := TBig.BigMin( vB, vA );
	Assert.AreEqual( vB, vMin2 );
end;

procedure TCommonMathBigTests.TestFirstBitSet;
type
	TFirstBitSetTest = record
		Num: TBigInteger;
		Ix: Integer;
	end;
var
	vTests: TArray<TFirstBitSetTest>;
	vTest: TFirstBitSetTest;
	vIx: Integer;
begin
	vTests := [
		TFirstBitSetTest.Create(Big0, 0),
		TFirstBitSetTest.Create(Big1, 0),
		TFirstBitSetTest.Create(Big2, 1),
		TFirstBitSetTest.Create(TBigInteger.Create($100), 8)
	];
	for vTest in vTests do
	begin
		vIx := TBig.FirstBitSet( vTest.Num );
		Assert.AreEqual(vTest.Ix, vIx, 'FirstBitSet(' + vTest.Num.ToString + ')');
	end;
end;

procedure TCommonMathBigTests.TestPaddedBigBytes;
type
	TPaddedBigBytesTest = record
		Num: TBigInteger;
		N: Integer;
		Result: TBytes;
	end;
var
	vTests: TArray<TPaddedBigBytesTest>;
	vTest: TPaddedBigBytesTest;
	vResult: TBytes;
begin
	vTests := [
		TPaddedBigBytesTest.Create(Big0, 4, [0, 0, 0, 0]),
		TPaddedBigBytesTest.Create(Big1, 4, [0, 0, 0, 1]),
		TPaddedBigBytesTest.Create(512, 4, [0, 0, 2, 0]),
		TPaddedBigBytesTest.Create(TBig.BigPow(2, 32), 5, [1, 0, 0, 0, 0])
	];
	for vTest in vTests do
	begin
		vResult := TBig.PaddedBigBytes( vTest.Num, vTest.N );
		Assert.AreEqual<TBytes>(vTest.Result, vResult, 'PaddedBigBytes(' + vTest.Num.ToString + ')');
	end;
end;

procedure TCommonMathBigTests.TestReadBits;
var
	vWant, vBuf: TBytes;
	vInt: TBigInteger;
	vInput: string;
	vCheck: procedure(const ParaInput: string);
begin
	vCheck := procedure(const ParaInput: string)
	var
		vWantBytes, vBufBytes: TBytes;
		vBigInt: TBigInteger;
	begin
		vWantBytes := THexUtil.HexToBytes(ParaInput);
		TBigInteger.TryParse(ParaInput, 16, vBigInt);
		try
			SetLength(vBufBytes, Length(vWantBytes));
			TBig.ReadBits(vBigInt, vBufBytes);
			Assert.AreEqual<TBytes>(vWantBytes, vBufBytes, 'ReadBits(' + ParaInput + ')');
		except
			on E: EOutOfMemory do
			begin
				Assert.Fail('Out of memory during TestReadBits');
			end;
		end;
	end;

	vCheck('000000000000000000000000000000000000000000000000000000FEFCF3F8F0');
	vCheck('0000000000012345000000000000000000000000000000000000FEFCF3F8F0');
	vCheck('18F8F8F1000111000110011100222004330052300000000000000000FEFCF3F8F0');
end;

procedure TCommonMathBigTests.TestByte;
type
	TByteTest = record
		X: string;
		Y: Integer;
		Expected: Byte;
	end;
var
	vTests: TArray<TByteTest>;
	vTest: TByteTest;
	vValue: TBigInteger;
	vActual: Byte;
begin
	vTests := [
		TByteTest.Create('00', 0, $00),
		TByteTest.Create('01', 1, $00),
		TByteTest.Create('00', 1, $00),
		TByteTest.Create('01', 0, $00), // LSB is at the far end
		TByteTest.Create('0000000000000000000000000000000000000000000000000000000000102030', 0, $00),
		TByteTest.Create('0000000000000000000000000000000000000000000000000000000000102030', 1, $00),
		TByteTest.Create('ABCDEF0908070605040302010000000000000000000000000000000000000000', 31, $00),
		TByteTest.Create('ABCDEF0908070605040302010000000000000000000000000000000000000000', 32, $00),
		TByteTest.Create('ABCDEF0908070605040302010000000000000000000000000000000000000000', 0, $AB),
		TByteTest.Create('ABCDEF0908070605040302010000000000000000000000000000000000000000', 1, $CD),
		TByteTest.Create('00CDEF090807060504030201ffffffffffffffffffffffffffffffffffffffff', 0, $00),
		TByteTest.Create('00CDEF090807060504030201ffffffffffffffffffffffffffffffffffffffff', 1, $CD),
		TByteTest.Create('0000000000000000000000000000000000000000000000000000000000102030', 31, $30),
		TByteTest.Create('0000000000000000000000000000000000000000000000000000000000102030', 30, $20),
		TByteTest.Create('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 32, $0),
		TByteTest.Create('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 31, $FF),
		TByteTest.Create('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', $FFFF, $0)
	];

	for vTest in vTests do
	begin
		TBigInteger.TryParse(vTest.X, 16, vValue);
		vActual := TBig.Byte(vValue, 32, vTest.Y);
		Assert.AreEqual(vTest.Expected, vActual, Format('Expected [%s] %d:th byte to be %x, was %x.', [vTest.X, vTest.Y, vTest.Expected, vActual]));
	end;
end;

procedure TCommonMathBigTests.TestU256;
type
	TU256Test = record
		X, Y: TBigInteger;
	end;
var
	vTests: TArray<TU256Test>;
	vTest: TU256Test;
	vY: TBigInteger;
begin
	vTests := [
		TU256Test.Create(Big0, Big0),
		TU256Test.Create(Big1, Big1),
		TU256Test.Create(tt255, tt255),
		TU256Test.Create(tt256, Big0),
		TU256Test.Create(tt256 + Big1, Big1),
		TU256Test.Create(TBigInteger.Create(-1), tt256 - Big1),
		TU256Test.Create(TBigInteger.Create(-2), tt256 - Big2)
	];
	for vTest in vTests do
	begin
		vY := TBig.U256( vTest.X );
		Assert.AreEqual(vTest.Y, vY, 'U256(' + vTest.X.ToHexString + ')');
	end;
end;

procedure TCommonMathBigTests.TestS256;
type
	TS256Test = record
		X, Y: TBigInteger;
	end;
var
	vTests: TArray<TS256Test>;
	vTest: TS256Test;
	vY: TBigInteger;
begin
	vTests := [
		TS256Test.Create(Big0, Big0),
		TS256Test.Create(Big1, Big1),
		TS256Test.Create(Big2, Big2),
		TS256Test.Create(tt255 - Big1, tt255 - Big1),
		TS256Test.Create(tt255, -tt255),
		TS256Test.Create(tt256 - Big1, TBigInteger.Create(-1)),
		TS256Test.Create(tt256 - Big2, TBigInteger.Create(-2))
	];
	for vTest in vTests do
	begin
		vY := TBig.S256( vTest.X );
		Assert.AreEqual(vTest.Y, vY, 'S256(' + vTest.X.ToHexString + ')');
	end;
end;

procedure TCommonMathBigTests.TestExp;
type
	TExpTest = record
		Base, Exponent, Result: TBigInteger;
	end;
var
	vTests: TArray<TExpTest>;
	vTest: TExpTest;
	vResult: TBigInteger;
begin
	vTests := [
		TExpTest.Create(Big0, Big0, Big1),
		TExpTest.Create(Big1, Big0, Big1),
		TExpTest.Create(Big1, Big1, Big1),
		TExpTest.Create(Big1, Big2, Big1),
		TExpTest.Create(Big3, 144, TBig.MustParseBig256('507528786056415600719754159741696356908742250191663887263627442114881')),
		TExpTest.Create(Big2, 255, TBig.MustParseBig256('57896044618658097711785492504343953926634992332820282019728792003956564819968'))
	];
	for vTest in vTests do
	begin
		vResult := TBig.Exp( vTest.Base, vTest.Exponent );
		Assert.AreEqual(vTest.Result, vResult, 'Exp(' + vTest.Base.ToString + ', ' + vTest.Exponent.ToString + ')');
	end;
end;

initialization
	TDUnitX.RegisterTestFixture(TCommonMathBigTests);
end.
