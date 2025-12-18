unit Ledger.Onroad.Pool.Pool;

interface

uses
  Common.Types,
  Interfaces.Core,
  Ledger.Onroad.Pool.Caller.Cache.Test,
  Ledger.Onroad.Pool.Contract.Pool,
  Ledger.Onroad.Pool.Error.Table,
  Ledger.Onroad.Pool.Storage,
  Ledger.Onroad.Pool.Storage.Test,
  Ledger.Onroad.Pool.Types,
  Ledger.Onroad.Pool.Types.Test,
  System.Generics.Collections,
  SysUtils Classes SyncObjs;

type
  TPool = class
  private
    FItems: TDictionary<THash, IOnroadTransaction>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Add(Tx: IOnroadTransaction);
    function Get(Hash: THash): IOnroadTransaction;
    function Has(Hash: THash): Boolean;
    procedure Remove(Hash: THash);
    function Count: Integer;
  end;

implementation

{ TPool }

constructor TPool.Create;
begin
  inherited Create;
  FItems := TDictionary<THash, IOnroadTransaction>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TPool.Destroy;
begin
  FItems.Free;
  FLock.Free;
  inherited;
end;

procedure TPool.Add(Tx: IOnroadTransaction);
begin
  FLock.BeginWrite;
  try
    FItems.AddOrSetValue(Tx.Hash, Tx);
  finally
    FLock.EndWrite;
  end;
end;

function TPool.Get(Hash: THash): IOnroadTransaction;
begin
  FLock.BeginRead;
  try
    FItems.TryGetValue(Hash, Result);
  finally
    FLock.EndRead;
  end;
end;

function TPool.Has(Hash: THash): Boolean;
begin
  FLock.BeginRead;
  try
    Result := FItems.ContainsKey(Hash);
  finally
    FLock.EndRead;
  end;
end;

procedure TPool.Remove(Hash: THash);
begin
  FLock.BeginWrite;
  try
    FItems.Remove(Hash);
  finally
    FLock.EndWrite;
  end;
end;

function TPool.Count: Integer;
begin
  FLock.BeginRead;
  try
    Result := FItems.Count;
  finally
    FLock.EndRead;
  end;
end;

end.
