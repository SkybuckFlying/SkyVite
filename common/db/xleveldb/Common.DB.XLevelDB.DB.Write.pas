unit Common.Db.XLevelDb.Db_Write;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Threading,
  System.Generics.Collections,
  Common.Db.XLevelDb.MemDB,
  Common.Db.XLevelDb.Opt,
  Common.Db.XLevelDb.Util,
  Common.Db.XLevelDb.Errors,
  Common.Db.XLevelDb.DB,
  Common.Db.XLevelDb.Key,
  Common.Db.XLevelDb.Batch,
  Common.Db.XLevelDb.Interfaces,
  Common.Db.XLevelDb.Session;

type
  TWriteMerge = record
    Sync: Boolean;
    Batch: TBatch;
    KeyType: TKeyType;
    Key, Value: TBytes;
  end;

  TDB = class partial
  private
    procedure UnlockWrite(AOverflow: Boolean; AMerged: Integer; AErr: Exception);
    function WriteJournal(const ABatches: TArray<TBatch>; ASeq: UInt64; ASync: Boolean): Exception;
    function RotateMem(AN: Integer; AWait: Boolean): TPair<TMemDB, Exception>;
    function Flush(AN: Integer): TPair<TMemDB, Integer>;
    function WriteLocked(ABatch, AOurBatch: TBatch; AMerge, ASync: Boolean): Exception;
    function PutRec(AKt: TKeyType; const AKey, AValue: TBytes; AWo: TWriteOptions): Exception;
  public
    // Write apply the given batch to the DB. The batch records will be applied
    // sequentially. Write might be used concurrently, when used concurrently and
    // batch is small enough, write will try to merge the batches. Set NoWriteMerge
    // option to true to disable write merge.
    //
    // It is safe to modify the contents of the arguments after Write returns but
    // not before. Write will not modify content of the batch.
    function Write(ABatch: TBatch; AWo: TWriteOptions): Exception;

    // Put sets the value for the given key. It overwrites any previous value
    // for that key; a DB is not a multi-map. Write merge also applies for Put, see
    // Write.
    //
    // It is safe to modify the contents of the arguments after Put returns but not
    // before.
    function Put(const AKey, AValue: TBytes; AWo: TWriteOptions): Exception;

    // Delete deletes the value for the given key. Delete will not returns error if
    // key doesn't exist. Write merge also applies for Delete, see Write.
    //
    // It is safe to modify the contents of the arguments after Delete returns but
    // not before.
    function Delete(const AKey: TBytes; AWo: TWriteOptions): Exception;

    // CompactRange compacts the underlying DB for the given key range.
    // In particular, deleted and overwritten versions are discarded,
    // and the data is rearranged to reduce the cost of operations
    // needed to access the data. This operation should typically only
    // be invoked by users who understand the underlying implementation.
    //
    // A nil Range.Start is treated as a key before all keys in the DB.
    // And a nil Range.Limit is treated as a key after all keys in the DB.
    // Therefore if both is nil then it will compact entire DB.
    function CompactRange(AR: TRange): Exception;

    // SetReadOnly makes DB read-only. It will stay read-only until reopened.
    function SetReadOnly: Exception;
  end;

function IsMemOverlaps(AIcmp: IComparer; AMem: TMemDB; const AMin, AMax: TBytes): Boolean;

implementation

uses
  System.DateUtils,
  System.Math,
  GoToDelphi.Helpers.TChannel,
  Common.Db.XLevelDb.DB_Compaction,
  Common.Db.XLevelDb.DB_State;

{ TDB }

function TDB.WriteJournal(const ABatches: TArray<TBatch>; ASeq: UInt64; ASync: Boolean): Exception;
var
  vWr: IWriter;
begin
  Result := nil;
  vWr := FJournal.Next;
  if vWr = nil then
  begin
    Result := Exception.Create('Failed to get next journal writer');
    Exit;
  end;
  Result := WriteBatchesWithHeader(vWr, ABatches, ASeq);
  if Result <> nil then
    Exit;
  Result := FJournal.Flush;
  if Result <> nil then
    Exit;
  if ASync then
    Result := FJournalWriter.Sync;
