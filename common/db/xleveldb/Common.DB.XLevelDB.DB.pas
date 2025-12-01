// Copyright (c) 2012, Suryandaru Triandana <syndtr@gmail.com>
// All rights reserved.
//
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
unit Common.Db.XLevelDB.DB;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  GoToDelphi.Helpers.TChannel,
  Common.Db.XLevelDB.Errors,
  Common.Db.XLevelDB.Iterator,
  Common.Db.XLevelDB.Journal,
  Common.Db.XLevelDB.MemDB,
  Common.Db.XLevelDB.Opt,
  Common.Db.XLevelDB.Storage,
  Common.Db.XLevelDB.Table,
  Common.Db.XLevelDB.Util,
  Common.Db.XLevelDB.Session,
  Common.Db.XLevelDB.Snapshot;

type
  // DB is a LevelDB database.
  TDB = class
  private
    // Need 64-bit alignment.
    FSeq: UInt64;

    // Stats. Need 64-bit alignment.
    FCWriteDelay: Int64; // The cumulative duration of write delays
    FCWriteDelayN: Integer; // The cumulative number of write delays
    FInWritePaused: Integer; // The indicator whether write operation is paused by compaction
    FAliveSnaps, FAliveIters: Integer;

    // Session.
    FS: TSession;

    // MemDB.
    FMemMu: TRTLCriticalSection;
    FMemPool: TChannel<TMemDB>;
    FMem, FFrozenMem: TMemDB;
    FJournal: TJournalWriter;
    FJournalWriter: IWriter;
    FJournalFd: TFileDesc;
    FFrozenJournalFd: TFileDesc;
    FFrozenSeq: UInt64;

    // Snapshot.
    FSnapsMu: TCriticalSection;
    FSnapsList: TList<TSnapshot>;

    // Write.
    FBatchPool: TObjectPool;
    FWriteMergeC: TChannel<TWriteMerge>;
    FWriteMergedC: TChannel<Boolean>;
    FWriteLockC: TChannel<Boolean>;
    FWriteAckC: TChannel<Exception>;
    FWriteDelay: TTimeSpan;
    FWriteDelayN: Integer;
    FTr: TTransaction;

    // Compaction.
    FCompCommitLk: TCriticalSection;
    FTCompCmdC: TChannel<TCCmd>;
    FTCompPauseC: TChannel<TChannel<Boolean>>;
    FMCompCmdC: TChannel<TCCmd>;
    FCompErrC: TChannel<Exception>;
    FCompPerErrC: TChannel<Exception>;
    FCompErrSetC: TChannel<Exception>;
    FCompWriteLocking: Boolean;
    FCompStats: TCStats;
    FMemDBMaxLevel: Integer; // For testing.

    // Close.
    FCloseW: TCountdownEvent;
    FCloseC: TChannel<Boolean>;
    FClosed: Cardinal;
    FCloser: IInterface;

    function Ok: Exception;
    function SetClosed: Boolean;
    procedure CompactionError;
    procedure MpoolDrain;
    procedure TCompaction;
    procedure MCompaction;
    function RecoverJournal: Exception;
    function RecoverJournalRO: Exception;
    function CheckAndCleanFiles: Exception;
    function NewMem(ParaSize: Integer): Exception;
    function GetMems: TPair<TMemDB, TMemDB>;
    procedure ClearMems;
    function Get(ParaAuxm: TMemDB; ParaAuxt: TFiles; ParaKey: TBytes; ParaSeq: UInt64; ParaRo: TReadOptions): TPair<TBytes, Exception>;
    function Has(ParaAuxm: TMemDB; ParaAuxt: TFiles; ParaKey: TBytes; ParaSeq: UInt64; ParaRo: TReadOptions): TPair<Boolean, Exception>;
    function NewIterator(ParaAuxm: TMemDB; ParaAuxt: TFiles; ParaSeq: UInt64; ParaSlice: TRange; ParaRo: TReadOptions): IIterator;
    function AcquireSnapshot: TSnapshot;
    procedure ReleaseSnapshot(ParaSe: TSnapshot);
  public
    constructor Create(ParaS: TSession);
    destructor Destroy; override;
    // Get gets the value for the given key. It returns ErrNotFound if the
    // DB does not contains the key.
    //
    // The returned slice is its own copy, it is safe to modify the contents
    // of the returned slice.
    // It is safe to modify the contents of the argument after Get returns.
    function Get(ParaKey: TBytes; ParaRo: TReadOptions): TPair<TBytes, Exception>;
    function Get2(ParaKey: TBytes; ParaRo: TReadOptions; ParaAuxm: TMemDB; ParaSeq: UInt64): TPair<TBytes, Exception>;
    // Has returns true if the DB does contains the given key.
    //
    // It is safe to modify the contents of the argument after Has returns.
    function Has(ParaKey: TBytes; ParaRo: TReadOptions): TPair<Boolean, Exception>;
    // NewIterator returns an iterator for the latest snapshot of the
    // underlying DB.
    // The returned iterator is not safe for concurrent use, but it is safe to use
    // multiple iterators concurrently, with each in a dedicated goroutine.
    // It is also safe to use an iterator concurrently with modifying its
    // underlying DB. The resultant key/value pairs are guaranteed to be
    // consistent.
    //
    // Slice allows slicing the iterator to only contains keys in the given
    // range. A nil Range.Start is treated as a key before all keys in the
    // DB. And a nil Range.Limit is treated as a key after all keys in
    // the DB.
    //
    // The iterator must be released after use, by calling Release method.
    //
    // Also read Iterator documentation of the leveldb/iterator package.
    function NewIterator(ParaSlice: TRange; ParaRo: TReadOptions): IIterator;
    function NewIterator2(ParaSlice: TRange; ParaRo: TReadOptions; ParaAuxm: TMemDB; ParaSeq: UInt64): IIterator;
    // GetSnapshot returns a latest snapshot of the underlying DB. A snapshot
    // is a frozen snapshot of a DB state at a particular point in time. The
    // content of snapshot are guaranteed to be consistent.
    //
    // The snapshot must be released after use, by calling Release method.
    function GetSnapshot: TPair<TSnapshot, Exception>;
    // GetProperty returns value of the given property name.
    function GetProperty(ParaName: string): TPair<string, Exception>;
    // Stats populates s with database statistics.
    function Stats(ParaS: TDBStats): Exception;
    // SizeOf calculates approximate sizes of the given key ranges.
    function SizeOf(ParaRanges: TArray<TRange>): TPair<TSizes, Exception>;
    // Close closes the DB.
    procedure Close;
  end;

