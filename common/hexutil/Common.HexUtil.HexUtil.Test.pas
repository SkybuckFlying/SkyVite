unit Common.HexUtil.HexUtil.Test;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  THexUtilTests = class
  public
    [Test]
    procedure TestEncode;
    [Test]
    procedure TestDecode;
    [Test]
    procedure TestEncodeBig;
    [Test]
    procedure TestDecodeBig;
    [Test]
    procedure TestEncodeUint64;
    [Test]
    procedure TestDecodeUint64;
  end;

implementation

uses
  System.SysUtils,
  System.Math.BigInts,
  Common.HexUtil;

{ THexUtilTests }

procedure THexUtilTests.TestEncode;
type
  TMarshalTest = record
    Input: TBytes;
    Want: string;
  end;
var
  vTests: TArray<TMarshalTest>;
  vTest: TMarshalTest;
  vEnc: string;
begin
  vTests := [
    (Input: []; Want: '0x'),
    (Input: [0]; Want: '0x00'),
    (Input: [0, 0, 1, 2]; Want: '0x00000102')
  ];
  for vTest in vTests do
  begin
    vEnc := Encode(vTest.Input);
    Assert.AreEqual(vTest.Want, vEnc, 'Encode bytes failed');
  end;
end;

procedure THexUtilTests.TestDecode;
type
  TUnmarshalTest = record
    Input: string;
    Want: TBytes;
    WantErr: ExceptClass;
  end;
var
  vTests: TArray<TUnmarshalTest>;
  vTest: TUnmarshalTest;
  vDec: TBytes;
begin
  vTests := [
    (Input: ''; WantErr: EHexutilError),
    (Input: '0'; WantErr: EHexutilError),
    (Input: '0x0'; WantErr: EHexutilError),
    (Input: '0x023'; WantErr: EHexutilError),
    (Input: '0xxx'; WantErr: EHexutilError),
    (Input: '0x01zz01'; WantErr: EHexutilError),
    (Input: '0x'; Want: []),
    (Input: '0X'; Want: []),
    (Input: '0x02'; Want: [2]),
    (Input: '0X02'; Want: [2]),
    (Input: '0xffffffffff'; Want: [$FF, $FF, $FF, $FF, $FF]),
    (Input: '0xffffffffffffffffffffffffffffffffffff'; Want: [$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF])
  ];
  for vTest in vTests do
  begin
    if vTest.WantErr <> nil then
    begin
      Assert.Throws(procedure begin Decode(vTest.Input); end, vTest.WantErr);
    end
    else
    begin
      vDec := Decode(vTest.Input);
      Assert.IsTrue(TBytes.Equals(vTest.Want, vDec), 'Decode bytes failed');
    end;
  end;
end;

procedure THexUtilTests.TestEncodeBig;
type
  TMarshalTest = record
    Input: TBigInteger;
    Want: string;
  end;
var
  vTests: TArray<TMarshalTest>;
  vTest: TMarshalTest;
  vEnc: string;
begin
  vTests := [
    (Input: TBigInteger.Zero; Want: '0x0'),
    (Input: TBigInteger.One; Want: '0x1'),
    (Input: TBigInteger.Create($FF); Want: '0xff'),
    (Input: TBigInteger.Create(TBytes.Create($11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF)); Want: '0x112233445566778899aabbccddeeff'),
    (Input: TBigInteger.Create(TBytes.Create($80, $A7, $F2, $C1, $BC, $C3, $96, $C0, $00)); Want: '0x80a7f2c1bcc396c00'),
    (Input: -TBigInteger.Create(TBytes.Create($80, $A7, $F2, $C1, $BC, $C3, $96, $C0, $00)); Want: '-0x80a7f2c1bcc396c00')
  ];
  for vTest in vTests do
  begin
    vEnc := EncodeBig(vTest.Input);
    Assert.AreEqual(vTest.Want, vEnc, 'Encode big failed');
  end;
end;

procedure THexUtilTests.TestDecodeBig;
type
  TUnmarshalTest = record
    Input: string;
    Want: TBigInteger;
    WantErr: ExceptClass;
  end;
