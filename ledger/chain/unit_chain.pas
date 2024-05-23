unit unit_chain;

// direct or last part direct.

interface

uses
  SysUtils, Classes, SyncObjs, DateUtils, StrUtils, Variants, Math,
  leveldb, common, config, types, upgrade, interfaces, core, block, cache,
  flusher, genesis, index, plugins, state, sync_cache, log15;

const
  stop = 0;
  start = 1;

type
  TChain = class
  private
    genesisCfg: TGenesis;
    chainCfg: TChainConfig;

    genesisSnapshotBlock: TSnapShotBlock;
    genesisAccountBlocks: array of TVmAccountBlock;
    genesisAccountBlockHash: TDictionary<THash, Variant>;

    dataDir: string;
    chainDir: string;
    verifier: TConsensusVerifier;

    log: TLogger;

    em: TEventManager;
    cache: TCache;
    metaDB: TLevelDB;
    indexDB: TIndexDB;
    blockDB: TBlockDB;
    stateDB: TStateDB;
    syncCache: TSyncCache;
    flusher: TFlusher;
    flushMu: TRTLCriticalSection;
    plugins: TPlugins;
    status: Cardinal;

  public
    constructor Create(dir: string; chainCfg: TChainConfig; genesisCfg: TGenesis);
    procedure Init;
    procedure Start;
    procedure Stop;
  end;

implementation

constructor TChain.Create(dir: string; chainCfg: TChainConfig; genesisCfg: TGenesis);
begin
  if chainCfg = nil then
    chainCfg := defaultConfig();
  if genesisCfg = nil then
    genesisCfg := MainnetGenesis();

  Self.genesisCfg := genesisCfg;
  Self.dataDir := dir;
  Self.chainDir := IncludeTrailingPathDelimiter(dir) + 'ledger';
  Self.log := TLogger.Create('module', 'chain');
  Self.chainCfg := chainCfg;

  Self.em := TEventManager.Create(Self);
  UpdateDexFundOwner(genesisCfg);
  genesisAccountBlocks := NewGenesisAccountBlocks(genesisCfg);
  genesisSnapshotBlock := NewGenesisSnapshotBlock(genesisAccountBlocks);
  genesisAccountBlockHash := VmBlocksToHashMap(genesisAccountBlocks);
end;

procedure TChain.Init;
begin
  log.Info('Begin initializing', ['method', 'Init']);
  if newDbAndRecover() <> nil then
    Exit;
  if checkAndInitData() <> nil then
    Exit;
  if status <> LedgerValid then
	raise Exception.CreateFmt('The genesis state is incorrect. You can fix the problem by removing the database manually. The directory of database is %s.', [chainDir]);
  if initCache() <> nil then
    Exit;
  if checkForkPoints() <> nil then
    Exit;
  log.Info('Complete initialization', ['method', 'Init']);
end;

procedure TChain.Start;
begin
  if InterlockedCompareExchange(status, stop, start) <> stop then
    Exit;
  flusher.Start();
  log.Info('Start flusher', ['method', 'Start']);
end;

procedure TChain.Stop;
begin
  if InterlockedCompareExchange(status, start, stop) <> start then
    Exit;
  flusher.Stop();
  log.Info('Stop flusher', ['method', 'Stop']);
end;

