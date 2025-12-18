unit Common.HexUtil.JSON.Test;

interface

uses
  Common.HexUtil.HexUtil,
  Common.HexUtil.HexUtil.Test,
  Common.HexUtil.Json,
  Common.HexUtil.Json.Example.Test,
  DUnitX.TestFramework Common.HexUtil.JSON Common.HexUtil,
  GoToDelphi.Helpers.BigInt System.SysUtils;

type
  TUnmarshalTest = record
    input: string;
    want: TValue;
    wantErr: Exception;
    wantErr32bit: Exception;
  end;

  [TestFixture]
  TJsonHexUtilTests = class(TObject)
  private
    procedure checkError(t: TTest; input: string; got, want: Exception);
    function referenceBig(s: string): TBigInt;
    function referenceBytes(s: string): TBytes;
  public
    [Test]
    procedure TestUnmarshalBytes;
    [Test]
    procedure TestMarshalBytes;
    [Test]
    procedure TestUnmarshalBig;
    [Test]
    procedure TestMarshalBig;
    [Test]
    procedure TestUnmarshalUint64;
    [Test]
    procedure TestMarshalUint64;
    [Test]
    procedure TestUnmarshalUint;
    [Test]
    procedure TestMarshalUint;
    [Test]
    procedure TestUnmarshalFixedUnprefixedText;
  end;

implementation

uses
  System.Rtti, System.TypInfo;

procedure TJsonHexUtilTests.checkError(t: TTest; input: string; got, want: Exception);
begin
  if got = nil then
  begin
    if want <> nil then
      t.Fail(Format('input %s: got no error, want %s', [input, want.Message]));
    Exit;
  end;
  if want = nil then
    t.Fail(Format('input %s: unexpected error %s', [input, got.Message]));
  if got.ClassName <> want.ClassName then
      t.Fail(Format('input %s: got error type %s, want %s', [input, got.ClassName, want.ClassName]));
  if got.Message <> want.Message then
    t.Fail(Format('input %s: got error %s, want %s', [input, got.Message, want.Message]));
end;

function TJsonHexUtilTests.referenceBig(s: string): TBigInt;
begin
  Result := TBigInt.Create;
  Result.SetString(s, 16);
end;

function TJsonHexUtilTests.referenceBytes(s: string): TBytes;
var
  len: Integer;
begin
  len := Length(s) div 2;
  SetLength(Result, len);
  HexToBin(PChar(s), Result, len);
end;

procedure TJsonHexUtilTests.TestUnmarshalBytes;
var
  tests: TArray<TUnmarshalTest>;
  test: TUnmarshalTest;
  v: Bytes;
  err: Exception;
begin
  tests := [
    TUnmarshalTest.Create('', TValue.Empty, EJsonUnMarshalType.Create('unexpected end of JSON input', TBytes)),
    TUnmarshalTest.Create('null', TValue.Empty, errNonString(TBytes)),
    TUnmarshalTest.Create('10', TValue.Empty, errNonString(TBytes)),
    TUnmarshalTest.Create('"0"', TValue.Empty, wrapTypeError(ErrMissingPrefix, TBytes)),
    TUnmarshalTest.Create('"0x0"', TValue.Empty, wrapTypeError(ErrOddLength, TBytes)),
    TUnmarshalTest.Create('"0xxx"', TValue.Empty, wrapTypeError(ErrSyntax, TBytes)),
    TUnmarshalTest.Create('"0x01zz01"', TValue.Empty, wrapTypeError(ErrSyntax, TBytes)),
    TUnmarshalTest.Create('""', referenceBytes('')),
    TUnmarshalTest.Create('"0x"', referenceBytes('')),
    TUnmarshalTest.Create('"0x02"', referenceBytes('02')),
    TUnmarshalTest.Create('"0X02"', referenceBytes('02')),
    TUnmarshalTest.Create('"0xffffffffff"', referenceBytes('ffffffffff')),
    TUnmarshalTest.Create('"0xffffffffffffffffffffffffffffffffffff"', referenceBytes('ffffffffffffffffffffffffffffffffffff'))
  ];

  for test in tests do
  begin
    err := v.UnmarshalJSON(TEncoding.UTF8.GetBytes(test.input));
    checkError(Self, test.input, err, test.wantErr);
    if err = nil then
      Assert.AreEqual(test.want.AsType<TBytes>, v, 'value mismatch');
  end;
end;

procedure TJsonHexUtilTests.TestMarshalBytes;
type
  TEncodeBytesTest = record
    input: TBytes;
    want: string;
  end;
var
  tests: TArray<TEncodeBytesTest>;
  test: TEncodeBytesTest;
  outBytes: TBytes;
  outStr: string;
