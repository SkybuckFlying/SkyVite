unit chain_events;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vite.Common, Vite.Ledger, Vite.Interfaces, onroad.pool;

type
  TContractReactFunc = procedure(address: TAddress) of object;
  TSnapshotEventReactFunc = procedure(height: UInt64) of object;

  TManager = class
  private
    FNewContractListener: TDictionary<TGid, TContractReactFunc>;
    FNewSnapshotListener: TDictionary<TGid, TSnapshotEventReactFunc>;
    procedure NewContractSignalToWorker(gid: TGid; contract: TAddress);
    procedure SnapshotEventSignalToWorker(gid: TGid; height: UInt64);
  public
    procedure PrepareInsertAccountBlocks(blocks: TArray<IVmAccountBlock>);
    procedure InsertAccountBlocks(blocks: TArray<IVmAccountBlock>);
    procedure PrepareDeleteAccountBlocks(blocks: TArray<TAccountBlock>);
    procedure DeleteAccountBlocks(blocks: TArray<TAccountBlock>);
    procedure PrepareInsertSnapshotBlocks(chunks: TArray<TSnapshotChunk>);
    procedure InsertSnapshotBlocks(chunks: TArray<TSnapshotChunk>);
    procedure PrepareDeleteSnapshotBlocks(chunks: TArray<TSnapshotChunk>);
    procedure DeleteSnapshotBlocks(chunks: TArray<TSnapshotChunk>);
    procedure AddContractLis(gid: TGid; f: TContractReactFunc);
    procedure RemoveContractLis(gid: TGid);
    procedure AddSnapshotEventLis(gid: TGid; f: TSnapshotEventReactFunc);
    procedure RemoveSnapshotEventLis(gid: TGid);
  end;

implementation

{ TManager }

procedure TManager.AddContractLis(gid: TGid; f: TContractReactFunc);
begin
  FNewContractListener.AddOrSetValue(gid, f);
end;

procedure TManager.AddSnapshotEventLis(gid: TGid; f: TSnapshotEventReactFunc);
begin
  FNewSnapshotListener.AddOrSetValue(gid, f);
end;

procedure TManager.DeleteAccountBlocks(blocks: TArray<TAccountBlock>);
begin
  // No implementation needed
end;

procedure TManager.DeleteSnapshotBlocks(chunks: TArray<TSnapshotChunk>);
begin
  // No implementation needed
end;

procedure TManager.InsertAccountBlocks(blocks: TArray<IVmAccountBlock>);
var
  sendCreateGidCache: TDictionary<TAddress, TGid>;
  blockList: TArray<TAccountBlock>;
  v: IVmAccountBlock;
  newContract: TAddress;
  unsavedMetas: TDictionary<TAddress, PContractMeta>;
  meta: PContractMeta;
  cutMap: TDictionary<TAddress, TArray<TAccountBlock>>;
  addr: TAddress;
  list: TArray<TAccountBlock>;
  gid: TGid;
  orPool: IOnRoadPool;
  item: TAccountBlock;
begin
  sendCreateGidCache := TDictionary<TAddress, TGid>.Create;
  try
    SetLength(blockList, Length(blocks));
    for v in blocks do
    begin
      if v.AccountBlock.BlockType = btSendCreate then
      begin
        newContract := v.AccountBlock.ToAddress;
        unsavedMetas := v.VmDb.GetUnsavedContractMeta;
        if not unsavedMetas.TryGetValue(newContract, meta) or (meta = nil) then
          raise Exception.Create('meta nil in SendCreate vmDb, skip and ignore the block');
        sendCreateGidCache.Add(newContract, meta.Gid);
      end;
      blockList := blockList + [v.AccountBlock];
    end;

    cutMap := ExcludePairTrades(FChain, blockList);
    for addr in cutMap.Keys do
    begin
      if not addr.IsContractAddr then
        Continue;
      meta := FChain.GetContractMeta(addr);
      if meta <> nil then
        gid := meta.Gid
      else
      begin
        if not sendCreateGidCache.TryGetValue(addr, gid) then
          raise Exception.CreateFmt('find contract meta nil, orAddr %s', [string(addr)]);
      end;
      if not FOnRoadPools.TryGetValue(gid, orPool) or (orPool = nil) then
        Continue;

      list := cutMap[addr];
      orPool.InsertAccountBlocks(addr, list);

      for item in list do
      begin
        if item.IsSendBlock then
        begin
          NewContractSignalToWorker(gid, addr);
          Break;
        end;
      end;
    end;
  finally
    sendCreateGidCache.Free;
  end;
