// Copyright (c) 2012, Suryandaru Triandana <syndtr@gmail.com>
// All rights reserved.
//
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
unit Common.Db.XLevelDB.DB.Snapshot;

interface

uses
  Common.DB.XLevelDB.Batch,
  Common.DB.XLevelDB.Comparer,
  Common.Db.XLevelDB.DB,
  Common.DB.XLevelDB.DB.Compaction,
  Common.DB.XLevelDB.DB.Iter,
  Common.DB.XLevelDB.DB.State,
  Common.DB.XLevelDB.DB.Transaction,
  Common.DB.XLevelDB.DB.Util,
  Common.DB.XLevelDB.DB.Write,
  Common.DB.XLevelDB.Doc,
  Common.Db.XLevelDB.Errors,
  Common.DB.XLevelDB.Filter,
  Common.Db.XLevelDB.Iterator,
  Common.DB.XLevelDB.Key,
  Common.Db.XLevelDB.Opt,
  Common.DB.XLevelDB.Options,
  Common.DB.XLevelDB.Session,
  Common.DB.XLevelDB.Session.Compaction,
  Common.DB.XLevelDB.Session.Record,
  Common.DB.XLevelDB.Session.Util,
  Common.DB.XLevelDB.Storage,
  Common.DB.XLevelDB.Table,
  Common.Db.XLevelDB.Util,
  Common.DB.XLevelDB.Version,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils;

type
  EErrSnapshotReleased = class(ELevelDBError);

  TSnapshotElement = class
  public
    Seq: UInt64;
    Ref: Integer;
    E: TList<TSnapshotElement>.TNode;
  end;

  // Snapshot is a DB snapshot.
  TSnapshot = class
  private
    FDb: TDB;
    FElem: TSnapshotElement;
    FMu: TRTLCriticalSection;
    FReleased: Boolean;
  public
    constructor Create(ADB: TDB);
    destructor Destroy; override;
    function ToString: string;
    // Get gets the value for the given key. It returns ErrNotFound if
    // the DB does not contains the key.
    //
    // The caller should not modify the contents of the returned slice, but
    // it is safe to modify the contents of the argument after Get returns.
    function Get(AKey: TBytes; ARo: TReadOptions): TPair<TBytes, Exception>;
    // Has returns true if the DB does contains the given key.
    //
    // It is safe to modify the contents of the argument after Get returns.
    function Has(AKey: TBytes; ARo: TReadOptions): TPair<Boolean, Exception>;
    // NewIterator returns an iterator for the snapshot of the underlying DB.
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
    // Releasing the snapshot doesn't mean releasing the iterator too, the
    // iterator would be still valid until released.
    //
    // Also read Iterator documentation of the leveldb/iterator package.
    function NewIterator(ASlice: TRange; ARo: TReadOptions): IIterator;
    // Release releases the snapshot. This will not release any returned
    // iterators, the iterators would still be valid until released or the
    // underlying DB is closed.
    //
    // Other methods should not be called after the snapshot has been released.
    procedure Release;
  end;

implementation

{ TSnapshot }

constructor TSnapshot.Create(ADB: TDB);
begin
  inherited Create;
  FDb := ADB;
  FElem := FDb.AcquireSnapshot;
  TInterlocked.Increment(FDb.FAliveSnaps);
end;

destructor TSnapshot.Destroy;
begin
  Release;
  inherited;
end;

function TSnapshot.ToString: string;
begin
  Result := Format('leveldb.Snapshot{%d}', [FElem.Seq]);
end;

function TSnapshot.Get(AKey: TBytes; ARo: TReadOptions): TPair<TBytes, Exception>;
var
  vErr: Exception;
begin
  vErr := FDb.Ok;
  if vErr <> nil then
  begin
    Result := TPair<TBytes, Exception>.Create(nil, vErr);
    Exit;
  end;

  EnterCriticalSection(FMu);
  try
    if FReleased then
    begin
      Result := TPair<TBytes, Exception>.Create(nil, EErrSnapshotReleased.Create(''));
      Exit;
    end;
    Result := FDb.Get(nil, nil, AKey, FElem.Seq, ARo);
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TSnapshot.Has(AKey: TBytes; ARo: TReadOptions): TPair<Boolean, Exception>;
var
  vErr: Exception;
begin
  vErr := FDb.Ok;
  if vErr <> nil then
  begin
    Result := TPair<Boolean, Exception>.Create(False, vErr);
    Exit;
  end;

  EnterCriticalSection(FMu);
  try
    if FReleased then
    begin
      Result := TPair<Boolean, Exception>.Create(False, EErrSnapshotReleased.Create(''));
      Exit;
    end;
    Result := FDb.Has(nil, nil, AKey, FElem.Seq, ARo);
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TSnapshot.NewIterator(ASlice: TRange; ARo: TReadOptions): IIterator;
var
  vErr: Exception;
begin
  vErr := FDb.Ok;
  if vErr <> nil then
    Exit(TEmptyIterator.Create(vErr));

  EnterCriticalSection(FMu);
  try
    if FReleased then
      Exit(TEmptyIterator.Create(EErrSnapshotReleased.Create('')));
    Result := FDb.NewIterator(nil, nil, FElem.Seq, ASlice, ARo);
  finally
    LeaveCriticalSection(FMu);
  end;
end;

procedure TSnapshot.Release;
begin
  EnterCriticalSection(FMu);
  try
    if not FReleased then
    begin
      FReleased := True;
      FDb.ReleaseSnapshot(FElem);
      TInterlocked.Decrement(FDb.FAliveSnaps);
      FDb := nil;
      FElem := nil;
    end;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

end.