// Open opens or creates a DB for the given storage.
function Open(ParaStor: IStorage; ParaO: TOptions): TPair<TDB, Exception>;
// OpenFile opens or creates a DB for the given path.
function OpenFile(ParaPath: string; ParaO: TOptions): TPair<TDB, Exception>;
// Recover recovers and opens a DB with missing or corrupted manifest files.
function Recover(ParaStor: IStorage; ParaO: TOptions): TPair<TDB, Exception>;
// RecoverFile recovers and opens a DB with missing or corrupted manifest files.
function RecoverFile(ParaPath: string; ParaO: TOptions): TPair<TDB, Exception>;

implementation

uses
  Common.Db.XLevelDb.Db_Write;

function MemGet(ParaMdb: TMemDB; ParaIkey: TBytes; ParaIcmp: TIComparer): TMemGetResult;
var
  vMk, vMv: TBytes;
  vErr: Exception;
  vUkey: TBytes;
  vKt: TKeyType;
  vKerr: Exception;
begin
  vErr := ParaMdb.Find(ParaIkey, vMk, vMv);
  if vErr = nil then
  begin
    vUkey := nil;
    vKt := TKeyType.KeyTypeDel;
    vKerr := ParseInternalKey(vMk, nil, @vKt, vUkey);
    if vKerr <> nil then
      raise vKerr;
    if ParaIcmp.UCompare(vUkey, ParaIkey.ukey) = 0 then
    begin
      if vKt = TKeyType.KeyTypeDel then
      begin
        Result.Ok := True;
        Result.Value := nil;
        Result.Err := ErrNotFound;
        Exit;
      end;
      Result.Ok := True;
      Result.Value := vMv;
      Result.Err := nil;
      Exit;
    end;
  end
  else if not (vErr is ENotFound) then
  begin
    Result.Ok := True;
    Result.Value := nil;
    Result.Err := vErr;
    Exit;
  end;
  Result.Ok := False;
end;

function NilIfNotFound(ParaErr: Exception): Exception;
begin
  if ParaErr is ENotFound then
    Result := nil
  else
    Result := ParaErr;
end;

function RecoverTable(ParaS: TSession; ParaO: TOptions): Exception;
var
  vFds: TArray<TFileDesc>;
  vErr: Exception;
  vMaxSeq: UInt64;
  vRecoveredKey, vGoodKey, vCorruptedKey, vCorruptedBlock, vDroppedTable: Integer;
  vStrict, vNoSync: Boolean;
  vRec: TSessionRecord;
  vBpool: TBufferPool;
  vI: Integer;
  vFd: TFileDesc;
  vReader: IReader;
  vSize: Int64;
  vTSeq: UInt64;
  vTGoodKey, vTCorruptedKey, vTCorruptedBlock: Integer;
  vImin, vImax: TBytes;
  vTr: TTableReader;
  vIter: IIterator;
  vIterErr: IErrorCallbackSetter;
  vKey: TBytes;
  vSeq: UInt64;
  vKErr: Exception;
  vTmpFd: TFileDesc;
  vNewSize: Int64;
  vWriter: IWriter;
  vTw: TTableWriter;
begin
  vO := DupOptions(ParaO);
  // Mask StrictReader, lets StrictRecovery doing its job.
  vO.Strict := vO.Strict and not TStrict.StrictReader;

  // Get all tables and sort it by file number.
  vFds := ParaS.stor.List(TFileType.TypeTable);
  if vFds = nil then
  begin
    Result := nil;
    Exit;
  end;
  SortFds(vFds);

  vMaxSeq := 0;
  vRecoveredKey := 0;
  vGoodKey := 0;
  vCorruptedKey := 0;
  vCorruptedBlock := 0;
  vDroppedTable := 0;

  // We will drop corrupted table.
  vStrict := vO.GetStrict(TStrict.StrictRecovery);
  vNoSync := vO.GetNoSync;

  vRec := TSessionRecord.Create;
  try
    vBpool := TBufferPool.Create(vO.GetBlockSize + 5);
    try
      // Recover all tables.
      if Length(vFds) > 0 then
      begin
        ParaS.LogF('table@recovery F·%d', [Length(vFds)]);

        // Mark file number as used.
        ParaS.MarkFileNum(vFds[High(vFds)].Num);

        for vI := 0 to High(vFds) do
        begin
          vFd := vFds[vI];
          ParaS.LogF('table@recovery recovering @%d', [vFd.Num]);
          vReader := ParaS.stor.Open(vFd);
          try
            // Get file size.
            vSize := vReader.Seek(0, soEnd);

            vTSeq := 0;
            vTGoodKey := 0;
            vTCorruptedKey := 0;
            vTCorruptedBlock := 0;
            vImin := nil;
            vImax := nil;

            vTr := TTableReader.Create(vReader, vSize, vFd, nil, vBpool, vO);
            try
              vIter := vTr.NewIterator(nil, nil);
              try
                if Supports(vIter, IErrorCallbackSetter, vIterErr) then
                begin
                  vIterErr.SetErrorCallback(procedure(ParaErr: Exception)
                  begin
                    if IsCorrupted(ParaErr) then
                    begin
                      ParaS.LogF('table@recovery block corruption @%d %q', [vFd.Num, ParaErr.Message]);
                      Inc(vTCorruptedBlock);
                    end;
                  end);
                end;

                // Scan the table.
                while vIter.Next do
                begin
                  vKey := vIter.Key;
                  vSeq := 0;
                  vKErr := ParseInternalKey(vKey, vSeq, nil);
                  if vKErr <> nil then
                  begin
                    Inc(vTCorruptedKey);
                    Continue;
                  end;
                  Inc(vTGoodKey);
                  if vSeq > vTSeq then
                    vTSeq := vSeq;
                  if vImin = nil then
                    vImin := Copy(vKey);
                  vImax := Copy(vKey);
                end;
                vErr := vIter.Error;
                if (vErr <> nil) and (not IsCorrupted(vErr)) then
                begin
                  Result := vErr;
                  Exit;
                end;
              finally
                vIter.Release;
              end;
            finally
              vTr.Free;
            end;

            Inc(vGoodKey, vTGoodKey);
            Inc(vCorruptedKey, vTCorruptedKey);
            Inc(vCorruptedBlock, vTCorruptedBlock);

            if vStrict and ((vTCorruptedKey > 0) or (vTCorruptedBlock > 0)) then
            begin
              Inc(vDroppedTable);
              ParaS.LogF('table@recovery dropped @%d Gk·%d Ck·%d Cb·%d S·%d Q·%d', [vFd.Num, vTGoodKey, vTCorruptedKey, vTCorruptedBlock, vSize, vTSeq]);
              Continue;
            end;

            if vTGoodKey > 0 then
            begin
              if (vTCorruptedKey > 0) or (vTCorruptedBlock > 0) then
              begin
                // Rebuild the table.
                ParaS.LogF('table@recovery rebuilding @%d', [vFd.Num]);
                vIter := vTr.NewIterator(nil, nil);
                try
                  vTmpFd := ParaS.NewTemp;
                  vWriter := ParaS.stor.Create(vTmpFd);
                  try
                    vTw := TTableWriter.Create(vWriter, vO);
                    try
                      while vIter.Next do
                      begin
                        vKey := vIter.Key;
                        if ValidInternalKey(vKey) then
                        begin
                          vErr := vTw.Append(vKey, vIter.Value);
                          if vErr <> nil then
                          begin
                            Result := vErr;
                            Exit;
                          end;
                        end;
                      end;
                      vErr := vIter.Error;
                      if (vErr <> nil) and (not IsCorrupted(vErr)) then
                      begin
                        Result := vErr;
                        Exit;
                      end;
                      vErr := vTw.Close;
                      if vErr <> nil then
                      begin
                        Result := vErr;
                        Exit;
                      end;
                      if not vNoSync then
                      begin
                        vErr := vWriter.Sync;
                        if vErr <> nil then
                        begin
                          Result := vErr;
                          Exit;
                        end;
                      end;
                      vNewSize := vTw.BytesLen;
                    finally
                      vTw.Free;
                    end;
                  finally
                    vWriter.Close;
                    if vErr <> nil then
                      ParaS.stor.Remove(vTmpFd);
                  end;
                finally
                  vIter.Release;
                end;
                vReader.Close;
                vErr := ParaS.stor.Rename(vTmpFd, vFd);
                if vErr <> nil then
                begin
                  Result := vErr;
                  Exit;
                end;
                vSize := vNewSize;
              end;
              if vTSeq > vMaxSeq then
                vMaxSeq := vTSeq;
              Inc(vRecoveredKey, vTGoodKey);
              // Add table to level 0.
              vRec.AddTable(0, vFd.Num, vSize, vImin, vImax);
              ParaS.LogF('table@recovery recovered @%d Gk·%d Ck·%d Cb·%d S·%d Q·%d', [vFd.Num, vTGoodKey, vTCorruptedKey, vTCorruptedBlock, vSize, vTSeq]);
            end
            else
            begin
              Inc(vDroppedTable);
              ParaS.LogF('table@recovery unrecoverable @%d Ck·%d Cb·%d S·%d', [vFd.Num, vTCorruptedKey, vTCorruptedBlock, vSize]);
            end;
          finally
            vReader := nil;
          end;
        end;

        ParaS.LogF('table@recovery recovered F·%d N·%d Gk·%d Ck·%d Q·%d', [Length(vFds), vRecoveredKey, vGoodKey, vCorruptedKey, vMaxSeq]);
      end;

      // Set sequence number.
      vRec.SetSeqNum(vMaxSeq);

      // Create new manifest.
      vErr := ParaS.CreateManifest;
      if vErr <> nil then
      begin
        Result := vErr;
        Exit;
      end;

      // Commit.
      Result := ParaS.Commit(vRec);
    finally
      vBpool.Free;
    end;
  finally
    vRec.Free;
  end;
