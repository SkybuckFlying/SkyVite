unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs,
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Batch,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Cache.Cache,
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
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.IndexedIter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Iterator.Iter,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Opt.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Options,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Session,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionCompaction,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionRecord,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.SessionUtil,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Storage.Storage,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Reader,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Table,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Writer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Version;

type
  IComparer = Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.Comparer.IComparer;
  TSession = class; // Circular dependency to be handled in Session.pas

  TtFile = class
  public
    Fd: TFileDesc;
    SeekLeft: Integer;
    Size: Int64;
    Imin: TInternalKey;
    Imax: TInternalKey;

    constructor Create(const ParaFd: TFileDesc; ParaSize: Int64; const ParaImin, ParaImax: TInternalKey);
    function After(ParaIcmp: IComparer; const ParaUkey: TBytes): Boolean;
    function Before(ParaIcmp: IComparer; const ParaUkey: TBytes): Boolean;
    function Overlaps(ParaIcmp: IComparer; const ParaUmin, ParaUmax: TBytes): Boolean;
    function ConsumeSeek: Integer;
  end;

  TtFiles = class(TList<TtFile>)
  public
    function Nums: string;
    procedure SortByKey(ParaIcmp: IComparer);
    procedure SortByNum;
    function TotalSize: Int64;
    function SearchMin(ParaIcmp: IComparer; const ParaIkey: TInternalKey): Integer;
    function SearchMax(ParaIcmp: IComparer; const ParaIkey: TInternalKey): Integer;
    function SearchNumLess(ParaNum: Int64): Integer;
    function SearchMinUkey(ParaIcmp: IComparer; const ParaUmin: TBytes): Integer;
    function SearchMaxUkey(ParaIcmp: IComparer; const ParaUmax: TBytes): Integer;
    function Overlaps(ParaIcmp: IComparer; const ParaUmin, ParaUmax: TBytes; ParaUnsorted: Boolean): Boolean;
    function GetOverlaps(ParaDst: TtFiles; ParaIcmp: IComparer; const ParaUmin, ParaUmax: TBytes; ParaOverlapped: Boolean): TtFiles;
    procedure GetRange(ParaIcmp: IComparer; out ParaImin, ParaImax: TInternalKey);
    // function NewIndexIterator(ParaTops: TtOps; ParaIcmp: IComparer; ParaSlice: TRange; ParaRO: TReadOptions): IIteratorIndexer;
  end;

  TtOps = class
  private
    mSession: TSession;
    mNoSync: Boolean;
    mEvictRemoved: Boolean;
    mCache: TCache;
    mBcache: TCache;
    // mBpool: TBufferPool;
  public
    constructor Create(ParaSession: TSession);
    destructor Destroy; override;
    // function Open(ParaF: TtFile): THandle;
    // function Find(ParaF: TtFile; const ParaKey: TBytes; ParaRO: TReadOptions): TFindResult;
    // function NewIterator(ParaF: TtFile; ParaSlice: TRange; ParaRO: TReadOptions): IIterator;
    procedure Remove(const ParaFd: TFileDesc);
    procedure Close;
  end;

implementation

{ TtFile }

function TtFile.After(ParaIcmp: IComparer; const ParaUkey: TBytes): Boolean;
begin
  Result := (ParaUkey <> nil) and (ParaIcmp.Compare(ParaUkey, Imax.Ukey) > 0);
end;

function TtFile.Before(ParaIcmp: IComparer; const ParaUkey: TBytes): Boolean;
begin
  Result := (ParaUkey <> nil) and (ParaIcmp.Compare(ParaUkey, Imin.Ukey) < 0);
end;

function TtFile.ConsumeSeek: Integer;
begin
  Result := TInterlocked.Decrement(SeekLeft);
end;

constructor TtFile.Create(const ParaFd: TFileDesc; ParaSize: Int64; const ParaImin, ParaImax: TInternalKey);
begin
  Fd := ParaFd;
  Size := ParaSize;
  Imin := ParaImin;
  Imax := ParaImax;
  SeekLeft := Integer(Size div 16384);
  if SeekLeft < 100 then
    SeekLeft := 100;
end;

function TtFile.Overlaps(ParaIcmp: IComparer; const ParaUmin, ParaUmax: TBytes): Boolean;
begin
  Result := (not After(ParaIcmp, ParaUmin)) and (not Before(ParaIcmp, ParaUmax));
