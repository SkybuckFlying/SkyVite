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

unit Common.Math.Integer;

interface

uses
  System.SysUtils,
  Common.Bytes;

type
  // HexOrDecimal64 marshals uint64 as hex or decimal.
  THexOrDecimal64 = record
  private
    mValue: UInt64;
  public
    procedure UnmarshalText(const ParaInput: TBytes);
    function MarshalText: TBytes;
    class operator Implicit(const ParaValue: UInt64): THexOrDecimal64;
    class operator Implicit(const ParaValue: THexOrDecimal64): UInt64;
  end;

  TIntegerMath = class
  public
    // ParseUint64 parses s as an integer in decimal or hexadecimal syntax.
    class function ParseUint64(const ParaS: string; out ParaValue: UInt64): Boolean;
    // MustParseUint64 parses s as an integer and panics if the string is invalid.
    class function MustParseUint64(const ParaS: string): UInt64;
    // SafeSub returns subtraction result and whether overflow occurred.
    class function SafeSub(const ParaX, ParaY: UInt64; out ParaResult: UInt64): Boolean;
    // SafeAdd returns the result and whether overflow occurred.
    class function SafeAdd(const ParaX, ParaY: UInt64; out ParaResult: UInt64): Boolean;
    // SafeMul returns multiplication result and whether overflow occurred.
    class function SafeMul(const ParaX, ParaY: UInt64; out ParaResult: UInt64): Boolean;
    // SatSub returns x-y with saturation on underflow.
    class function SatSub(const ParaX, ParaY: UInt64): UInt64;
  end;

// Integer limit values.
const
  ConstMaxInt8 = 1 shl 7 - 1;
  ConstMinInt8 = -1 shl 7;
  ConstMaxInt16 = 1 shl 15 - 1;
  ConstMinInt16 = -1 shl 15;
  ConstMaxInt32 = 1 shl 31 - 1;
  ConstMinInt32 = -1 shl 31;
  ConstMaxInt64 = 1 shl 63 - 1;
  ConstMinInt64 = -1 shl 63;
  ConstMaxUint8 = 1 shl 8 - 1;
  ConstMaxUint16 = 1 shl 16 - 1;
  ConstMaxUint32 = 1 shl 32 - 1;
  ConstMaxUint64 = 1 shl 64 - 1;

implementation

uses
  System.StrUtils;

{ THexOrDecimal64 }

procedure THexOrDecimal64.UnmarshalText(const ParaInput: TBytes);
var
  vInt: UInt64;
  vOk: Boolean;
  vInputString: string;
begin
  try
    vInputString := TEncoding.UTF8.GetString(ParaInput);
    vOk := TIntegerMath.ParseUint64(vInputString, vInt);
    if not vOk then
    begin
      raise Exception.CreateFmt('invalid hex or decimal integer %s', [vInputString]);
    end;
    mValue := vInt;
  except
    on E: Exception do
    begin
      raise;
    end;
  end;
end;

function THexOrDecimal64.MarshalText: TBytes;
var
  vHex: string;
begin
  vHex := '0x' + IntToHex(mValue);
  Result := TEncoding.UTF8.GetBytes(vHex);
end;

class operator THexOrDecimal64.Implicit(const ParaValue: UInt64): THexOrDecimal64;
begin
  Result.mValue := ParaValue;
end;

class operator THexOrDecimal64.Implicit(const ParaValue: THexOrDecimal64): UInt64;
begin
  Result := ParaValue.mValue;
end;

{ TIntegerMath }

class function TIntegerMath.ParseUint64(const ParaS: string; out ParaValue: UInt64): Boolean;
var
  vHex: string;
begin
  Result := false;
  if ParaS = '' then
  begin
    ParaValue := 0;
    Result := true;
    Exit;
  end;

  if System.StrUtils.StartsWith(ParaS, '0x') or System.StrUtils.StartsWith(ParaS, '0X') then
  begin
    vHex := ParaS.Substring(2);
    Result := TryHexToUInt64(vHex, ParaValue);
  end
  else
  begin
    Result := TryStrToUInt64(ParaS, ParaValue);
  end;
end;

class function TIntegerMath.MustParseUint64(const ParaS: string): UInt64;
var
  vValue: UInt64;
  vOk: Boolean;
begin
  vOk := ParseUint64(ParaS, vValue);
  if not vOk then
  begin
    raise Exception.Create('invalid unsigned 64 bit integer: ' + ParaS);
  end;
  Result := vValue;
end;

class function TIntegerMath.SafeSub(const ParaX, ParaY: UInt64; out ParaResult: UInt64): Boolean;
begin
  Result := ParaX < ParaY;
  if Result then
  begin
    ParaResult := 0; // Or some other defined behavior for overflow
  end
  else
  begin
    ParaResult := ParaX - ParaY;
  end;
end;

class function TIntegerMath.SafeAdd(const ParaX, ParaY: UInt64; out ParaResult: UInt64): Boolean;
begin
  ParaResult := ParaX + ParaY;
  Result := ParaY > (ConstMaxUint64 - ParaX);
end;

class function TIntegerMath.SafeMul(const ParaX, ParaY: UInt64; out ParaResult: UInt64): Boolean;
begin
  if (ParaX = 0) or (ParaY = 0) then
  begin
    ParaResult := 0;
    Result := false;
    Exit;
  end;
  Result := ParaY > (ConstMaxUint64 div ParaX);
  if Result then
  begin
    ParaResult := 0; // Or some other defined behavior for overflow
  end
  else
  begin
    ParaResult := ParaX * ParaY;
  end;
end;

class function TIntegerMath.SatSub(const ParaX, ParaY: UInt64): UInt64;
begin
  if ParaX < ParaY then
  begin
    Result := 0;
  end
  else
  begin
    Result := ParaX - ParaY;
  end;
end;

end.