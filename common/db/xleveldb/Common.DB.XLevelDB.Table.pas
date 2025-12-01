unit Common.Db.XLevelDb.Table;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Common.Db.XLevelDb.Storage,
  Common.Db.XLevelDb.Internal,
  Common.Db.XLevelDb.Comparer,
  Common.Db.XLevelDb.Cache,
  Common.Db.XLevelDb.Iterator,
  Common.Db.XLevelDb.Options,
  Common.Db.XLevelDb.Util;

type
  TtFile = record
    mFd: TFileDesc;
    mSeekLeft: Integer;
    mSize: Int64;
    mIMin, mIMax: TInternalKey;
    function After(ParaIcmp: IComparer; ParaUkey: TBytes): Boolean;
    function Before(ParaIcmp: IComparer; ParaUkey: TBytes): Boolean;
    function Overlaps(ParaIcmp: IComparer; ParaUMin, ParaUMax: TBytes): Boolean;
    function ConsumeSeek: Integer;
    class function New(ParaFd: TFileDesc; ParaSize: Int64; ParaIMin, ParaIMax: TInternalKey): TtFile; static;
  end;

  TtFiles = class(TObjectList<TtFile>)
  public
    function Nums: string;
    function LessByKey(ParaIcmp: IComparer; i, j: Integer): Boolean;
    function LessByNum(i, j: Integer): Boolean;
    procedure SortByKey(ParaIcmp: IComparer);
    procedure SortByNum;
    function Size: Int64;
    function SearchMin(ParaIcmp: IComparer; ParaIkey: TInternalKey): Integer;
    function SearchMax(ParaIcmp: IComparer; ParaIkey: TInternalKey): Integer;
    function Overlaps(ParaIcmp: IComparer; ParaUMin, ParaUMax: TBytes; ParaUnsorted: Boolean): Boolean;
    function GetOverlaps(ParaDst: TtFiles; ParaIcmp: IComparer; ParaUMin, ParaUMax: TBytes; ParaOverlapped: Boolean): TtFiles;
    procedure GetRange(ParaIcmp: IComparer; out ParaIMin, ParaIMax: TInternalKey);
    function NewIndexIterator(ParaTops: TtOps; ParaIcmp: IComparer; ParaSlice: PRange; ParaRo: TReadOptions): IIteratorIndexer;
  end;

  TtOps = class
  private
    mSession: TSession;
    mNoSync: Boolean;
    mCache: TCache;
    mBCache: TCache;
    mBPool: TBufferPool;
  public
    constructor Create(ParaSession: TSession);
    destructor Destroy; override;
    function CreateWriter: TtWriter;
    function CreateFrom(ParaSrc: IIterator): TtFile;
    function Open(ParaFile: TtFile): TCacheHandle;
    function Find(ParaFile: TtFile; ParaKey: TBytes; ParaRo: TReadOptions; out RKey, RValue: TBytes): Boolean;
    function FindKey(ParaFile: TtFile; ParaKey: TBytes; ParaRo: TReadOptions; out RKey: TBytes): Boolean;
    function OffsetOf(ParaFile: TtFile; ParaKey: TBytes): Int64;
    function NewIterator(ParaFile: TtFile; ParaSlice: PRange; ParaRo: TReadOptions): IIterator;
    procedure Remove(ParaFile: TtFile);
    procedure Close;
  end;

  TtWriter = class
  private
    mTOps: TtOps;
    mFd: TFileDesc;
    mWriter: IWriter;
    mTableWriter: TTableWriter;
    mFirst, mLast: TBytes;
  public
    constructor Create(ParaTOps: TtOps);
    destructor Destroy; override;
    function Append(ParaKey, ParaValue: TBytes): Boolean;
    function Empty: Boolean;
    procedure Close;
    function Finish: TtFile;
    procedure Drop;
  end;

implementation

uses
  System.Classes,
  GoToDelphi.Helpers.TChannel;

{ TtFile }

function TtFile.After(ParaIcmp: IComparer; ParaUkey: TBytes): Boolean;
begin
  Result := (ParaUkey <> nil) and (ParaIcmp.Compare(ParaUkey, mIMax.UKey) > 0);
end;

function TtFile.Before(ParaIcmp: IComparer; ParaUkey: TBytes): Boolean;
begin
  Result := (ParaUkey <> nil) and (ParaIcmp.Compare(ParaUkey, mIMin.UKey) < 0);
end;

function TtFile.Overlaps(ParaIcmp: IComparer; ParaUMin, ParaUMax: TBytes): Boolean;
begin
  Result := not After(ParaIcmp, ParaUMin) and not Before(ParaIcmp, ParaUMax);
end;

function TtFile.ConsumeSeek: Integer;
begin
  Result := TInterlocked.Decrement(mSeekLeft);
