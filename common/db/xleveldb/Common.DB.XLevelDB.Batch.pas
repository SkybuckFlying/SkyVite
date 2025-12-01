// Copyright (c) 2012, Suryandaru Triandana <syndtr@gmail.com>
// All rights reserved.
//
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
unit Common.Db.XLevelDB.Batch;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  Common.Db.XLevelDB.Errors,
  Common.Db.XLevelDB.MemDB,
  Common.Db.XLevelDB.Key,
  Common.Db.XLevelDB.Storage,
  GoToDelphi.Helpers.TChannel,
  Common.Utils;

type
  // ErrBatchCorrupted records reason of batch corruption. This error will be
  // wrapped with errors.ErrCorrupted.
  EErrBatchCorrupted = class(ELevelDBError)
  public
    mReason: string;
    constructor Create(const ParaReason: string);
  end;

  // BatchReplay wraps basic batch operations.
  IBatchReplay = interface
    ['{6E9C3F3D-9B4F-4A2B-A68D-3F4E4F2A2B3C}']
    procedure Put(ParaKey, ParaValue: TBytes);
    procedure Delete(ParaKey: TBytes);
  end;

  TBatchIndex = record
    mKeyType: TKeyType;
    mKeyPos, mKeyLen: Integer;
    mValuePos, mValueLen: Integer;

    function K(const ParaData: TBytes): TBytes;
    function V(const ParaData: TBytes): TBytes;
    procedure KV(const ParaData: TBytes; out ParaKey, ParaValue: TBytes);
  end;

const
  ConstBatchHeaderLen = 8 + 4;
  ConstBatchGrowRec = 3000;
  ConstBatchBufioSize = 16;

type
  // Batch is a write batch.
  TBatch = class
  private
    mData: TBytes;
    mIndex: TArray<TBatchIndex>;
    // internalLen is sums of key/value pair length plus 8-bytes internal key.
    mInternalLen: Integer;
    procedure Grow(ParaN: Integer);
    procedure AppendRec(ParaKt: TKeyType; const ParaKey, ParaValue: TBytes);
  public
    constructor Create;
    destructor Destroy; override;
    // Put appends 'put operation' of the given key/value pair to the batch.
    // It is safe to modify the contents of the argument after Put returns but not
    // before.
    procedure Put(const ParaKey, ParaValue: TBytes);
    // Delete appends 'delete operation' of the given key to the batch.
    // It is safe to modify the contents of the argument after Delete returns but
    // not before.
    procedure Delete(const ParaKey: TBytes);
    // Dump dumps batch contents. The returned slice can be loaded into the
    // batch using Load method.
    // The returned slice is not its own copy, so the contents should not be
    // modified.
    function Dump: TBytes;
    // Load loads given slice into the batch. Previous contents of the batch
    // will be discarded.
    // The given slice will not be copied and will be used as batch buffer, so
    // it is not safe to modify the contents of the slice.
    function Load(const ParaData: TBytes): Exception;
    // Replay replays batch contents.
    function Replay(ParaR: IBatchReplay): Exception;
    // Len returns number of records in the batch.
    function Len: Integer;
    function Size: Integer;
    // Reset resets the batch.
    procedure Reset;
    procedure Append(ParaP: TBatch);
    function ReplayInternal(ParaFn: TFunc<Integer, TKeyType, TBytes, TBytes, Exception>): Exception;
    function Decode(const ParaData: TBytes; ParaExpectedLen: Integer): Exception;
    function PutMem(ParaSeq: UInt64; ParaMdb: TDB): Exception;
    function RevertMem(ParaSeq: UInt64; ParaMdb: TDB): Exception;
  end;

function NewBatch: TObject;
function DecodeBatch(const ParaData: TBytes; ParaFn: TFunc<Integer, TBatchIndex, Exception>): Exception;
function DecodeBatchToMem(const ParaData: TBytes; ParaExpectSeq: UInt64; ParaMdb: TDB; out ParaSeq: UInt64; out ParaBatchLen: Integer): Exception;
function EncodeBatchHeader(ParaDst: TBytes; ParaSeq: UInt64; ParaBatchLen: Integer): TBytes;
function DecodeBatchHeader(const ParaData: TBytes; out ParaSeq: UInt64; out ParaBatchLen: Integer): Exception;
function BatchesLen(const ParaBatches: TArray<TBatch>): Integer;
function WriteBatchesWithHeader(ParaWr: TStream; const ParaBatches: TArray<TBatch>; ParaSeq: UInt64): Exception;

implementation

uses
  System.Types;

function NewErrBatchCorrupted(const ParaReason: string): Exception;
begin
  Result := EErrBatchCorrupted.Create(ParaReason);
end;