end;

function TDB.RotateMem(AN: Integer; AWait: Boolean): TPair<TMemDB, Exception>;
var
  vMem: TMemDB;
  vErr: Exception;
  vRetryLimit: Integer;
begin
  vRetryLimit := 3;
  while True do
  begin
    // Wait for pending memdb compaction.
    vErr := CompTriggerWait(FMCompCmdC);
    if vErr <> nil then
    begin
      Result := TPair<TMemDB, Exception>.Create(nil, vErr);
      Exit;
    end;
    Dec(vRetryLimit);

    // Create new memdb and journal.
    vMem := nil;
    try
      vErr := NewMem(AN);
      if vErr = nil then
        vMem := FMem;
    except
      on E: Exception do
        vErr := E;
    end;

    if vErr <> nil then
    begin
      if (vErr is EErrHasFrozenMem) then
      begin
        if vRetryLimit <= 0 then
          raise Exception.Create('BUG: still has frozen memdb');
        Continue; // goto retry
      end;
      Result := TPair<TMemDB, Exception>.Create(nil, vErr);
      Exit;
    end;

    // Schedule memdb compaction.
    if AWait then
      vErr := CompTriggerWait(FMCompCmdC)
    else
      CompTrigger(FMCompCmdC);

    Result := TPair<TMemDB, Exception>.Create(vMem, vErr);
    Exit;
  end;
end;

function TDB.Flush(AN: Integer): TPair<TMemDB, Integer>;
var
  vDelayed: Boolean;
  vSlowdownTrigger: Integer;
  vPauseTrigger: Integer;
  vMdb: TMemDB;
  vMdbFree: Integer;
  vTLen: Integer;
  vStart: TDateTime;
  vErr: Exception;
  vRotateRes: TPair<TMemDB, Exception>;
begin
  vDelayed := False;
  vSlowdownTrigger := FS.O.GetWriteL0SlowdownTrigger;
  vPauseTrigger := FS.O.GetWriteL0PauseTrigger;

  vStart := Now;
  while True do
  begin
    vMdb := GetEffectiveMem;
    if vMdb = nil then
    begin
      raise EErrClosed.Create('');
    end;

    try
      vTLen := FS.TLen(0);
      vMdbFree := vMdb.Free;

      if (vTLen >= vSlowdownTrigger) and not vDelayed then
      begin
        vDelayed := True;
        TThread.Sleep(1); // time.Millisecond
      end
      else if vMdbFree >= AN then
      begin
        Result := TPair<TMemDB, Integer>.Create(vMdb, vMdbFree);
        Exit;
      end
      else if vTLen >= vPauseTrigger then
      begin
        vDelayed := True;
        // Set the write paused flag explicitly.
        TInterlocked.Exchange(FInWritePaused, 1);
        vErr := CompTriggerWait(FTCompCmdC);
        // Unset the write paused flag.
        TInterlocked.Exchange(FInWritePaused, 0);
        if vErr <> nil then
        begin
          raise vErr;
        end;
      end
      else
      begin
        // Allow memdb to grow if it has no entry.
        if vMdb.Len = 0 then
        begin
          vMdbFree := AN;
          Result := TPair<TMemDB, Integer>.Create(vMdb, vMdbFree);
          Exit;
        end
        else
        begin
          vMdb.Decref;
          vRotateRes := RotateMem(AN, False);
          vMdb := vRotateRes.Key;
          vErr := vRotateRes.Value;
          if vErr = nil then
            vMdbFree := vMdb.Free
          else
            vMdbFree := 0;
          Result := TPair<TMemDB, Integer>.Create(vMdb, vMdbFree);
          Exit;
        end;
      end;
    finally
      if vMdb <> nil then
        vMdb.Decref;
    end;
  end;

  if vDelayed then
  begin
    FWriteDelay := FWriteDelay + TTimeSpan.FromMilliseconds(MilliSecondsBetween(vStart, Now));
    Inc(FWriteDelayN);
  end
  else if FWriteDelayN > 0 then
  begin
    Logf('db@write was delayed N·%d T·%s', [FWriteDelayN, FWriteDelay.ToString]);
    TInterlocked.Add(FCWriteDelayN, FWriteDelayN);
    TInterlocked.Add(FCWriteDelay, FWriteDelay.TotalMilliseconds);
    FWriteDelay := TTimeSpan.Zero;
    FWriteDelayN := 0;
  end;