end;

class function TtFile.New(ParaFd: TFileDesc; ParaSize: Int64; ParaIMin, ParaIMax: TInternalKey): TtFile;
begin
  Result.mFd := ParaFd;
  Result.mSize := ParaSize;
  Result.mIMin := ParaIMin;
  Result.mIMax := ParaIMax;
  Result.mSeekLeft := Trunc(ParaSize / 16384);
  if Result.mSeekLeft < 100 then
  begin
    Result.mSeekLeft := 100;
  end;
end;

{ TtFiles }

function TtFiles.Nums: string;
var
  vI: Integer;
  vFile: TtFile;
begin
  Result := '[ ';
  for vI := 0 to Count - 1 do
  begin
    vFile := Items[vI];
    if vI <> 0 then
    begin
      Result := Result + ', ';
    end;
    Result := Result + IntToStr(vFile.mFd.Num);
  end;
  Result := Result + ' ]';
end;

function TtFiles.LessByKey(ParaIcmp: IComparer; i, j: Integer): Boolean;
var
  vA, vB: TtFile;
  vN: Integer;
begin
  vA := Items[i];
  vB := Items[j];
  vN := ParaIcmp.Compare(vA.mIMin, vB.mIMin);
  if vN = 0 then
  begin
    Result := vA.mFd.Num < vB.mFd.Num;
  end
  else
  begin
    Result := vN < 0;
  end;
end;

function TtFiles.LessByNum(i, j: Integer): Boolean;
begin
  Result := Items[i].mFd.Num > Items[j].mFd.Num;
end;

procedure TtFiles.SortByKey(ParaIcmp: IComparer);
begin
  Sort(TComparer<TtFile>.Construct(
    function(const Left, Right: TtFile): Integer
    begin
      if LessByKey(ParaIcmp, IndexOf(Left), IndexOf(Right)) then
        Result := -1
      else
        Result := 1;
    end));
end;

procedure TtFiles.SortByNum;
begin
  Sort(TComparer<TtComparer<TtFile>>.Construct(
    function(const Left, Right: TtFile): Integer
    begin
      if LessByNum(IndexOf(Left), IndexOf(Right)) then
        Result := -1
      else
        Result := 1;
    end));
end;

function TtFiles.Size: Int64;
var
  vFile: TtFile;
begin
  Result := 0;
  for vFile in Self do
  begin
    Result := Result + vFile.mSize;
  end;
end;

function TtFiles.SearchMin(ParaIcmp: IComparer; ParaIkey: TInternalKey): Integer;
var
  vLow, vHigh, vMid: Integer;
begin
  vLow := 0;
  vHigh := Count;
  while vLow < vHigh do
  begin
    vMid := vLow + (vHigh - vLow) div 2;
    if ParaIcmp.Compare(Items[vMid].mIMin, ParaIkey) >= 0 then
    begin
      vHigh := vMid;
    end
    else
    begin
      vLow := vMid + 1;
    end;
  end;
  Result := vLow;
end;

function TtFiles.SearchMax(ParaIcmp: IComparer; ParaIkey: TInternalKey): Integer;
var
  vLow, vHigh, vMid: Integer;
begin
  vLow := 0;
  vHigh := Count;
  while vLow < vHigh do
  begin
    vMid := vLow + (vHigh - vLow) div 2;
    if ParaIcmp.Compare(Items[vMid].mIMax, ParaIkey) >= 0 then
    begin
      vHigh := vMid;
    end
    else
    begin
      vLow := vMid + 1;
    end;
  end;
  Result := vLow;
end;

function TtFiles.Overlaps(ParaIcmp: IComparer; ParaUMin, ParaUMax: TBytes; ParaUnsorted: Boolean): Boolean;
var
  vI: Integer;
  vFile: TtFile;
begin
  if ParaUnsorted then
  begin
    for vFile in Self do
    begin
      if vFile.Overlaps(ParaIcmp, ParaUMin, ParaUMax) then
      begin
        Result := True;
        Exit;
      end;
    end;
    Result := False;
    Exit;
  end;

  vI := 0;
  if Length(ParaUMin) > 0 then
  begin
    vI := SearchMax(ParaIcmp, MakeInternalKey(nil, ParaUMin, KeyMaxSeq, KeyTypeSeek));
  end;
  if vI >= Count then
  begin
    Result := False;
    Exit;
  end;
  Result := not Items[vI].Before(ParaIcmp, ParaUMax);
end;

function TtFiles.GetOverlaps(ParaDst: TtFiles; ParaIcmp: IComparer; ParaUMin, ParaUMax: TBytes; ParaOverlapped: Boolean): TtFiles;
var
  vI: Integer;
  vT: TtFile;
