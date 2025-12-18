unit access;

interface

uses
  Ledger.Onroad.Access.Test,
  Ledger.Onroad.Chain.Events,
  Ledger.Onroad.ChainDB.Test,
  Ledger.Onroad.Contract,
  Ledger.Onroad.Contract.Test,
  Ledger.Onroad.Manager,
  Ledger.Onroad.Manager.Test,
  Ledger.Onroad.Pending.Cache,
  Ledger.Onroad.Pending.Cache.Test,
  Ledger.Onroad.Reader,
  Ledger.Onroad.Reader.Test,
  Ledger.Onroad.Task.Pqueue,
  Ledger.Onroad.Task.Pqueue.Test,
  Ledger.Onroad.TaskProcessor,
  Ledger.Onroad.TaskProcessor.Test,
  Ledger.Onroad.Utils,
  Ledger.Onroad.Utils.Test,
  Ledger.Onroad.Worker,
  System.SysUtils System.Classes,
  Vite.Common Vite.Ledger Vite.Interfaces onroad.pool;

type
  TManager = class
  public
    function GetOnRoadTotalNumByAddr(gid: TGid; addr: TAddress): UInt64;
    function GetAllCallersFrontOnRoad(gid: TGid; addr: TAddress): TArray<TAccountBlock>;
    function IsFrontOnRoadOfCaller(gid: TGid; orAddr, caller: TAddress; hash: THash): Boolean;
    procedure DeleteDirect(sendBlock: TAccountBlock);
    function InsertBlockToPool(block: IVmAccountBlock): Boolean;
  end;

implementation

{ TManager }

function TManager.GetAllCallersFrontOnRoad(gid: TGid; addr: TAddress): TArray<TAccountBlock>;
var
  onRoadPool: IOnRoadPool;
  ok: Boolean;
begin
  ok := FOnRoadPools.TryGetValue(gid, onRoadPool);
  if not ok or (onRoadPool = nil) then
  begin
    FLog.Error(ErrOnRoadPoolNotAvailable.Message, 'gid', gid, 'addr', addr);
    raise ErrOnRoadPoolNotAvailable;
  end;
  Result := onRoadPool.GetFrontOnRoadBlocksByAddr(addr);
end;

function TManager.GetOnRoadTotalNumByAddr(gid: TGid; addr: TAddress): UInt64;
var
  onRoadPool: IOnRoadPool;
  ok: Boolean;
begin
  ok := FOnRoadPools.TryGetValue(gid, onRoadPool);
  if not ok or (onRoadPool = nil) then
  begin
    FLog.Error(ErrOnRoadPoolNotAvailable.Message, 'gid', gid, 'addr', addr);
    raise ErrOnRoadPoolNotAvailable;
  end;
  Result := onRoadPool.GetOnRoadTotalNumByAddr(addr);
end;

function TManager.InsertBlockToPool(block: IVmAccountBlock): Boolean;
begin
  Result := FPool.AddDirectAccountBlock(block.AccountBlock.AccountAddress, block);
end;

function TManager.IsFrontOnRoadOfCaller(gid: TGid; orAddr, caller: TAddress;
  hash: THash): Boolean;
var
  onRoadPool: IOnRoadPool;
  ok: Boolean;
begin
  ok := FOnRoadPools.TryGetValue(gid, onRoadPool);
  if not ok or (onRoadPool = nil) then
  begin
    FLog.Error(ErrOnRoadPoolNotAvailable.Message, 'gid', gid, 'addr', orAddr);
    raise ErrOnRoadPoolNotAvailable;
  end;
  Result := onRoadPool.IsFrontOnRoadOfCaller(orAddr, caller, hash);
end;

procedure TManager.DeleteDirect(sendBlock: TAccountBlock);
begin
  FChain.DeleteOnRoad(sendBlock.ToAddress, sendBlock.Hash);
end;

end.
