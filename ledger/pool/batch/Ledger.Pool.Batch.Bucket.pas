unit Ledger.Pool.Batch.Bucket;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Pool.Batch.Batch,
  Ledger.Pool.Batch.Batch.Executor.Impl,
  Ledger.Pool.Batch.Batch.Impl,
  Ledger.Pool.Batch.Batch.Test,
  Ledger.Pool.Batch.Example.Test,
  Ledger.Pool.Batch.Level,
  Ledger.Pool.Batch.Level.Account,
  Ledger.Pool.Batch.Level.Snapshot,
  Ledger.Pool.Batch.Mock.Chain,
  Ledger.Pool.Batch.Mock.Item,
  System.Generics.Collections,
  SysUtils Classes SyncObjs;

type
  TBucket = class
  private
    FItems: TDictionary<THash, ITransaction>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
    FMaxSize: Integer; // Optional: to enforce a size limit
    
  public
    constructor Create(MaxSize: Integer = 0);
    destructor Destroy; override;
    
    function Add(Tx: ITransaction): Boolean;
    function Get(Hash: THash): ITransaction;
    function Has(Hash: THash): Boolean;
    procedure Remove(Hash: THash);
    function Count: Integer;
    function GetTransactions: TArray<ITransaction>;
  end;

implementation

{ TBucket }

constructor TBucket.Create(MaxSize: Integer = 0);
begin
  inherited Create;
  FItems := TDictionary<THash, ITransaction>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
  FMaxSize := MaxSize;
end;

destructor TBucket.Destroy;
begin
  FItems.Free;
  FLock.Free;
  inherited;
end;

function TBucket.Add(Tx: ITransaction): Boolean;
begin
  FLock.BeginWrite;
  try
    if (FMaxSize > 0) and (FItems.Count >= FMaxSize) then
      Exit(False);
      
    if FItems.ContainsKey(Tx.Hash) then
      Exit(True); // Already exists
      
    FItems.Add(Tx.Hash, Tx);
    Result := True;
  finally
    FLock.EndWrite;
  end;
end;

function TBucket.Get(Hash: THash): ITransaction;
begin
  FLock.BeginRead;
  try
    FItems.TryGetValue(Hash, Result);
  finally
    FLock.EndRead;
  end;
end;

function TBucket.Has(Hash: THash): Boolean;
begin
  FLock.BeginRead;
  try
    Result := FItems.ContainsKey(Hash);
  finally
    FLock.EndRead;
  end;
end;

procedure TBucket.Remove(Hash: THash);
begin
  FLock.BeginWrite;
  try
    FItems.Remove(Hash);
  finally
    FLock.EndWrite;
  end;
end;

function TBucket.Count: Integer;
begin
  FLock.BeginRead;
  try
    Result := FItems.Count;
  finally
    FLock.EndRead;
  end;
end;

function TBucket.GetTransactions: TArray<ITransaction>;
begin
  FLock.BeginRead;
  try
    Result := FItems.Values.ToArray;
  finally
    FLock.EndRead;
  end;
end;

end.
