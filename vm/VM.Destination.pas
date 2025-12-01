unit VM.Destination;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  GoToDelphi.Helpers.BigInt,
  Vite.Common.Types,
  VM.Opcodes;

type
  TBitVec = TBytes;
  TDestinations = TDictionary<TAddress, TBitVec>;

  TBitVecHelper = record helper for TBitVec
    procedure SetValue(ParaPos: UInt64);
    procedure Set8(ParaPos: UInt64);
    function CodeSegment(ParaPos: UInt64): Boolean;
  end;

  TDestinationsHelper = record helper for TDestinations
    function Has(const ParaAddr: TAddress; const ParaCode: TBytes; const ParaDest: TBigInt): Boolean;
  end;

function CodeBitmap(const ParaCode: TBytes): TBitVec;
function ContainsStatusCode(const ParaCode: TBytes): Boolean;
function ContainsCertainStatusCode(const ParaCode: TBytes; out ParaRequireSnapshot, ParaRequireSnapshotWithSeed: Boolean): Boolean;
function GetCodeWithoutAuxCodeAndParams(const ParaCode: TBytes): TBytes;

var
  AuxCodePrefix: TBytes;
  AuxCodeSuffix: TBytes;
  StatusCodeList: TArray<TOpCode>;
  AuxCodePrefixWithFE: TBytes;
  PushCheckCount: Integer;
  StatusCodeListRequireSnapshot: TArray<TOpCode>;
  StatusCodeListRequireSnapshotWithSeed: TArray<TOpCode>;

implementation

uses
  System.Math,
  System.StrUtils;

{ TBitVecHelper }

procedure TBitVecHelper.SetValue(ParaPos: UInt64);
begin
  Self[ParaPos div 8] := Self[ParaPos div 8] or ($80 shr (ParaPos mod 8));
end;

procedure TBitVecHelper.Set8(ParaPos: UInt64);
begin
  Self[ParaPos div 8] := Self[ParaPos div 8] or ($FF shr (ParaPos mod 8));
  Self[ParaPos div 8 + 1] := Self[ParaPos div 8 + 1] or (not ($FF shr (ParaPos mod 8)));
end;

function TBitVecHelper.CodeSegment(ParaPos: UInt64): Boolean;
begin
  Result := (Self[ParaPos div 8] and ($80 shr (ParaPos mod 8))) = 0;
end;

{ TDestinationsHelper }

function TDestinationsHelper.Has(const ParaAddr: TAddress; const ParaCode: TBytes; const ParaDest: TBigInt): Boolean;
var
  vUDest: UInt64;
  vM: TBitVec;
  vAnalysed: Boolean;
begin
  if ParaDest.BitLength >= 63 then
  begin
    Result := False;
    Exit;
  end;

  vUDest := ParaDest.ToUInt64;
  if vUDest >= Length(ParaCode) then
  begin
    Result := False;
    Exit;
  end;

  vAnalysed := Self.TryGetValue(ParaAddr, vM);
  if not vAnalysed then
  begin
    vM := CodeBitmap(ParaCode);
    Self.Add(ParaAddr, vM);
  end;
  Result := (TOpCode(ParaCode[vUDest]) = TOpCode.JUMPDEST) and vM.CodeSegment(vUDest);
end;

// codeBitmap collects data locations in code.
function CodeBitmap(const ParaCode: TBytes): TBitVec;
var
  vBits: TBitVec;
  vPc: UInt64;
  vOp: TOpCode;
  vNumBits: Byte;
begin
  // The bitmap is 4 bytes longer than necessary, in case the code
  // ends with a PUSH32, the algorithm will push zeroes onto the
  // bitvector outside the bounds of the actual code.
  SetLength(vBits, Length(ParaCode) div 8 + 1 + 4);
  vPc := 0;
  while vPc < Length(ParaCode) do
  begin
    vOp := TOpCode(ParaCode[vPc]);
    if (vOp >= TOpCode.PUSH1) and (vOp <= TOpCode.PUSH32) then
    begin
      vNumBits := Ord(vOp) - Ord(TOpCode.PUSH1) + 1;
      Inc(vPc);
      while vNumBits >= 8 do
      begin
        vBits.Set8(vPc);
        Inc(vPc, 8);
        Dec(vNumBits, 8);
      end;
      while vNumBits > 0 do
      begin
        vBits.SetValue(vPc);
        Inc(vPc);
        Dec(vNumBits);
      end;
    end
    else
    begin
      Inc(vPc);
    end;
  end;
  Result := vBits;
end;

function ContainsAuxCode(const ParaCode: TBytes): Boolean;
var
  vL: Integer;
  vCode: TBytes;
begin
  vL := Length(ParaCode);
  vCode := Copy(ParaCode, vL - 43, 9);
  Result := (vL > 43) and (CompareMem(PByte(vCode), PByte(AuxCodePrefix), Length(AuxCodePrefix)))) and (CompareMem(PByte(Copy(ParaCode, vL - 2, 2)), PByte(AuxCodeSuffix), Length(AuxCodeSuffix)));