end;

{ TtFiles }

function TtFiles.GetOverlaps(ParaDst: TtFiles; ParaIcmp: IComparer; const ParaUmin, ParaUmax: TBytes; ParaOverlapped: Boolean): TtFiles;
var
  vBegin, vEnd: Integer;
  vIndex: Integer;
  vT: TtFile;
  vUmin, vUmax: TBytes;
  vRestart: Boolean;
  i: Integer;
begin
  if Count = 0 then
    Exit(nil);

  if not ParaOverlapped then
  begin
    vBegin := 0;
    vEnd := Count;
    if ParaUmin <> nil then
    begin
      vIndex := SearchMinUkey(ParaIcmp, ParaUmin);
      if vIndex = 0 then
        vBegin := 0
      else if CompareMemory(@Items[vIndex - 1].Imax.Ukey[0], @ParaUmin[0], Length(ParaUmin)) >= 0 then
        vBegin := vIndex - 1
      else
        vBegin := vIndex;
    end;
    if ParaUmax <> nil then
    begin
      vIndex := SearchMaxUkey(ParaIcmp, ParaUmax);
      if vIndex = Count then
        vEnd := Count
      else if CompareMemory(@Items[vIndex].Imin.Ukey[0], @ParaUmax[0], Length(ParaUmax)) <= 0 then
        vEnd := vIndex + 1
      else
        vEnd := vIndex;
    end;
    if vBegin >= vEnd then
      Exit(nil);
    if ParaDst = nil then
      ParaDst := TtFiles.Create;
    ParaDst.Clear;
    for i := vBegin to vEnd - 1 do
      ParaDst.Add(Items[i]);
    Exit(ParaDst);
  end;

  vUmin := ParaUmin;
  vUmax := ParaUmax;
  if ParaDst = nil then
    ParaDst := TtFiles.Create;
  ParaDst.Clear;
  i := 0;
  while i < Count do
  begin
    vT := Items[i];
    if vT.Overlaps(ParaIcmp, vUmin, vUmax) then
    begin
      vRestart := False;
      if (vUmin <> nil) and (ParaIcmp.Compare(vT.Imin.Ukey, vUmin) < 0) then
      begin
        vUmin := vT.Imin.Ukey;
        ParaDst.Clear;
        vRestart := True;
      end
      else if (vUmax <> nil) and (ParaIcmp.Compare(vT.Imax.Ukey, vUmax) > 0) then
      begin
        vUmax := vT.Imax.Ukey;
        ParaDst.Clear;
        vRestart := True;
      end;

      if vRestart then
      begin
        i := 0;
        continue;
      end;
      ParaDst.Add(vT);
    end;
    Inc(i);
  end;
  Result := ParaDst;
end;

procedure TtFiles.GetRange(ParaIcmp: IComparer; out ParaImin, ParaImax: TInternalKey);
var
  i: Integer;
  vT: TtFile;
begin
  for i := 0 to Count - 1 do
  begin
    vT := Items[i];
    if i = 0 then
    begin
      ParaImin := vT.Imin;
      ParaImax := vT.Imax;
      continue;
    end;
    if ParaIcmp.Compare(vT.Imin, ParaImin) < 0 then
      ParaImin := vT.Imin;
    if ParaIcmp.Compare(vT.Imax, ParaImax) > 0 then
      ParaImax := vT.Imax;
  end;
end;

function TtFiles.Nums: string;
var
  i: Integer;
begin
  Result := '[ ';
  for i := 0 to Count - 1 do
  begin
    if i <> 0 then
      Result := Result + ', ';
    Result := Result + IntToStr(Items[i].Fd.Num);
  end;
  Result := Result + ' ]';
end;

function TtFiles.Overlaps(ParaIcmp: IComparer; const ParaUmin, ParaUmax: TBytes; ParaUnsorted: Boolean): Boolean;
var
  i: Integer;
begin
  if ParaUnsorted then
  begin
    for i := 0 to Count - 1 do
      if Items[i].Overlaps(ParaIcmp, ParaUmin, ParaUmax) then
        Exit(True);
    Exit(False);
  end;

  i := 0;
  if ParaUmin <> nil then
    i := SearchMax(ParaIcmp, TInternalKeyHelper.Create(nil, ParaUmin, KEY_MAX_SEQ, ktSeek));

  if i >= Count then
    Exit(False);

  Result := not Items[i].Before(ParaIcmp, ParaUmax);
