unit Common.DB.XLevelDB.Key;

interface

uses
  System.SysUtils,
  Common.DB.XLevelDB.Errors,
  Common.DB.XLevelDB.Storage;

type
  EInternalKeyCorrupted = class(ECorrupted)
  public
    mIkey: TBytes;
    mReason: string;
    constructor Create(const ParaIkey: TBytes; const ParaReason: string; const ParaFileDesc: TFileDesc);
    function ToString: string; override;
  end;

  TKeyType = (
    KeyTypeDel = 0,
    KeyTypeVal = 1
  );

const
  ConstKeyTypeSeek = TKeyType.KeyTypeVal;
  ConstKeyMaxSeq = (UInt64(1) shl 56) - 1;
  ConstKeyMaxNum = (ConstKeyMaxSeq shl 8) or UInt64(ConstKeyTypeSeek);

var
  gKeyMaxNumBytes: TBytes;

type
  TInternalKey = TBytes;

function MakeInternalKey(const ParaDst, ParaUkey: TBytes; ParaSeq: UInt64; ParaKt: TKeyType): TInternalKey;
procedure ParseInternalKey(const ParaIk: TBytes; out ParaUkey: TBytes; out ParaSeq: UInt64; out ParaKt: TKeyType);
function ValidInternalKey(const ParaIk: TBytes): Boolean;
function InternalKeyToString(const ParaIk: TInternalKey): string;

// Helper functions for TInternalKey to mimic Go's methods
function GetUKey(const ParaIk: TInternalKey): TBytes;
function GetNum(const ParaIk: TInternalKey): UInt64;
procedure ParseNum(const ParaIk: TInternalKey; out ParaSeq: UInt64; out ParaKt: TKeyType);


implementation

uses
  System.Classes;

{ EInternalKeyCorrupted }

constructor EInternalKeyCorrupted.Create(const ParaIkey: TBytes; const ParaReason: string; const ParaFileDesc: TFileDesc);
begin
  inherited Create(ParaFileDesc, Format('leveldb: internal key "%s" corrupted: %s', [BytesToHex(ParaIkey), ParaReason]));
  mIkey := ParaIkey;
  mReason := ParaReason;
end;

function EInternalKeyCorrupted.ToString: string;
begin
  Result := Message;
end;

function newErrInternalKeyCorrupted(const ParaIkey: TBytes; const ParaReason: string): ECorrupted;
var
  vIkeyCopy: TBytes;
begin
  SetLength(vIkeyCopy, Length(ParaIkey));
  System.Move(ParaIkey[0], vIkeyCopy[0], Length(ParaIkey));
  Result := EInternalKeyCorrupted.Create(vIkeyCopy, ParaReason, TFileDesc.Create(0, TFileType.FileTypeTable, ''));
end;

function KeyTypeToString(ParaKt: TKeyType): string;
begin
  case ParaKt of
    TKeyType.KeyTypeDel: Result := 'd';
    TKeyType.KeyTypeVal: Result := 'v';
  else
    Result := Format('<invalid:%x>', [Ord(ParaKt)]);
  end;
end;

procedure InternalKeyAssert(const ParaIk: TInternalKey);
begin
  if ParaIk = nil then
    raise Exception.Create('leveldb: nil internalKey');
  if Length(ParaIk) < 8 then
    raise Exception.Create(Format('leveldb: internal key "%s", len=%d: invalid length', [BytesToHex(ParaIk), Length(ParaIk)]));
end;

function MakeInternalKey(const ParaDst, ParaUkey: TBytes; ParaSeq: UInt64; ParaKt: TKeyType): TInternalKey;
var
  vDst: TBytes;
  vNum: UInt64;
begin
  if ParaSeq > ConstKeyMaxSeq then
    raise Exception.Create('leveldb: invalid sequence number');
  if ParaKt > TKeyType.KeyTypeVal then
    raise Exception.Create('leveldb: invalid type');

  vDst := ParaDst;
  SetLength(vDst, Length(ParaUkey) + 8);
  System.Move(ParaUkey[0], vDst[0], Length(ParaUkey));
  vNum := (ParaSeq shl 8) or UInt64(ParaKt);
  PUInt64(@vDst[Length(ParaUkey)])^ := vNum;
  Result := vDst;
end;

procedure ParseInternalKey(const ParaIk: TBytes; out ParaUkey: TBytes; out ParaSeq: UInt64; out ParaKt: TKeyType);
var
  vNum: UInt64;
begin
  if Length(ParaIk) < 8 then
  begin
    raise newErrInternalKeyCorrupted(ParaIk, 'invalid length');
  end;
  vNum := PUInt64(@ParaIk[Length(ParaIk) - 8])^;
  ParaSeq := vNum shr 8;
  ParaKt := TKeyType(vNum and $FF);
  if ParaKt > TKeyType.KeyTypeVal then
  begin
    raise newErrInternalKeyCorrupted(ParaIk, 'invalid type');
  end;
  SetLength(ParaUkey, Length(ParaIk) - 8);
  System.Move(ParaIk[0], ParaUkey[0], Length(ParaUkey));
end;

function ValidInternalKey(const ParaIk: TBytes): Boolean;
var
  vUkey: TBytes;
  vSeq: UInt64;
  vKt: TKeyType;
begin
  try
    ParseInternalKey(ParaIk, vUkey, vSeq, vKt);
    Result := True;
  except
    on E: ECorrupted do
      Result := False;
  end;
end;

function GetUKey(const ParaIk: TInternalKey): TBytes;
begin
  InternalKeyAssert(ParaIk);
  SetLength(Result, Length(ParaIk) - 8);
  System.Move(ParaIk[0], Result[0], Length(Result));
end;

function GetNum(const ParaIk: TInternalKey): UInt64;
begin
  InternalKeyAssert(ParaIk);
  Result := PUInt64(@ParaIk[Length(ParaIk) - 8])^;
end;

procedure ParseNum(const ParaIk: TInternalKey; out ParaSeq: UInt64; out ParaKt: TKeyType);
var
  vNum: UInt64;
begin
  vNum := GetNum(ParaIk);
  ParaSeq := vNum shr 8;
  ParaKt := TKeyType(vNum and $FF);
  if ParaKt > TKeyType.KeyTypeVal then
  begin
    raise Exception.Create(Format('leveldb: internal key "%s", len=%d: invalid type %x', [BytesToHex(ParaIk), Length(ParaIk), Ord(ParaKt)]));
  end;
end;

function Shorten(const s: string): string;
begin
  // Placeholder for the actual shorten logic, which is not in this file.
  Result := s;
end;

function InternalKeyToString(const ParaIk: TInternalKey): string;
var
  vUkey: TBytes;
  vSeq: UInt64;
  vKt: TKeyType;
begin
  if ParaIk = nil then
    Result := '<nil>'
  else
  try
    ParseInternalKey(ParaIk, vUkey, vSeq, vKt);
    Result := Format('%s,%s%d', [Shorten(TEncoding.UTF8.GetString(vUkey)), KeyTypeToString(vKt), vSeq]);
  except
    on E: Exception do
      Result := Format('<invalid:%s>', [BytesToHex(ParaIk)]);
  end;
end;

initialization
  SetLength(gKeyMaxNumBytes, 8);
  PUInt64(@gKeyMaxNumBytes[0])^ := ConstKeyMaxNum;
end.
