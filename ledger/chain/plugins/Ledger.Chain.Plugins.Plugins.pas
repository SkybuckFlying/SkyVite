unit Ledger.Chain.Plugins.Plugins;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  Interfaces.Core,
  Ledger.Chain.DB,
  Ledger.Chain.Plugins.Interface,
  Log15;

const
  roundSize = 10;

const
  stop = 0;
  start = 1;

type
  TPlugins = class
  private
    FDataDir: string;
    FLog: TLog15Logger;
    FChain: IChain;
    FStore: TStore;
    FPlugins: TDictionary<string, IPlugin>;
    FWriteStatus: Cardinal;
    FMu: TRTLCriticalSection;
  public
    constructor Create(const AChainDir: string; AChain: IChain);
    destructor Destroy; override;
    procedure StopWrite;
    procedure StartWrite;
    function RebuildData: HResult;
    function Close: HResult;
    function Store: TStore;
    function GetPlugin(const AName: string): IPlugin;
    procedure RemovePlugin(const AName: string);
    function PrepareInsertAccountBlocks(AVmBlocks: TArray<IVmAccountBlock>): HResult;
    function PrepareInsertSnapshotBlocks(AChunks: TArray<TSnapshotChunk>): HResult;
    function PrepareDeleteAccountBlocks(ABlocks: TArray<TAccountBlock>): HResult;
    function PrepareDeleteSnapshotBlocks(AChunks: TArray<TSnapshotChunk>): HResult;
    function DeleteSnapshotBlocks(AChunks: TArray<TSnapshotChunk>): HResult;
    function InsertAccountBlocks(ABlocks: TArray<IVmAccountBlock>): HResult;
    function InsertSnapshotBlocks(AChunks: TArray<TSnapshotChunk>): HResult;
    function DeleteAccountBlocks(ABlocks: TArray<TAccountBlock>): HResult;
  end;

implementation

uses
  System.IOUtils,
  Ledger.Chain.Plugins.Filter.Token,
  Ledger.Chain.Plugins.Onroad.Info;

{ TPlugins }

constructor TPlugins.Create(const AChainDir: string; AChain: IChain);
var
  err: HResult;
begin
  inherited Create;
  FDataDir := TPath.Combine(AChainDir, 'plugins');

  FStore := TStore.Create(FDataDir, 'plugins');
  if FStore = nil then
    raise Exception.Create('Failed to create store');

  FPlugins := TDictionary<string, IPlugin>.Create;
  FPlugins.Add('filterToken', NewFilterToken(FStore, AChain));
  FPlugins.Add('onRoadInfo', NewOnRoadInfo(FStore, AChain));

  FChain := AChain;
  FWriteStatus := start;
  FLog := TLog15Logger.Create('module', 'chain_plugins');
  InitializeCriticalSection(FMu);
end;

destructor TPlugins.Destroy;
begin
  FPlugins.Free;
  DeleteCriticalSection(FMu);
  inherited;
end;

procedure TPlugins.StopWrite;
begin
  if TInterlocked.CompareExchange(FWriteStatus, stop, start) <> start then
    Exit;

  EnterCriticalSection(FMu);
end;

procedure TPlugins.StartWrite;
begin
  if TInterlocked.CompareExchange(FWriteStatus, start, stop) <> stop then
    Exit;

  LeaveCriticalSection(FMu);
end;

function TPlugins.RebuildData: HResult;
var
  flusher: IFlusher;
  latestSnapshot: TSnapshotBlock;
  h, targetH: UInt64;
  chunks: TArray<TSnapshotChunk>;
  chunk: TSnapshotChunk;
  ab: TAccountBlock;
  batch: TBatch;
  plugin: IPlugin;
  pErr: Exception;
begin
  StopWrite;
  try
    FLog.Info('Start rebuild plugin data');

    if FStore.Close <> S_OK then
    begin
      Result := E_FAIL;
      Exit;
    end;

    // remove data
    TDirectory.Delete(FDataDir, True);

    // set new store
    FStore := TStore.Create(FDataDir, 'plugins');
    if FStore = nil then
    begin
      Result := E_FAIL;
      Exit;
    end;

    for plugin in FPlugins.Values do
      plugin.SetStore(FStore);

    // replace flusher store
    flusher := FChain.Flusher;
    flusher.ReplaceStore(FStore.Id, FStore);

    // get latest snapshot block
    latestSnapshot := FChain.GetLatestSnapshotBlock;
    if latestSnapshot = nil then
    begin
      Result := E_FAIL;
      Exit;
    end;

    FLog.Info(Format('latestSnapshot[%s %d]', [latestSnapshot.Hash.ToString, latestSnapshot.Height]), 'method', 'RebuildData');

    // build data
    h := 0;

    while h < latestSnapshot.Height do
    begin
      targetH := h + roundSize;
      if targetH > latestSnapshot.Height then
        targetH := latestSnapshot.Height;

      chunks := FChain.GetSubLedger(h, targetH);

      FLog.Info(Format('rebuild %d - %d', [h + 1, targetH]), 'method', 'RebuildData');

      for chunk in chunks do
      begin
        if (chunk.SnapshotBlock <> nil) and (chunk.SnapshotBlock.Height = h) then
          Continue;
        // write ab
        for ab in chunk.AccountBlocks do
        begin
          batch := FStore.NewBatch;

          for plugin in FPlugins.Values do
          begin
            if plugin.InsertAccountBlock(batch, ab) <> S_OK then
            begin
              Result := E_FAIL;
              Exit;
            end;
          end;
          FStore.WriteAccountBlock(batch, ab);
        end;

        // write sb
        batch := FStore.NewBatch;

        for plugin in FPlugins.Values do
        begin
          if plugin.InsertSnapshotBlock(batch, chunk.SnapshotBlock, chunk.AccountBlocks) <> S_OK then
          begin
            pErr := Exception.CreateFmt('InsertSnapshotBlock fail, sb[%d, %s,len=%d] ', [chunk.SnapshotBlock.Height, chunk.SnapshotBlock.Hash.ToString, Length(chunk.AccountBlocks)]);
            FLog.Error(pErr.Message, 'method', 'RebuildData');
            raise pErr;
          end;
        end;

        FStore.WriteSnapshot(batch, chunk.AccountBlocks);
      end;

      // flush to disk
      flusher.Flush;

      h := targetH;
    end;

    // success
    FLog.Info('Succeed rebuild plugin data');
    Result := S_OK;
  finally
    StartWrite;
  end;