end;

function TtFiles.SearchMax(ParaIcmp: IComparer; const ParaIkey: TInternalKey): Integer;
var
  vLow, vHigh, vMid: Integer;
begin
  vLow := 0;
  vHigh := Count;
  while vLow < vHigh do
  begin
    vMid := vLow + (vHigh - vLow) div 2;
    if ParaIcmp.Compare(Items[vMid].Imax, ParaIkey) < 0 then
      vLow := vMid + 1
    else
      vHigh := vMid;
  end;
  Result := vLow;
end;

function TtFiles.SearchMaxUkey(ParaIcmp: IComparer; const ParaUmax: TBytes): Integer;
var
  vLow, vHigh, vMid: Integer;
begin
  vLow := 0;
  vHigh := Count;
  while vLow < vHigh do
  begin
    vMid := vLow + (vHigh - vLow) div 2;
    if ParaIcmp.Compare(Items[vMid].Imax.Ukey, ParaUmax) <= 0 then
      vLow := vMid + 1
    else
      vHigh := vMid;
  end;
  Result := vLow;
end;

function TtFiles.SearchMin(ParaIcmp: IComparer; const ParaIkey: TInternalKey): Integer;
var
  vLow, vHigh, vMid: Integer;
begin
  vLow := 0;
  vHigh := Count;
  while vLow < vHigh do
  begin
    vMid := vLow + (vHigh - vLow) div 2;
    if ParaIcmp.Compare(Items[vMid].Imin, ParaIkey) < 0 then
      vLow := vMid + 1
    else
      vHigh := vMid;
  end;
  Result := vLow;
end;

function TtFiles.SearchMinUkey(ParaIcmp: IComparer; const ParaUmin: TBytes): Integer;
var
  vLow, vHigh, vMid: Integer;
begin
  vLow := 0;
  vHigh := Count;
  while vLow < vHigh do
  begin
    vMid := vLow + (vHigh - vLow) div 2;
    if ParaIcmp.Compare(Items[vMid].Imin.Ukey, ParaUmin) <= 0 then
      vLow := vMid + 1
    else
      vHigh := vMid;
  end;
  Result := vLow;
end;

function TtFiles.SearchNumLess(ParaNum: Int64): Integer;
var
  vLow, vHigh, vMid: Integer;
begin
  vLow := 0;
  vHigh := Count;
  while vLow < vHigh do
  begin
    vMid := vLow + (vHigh - vLow) div 2;
    if Items[vMid].Fd.Num >= ParaNum then
      vLow := vMid + 1
    else
      vHigh := vMid;
  end;
  Result := vLow;
end;

procedure TtFiles.SortByKey(ParaIcmp: IComparer);
begin
  Sort(TComparer<TtFile>.Construct(
    function(const Left, Right: TtFile): Integer
    begin
      Result := ParaIcmp.Compare(Left.Imin, Right.Imin);
      if Result = 0 then
      begin
        if Left.Fd.Num < Right.Fd.Num then Result := -1
        else if Left.Fd.Num > Right.Fd.Num then Result := 1;
      end;
    end));
end;

procedure TtFiles.SortByNum;
begin
  Sort(TComparer<TtFile>.Construct(
    function(const Left, Right: TtFile): Integer
    begin
      if Left.Fd.Num > Right.Fd.Num then Result := -1
      else if Left.Fd.Num < Right.Fd.Num then Result := 1
      else Result := 0;
    end));
end;

function TtFiles.TotalSize: Int64;
var
  vT: TtFile;
begin
  Result := 0;
  for vT in Self do
    Result := Result + vT.Size;
end;

{ TtOps }

procedure TtOps.Close;
begin
  mCache.Free;
  if mBcache <> nil then
    mBcache.Free;
end;

constructor TtOps.Create(ParaSession: TSession);
begin
  mSession := ParaSession;
  // Options logic to be implemented when TSession is available
end;

destructor TtOps.Destroy;
begin
  Close;
  inherited;
end;

procedure TtOps.Remove(const ParaFd: TFileDesc);
begin
  // Cache and storage removal logic
end;

end.