procedure TChain.Destroy;
begin
  c.log.Info('Begin to destroy', 'method', 'Close');

  c.cache.Destroy();
  c.log.Info('Close cache', 'method', 'Close');

  if c.stateDB.Close() <> nil then
  begin
    cErr := Format('c.stateDB.Close failed, error is %s', [err]);
    c.log.Error(cErr, 'method', 'Close');
    Exit(cErr);
  end;

  c.log.Info('Close stateDB', 'method', 'Close');

  if c.indexDB.Close() <> nil then
  begin
    cErr := Format('c.indexDB.Close failed, error is %s', [err]);
    c.log.Error(cErr, 'method', 'Close');
    Exit(cErr);
  end;
  c.log.Info('Close indexDB', 'method', 'Close');

  if c.blockDB.Close() <> nil then
  begin
    cErr := Format('c.blockDB.Close failed, error is %s', [err]);
    c.log.Error(cErr, 'method', 'Close');
    Exit(cErr);
  end;
  c.log.Info('Close blockDB', 'method', 'Close');

  if c.syncCache.Close() <> nil then
  begin
    cErr := Format('c.syncCache.Close failed, error is %s', [err]);
    c.log.Error(cErr, 'method', 'Close');
    Exit(cErr);
  end;
  c.log.Info('Close syncCache', 'method', 'Close');

  c.flusher := nil;
  c.cache := nil;
  c.stateDB := nil;
  c.indexDB := nil;
  c.blockDB := nil;
  c.syncCache := nil;

  c.log.Info('Complete destruction', 'method', 'Close');

  Exit(nil);
end;

function TChain.Plugins: TPlugins;
begin
  Exit(c.plugins);
end;

function TChain.NewDb(dirName: string): TDB;
var
  absoluteDirName: string;
begin
  absoluteDirName := Path.Join(c.chainDir, dirName);
  Result := leveldb.OpenFile(absoluteDirName, nil);
end;

function TChain.PrepareOnroadDb: TDB;
var
  dirName, absoluteDirName: string;
begin
  dirName := 'onroad';
  absoluteDirName := Path.Join(c.chainDir, dirName);
  c.log.Info('clear onroad db', 'dir', absoluteDirName);

  if RemoveAll(absoluteDirName) <> nil then
  begin
    Exit(nil, err);
  end;
  Exit(c.NewDb(dirName));
end;

procedure TChain.SetConsensus(verifier: IConsensusVerifier; periodTimeIndex: ITimeIndex);
begin
  c.log.Info('Start set consensus', 'method', 'SetConsensus');
  c.verifier := verifier;

  if c.stateDB.SetTimeIndex(periodTimeIndex) <> nil then
  begin
    common.Crit(Format('c.stateDB.SetConsensus failed. Error: %s', [err]), 'method', 'SetConsensus');
  end;
  c.log.Info('set consensus finished', 'method', 'SetConsensus');
end;

function TChain.newDbAndRecover: Error;
var
  err: Error;
begin
  // new metaDB
  c.metaDB, err := c.NewDb('chain_meta');
  if err <> nil then
  begin
	c.log.Error(Format('new meta db failed, error is %s, chainDir is %s', [err, c.chainDir]), 'method', 'newDbAndRecover');
    Exit(err);
  end;

  // new ledger db
  c.indexDB, err := chain_index.NewIndexDB(c.chainDir);
  if err <> nil then
  begin
    c.log.Error(Format('chain_index.NewIndexDB failed, error is %s, chainDir is %s', [err, c.chainDir]), 'method', 'newDbAndRecover');
    Exit(err);
  end;

  // new block db
  c.blockDB, err := chain_block.NewBlockDB(c.chainDir);
  if err <> nil then
  begin
    c.log.Error(Format('chain_block.NewBlockDB failed, error is %s, chainDir is %s', [err, c.chainDir]), 'method', 'newDbAndRecover');
    Exit(err);
  end;

  // new state db
  c.stateDB, err := chain_state.NewStateDB(c, c.chainCfg, c.chainDir);
  if err <> nil then
  begin
    cErr := Format('chain_cache.NewStateDB failed, error is %s', [err]);

    c.log.Error(cErr, 'method', 'newDbAndRecover');
    Exit(err);
  end;

  // init plugins
  if c.chainCfg.OpenPlugins then
  begin
    c.plugins, err := chain_plugins.NewPlugins(c.chainDir, c);
    if err <> nil then
    begin
      cErr := Format('chain_plugins.NewPlugins failed. Error: %s', [err]);
      c.log.Error(cErr, 'method', 'newDbAndRecover');
      Exit(cErr);
    end;
    c.Register(c.plugins);
  end;

  // new flusher
  stores := [c.blockDB, c.stateDB.Store(), c.stateDB.RedoStore(), c.indexDB.Store()];
  if c.chainCfg.OpenPlugins then
  begin
    stores := append(stores, c.plugins.Store());
  end;
  c.flusher, err := chain_flusher.NewFlusher(stores, c.flushMu, c.chainDir);
  if err <> nil then
  begin
    cErr := Format('chain_flusher.NewFlusher failed. Error: %s', [err]);
    c.log.Error(cErr, 'method', 'newDbAndRecover');
    Exit(cErr);
  end;

  // flusher check and recover
  if c.flusher.Recover() <> nil then
  begin
    cErr := Format('c.flusher.Recover failed. Error: %s', [err]);
    c.log.Error(cErr, 'method', 'newDbAndRecover');
    Exit(cErr);
  end;

  // new cache
  c.cache, err := chain_cache.NewCache(c);
  if err <> nil then
  begin
    cErr := Format('chain_cache.NewCache failed, error is %s', [err]);

    c.log.Error(cErr, 'method', 'checkAndInitData');
    Exit(cErr);
  end;

  Exit(nil);