end;

function TPlugins.Close: HResult;
begin
  Result := FStore.Close;
end;

function TPlugins.Store: TStore;
begin
  Result := FStore;
end;

function TPlugins.GetPlugin(const AName: string): IPlugin;
begin
  FPlugins.TryGetValue(AName, Result);
end;

procedure TPlugins.RemovePlugin(const AName: string);
begin
  FPlugins.Remove(AName);
end;

function TPlugins.PrepareInsertAccountBlocks(AVmBlocks: TArray<IVmAccountBlock>): HResult;
var
  vmBlock: IVmAccountBlock;
  batch: TBatch;
  plugin: IPlugin;
begin
  EnterCriticalSection(FMu);
  try
    // for recover
    for vmBlock in AVmBlocks do
    begin
      batch := FStore.NewBatch;

      for plugin in FPlugins.Values do
      begin
        if plugin.InsertAccountBlock(batch, vmBlock.AccountBlock) <> S_OK then
        begin
          Result := E_FAIL;
          Exit;
        end;
      end;
      FStore.WriteAccountBlock(batch, vmBlock.AccountBlock);
    end;
    Result := S_OK;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TPlugins.PrepareInsertSnapshotBlocks(AChunks: TArray<TSnapshotChunk>): HResult;
var
  chunk: TSnapshotChunk;
  batch: TBatch;
  plugin: IPlugin;
begin
  EnterCriticalSection(FMu);
  try
    for chunk in AChunks do
    begin
      batch := FStore.NewBatch;

      for plugin in FPlugins.Values do
      begin
        if plugin.InsertSnapshotBlock(batch, chunk.SnapshotBlock, chunk.AccountBlocks) <> S_OK then
        begin
          Result := E_FAIL;
          Exit;
        end;
      end;
      FStore.WriteSnapshot(batch, chunk.AccountBlocks);
    end;
    Result := S_OK;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TPlugins.PrepareDeleteAccountBlocks(ABlocks: TArray<TAccountBlock>): HResult;
var
  batch: TBatch;
  plugin: IPlugin;
begin
  EnterCriticalSection(FMu);
  try
    batch := FStore.NewBatch;

    for plugin in FPlugins.Values do
    begin
      if plugin.DeleteAccountBlocks(batch, ABlocks) <> S_OK then
      begin
        Result := E_FAIL;
        Exit;
      end;
    end;
    FStore.RollbackAccountBlocks(batch, ABlocks);
    Result := S_OK;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TPlugins.PrepareDeleteSnapshotBlocks(AChunks: TArray<TSnapshotChunk>): HResult;
var
  batch: TBatch;
  plugin: IPlugin;
begin
  EnterCriticalSection(FMu);
  try
    batch := FStore.NewBatch;

    for plugin in FPlugins.Values do
    begin
      if plugin.DeleteSnapshotBlocks(batch, AChunks) <> S_OK then
      begin
        Result := E_FAIL;
        Exit;
      end;
    end;
    FStore.RollbackSnapshot(batch);
    Result := S_OK;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TPlugins.DeleteSnapshotBlocks(AChunks: TArray<TSnapshotChunk>): HResult;
var
  allUnconfirmedBlocks: TArray<TAccountBlock>;
  rollbackBatch, batch: TBatch;
  plugin: IPlugin;
  unconfirmedBlock: TAccountBlock;
begin
  EnterCriticalSection(FMu);
  try
    allUnconfirmedBlocks := FChain.GetAllUnconfirmedBlocks;

    rollbackBatch := FStore.NewBatch;

    for plugin in FPlugins.Values do
    begin
      if plugin.RemoveNewUnconfirmed(rollbackBatch, allUnconfirmedBlocks) <> S_OK then
      begin
        Result := E_FAIL;
        Exit;
      end;
    end;

    FStore.RollbackSnapshot(rollbackBatch);

    for plugin in FPlugins.Values do
    begin
      batch := FStore.NewBatch;
      for unconfirmedBlock in allUnconfirmedBlocks do
      begin
        if plugin.InsertAccountBlock(rollbackBatch, unconfirmedBlock) <> S_OK then
        begin
          Result := E_FAIL;
          Exit;
        end;
        FStore.WriteAccountBlock(batch, unconfirmedBlock);
      end;
    end;
    Result := S_OK;
  finally
    LeaveCriticalSection(FMu);
  end;
end;

function TPlugins.InsertAccountBlocks(ABlocks: TArray<IVmAccountBlock>): HResult;
begin
  Result := S_OK;
end;

function TPlugins.InsertSnapshotBlocks(AChunks: TArray<TSnapshotChunk>): HResult;
begin
  Result := S_OK;
end;

function TPlugins.DeleteAccountBlocks(ABlocks: TArray<TAccountBlock>): HResult;
begin
  Result := S_OK;
end;

end.