{ EErrBatchCorrupted }

constructor EErrBatchCorrupted.Create(const ParaReason: string);
begin
  inherited Create(Format('leveldb: batch corrupted: %s', [ParaReason]));
  mReason := ParaReason;
end;

{ TBatchIndex }

function TBatchIndex.K(const ParaData: TBytes): TBytes;
begin
  Result := Copy(ParaData, mKeyPos, mKeyLen);
end;

function TBatchIndex.V(const ParaData: TBytes): TBytes;
begin
  if mValueLen <> 0 then
    Result := Copy(ParaData, mValuePos, mValueLen)
  else
    Result := nil;
end;

procedure TBatchIndex.KV(const ParaData: TBytes; out ParaKey, ParaValue: TBytes);
begin
  ParaKey := K(ParaData);
  ParaValue := V(ParaData);
end;

{ TBatch }

constructor TBatch.Create;
begin
  inherited Create;
  SetLength(mData, 0);
  SetLength(mIndex, 0);
  mInternalLen := 0;
end;

destructor TBatch.Destroy;
begin
  inherited;
end;

procedure TBatch.Grow(ParaN: Integer);
var
  vO: Integer;
  vDiv: Integer;
  vNewData: TBytes;
begin
  vO := Length(mData);
  if Capacity(mData) - vO < ParaN then
  begin
    vDiv := 1;
    if Length(mIndex) > ConstBatchGrowRec then
    begin
      vDiv := Length(mIndex) div ConstBatchGrowRec;
    end;
    SetLength(vNewData, vO, vO + ParaN + vO div vDiv);
    System.Move(mData[0], vNewData[0], vO);
    mData := vNewData;
  end;
end;

procedure TBatch.AppendRec(ParaKt: TKeyType; const ParaKey, ParaValue: TBytes);
var
  vN: Integer;
  vIndex: TBatchIndex;
  vO: Integer;
  vData: TBytes;
  vUvarintLen: Integer;
begin
  vN := 1 + 10 + Length(ParaKey); // MaxVarintLen32 is 10 in Go for uint64
  if ParaKt = TKeyType.KeyTypeVal then
  begin
    vN := vN + 10 + Length(ParaValue);
  end;
  Grow(vN);
  vIndex.mKeyType := ParaKt;
  vO := Length(mData);
  SetLength(mData, vO + vN);
  vData := mData;
  vData[vO] := Byte(ParaKt);
  Inc(vO);
  vUvarintLen := PutUvarint(vData, vO, Length(ParaKey));
  Inc(vO, vUvarintLen);
  vIndex.mKeyPos := vO;
  vIndex.mKeyLen := Length(ParaKey);
  System.Move(ParaKey[0], vData[vO], Length(ParaKey));
  Inc(vO, Length(ParaKey));
  if ParaKt = TKeyType.KeyTypeVal then
  begin
    vUvarintLen := PutUvarint(vData, vO, Length(ParaValue));
    Inc(vO, vUvarintLen);
    vIndex.mValuePos := vO;
    vIndex.mValueLen := Length(ParaValue);
    System.Move(ParaValue[0], vData[vO], Length(ParaValue));
    Inc(vO, Length(ParaValue));
  end;
  SetLength(mData, vO);
  SetLength(mIndex, Length(mIndex) + 1);
  mIndex[High(mIndex)] := vIndex;
  mInternalLen := mInternalLen + vIndex.mKeyLen + vIndex.mValueLen + 8;
end;

procedure TBatch.Put(const ParaKey, ParaValue: TBytes);
begin
  AppendRec(TKeyType.KeyTypeVal, ParaKey, ParaValue);
end;

procedure TBatch.Delete(const ParaKey: TBytes);
begin
  AppendRec(TKeyType.KeyTypeDel, ParaKey, nil);
end;

function TBatch.Dump: TBytes;
begin
  Result := mData;
end;

function TBatch.Load(const ParaData: TBytes): Exception;
begin
  Result := Decode(ParaData, -1);
end;

function TBatch.Replay(ParaR: IBatchReplay): Exception;
var
  vIndex: TBatchIndex;
begin
  Result := nil;
  for vIndex in mIndex do
  begin
    case vIndex.mKeyType of
      TKeyType.KeyTypeVal:
        ParaR.Put(vIndex.K(mData), vIndex.V(mData));
      TKeyType.KeyTypeDel:
        ParaR.Delete(vIndex.K(mData));
    end;
  end;
end;

function TBatch.Len: Integer;
begin
  Result := Length(mIndex);
end;

function TBatch.Size: Integer;
begin
  Result := Length(mData) + (Length(mIndex) * 3 * SizeOf(Pointer));
end;

