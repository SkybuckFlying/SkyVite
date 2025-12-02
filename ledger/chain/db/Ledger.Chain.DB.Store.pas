unit Ledger.Chain.Db.Store;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  Common.Types,
  Common.Db.MemDB,
  Common.Db.XLevelDB,
  Common.Db.XLevelDB.DB,
  Common.Db.XLevelDB.Batch,
  Common.Db.XLevelDB.Util,
  Interfaces.Chain,
  Interfaces.Core,
  Ledger.Chain.Db.UnconfirmedBatch;

type
  TStore = class
  private
    mId: THash;
    mName: string;
    mMemDbMu: TRTLCriticalSection;
    mMemDb: TMemDB;
    mSnapshotBatch: TBatch;
    mFlushingBatch: TBatch;
    mUnconfirmedBatchs: TUnconfirmedBatchs;
    mDbDir: string;
    mDb: TDB;
    mAfterRecoverFuncs: TList<TProc>;
    procedure PutMemDb(ParaBatch: TBatch);
    procedure ReleaseFlushingBatch; // Helper procedure
  public
    // from Store.pas
    constructor Create(const ParaDataDir, ParaName: string);
    constructor CreateWithDb(const ParaDataDir, ParaName: string; ParaDiskStore: TDB);
    destructor Destroy; override;
    procedure CompactRange(ParaRange: TRange);
    function NewBatch: TBatch;
    function Get(ParaKey: TBytes): TPair<TBytes, Exception>;
    function GetOriginal(ParaKey: TBytes): TPair<TBytes, Exception>;
    function Has(ParaKey: TBytes): TPair<Boolean, Exception>;
    function NewIterator(ParaSlice: TRange): IStorageIterator;
    procedure Close;
    procedure Clean;
    procedure RegisterAfterRecover(ParaFunc: TProc);
    function GetStatus: TArray<IDBStatus>;
    function Store: TDB;

    // from Flush.pas
    function Id: THash;
    procedure Prepare;
    procedure CancelPrepare;
    function RedoLog: TBytes;
    function Commit: HResult;
    procedure AfterCommit;
    procedure BeforeRecover(const ARedoLog: TBytes);
    procedure AfterRecover;
    function PatchRedoLog(const ARedoLog: TBytes): HResult;

    // from Rollback.pas
    procedure RollbackAccountBlocks(ParaRollbackBatch: TLevelDBBatch; ParaAccountBlocks: TArray<TAccountBlock>);
    procedure RollbackAccountBlockByHash(ParaRollbackBatch: TLevelDBBatch; ParaBlockHashList: TArray<TBytes>);
    procedure RollbackSnapshot(ParaRollbackBatch: TLevelDBBatch);

    // from Write.pas
    procedure WriteDirectly(ParaBatch: TLevelDBBatch);
    procedure WriteAccountBlock(ParaBatch: TLevelDBBatch; ParaBlock: TAccountBlock);
    procedure WriteAccountBlockByHash(ParaBatch: TLevelDBBatch; ParaBlockHash: TBytes);
    procedure WriteSnapshot(ParaSnapshotBatch: TLevelDBBatch; ParaAccountBlocks: TArray<TAccountBlock>);
    procedure WriteSnapshotByHash(ParaSnapshotBatch: TLevelDBBatch; ParaBlockHashList: TArray<TBytes>);
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  Crypto,
  Common.Db,
  Common.Db.XLevelDB.MemDB;

{ TStore }

// from Store.pas

constructor TStore.Create(const ParaDataDir, ParaName: string);
var
  vDiskStore: TDB;
  vPair: TPair<TDB, Exception>;
begin
  vPair := OpenFile(ParaDataDir, nil);
  if vPair.Value <> nil then
    raise vPair.Value;
  vDiskStore := vPair.Key;
  CreateWithDb(ParaDataDir, ParaName, vDiskStore);
end;

constructor TStore.CreateWithDb(const ParaDataDir, ParaName: string; ParaDiskStore: TDB);
var
  vHash: THash;
begin
  vHash := THash.FromBytes(THash.Sum256(TEncoding.UTF8.GetBytes(ParaName)));
  mId := vHash;
  mName := ParaName;
  mMemDb := TMemDB.Create;
  mUnconfirmedBatchs := TUnconfirmedBatchs.Create;
  mDbDir := ParaDataDir;
  mDb := ParaDiskStore;
  mSnapshotBatch := NewBatch;
  mAfterRecoverFuncs := TList<TProc>.Create;
  InitializeCriticalSection(mMemDbMu);
end;

destructor TStore.Destroy;
begin
  mMemDb.Free;
  mSnapshotBatch.Free;
  if mFlushingBatch <> nil then
    mFlushingBatch.Free;
  mUnconfirmedBatchs.Free;
  if mDb <> nil then
    mDb.Close;
  mAfterRecoverFuncs.Free;
  DeleteCriticalSection(mMemDbMu);
  inherited;
end;

procedure TStore.CompactRange(ParaRange: TRange);
begin
  mDb.CompactRange(ParaRange);
end;

function TStore.NewBatch: TBatch;
begin
  Result := TBatch.Create;