end;

function OpenDB(ParaS: TSession): TPair<TDB, Exception>;
var
  vDB: TDB;
  vErr: Exception;
begin
  ParaS.Log('db@open opening');
  vDB := TDB.Create(ParaS);
  try
    // Recover journals.
    vErr := vDB.RecoverJournal;
    if vErr <> nil then
    begin
      Result := TPair<TDB, Exception>.Create(nil, vErr);
      Exit;
    end;

    // Remove any obsolete files.
    vErr := vDB.CheckAndCleanFiles;
    if vErr <> nil then
    begin
      // Close journal.
      if vDB.FJournal <> nil then
      begin
        vDB.FJournal.Close;
        vDB.FJournalWriter.Close;
      end;
      Result := TPair<TDB, Exception>.Create(nil, vErr);
      Exit;
    end;

    // Doesn't need to be included in the wait group.
    TThread.CreateAnonymousThread(procedure
    begin
      vDB.CompactionError;
    end).Start;
    TThread.CreateAnonymousThread(procedure
    begin
      vDB.MpoolDrain;
    end).Start;

    if ParaS.Options.GetReadOnly then
    begin
      // vDB.SetReadOnly;
    end
    else
    begin
      vDB.FCloseW.Add(2);
      TThread.CreateAnonymousThread(procedure
      begin
        vDB.TCompaction;
      end).Start;
      TThread.CreateAnonymousThread(procedure
      begin
        vDB.MCompaction;
      end).Start;
    end;

    ParaS.LogF('db@open done T·%v', [Now - ParaS.StartTime]);
    Result := TPair<TDB, Exception>.Create(vDB, nil);
  except
    on E: Exception do
    begin
      vDB.Free;
      Result := TPair<TDB, Exception>.Create(nil, E);
    end;
  end;
end;

function Open(ParaStor: IStorage; ParaO: TOptions): TPair<TDB, Exception>;
var
  vS: TSession;
  vErr: Exception;
begin
  vS := TSession.Create(ParaStor, ParaO);
  try
    vErr := vS.Recover;
    if vErr <> nil then
    begin
      if not IsNotExist(vErr) or vS.Options.GetErrorIfMissing then
      begin
        Result := TPair<TDB, Exception>.Create(nil, vErr);
        Exit;
      end;
      vErr := vS.CreateManifest;
      if vErr <> nil then
      begin
        Result := TPair<TDB, Exception>.Create(nil, vErr);
        Exit;
      end;
    end
    else if vS.Options.GetErrorIfExist then
    begin
      Result := TPair<TDB, Exception>.Create(nil, EOSError.Create('Database exists'));
      Exit;
    end;

    Result := OpenDB(vS);
  finally
    if Result.Value <> nil then
    begin
      vS.Close;
      vS.Release;
    end;
  end;
end;

function OpenFile(ParaPath: string; ParaO: TOptions): TPair<TDB, Exception>;
var
  vStor: IStorage;
  vErr: Exception;
  vDB: TDB;
begin
  vStor := TFileStorage.Create(ParaPath, ParaO.GetReadOnly);
  try
    Result := Open(vStor, ParaO);
    if Result.Value <> nil then
    begin
      vStor.Close;
    end
    else
    begin
      vDB := Result.Key;
      vDB.FCloser := vStor;
    end;
  except
    on E: Exception do
    begin
      Result := TPair<TDB, Exception>.Create(nil, E);
    end;
  end;
