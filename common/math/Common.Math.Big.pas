// Copyright 2017 The go-ethereum Authors
// This file is part of the go-ethereum library.
//
// The go-ethereum library is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// The go-ethereum library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with the go-ethereum library. If not, see <http://www.gnu.org/licenses/>.

unit Common.Math.Big;

interface

uses
  Common.Bytes,
  Common.Math.Big.Test,
  Common.Math.Integer,
  Common.Math.Integer.Test,
  System.Math.BigInts,
  System.SysUtils;

type
  TBytes = TArray<Byte>;

  // HexOrDecimal256 marshals big.Int as hex or decimal.
  THexOrDecimal256 = record
  private
    mValue: TBigInteger;
  public
    procedure UnmarshalText(const ParaInput: TBytes);
    function MarshalText: TBytes;
    class operator Implicit(const ParaValue: TBigInteger): THexOrDecimal256;
    class operator Implicit(const ParaValue: THexOrDecimal256): TBigInteger;
  end;

  TBigMath = class
  public
    // ParseBig256 parses s as a 256 bit integer in decimal or hexadecimal syntax.
    class function ParseBig256(const ParaS: string): TBigInteger;
    // MustParseBig256 parses s as a 256 bit big integer and panics if the string is invalid.
    class function MustParseBig256(const ParaS: string): TBigInteger;
    // BigPow returns a ** b as a big integer.
    class function BigPow(const ParaA, ParaB: Int64): TBigInteger;
    // BigMax returns the larger of x or y.
    class function BigMax(const ParaX, ParaY: TBigInteger): TBigInteger;
    // BigMin returns the smaller of x or y.
    class function BigMin(const ParaX, ParaY: TBigInteger): TBigInteger;
    // FirstBitSet returns the index of the first 1 bit in v, counting from LSB.
    class function FirstBitSet(const ParaV: TBigInteger): Integer;
    // PaddedBigBytes encodes a big integer as a big-endian byte slice.
    class function PaddedBigBytes(const ParaBigint: TBigInteger; const ParaN: Integer): TBytes;
    // Byte returns the byte at position n, with the supplied padlength in Little-Endian encoding.
    class function Byte(const ParaBigint: TBigInteger; const ParaPadLength, ParaN: Integer): System.Byte;
    // ReadBits encodes the absolute value of bigint as big-endian bytes.
    class procedure ReadBits(const ParaBigint: TBigInteger; var ParaBuf: TBytes);
    // U256 encodes as a 256 bit two's complement number.
    class function U256(const ParaX: TBigInteger): TBigInteger;
    // S256 interprets x as a two's complement number.
    class function S256(const ParaX: TBigInteger): TBigInteger;
    // Exp implements exponentiation by squaring.
    class function Exp(ParaBase, ParaExponent: TBigInteger): TBigInteger;
  end;

var
  ConstWordBits: Integer;
  ConstWordBytes: Integer;
  ConstMaxBigIntLen: Integer;

  tt255, tt256, tt256m1, tt63, MaxBig256, MaxBig63: TBigInteger;

  // Below are some famous big integer values.
  Big0, Big1, Big2, Big3, Big4, Big5, Big8, Big10, Big32, Big256: TBigInteger;

implementation

uses
  System.StrUtils, System.BigNumbers;

// bigEndianByteAt returns the byte at position n,
// in Big-Endian encoding
// So n==0 returns the least significant byte
function bigEndianByteAt(const ParaBigint: TBigInteger; const ParaN: Integer): byte;
var
  vBytes: TBytes;
  vIndex: Integer;
begin
  vBytes := ParaBigint.ToByteArray; // Big-endian
  vIndex := Length(vBytes) - 1 - ParaN;
  if (vIndex < 0) or (vIndex >= Length(vBytes)) then
  begin
    Result := 0;
  end
  else
  begin
    Result := vBytes[vIndex];
  end;
end;

{ THexOrDecimal256 }

procedure THexOrDecimal256.UnmarshalText(const ParaInput: TBytes);
var
  vBigint: TBigInteger;
  vInputString: string;
begin
  try
    vInputString := TEncoding.UTF8.GetString(ParaInput);
    vBigint := TBigMath.ParseBig256(vInputString);
    if vBigint = nil then
    begin
      raise Exception.CreateFmt('invalid hex or decimal integer %s', [vInputString]);
    end;
    mValue := vBigint;
  except
    on E: Exception do
    begin
      // Handle or re-raise exception
      raise;
    end;
  end;
end;

function THexOrDecimal256.MarshalText: TBytes;
var
  vHex: string;
begin
  if mValue = nil then
  begin
    Result := TEncoding.UTF8.GetBytes('0x0');
  end
  else
  begin
    vHex := '0x' + mValue.ToHexString;
    Result := TEncoding.UTF8.GetBytes(vHex);
  end;
end;

class operator THexOrDecimal256.Implicit(const ParaValue: TBigInteger): THexOrDecimal256;
begin
  Result.mValue := ParaValue;
end;

class operator THexOrDecimal256.Implicit(const ParaValue: THexOrDecimal256): TBigInteger;
begin
  Result := ParaValue.mValue;
end;

{ TBigMath }

class function TBigMath.ParseBig256(const ParaS: string): TBigInteger;
var
  vBigint: TBigInteger;
  vOk: Boolean;
begin
  if ParaS = '' then
  begin
    Result := Big0;
    Exit;
  end;

  if System.StrUtils.StartsWith(ParaS, '0x') or System.StrUtils.StartsWith(ParaS, '0X') then
  begin
    vOk := TBigInteger.TryParse(ParaS.Substring(2), 16, vBigint);
  end
  else
  begin
    vOk := TBigInteger.TryParse(ParaS, 10, vBigint);
  end;

  if vOk and (vBigint.GetBitLength > 256) then
  begin
    Result := nil;
  end
  else if not vOk then
  begin
    Result := nil;
  end
  else
  begin
    Result := vBigint;
  end;
