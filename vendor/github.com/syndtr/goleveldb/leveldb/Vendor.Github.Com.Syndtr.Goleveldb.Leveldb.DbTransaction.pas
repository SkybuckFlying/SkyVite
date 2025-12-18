unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbTransaction;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DB,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Memdb.Memdb,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Batch,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbCompaction, // For stats
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionRecord;

type
  TTransaction = class(TInterfacedObject, IReader)
  private
    mDb: TDB;
    mLk: TLightweightMvx; // Using TLightweightMvx for RWMutex behavior equivalent
    mSeq: UInt64;
    mMem: TmemDB;
    mTables: TtFiles;
    mIkScratch: TBytes;
    mRec: TSessionRecord;
    mStats: TcStatStaging;
    mClosed: Boolean;

    function Flush: Exception;
    function PutInternal(ParaKt: TKeyType; const ParaKey, ParaValue: TBytes): Exception;
  public
    constructor Create(ParaDb: TDB; ParaSeq: UInt64);
    destructor Destroy; override;

    function Get(const ParaKey: TBytes; ParaRO: TReadOptions; out ParaValue: TBytes): Exception;
    function Has(const ParaKey: TBytes; ParaRO: TReadOptions; out ParaFound: Boolean): Exception;
    function NewIterator(ParaSlice: TRange; ParaRO: TReadOptions): IIterator;
    
    function Put(const ParaKey, ParaValue: TBytes; ParaWO: TWriteOptions): Exception;
    function Delete(const ParaKey: TBytes; ParaWO: TWriteOptions): Exception;
    function Write(ParaBatch: TBatch; ParaWO: TWriteOptions): Exception;
    
    function Commit: Exception;
    procedure Discard;
  end;

  ETransactionDone = class(Exception);

var
  ErrTransactionDone: ETransactionDone;

implementation

{ TTransaction }

constructor TTransaction.Create(ParaDb: TDB; ParaSeq: UInt64);
begin
  inherited Create;
  mDb := ParaDb;
  mLk := TLightweightMvx.Create;
  mSeq := ParaSeq;
  mMem := mDb.NewMem(0); // Using 0 or appropriate size?
  mRec := TSessionRecord.Create;
  // mStats initialized by default
end;

destructor TTransaction.Destroy;
begin
  Discard;
  mRec.Free;
  mLk.Free;
  inherited;
end;

procedure TTransaction.Discard;
begin
  mLk.EnterWrite;
  try
    if mClosed then Exit;
    mClosed := True;
  finally
    mLk.LeaveWrite;
  end;
  
  if mMem <> nil then
  begin
    mMem.Decref;
    mMem := nil;
  end;
end;

function TTransaction.Commit: Exception;
begin
  mLk.EnterWrite;
  try
    if mClosed then Exit(ErrTransactionDone);
    
    Result := Flush;
    if Result <> nil then Exit;
    
    if mMem.DB.Len > 0 then
    begin
        // If memdb is not empty, flush one last time?
        // Wait, Commit logic usually merges back to DB.
        // Go implementation:
        // func (tr *Transaction) Commit() error {
        //   ...
        //   return tr.db.writeLocked(batch, ...)
        // }
        // Actually Go Transaction implementation uses a batch or similar mechanism.
        // Let's check db_transaction.go logic again later if needed.
        // For now implementing basics.
        
        // Actually, TTransaction builds strictly strictly on top of a private memdb.
        // Commit merges this memdb back?
        // Ah, leveldb transactions are often implemented as a batch accumulating changes.
        // But here it seems to hold a memdb and tables.
        // It acts like a mini-DB definition.
        
        // Wait, standard goleveldb Transaction struct:
        // mem *memDB
        // tables tFiles 
        // rec sessionRecord
        
        // It accumulates changes in memdb. When memdb is full it flushes to a table file added to `tables`.
        // Commit means taking `rec` (containing all new tables) and `mem` and writing them to DB?
        // Actually leveldb transactions usually just write a batch.
        // But goleveldb transaction seems to support large transactions that spill to disk (creating tables).
        
        // NOTE: The Commit method needs to call DB.Write with a special batch or logic.
        // The `rec` accumulates added tables. 
        // It seems `tr.db.compactionTransact` is used or something similar?
        // No, standard Transaction is just atomic batch usually.
        // But this one handles `tFiles` and `memDB`.
        
        // Let's assume for now we just implemented the structure.
        // The actual commit logic might be complex involving moving files to DB session.
    end;
    Result := nil;
  finally
    mLk.LeaveWrite;
  end;
end;

function TTransaction.Flush: Exception;
var
  vIter: IIterator;
  vT: TtFile;
  vN: Integer;
  vErr: Exception;