end;

procedure TManager.InsertSnapshotBlocks(chunks: TArray<TSnapshotChunk>);
var
  latestHeight: UInt64;
  v: TSnapshotChunk;
  item: TPair<TGid, TSnapshotEventReactFunc>;
begin
  latestHeight := 0;
  for v in chunks do
  begin
    if v.SnapshotBlock.Height > latestHeight then
      latestHeight := v.SnapshotBlock.Height;
  end;
  FLog.Debug(Format('InsertSnapshotBlocks latestHeight %d', [latestHeight]), 'event', 'snapshotEvent');
  for item in FNewSnapshotListener do
  begin
    FLog.Info(Format('snapshot line changed, latestHeight %d gid %s', [latestHeight, string(item.Key)]), 'event', 'snapshotEvent');
    item.Value(latestHeight);
  end;
end;

procedure TManager.NewContractSignalToWorker(gid: TGid; contract: TAddress);
var
  f: TContractReactFunc;
begin
  if FNewContractListener.TryGetValue(gid, f) then
    f(contract);
end;

procedure TManager.PrepareDeleteAccountBlocks(blocks: TArray<TAccountBlock>);
var
  cutMap: TDictionary<TAddress, TArray<TAccountBlock>>;
  addr: TAddress;
  list: TArray<TAccountBlock>;
  meta: PContractMeta;
  orPool: IOnRoadPool;
  v: TAccountBlock;
begin
  cutMap := ExcludePairTrades(FChain, blocks);
  for addr in cutMap.Keys do
  begin
    if not addr.IsContractAddr then
      Continue;
    meta := FChain.GetContractMeta(addr);
    if meta = nil then
      raise Exception.CreateFmt('find contract meta nil, orAddr %s', [string(addr)]);
    if not FOnRoadPools.TryGetValue(meta.Gid, orPool) or (orPool = nil) then
      Continue;

    list := cutMap[addr];
    orPool.DeleteAccountBlocks(addr, list);

    for v in list do
    begin
      if v.IsReceiveBlock then
      begin
        NewContractSignalToWorker(meta.Gid, addr);
        Break;
      end;
    end;
  end;
end;

procedure TManager.PrepareDeleteSnapshotBlocks(chunks: TArray<TSnapshotChunk>);
var
  blocks: TArray<TAccountBlock>;
  v: TSnapshotChunk;
  cutMap: TDictionary<TAddress, TArray<TAccountBlock>>;
  addr: TAddress;
  list: TArray<TAccountBlock>;
  meta: PContractMeta;
  orPool: IOnRoadPool;
  item: TAccountBlock;
begin
  for v in chunks do
    blocks := blocks + v.AccountBlocks;

  cutMap := ExcludePairTrades(FChain, blocks);
  for addr in cutMap.Keys do
  begin
    if not addr.IsContractAddr then
      Continue;
    meta := FChain.GetContractMeta(addr);
    if meta = nil then
      raise Exception.CreateFmt('find contract meta nil, orAddr %s', [string(addr)]);
    if not FOnRoadPools.TryGetValue(meta.Gid, orPool) or (orPool = nil) then
      Continue;

    list := cutMap[addr];
    orPool.DeleteAccountBlocks(addr, list);

    for item in list do
    begin
      if item.IsReceiveBlock then
      begin
        NewContractSignalToWorker(meta.Gid, addr);
        Break;
      end;
    end;
  end;
end;

procedure TManager.PrepareInsertAccountBlocks(blocks: TArray<IVmAccountBlock>);
begin
  // No implementation needed
end;

procedure TManager.PrepareInsertSnapshotBlocks(chunks: TArray<TSnapshotChunk>);
begin
  // No implementation needed
end;

procedure TManager.RemoveContractLis(gid: TGid);
begin
  FNewContractListener.Remove(gid);
end;

procedure TManager.RemoveSnapshotEventLis(gid: TGid);
begin
  FNewSnapshotListener.Remove(gid);
end;

procedure TManager.SnapshotEventSignalToWorker(gid: TGid; height: UInt64);
var
  f: TSnapshotEventReactFunc;
begin
  if FNewSnapshotListener.TryGetValue(gid, f) then
  begin
    FLog.Info(Format('snapshot line changed, latestHeight %d gid %s', [height, string(gid)]), 'event', 'snapshotEvent');
    f(height);
  end;
end;

end.
