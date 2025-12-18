unit Pow.Pow;

interface

uses
  Common.Helper,
  Common.Types,
  Crypto,
  Pow.Pow.Test,
  System.Classes,
  System.Math.BigInt,
  System.SysUtils;

const
  ConstFullThreshold = $FFFFFFFFFFFFFFFF;

var
  gDefaultTarget: TBigInteger;
  gVMTestParamEnabled: Boolean;

procedure Init(const ParaVMTestParamEnabled: Boolean);
function GetPowNonce(const ParaDifficulty: TBigInteger; const ParaDataHash: THash; out ParaNonce: TBytes): Boolean;
function MapPowNonce(const ParaDifficulty: TBigInteger; const ParaDataHash: THash; const ParaFromValue, ParaToValue: UInt64; out ParaNonce: TBytes; out ParaNonceValue: UInt64): Boolean;
function MapPowNonce2(const ParaDifficulty: TBigInteger; const ParaDataHash: THash; const ParaLen: UInt64; out ParaNonce: TBytes; out ParaNonceValue: UInt64): Boolean;
function CheckPowNonce(const ParaDifficulty: TBigInteger; const ParaNonce: TBytes; const ParaData: TBytes): Boolean;
function QuickInc(var ParaX: TBytes): TBytes;
function QuickGreater(const ParaX, ParaY: TBytes): Boolean;
function Uint64ToByteArray(const ParaI: UInt64): TBytes;
function DifficultyToTarget(const ParaDifficulty: TBigInteger): TBigInteger;
function TargetToDifficulty(const ParaTarget: TBigInteger): TBigInteger;

implementation

uses
  System.Hash,
  System.DateUtils,
  GoToDelphi.Helpers.BigInt;

procedure Init(const ParaVMTestParamEnabled: Boolean);
begin
  gVMTestParamEnabled := ParaVMTestParamEnabled;
end;

function PowHash256(const ParaNonce, ParaData: TBytes): TBytes;
var
  vHash: IHasher;
begin
  vHash := THashBlake2b.Create(256);
  vHash.Write(ParaNonce);
  vHash.Write(ParaData);
  Result := vHash.Sum(nil);
end;

function PowHash256FromHash(const ParaHash: IHasher; const ParaNonce, ParaData: TBytes): TBytes;
begin
  ParaHash.Write(ParaNonce);
  ParaHash.Write(ParaData);
  Result := ParaHash.Sum(nil);
end;

function GetPowNonce(const ParaDifficulty: TBigInteger; const ParaDataHash: THash; out ParaNonce: TBytes): Boolean;
var
  vTarget: TBigInteger;
  vData: TBytes;
  vTarget256: TBytes;
  vIndex: Integer;
  vTime: TDateTime;
  vOut: TBytes;
begin
  Result := False;
  if gVMTestParamEnabled then
  begin
    vTarget := gDefaultTarget;
  end
  else
  begin
    if ParaDifficulty.IsZero then
    begin
      raise Exception.Create('difficulty can''t be nil');
    end;
    vTarget := DifficultyToTarget(ParaDifficulty);
    if vTarget.IsZero or (vTarget.BitCount > 256) then
    begin
      raise Exception.Create('target too long');
    end;
  end;

  vData := ParaDataHash.Bytes;
  vTarget256 := LeftPadBytes(vTarget.ToBytes, 32);
  vIndex := 0;
  vTime := Now;
  while True do
  begin
    ParaNonce := GetEntropyCSPRNG(8);
    vOut := PowHash256(ParaNonce, vData);
    if QuickGreater(vOut, vTarget256) then
    begin
      Result := True;
      Exit;
    end;
    Inc(vIndex);
    if vIndex > 10000 then
    begin
      if MinutesBetween(Now, vTime) > 10 then
      begin
        Break;
      end;
      vIndex := 0;
    end;
  end;
end;

function MapPowNonce(const ParaDifficulty: TBigInteger; const ParaDataHash: THash; const ParaFromValue, ParaToValue: UInt64; out ParaNonce: TBytes; out ParaNonceValue: UInt64): Boolean;
var
  vTarget: TBigInteger;
  vData: TBytes;
  vTarget256: TBytes;
  vTime: TDateTime;
  vIndex: Integer;
  vHash: IHasher;
  vOut: TBytes;
  vFrom: UInt64;
begin
  Result := False;
  if gVMTestParamEnabled then
  begin
    vTarget := gDefaultTarget;
  end
  else
  begin
    if ParaDifficulty.IsZero then
    begin
      raise Exception.Create('difficulty can''t be nil');
    end;
    vTarget := DifficultyToTarget(ParaDifficulty);
    if vTarget.IsZero or (vTarget.BitCount > 256) then
    begin
      raise Exception.Create('target too long');
    end;
  end;

  vData := ParaDataHash.Bytes;
  vTarget256 := LeftPadBytes(vTarget.ToBytes, 32);
  vTime := Now;
  vIndex := 0;
  SetLength(ParaNonce, 8);
  vHash := THashBlake2b.Create(256);
  vFrom := ParaFromValue;
  while vFrom < ParaToValue do
  begin
    TEncoding.BigEndian.PutUInt64(ParaNonce, vFrom);
    vOut := PowHash256FromHash(vHash, ParaNonce, vData);
    if QuickGreater(vOut, vTarget256) then
    begin
      ParaNonceValue := vFrom;
      Result := True;
      Exit;
    end;
    vHash.Reset;
    Inc(vFrom);
    if vIndex > 100000 then
    begin
      if MinutesBetween(Now, vTime) > 10 then
      begin
        Break;
      end;
      vIndex := 0;
    end;
  end;
