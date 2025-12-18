unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Batch;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Db,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbSnapshot,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbState,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbTransaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbWrite,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Doc,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Memdb,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Session,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionRecord,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Version;

type
  TMemDB_DB = Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Memdb.TDB;

  IBatchReplay = interface
    ['{E9A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F80}']
    procedure Put(const ParaKey, ParaValue: TBytes);
    procedure Delete(const ParaKey: TBytes);
  end;

  TBatchIndex = record
    KeyType: TKeyType;
    KeyPos, KeyLen: Integer;
    ValuePos, ValueLen: Integer;
    function K(const ParaData: TBytes): TBytes;
    function V(const ParaData: TBytes): TBytes;
  end;

  TBatch = class
  private
    mData: TBytes;
    mIndex: TArray<TBatchIndex>;
    mInternalLen: Integer;

    procedure Grow(ParaN: Integer);
    procedure AppendRec(ParaKt: TKeyType; const ParaKey, ParaValue: TBytes);
    function DecodeInternal(const ParaData: TBytes; ParaExpectedLen: Integer): Exception;
  public
    constructor Create;
    procedure Put(const ParaKey, ParaValue: TBytes);
    procedure Delete(const ParaKey: TBytes);
    function Dump: TBytes;
    function Load(const ParaData: TBytes): Exception;
    function Replay(const ParaR: IBatchReplay): Exception;
    function Len: Integer;
    procedure Reset;
    
    function PutMem(ParaSeq: UInt64; ParaMdb: TMemDB_DB): Exception;
    
    property Data: TBytes read mData;
    property InternalLen: Integer read mInternalLen;
  end;

  EBatchCorrupted = class(ECorrupted)
  public
    constructor Create(const ParaReason: string);
  end;

const
  BATCH_HEADER_LEN = 8 + 4;

function EncodeBatchHeader(const ParaDst: TBytes; ParaSeq: UInt64; ParaBatchLen: Integer): TBytes;
function DecodeBatchHeader(const ParaData: TBytes; out ParaSeq: UInt64; out ParaBatchLen: Integer): Exception;
function WriteBatchesWithHeader(ParaW: IWriter; ParaBatches: TArray<TBatch>; ParaSeq: UInt64): Exception;

implementation

{ TBatchIndex }

function TBatchIndex.K(const ParaData: TBytes): TBytes;
begin
  Result := Copy(ParaData, KeyPos, KeyLen);
end;

function TBatchIndex.V(const ParaData: TBytes): TBytes;
begin
  if ValueLen <> 0 then
    Result := Copy(ParaData, ValuePos, ValueLen)
  else
    Result := nil;
end;

{ TBatch }

procedure TBatch.AppendRec(ParaKt: TKeyType; const ParaKey, ParaValue: TBytes);
var
  vN: Integer;
  vIndex: TBatchIndex;
  vO: Integer;
begin
  vN := 1 + 10 + Length(ParaKey); // 10 is MaxVarintLen32
  if ParaKt = ktVal then
    vN := vN + 10 + Length(ParaValue);
  
  Grow(vN);
  vIndex.KeyType := ParaKt;
  vO := Length(mData);
  SetLength(mData, vO + vN);
  
  mData[vO] := Byte(ParaKt);
  Inc(vO);
  
  vO := vO + Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.PutUvarint( @mData[vO], UInt64(Length(ParaKey)) );
  vIndex.KeyPos := vO;
  vIndex.KeyLen := Length(ParaKey);
  if Length(ParaKey) > 0 then
    Move(ParaKey[0], mData[vO], Length(ParaKey));
  vO := vO + Length(ParaKey);
  
  if ParaKt = ktVal then
  begin
    vO := vO + Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.PutUvarint( @mData[vO], UInt64(Length(ParaValue)) );
    vIndex.ValuePos := vO;
    vIndex.ValueLen := Length(ParaValue);
    if Length(ParaValue) > 0 then
      Move(ParaValue[0], mData[vO], Length(ParaValue));
    vO := vO + Length(ParaValue);
  end
  else
  begin
    vIndex.ValuePos := 0;
    vIndex.ValueLen := 0;
  end;
  
  SetLength(mData, vO);
  SetLength(mIndex, Length(mIndex) + 1);
  mIndex[High(mIndex)] := vIndex;
  mInternalLen := mInternalLen + vIndex.KeyLen + vIndex.ValueLen + 8;
end;

constructor TBatch.Create;
begin
  inherited Create;
  mData := nil;
  mIndex := nil;
  mInternalLen := 0;
end;

function TBatch.DecodeInternal(const ParaData: TBytes; ParaExpectedLen: Integer): Exception;
var
  vO: Integer;
  vIndex: TBatchIndex;
  vX: UInt64;
  vN: Integer;
  vCount: Integer;