end;

function Recover(ParaStor: IStorage; ParaO: TOptions): TPair<TDB, Exception>;
var
  vS: TSession;
  vErr: Exception;
begin
  vS := TSession.Create(ParaStor, ParaO);
  try
    vErr := RecoverTable(vS, ParaO);
    if vErr <> nil then
    begin
      Result := TPair<TDB, Exception>.Create(nil, vErr);
      Exit;
    end;
    Result := OpenDB(vS);
  finally
    if Result.Value <> nil then
    begin
      vS.Close;
      vS.Release;
    end;
  end;
end;

function RecoverFile(ParaPath: string; ParaO: TOptions): TPair<TDB, Exception>;
var
  vStor: IStorage;
  vErr: Exception;
  vDB: TDB;
begin
  vStor := TFileStorage.Create(ParaPath, False);
  try
    Result := Recover(vStor, ParaO);
    if Result.Value <> nil then
    begin
      vStor.Close;
    end
    else
    begin
      vDB := Result.Key;
      vDB.FCloser := vStor;
    end;
  except
    on E: Exception do
    begin
      Result := TPair<TDB, Exception>.Create(nil, E);
    end;
  end;
end;

{ TDB }

constructor TDB.Create(ParaS: TSession);
begin
  inherited Create;
  FS := ParaS;
  FSeq := FS.StartSeqNum;
  FMemPool := TChannel<TMemDB>.Create(1);
  FSnapsList := TList<TSnapshot>.Create;
  FBatchPool := TObjectPool.Create;
  FWriteMergeC := TChannel<TWriteMerge>.Create;
  FWriteMergedC := TChannel<Boolean>.Create;
  FWriteLockC := TChannel<Boolean>.Create(1);
  FWriteAckC := TChannel<Exception>.Create;
  FTCompCmdC := TChannel<TCCmd>.Create;
  FTCompPauseC := TChannel<TChannel<Boolean>>.Create;
  FMCompCmdC := TChannel<TCCmd>.Create;
  FCompErrC := TChannel<Exception>.Create;
  FCompPerErrC := TChannel<Exception>.Create;
  FCompErrSetC := TChannel<Exception>.Create;
  FCloseC := TChannel<Boolean>.Create;
  FCloseW := TCountdownEvent.Create;
  InitializeCriticalSection(FMemMu);
  InitializeCriticalSection(FSnapsMu);
  InitializeCriticalSection(FCompCommitLk);
end;

destructor TDB.Destroy;
begin
  FSnapsList.Free;
  FBatchPool.Free;
  FWriteMergeC.Free;
  FWriteMergedC.Free;
  FWriteLockC.Free;
  FWriteAckC.Free;
  FTCompCmdC.Free;
  FTCompPauseC.Free;
  FMCompCmdC.Free;
  FCompErrC.Free;
  FCompPerErrC.Free;
  FCompErrSetC.Free;
  FCloseC.Free;
  FCloseW.Free;
  DeleteCriticalSection(FMemMu);
  DeleteCriticalSection(FSnapsMu);
  DeleteCriticalSection(FCompCommitLk);
  inherited;
end;

function TDB.Ok: Exception;
begin
  if AtomicGetValue(FClosed) <> 0 then
    Result := ErrClosed
  else
    Result := nil;
end;

function TDB.SetClosed: Boolean;
begin
  Result := AtomicIncrement(FClosed) = 1;
end;

procedure TDB.CompactionError;
var
  vErr: Exception;
begin
  FCompErrC.Receive(vErr);
  if vErr <> nil then
    FS.LogF('compaction error: %v', [vErr.Message]);
end;

procedure TDB.MpoolDrain;
var
  vM: TMemDB;
begin
  while FMemPool.Receive(vM) do
    vM.Free;
end;

procedure TDB.TCompaction;
begin
  // Implementation of TCompaction
end;

procedure TDB.MCompaction;
begin
  // Implementation of MCompaction
end;

function TDB.RecoverJournal: Exception;
var
  vRawFds, vFds: TArray<TFileDesc>;
  vErr: Exception;
  vI: Integer;
  vFd: TFileDesc;
  vOfd: TFileDesc;
  vRec: TSessionRecord;
  vStrict, vChecksum: Boolean;
  vWriteBuffer: Integer;
  vJr: TJournalReader;
  vMdb: TMemDB;
  vBuf: TBuffer;
  vBatchSeq: UInt64;
  vBatchLen: Integer;
  vFr: IReader;
  vR: IReader;
