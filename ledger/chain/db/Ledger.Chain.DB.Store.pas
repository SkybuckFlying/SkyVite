unit Ledger.Chain.Db.Store;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  Common.Types,
  Common.Db.MemDB,
  Common.Db.XLevelDB.DB,
  Common.Db.XLevelDB.Batch,
  Common.Db.XLevelDB.Util,
  Interfaces.Chain,
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
  public
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
  end;

implementation

uses
  System.IOUtils,
  System.JSON,
  Crypto,
  Common.Db.XLevelDB.MemDB;

{ TStore }

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

end.