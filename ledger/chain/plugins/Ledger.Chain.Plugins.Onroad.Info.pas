unit Ledger.Chain.Plugins.Onroad.Info;

interface

uses
  Common.DB.XLevelDB,
  Common.Types,
  Common.VitePB,
  Interfaces.Core,
  Ledger.Chain.DB,
  Ledger.Chain.Flusher,
  Ledger.Chain.Plugins.DB.Key.Prefix,
  Ledger.Chain.Plugins.Filter.Token,
  Ledger.Chain.Plugins.Interface,
  Ledger.Chain.Plugins.Onroad.Info.Test,
  Ledger.Chain.Plugins.Plugins,
  System.Generics.Collections,
  System.Math.BigInts,
  System.SysUtils;

type
  TOnRoadInfo = class(TInterfacedObject, IPlugin)
  private
    FChain: IChain;
    FUnconfirmedCache: TDictionary<TAddress, TDictionary<THash, TAccountBlock>>;
    FStore: TStore;
    FMutex: TMultiReadExclusiveWriteSynchronizer;
  public
    constructor Create(AStore: TStore; AChain: IChain);
    destructor Destroy; override;
    procedure SetStore(AStore: TStore);
    function ReBuildOnRoadInfo(AFlusher: TFlusher): HResult;
    function InsertSnapshotBlock(ABatch: TBatch; ASnapshotBlock: TSnapshotBlock; AConfirmedBlocks: TArray<TAccountBlock>): HResult;
    function DeleteSnapshotBlocks(ABatch: TBatch; AChunks: TArray<TSnapshotChunk>): HResult;
    function RemoveNewUnconfirmed(ARollbackBatch: TBatch; AAllUnconfirmedBlocks: TArray<TAccountBlock>): HResult;
    function InsertAccountBlock(ABatch: TBatch; ABlock: TAccountBlock): HResult;
    function DeleteAccountBlocks(ABatch: TBatch; ABlocks: TArray<TAccountBlock>): HResult;
    function UpdateOnRoadInfo(const AAddr: TAddress; const ATkId: TTokenTypeId; ANumber: UInt64; const AAmount: TBigInteger): HResult;
    function RemoveFromUnconfirmedCache(const AAddr: TAddress; AHashList: TArray<PHash>): HResult;
    function GetOnRoadInfoUnconfirmedHashList(const AAddr: TAddress): TArray<PHash>;
    function GetAccountInfo(const AAddr: TAddress): TAccountInfo;
  end;

function NewOnRoadInfo(AStore: TStore; AChain: IChain): IPlugin;

implementation

uses
  Ledger.Chain.Plugins.DB.Key.Prefix,
  Common.Helper;

{ TOnRoadInfo }

constructor TOnRoadInfo.Create(AStore: TStore; AChain: IChain);
begin
  inherited Create;
  FChain := AChain;
  FStore := AStore;
  FUnconfirmedCache := TDictionary<TAddress, TDictionary<THash, TAccountBlock>>.Create;
  FMutex := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TOnRoadInfo.Destroy;
begin
  FUnconfirmedCache.Free;
  FMutex.Free;
  inherited;
end;

procedure TOnRoadInfo.SetStore(AStore: TStore);
begin
  FStore := AStore;
end;

function TOnRoadInfo.ReBuildOnRoadInfo(AFlusher: TFlusher): HResult;
var
  vAddrOnRoadMap: TDictionary<TAddress, TArray<THash>>;
  vAddrInfoMap: TDictionary<TTokenTypeId, TOnRoadMeta>;
  vBlock: TAccountBlock;
  vOM: TOnRoadMeta;
  vBatch: TBatch;
begin
  vAddrOnRoadMap := FChain.LoadAllOnRoad;
  for var KVP in vAddrOnRoadMap do
  begin
    var Addr := KVP.Key;
    var HashList := KVP.Value;
    vAddrInfoMap := TDictionary<TTokenTypeId, TOnRoadMeta>.Create;
    try
      for var Hash in HashList do
      begin
        vBlock := FChain.GetAccountBlockByHash(Hash);
        if vBlock = nil then
          raise Exception.Create('can''t find the onroad block by hash');
        if not vAddrInfoMap.TryGetValue(vBlock.TokenId, vOM) then
        begin
          vOM := TOnRoadMeta.Create;
          vAddrInfoMap.Add(vBlock.TokenId, vOM);
        end;
        vOM.TotalAmount := vOM.TotalAmount + vBlock.Amount;
        vOM.Number := vOM.Number + 1;
      end;

      vBatch := FStore.NewBatch;
      try
        for var KVP2 in vAddrInfoMap do
        begin
          var TkId := KVP2.Key;
          vOM := KVP2.Value;
          var Key := CreateOnRoadInfoKey(Addr, TkId);
          vOM.WriteMeta(vBatch, Key);
        end;
        FStore.WriteDirectly(vBatch);
        AFlusher.Flush;
      finally
        vBatch.Free;
      end;
    finally
      for var KVP2 in vAddrInfoMap do
        KVP2.Value.Free;
      vAddrInfoMap.Free;
    end;
  end;
  Result := S_OK;