var
  vTests: TArray<TUnmarshalTest>;
  vTest: TUnmarshalTest;
  vDec: TBigInteger;
begin
  vTests := [
    (Input: '0'; WantErr: EHexutilError),
    (Input: '0x'; WantErr: EHexutilError),
    (Input: '0x01'; WantErr: EHexutilError),
    (Input: '0xx'; WantErr: EHexutilError),
    (Input: '0x1zz01'; WantErr: EHexutilError),
    (Input: '0x10000000000000000000000000000000000000000000000000000000000000000'; WantErr: EHexutilError),
    (Input: '0x0'; Want: TBigInteger.Zero),
    (Input: '0x2'; Want: TBigInteger.Create(2)),
    (Input: '0x2F2'; Want: TBigInteger.Create($2F2)),
    (Input: '0X2F2'; Want: TBigInteger.Create($2F2)),
    (Input: '0x1122aaff'; Want: TBigInteger.Create($1122aaff)),
    (Input: '0xbBb'; Want: TBigInteger.Create($bbb)),
    (Input: '0xfffffffff'; Want: TBigInteger.Create($ffffffff)),
    (Input: '0x112233445566778899aabbccddeeff'; Want: TBigInteger.Create(TBytes.Create($11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF))),
    (Input: '0xffffffffffffffffffffffffffffffffffff'; Want: TBigInteger.Create(TBytes.Create($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF))),
    (Input: '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'; Want: TBigInteger.Create(TBytes.Create($FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF)))
  ];
  for vTest in vTests do
  begin
    if vTest.WantErr <> nil then
    begin
      Assert.Throws(procedure begin DecodeBig(vTest.Input); end, vTest.WantErr);
    end
    else
    begin
      vDec := DecodeBig(vTest.Input);
      Assert.AreEqual(vTest.Want, vDec, 'Decode big failed');
    end;
  end;
end;

procedure THexUtilTests.TestEncodeUint64;
type
  TMarshalTest = record
    Input: UInt64;
    Want: string;
  end;
var
  vTests: TArray<TMarshalTest>;
  vTest: TMarshalTest;
  vEnc: string;
begin
  vTests := [
    (Input: 0; Want: '0x0'),
    (Input: 1; Want: '0x1'),
    (Input: $FF; Want: '0xff'),
    (Input: $1122334455667788; Want: '0x1122334455667788')
  ];
  for vTest in vTests do
  begin
    vEnc := EncodeUint64(vTest.Input);
    Assert.AreEqual(vTest.Want, vEnc, 'Encode uint64 failed');
  end;
end;

procedure THexUtilTests.TestDecodeUint64;
type
  TUnmarshalTest = record
    Input: string;
    Want: UInt64;
    WantErr: ExceptClass;
  end;
var
  vTests: TArray<TUnmarshalTest>;
  vTest: TUnmarshalTest;
  vDec: UInt64;
begin
  vTests := [
    (Input: '0'; WantErr: EHexutilError),
    (Input: '0x'; WantErr: EHexutilError),
    (Input: '0x01'; WantErr: EHexutilError),
    (Input: '0xfffffffffffffffff'; WantErr: EHexutilError),
    (Input: '0xx'; WantErr: EHexutilError),
    (Input: '0x1zz01'; WantErr: EHexutilError),
    (Input: '0x0'; Want: 0),
    (Input: '0x2'; Want: 2),
    (Input: '0x2F2'; Want: $2F2),
    (Input: '0X2F2'; Want: $2F2),
    (Input: '0x1122aaff'; Want: $1122aaff),
    (Input: '0xbbb'; Want: $bbb),
    (Input: '0xffffffffffffffff'; Want: $ffffffffffffffff)
  ];
  for vTest in vTests do
  begin
    if vTest.WantErr <> nil then
    begin
      Assert.Throws(procedure begin DecodeUint64(vTest.Input); end, vTest.WantErr);
    end
    else
    begin
      vDec := DecodeUint64(vTest.Input);
      Assert.AreEqual(vTest.Want, vDec, 'Decode uint64 failed');
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(THexUtilTests);
end.
