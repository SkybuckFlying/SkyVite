unit Common.Bytes;

interface

uses
  System.SysUtils, GoToDelphi.Helpers.BigInt;

type
  TBytes = TArray<Byte>;

function Uint64ToBytes(ParaI: UInt64): TBytes;
function BytesToUint64(ParaB: TBytes): UInt64;
function BytesToBig(ParaData: TBytes): TBigInt;
function BigToBytes(ParaN: TBigInt): TBytes;
function LeftPadBytes(ParaSlice: TBytes; ParaL: Integer): TBytes;
function RightPadBytes(ParaSlice: TBytes; ParaL: Integer): TBytes;
function IsEqualBytes(ParaA, ParaB: TBytes): Boolean;

implementation

function Uint64ToBytes(ParaI: UInt64): TBytes;
var
  vBuf: TBytes;
begin
  try
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
  except
    on EOutOfMemory do
    begin
      // Handle memory allocation failure
      // Depending on the application's needs, you might log the error,
      // re-raise the exception, or return an empty array.
      Result := [];
    end;
  end;
end;

function BytesToUint64(ParaB: TBytes): UInt64;
begin
  if Length(ParaB) <> 8 then
  begin
    raise EArgumentException.Create('Input byte array must be 8 bytes long');
  end;

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
  vPadded: TBytes;
  vSliceLen: Integer;
begin
  vSliceLen := Length(ParaSlice);
  if ParaL < vSliceLen then
  begin
    Result := ParaSlice;
    Exit;
  end;

  try
    SetLength(vPadded, ParaL);
    System.Move(ParaSlice[0], vPadded[ParaL - vSliceLen], vSliceLen);
    Result := vPadded;
  except
    on EOutOfMemory do
    begin
      Result := [];
    end;
  end;
end;

function RightPadBytes(ParaSlice: TBytes; ParaL: Integer): TBytes;
var
  vPadded: TBytes;
begin
  if ParaL < Length(ParaSlice) then
  begin
    Result := ParaSlice;
    Exit;
  end;

  try
    SetLength(vPadded, ParaL);
    System.Move(ParaSlice[0], vPadded[0], Length(ParaSlice));
    Result := vPadded;
  except
    on EOutOfMemory do
    begin
      Result := [];
    end;
  end;
end;

function IsEqualBytes(ParaA, ParaB: TBytes): Boolean;
var
  vIndex: Integer;
begin
  if Length(ParaA) <> Length(ParaB) then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
  for vIndex := 0 to Length(ParaA) - 1 do
  begin
    if ParaA[vIndex] <> ParaB[vIndex] then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

end.