begin
  // Get all journals and sort it by file number.
  vRawFds := FS.stor.List(TFileType.TypeJournal);
  SortFds(vRawFds);

  // Journals that will be recovered.
  SetLength(vFds, 0);
  for vI := 0 to High(vRawFds) do
  begin
    vFd := vRawFds[vI];
    if (vFd.Num >= FS.GetJournalNum) or (vFd.Num = FS.GetPrevJournalNum) then
      vFds := vFds + [vFd];
  end;

  vOfd.Num := 0;
  vRec := TSessionRecord.Create;
  try
    // Recover journals.
    if Length(vFds) > 0 then
    begin
      FS.LogF('journal@recovery F·%d', [Length(vFds)]);

      // Mark file number as used.
      FS.MarkFileNum(vFds[High(vFds)].Num);

      // Options.
      vStrict := FS.Options.GetStrict(TStrict.StrictJournal);
      vChecksum := FS.Options.GetStrict(TStrict.StrictJournalChecksum);
      vWriteBuffer := FS.Options.GetWriteBuffer;

      vJr := nil;
      vMdb := TMemDB.Create(FS.icmp, vWriteBuffer);
      try
        vBuf := TBuffer.Create;
        try
          for vI := 0 to High(vFds) do
          begin
            vFd := vFds[vI];
            FS.LogF('journal@recovery recovering @%d', [vFd.Num]);

            vFr := FS.stor.Open(vFd);
            try
              // Create or reset journal reader instance.
              if vJr = nil then
                vJr := TJournalReader.Create(vFr, TDropper.Create(FS, vFd), vStrict, vChecksum)
              else
                vJr.Reset(vFr, TDropper.Create(FS, vFd), vStrict, vChecksum);

              // Flush memdb and remove obsolete journal file.
              if vOfd.Num <> 0 then
              begin
                if vMdb.Len > 0 then
                begin
                  vErr := FS.FlushMemdb(vRec, vMdb, 0);
                  if vErr <> nil then
                  begin
                    Result := vErr;
                    Exit;
                  end;
                end;

                vRec.SetJournalNum(vFd.Num);
                vRec.SetSeqNum(FSeq);
                vErr := FS.Commit(vRec);
                if vErr <> nil then
                begin
                  Result := vErr;
                  Exit;
                end;
                vRec.ResetAddedTables;

                FS.stor.Remove(vOfd);
                vOfd.Num := 0;
              end;

              // Replay journal to memdb.
              vMdb.Reset;
              while True do
              begin
                vR := vJr.Next(vErr);
                if vErr <> nil then
                begin
                  if vErr is EEOF then
                    Break
                  else
                  begin
                    Result := SetFd(vErr, vFd);
                    Exit;
                  end;
                end;

                vBuf.Reset;
                vBuf.ReadFrom(vR);
                vErr := DecodeBatchToMem(vBuf.Bytes, FSeq, vMdb, vBatchSeq, vBatchLen);
                if vErr <> nil then
                begin
                  if not vStrict and IsCorrupted(vErr) then
                  begin
                    FS.LogF('journal error: %v (skipped)', [vErr.Message]);
                    // We won't apply sequence number as it might be corrupted.
                    Continue;
                  end;
                  Result := SetFd(vErr, vFd);
                  Exit;
                end;

                // Save sequence number.
                FSeq := vBatchSeq + vBatchLen;

                // Flush it if large enough.
                if vMdb.Size >= vWriteBuffer then
                begin
                  vErr := FS.FlushMemdb(vRec, vMdb, 0);
                  if vErr <> nil then
                  begin
                    Result := vErr;
                    Exit;
                  end;
                  vMdb.Reset;
                end;
              end;
            finally
              vFr.Close;
            end;
            vOfd := vFd;
          end;
        finally
          vBuf.Free;
        end;

        // Flush the last memdb.
        if vMdb.Len > 0 then
        begin
          vErr := FS.FlushMemdb(vRec, vMdb, 0);
          if vErr <> nil then
          begin
            Result := vErr;
            Exit;
          end;
        end;
      finally
        vMdb.Free;
        if vJr <> nil then
          vJr.Free;
      end;
    end;

    // Create a new journal.
    vErr := NewMem(0);
    if vErr <> nil then
    begin
      Result := vErr;
      Exit;
    end;

    // Commit.
    vRec.SetJournalNum(FJournalFd.Num);
    vRec.SetSeqNum(FSeq);
    vErr := FS.Commit(vRec);
    if vErr <> nil then
    begin
      // Close journal on error.
      if FJournal <> nil then
      begin
        FJournal.Close;
        FJournalWriter.Close;
      end;
      Result := vErr;
      Exit;
    end;

    // Remove the last obsolete journal file.
    if vOfd.Num <> 0 then
      FS.stor.Remove(vOfd);

    Result := nil;
  finally
    vRec.Free;
  end;
end;

function TDB.RecoverJournalRO: Exception;
var
  vRawFds, vFds: TArray<TFileDesc>;
  vErr: Exception;
  vI: Integer;
  vFd: TFileDesc;
  vStrict, vChecksum: Boolean;
  vWriteBuffer: Integer;
  vMdb: TMemDB;
  vJr: TJournalReader;
  vBuf: TBuffer;
  vBatchSeq: UInt64;
  vBatchLen: Integer;
  vFr: IReader;
  vR: IReader;
begin
  // Get all journals and sort it by file number.
  vRawFds := FS.stor.List(TFileType.TypeJournal);
  SortFds(vRawFds);

  // Journals that will be recovered.
  SetLength(vFds, 0);
  for vI := 0 to High(vRawFds) do
  begin
    vFd := vRawFds[vI];
    if (vFd.Num >= FS.GetJournalNum) or (vFd.Num = FS.GetPrevJournalNum) then
      vFds := vFds + [vFd];
  end;

  // Options.
  vStrict := FS.Options.GetStrict(TStrict.StrictJournal);
  vChecksum := FS.Options.GetStrict(TStrict.StrictJournalChecksum);
  vWriteBuffer := FS.Options.GetWriteBuffer;

  vMdb := TMemDB.Create(FS.icmp, vWriteBuffer);
  try
    // Recover journals.
    if Length(vFds) > 0 then
    begin
      FS.LogF('journal@recovery RO·Mode F·%d', [Length(vFds)]);

      vJr := nil;
      vBuf := TBuffer.Create;
      try
        for vI := 0 to High(vFds) do
        begin
          vFd := vFds[vI];
          FS.LogF('journal@recovery recovering @%d', [vFd.Num]);

          vFr := FS.stor.Open(vFd);
          try
            // Create or reset journal reader instance.
            if vJr = nil then
              vJr := TJournalReader.Create(vFr, TDropper.Create(FS, vFd), vStrict, vChecksum)
            else
              vJr.Reset(vFr, TDropper.Create(FS, vFd), vStrict, vChecksum);

            // Replay journal to memdb.
            while True do
            begin
              vR := vJr.Next(vErr);
              if vErr <> nil then
              begin
                if vErr is EEOF then
                  Break
                else
                begin
                  Result := SetFd(vErr, vFd);
                  Exit;
                end;
              end;

              vBuf.Reset;
              vBuf.ReadFrom(vR);
              vErr := DecodeBatchToMem(vBuf.Bytes, FSeq, vMdb, vBatchSeq, vBatchLen);
              if vErr <> nil then
              begin
                if not vStrict and IsCorrupted(vErr) then
                begin
                  FS.LogF('journal error: %v (skipped)', [vErr.Message]);
                  // We won't apply sequence number as it might be corrupted.
                  Continue;
                end;
                Result := SetFd(vErr, vFd);
                Exit;
              end;

              // Save sequence number.
              FSeq := vBatchSeq + vBatchLen;
            end;
          finally
            vFr.Close;
          end;
        end;
      finally
        vBuf.Free;
        if vJr <> nil then
          vJr.Free;
      end;
    end;

    // Set memDB.
    FMem := TMemDB.Create(FS.icmp, vWriteBuffer);
    FMem.Assign(vMdb);
    FMem.FRef := 1;

    Result := nil;
  finally
    vMdb.Free;
  end;
end;

function TDB.CheckAndCleanFiles: Exception;
var
  liveFiles: TDictionary<UInt64, Boolean>;
  v: TVersion;
  t: TTable;
  level: Integer;
  tables: TList<TTable>;
  fds: TArray<TFileDesc>;
  fd: TFileDesc;
  typ: TFileType;