begin
  tests := [
    TEncodeBytesTest.Create(referenceBytes(''), '0x'),
    TEncodeBytesTest.Create(referenceBytes('02'), '0x02'),
    TEncodeBytesTest.Create(referenceBytes('ffffffffff'), '0xffffffffff'),
    TEncodeBytesTest.Create(referenceBytes('ffffffffffffffffffffffffffffffffffff'), '0xffffffffffffffffffffffffffffffffffff')
  ];

  for test in tests do
  begin
    outBytes := test.input.MarshalText;
    outStr := TEncoding.UTF8.GetString(outBytes);
    Assert.AreEqual('"' + test.want + '"', outStr, 'MarshalJSON output mismatch');
    Assert.AreEqual(test.want, test.input.ToString, 'String mismatch');
  end;
end;

procedure TJsonHexUtilTests.TestUnmarshalBig;
var
  tests: TArray<TUnmarshalTest>;
  test: TUnmarshalTest;
  v: Big;
  err: Exception;
begin
  tests := [
    TUnmarshalTest.Create('', TValue.Empty, EJsonUnMarshalType.Create('unexpected end of JSON input', TBigInt)),
    TUnmarshalTest.Create('null', TValue.Empty, errNonString(TBigInt)),
    TUnmarshalTest.Create('10', TValue.Empty, errNonString(TBigInt)),
    TUnmarshalTest.Create('"0"', TValue.Empty, wrapTypeError(ErrMissingPrefix, TBigInt)),
    TUnmarshalTest.Create('"0x"', TValue.Empty, wrapTypeError(ErrEmptyNumber, TBigInt)),
    TUnmarshalTest.Create('"0x01"', TValue.Empty, wrapTypeError(ErrLeadingZero, TBigInt)),
    TUnmarshalTest.Create('"0xx"', TValue.Empty, wrapTypeError(ErrSyntax, TBigInt)),
    TUnmarshalTest.Create('"0x1zz01"', TValue.Empty, wrapTypeError(ErrSyntax, TBigInt)),
    TUnmarshalTest.Create('"0x10000000000000000000000000000000000000000000000000000000000000000"', TValue.Empty, wrapTypeError(ErrBig256Range, TBigInt)),
    TUnmarshalTest.Create('""', TValue.From<TBigInt>(referenceBig('0'))),
    TUnmarshalTest.Create('"0x0"', TValue.From<TBigInt>(referenceBig('0'))),
    TUnmarshalTest.Create('"0x2"', TValue.From<TBigInt>(referenceBig('2'))),
    TUnmarshalTest.Create('"0x2F2"', TValue.From<TBigInt>(referenceBig('2f2'))),
    TUnmarshalTest.Create('"0X2F2"', TValue.From<TBigInt>(referenceBig('2f2'))),
    TUnmarshalTest.Create('"0x1122aaff"', TValue.From<TBigInt>(referenceBig('1122aaff'))),
    TUnmarshalTest.Create('"0xbBb"', TValue.From<TBigInt>(referenceBig('bbb'))),
    TUnmarshalTest.Create('"0xfffffffff"', TValue.From<TBigInt>(referenceBig('fffffffffff'))),
    TUnmarshalTest.Create('"0x112233445566778899aabbccddeeff"', TValue.From<TBigInt>(referenceBig('112233445566778899aabbccddeeff'))),
    TUnmarshalTest.Create('"0xffffffffffffffffffffffffffffffffffff"', TValue.From<TBigInt>(referenceBig('ffffffffffffffffffffffffffffffffffff'))),
    TUnmarshalTest.Create('"0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"', TValue.From<TBigInt>(referenceBig('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff')))
  ];

  for test in tests do
  begin
    err := v.UnmarshalJSON(TEncoding.UTF8.GetBytes(test.input));
    checkError(Self, test.input, err, test.wantErr);
    if err = nil then
      Assert.AreEqual(test.want.AsType<TBigInt>, v, 'value mismatch');
  end;
end;

procedure TJsonHexUtilTests.TestMarshalBig;
type
  TEncodeBigTest = record
    input: TBigInt;
    want: string;
  end;
var
  tests: TArray<TEncodeBigTest>;
  test: TEncodeBigTest;
  outBytes: TBytes;
  outStr: string;
begin
  tests := [
    TEncodeBigTest.Create(referenceBig('0'), '0x0'),
    TEncodeBigTest.Create(referenceBig('2'), '0x2'),
    TEncodeBigTest.Create(referenceBig('2f2'), '0x2f2'),
    TEncodeBigTest.Create(referenceBig('1122aaff'), '0x1122aaff'),
    TEncodeBigTest.Create(referenceBig('ffffffffffffffffffffffffffffffffffff'), '0xffffffffffffffffffffffffffffffffffff')
  ];

  for test in tests do
  begin
    outBytes := test.input.MarshalText;
    outStr := TEncoding.UTF8.GetString(outBytes);
    Assert.AreEqual('"' + test.want + '"', outStr, 'MarshalJSON output mismatch');
    Assert.AreEqual(test.want, test.input.ToString, 'String mismatch');
  end;