end;

function TStore.Get(ParaKey: TBytes): TPair<TBytes, Exception>;
var
  vMemDb: TMemDB;
  vSeq: UInt64;
  vPair: TPair<TBytes, Exception>;
begin
  EnterCriticalSection(mMemDbMu);
  try
    vMemDb := mMemDb;
    vSeq := mMemDb.GetSeq;
  finally
    LeaveCriticalSection(mMemDbMu);
  end;
  vPair := mDb.Get2(ParaKey, nil, vMemDb, vSeq);
  if (vPair.Value <> nil) and (vPair.Value is ENotFound) then
  begin
    Result := TPair<TBytes, Exception>.Create(nil, nil);
    Exit;
  end;
  Result := vPair;
end;

function TStore.GetOriginal(ParaKey: TBytes): TPair<TBytes, Exception>;
var
  vMemDb: TMemDB;
  vSeq: UInt64;
begin
  EnterCriticalSection(mMemDbMu);
  try
    vMemDb := mMemDb;
    vSeq := mMemDb.GetSeq;
  finally
    LeaveCriticalSection(mMemDbMu);
  end;
  Result := mDb.Get2(ParaKey, nil, vMemDb, vSeq);
end;

function TStore.Has(ParaKey: TBytes): TPair<Boolean, Exception>;
var
  vMemDb: TMemDB;
  vSeq: UInt64;
  vPair: TPair<TBytes, Exception>;
begin
  EnterCriticalSection(mMemDbMu);
  try
    vMemDb := mMemDb;
    vSeq := mMemDb.GetSeq;
  finally
    LeaveCriticalSection(mMemDbMu);
  end;
  vPair := mDb.Get2(ParaKey, nil, vMemDb, vSeq);
  if vPair.Value <> nil then
  begin
    if vPair.Value is ENotFound then
      Result := TPair<Boolean, Exception>.Create(False, nil)
    else
      Result := TPair<Boolean, Exception>.Create(False, vPair.Value);
  end
  else
    Result := TPair<Boolean, Exception>.Create(True, nil);
end;

function TStore.NewIterator(ParaSlice: TRange): IStorageIterator;
var
  vMemDb: TMemDB;
  vSeq: UInt64;
begin
  EnterCriticalSection(mMemDbMu);
  try
    vMemDb := mMemDb;
    vSeq := mMemDb.GetSeq;
  finally
    LeaveCriticalSection(mMemDbMu);
  end;
  Result := mDb.NewIterator2(ParaSlice, nil, vMemDb, vSeq);
end;

procedure TStore.Close;
begin
  mMemDb := nil;
  mDb.Close;
end;

procedure TStore.Clean;
begin
  Close;
  if TDirectory.Exists(mDbDir) then
    TDirectory.Delete(mDbDir, True);
  mDb := nil;
end;

procedure TStore.RegisterAfterRecover(ParaFunc: TProc);
begin
  mAfterRecoverFuncs.Add(ParaFunc);
end;

function TStore.GetStatus: TArray<IDBStatus>;
var
  vCount, vSize: Integer;
  vStats: TDBStats;
  vStatus: string;
  vStatusList: TArray<IDBStatus>;
begin
  vCount := 0;
  vSize := 0;
  if mMemDb <> nil then
  begin
    vCount := vCount + mMemDb.Len;
    vSize := vSize + mMemDb.Size;
  end;
  if mSnapshotBatch <> nil then
  begin
    vCount := vCount + mSnapshotBatch.Len;
    vSize := vSize + mSnapshotBatch.Size;
  end;
  if mFlushingBatch <> nil then
  begin
    vCount := vCount + mFlushingBatch.Len;
    vSize := vSize + mSnapshotBatch.Size;
  end;

  mDb.Stats(vStats);
  // vStatus := TJson.Format(vStats); // TDBStats is not a JSON object

  SetLength(vStatusList, 2);
  vStatusList[0] := TDBStatus.Create('mem', vCount, vSize, '');
  vStatusList[1] := TDBStatus.Create('levelDB', 0, 0, ''); // Status string is complex
  Result := vStatusList;
end;

procedure TStore.PutMemDb(ParaBatch: TBatch);
begin
  ParaBatch.Replay(mMemDb);
end;

function TStore.Store: TDB;
begin
  Result := mDb;
end;

// from Flush.pas

function TStore.Id: THash;
begin
  Result := Self.mId;
end;

procedure TStore.Prepare;
begin
  if Self.mFlushingBatch <> nil then
    raise Exception.Create('prepare repeatedly');
  Self.mFlushingBatch := Self.mSnapshotBatch;
  Self.mSnapshotBatch := Self.NewBatch;
end;

procedure TStore.CancelPrepare;
var
  vCurrentSnapshotBatch: TBatch;
begin
  vCurrentSnapshotBatch := Self.mSnapshotBatch;
  Self.mSnapshotBatch := Self.NewBatch;
  Self.mSnapshotBatch.Append(Self.mFlushingBatch);
  Self.mSnapshotBatch.Append(vCurrentSnapshotBatch);
  Self.ReleaseFlushingBatch;
end;