end;

procedure TDB.UnlockWrite(AOverflow: Boolean; AMerged: Integer; AErr: Exception);
var
  i: Integer;
  vSuccess: Boolean;
begin
  for i := 0 to AMerged - 1 do
    FWriteAckC.Send(AErr);

  if AOverflow then
    FWriteMergedC.Send(False)
  else
  begin
    FWriteLockC.Receive(vSuccess);
  end;
end;

function TDB.WriteLocked(ABatch, AOurBatch: TBatch; AMerge, ASync: Boolean): Exception;
var
  vMdb: TMemDB;
  vMdbFree: Integer;
  vErr: Exception;
  vOverflow: Boolean;
  vMerged: Integer;
  vBatches: TArray<TBatch>;
  vMergeLimit: Integer;
  vIncoming: TWriteMerge;
  vInternalLen: Integer;
  vSeq: UInt64;
  vB: TBatch;
  vFlushRes: TPair<TMemDB, Integer>;
begin
  Result := nil;
  // Try to flush memdb. This method would also trying to throttle writes
  // if it is too fast and compaction cannot catch-up.
  try
    vFlushRes := Flush(ABatch.InternalLen);
    vMdb := vFlushRes.Key;
    vMdbFree := vFlushRes.Value;
  except
    on E: Exception do
    begin
      UnlockWrite(False, 0, E);
      Result := E;
      Exit;
    end;
  end;

  try
    vOverflow := False;
    vMerged := 0;
    vBatches := [ABatch];

    if AMerge then
    begin
      // Merge limit.
      if ABatch.InternalLen > (128 shl 10) then
        vMergeLimit := (1 shl 20) - ABatch.InternalLen
      else
        vMergeLimit := 128 shl 10;
      var vMergeCap := vMdbFree - ABatch.InternalLen;
      if vMergeLimit > vMergeCap then
        vMergeLimit := vMergeCap;

      while vMergeLimit > 0 do
      begin
        if FWriteMergeC.TryReceive(vIncoming) then
        begin
          if vIncoming.Batch <> nil then
          begin
            // Merge batch.
            if vIncoming.Batch.InternalLen > vMergeLimit then
            begin
              vOverflow := True;
              Break; // break merge
            end;
            vBatches := vBatches + [vIncoming.Batch];
            vMergeLimit := vMergeLimit - vIncoming.Batch.InternalLen;
          end
          else
          begin
            // Merge put.
            vInternalLen := Length(vIncoming.Key) + Length(vIncoming.Value) + 8;
            if vInternalLen > vMergeLimit then
            begin
              vOverflow := True;
              Break; // break merge
            end;
            if AOurBatch = nil then
            begin
              AOurBatch := FBatchPool.Get as TBatch;
              AOurBatch.Reset;
              vBatches := vBatches + [AOurBatch];
            end;
            // We can use same batch since concurrent write doesn't
            // guarantee write order.
            AOurBatch.AppendRec(vIncoming.KeyType, vIncoming.Key, vIncoming.Value);
            vMergeLimit := vMergeLimit - vInternalLen;
          end;
          ASync := ASync or vIncoming.Sync;
          Inc(vMerged);
          FWriteMergedC.Send(True);
        end
        else
          Break; // break merge
      end;
    end;

    // Release ourBatch if any.
    if AOurBatch <> nil then
      FBatchPool.Put(AOurBatch);

    // Seq number.
    vSeq := FSeq + 1;

    // Write journal.
    Result := WriteJournal(vBatches, vSeq, ASync);
    if Result <> nil then
    begin
      UnlockWrite(vOverflow, vMerged, Result);
      Exit;
    end;

    // Put batches.
    for vB in vBatches do
    begin
      vErr := vB.PutMem(vSeq, vMdb);
      if vErr <> nil then
        raise vErr; // Panic in Go, so raise exception
      vSeq := vSeq + UInt64(vB.Len);
    end;

    // Incr seq number.
    AddSeq(UInt64(BatchesLen(vBatches)));

    // Rotate memdb if it's reach the threshold.
    if ABatch.InternalLen >= vMdbFree then
      RotateMem(0, False);

    UnlockWrite(vOverflow, vMerged, nil);
  finally
    if vMdb <> nil then
      vMdb.Decref;
  end;