end;

procedure TJsonHexUtilTests.TestUnmarshalUint64;
var
  tests: TArray<TUnmarshalTest>;
  test: TUnmarshalTest;
  v: Uint64;
  err: Exception;
  Uint64T: TClass;
begin
  Uint64T := TValue.From<Uint64>(0).TypeInfo.GetClass;
  tests := [
    TUnmarshalTest.Create('', TValue.Empty, EJsonUnMarshalType.Create('unexpected end of JSON input', Uint64T)),
    TUnmarshalTest.Create('null', TValue.Empty, errNonString(Uint64T)),
    TUnmarshalTest.Create('10', TValue.Empty, errNonString(Uint64T)),
    TUnmarshalTest.Create('"0"', TValue.Empty, wrapTypeError(ErrMissingPrefix, Uint64T)),
    TUnmarshalTest.Create('"0x"', TValue.Empty, wrapTypeError(ErrEmptyNumber, Uint64T)),
    TUnmarshalTest.Create('"0x01"', TValue.Empty, wrapTypeError(ErrLeadingZero, Uint64T)),
    TUnmarshalTest.Create('"0xfffffffffffffffff"', TValue.Empty, wrapTypeError(ErrUint64Range, Uint64T)),
    TUnmarshalTest.Create('"0xx"', TValue.Empty, wrapTypeError(ErrSyntax, Uint64T)),
    TUnmarshalTest.Create('"0x1zz01"', TValue.Empty, wrapTypeError(ErrSyntax, Uint64T)),
    TUnmarshalTest.Create('""', TValue.From<Uint64>(0)),
    TUnmarshalTest.Create('"0x0"', TValue.From<Uint64>(0)),
    TUnmarshalTest.Create('"0x2"', TValue.From<Uint64>($2)),
    TUnmarshalTest.Create('"0x2F2"', TValue.From<Uint64>($2f2)),
    TUnmarshalTest.Create('"0X2F2"', TValue.From<Uint64>($2f2)),
    TUnmarshalTest.Create('"0x1122aaff"', TValue.From<Uint64>($1122aaff)),
    TUnmarshalTest.Create('"0xbbb"', TValue.From<Uint64>($bbb)),
    TUnmarshalTest.Create('"0xffffffffffffffff"', TValue.From<Uint64>($ffffffffffffffff))
  ];

  for test in tests do
  begin
    err := v.UnmarshalJSON(TEncoding.UTF8.GetBytes(test.input));
    checkError(Self, test.input, err, test.wantErr);
    if err = nil then
      Assert.AreEqual(test.want.AsType<Uint64>, v, 'value mismatch');
  end;
end;

procedure TJsonHexUtilTests.TestMarshalUint64;
type
  TEncodeUint64Test = record
    input: Uint64;
    want: string;
  end;
var
  tests: TArray<TEncodeUint64Test>;
  test: TEncodeUint64Test;
  outBytes: TBytes;
  outStr: string;
begin
  tests := [
    TEncodeUint64Test.Create(0, '0x0'),
    TEncodeUint64Test.Create($2, '0x2'),
    TEncodeUint64Test.Create($2f2, '0x2f2'),
    TEncodeUint64Test.Create($1122aaff, '0x1122aaff'),
    TEncodeUint64Test.Create($ffffffffffffffff, '0xffffffffffffffff')
  ];

  for test in tests do
  begin
    outBytes := test.input.MarshalText;
    outStr := TEncoding.UTF8.GetString(outBytes);
    Assert.AreEqual('"' + test.want + '"', outStr, 'MarshalJSON output mismatch');
    Assert.AreEqual(test.want, test.input.ToString, 'String mismatch');
  end;
end;

procedure TJsonHexUtilTests.TestUnmarshalUint;
var
  tests: TArray<TUnmarshalTest>;
  test: TUnmarshalTest;
  v: Uint;
  err: Exception;
  UintT: TClass;
  maxUint33bits: Uint64;