end;

// ContainsStatusCode checks whether code includes status reading opcode.
function ContainsStatusCode(const ParaCode: TBytes): Boolean;
var
  vM: TBitVec;
  vI: UInt64;
  vC: TOpCode;
  vCode: TBytes;
begin
  vCode := ParaCode;
  if ContainsAuxCode(vCode) then
  begin
    SetLength(vCode, Length(vCode) - 43);
  end;
  vM := CodeBitmap(vCode);
  Result := False;
  for vI := 0 to Length(vCode) - 1 do
  begin
    if vM.CodeSegment(vI) then
    begin
      for vC in StatusCodeList do
      begin
        if TOpCode(vCode[vI]) = vC then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
end;

// ContainsCertainStatusCode method checks whether the input code contains
// certain op codes that read cross chain data.
function ContainsCertainStatusCode(const ParaCode: TBytes; out ParaRequireSnapshot, ParaRequireSnapshotWithSeed: Boolean): Boolean;
var
  vResultCode: TBytes;
  vM: TBitVec;
  vI: UInt64;
  vC: TOpCode;
begin
  ParaRequireSnapshot := False;
  ParaRequireSnapshotWithSeed := False;
  if Length(ParaCode) = 0 then
  begin
    Result := False;
    Exit;
  end;
  vResultCode := GetCodeWithoutAuxCodeAndParams(ParaCode);
  vM := CodeBitmap(vResultCode);
  for vI := 0 to Length(vResultCode) - 1 do
  begin
    if vM.CodeSegment(vI) then
    begin
      for vC in StatusCodeListRequireSnapshot do
      begin
        if TOpCode(vResultCode[vI]) = vC then
        begin
          ParaRequireSnapshot := True;
          if ParaRequireSnapshotWithSeed then
          begin
            Result := True;
            Exit;
          end;
        end;
      end;
      for vC in StatusCodeListRequireSnapshotWithSeed do
      begin
        if TOpCode(vResultCode[vI]) = vC then
        begin
          ParaRequireSnapshotWithSeed := True;
          if ParaRequireSnapshot then
          begin
            Result := True;
            Exit;
          end;
        end;
      end;
    end;
  end;
  Result := ParaRequireSnapshot or ParaRequireSnapshotWithSeed;
end;

function GetCodeWithoutAuxCodeAndParams(const ParaCode: TBytes): TBytes;
var
  vOriginM: TBitVec;
  vResultCode: TBytes;
  vPrevIndex: Integer;
  vIndex, vNewIndex: Integer;
  vFlag: Boolean;
  vI: Integer;
  vCode: TBytes;
begin
  vCode := ParaCode;
  vOriginM := CodeBitmap(vCode);
  vPrevIndex := 0;
  while True do
  begin
    vIndex := Pos(AuxCodePrefixWithFE, vCode);
    if (vIndex < 1) or (vIndex > Length(vCode) - 44) then
    begin
      vResultCode := Concat(vResultCode, vCode);
      Break;
    end;
    vFlag := False;
    for vI := 0 to PushCheckCount - 1 do
    begin
      if not vOriginM.CodeSegment(vPrevIndex + vIndex + vI - 1) then
      begin
        vFlag := True;
        Break;
      end;
    end;
    if vFlag then
    begin
      vNewIndex := vIndex + Length(AuxCodePrefixWithFE);
      vResultCode := Concat(vResultCode, Copy(vCode, 1, vNewIndex));
      System.Delete(vCode, 1, vNewIndex);
      Inc(vPrevIndex, vNewIndex);
    end
    else
    begin
      vResultCode := Concat(vResultCode, Copy(vCode, 1, vIndex));
      Break;
    end;
  end;
  Result := vResultCode;
end;

initialization
  AuxCodePrefix := [$a1, $65, Ord('b'), Ord('z'), Ord('z'), Ord('r'), Ord('0'), $58, $20];
  AuxCodeSuffix := [$00, $29];
  StatusCodeList := [TOpCode.HEIGHT, TOpCode.TIMESTAMP, TOpCode.SEED, TOpCode.DELEGATECALL, TOpCode.EXTCODESIZE, TOpCode.EXTCODECOPY];
  AuxCodePrefixWithFE := [$fe, $a1, $65, Ord('b'), Ord('z'), Ord('z'), Ord('r'), Ord('0'), $58, $20];
  PushCheckCount := 3;
  StatusCodeListRequireSnapshot := [TOpCode.HEIGHT, TOpCode.TIMESTAMP, TOpCode.DELEGATECALL, TOpCode.EXTCODESIZE, TOpCode.EXTCODECOPY];
  StatusCodeListRequireSnapshotWithSeed := [TOpCode.SEED, TOpCode.RANDOM];
end.