begin
  mData := ParaData;
  mIndex := nil;
  mInternalLen := 0;
  vO := 0;
  vCount := 0;
  
  try
    while vO < Length(mData) do
    begin
      vIndex.KeyType := TKeyType(mData[vO]);
      if vIndex.KeyType > ktVal then
        Exit(EBatchCorrupted.Create(Format('bad record: invalid type %#x', [Byte(vIndex.KeyType)])));
      Inc(vO);
      
      vN := Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Uvarint( @mData[vO], vX );
      if (vN <= 0) or (vO + vN + Integer(vX) > Length(mData)) then
        Exit(EBatchCorrupted.Create('bad record: invalid key length'));
      vO := vO + vN;
      vIndex.KeyPos := vO;
      vIndex.KeyLen := Integer(vX);
      vO := vO + vIndex.KeyLen;
      
      if vIndex.KeyType = ktVal then
      begin
        vN := Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Uvarint( @mData[vO], vX );
        if (vN <= 0) or (vO + vN + Integer(vX) > Length(mData)) then
          Exit(EBatchCorrupted.Create('bad record: invalid value length'));
        vO := vO + vN;
        vIndex.ValuePos := vO;
        vIndex.ValueLen := Integer(vX);
        vO := vO + vIndex.ValueLen;
      end
      else
      begin
        vIndex.ValuePos := 0;
        vIndex.ValueLen := 0;
      end;
      
      SetLength(mIndex, Length(mIndex) + 1);
      mIndex[High(mIndex)] := vIndex;
      mInternalLen := mInternalLen + vIndex.KeyLen + vIndex.ValueLen + 8;
      Inc(vCount);
    end;
  except
    on E: Exception do Exit(E);
  end;
  
  if (ParaExpectedLen >= 0) and (vCount <> ParaExpectedLen) then
    Exit(EBatchCorrupted.Create(Format('invalid records length: %d vs %d', [ParaExpectedLen, vCount])));
    
  Result := nil;
end;

procedure TBatch.Delete(const ParaKey: TBytes);
begin
  AppendRec(ktDel, ParaKey, nil);
end;

function TBatch.Dump: TBytes;
begin
  Result := mData;
end;

procedure TBatch.Grow(ParaN: Integer);
begin
end;

function TBatch.Len: Integer;
begin
  Result := Length(mIndex);
end;

function TBatch.Load(const ParaData: TBytes): Exception;
begin
  Result := DecodeInternal(ParaData, -1);
end;

procedure TBatch.Put(const ParaKey, ParaValue: TBytes);
begin
  AppendRec(ktVal, ParaKey, ParaValue);
end;

function TBatch.PutMem(ParaSeq: UInt64; ParaMdb: TMemDB_DB): Exception;
var
  vIdx: TBatchIndex;
  vIkey: TInternalKey;
begin
  for vIdx in mIndex do
  begin
    vIkey := TInternalKey.Create(vIdx.K(mData), ParaSeq, vIdx.KeyType);
    try
      case vIdx.KeyType of
        ktVal: ParaMdb.Put(vIkey.Data, vIdx.V(mData));
        ktDel: ParaMdb.Delete(vIkey.Data);
      end;
    finally
      vIkey.Free;
    end;
    Inc(ParaSeq);
  end;
  Result := nil;
end;



function TBatch.Replay(const ParaR: IBatchReplay): Exception;
var
  vIndex: TBatchIndex;
begin
  for vIndex in mIndex do
  begin
    case vIndex.KeyType of
      ktVal: ParaR.Put(vIndex.K(mData), vIndex.V(mData));
      ktDel: ParaR.Delete(vIndex.K(mData));
    end;
  end;
  Result := nil;
end;

procedure TBatch.Reset;
begin
  mData := nil;
  mIndex := nil;
  mInternalLen := 0;
end;

{ EBatchCorrupted }

constructor EBatchCorrupted.Create(const ParaReason: string);
begin
  inherited Create('leveldb: batch corrupted: ' + ParaReason);
end;

function EncodeBatchHeader(const ParaDst: TBytes; ParaSeq: UInt64; ParaBatchLen: Integer): TBytes;
var
  vDst: TBytes;
begin
  vDst := ParaDst;
  if Length(vDst) < BATCH_HEADER_LEN then
    SetLength(vDst, BATCH_HEADER_LEN);
  Move(ParaSeq, vDst[0], 8);
  Move(ParaBatchLen, vDst[8], 4);
  Result := vDst;
end;

function DecodeBatchHeader(const ParaData: TBytes; out ParaSeq: UInt64; out ParaBatchLen: Integer): Exception;
begin
  if Length(ParaData) < BATCH_HEADER_LEN then
  begin
    ParaSeq := 0;
    ParaBatchLen := 0;
    Exit(EBatchCorrupted.Create('too short'));
  end;
  Move(ParaData[0], ParaSeq, 8);
  Move(ParaData[8], ParaBatchLen, 4);
  if ParaBatchLen < 0 then
    Exit(EBatchCorrupted.Create('invalid records length'));
  Result := nil;
end;

function WriteBatchesWithHeader(ParaW: IWriter; ParaBatches: TArray<TBatch>; ParaSeq: UInt64): Exception;
var
  vTotalLen: Integer;
  vB: TBatch;
  vHeader: TBytes;
begin
  vTotalLen := 0;
  for vB in ParaBatches do
    Inc(vTotalLen, vB.Len);
    
  SetLength(vHeader, BATCH_HEADER_LEN);
  EncodeBatchHeader(vHeader, ParaSeq, vTotalLen);
  
  try
    ParaW.Write(vHeader);
    for vB in ParaBatches do
      ParaW.Write(vB.Data);
    Result := nil;
  except
    on E: Exception do Result := E;
  end;
end;

end.