begin
  Result := ParaDst;
  Result.Clear;
  vI := 0;
  while vI < Count do
  begin
    vT := Items[vI];
    if vT.Overlaps(ParaIcmp, ParaUMin, ParaUMax) then
    begin
      if (ParaUMin <> nil) and (ParaIcmp.Compare(vT.mIMin.UKey, ParaUMin) < 0) then
      begin
        ParaUMin := vT.mIMin.UKey;
        Result.Clear;
        vI := 0;
        Continue;
      end
      else if (ParaUMax <> nil) and (ParaIcmp.Compare(vT.mIMax.UKey, ParaUMax) > 0) then
      begin
        ParaUMax := vT.mIMax.UKey;
        if ParaOverlapped then
        begin
          Result.Clear;
          vI := 0;
          Continue;
        end;
      end;
      Result.Add(vT);
    end;
    Inc(vI);
  end;
end;

procedure TtFiles.GetRange(ParaIcmp: IComparer; out ParaIMin, ParaIMax: TInternalKey);
var
  vI: Integer;
  vT: TtFile;
begin
  for vI := 0 to Count - 1 do
  begin
    vT := Items[vI];
    if vI = 0 then
    begin
      ParaIMin := vT.mIMin;
      ParaIMax := vT.mIMax;
      Continue;
    end;
    if ParaIcmp.Compare(vT.mIMin, ParaIMin) < 0 then
    begin
      ParaIMin := vT.mIMin;
    end;
    if ParaIcmp.Compare(vT.mIMax, ParaIMax) > 0 then
    begin
      ParaIMax := vT.mIMax;
    end;
  end;
end;

function TtFiles.NewIndexIterator(ParaTops: TtOps; ParaIcmp: IComparer; ParaSlice: PRange; ParaRo: TReadOptions): IIteratorIndexer;
var
  vStart, vLimit: Integer;
  vFiles: TtFiles;
begin
  vFiles := Self;
  if ParaSlice <> nil then
  begin
    vStart := 0;
    if ParaSlice.Start <> nil then
    begin
      vStart := SearchMax(ParaIcmp, TInternalKey(ParaSlice.Start));
    end;
    if ParaSlice.Limit <> nil then
    begin
      vLimit := SearchMin(ParaIcmp, TInternalKey(ParaSlice.Limit));
    end
    else
    begin
      vLimit := Count;
    end;
    vFiles.Clear;
    vFiles.AddRange(Self.ToArray, vStart, vlimit - vStart);
  end;
  Result := TArrayIndexer.Create(vFiles, ParaTops, ParaIcmp, ParaSlice, ParaRo);
end;

{ TtOps }

constructor TtOps.Create(ParaSession: TSession);
var
  vCacher: ICacher;
  vBCacher: ICacher;
begin
  mSession := ParaSession;
  mNoSync := mSession.Options.GetNoSync;
  if mSession.Options.GetOpenFilesCacheCapacity > 0 then
  begin
    vCacher := TLRUCache.Create(mSession.Options.GetOpenFilesCacheCapacity);
  end;
  mCache := TCache.Create(vCacher);
  if not mSession.Options.GetDisableBlockCache then
  begin
    if mSession.Options.GetBlockCacheCapacity > 0 then
    begin
      vBCacher := TLRUCache.Create(mSession.Options.GetBlockCacheCapacity);
    end;
    mBCache := TCache.Create(vBCacher);
  end;
  if not mSession.Options.GetDisableBufferPool then
  begin
    mBPool := TBufferPool.Create(mSession.Options.GetBlockSize + 5);
  end;
end;

destructor TtOps.Destroy;
begin
  mBPool.Free;
  mCache.Free;
  if mBCache <> nil then
  begin
    mBCache.Free;
  end;
  inherited;
end;

function TtOps.CreateWriter: TtWriter;
var
  vFd: TFileDesc;
  vFw: IWriter;
begin
  vFd.FileType := TFileType.TypeTable;
  vFd.Num := mSession.AllocFileNum;
  vFw := mSession.Storage.Create(vFd);
  Result := TtWriter.Create(Self, vFd, vFw, TTableWriter.Create(vFw, mSession.Options));
end;

function TtOps.CreateFrom(ParaSrc: IIterator): TtFile;
var
  vWriter: TtWriter;
begin
  vWriter := CreateWriter;
  try
    while ParaSrc.Next do
    begin
      vWriter.Append(ParaSrc.Key, ParaSrc.Value);
    end;
    if ParaSrc.Error <> nil then
    begin
      raise Exception.Create(ParaSrc.Error.Message);
    end;
    Result := vWriter.Finish;
  except
    vWriter.Drop;
    raise;
  end;
end;

function TtOps.Open(ParaFile: TtFile): TCacheHandle;
var
  vReader: IReader;
  vBCacheNS: TNamespaceGetter;
  vTableReader: TTableReader;
