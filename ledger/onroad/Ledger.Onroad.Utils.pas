unit utils;

interface

uses
  Ledger.Onroad.Access,
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
  Ledger.Onroad.Utils.Test,
  Ledger.Onroad.Worker,
  System.SysUtils System.Classes System.Generics.Collections,
  Vite.Common Vite.Ledger;

type
  IJudgeGenesis = interface
    ['{F6F5E4D3-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    function IsGenesisAccountBlock(block: THash): Boolean;
  end;

function ExcludePairTrades(chain: IJudgeGenesis; blockList: TArray<TAccountBlock>): TDictionary<TAddress, TArray<TAccountBlock>>;

implementation

function ExcludePairTrades(chain: IJudgeGenesis; blockList: TArray<TAccountBlock>): TDictionary<TAddress, TArray<TAccountBlock>>;
var
  cutMap: TDictionary<THash, TAccountBlock>;
  block: TAccountBlock;
  v: TAccountBlock;
  ok: Boolean;
  subSend: TAccountBlock;
  pendingMap: TDictionary<TAddress, TArray<TAccountBlock>>;
  addr: PAddress;
  list: TArray<TAccountBlock>;
begin
  cutMap := TDictionary<THash, TAccountBlock>.Create;
  try
    for block in blockList do
    begin
      if block.IsSendBlock then
      begin
        if cutMap.TryGetValue(block.Hash, v) and (v <> nil) and v.IsReceiveBlock then
          cutMap.Remove(block.Hash)
        else
          cutMap.Add(block.Hash, block);
        Continue;
      end;

      if chain.IsGenesisAccountBlock(block.Hash) then
        Continue;

      // receive block
      if cutMap.TryGetValue(block.FromBlockHash, v) and (v <> nil) and v.IsSendBlock then
        cutMap.Remove(block.FromBlockHash)
      else
        cutMap.Add(block.FromBlockHash, block);

      // sendBlockList
      if not block.AccountAddress.IsContractAddr or (Length(block.SendBlockList) <= 0) then
        Continue;

      for subSend in block.SendBlockList do
      begin
        if cutMap.TryGetValue(subSend.Hash, v) and (v <> nil) and v.IsReceiveBlock then
          cutMap.Remove(subSend.Hash)
        else
          cutMap.Add(subSend.Hash, subSend);
      end;
    end;

    pendingMap := TDictionary<TAddress, TArray<TAccountBlock>>.Create;
    for v in cutMap.Values do
    begin
      if v = nil then
        Continue;

      if v.IsSendBlock then
        addr := @v.ToAddress
      else
        addr := @v.AccountAddress;

      if not pendingMap.TryGetValue(addr^, list) then
      begin
        list := [];
        pendingMap.Add(addr^, list);
      end;
      list := list + [v];
      pendingMap.AddOrSetValue(addr^, list);
    end;
    Result := pendingMap;
  finally
    cutMap.Free;
  end;
end;

end.
