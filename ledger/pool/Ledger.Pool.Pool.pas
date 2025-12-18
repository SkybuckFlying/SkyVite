unit Ledger.Pool.Pool;

interface

uses
  SysUtils, Classes, SyncObjs,
  System.Generics.Collections,
  Common.Types,
  Interfaces.Core,
  unit_Go__Lang_Compatibility_version_006;

type
  // Forward declaration
  ITransaction = interface;

  TPool = class
  private
    FAll: TDictionary<THash, ITransaction>;
    FQueued: TDictionary<TAddress, TList<ITransaction>>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
    FNewTxChan: TGoChannel<ITransaction>;
    // ... other fields like pending, etc.
    
    procedure AddTransaction(Tx: ITransaction);
    procedure RemoveTransaction(Tx: ITransaction);
    
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Add(Tx: ITransaction);
    function Get(Hash: THash): ITransaction;
    procedure Remove(Hash: THash);
    function GetPending: TArray<ITransaction>;
    
    procedure Start;
    procedure Stop;
  end;

implementation

{ TPool }

constructor TPool.Create;
begin
  inherited Create;
  FAll := TDictionary<THash, ITransaction>.Create;
  FQueued := TDictionary<TAddress, TList<ITransaction>>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
  FNewTxChan := TGoChannel<ITransaction>.Create(100);
end;

destructor TPool.Destroy;
begin
  FAll.Free;
  FQueued.Free;
  FLock.Free;
  FNewTxChan.Free;
  inherited;
end;

procedure TPool.Add(Tx: ITransaction);
begin
  FLock.BeginWrite;
  try
    AddTransaction(Tx);
  finally
    FLock.EndWrite;
  end;
  FNewTxChan.Send(Tx);
end;

procedure TPool.AddTransaction(Tx: ITransaction);
begin
  if FAll.ContainsKey(Tx.Hash) then
    Exit;
    
  FAll.Add(Tx.Hash, Tx);
  
  var queue: TList<ITransaction>;
  if not FQueued.TryGetValue(Tx.Address, queue) then
  begin
    queue := TList<ITransaction>.Create;
    FQueued.Add(Tx.Address, queue);
  end;
  queue.Add(Tx);
end;

function TPool.Get(Hash: THash): ITransaction;
begin
  FLock.BeginRead;
  try
    FAll.TryGetValue(Hash, Result);
  finally
    FLock.EndRead;
  end;
end;

procedure TPool.Remove(Hash: THash);
begin
  var tx := Get(Hash);
  if tx <> nil then
  begin
    FLock.BeginWrite;
    try
      RemoveTransaction(tx);
    finally
      FLock.EndWrite;
    end;
  end;
end;

procedure TPool.RemoveTransaction(Tx: ITransaction);
begin
  FAll.Remove(Tx.Hash);
  
  var queue: TList<ITransaction>;
  if FQueued.TryGetValue(Tx.Address, queue) then
  begin
    queue.Remove(Tx);
    if queue.Count = 0 then
    begin
      FQueued.Remove(Tx.Address);
      queue.Free;
    end;
  end;
end;

function TPool.GetPending: TArray<ITransaction>;
begin
  FLock.BeginRead;
  try
    // This is a simplification. A real implementation would
    // collect transactions from the `pending` sub-pool.
    Result := FAll.Values.ToArray;
  finally
    FLock.EndRead;
  end;
end;

procedure TPool.Start;
begin
  // Start any background processing loops
end;

procedure TPool.Stop;
begin
  // Stop background loops
end;

end.