end;

function TDB.Write(ABatch: TBatch; AWo: TWriteOptions): Exception;
var
  vErr: Exception;
  vMerge: Boolean;
  vSync: Boolean;
  vTr: ITransaction;
  vWriteMerge: TWriteMerge;
  vReceived: Boolean;
begin
  Result := Ok;
  if (Result <> nil) or (ABatch = nil) or (ABatch.Len = 0) then
    Exit;

  // If the batch size is larger than write buffer, it may justified to write
  // using transaction instead. Using transaction the batch will be written
  // into tables directly, skipping the journaling.
  if (ABatch.InternalLen > FS.O.GetWriteBuffer) and not FS.O.GetDisableLargeBatchTransaction then
  begin
    vTr := OpenTransaction;
    try
      vErr := vTr.Write(ABatch, AWo);
      if vErr <> nil then
      begin
        vTr.Discard;
        Result := vErr;
        Exit;
      end;
      Result := vTr.Commit;
    finally
      // vTr is an interface, no need to free
    end;
    Exit;
  end;

  vMerge := not AWo.GetNoWriteMerge and not FS.O.GetNoWriteMerge;
  vSync := AWo.GetSync and not FS.O.GetNoSync;

  // Acquire write lock.
  if vMerge then
  begin
    vWriteMerge.Sync := vSync;
    vWriteMerge.Batch := ABatch;
    if FWriteMergeC.TrySend(vWriteMerge) then
    begin
      if FWriteMergedC.Receive(vReceived) and vReceived then
      begin
        FWriteAckC.Receive(Result);
        Exit;
      end;
      // Write is not merged, the write lock is handed to us. Continue.
    end
    else if FWriteLockC.TrySend(True) then
    begin
      // Write lock acquired.
    end
    else if FCompPerErrC.TryReceive(vErr) then
    begin
      Result := vErr;
      Exit;
    end
    else if FCloseC.IsClosed then
    begin
      Result := ErrClosed;
      Exit;
    end;
  end
  else
  begin
    if not FWriteLockC.TrySend(True) then
    begin
      if FCompPerErrC.TryReceive(vErr) then
      begin
        Result := vErr;
        Exit;
      end
      else if FCloseC.IsClosed then
      begin
        Result := ErrClosed;
        Exit;
      end;
    end;
  end;

  Result := WriteLocked(ABatch, nil, vMerge, vSync);
end;

function TDB.PutRec(AKt: TKeyType; const AKey, AValue: TBytes; AWo: TWriteOptions): Exception;
var
  vErr: Exception;
  vMerge: Boolean;
  vSync: Boolean;
  vBatch: TBatch;
  vWriteMerge: TWriteMerge;
  vReceived: Boolean;
begin
  Result := Ok;
  if Result <> nil then
    Exit;

  vMerge := not AWo.GetNoWriteMerge and not FS.O.GetNoWriteMerge;
  vSync := AWo.GetSync and not FS.O.GetNoSync;

  // Acquire write lock.
  if vMerge then
  begin
    vWriteMerge.Sync := vSync;
    vWriteMerge.KeyType := AKt;
    vWriteMerge.Key := AKey;
    vWriteMerge.Value := AValue;
    if FWriteMergeC.TrySend(vWriteMerge) then
    begin
      if FWriteMergedC.Receive(vReceived) and vReceived then
      begin
        FWriteAckC.Receive(Result);
        Exit;
      end;
      // Write is not merged, the write lock is handed to us. Continue.
    end
    else if FWriteLockC.TrySend(True) then
    begin
      // Write lock acquired.
    end
    else if FCompPerErrC.TryReceive(vErr) then
    begin
      Result := vErr;
      Exit;
    end
    else if FCloseC.IsClosed then
    begin
      Result := ErrClosed;
      Exit;
    end;
  end
  else
  begin
    if not FWriteLockC.TrySend(True) then
    begin
      if FCompPerErrC.TryReceive(vErr) then
      begin
        Result := vErr;
        Exit;
      end
      else if FCloseC.IsClosed then
      begin
        Result := ErrClosed;
        Exit;
      end;
    end;
  end;

  vBatch := FBatchPool.Get as TBatch;
  vBatch.Reset;
  vBatch.AppendRec(AKt, AKey, AValue);
  Result := WriteLocked(vBatch, vBatch, vMerge, vSync);