begin
  Result := nil;
  liveFiles := TDictionary<UInt64, Boolean>.Create;
  try
    v := FS.GetVersion;
    try
      liveFiles.Add(FS.GetCurrentManifest.Num, True);
      liveFiles.Add(FS.GetJournalNum, True);
      if FS.GetPrevJournalNum <> 0 then
        liveFiles.Add(FS.GetPrevJournalNum, True);

      for level := 0 to v.levels.Count - 1 do
      begin
        tables := v.levels[level];
        for t in tables do
          liveFiles.Add(t.fd.Num, True);
      end;
    finally
      v.release;
    end;

    for typ := Low(TFileType) to High(TFileType) do
    begin
      fds := FS.stor.List(typ);
      if fds = nil then
        Continue;

      for fd in fds do
        if not liveFiles.ContainsKey(fd.Num) then
        begin
          FS.logf('file@clean removing @%d', [fd.Num]);
          FS.stor.Remove(fd);
        end;
    end;
  finally
    liveFiles.Free;
  end;
end;

function TDB.NewMem(ParaSize: Integer): Exception;
var
  vErr: Exception;
  vFd: TFileDesc;
  vWriter: IWriter;
begin
  vFd := FS.NewFileNum;
  vWriter := FS.stor.Create(vFd);
  if vWriter = nil then
    Result := EOSError.Create('Cannot create file');
  FJournal := TJournalWriter.Create(vWriter);
  FJournalWriter := vWriter;
  FJournalFd := vFd;
  FMem := TMemDB.Create(FS.icmp, ParaSize);
  Result := nil;
end;

function TDB.GetMems: TPair<TMemDB, TMemDB>;
begin
  EnterCriticalSection(FMemMu);
  try
    Result.Key := FMem;
    Result.Value := FFrozenMem;
  finally
    LeaveCriticalSection(FMemMu);
  end;
end;

procedure TDB.ClearMems;
begin
  EnterCriticalSection(FMemMu);
  try
    FMem := nil;
    FFrozenMem := nil;
  finally
    LeaveCriticalSection(FMemMu);
  end;
end;

function TDB.Get(ParaAuxm: TMemDB; ParaAuxt: TFiles; ParaKey: TBytes; ParaSeq: UInt64; ParaRo: TReadOptions): TPair<TBytes, Exception>;
var
  vIkey: TBytes;
  vMemGetRes: TMemGetResult;
  vEm, vFm: TMemDB;
  vM: TMemDB;
  v: TVersion;
  vValue: TBytes;
  vCSched: Boolean;
  vErr: Exception;
begin
  vIkey := MakeInternalKey(nil, ParaKey, ParaSeq, TKeyType.KeyTypeSeek);

  if ParaAuxm <> nil then
  begin
    vMemGetRes := MemGet(ParaAuxm, vIkey, FS.icmp);
    if vMemGetRes.Ok then
    begin
      Result := TPair<TBytes, Exception>.Create(CopyBytes(vMemGetRes.Value), vMemGetRes.Err);
      Exit;
    end;
  end;

  vEm := GetMems.Key;
  vFm := GetMems.Value;
  for vM in [vEm, vFm] do
  begin
    if vM = nil then
      Continue;
    try
      vMemGetRes := MemGet(vM, vIkey, FS.icmp);
      if vMemGetRes.Ok then
      begin
        Result := TPair<TBytes, Exception>.Create(CopyBytes(vMemGetRes.Value), vMemGetRes.Err);
        Exit;
      end;
    finally
      vM.Decref;
    end;
  end;

  v := FS.version;
  try
    v.Get(ParaAuxt, vIkey, ParaRo, False, vValue, vCSched, vErr);
    if vCSched then
      CompTrigger(FTCompCmdC);
    Result := TPair<TBytes, Exception>.Create(vValue, vErr);
  finally
    v.release;
  end;
end;

function TDB.Has(ParaAuxm: TMemDB; ParaAuxt: TFiles; ParaKey: TBytes; ParaSeq: UInt64; ParaRo: TReadOptions): TPair<Boolean, Exception>;
var
  vIkey: TBytes;
  vMemGetRes: TMemGetResult;
  vEm, vFm: TMemDB;
  vM: TMemDB;
  v: TVersion;
  vCSched: Boolean;
  vErr: Exception;
begin
  vIkey := MakeInternalKey(nil, ParaKey, ParaSeq, TKeyType.KeyTypeSeek);

  if ParaAuxm <> nil then
  begin
    vMemGetRes := MemGet(ParaAuxm, vIkey, FS.icmp);
    if vMemGetRes.Ok then
    begin
      Result := TPair<Boolean, Exception>.Create(vMemGetRes.Err = nil, NilIfNotFound(vMemGetRes.Err));
      Exit;
    end;
  end;

  vEm := GetMems.Key;
  vFm := GetMems.Value;
  for vM in [vEm, vFm] do
  begin
    if vM = nil then
      Continue;
    try
      vMemGetRes := MemGet(vM, vIkey, FS.icmp);
      if vMemGetRes.Ok then
      begin
        Result := TPair<Boolean, Exception>.Create(vMemGetRes.Err = nil, NilIfNotFound(vMemGetRes.Err));
        Exit;
      end;
    finally
      vM.Decref;
    end;
  end;

  v := FS.version;
  try
    v.Get(ParaAuxt, vIkey, ParaRo, True, nil, vCSched, vErr);
    if vCSched then
      CompTrigger(FTCompCmdC);
    if vErr = nil then
      Result := TPair<Boolean, Exception>.Create(True, nil)
    else if vErr is ENotFound then
      Result := TPair<Boolean, Exception>.Create(False, nil)
    else
      Result := TPair<Boolean, Exception>.Create(False, vErr);
  finally
    v.release;
  end;
end;

function TDB.NewIterator(ParaAuxm: TMemDB; ParaAuxt: TFiles; ParaSeq: UInt64; ParaSlice: TRange; ParaRo: TReadOptions): IIterator;
var
  vEm, vFm: TMemDB;
  vM: TMemDB;
  vIters: TArray<IIterator>;
  v: TVersion;
begin
  vEm := GetMems.Key;
  vFm := GetMems.Value;
  SetLength(vIters, 0);
  if ParaAuxm <> nil then
    vIters := vIters + [ParaAuxm.NewIterator(ParaSlice)];
  for vM in [vEm, vFm] do
  begin
    if vM = nil then
      Continue;
    vIters := vIters + [vM.NewIterator(ParaSlice)];
  end;

  v := FS.version;
  try
    Result := TMergedIterator.Create(FS.icmp, vIters, v.NewIterator(ParaAuxt, ParaSlice, ParaRo));
  finally
    v.release;
  end;
end;

