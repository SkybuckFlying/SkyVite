unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DBIter;

interface

uses
  System.Math,
  System.SyncObjs,
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Batch,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Db,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DbSnapshot,
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
  TmemDB = class; // Forward

  TMemdbReleaser = class(TInterfacedObject, IReleaser)
  private
    mM: TmemDB;
    mOnce: Integer;
  public
    constructor Create(ParaM: TmemDB);
    procedure Release;
  end;

  TDir = (dirReleased, dirSOI, dirEOI, dirBackward, dirForward);

  TdbIter = class(TBasicReleaser, IIteratorSeeker, ICommonIterator, IIterator)
  private
    mDb: TDB;
    mIcmp: IComparer;
    mIter: IIterator;
    mSeq: UInt64;
    mStrict: Boolean;
    mDisableSampling: Boolean;

    mSamplingGap: Integer;
    mDir: TDir;
    mKey: TBytes;
    mValue: TBytes;
    mErr: Exception;

    procedure SampleSeek;
    procedure SetErr(ParaErr: Exception);
    procedure IterErr;
    function DoNext: Boolean;
    function DoPrev: Boolean;
  public
    constructor Create(ParaDb: TDB; ParaIcmp: IComparer; ParaIter: IIterator; ParaSeq: UInt64; ParaStrict: Boolean);
    destructor Destroy; override;

    function Valid: Boolean; virtual;
    function First: Boolean; virtual;
    function Last: Boolean; virtual;
    function Seek(const ParaKey: TBytes): Boolean; virtual;
    function Next: Boolean; virtual;
    function Prev: Boolean; virtual;
    function Key: TBytes; virtual;
    function Value: TBytes; virtual;
    function Error: Exception; virtual;
    procedure Release; override;
  end;

implementation

uses
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.DB;

{ TMemdbReleaser }

constructor TMemdbReleaser.Create(ParaM: TmemDB);
begin
  inherited Create;
  mM := ParaM;
end;

procedure TMemdbReleaser.Release;
begin
  if TInterlocked.CompareExchange(mOnce, 1, 0) = 0 then
  begin
    if mM <> nil then
      // mM.Decref;
    mM := nil;
  end;
end;

{ TdbIter }

constructor TdbIter.Create(ParaDb: TDB; ParaIcmp: IComparer; ParaIter: IIterator; ParaSeq: UInt64; ParaStrict: Boolean);
begin
  inherited Create;
  mDb := ParaDb;
  mIcmp := ParaIcmp;
  mIter := ParaIter;
  mSeq := ParaSeq;
  mStrict := ParaStrict;
  mDir := dirSOI;
end;

destructor TdbIter.Destroy;
begin
  inherited;
end;

function TdbIter.DoNext: Boolean;
var
  vUkey: TBytes;
  vSeq: UInt64;
  vKt: TKeyType;
  vKerr: Exception;
begin
  while True do
  begin
    vKerr := TInternalKey.ParseInternalKey(mIter.Key, vUkey, vSeq, vKt);
    if vKerr = nil then
    begin
      SampleSeek;
      if vSeq <= mSeq then
      begin
        case vKt of
          ktDel:
            begin
              mKey := Copy(vUkey, 0, Length(vUkey));
              mDir := dirForward;
            end;
          ktVal:
            begin
              if (mDir = dirSOI) or (mIcmp.Compare(vUkey, mKey) > 0) then
              begin
                mKey := Copy(vUkey, 0, Length(vUkey));
                mValue := Copy(mIter.Value, 0, Length(mIter.Value));
                mDir := dirForward;
                Exit(True);
              end;
            end;
        end;
      end;
    end
    else if mStrict then
    begin
      SetErr(vKerr);
      Break;
    end;

    if not mIter.Next then
    begin
      mDir := dirEOI;
      IterErr;
      Break;
    end;
  end;
  Result := False;
end;

function TdbIter.DoPrev: Boolean;
var
  vDel: Boolean;
  vUkey: TBytes;
  vSeq: UInt64;
  vKt: TKeyType;
  vKerr: Exception;
