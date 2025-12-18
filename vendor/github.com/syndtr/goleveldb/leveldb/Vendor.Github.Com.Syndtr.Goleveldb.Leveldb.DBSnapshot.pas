unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DBSnapshot;

interface

uses
  System.SyncObjs,
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Batch,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Db,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbState,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbTransaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DBUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbWrite,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Doc,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Errors,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
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
  TDB = class; // Forward
  TSnapshotElement = class; // Forward

  TSnapshot = class(TInterfacedObject, IReader)
  private
    mDb: TDB;
    mElem: TSnapshotElement;
    mMu: TLightweightMREW;
    mReleased: Boolean;
  public
    constructor Create(ParaDb: TDB; ParaElem: TSnapshotElement);
    destructor Destroy; override;
    
    function Get(const ParaKey: TBytes; ParaRO: TReadOptions; out ParaValue: TBytes): Exception;
    function NewIterator(ParaSlice: TRange; ParaRO: TReadOptions): IIterator;
    procedure Release;
    
    property Elem: TSnapshotElement read mElem;
  end;

  TSnapshotElement = class
  public
    Seq: UInt64;
    Ref: Integer;
    // Managed by TDB's list
  end;

implementation

uses
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DB;

{ TSnapshot }

constructor TSnapshot.Create(ParaDb: TDB; ParaElem: TSnapshotElement);
begin
  inherited Create;
  mDb := ParaDb;
  mElem := ParaElem;
  mMu := TLightweightMREW.Create;
end;

destructor TSnapshot.Destroy;
begin
  Release;
  mMu.Free;
  inherited;
end;

function TSnapshot.Get(const ParaKey: TBytes; ParaRO: TReadOptions; out ParaValue: TBytes): Exception;
begin
  mMu.EnterRead;
  try
    if mReleased then
      Exit(Exception.Create('leveldb: snapshot released'));
    // Result := mDb.GetInternal(nil, nil, ParaKey, mElem.Seq, ParaRO, ParaValue);
    Result := nil;
  finally
    mMu.LeaveRead;
  end;
end;

function TSnapshot.NewIterator(ParaSlice: TRange; ParaRO: TReadOptions): IIterator;
begin
  mMu.EnterRead;
  try
    if mReleased then
      // Exit(TNewEmptyIterator.Create(Exception.Create('leveldb: snapshot released')));
      Exit(nil);
    // Result := mDb.NewIteratorInternal(nil, nil, mElem.Seq, ParaSlice, ParaRO);
    Result := nil;
  finally
    mMu.LeaveRead;
  end;
end;

procedure TSnapshot.Release;
begin
  mMu.EnterWrite;
  try
    if not mReleased then
    begin
      mReleased := True;
      // mDb.ReleaseSnapshot(mElem);
      mDb := nil;
      mElem := nil;
    end;
  finally
    mMu.LeaveWrite;
  end;
end;

end.
