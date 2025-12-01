// Copyright (c) 2016, Suryandaru Triandana <syndtr@gmail.com>
// All rights reserved.
//
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
unit Common.Db.XLevelDB.DB.Transaction;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Threading,
  System.Generics.Collections,
  GoToDelphi.Helpers.TChannel,
  Common.Db.XLevelDB.Iterator,
  Common.Db.XLevelDB.MemDB,
  Common.Db.XLevelDB.Opt,
  Common.Db.XLevelDB.Util,
  Common.Db.XLevelDB.Errors,
  Common.Db.XLevelDB.DB.State,
  Common.Db.XLevelDB.DB.Compaction,
  Common.Db.XLevelDB.Key,
  Common.Db.XLevelDB.Batch,
  Common.Db.XLevelDB.Session,
  Common.Db.XLevelDB.DB;

type
  EErrTransactionDone = class(ELevelDBError);

  // Transaction is the transaction handle.
  TTransaction = class
  private
    FDb: TDB;
    FLk: TRTLCriticalSection;
    FSeq: UInt64;
    FMem: TMemDBWrapper;
    FTables: TFileTableList;
    FIkScratch: TBytes;
    FRec: TSessionRecord;
    FStats: TCStatStaging;
    FClosed: Boolean;
    function Flush: Exception;
    function PutInternal(AKt: TKeyType; AKey, AValue: TBytes): Exception;
    procedure SetDone;
    procedure DiscardInternal;
  public
    constructor Create(ADB: TDB);
    destructor Destroy; override;
    // Get gets the value for the given key. It returns ErrNotFound if the
    // DB does not contains the key.
    //
    // The returned slice is its own copy, it is safe to modify the contents
    // of the returned slice.
    // It is safe to modify the contents of the argument after Get returns.
    function Get(AKey: TBytes; ARo: TReadOptions): TPair<TBytes, Exception>;
    // Has returns true if the DB does contains the given key.
    //
    // It is safe to modify the contents of the argument after Has returns.
    function Has(AKey: TBytes; ARo: TReadOptions): TPair<Boolean, Exception>;
    // NewIterator returns an iterator for the latest snapshot of the transaction.
    // The returned iterator is not safe for concurrent use, but it is safe to use
    // multiple iterators concurrently, with each in a dedicated goroutine.
    // It is also safe to use an iterator concurrently while writes to the
    // transaction. The resultant key/value pairs are guaranteed to be consistent.
    //
    // Slice allows slicing the iterator to only contains keys in the given
    // range. A nil Range.Start is treated as a key before all keys in the
    // DB. And a nil Range.Limit is treated as a key after all keys in
    // the DB.
    //
    // The iterator must be released after use, by calling Release method.
    //
    // Also read Iterator documentation of the leveldb/iterator package.
    function NewIterator(ASlice: TRange; ARo: TReadOptions): IIterator;
    // Put sets the value for the given key. It overwrites any previous value
    // for that key; a DB is not a multi-map.
    // Please note that the transaction is not compacted until committed, so if you
    // writes 10 same keys, then those 10 same keys are in the transaction.
    //
    // It is safe to modify the contents of the arguments after Put returns.
    procedure Put(AKey, AValue: TBytes; AWo: TWriteOptions);
    // Delete deletes the value for the given key.
    // Please note that the transaction is not compacted until committed, so if you
    // writes 10 same keys, then those 10 same keys are in the transaction.
    //
    // It is safe to modify the contents of the arguments after Delete returns.
    procedure Delete(AKey: TBytes; AWo: TWriteOptions);
    // Write apply the given batch to the transaction. The batch will be applied
    // sequentially.
    // Please note that the transaction is not compacted until committed, so if you
    // writes 10 same keys, then those 10 same keys are in the transaction.
    //
    // It is safe to modify the contents of the arguments after Write returns.
    procedure Write(AB: TBatch; AWo: TWriteOptions);
    // Commit commits the transaction. If error is not nil, then the transaction is
    // not committed, it can then either be retried or discarded.
    //
    // Other methods should not be called after transaction has been committed.
    function Commit: Exception;
    // Discard discards the transaction.
    //
    // Other methods should not be called after transaction has been discarded.
    procedure Discard;
  end;

implementation

{ TTransaction }

constructor TTransaction.Create(ADB: TDB);
begin
  inherited Create;
  FDb := ADB;
  FSeq := FDb.GetSeq;
  FMem := FDb.MpoolGet(0);
  FMem.Incref;
  FTables := TFileTableList.Create;
  FRec := TSessionRecord.Create;
end;

destructor TTransaction.Destroy;
begin
  if not FClosed then
    Discard;
  FTables.Free;
  FRec.Free;
  inherited;
end;

function TTransaction.Get(AKey: TBytes; ARo: TReadOptions): TPair<TBytes, Exception>;
begin
  EnterCriticalSection(FLk);
  try
    if FClosed then
      raise EErrTransactionDone.Create('');
    Result := FDb.Get(FMem.DB, FTables, AKey, FSeq, ARo);
  finally
    LeaveCriticalSection(FLk);
  end;
end;

function TTransaction.Has(AKey: TBytes; ARo: TReadOptions): TPair<Boolean, Exception>;
begin
  EnterCriticalSection(FLk);
  try
    if FClosed then
      raise EErrTransactionDone.Create('');
    Result := FDb.Has(FMem.DB, FTables, AKey, FSeq, ARo);
  finally
    LeaveCriticalSection(FLk);
  end;
end;