function TDB.AcquireSnapshot: TSnapshot;
begin
  EnterCriticalSection(FSnapsMu);
  try
    if FSnapsList.Count = 0 then
      Result := TSnapshot.Create(Self, FSeq)
    else
      Result := TSnapshot.Create(Self, FSnapsList.Last.Seq);
    FSnapsList.Add(Result);
  finally
    LeaveCriticalSection(FSnapsMu);
  end;
  AtomicIncrement(FAliveSnaps);
end;

procedure TDB.ReleaseSnapshot(ParaSe: TSnapshot);
begin
  EnterCriticalSection(FSnapsMu);
  try
    FSnapsList.Remove(ParaSe);
  finally
    LeaveCriticalSection(FSnapsMu);
  end;
  AtomicDecrement(FAliveSnaps);
end;

function TDB.Get(ParaKey: TBytes; ParaRo: TReadOptions): TPair<TBytes, Exception>;
var
  vErr: Exception;
  vSe: TSnapshot;
begin
  vErr := Ok;
  if vErr <> nil then
  begin
    Result := TPair<TBytes, Exception>.Create(nil, vErr);
    Exit;
  end;

  vSe := AcquireSnapshot;
  try
    Result := Get(nil, nil, ParaKey, vSe.Seq, ParaRo);
  finally
    ReleaseSnapshot(vSe);
  end;
end;

function TDB.Get2(ParaKey: TBytes; ParaRo: TReadOptions; ParaAuxm: TMemDB; ParaSeq: UInt64): TPair<TBytes, Exception>;
var
  vErr: Exception;
begin
  vErr := Ok;
  if vErr <> nil then
  begin
    Result := TPair<TBytes, Exception>.Create(nil, vErr);
    Exit;
  end;

  Result := Get(ParaAuxm, nil, ParaKey, ParaSeq, ParaRo);
end;

function TDB.Has(ParaKey: TBytes; ParaRo: TReadOptions): TPair<Boolean, Exception>;
var
  vErr: Exception;
  vSe: TSnapshot;
begin
  vErr := Ok;
  if vErr <> nil then
  begin
    Result := TPair<Boolean, Exception>.Create(False, vErr);
    Exit;
  end;

  vSe := AcquireSnapshot;
  try
    Result := Has(nil, nil, ParaKey, vSe.Seq, ParaRo);
  finally
    ReleaseSnapshot(vSe);
  end;
end;

function TDB.NewIterator(ParaSlice: TRange; ParaRo: TReadOptions): IIterator;
var
  vErr: Exception;
  vSe: TSnapshot;
begin
  vErr := Ok;
  if vErr <> nil then
  begin
    Result := TEmptyIterator.Create(vErr);
    Exit;
  end;

  vSe := AcquireSnapshot;
  try
    Result := NewIterator(nil, nil, vSe.Seq, ParaSlice, ParaRo);
  finally
    ReleaseSnapshot(vSe);
  end;
end;

function TDB.NewIterator2(ParaSlice: TRange; ParaRo: TReadOptions; ParaAuxm: TMemDB; ParaSeq: UInt64): IIterator;
var
  vErr: Exception;
begin
  vErr := Ok;
  if vErr <> nil then
  begin
    Result := TEmptyIterator.Create(vErr);
    Exit;
  end;

  Result := NewIterator(ParaAuxm, nil, ParaSeq, ParaSlice, ParaRo);
end;

function TDB.GetSnapshot: TPair<TSnapshot, Exception>;
var
  vErr: Exception;
begin
  vErr := Ok;
  if vErr <> nil then
    Result := TPair<TSnapshot, Exception>.Create(nil, vErr)
  else
    Result := TPair<TSnapshot, Exception>.Create(AcquireSnapshot, nil);
end;

function TDB.GetProperty(ParaName: string): TPair<string, Exception>;
var
  vErr: Exception;
  vPrefix: string;
  vP: string;
  v: TVersion;
  vNumFilesPrefix: string;
  vLevel: Cardinal;
  vRest: string;
  vN: Integer;
  vValue: string;
  vTables: TList<TTable>;
  vDuration: TTimeSpan;
  vRead, vWrite: Int64;
  vI: Integer;
  vT: TTable;
  vWriteDelayN: Integer;
  vWriteDelay: TTimeSpan;
  vPaused: Boolean;
begin
  vErr := Ok;
  if vErr <> nil then
  begin
    Result := TPair<string, Exception>.Create('', vErr);
    Exit;
  end;

  vPrefix := 'leveldb.';
  if not StartsStr(vPrefix, ParaName) then
  begin
    Result := TPair<string, Exception>.Create('', ErrNotFound);
    Exit;
  end;
  vP := Copy(ParaName, Length(vPrefix) + 1, MaxInt);

  v := FS.version;
  try
    vNumFilesPrefix := 'num-files-at-level';
    if StartsStr(vNumFilesPrefix, vP) then
    begin
      vN := SScanf(Copy(vP, Length(vNumFilesPrefix) + 1, MaxInt), '%d%s', [@vLevel, @vRest]);
      if vN <> 1 then
        Result := TPair<string, Exception>.Create('', ErrNotFound)
      else
        Result := TPair<string, Exception>.Create(IntToStr(v.tLen(vLevel)), nil);
    end
    else if vP = 'stats' then
    begin
      vValue := 'Compactions' + sLineBreak +
        ' Level |   Tables   |    Size(MB)   |    Time(sec)  |    Read(MB)   |   Write(MB)' + sLineBreak +
        '-------+------------+---------------+---------------+---------------+---------------' + sLineBreak;
      for vI := 0 to High(v.levels) do
      begin
        vTables := v.levels[vI];
        FCompStats.GetStat(vI, vDuration, vRead, vWrite);
        if (vTables.Count = 0) and (vDuration = 0) then
          Continue;
        vValue := vValue + Format(' %3d   | %10d | %13.5f | %13.5f | %13.5f | %13.5f' + sLineBreak,
          [vI, vTables.Count, vTables.Size / 1048576.0, vDuration.TotalSeconds, vRead / 1048576.0, vWrite / 1048576.0]);
      end;
      Result := TPair<string, Exception>.Create(vValue, nil);
    end
    else if vP = 'iostats' then
    begin
      Result := TPair<string, Exception>.Create(Format('Read(MB):%.5f Write(MB):%.5f', [FS.stor.Reads / 1048576.0, FS.stor.Writes / 1048576.0]), nil);
    end
    else if vP = 'writedelay' then
    begin
      vWriteDelayN := AtomicGetValue(FCWriteDelayN);
      vWriteDelay := TTimeSpan.FromTicks(AtomicGetValue(FCWriteDelay));
      vPaused := AtomicGetValue(FInWritePaused) = 1;
      Result := TPair<string, Exception>.Create(Format('DelayN:%d Delay:%s Paused:%t', [vWriteDelayN, vWriteDelay.ToString, vPaused]), nil);
    end
    else if vP = 'sstables' then
    begin
      for vI := 0 to High(v.levels) do
      begin
        vTables := v.levels[vI];
        vValue := vValue + Format('--- level %d ---' + sLineBreak, [vI]);
        for vT in vTables do
          vValue := vValue + Format('%d:%d[%q .. %q]' + sLineBreak, [vT.fd.Num, vT.size, vT.imin, vT.imax]);
      end;
      Result := TPair<string, Exception>.Create(vValue, nil);
    end
    else if vP = 'blockpool' then
    begin
      Result := TPair<string, Exception>.Create(FS.tops.bpool.ToString, nil);
    end
    else if vP = 'cachedblock' then
    begin
      if FS.tops.bcache <> nil then
        Result := TPair<string, Exception>.Create(IntToStr(FS.tops.bcache.Size), nil)
      else
        Result := TPair<string, Exception>.Create('<nil>', nil);
    end
    else if vP = 'openedtables' then
    begin
      Result := TPair<string, Exception>.Create(IntToStr(FS.tops.cache.Size), nil);
    end
    else if vP = 'alivesnaps' then
    begin
      Result := TPair<string, Exception>.Create(IntToStr(AtomicGetValue(FAliveSnaps)), nil);
    end
    else if vP = 'aliveiters' then
    begin
      Result := TPair<string, Exception>.Create(IntToStr(AtomicGetValue(FAliveIters)), nil);
    end
    else
      Result := TPair<string, Exception>.Create('', ErrNotFound);
  finally
    v.release;
  end;
