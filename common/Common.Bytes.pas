unit Common.Bytes;

interface

uses
  Common.Bytes.Test,
  Common.Condtimeout,
  Common.Condtimeout.Test,
  Common.Condtimer,
  Common.Condtimer.Test,
  Common.Default.Params,
  Common.GoRoutine,
  Common.GoRoutine.Test,
  Common.Lifecycle,
  Common.Lock,
  Common.Lock.Test,
  Common.Log,
  Common.Mock,
  Common.Mock.Test,
  Common.Utils,
  Common.Version,
  System.SysUtils System.Classes Common.BigInt;

type
  TBytes = TArray<Byte>;

function Uint64ToBytes(ParaI: UInt64): TBytes;
function BytesToUint64(ParaB: TBytes): UInt64;
function BytesToBig(ParaData: TBytes): TBigInt;
function BigToBytes(ParaN: TBigInt): TBytes;
function LeftPadBytes(ParaSlice: TBytes; ParaL: Integer): TBytes;
function RightPadBytes(ParaSlice: TBytes; ParaL: Integer): TBytes;
function IsEqualBytes(ParaA, ParaB: TBytes): Boolean;

function ToHex(b: TBytes): string;
function FromHex(s: string): TBytes;
function CopyBytes(b: TBytes): TBytes;
function HasHexPrefix(str: string): Boolean;
function IsHexCharacter(c: Byte): Boolean;
function IsHex(str: string): Boolean;
function Bytes2Hex(d: TBytes): string;
function Hex2Bytes(str: string): TBytes;
function Hex2BytesFixed(str: string; flen: Integer): TBytes;

implementation

function Uint64ToBytes(ParaI: UInt64): TBytes;
var
  vBuf: TBytes;
begin
  SetLength(vBuf, 8);
  vBuf[0] := Byte(ParaI shr 56);
  vBuf[1] := Byte(ParaI shr 48);
  vBuf[2] := Byte(ParaI shr 40);
  vBuf[3] := Byte(ParaI shr 32);
  vBuf[4] := Byte(ParaI shr 24);
  vBuf[5] := Byte(ParaI shr 16);
  vBuf[6] := Byte(ParaI shr 8);
  vBuf[7] := Byte(ParaI);
  Result := vBuf;
end;

function BytesToUint64(ParaB: TBytes): UInt64;
begin
  if Length(ParaB) <> 8 then
    raise EArgumentException.Create('Input byte array must be 8 bytes long');

  Result := (UInt64(ParaB[0]) shl 56) or
            (UInt64(ParaB[1]) shl 48) or
            (UInt64(ParaB[2]) shl 40) or
            (UInt64(ParaB[3]) shl 32) or
            (UInt64(ParaB[4]) shl 24) or
            (UInt64(ParaB[5]) shl 16) or
            (UInt64(ParaB[6]) shl 8) or
            UInt64(ParaB[7]);
end;

function BytesToBig(ParaData: TBytes): TBigInt;
begin
  Result := TBigInt.FromBytes(ParaData);
end;

function BigToBytes(ParaN: TBigInt): TBytes;
begin
  Result := ParaN.ToBytes;
end;

function LeftPadBytes(ParaSlice: TBytes; ParaL: Integer): TBytes;
var
  vSliceLen: Integer;
begin
  vSliceLen := Length(ParaSlice);
  if ParaL <= vSliceLen then
    Exit(ParaSlice);

  SetLength(Result, ParaL);
  if vSliceLen > 0 then
    Move(ParaSlice[0], Result[ParaL - vSliceLen], vSliceLen);
end;

function RightPadBytes(ParaSlice: TBytes; ParaL: Integer): TBytes;
begin
  if ParaL <= Length(ParaSlice) then
    Exit(ParaSlice);

  SetLength(Result, ParaL);
  if Length(ParaSlice) > 0 then
    Move(ParaSlice[0], Result[0], Length(ParaSlice));
end;

function IsEqualBytes(ParaA, ParaB: TBytes): Boolean;
var
  i: Integer;
begin
  if Length(ParaA) <> Length(ParaB) then
    Exit(False);
  for i := 0 to High(ParaA) do
    if ParaA[i] <> ParaB[i] then
      Exit(False);
  Result := True;
end;

function Bytes2Hex(d: TBytes): string;
begin
  if Length(d) = 0 then
    Exit('');
  SetLength(Result, Length(d) * 2);
  BinToHex(d[0], PChar(Result), Length(d));
end;

function ToHex(b: TBytes): string;
var
  hex: string;
begin
  hex := Bytes2Hex(b);
  if Length(hex) = 0 then
    hex := '0';
  Result := '0x' + hex;
end;

function Hex2Bytes(str: string): TBytes;
begin
  if Length(str) mod 2 <> 0 then
    str := '0' + str;
  SetLength(Result, Length(str) div 2);
  if Length(Result) > 0 then
    HexToBin(PChar(str), Result[0], Length(Result));
end;

function FromHex(s: string): TBytes;
begin
  if (Length(s) > 1) and ((s[1] = '0') and ((s[2] = 'x') or (s[2] = 'X'))) then
    s := Copy(s, 3, Length(s));
  Result := Hex2Bytes(s);
end;

function CopyBytes(b: TBytes): TBytes;
begin
  Result := Copy(b);
end;

function HasHexPrefix(str: string): Boolean;
begin
  Result := (Length(str) >= 2) and (str[1] = '0') and ((str[2] = 'x') or (str[2] = 'X'));
end;

function IsHexCharacter(c: Byte): Boolean;
begin
  Result := ((c >= Ord('0')) and (c <= Ord('9'))) or
            ((c >= Ord('a')) and (c <= Ord('f'))) or
            ((c >= Ord('A')) and (c <= Ord('F')));
end;

function IsHex(str: string): Boolean;
var
  c: Char;
begin
  if Length(str) mod 2 <> 0 then
    Exit(False);
  for c in str do
    if not IsHexCharacter(Ord(c)) then
      Exit(False);
  Result := True;
end;

function Hex2BytesFixed(str: string; flen: Integer): TBytes;
var
  h: TBytes;
begin
  h := Hex2Bytes(str);
  if Length(h) = flen then
    Exit(h);
  
  if Length(h) > flen then
  begin
    Result := Copy(h, Length(h) - flen, flen); // 0-indexed? Copy takes index, count.
    // Copy(Arr, Index, Count). Index is 0-based for dyn array?
    // Wait, System.Copy for dyn array: Index is starting element index.
    // h[Length(h)-flen] is the start.
    Exit;
  end;

  SetLength(Result, flen);
  if Length(h) > 0 then
    Move(h[0], Result[flen - Length(h)], Length(h));
end;

end.
