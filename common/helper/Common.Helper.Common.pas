unit Common.Helper.Common;

interface

uses
  System.SysUtils, System.Math.BigInt;

const
  MaxUint64 = High(UInt64);

var
  Big0: TBigInteger;
  Big1: TBigInteger;
  Big2: TBigInteger;
  Big10: TBigInteger;
  Big31: TBigInteger;
  Big32: TBigInteger;
  Big50: TBigInteger;
  Big100: TBigInteger;
  Big256: TBigInteger;
  Big257: TBigInteger;
  Tt255: TBigInteger;
  Tt256: TBigInteger;
  Tt256m1: TBigInteger;

function ToWordSize(ParaSize: UInt64): UInt64;
function BigUint64(const ParaV: TBigInteger; out ParaOverflow: Boolean): UInt64;
function RightPadBytes(const ParaSlice: TBytes; ParaL: Integer): TBytes;
function LeftPadBytes(const ParaSlice: TBytes; ParaL: Integer): TBytes;
function LDI(const ParaSlice: TBytes): TBytes;
function GetDataBig(const ParaData: TBytes; const ParaStart, ParaSize: TBigInteger): TBytes;
function BytesToString(const ParaData: TBytes): string;
function HexToBytes(const ParaStr: string): TBytes;
function AllZero(const ParaB: TBytes): Boolean;
function JoinBytes(const ParaData: array of TBytes): TBytes;
function BytesToU64(const ParaData: TBytes): UInt64;
function IsNil(const ParaI: IInterface): Boolean;
procedure AssertNil(const ParaI: IInterface);

implementation

uses
  System.Net.Sockets, System.StrUtils, IdGlobal;

function ToWordSize(ParaSize: UInt64): UInt64;
const
  WordSize = 32;
begin
  if ParaSize > MaxUint64 - WordSize + 1 then
    Result := MaxUint64 div WordSize + 1
  else
    Result := (ParaSize + WordSize - 1) div WordSize;
end;

function BigUint64(const ParaV: TBigInteger; out ParaOverflow: Boolean): UInt64;
begin
  ParaOverflow := ParaV.BitLength > 64;
  Result := ParaV.ToUInt64;
end;

function RightPadBytes(const ParaSlice: TBytes; ParaL: Integer): TBytes;
var
  vPadded: TBytes;
begin
  if ParaL <= Length(ParaSlice) then
    Result := ParaSlice
  else
  begin
    SetLength(vPadded, ParaL);
    System.Move(ParaSlice[0], vPadded[0], Length(ParaSlice));
    Result := vPadded;
  end;
end;

function LeftPadBytes(const ParaSlice: TBytes; ParaL: Integer): TBytes;
var
  vPadded: TBytes;
begin
  if ParaL <= Length(ParaSlice) then
    Result := ParaSlice
  else
  begin
    SetLength(vPadded, ParaL);
    System.Move(ParaSlice[0], vPadded[ParaL - Length(ParaSlice)], Length(ParaSlice));
    Result := vPadded;
  end;
end;

function LDI(const ParaSlice: TBytes): TBytes;
var
  vI: Integer;
begin
  SetLength(Result, Length(ParaSlice));
  for vI := 0 to High(ParaSlice) do
    Result[vI] := not ParaSlice[vI];
end;

function GetDataBig(const ParaData: TBytes; const ParaStart, ParaSize: TBigInteger): TBytes;
var
  vDLen: TBigInteger;
  vS, vE: TBigInteger;
begin
  vDLen := TBigInteger.Create(Length(ParaData));
  vS := TBigInteger.Min(ParaStart, vDLen);
  vE := TBigInteger.Min(vS + ParaSize, vDLen);
  Result := RightPadBytes(Copy(ParaData, vS.ToInteger, vE.ToInteger - vS.ToInteger), ParaSize.ToInteger);
end;

function BytesToString(const ParaData: TBytes): string;
var
  vI: Integer;
begin
  for vI := 0 to High(ParaData) do
  begin
    if ParaData[vI] = 0 then
    begin
      Result := TEncoding.UTF8.GetString(ParaData, 0, vI);
      Exit;
    end;
  end;
  Result := TEncoding.UTF8.GetString(ParaData);
end;

function HexToBytes(const ParaStr: string): TBytes;
begin
  Result := IndyHexToBytes(ParaStr);
end;

function AllZero(const ParaB: TBytes): Boolean;
var
  vByte: Byte;
begin
  for vByte in ParaB do
  begin
    if vByte <> 0 then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

function JoinBytes(const ParaData: array of TBytes): TBytes;
var
  vD: TBytes;
  vLen: Integer;
  vI: Integer;
begin
  vLen := 0;
  for vD in ParaData do
    Inc(vLen, Length(vD));
  SetLength(Result, vLen);
  vI := 0;
  for vD in ParaData do
  begin
    System.Move(vD[0], Result[vI], Length(vD));
    Inc(vI, Length(vD));
  end;
end;

function BytesToU64(const ParaData: TBytes): UInt64;
begin
  if Length(ParaData) < 8 then
    Result := 0
  else
    Result := TNetEncoding.BigEndian.ToUInt64(ParaData, 0);
end;

function IsNil(const ParaI: IInterface): Boolean;
begin
  Result := ParaI = nil;
end;

procedure AssertNil(const ParaI: IInterface);
begin
  if ParaI <> nil then
    raise Exception.Create('Not nil');
end;

initialization
  Big0 := TBigInteger.Create(0);
  Big1 := TBigInteger.Create(1);
  Big2 := TBigInteger.Create(2);
  Big10 := TBigInteger.Create(10);
  Big31 := TBigInteger.Create(31);
  Big32 := TBigInteger.Create(32);
  Big50 := TBigInteger.Create(50);
  Big100 := TBigInteger.Create(100);
  Big256 := TBigInteger.Create(256);
  Big257 := TBigInteger.Create(257);
  Tt255 := TBigInteger.Power(2, 255);
  Tt256 := TBigInteger.Power(2, 256);
  Tt256m1 := Tt256 - Big1;
finalization
  Big0 := nil;
  Big1 := nil;
  Big2 := nil;
  Big10 := nil;
  Big31 := nil;
  Big32 := nil;
  Big50 := nil;
  Big100 := nil;
  Big256 := nil;
  Big257 := nil;
  Tt255 := nil;
  Tt256 := nil;
  Tt256m1 := nil;
end.