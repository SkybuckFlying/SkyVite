unit Common.Bloom.Util;

interface

uses
  System.SysUtils,
  GoToDelphi.Helpers.FNV;

/*
 * Copyright 2019 The go-vite Authors
 * This file is part of the go-vite library.
 *
 * The go-vite library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The go-vite library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the go-vite library. If not, see <http://www.gnu.org/licenses/>.
 */

function OptimalM( ParaN : Cardinal; ParaFPRate : Double ): Cardinal;
function OptimalK( ParaFPRate : Double ): Cardinal;
procedure HashInternal( ParaData : TBytes; ParaHash : IHash64; out ParaLower, ParaUpper: Cardinal );

implementation

uses
  System.Math;

const
  ConstFillRatio = 0.5;

var
  vFillRatioX: Double = 0;

// OptimalM calculates the optimal Bloom filter size, m, based on the number of
// items and the desired rate of false positives.
function OptimalM( ParaN : Cardinal; ParaFPRate : Double ): Cardinal;
var
  vBase: Double;
  vR: Double;
begin
  if vFillRatioX = 0 then
  begin
    vFillRatioX := System.Math.Ln(ConstFillRatio) * System.Math.Ln(1 - ConstFillRatio);
  end;

  vBase := System.Math.Abs(System.Math.Ln(ParaFPRate)) / vFillRatioX;
  vR := ParaN * vBase;
  Result := Ceil(vR);
end;

// OptimalK calculates the optimal number of hash functions to use for a Bloom
// filter based on the desired rate of false positives.
function OptimalK( ParaFPRate : Double ): Cardinal;
begin
  Result := Ceil(System.Math.Log2(1 / ParaFPRate));
end;

// hashInternal returns the upper and lower base hash values from which the k
// hashes are derived.
procedure HashInternal( ParaData : TBytes; ParaHash : IHash64; out ParaLower, ParaUpper: Cardinal );
var
  vSumBytes: TBytes;
begin
  ParaHash.Write(ParaData);
  vSumBytes := ParaHash.Sum([]); // Pass empty TBytes to get only the hash result
  ParaHash.Reset;

  // Equivalent to binary.BigEndian.Uint32(sum[4:8]) and sum[0:4])
  if Length(vSumBytes) >= 8 then
  begin
    ParaLower := (Cardinal(vSumBytes[4]) shl 24) or
                 (Cardinal(vSumBytes[5]) shl 16) or
                 (Cardinal(vSumBytes[6]) shl 8) or
                 Cardinal(vSumBytes[7]);

    ParaUpper := (Cardinal(vSumBytes[0]) shl 24) or
                 (Cardinal(vSumBytes[1]) shl 16) or
                 (Cardinal(vSumBytes[2]) shl 8) or
                 Cardinal(vSumBytes[3]);
  end
  else
  begin
    ParaLower := 0;
    ParaUpper := 0;
  end;
end;

end.