procedure TBatch.Reset;
begin
  SetLength(mData, 0);
  SetLength(mIndex, 0);
  mInternalLen := 0;
end;

procedure TBatch.Append(ParaP: TBatch);
var
  vOB: Integer;
  vOI: Integer;
  vI: Integer;
  vIndex: TBatchIndex;
begin
  vOB := Length(mData);
  vOI := Length(mIndex);
  SetLength(mData, Length(mData) + Length(ParaP.mData));
  System.Move(ParaP.mData[0], mData[vOB], Length(ParaP.mData));
  SetLength(mIndex, Length(mIndex) + Length(ParaP.mIndex));
  System.Move(ParaP.mIndex[0], mIndex[vOI], Length(ParaP.mIndex) * SizeOf(TBatchIndex));
  mInternalLen := mInternalLen + ParaP.mInternalLen;

  // Updating index offset.
  if vOB <> 0 then
  begin
    for vI := vOI to High(mIndex) do
    begin
      vIndex := mIndex[vI];
      vIndex.mKeyPos := vIndex.mKeyPos + vOB;
      if vIndex.mValueLen <> 0 then
      begin
        vIndex.mValuePos := vIndex.mValuePos + vOB;
      end;
      mIndex[vI] := vIndex;
    end;
  end;
end;

function TBatch.ReplayInternal(ParaFn: TFunc<Integer, TKeyType, TBytes, TBytes, Exception>): Exception;
var
  vI: Integer;
  vIndex: TBatchIndex;
begin
  Result := nil;
  for vI := 0 to High(mIndex) do
  begin
    vIndex := mIndex[vI];
    Result := ParaFn(vI, vIndex.mKeyType, vIndex.K(mData), vIndex.V(mData));
    if Result <> nil then
    begin
      Exit;
    end;
  end;
end;

function TBatch.Decode(const ParaData: TBytes; ParaExpectedLen: Integer): Exception;
begin
  mData := ParaData;
  SetLength(mIndex, 0);
  mInternalLen := 0;
  Result := DecodeBatch(ParaData,
    function(ParaI: Integer; ParaIndex: TBatchIndex): Exception
    begin
      SetLength(mIndex, Length(mIndex) + 1);
      mIndex[High(mIndex)] := ParaIndex;
      mInternalLen := mInternalLen + ParaIndex.mKeyLen + ParaIndex.mValueLen + 8;
      Result := nil;
    end);
  if Result <> nil then
  begin
    Exit;
  end;
  if (ParaExpectedLen >= 0) and (Length(mIndex) <> ParaExpectedLen) then
  begin
    Result := NewErrBatchCorrupted(Format('invalid records length: %d vs %d', [ParaExpectedLen, Length(mIndex)]));
  end;
end;

function TBatch.PutMem(ParaSeq: UInt64; ParaMdb: TDB): Exception;
var
  vIK: TBytes;
  vI: Integer;
  vIndex: TBatchIndex;
begin
  Result := nil;
  vIK := nil;
  for vI := 0 to High(mIndex) do
  begin
    vIndex := mIndex[vI];
    vIK := MakeInternalKey(vIK, vIndex.K(mData), ParaSeq + UInt64(vI), vIndex.mKeyType);
    Result := ParaMdb.Put(vIK, vIndex.V(mData));
    if Result <> nil then
    begin
      Exit;
    end;
  end;
end;

function TBatch.RevertMem(ParaSeq: UInt64; ParaMdb: TDB): Exception;
var
  vIK: TBytes;
  vI: Integer;
  vIndex: TBatchIndex;
begin
  Result := nil;
  vIK := nil;
  for vI := 0 to High(mIndex) do
  begin
    vIndex := mIndex[vI];
    vIK := MakeInternalKey(vIK, vIndex.K(mData), ParaSeq + UInt64(vI), vIndex.mKeyType);
    Result := ParaMdb.Delete(vIK);
    if Result <> nil then
    begin
      Exit;
    end;
  end;
end;

function NewBatch: TObject;
begin
  Result := TBatch.Create;
end;

function DecodeBatch(const ParaData: TBytes; ParaFn: TFunc<Integer, TBatchIndex, Exception>): Exception;
var
  vIndex: TBatchIndex;
  vI, vO: Integer;
  vX: UInt64;
  vN: Integer;