end;

function TDB.Put(const AKey, AValue: TBytes; AWo: TWriteOptions): Exception;
begin
  Result := PutRec(TKeyType.KeyTypeVal, AKey, AValue, AWo);
end;

function TDB.Delete(const AKey: TBytes; AWo: TWriteOptions): Exception;
begin
  Result := PutRec(TKeyType.KeyTypeDel, AKey, nil, AWo);
end;

function IsMemOverlaps(AIcmp: IComparer; AMem: TMemDB; const AMin, AMax: TBytes): Boolean;
var
  vIter: IIterator;
begin
  vIter := AMem.NewIterator(nil);
  try
    Result := (AMax = nil) or (vIter.First and (AIcmp.UserComparer.Compare(AMax, TInternalKey(vIter.Key).UKey) >= 0)) and
              (AMin = nil) or (vIter.Last and (AIcmp.UserComparer.Compare(AMin, TInternalKey(vIter.Key).UKey) <= 0));
  finally
    // vIter is an interface, no need to free
  end;
end;

function TDB.CompactRange(AR: TRange): Exception;
var
  vErr: Exception;
  vMdb: TMemDB;
  vRotateRes: TPair<TMemDB, Exception>;
begin
  Result := Ok;
  if Result <> nil then
    Exit;

  // Lock writer.
  if not FWriteLockC.TrySend(True) then
  begin
    if FCompPerErrC.TryReceive(vErr) then
    begin
      Result := vErr;
      Exit;
    end
    else if FCloseC.IsClosed then
    begin
      Result := ErrClosed;
      Exit;
    end;
  end;

  try
    // Check for overlaps in memdb.
    vMdb := GetEffectiveMem;
    if vMdb = nil then
    begin
      Result := ErrClosed;
      Exit;
    end;
    try
      if IsMemOverlaps(FS.ICmp, vMdb, AR.Start, AR.Limit) then
      begin
        // Memdb compaction.
        vRotateRes := RotateMem(0, False);
        vErr := vRotateRes.Value;
        if vErr <> nil then
        begin
          Result := vErr;
          Exit;
        end;
        Result := CompTriggerWait(FMCompCmdC);
        if Result <> nil then
          Exit;
      end;
    finally
      vMdb.Decref;
    end;
  finally
    UnlockWrite(False, 0, nil);
  end;

  // Table compaction.
  Result := CompTriggerRange(FTCompCmdC, -1, AR.Start, AR.Limit);
end;

function TDB.SetReadOnly: Exception;
var
  vErr: Exception;
  vPerr: Exception;
begin
  Result := Ok;
  if Result <> nil then
    Exit;

  // Lock writer.
  if not FWriteLockC.TrySend(True) then
  begin
    if FCompPerErrC.TryReceive(vErr) then
    begin
      Result := vErr;
      Exit;
    end
    else if FCloseC.IsClosed then
    begin
      Result := ErrClosed;
      Exit;
    end;
  end;
  FCompWriteLocking := True;

  // Set compaction read-only.
  if not FCompErrSetC.TrySend(ErrReadOnly) then
  begin
    if FCompPerErrC.TryReceive(vPerr) then
    begin
      Result := vPerr;
      Exit;
    end
    else if FCloseC.IsClosed then
    begin
      Result := ErrClosed;
      Exit;
    end;
  end;

  Result := nil;
end;

end.