begin
  UintT := TValue.From<Uint>(0).TypeInfo.GetClass;
  maxUint33bits := High(UInt32) + 1;

  tests := [
    TUnmarshalTest.Create('', TValue.Empty, EJsonUnMarshalType.Create('unexpected end of JSON input', UintT)),
    TUnmarshalTest.Create('null', TValue.Empty, errNonString(UintT)),
    TUnmarshalTest.Create('10', TValue.Empty, errNonString(UintT)),
    TUnmarshalTest.Create('"0"', TValue.Empty, wrapTypeError(ErrMissingPrefix, UintT)),
    TUnmarshalTest.Create('"0x"', TValue.Empty, wrapTypeError(ErrEmptyNumber, UintT)),
    TUnmarshalTest.Create('"0x01"', TValue.Empty, wrapTypeError(ErrLeadingZero, UintT)),
    TUnmarshalTest.Create('"0x100000000"', TValue.From<Uint>(maxUint33bits), nil, wrapTypeError(ErrUintRange, UintT)),
    TUnmarshalTest.Create('"0xfffffffffffffffff"', TValue.Empty, wrapTypeError(ErrUintRange, UintT)),
    TUnmarshalTest.Create('"0xx"', TValue.Empty, wrapTypeError(ErrSyntax, UintT)),
    TUnmarshalTest.Create('"0x1zz01"', TValue.Empty, wrapTypeError(ErrSyntax, UintT)),
    TUnmarshalTest.Create('""', TValue.From<Uint>(0)),
    TUnmarshalTest.Create('"0x0"', TValue.From<Uint>(0)),
    TUnmarshalTest.Create('"0x2"', TValue.From<Uint>($2)),
    TUnmarshalTest.Create('"0x2F2"', TValue.From<Uint>($2f2)),
    TUnmarshalTest.Create('"0X2F2"', TValue.From<Uint>($2f2)),
    TUnmarshalTest.Create('"0x1122aaff"', TValue.From<Uint>($1122aaff)),
    TUnmarshalTest.Create('"0xbbb"', TValue.From<Uint>($bbb)),
    TUnmarshalTest.Create('"0xffffffff"', TValue.From<Uint>($ffffffff)),
    TUnmarshalTest.Create('"0xffffffffffffffff"', TValue.From<Uint>(High(UInt64)), nil, wrapTypeError(ErrUintRange, UintT))
  ];

  for test in tests do
  begin
    err := v.UnmarshalJSON(TEncoding.UTF8.GetBytes(test.input));
    if (SizeOf(Pointer) = 4) and (test.wantErr32bit <> nil) then
      checkError(Self, test.input, err, test.wantErr32bit)
    else
      checkError(Self, test.input, err, test.wantErr);
    if err = nil then
      Assert.AreEqual(test.want.AsType<Uint>, v, 'value mismatch');
  end;
end;

procedure TJsonHexUtilTests.TestMarshalUint;
type
  TEncodeUintTest = record
    input: Uint;
    want: string;
  end;
var
  tests: TArray<TEncodeUintTest>;
  test: TEncodeUintTest;
  outBytes: TBytes;
  outStr: string;
begin
  tests := [
    TEncodeUintTest.Create(0, '0x0'),
    TEncodeUintTest.Create($2, '0x2'),
    TEncodeUintTest.Create($2f2, '0x2f2'),
    TEncodeUintTest.Create($1122aaff, '0x1122aaff')
  ];

  for test in tests do
  begin
    outBytes := test.input.MarshalText;
    outStr := TEncoding.UTF8.GetString(outBytes);
    Assert.AreEqual('"' + test.want + '"', outStr, 'MarshalJSON output mismatch');
    Assert.AreEqual(test.want, test.int.ToString, 'String mismatch');
  end;
end;

procedure TJsonHexUtilTests.TestUnmarshalFixedUnprefixedText;
type
  TFixedUnprefixedTest = record
    input: string;
    want: TBytes;
    wantErr: Exception;
  end;
var
  tests: TArray<TFixedUnprefixedTest>;
  test: TFixedUnprefixedTest;
  outBytes: TBytes;
  err: Exception;
begin
  tests := [
    TFixedUnprefixedTest.Create('0x2', nil, ErrOddLength),
    TFixedUnprefixedTest.Create('2', nil, ErrOddLength),
    TFixedUnprefixedTest.Create('4444', nil, Exception.Create('hex string has length 4, want 8 for x')),
    TFixedUnprefixedTest.Create('444444gg', referenceBytes('00000000'), ErrSyntax),
    TFixedUnprefixedTest.Create('0x444444gg', referenceBytes('00000000'), ErrSyntax),
    TFixedUnprefixedTest.Create('44444444', referenceBytes('44444444')),
    TFixedUnprefixedTest.Create('0x44444444', referenceBytes('44444444'))
  ];

  for test in tests do
  begin
    SetLength(outBytes, 4);
    err := TJsonHexUtil.UnmarshalFixedUnprefixedText('x', TEncoding.UTF8.GetBytes(test.input), outBytes);
    checkError(Self, test.input, err, test.wantErr);
    if test.want <> nil then
      Assert.AreEqual(test.want, outBytes, 'output mismatch');
  end;
end;

initialization
  RegisterTestFixture(TJsonHexUtilTests);
end.