end;

class function TBigMath.MustParseBig256(const ParaS: string): TBigInteger;
var
  vValue: TBigInteger;
begin
  vValue := ParseBig256(ParaS);
  if vValue = nil then
  begin
    raise Exception.Create('invalid 256 bit integer: ' + ParaS);
  end;
  Result := vValue;
end;

class function TBigMath.BigPow(const ParaA, ParaB: Int64): TBigInteger;
var
  vA, vB: TBigInteger;
begin
  vA := ParaA;
  vB := ParaB;
  Result := TBigInteger.Pow(vA, vB.ToUInt64);
end;

class function TBigMath.BigMax(const ParaX, ParaY: TBigInteger): TBigInteger;
begin
  if ParaX.CompareTo(ParaY) < 0 then
  begin
    Result := ParaY;
  end
  else
  begin
    Result := ParaX;
  end;
end;

class function TBigMath.BigMin(const ParaX, ParaY: TBigInteger): TBigInteger;
begin
  if ParaX.CompareTo(ParaY) > 0 then
  begin
    Result := ParaY;
  end
  else
  begin
    Result := ParaX;
  end;
end;

class function TBigMath.FirstBitSet(const ParaV: TBigInteger): Integer;
var
  vIndex: Integer;
begin
  Result := ParaV.GetBitLength;
  for vIndex := 0 to ParaV.GetBitLength - 1 do
  begin
    if ParaV.TestBit(vIndex) then
    begin
      Result := vIndex;
      Exit;
    end;
  end;
end;

class function TBigMath.PaddedBigBytes(const ParaBigint: TBigInteger; const ParaN: Integer): TBytes;
var
  vBytes: TBytes;
begin
  if (ParaBigint.GetBitLength div 8) >= ParaN then
  begin
    Result := ParaBigint.ToByteArray;
    Exit;
  end;
  try
    SetLength(Result, ParaN);
    ReadBits(ParaBigint, Result);
  except
    on EOutOfMemory do
    begin
      // Handle exception
      Result := nil;
    end;
  end;
end;

class function TBigMath.Byte(const ParaBigint: TBigInteger; const ParaPadLength, ParaN: Integer): System.Byte;
begin
  if ParaN >= ParaPadLength then
  begin
    Result := 0;
  end
  else
  begin
    Result := bigEndianByteAt(ParaBigint, ParaPadLength - 1 - ParaN);
  end;
end;

class procedure TBigMath.ReadBits(const ParaBigint: TBigInteger; var ParaBuf: TBytes);
var
  vBytes: TBytes;
  vLen, vOffset: Integer;
begin
  vBytes := ParaBigint.ToByteArray; // Big-endian bytes
  vLen := Length(vBytes);
  vOffset := Length(ParaBuf) - vLen;

  // Clear the buffer
  FillChar(ParaBuf[0], Length(ParaBuf), 0);

  if vLen > 0 then
  begin
    System.Move(vBytes[0], ParaBuf[vOffset], vLen);
  end;
end;

class function TBigMath.U256(const ParaX: TBigInteger): TBigInteger;
begin
  Result := ParaX and tt256m1;
end;

// S256 interprets x as a two's complement number.
// x must not exceed 256 bits (the result is undefined if it does) and is not modified.
//
//   S256(0)        = 0
//   S256(1)        = 1
//   S256(2**255)   = -2**255
//   S256(2**256-1) = -1
class function TBigMath.S256(const ParaX: TBigInteger): TBigInteger;
begin
  if ParaX.CompareTo(tt255) < 0 then
  begin
    Result := ParaX;
  end
  else
  begin
    Result := ParaX - tt256;
  end;
end;

// Exp implements exponentiation by squaring.
// Exp returns a newly-allocated big integer and does not change
// base or exponent. The result is truncated to 256 bits.
class function TBigMath.Exp(ParaBase, ParaExponent: TBigInteger): TBigInteger;
var
  vResult: TBigInteger;
  vBaseCopy, vExponentCopy: TBigInteger;
  vIndex: Integer;
begin
  vResult := Big1;
  vBaseCopy := ParaBase;
  vExponentCopy := ParaExponent;

  for vIndex := 0 to vExponentCopy.GetBitLength do
  begin
    if vExponentCopy.TestBit(0) then
    begin
      vResult := U256(vResult * vBaseCopy);
    end;
    vBaseCopy := U256(vBaseCopy * vBaseCopy);
    vExponentCopy := vExponentCopy shr 1;
    if vExponentCopy.IsZero then
    begin
      break;
    end;
  end;
  Result := vResult;
end;

initialization
  ConstWordBits := 32; // Assuming 32-bit words for compatibility
  ConstWordBytes := ConstWordBits div 8;
  ConstMaxBigIntLen := 256;

  tt255 := TBigMath.BigPow(2, 255);
  tt256 := TBigMath.BigPow(2, 256);
  tt256m1 := tt256 - TBigInteger.One;
  tt63 := TBigMath.BigPow(2, 63);
  MaxBig256 := tt256m1;
  MaxBig63 := tt63 - TBigInteger.One;

  Big0 := 0;
  Big1 := 1;
  Big2 := 2;
  Big3 := 3;
  Big4 := 4;
  Big5 := 5;
  Big8 := 8;
  Big10 := 10;
  Big32 := 32;
  Big256 := 256;
end.