function TStore.RedoLog: TBytes;
begin
  Result := Self.mFlushingBatch.Dump;
end;

function TStore.Commit: HResult;
begin
  Result := Self.mDb.Write(Self.mFlushingBatch, nil);
end;

procedure TStore.AfterCommit;
var
  i: Integer;
  batch: TBatch;
begin
  Self.ReleaseFlushingBatch;
  EnterCriticalSection(Self.mMemDbMu);
  try
    Self.mMemDb := TMemDB.Create;
    Self.mSnapshotBatch.Replay(Self.mMemDb);
    Self.mUnconfirmedBatchs.All(procedure(batch: TBatch)
      begin
        batch.Replay(Self.mMemDb);
      end);
  finally
    LeaveCriticalSection(Self.mMemDbMu);
  end;
end;

procedure TStore.BeforeRecover(const ARedoLog: TBytes);
begin
  // No-op
end;

procedure TStore.AfterRecover;
var
  F: TProc;
begin
  for F in Self.mAfterRecoverFuncs do
    F();
end;

function TStore.PatchRedoLog(const ARedoLog: TBytes): HResult;
var
  vBatch: TBatch;
begin
  vBatch := TBatch.Create;
  try
    vBatch.Load(ARedoLog);
    Result := Self.mDb.Write(vBatch, nil);
  finally
    vBatch.Free;
  end;
end;

// from Rollback.pas

procedure TStore.RollbackAccountBlocks(ParaRollbackBatch: TLevelDBBatch; ParaAccountBlocks: TArray<TAccountBlock>);
var
  vBlock: TAccountBlock;
begin
  for vBlock in ParaAccountBlocks do
  begin
    mUnconfirmedBatchs.Remove(vBlock.Hash);
  end;
  PutMemDb(ParaRollbackBatch);
end;

procedure TStore.RollbackAccountBlockByHash(ParaRollbackBatch: TLevelDBBatch; ParaBlockHashList: TArray<TBytes>);
var
  vBlockHash: TBytes;
begin
  for vBlockHash in ParaBlockHashList do
  begin
    mUnconfirmedBatchs.Remove(vBlockHash);
  end;
  PutMemDb(ParaRollbackBatch);
end;

procedure TStore.RollbackSnapshot(ParaRollbackBatch: TLevelDBBatch);
begin
  PutMemDb(ParaRollbackBatch);
  mUnconfirmedBatchs.All(procedure(ParaBatch: TLevelDBBatch)
    begin
      mSnapshotBatch.Append(ParaBatch);
    end);
  mSnapshotBatch.Append(ParaRollbackBatch);
  mUnconfirmedBatchs.Clear;
end;

// from Write.pas

procedure TStore.WriteDirectly(ParaBatch: TLevelDBBatch);
begin
  PutMemDb(ParaBatch);
  mSnapshotBatch.Append(ParaBatch);
end;

procedure TStore.WriteAccountBlock(ParaBatch: TLevelDBBatch; ParaBlock: TAccountBlock);
begin
  WriteAccountBlockByHash(ParaBatch, ParaBlock.Hash);
end;

procedure TStore.WriteAccountBlockByHash(ParaBatch: TLevelDBBatch; ParaBlockHash: TBytes);
begin
  PutMemDb(ParaBatch);
  mUnconfirmedBatchs.Put(ParaBlockHash, ParaBatch);
end;

procedure TStore.WriteSnapshot(ParaSnapshotBatch: TLevelDBBatch; ParaAccountBlocks: TArray<TAccountBlock>);
var
  vAccountBlockHashList: TArray<TBytes>;
  i: Integer;
  vAccountBlock: TAccountBlock;
begin
  SetLength(vAccountBlockHashList, Length(ParaAccountBlocks));
  for i := 0 to High(ParaAccountBlocks) do
  begin
    vAccountBlock := ParaAccountBlocks[i];
    vAccountBlockHashList[i] := vAccountBlock.Hash;
  end;
  WriteSnapshotByHash(ParaSnapshotBatch, vAccountBlockHashList);
end;

procedure TStore.WriteSnapshotByHash(ParaSnapshotBatch: TLevelDBBatch; ParaBlockHashList: TArray<TBytes>);
var
  vBlockHash: TBytes;
  vPair: TPair<TLevelDBBatch, Boolean>;
  vBatch: TLevelDBBatch;
begin
  PutMemDb(ParaSnapshotBatch);
  for vBlockHash in ParaBlockHashList do
  begin
    vPair := mUnconfirmedBatchs.Get(vBlockHash);
    if not vPair.Value then
    begin
      raise Exception.CreateFmt('store.WriteSnapshot failed, account block hash %s batch is not existed', [vBlockHash.ToString]);
    end;
    vBatch := vPair.Key;
    mSnapshotBatch.Append(vBatch);
    mUnconfirmedBatchs.Remove(vBlockHash);
  end;
  mSnapshotBatch.Append(ParaSnapshotBatch);
end;


procedure TStore.ReleaseFlushingBatch;
begin
  if mFlushingBatch <> nil then
  begin
    mFlushingBatch.Free;
    mFlushingBatch := nil;
  end;
end;


end.
