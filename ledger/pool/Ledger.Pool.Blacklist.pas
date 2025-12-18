unit Ledger.Pool.Blacklist;

interface

uses
  Common.Types,
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Bc.Pool,
  Ledger.Pool.Blacklist.Test,
  Ledger.Pool.Branch.Chain,
  Ledger.Pool.Chain.Pool,
  Ledger.Pool.Chain.Pool.Test,
  Ledger.Pool.Context,
  Ledger.Pool.Face,
  Ledger.Pool.Mock.Common.Block,
  Ledger.Pool.Pipeline.Pool,
  Ledger.Pool.Pool,
  Ledger.Pool.Pool.Batch,
  Ledger.Pool.Pool.Batch.Chunk,
  Ledger.Pool.Pool.Batch.Fork,
  Ledger.Pool.Pool.Fork.Checker,
  Ledger.Pool.Pool.Fork.Checker.Test,
  Ledger.Pool.Snapshot.Listener,
  Ledger.Pool.Snapshot.Pool,
  Ledger.Pool.Snapshot.Pool.Test,
  Ledger.Pool.Tools,
  Ledger.Pool.Tools.Chain,
  Ledger.Pool.Tools.Fetcher,
  Ledger.Pool.Tools.Verifier,
  Ledger.Pool.Worker,
  System.Generics.Collections,
  SysUtils Classes SyncObjs;

type
  TBlacklist = class
  private
    FList: TDictionary<TAddress, Boolean>;
    FLock: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Add(Addr: TAddress);
    procedure Remove(Addr: TAddress);
    function Contains(Addr: TAddress): Boolean;
    function Count: Integer;
    function GetAddresses: TArray<TAddress>;
  end;

implementation

{ TBlacklist }

constructor TBlacklist.Create;
begin
  inherited Create;
  FList := TDictionary<TAddress, Boolean>.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TBlacklist.Destroy;
begin
  FList.Free;
  FLock.Free;
  inherited;
end;

procedure TBlacklist.Add(Addr: TAddress);
begin
  FLock.BeginWrite;
  try
    FList.AddOrSetValue(Addr, True);
  finally
    FLock.EndWrite;
  end;
end;

procedure TBlacklist.Remove(Addr: TAddress);
begin
  FLock.BeginWrite;
  try
    FList.Remove(Addr);
  finally
    FLock.EndWrite;
  end;
end;

function TBlacklist.Contains(Addr: TAddress): Boolean;
begin
  FLock.BeginRead;
  try
    Result := FList.ContainsKey(Addr);
  finally
    FLock.EndRead;
  end;
end;

function TBlacklist.Count: Integer;
begin
  FLock.BeginRead;
  try
    Result := FList.Count;
  finally
    FLock.EndRead;
  end;
end;

function TBlacklist.GetAddresses: TArray<TAddress>;
begin
  FLock.BeginRead;
  try
    Result := FList.Keys.ToArray;
  finally
    FLock.EndRead;
  end;
end;

end.