end;

function MapPowNonce2(const ParaDifficulty: TBigInteger; const ParaDataHash: THash; const ParaLen: UInt64; out ParaNonce: TBytes; out ParaNonceValue: UInt64): Boolean;
var
  vTarget: TBigInteger;
  vData: TBytes;
  vTarget256: TBytes;
  vTime: TDateTime;
  vIndex: Integer;
  vHash: IHasher;
  vI: UInt64;
  vOut: TBytes;
begin
  Result := False;
  if gVMTestParamEnabled then
  begin
    vTarget := gDefaultTarget;
  end
  else
  begin
    if ParaDifficulty.IsZero then
    begin
      raise Exception.Create('difficulty can''t be nil');
    end;
    vTarget := DifficultyToTarget(ParaDifficulty);
    if vTarget.IsZero or (vTarget.BitCount > 256) then
    begin
      raise Exception.Create('target too long');
    end;
  end;

  vData := ParaDataHash.Bytes;
  vTarget256 := LeftPadBytes(vTarget.ToBytes, 32);
  vTime := Now;
  vIndex := 0;
  vHash := THashBlake2b.Create(256);
  vI := 0;
  while vI < ParaLen do
  begin
    ParaNonce := GetEntropyCSPRNG(8);
    vOut := PowHash256FromHash(vHash, ParaNonce, vData);
    if QuickGreater(vOut, vTarget256) then
    begin
      ParaNonceValue := vI;
      Result := True;
      Exit;
    end;
    vHash.Reset;
    Inc(vI);
    if vIndex > 100000 then
    begin
      if MinutesBetween(Now, vTime) > 10 then
      begin
        Break;
      end;
      vIndex := 0;
    end;
  end;
end;

function CheckPowNonce(const ParaDifficulty: TBigInteger; const ParaNonce: TBytes; const ParaData: TBytes): Boolean;
var
  vTarget: TBigInteger;
  vOut: TBytes;
begin
  if gVMTestParamEnabled then
  begin
    vTarget := gDefaultTarget;
  end
  else
  begin
    vTarget := DifficultyToTarget(ParaDifficulty);
    if vTarget.IsZero or (vTarget.BitCount > 256) then
    begin
      Result := False;
      Exit;
    end;
  end;
  vOut := PowHash256(ParaNonce, ParaData);
  Result := QuickGreater(vOut, LeftPadBytes(vTarget.ToBytes, 32));
end;

function QuickInc(var ParaX: TBytes): TBytes;
var
  vIndex: Integer;
begin
  for vIndex := 1 to Length(ParaX) do
  begin
    ParaX[Length(ParaX) - vIndex] := ParaX[Length(ParaX) - vIndex] + 1;
    if ParaX[Length(ParaX) - vIndex] <> 0 then
    begin
      Result := ParaX;
      Exit;
    end;
  end;
  Result := ParaX;
end;

function QuickGreater(const ParaX, ParaY: TBytes): Boolean;
var
  vIndex: Integer;
begin
  for vIndex := 0 to 31 do
  begin
    if ParaX[vIndex] > ParaY[vIndex] then
    begin
      Result := True;
      Exit;
    end;
    if ParaX[vIndex] < ParaY[vIndex] then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

function Uint64ToByteArray(const ParaI: UInt64): TBytes;
begin
  SetLength(Result, 8);
  TEncoding.LittleEndian.PutUInt64(Result, ParaI);
end;

const
  prec = 64;

var
  floatTwo256: TBigFloat;
  float1: TBigFloat;

function BigFloatToBigInt(const ParaF: TBigFloat): TBigInteger;
var
  vStr: string;
begin
  vStr := ParaF.ToString;
  Result := TBigInteger.Parse(vStr);
end;

function DifficultyToTarget(const ParaDifficulty: TBigInteger): TBigInteger;
var
  vTmp: TBigFloat;
begin
  vTmp := TBigFloat.Create(ParaDifficulty);
  vTmp := float1 / vTmp;
  vTmp := vTmp + float1;
  vTmp := floatTwo256 / vTmp;
  Result := BigFloatToBigInt(vTmp);
end;

function TargetToDifficulty(const ParaTarget: TBigInteger): TBigInteger;
var
  vTmp: TBigFloat;
begin
  vTmp := TBigFloat.Create(ParaTarget);
  vTmp := floatTwo256 / vTmp;
  vTmp := vTmp - float1;
  vTmp := float1 / vTmp;
  Result := BigFloatToBigInt(vTmp);
end;

initialization
  gDefaultTarget := TBigInteger.Create(ConstFullThreshold);
  floatTwo256 := TBigFloat.Create(TBigInteger.Pow(2, 256));
  float1 := TBigFloat.Create(1);
end.
