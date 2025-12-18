unit Common.Db.MemDB;

interface

uses
  Common.Db.MemBatch,
  Common.Db.MemSnapshot,
  Common.DB.Merged.Iterator,
  common.db.xleveldb,
  common.db.xleveldb.comparer,
  common.db.xleveldb.iterator,
  common.db.xleveldb.memdb,
  common.db.xleveldb.util,
  GoToDelphi.Helpers.TChannel,
  System.SyncObjs,
  System.SysUtils;

type
  TMemDB = class
  private
    mStorage : memdb.TDB;
    mSeq : UInt64;
    mCopyMu : TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function GetDb : memdb.TDB;
    function GetSeq : UInt64;
    procedure Put( ParaKey : TBytes; ParaValue : TBytes );
    procedure Delete( ParaKey : TBytes );
    function Len : integer;
    function Size : integer;
    procedure Close;
    function NewIterator(ParaSlice : util.Range) : iterator.Iterator;
    function Get(ParaKey : TBytes) : TBytes;
    function Has(ParaKey : TBytes) : boolean;
    function NewBatch : Batch;
    procedure Write(ParaBatch : Batch);
    function GetSnapshot : Snapshot;
  end;

implementation

{ TMemDB }

function NewStorage: memdb.TDB;
begin
	Result := memdb.New(common.db.xleveldb.NewIComparer(comparer.DefaultComparer), 0);
end;

constructor TMemDB.Create;
begin
	inherited Create;
	mStorage := NewStorage();
	mSeq := common.db.xleveldb.KeyMaxSeq - 10000*10000;
	InitializeCriticalSection(mCopyMu);
end;

destructor TMemDB.Destroy;
begin
	mStorage.Free;
	DeleteCriticalSection(mCopyMu);
	inherited;
end;

function TMemDB.GetDb : memdb.TDB;
begin
	Result := mStorage;
end;

function TMemDB.GetSeq : UInt64;
begin
	Result := TInterlocked.Read(mSeq);
end;

procedure TMemDB.Put( ParaKey : TBytes; ParaValue : TBytes );
var
	vInternalKey: TBytes;
begin
	TInterlocked.Add(mSeq, 1);
	vInternalKey := common.db.xleveldb.MakeInternalKey(nil, ParaKey, mSeq, common.db.xleveldb.KeyTypeVal);
	mStorage.Put(vInternalKey, ParaValue);
end;

procedure TMemDB.Delete( ParaKey : TBytes );
var
	vInternalKey: TBytes;
begin
	TInterlocked.Add(mSeq, 1);
	vInternalKey := common.db.xleveldb.MakeInternalKey(nil, ParaKey, mSeq, common.db.xleveldb.KeyTypeDel);
	mStorage.Put(vInternalKey, nil);
end;

function TMemDB.Len : integer;
begin
	Result := mStorage.Len;
end;

function TMemDB.Size : integer;
begin
	Result := mStorage.Size;
end;

procedure TMemDB.Close;
begin
  mStorage.Close;
end;

function TMemDB.NewIterator(ParaSlice : util.Range) : iterator.Iterator;
begin
  Result := mStorage.NewIterator(ParaSlice);
end;

function TMemDB.Get(ParaKey : TBytes) : TBytes;
begin
  Result := mStorage.Get(ParaKey);
end;

function TMemDB.Has(ParaKey : TBytes) : boolean;
begin
  Result := mStorage.Has(ParaKey);
end;

function TMemDB.NewBatch : Batch;
begin
  Result := newMemBatch(Self);
end;

procedure TMemDB.Write(ParaBatch : Batch);
var
  vMemBatch : TMemBatch;
begin
  vMemBatch := ParaBatch as TMemBatch;
  mStorage.Write(vMemBatch.batch);
end;

function TMemDB.GetSnapshot : Snapshot;
begin
  Result := newMemSnapshot(Self);
end;

end.