end;

function TChain.checkAndInitData: (Byte, Error);
var
  status: Byte;
  err: Error;
begin
  // check ledger
  status, err := chain_genesis.CheckLedger(c, c.genesisSnapshotBlock, c.genesisAccountBlocks);
  if err <> nil then
  begin
    cErr := Format('chain_genesis.CheckLedger failed, error is %s, chainDir is %s', [err, c.chainDir]);

    c.log.Error(cErr, 'method', 'checkAndInitData');
    Exit(status, err);
  end;

  if status = chain_genesis.LedgerInvalid then
  begin
    Exit(status, nil);
  end;

  if status = chain_genesis.LedgerEmpty then
  begin
    if chain_genesis.InitLedger(c, c.genesisSnapshotBlock, c.genesisAccountBlocks) <> nil then
    begin
      cErr := Format('chain_genesis.InitLedger failed, error is %s', [err]);
      c.log.Error(cErr, 'method', 'checkAndInitData');
      Exit(chain_genesis.LedgerInvalid, err);
    end;

    status := chain_genesis.LedgerValid;
  end;

  Exit(status, nil);
end;

function TChain.checkForkPoints: Error;
var
  latest: TSnapshotBlock;
  activePoints: TArray<TUpgradePoint>;
  rollbackForkPoint: TUpgradePoint;
  i: Integer;
  forkPoint: TUpgradePoint;
  sb: TSnapshotBlock;
begin
  latest := c.GetLatestSnapshotBlock();
  activePoints := upgrade.GetActivePoints(latest.Height);

  // check
  rollbackForkPoint := nil;
  for i := Length(activePoints) - 1 downto 0 do
  begin
    forkPoint := activePoints[i];
    sb, err := c.GetSnapshotBlockByHeight(forkPoint.Height);
    if err <> nil then
    begin
      Exit(err);
    end;

    if sb = nil then
    begin
      Continue;
    end;

    if sb.ComputeHash() = sb.Hash then
    begin
      Break;
    end;
    rollbackForkPoint := forkPoint;
  end;

  // rollback
  if rollbackForkPoint <> nil then
  begin
    Exit(Format('error fork point check, %d', [rollbackForkPoint.Height]));
  end;

  Exit(nil);
end;

function TChain.initCache: Error;
var
  err: Error;