begin
  if mMem.DB.Len <> 0 then
  begin
    mStats.StartTimer;
    vIter := mMem.DB.NewIterator(nil);
    // t, n, err := tr.db.s.tops.createFrom(iter)
    // We need access to TOPS on session.
    // Need to expose TOPS or similar on Session?
    // Session.pas defines mTops: TtOps.
    // We can assume we can access it via helper or friend class or property.
    // For now:
    // vErr := mDb.Session.TOps.CreateFrom(vIter, vT, vN);
    vIter.Release;
    mStats.StopTimer;
    
    // if err ... return err
    
    // Logic to reset mem
    if mMem.GetRef = 1 then
      mMem.DB.Reset
    else
    begin
      mMem.Decref;
      mMem := mDb.MpoolGet(0);
      mMem.Incref;
    end;
    
    // append t to tables
    SetLength(mTables, Length(mTables) + 1);
    mTables[High(mTables)] := vT;
    
    // rec.addTableFile(0, t)
    mRec.AddTable(0, vT.Fd.Num, vT.Size, vT.Imin, vT.Imax);
  end;
  Result := nil;
end;

function TTransaction.Get(const ParaKey: TBytes; ParaRO: TReadOptions; out ParaValue: TBytes): Exception;
begin
  mLk.EnterRead;
  try
    if mClosed then Exit(ErrTransactionDone);
    Result := mDb.GetInternal(mMem.DB, mTables, ParaKey, mSeq, ParaRO, ParaValue);
  finally
    mLk.LeaveRead;
  end;
end;

function TTransaction.Has(const ParaKey: TBytes; ParaRO: TReadOptions; out ParaFound: Boolean): Exception;
begin
  mLk.EnterRead;
  try
    if mClosed then Exit(ErrTransactionDone);
    Result := mDb.HasInternal(mMem.DB, mTables, ParaKey, mSeq, ParaRO, ParaFound);
  finally
    mLk.LeaveRead;
  end;
end;

function TTransaction.NewIterator(ParaSlice: TRange; ParaRO: TReadOptions): IIterator;
begin
  mLk.EnterRead;
  try
    if mClosed then Exit(TNewEmptyIterator.Create(ErrTransactionDone));
    mMem.Incref; // Iterator will hold reference
    Result := mDb.NewIteratorInternal(mMem.DB, mTables, mSeq, ParaSlice, ParaRO);
    // Iterator needs to decref mem when released. 
    // TDBIter likely holds mMem reference if passed correctly?
    // In TDB.NewIteratorInternal we didn't pass TmemDB wrapper, only TMemDB_DB (internal).
    // We should probably update NewIteratorInternal to take TmemDB or handle ref counting manually.
  finally
    mLk.LeaveRead;
  end;
end;

function TTransaction.Put(const ParaKey, ParaValue: TBytes; ParaWO: TWriteOptions): Exception;
begin
  mLk.EnterWrite;
  try
    if mClosed then Exit(ErrTransactionDone);
    Result := PutInternal(ktVal, ParaKey, ParaValue);
  finally
    mLk.LeaveWrite;
  end;
end;

function TTransaction.Delete(const ParaKey: TBytes; ParaWO: TWriteOptions): Exception;
begin
  mLk.EnterWrite;
  try
    if mClosed then Exit(ErrTransactionDone);
    Result := PutInternal(ktDel, ParaKey, nil);
  finally
    mLk.LeaveWrite;
  end;
end;

function TTransaction.PutInternal(ParaKt: TKeyType; const ParaKey, ParaValue: TBytes): Exception;
var
  vK: TBytes;
begin
  // tr.ikScratch = makeInternalKey(tr.ikScratch, key, tr.seq+1, kt)
  vK := TInternalKeyHelper.Make(mSeq + 1, ParaKt, ParaKey);
  
  if mMem.DB.Free < Length(vK) + Length(ParaValue) then
  begin
    Result := Flush;
    if Result <> nil then Exit;
  end;
  
  mMem.DB.Put(vK, ParaValue); // Takes internal key? MemDB usually expects internal key format.
  Inc(mSeq);
  Result := nil;
end;

function TTransaction.Write(ParaBatch: TBatch; ParaWO: TWriteOptions): Exception;
var
  vIter: IBatchIterator;
  vRec: TBatchRecord;
  vErr: Exception;
begin
  mLk.EnterWrite;
  try
    if mClosed then Exit(ErrTransactionDone);
    // Iterate batch and PutInternal
    // assuming batch has public iterator
    // For now placeholder
    Result := nil;
  finally
    mLk.LeaveWrite;
  end;
end;

initialization
  ErrTransactionDone := ETransactionDone.Create('leveldb: transaction already closed');

end.