begin
  mDir := dirBackward;
  vDel := True;
  if mIter.Valid then
  begin
    while True do
    begin
      vKerr := TInternalKey.ParseInternalKey(mIter.Key, vUkey, vSeq, vKt);
      if vKerr = nil then
      begin
        SampleSeek;
        if vSeq <= mSeq then
        begin
          if (not vDel) and (mIcmp.Compare(vUkey, mKey) < 0) then
            Exit(True);
          vDel := (vKt = ktDel);
          if not vDel then
          begin
            mKey := Copy(vUkey, 0, Length(vUkey));
            mValue := Copy(mIter.Value, 0, Length(mIter.Value));
          end;
        end;
      end
      else if mStrict then
      begin
        SetErr(vKerr);
        Exit(False);
      end;

      if not mIter.Prev then
        Break;
    end;
  end;

  if vDel then
  begin
    mDir := dirSOI;
    IterErr;
    Exit(False);
  end;
  Result := True;
end;

function TdbIter.Error: Exception;
begin
  Result := mErr;
end;

function TdbIter.First: Boolean;
begin
  if mErr <> nil then Exit(False);
  if mDir = dirReleased then
  begin
    mErr := Exception.Create('leveldb: iterator released');
    Exit(False);
  end;

  if mIter.First then
  begin
    mDir := dirSOI;
    Exit(DoNext);
  end;
  mDir := dirEOI;
  IterErr;
  Result := False;
end;

procedure TdbIter.IterErr;
begin
  if mIter.Error <> nil then
    SetErr(mIter.Error);
end;

function TdbIter.Key: TBytes;
begin
  if (mErr <> nil) or (mDir <= dirEOI) then
    Exit(nil);
  Result := mKey;
end;

function TdbIter.Last: Boolean;
begin
  if mErr <> nil then Exit(False);
  if mDir = dirReleased then
  begin
    mErr := Exception.Create('leveldb: iterator released');
    Exit(False);
  end;

  if mIter.Last then
    Exit(DoPrev);
  mDir := dirSOI;
  IterErr;
  Result := False;
end;

function TdbIter.Next: Boolean;
begin
  if (mDir = dirEOI) or (mErr <> nil) then
    Exit(False);
  if mDir = dirReleased then
  begin
    mErr := Exception.Create('leveldb: iterator released');
    Exit(False);
  end;

  if (not mIter.Next) or ((mDir = dirBackward) and (not mIter.Next)) then
  begin
    mDir := dirEOI;
    IterErr;
    Exit(False);
  end;
  Result := DoNext;
end;

function TdbIter.Prev: Boolean;
begin
  if (mDir = dirSOI) or (mErr <> nil) then
    Exit(False);
  if mDir = dirReleased then
  begin
    mErr := Exception.Create('leveldb: iterator released');
    Exit(False);
  end;

  case mDir of
    dirEOI: Exit(Last);
    dirForward:
      begin
        while mIter.Prev do
        begin
          // Logic to skip keys with same ukey but higher seq
          // Simplified for now
          break;
        end;
      end;
  end;
  Result := DoPrev;
end;

procedure TdbIter.Release;
begin
  if mDir <> dirReleased then
  begin
    mDir := dirReleased;
    mKey := nil;
    mValue := nil;
    if mIter <> nil then
    begin
      mIter.Release;
      mIter := nil;
    end;
    if mDb <> nil then
    begin
      // TInterlocked.Decrement(mDb.mAliveIters);
      mDb := nil;
    end;
    inherited;
  end;
end;

procedure TdbIter.SampleSeek;
begin
  // Trigger sampling in DB
end;

function TdbIter.Seek(const ParaKey: TBytes): Boolean;
var
  vIkey: TInternalKey;
begin
  if mErr <> nil then Exit(False);
  if mDir = dirReleased then
  begin
    mErr := Exception.Create('leveldb: iterator released');
    Exit(False);
  end;

  vIkey := TInternalKey.Create(ParaKey, keyMaxSeq, ktVal); // ktVal or ktSeek?
  try
    if mIter.Seek(vIkey.Data) then
    begin
      mDir := dirSOI;
      Exit(DoNext);
    end;
  finally
    vIkey.Free;
  end;
  mDir := dirEOI;
  IterErr;
  Result := False;
end;

procedure TdbIter.SetErr(ParaErr: Exception);
begin
  mErr := ParaErr;
  mKey := nil;
  mValue := nil;
end;

function TdbIter.Valid: Boolean;
begin
  Result := (mErr = nil) and (mDir > dirEOI);
end;

function TdbIter.Value: TBytes;
begin
  if (mErr <> nil) or (mDir <= dirEOI) then
    Exit(nil);
  Result := mValue;
end;

end.