begin
  Result := mCache.Get(0, ParaFile.mFd.Num,
    function: TCacheValue
    begin
      vReader := mSession.Storage.Open(ParaFile.mFd);
      if vReader = nil then
      begin
        Result := nil;
        Exit;
      end;
      if mBCache <> nil then
      begin
        vBCacheNS := TNamespaceGetter.Create(mBCache, ParaFile.mFd.Num);
      end;
      vTableReader := TTableReader.Create(vReader, ParaFile.mSize, ParaFile.mFd, vBCacheNS, mBPool, mSession.Options);
      if vTableReader = nil then
      begin
        vReader.Close;
        Result := nil;
        Exit;
      end;
      Result := vTableReader;
    end);
  if (Result = nil) then
  begin
    raise Exception.Create('ErrClosed');
  end;
end;

function TtOps.Find(ParaFile: TtFile; ParaKey: TBytes; ParaRo: TReadOptions; out RKey, RValue: TBytes): Boolean;
var
  vCh: TCacheHandle;
begin
  vCh := Open(ParaFile);
  try
    Result := (vCh.Value as TTableReader).Find(ParaKey, True, ParaRo, RKey, RValue);
  finally
    vCh.Release;
  end;
end;

function TtOps.FindKey(ParaFile: TtFile; ParaKey: TBytes; ParaRo: TReadOptions; out RKey: TBytes): Boolean;
var
  vCh: TCacheHandle;
begin
  vCh := Open(ParaFile);
  try
    Result := (vCh.Value as TTableReader).FindKey(ParaKey, True, ParaRo, RKey);
  finally
    vCh.Release;
  end;
end;

function TtOps.OffsetOf(ParaFile: TtFile; ParaKey: TBytes): Int64;
var
  vCh: TCacheHandle;
begin
  vCh := Open(ParaFile);
  try
    Result := (vCh.Value as TTableReader).OffsetOf(ParaKey);
  finally
    vCh.Release;
  end;
end;

function TtOps.NewIterator(ParaFile: TtFile; ParaSlice: PRange; ParaRo: TReadOptions): IIterator;
var
  vCh: TCacheHandle;
  vIter: IIterator;
begin
  vCh := Open(ParaFile);
  vIter := (vCh.Value as TTableReader).NewIterator(ParaSlice, ParaRo);
  vIter.SetReleaser(vCh);
  Result := vIter;
end;

procedure TtOps.Remove(ParaFile: TtFile);
begin
  mCache.Delete(0, ParaFile.mFd.Num,
    procedure
    begin
      try
        mSession.Storage.Remove(ParaFile.mFd);
        mSession.Log(Format('table@remove removed @%d', [ParaFile.mFd.Num]));
      except
        on E: Exception do
        begin
          mSession.Log(Format('table@remove removing @%d %s', [ParaFile.mFd.Num, E.Message]));
        end;
      end;
      if mBCache <> nil then
      begin
        mBCache.EvictNS(ParaFile.mFd.Num);
      end;
    end);
end;

procedure TtOps.Close;
begin
  mBPool.Close;
  mCache.Close;
  if mBCache <> nil then
  begin
    mBCache.CloseWeak;
  end;
end;

{ TtWriter }

constructor TtWriter.Create(ParaTOps: TtOps; ParaFd: TFileDesc; ParaWriter: IWriter; ParaTableWriter: TTableWriter);
begin
  mTOps := ParaTOps;
  mFd := ParaFd;
  mWriter := ParaWriter;
  mTableWriter := ParaTableWriter;
end;

destructor TtWriter.Destroy;
begin
  Close;
  mTableWriter.Free;
  inherited;
end;

function TtWriter.Append(ParaKey, ParaValue: TBytes): Boolean;
begin
  if mFirst = nil then
  begin
    mFirst := ParaKey;
  end;
  mLast := ParaKey;
  Result := mTableWriter.Append(ParaKey, ParaValue);
end;

function TtWriter.Empty: Boolean;
begin
  Result := mFirst = nil;
end;

procedure TtWriter.Close;
begin
  if mWriter <> nil then
  begin
    mWriter.Close;
    mWriter := nil;
  end;
end;

function TtWriter.Finish: TtFile;
begin
  try
    mTableWriter.Close;
    if not mTOps.mNoSync then
    begin
      mWriter.Sync;
    end;
    Result := TtFile.New(mFd, mTableWriter.BytesLen, TInternalKey(mFirst), TInternalKey(mLast));
  finally
    Close;
  end;
end;

procedure TtWriter.Drop;
begin
  Close;
  mTOps.mSession.Storage.Remove(mFd);
  mTOps.mSession.ReuseFileNum(mFd.Num);
  mTableWriter := nil;
  mFirst := nil;
  mLast := nil;
end;

end.