begin
  // init cache
  if c.cache.Init() <> nil then
  begin
    cErr := Format('c.cache.Init failed. Error: %s', [err]);
    c.log.Error(cErr, 'method', 'initCache');
    Exit(cErr);
  end;

  // init state db cache
  if c.stateDB.Init() <> nil then
  begin
    cErr := Format('c.stateDB.Init failed. Error: %s', [err]);
    c.log.Error(cErr, 'method', 'initCache');
    Exit(cErr);
  end;

  // init index db cache
  if c.indexDB.Init(c) <> nil then
  begin
    cErr := Format('c.indexDB.Init failed. Error: %s', [err]);
    c.log.Error(cErr, 'method', 'initCache');
    Exit(cErr);
  end;

  // init sync cache
  c.syncCache, err := sync_cache.NewSyncCache(Path.Join(c.chainDir, 'sync_cache'));
  if err <> nil then
  begin
    cErr := Format('sync_cache.NewSyncCache failed. Error: %s', [err]);
    c.log.Error(cErr, 'method', 'initCache');
    Exit(cErr);
  end;

  Exit(nil);
end;

function TChain.closeAndCleanData: Error;
var
  err: Error;
begin
  // close blockDB
  if c.blockDB.Close() <> nil then
  begin
    cErr := Format('c.blockDB.Close failed. Error: %s', [err]);

    c.log.Error(cErr, 'method', 'closeAndCleanData');
    Exit(err);
  end;

  // close indexDB
  if c.indexDB.Close() <> nil then
  begin
    cErr := Format('c.indexDB.Close failed. Error: %s', [err]);

    c.log.Error(cErr, 'method', 'closeAndCleanData');
    Exit(err);
  end;

  // close stateDB
  if c.stateDB.Close() <> nil then
  begin
    cErr := Format('c.stateDB.Close failed. Error: %s', [err]);

    c.log.Error(cErr, 'method', 'closeAndCleanData');
    Exit(err);
  end;

  // close flusher
  if c.flusher.Close() <> nil then
  begin
    cErr := Format('c.flusher.Close failed. Error: %s', [err]);

    c.log.Error(cErr, 'method', 'closeAndCleanData');
    Exit(err);
  end;

  // close plugins
  if c.chainCfg.OpenPlugins then
  begin
    if c.plugins.Close() <> nil then
    begin
      cErr := Format('c.plugins.Close failed. Error: %s', [err]);

      c.log.Error(cErr, 'method', 'closeAndCleanData');
      Exit(err);
    end;
  end;

  // clean all data
  if c.cleanAllData() <> nil then
  begin
    cErr := Format('c.cleanAllData failed. Error: %s', [err]);

    c.log.Error(cErr, 'method', 'closeAndCleanData');
    Exit(err);
  end;
  Exit(nil);
end;

function TChain.cleanAllData: Error;
begin
  Exit(RemoveAll(c.chainDir));
end;

function TChain.defaultConfig: TChainConfig;
begin
  Result := config.Chain.Create;
  Result.LedgerGc := True;
  Result.LedgerGcRetain := 24 * 3600;
  Result.OpenPlugins := False;
end;

function TChain.DBs: (TIndexDB, TBlockDB, TStateDB);
begin
  Exit(c.indexDB, c.blockDB, c.stateDB);
end;

function TChain.Flusher: TFlusher;
begin
  Exit(c.flusher);
end;

procedure TChain.ResetLog(dir: string; lvl: string);
var
  h: TLogHandler;
begin
  h := common.LogHandler(dir, 'chain_logs', 'chain.log', lvl);
  c.log.SetHandler(h);
  c.blockDB.SetLog(h);
end;

function TChain.GetStatus: TArray<IDBStatus>;
var
  statusList: TArray<IDBStatus>;
begin
  statusList := [];
  statusList := statusList + c.cache.GetStatus();
  statusList := statusList + c.indexDB.GetStatus();
  statusList := statusList + c.blockDB.GetStatus();
  statusList := statusList + c.stateDB.GetStatus();

  Exit(statusList);
end;

procedure TChain.SetCacheLevelForConsensus(level: UInt32);
begin
  c.stateDB.SetCacheLevelForConsensus(level);
end;

procedure TChain.StopWrite;
begin
  c.flushMu.Lock();
end;

procedure TChain.RecoverWrite;
begin
  c.flushMu.Unlock();
end;


end.
