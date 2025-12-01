unit Ledger.Chain.Db.UnconfirmedBatch;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  Common.Types,
  Common.Db.XLevelDB.Batch;

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
