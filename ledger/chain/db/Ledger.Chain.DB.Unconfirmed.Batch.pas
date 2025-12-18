unit Ledger.Chain.Db.UnconfirmedBatch;

interface

uses
  Common.Db.XLevelDB.Batch,
  Common.Types,
  Ledger.Chain.DB.Flush,
  Ledger.Chain.DB.Flush.Test,
  Ledger.Chain.DB.Mem.DB.Test,
  Ledger.Chain.DB.Rollback,
  Ledger.Chain.DB.Store,
  Ledger.Chain.DB.Store.Test,
  Ledger.Chain.DB.Write,
  System.SysUtils System.Classes System.Generics.Collections System.SyncObjs;

type
  TUnconfirmedBatchs = class
  private
    mBatchMap: TDictionary<THash, TLinkedListNode<TBatch>>;
    mBatchList: TLinkedList<TBatch>;
    mMutex: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function Size: Integer;
    function Get(const ParaBlockHash: THash): TPair<TBatch, Boolean>;
    procedure Put(const ParaBlockHash: THash; ParaBatch: TBatch);
    procedure Remove(const ParaBlockHash: THash);
    procedure Clear;
    procedure All(ParaFunc: TProc<TBatch>);
  end;

implementation

{ TUnconfirmedBatchs }

constructor TUnconfirmedBatchs.Create;
begin
  inherited Create;
  mBatchMap := TDictionary<THash, TLinkedListNode<TBatch>>.Create;
  mBatchList := TLinkedList<TBatch>.Create;
  InitializeCriticalSection(mMutex);
end;

destructor TUnconfirmedBatchs.Destroy;
begin
  mBatchMap.Free;
  mBatchList.Free;
  DeleteCriticalSection(mMutex);
  inherited;
end;

function TUnconfirmedBatchs.Size: Integer;
begin
  EnterCriticalSection(mMutex);
  try
    Result := mBatchMap.Count;
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

function TUnconfirmedBatchs.Get(const ParaBlockHash: THash): TPair<TBatch, Boolean>;
var
  vElem: TLinkedListNode<TBatch>;
begin
  EnterCriticalSection(mMutex);
  try
    if mBatchMap.TryGetValue(ParaBlockHash, vElem) then
      Result := TPair<TBatch, Boolean>.Create(vElem.Value, True)
    else
      Result := TPair<TBatch, Boolean>.Create(nil, False);
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

procedure TUnconfirmedBatchs.Put(const ParaBlockHash: THash; ParaBatch: TBatch);
var
  vElem: TLinkedListNode<TBatch>;
begin
  EnterCriticalSection(mMutex);
  try
    vElem := mBatchList.AddLast(ParaBatch);
    mBatchMap.Add(ParaBlockHash, vElem);
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

procedure TUnconfirmedBatchs.Remove(const ParaBlockHash: THash);
var
  vElem: TLinkedListNode<TBatch>;
begin
  EnterCriticalSection(mMutex);
  try
    if mBatchMap.TryGetValue(ParaBlockHash, vElem) then
    begin
      mBatchList.Remove(vElem);
      mBatchMap.Remove(ParaBlockHash);
    end;
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

procedure TUnconfirmedBatchs.Clear;
begin
  EnterCriticalSection(mMutex);
  try
    mBatchMap.Clear;
    mBatchList.Clear;
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

procedure TUnconfirmedBatchs.All(ParaFunc: TProc<TBatch>);
var
  vElem: TLinkedListNode<TBatch>;
begin
  EnterCriticalSection(mMutex);
  try
    vElem := mBatchList.First;
    while vElem <> nil do
    begin
      ParaFunc(vElem.Value);
      vElem := vElem.Next;
    end;
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

end.