end;

function TOnRoadInfo.InsertSnapshotBlock(ABatch: TBatch; ASnapshotBlock: TSnapshotBlock; AConfirmedBlocks: TArray<TAccountBlock>): HResult;
begin
  FMutex.BeginWrite;
  try
    Self.RemoveUnconfirmed(AConfirmedBlocks);
    if Self.FlushWriteBySnapshotLine(ABatch, ExcludePairTrades(FChain, AConfirmedBlocks)) <> S_OK then
    begin
      // oLog.Error(Format('flushWriteBySnapshotLine err:%v, sb[%v %v]', [Err, ASnapshotBlock.Height, ASnapshotBlock.Hash]), 'method', 'InsertSnapshotBlock');
      // TODO redo the plugin onroad_info
    end;
  finally
    FMutex.EndWrite;
  end;
  Result := S_OK;
end;

function TOnRoadInfo.DeleteSnapshotBlocks(ABatch: TBatch; AChunks: TArray<TSnapshotChunk>): HResult;
var
  vUnconfirmedBlocks, vConfirmedBlocks: TArray<TAccountBlock>;
  vHeightStr: string;
begin
  if Length(AChunks) = 0 then
    Exit(S_OK);

  vUnconfirmedBlocks := [];
  vConfirmedBlocks := [];
  for var Chunk in AChunks do
  begin
    if Length(Chunk.AccountBlocks) = 0 then
      Continue;
    if Chunk.SnapshotBlock <> nil then
      vConfirmedBlocks := vConfirmedBlocks + Chunk.AccountBlocks
    else
      vUnconfirmedBlocks := vUnconfirmedBlocks + Chunk.AccountBlocks;
  end;

  FMutex.BeginWrite;
  try
    if Self.FlushDeleteBySnapshotLine(ABatch, ExcludePairTrades(FChain, vConfirmedBlocks)) <> S_OK then
    begin
      vHeightStr := '';
      for var Chunk in AChunks do
        if (Chunk <> nil) and (Chunk.SnapshotBlock <> nil) then
          vHeightStr := vHeightStr + Chunk.SnapshotBlock.Height.ToString + ',';
      // oLog.Error(Format('flushDeleteBySnapshotLine err:%v, sb[%v]', [Err, vHeightStr]), 'method', 'DeleteSnapshotBlocks');
      // TODO redo the plugin onroad_info
    end;
  finally
    FMutex.EndWrite;
  end;
  Result := S_OK;
end;

function TOnRoadInfo.RemoveNewUnconfirmed(ARollbackBatch: TBatch; AAllUnconfirmedBlocks: TArray<TAccountBlock>): HResult;
var
  vPendingRollbackList: TArray<TAccountBlock>;
  vOnRoadMap: TDictionary<THash, TAccountBlock>;
begin
  FMutex.BeginWrite;
  try
    vPendingRollbackList := [];
    for var Block in AAllUnconfirmedBlocks do
    begin
      if Block = nil then
        Continue;
      if FUnconfirmedCache.TryGetValue(Block.AccountAddress, vOnRoadMap) and (vOnRoadMap <> nil) then
        if vOnRoadMap.ContainsKey(Block.Hash) then
          Continue;
      vPendingRollbackList := vPendingRollbackList + [Block];
    end;

    if Self.FlushDeleteBySnapshotLine(ARollbackBatch, ExcludePairTrades(FChain, vPendingRollbackList)) <> S_OK then
    begin
      // oLog.Error(Format('flushDeleteBySnapshotLine err:%v', [Err]), 'method', 'RemoveNewUnconfirmed');
      // TODO redo the plugin onroad_info
    end;

    FUnconfirmedCache.Clear;
  finally
    FMutex.EndWrite;
  end;
  Result := S_OK;
end;

function TOnRoadInfo.InsertAccountBlock(ABatch: TBatch; ABlock: TAccountBlock): HResult;
var
  vBlocks: TArray<TAccountBlock>;
begin
  FMutex.BeginWrite;
  try
    SetLength(vBlocks, 1);
    vBlocks[0] := ABlock;
    Self.AddUnconfirmed(vBlocks);
  finally
    FMutex.EndWrite;
  end;
  Result := S_OK;
end;

function TOnRoadInfo.DeleteAccountBlocks(ABatch: TBatch; ABlocks: TArray<TAccountBlock>): HResult;
begin
  FMutex.BeginWrite;
  try
    Self.RemoveUnconfirmed(ABlocks);
  finally
    FMutex.EndWrite;
  end;
  Result := S_OK;
end;
// ... rest of the implementation
end.
