unit Common.Helper.Math.Big;

interface

uses
  System.SysUtils,
  GoToDelphi.Helpers.BigInt,
  Common.Helper.Common;

type
  TBigHelper = class
  private
    class function BigEndianByteAt(const ParaBigInt: TBigInt; ParaN: Integer): Byte;
  public
    class function BigPow(ParaA, ParaB: Int64): TBigInt;
    class procedure ReadBits(const ParaBigInt: TBigInt; var ParaBuf: TBytes);
    class function U256(ParaX: TBigInt): TBigInt;
    class function S256(ParaX: TBigInt): TBigInt;
    class function Exp(ParaBase, ParaExponent: TBigInt): TBigInt;
    class function Byte(const ParaBigInt: TBigInt; ParaPadLength, ParaN: Integer): Byte;
    class function PaddedBigBytes(const ParaBigInt: TBigInt; ParaN: Integer): TBytes;
    class function BigMin(const ParaX, ParaY: TBigInt): TBigInt;
    class function BigMax(const ParaX, ParaY: TBigInt): TBigInt;
  end;

implementation

uses
  System.Math;

{ TBigHelper }

// BigPow returns a ** b as a big integer.
class function TBigHelper.BigPow(ParaA, ParaB: Int64): TBigInt;
var
  vR: TBigInt;
begin
  vR := TBigInt.New(ParaA);
  Result := vR.Exp(vR, TBigInt.New(ParaB), nil);
end;

// ReadBits encodes the absolute amount of bigint as big-endian bytes. Callers must ensure
// that buf has enough space. If buf is too short the result will be incomplete.
class procedure TBigHelper.ReadBits(const ParaBigInt: TBigInt; var ParaBuf: TBytes);
var
  vI, vJ: Integer;
  vD: TBigWord;
begin
  vI := Length(ParaBuf);
  for vD in ParaBigInt.Bits do
  begin
    vJ := 0;
    while (vJ < WordBytes) and (vI > 0) do
    begin
      Dec(vI);
      ParaBuf[vI] := System.Byte(vD);
      vD := vD shr 8;
      Inc(vJ);
    end;
  end;
end;

// U256 encodes as a 256 bit two's complement number. This operation is destructive.
class function TBigHelper.U256(ParaX: TBigInt): TBigInt;
begin
  Result := ParaX.And(ParaX, Tt256m1);
end;

// S256 interprets x as a two's complement number.
// x must not exceed 256 bits (the result is undefined if it does) and is not modified.
//
//   S256(0)        = 0
//   S256(1)        = 1
//   S256(2**255)   = -2**255
//   S256(2**256-1) = -1
class function TBigHelper.S256(ParaX: TBigInt): TBigInt;
begin
  if ParaX.Cmp(Tt255) < 0 then
  begin
    Result := ParaX;
  end
  else
  begin
    Result := TBigInt.New.Sub(ParaX, Tt256);
  end;
end;

// Exp implements exponentiation by squaring.
// Exp returns a newly-allocated big integer and does not change
// base or exponent. The result is truncated to 256 bits.
class function TBigHelper.Exp(ParaBase, ParaExponent: TBigInt): TBigInt;
var
  vResult: TBigInt;
  vIndex: Integer;
  vWord: TBigWord;
begin
  vResult := TBigInt.New(1);
  for vWord in ParaExponent.Bits do
  begin
    for vIndex := 0 to WordBits - 1 do
    begin
      if (vWord and 1) = 1 then
      begin
        vResult := U256(vResult.Mul(vResult, ParaBase));
      end;
      ParaBase := U256(ParaBase.Mul(ParaBase, ParaBase));
      vWord := vWord shr 1;
    end;
  end;
  Result := vResult;
end;

// bigEndianByteAt returns the byte at position n,
// in Big-Endian encoding
// So n==0 returns the least significant byte
class function TBigHelper.BigEndianByteAt(const ParaBigInt: TBigInt; ParaN: Integer): Byte;
var
  vWords: TArray<TBigWord>;
  vIndex, vShift: Integer;
  vWord: TBigWord;
begin
  vWords := ParaBigInt.Bits;
  // Check word-bucket the byte will reside in
  vIndex := ParaN div WordBytes;
  if vIndex >= Length(vWords) then
  begin
    Result := System.Byte(0);
  end
  else
  begin
    vWord := vWords[vIndex];
    // Offset of the byte
    vShift := 8 * (ParaN mod WordBytes);
    Result := System.Byte(vWord shr vShift);
  end;
end;

// Byte returns the byte at position n,
// with the supplied padlength in Little-Endian encoding.
// n==0 returns the MSB
// Example: bigint '5', padlength 32, n=31 => 5
class function TBigHelper.Byte(const ParaBigInt: TBigInt; ParaPadLength, ParaN: Integer): Byte;
begin
  if ParaN >= ParaPadLength then
  begin
    Result := System.Byte(0);
  end
  else
  begin
    Result := BigEndianByteAt(ParaBigInt, ParaPadLength - 1 - ParaN);
  end;
end;

// PaddedBigBytes encodes a big integer as a big-endian byte slice. The length
// of the slice is at least n bytes.
class function TBigHelper.PaddedBigBytes(const ParaBigInt: TBigInt; ParaN: Integer): TBytes;
begin
  if (ParaBigInt.BitLen div 8) >= ParaN then
  begin
    Result := ParaBigInt.Bytes;
  end
  else
  begin
    SetLength(Result, ParaN);
    ReadBits(ParaBigInt, Result);
  end;
end;

// BigMin returns the smaller of x or y.
class function TBigHelper.BigMin(const ParaX, ParaY: TBigInt): TBigInt;
begin
  if ParaX.Cmp(ParaY) > 0 then
  begin
    Result := ParaY;
  end
  else
  begin
    Result := ParaX;
  end;
end;

// BigMax returns the larger of x or y.
class function TBigHelper.BigMax(const ParaX, ParaY: TBigInt): TBigInt;
begin
  if ParaX.Cmp(ParaY) < 0 then
  begin
    Result := ParaY;
  end
  else
  begin
    Result := ParaX;
  end;
end;

end.