end;

function TDB.Stats(ParaS: TDBStats): Exception;
var
  vErr: Exception;
  v: TVersion;
  vI: Integer;
  vTables: TList<TTable>;
  vDuration: TTimeSpan;
  vRead, vWrite: Int64;
begin
  vErr := Ok;
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;

  ParaS.IORead := FS.stor.Reads;
  ParaS.IOWrite := FS.stor.Writes;
  ParaS.WriteDelayCount := AtomicGetValue(FCWriteDelayN);
  ParaS.WriteDelayDuration := TTimeSpan.FromTicks(AtomicGetValue(FCWriteDelay));
  ParaS.WritePaused := AtomicGetValue(FInWritePaused) = 1;

  ParaS.OpenedTablesCount := FS.tops.cache.Size;
  if FS.tops.bcache <> nil then
    ParaS.BlockCacheSize := FS.tops.bcache.Size
  else
    ParaS.BlockCacheSize := 0;

  ParaS.AliveIterators := AtomicGetValue(FAliveIters);
  ParaS.AliveSnapshots := AtomicGetValue(FAliveSnaps);

  SetLength(ParaS.LevelDurations, 0);
  SetLength(ParaS.LevelRead, 0);
  SetLength(ParaS.LevelWrite, 0);
  SetLength(ParaS.LevelSizes, 0);
  SetLength(ParaS.LevelTablesCounts, 0);

  v := FS.version;
  try
    for vI := 0 to High(v.levels) do
    begin
      vTables := v.levels[vI];
      FCompStats.GetStat(vI, vDuration, vRead, vWrite);
      if (vTables.Count = 0) and (vDuration = 0) then
        Continue;
      ParaS.LevelDurations := ParaS.LevelDurations + [vDuration];
      ParaS.LevelRead := ParaS.LevelRead + [vRead];
      ParaS.LevelWrite := ParaS.LevelWrite + [vWrite];
      ParaS.LevelSizes := ParaS.LevelSizes + [vTables.Size];
      ParaS.LevelTablesCounts := ParaS.LevelTablesCounts + [vTables.Count];
    end;
  finally
    v.release;
  end;
  Result := nil;
end;

function TDB.SizeOf(ParaRanges: TArray<TRange>): TPair<TSizes, Exception>;
var
  vErr: Exception;
  v: TVersion;
  vSizes: TSizes;
  vR: TRange;
  vImin, vImax: TBytes;
  vStart, vLimit, vSize: Int64;
begin
  vErr := Ok;
  if vErr <> nil then
  begin
    Result := TPair<TSizes, Exception>.Create(nil, vErr);
    Exit;
  end;

  v := FS.version;
  try
    SetLength(vSizes, 0);
    for vR in ParaRanges do
    begin
      vImin := MakeInternalKey(nil, vR.Start, KeyMaxSeq, TKeyType.KeyTypeSeek);
      vImax := MakeInternalKey(nil, vR.Limit, KeyMaxSeq, TKeyType.KeyTypeSeek);
      vStart := v.OffsetOf(vImin, vErr);
      if vErr <> nil then
      begin
        Result := TPair<TSizes, Exception>.Create(nil, vErr);
        Exit;
      end;
      vLimit := v.OffsetOf(vImax, vErr);
      if vErr <> nil then
      begin
        Result := TPair<TSizes, Exception>.Create(nil, vErr);
        Exit;
      end;
      if vLimit >= vStart then
        vSize := vLimit - vStart
      else
        vSize := 0;
      vSizes := vSizes + [vSize];
    end;
    Result := TPair<TSizes, Exception>.Create(vSizes, nil);
  finally
    v.release;
  end;
end;

procedure TDB.Close;
var
  vErr, vErr1: Exception;
begin
  if not SetClosed then
    Exit(ErrClosed);

  FS.Log('db@close closing');

  // Get compaction error.
  FCompErrC.TryReceive(vErr);
  if (vErr <> nil) and (vErr is EReadOnly) then
    vErr := nil;

  // Signal all goroutines.
  FCloseC.Close;

  // Discard open transaction.
  if FTr <> nil then
    FTr.Discard;

  // Acquire writer lock.
  FWriteLockC.Send(True);

  // Wait for all gorotines to exit.
  FCloseW.Wait;

  // Closes journal.
  if FJournal <> nil then
  begin
    FJournal.Close;
    FJournalWriter.Close;
    FJournal := nil;
    FJournalWriter := nil;
  end;

  if FWriteDelayN > 0 then
    FS.LogF('db@write was delayed N·%d T·%v', [FWriteDelayN, FWriteDelay]);

  // Close session.
  FS.Close;
  FS.LogF('db@close done T·%v', [Now - FS.StartTime]);
  FS.Release;

  if FCloser <> nil then
  begin
    vErr1 := (FCloser as IInterface as IClosable).Close;
    if vErr = nil then
      vErr := vErr1;
    FCloser := nil;
  end;

  // Clear memdbs.
  ClearMems;

  if vErr <> nil then
    raise vErr;
end;

end.