begin
  Result := nil;
  vO := 0;
  vI := 0;
  while vO < Length(ParaData) do
  begin
    // Key type.
    vIndex.mKeyType := TKeyType(ParaData[vO]);
    if vIndex.mKeyType > TKeyType.KeyTypeVal then
    begin
      Result := NewErrBatchCorrupted(Format('bad record: invalid type %#x', [Byte(vIndex.mKeyType)]));
      Exit;
    end;
    Inc(vO);

    // Key.
    vX := GetUvarint(ParaData, vO, vN);
    Inc(vO, vN);
    if (vN <= 0) or (vO + Integer(vX) > Length(ParaData)) then
    begin
      Result := NewErrBatchCorrupted('bad record: invalid key length');
      Exit;
    end;
    vIndex.mKeyPos := vO;
    vIndex.mKeyLen := Integer(vX);
    Inc(vO, vIndex.mKeyLen);

    // Value.
    if vIndex.mKeyType = TKeyType.KeyTypeVal then
    begin
      vX := GetUvarint(ParaData, vO, vN);
      Inc(vO, vN);
      if (vN <= 0) or (vO + Integer(vX) > Length(ParaData)) then
      begin
        Result := NewErrBatchCorrupted('bad record: invalid value length');
        Exit;
      end;
      vIndex.mValuePos := vO;
      vIndex.mValueLen := Integer(vX);
      Inc(vO, vIndex.mValueLen);
    end
    else
    begin
      vIndex.mValuePos := 0;
      vIndex.mValueLen := 0;
    end;

    Result := ParaFn(vI, vIndex);
    if Result <> nil then
    begin
      Exit;
    end;
    Inc(vI);
  end;
end;

function DecodeBatchToMem(const ParaData: TBytes; ParaExpectSeq: UInt64; ParaMdb: TDB; out ParaSeq: UInt64; out ParaBatchLen: Integer): Exception;
var
  vIK: TBytes;
  vDecodedLen: Integer;
  vData: TBytes;
begin
  Result := DecodeBatchHeader(ParaData, ParaSeq, ParaBatchLen);
  if Result <> nil then
  begin
    Exit;
  end;
  if ParaSeq < ParaExpectSeq then
  begin
    Result := NewErrBatchCorrupted('invalid sequence number');
    Exit;
  end;
  vData := Copy(ParaData, ConstBatchHeaderLen);
  vIK := nil;
  vDecodedLen := 0;
  Result := DecodeBatch(vData,
    function(ParaI: Integer; ParaIndex: TBatchIndex): Exception
    begin
      if ParaI >= ParaBatchLen then
      begin
        Result := NewErrBatchCorrupted('invalid records length');
        Exit;
      end;
      vIK := MakeInternalKey(vIK, ParaIndex.K(vData), ParaSeq + UInt64(ParaI), ParaIndex.mKeyType);
      Result := ParaMdb.Put(vIK, ParaIndex.V(vData));
      if Result <> nil then
      begin
        Exit;
      end;
      Inc(vDecodedLen);
      Result := nil;
    end);
  if (Result = nil) and (vDecodedLen <> ParaBatchLen) then
  begin
    Result := NewErrBatchCorrupted(Format('invalid records length: %d vs %d', [ParaBatchLen, vDecodedLen]));
  end;
end;

function EncodeBatchHeader(ParaDst: TBytes; ParaSeq: UInt64; ParaBatchLen: Integer): TBytes;
begin
  SetLength(Result, ConstBatchHeaderLen);
  PUInt64(@Result[0])^ := ParaSeq;
  PUInt32(@Result[8])^ := Cardinal(ParaBatchLen);
end;

function DecodeBatchHeader(const ParaData: TBytes; out ParaSeq: UInt64; out ParaBatchLen: Integer): Exception;
begin
  Result := nil;
  if Length(ParaData) < ConstBatchHeaderLen then
  begin
    Result := NewErrBatchCorrupted('too short');
    Exit;
  end;

  ParaSeq := PUInt64(@ParaData[0])^;
  ParaBatchLen := Integer(PUInt32(@ParaData[8])^);
  if ParaBatchLen < 0 then
  begin
    Result := NewErrBatchCorrupted('invalid records length');
    Exit;
  end;
end;

function BatchesLen(const ParaBatches: TArray<TBatch>): Integer;
var
  vBatch: TBatch;
begin
  Result := 0;
  for vBatch in ParaBatches do
  begin
    Result := Result + vBatch.Len;
  end;
end;

function WriteBatchesWithHeader(ParaWr: TStream; const ParaBatches: TArray<TBatch>; ParaSeq: UInt64): Exception;
var
  vHeader: TBytes;
  vBatch: TBatch;
begin
  Result := nil;
  try
    vHeader := EncodeBatchHeader(nil, ParaSeq, BatchesLen(ParaBatches));
    ParaWr.Write(vHeader, 0, Length(vHeader));
    for vBatch in ParaBatches do
    begin
      ParaWr.Write(vBatch.mData, 0, Length(vBatch.mData));
    end;
  except
    on E: Exception do
    begin
      Result := E;
    end;
  end;
end;

end.