function TTransaction.NewIterator(ASlice: TRange; ARo: TReadOptions): IIterator;
begin
  EnterCriticalSection(FLk);
  try
    if FClosed then
      Exit(TEmptyIterator.Create(EErrTransactionDone.Create('')));
    FMem.Incref;
    Result := FDb.NewIterator(FMem, FTables, FSeq, ASlice, ARo);
  finally
    LeaveCriticalSection(FLk);
  end;
end;

function TTransaction.Flush: Exception;
var
  vIter: IIterator;
  vT: TTable;
  vN: Integer;
  vErr: Exception;
begin
  Result := nil;
  if FMem.DB.Len <> 0 then
  begin
    FStats.StartTimer;
    vIter := FMem.DB.NewIterator(nil);
    try
      vT, vN, vErr := FDb.FS.Tops.CreateFrom(vIter);
      if vErr <> nil then
        Exit(vErr);
    finally
      vIter.Release;
    end;
    FStats.StopTimer;

    if FMem.GetRef = 1 then
      FMem.DB.Reset
    else
    begin
      FMem.Decref;
      FMem := FDb.MpoolGet(0);
      FMem.Incref;
    end;
    FTables.Add(vT);
    FRec.AddTableFile(0, vT);
    FStats.Write := FStats.Write + vT.Size;
    FDb.LogF('transaction@flush created L0@%d N·%d S·%s %q:%q', [vT.Fd.Num, vN, ShortenB(vT.Size), vT.Imin, vT.Imax]);
  end;
end;

function TTransaction.PutInternal(AKt: TKeyType; AKey, AValue: TBytes): Exception;
begin
  FIkScratch := MakeInternalKey(FIkScratch, AKey, FSeq + 1, AKt);
  if FMem.DB.Free < Length(FIkScratch) + Length(AValue) then
  begin
    Result := Flush;
    if Result <> nil then
      Exit;
  end;
  Result := FMem.DB.Put(FIkScratch, AValue);
  if Result = nil then
    Inc(FSeq);
end;

procedure TTransaction.Put(AKey, AValue: TBytes; AWo: TWriteOptions);
var
  vErr: Exception;
begin
  EnterCriticalSection(FLk);
  try
    if FClosed then
      raise EErrTransactionDone.Create('');
    vErr := PutInternal(KeyTypeVal, AKey, AValue);
    if vErr <> nil then
      raise vErr;
  finally
    LeaveCriticalSection(FLk);
  end;
end;

procedure TTransaction.Delete(AKey: TBytes; AWo: TWriteOptions);
var
  vErr: Exception;
begin
  EnterCriticalSection(FLk);
  try
    if FClosed then
      raise EErrTransactionDone.Create('');
    vErr := PutInternal(KeyTypeDel, AKey, nil);
    if vErr <> nil then
      raise vErr;
  finally
    LeaveCriticalSection(FLk);
  end;
end;

procedure TTransaction.Write(AB: TBatch; AWo: TWriteOptions);
var
  vErr: Exception;
begin
  if (AB = nil) or (AB.Len = 0) then
    Exit;

  EnterCriticalSection(FLk);
  try
    if FClosed then
      raise EErrTransactionDone.Create('');
    vErr := AB.ReplayInternal(
      function(AI: Integer; AKt: TKeyType; AK, AV: TBytes): Exception
      begin
        Result := PutInternal(AKt, AK, AV);
      end);
    if vErr <> nil then
      raise vErr;
  finally
    LeaveCriticalSection(FLk);
  end;
end;

procedure TTransaction.SetDone;
begin
  FClosed := True;
  FDb.tr := nil;
  FMem.Decref;
  FDb.WriteLockC.Receive(nil);
end;

function TTransaction.Commit: Exception;
var
  vErr, vCerr: Exception;
  vRetry: Integer;
begin
  vErr := FDb.Ok;
  if vErr <> nil then
    Exit(vErr);

  EnterCriticalSection(FLk);
  try
    if FClosed then
      raise EErrTransactionDone.Create('');
    vErr := Flush;
    if vErr <> nil then
      Exit(vErr);

    if FTables.Count <> 0 then
    begin
      FRec.SetSeqNum(FSeq);
      EnterCriticalSection(FDb.CompCommitLk);
      try
        FStats.StartTimer;
        vCerr := nil;
        for vRetry := 0 to 2 do
        begin
          vCerr := FDb.S.Commit(FRec);
          if vCerr <> nil then
          begin
            FDb.LogF('transaction@commit error R·%d %q', [vRetry, vCerr.Message]);
            if FDb.CloseC.TryReceive(nil, 1000) then
            begin
              FDb.LogF('transaction@commit exiting');
              Exit(vCerr);
            end;
          end
          else
          begin
            FDb.SetSeq(FSeq);
            Break;
          end;
        end;
        FStats.StopTimer;
        if vCerr <> nil then
          Exit(vCerr);

        FDb.CompStats.AddStat(0, FStats);
        FDb.CompTrigger(FDb.TCompCmdC);
      finally
        LeaveCriticalSection(FDb.CompCommitLk);
      end;
      FDb.WaitCompaction;
    end;
    SetDone;
    Result := nil;
  finally
    LeaveCriticalSection(FLk);
  end;
end;

procedure TTransaction.DiscardInternal;
var
  vT: TTable;
  vErr: Exception;
begin
  for vT in FTables do
  begin
    FDb.LogF('transaction@discard @%d', [vT.Fd.Num]);
    vErr := FDb.S.Stor.Remove(vT.Fd);
    if vErr = nil then
      FDb.S.ReuseFileNum(vT.Fd.Num);
  end;
end;

procedure TTransaction.Discard;
begin
  EnterCriticalSection(FLk);
  try
    if not FClosed then
    begin
      DiscardInternal;
      SetDone;
    end;
  finally
    LeaveCriticalSection(FLk);
  end;
end;

end.
