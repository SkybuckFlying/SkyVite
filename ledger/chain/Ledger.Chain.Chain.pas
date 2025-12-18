unit V2.Ledger.Chain.Chain;

interface

uses
  Ledger.Chain.Account,
  Ledger.Chain.Account.Block,
  Ledger.Chain.Account.Block.Test,
  Ledger.Chain.Account.Test,
  Ledger.Chain.Builtin.Contract,
  Ledger.Chain.Builtin.Contract.Test,
  Ledger.Chain.Chain.Test,
  Ledger.Chain.Check,
  Ledger.Chain.Delete,
  Ledger.Chain.Delete.Test,
  Ledger.Chain.Event.Manager,
  Ledger.Chain.Fork,
  Ledger.Chain.Insert,
  Ledger.Chain.Insert.Test,
  Ledger.Chain.Interface,
  Ledger.Chain.Meta,
  Ledger.Chain.Onroad,
  Ledger.Chain.Onroad.Test,
  Ledger.Chain.Snapshot.Block,
  Ledger.Chain.Snapshot.Block.Test,
  Ledger.Chain.State,
  Ledger.Chain.State.Test,
  Ledger.Chain.Sync.Ledger,
  Ledger.Chain.Unconfirmed,
  Ledger.Chain.Unconfirmed.Test,
  System.SysUtils System.Classes System.Generics.Collections System.SyncObjs,
  V2.Common.Config V2.Common.Types V2.Interfaces V2.Interfaces.Core,
  V2.Common.Upgrade,
  V2.Ledger.Chain.Block V2.Ledger.Chain.Cache V2.Ledger.Chain.Flusher,
  V2.Ledger.Chain.Genesis V2.Ledger.Chain.Index V2.Ledger.Chain.Plugins,
  V2.Ledger.Chain.State V2.Ledger.Chain.SyncCache V2.Log15 V2.Common.DB.XLevelDB;

type
  TChainStatus = (
    csStop,
    csStart
  );

  TChain = class(TInterfacedObject, IChain)
  private
    FGenesisCfg: TGenesisConfig;
    FChainCfg: TChainConfig;
    FGenesisSnapshotBlock: ISnapshotBlock;
    FGenesisAccountBlocks: TArray<IVmAccountBlock>;
    FGenesisAccountBlockHash: TDictionary<THash, Boolean>;
    FDataDir: string;
    FChainDir: string;
    FVerifier: IConsensusVerifier;
    FLog: ILogger;
    FEM: IEventManager;
    FCache: TCache;
    FMetaDB: TLevelDB;
    FIndexDB: TIndexDB;
    FBlockDB: TBlockDB;
    FStateDB: TStateDB;
    FSyncCache: ISyncCache;
    FFlusher: TFlusher;
    FFlushMu: TMultiReadExclusiveWriteSynchronizer;
    FPlugins: TPlugins;
    FStatus: TChainStatus;
    function NewDb(ADirName: string): TLevelDB;
    procedure NewDbAndRecover;
    function CheckAndInitData: Byte;
    function CheckForkPoints: Boolean;
    procedure InitCache;
    procedure CloseAndCleanData;
    procedure CleanAllData;
    function DefaultConfig: TChainConfig;
  public
    constructor Create(ADir: string; AChainCfg: TChainConfig; AGenesisCfg: TGenesisConfig);
    destructor Destroy; override;
    procedure Init;
    procedure Start;
    procedure Stop;
    procedure DestroyChain;
    function Plugins: TPlugins;
    function PrepareOnroadDb: TLevelDB;
    procedure SetConsensus(AVerifier: IConsensusVerifier; APeriodTimeIndex: ITimeIndex);
    procedure DBs(out AIndexDB: TIndexDB; out ABlockDB: TBlockDB; out AStateDB: TStateDB);
    function Flusher: TFlusher;
    procedure ResetLog(ADir, ALvl: string);
    function GetStatus: TArray<IDBStatus>;
    procedure SetCacheLevelForConsensus(ALevel: TUInt32);
    procedure StopWrite;
    procedure RecoverWrite;
  end;

implementation

uses
  System.IOUtils,
  V2.Common;

{ TChain }

constructor TChain.Create(ADir: string; AChainCfg: TChainConfig; AGenesisCfg: TGenesisConfig);
begin
  inherited Create;
  if AChainCfg = nil then
    FChainCfg := DefaultConfig
  else
    FChainCfg := AChainCfg;
  if AGenesisCfg = nil then
    FGenesisCfg := TGenesisConfig.MainnetGenesis
  else
    FGenesisCfg := AGenesisCfg;

  FDataDir := ADir;
  FChainDir := TPath.Combine(ADir, 'ledger');
  FLog := TLog15.New('module', 'chain');
  FEM := TEventManager.Create(Self);
  TChainGenesis.UpdateDexFundOwner(FGenesisCfg);
  FGenesisAccountBlocks := TChainGenesis.NewGenesisAccountBlocks(FGenesisCfg);
  FGenesisSnapshotBlock := TChainGenesis.NewGenesisSnapshotBlock(FGenesisAccountBlocks);
  FGenesisAccountBlockHash := TChainGenesis.VmBlocksToHashMap(FGenesisAccountBlocks);
end;

destructor TChain.Destroy;
begin
  FFlushMu.Free;
  inherited Destroy;
end;

procedure TChain.Init;
var
  LStatus: Byte;
begin
  FLog.Info('Begin initializing', ['method', 'Init']);
  try
    NewDbAndRecover;
    LStatus := CheckAndInitData;
    if LStatus <> TChainGenesis.LedgerValid then
      raise Exception.CreateFmt('The genesis state is incorrect. You can fix the problem by removing the database manually. The directory of database is %s.', [FChainDir]);
    InitCache;
    CheckForkPoints;
  except
    on E: Exception do
    begin
      FLog.Error('Init failed', ['error', E.Message]);
      raise;
    end;
  end;
  FLog.Info('Complete initialization', ['method', 'Init']);
end;

procedure TChain.Start;
begin
  if AtomicCmpSet(Integer(FStatus), Integer(csStop), Integer(csStart)) then
  begin
    FFlusher.Start;
    FLog.Info('Start flusher', ['method', 'Start']);
  end;
end;

procedure TChain.Stop;
begin
  if AtomicCmpSet(Integer(FStatus), Integer(csStart), Integer(csStop)) then
  begin
    FFlusher.Stop;
    FLog.Info('Stop flusher', ['method', 'Stop']);
  end;
end;

procedure TChain.DestroyChain;
begin
  FLog.Info('Begin to destroy', ['method', 'Close']);
  try
    FCache.Destroy;
    FLog.Info('Close cache', ['method', 'Close']);
    FStateDB.Close;
    FLog.Info('Close stateDB', ['method', 'Close']);
    FIndexDB.Close;
    FLog.Info('Close indexDB', ['method', 'Close']);
    FBlockDB.Close;
    FLog.Info('Close blockDB', ['method', 'Close']);
    FSyncCache.Close;
    FLog.Info('Close syncCache', ['method', 'Close']);
    FFlusher := nil;
    FCache := nil;
    FStateDB := nil;
    FIndexDB := nil;
    FBlockDB := nil;
    FSyncCache := nil;
  except
    on E: Exception do
    begin
      FLog.Error('DestroyChain failed', ['error', E.Message]);
      raise;
    end;
  end;
  FLog.Info('Complete destruction', ['method', 'Close']);
end;

function TChain.Plugins: TPlugins;
begin
  Result := FPlugins;
end;

function TChain.NewDb(ADirName: string): TLevelDB;
var
  LAbsoluteDirName: string;
begin
  LAbsoluteDirName := TPath.Combine(FChainDir, ADirName);
  try
    Result := TLevelDB.OpenFile(LAbsoluteDirName, nil);
  except
    on E: Exception do
    begin
      FLog.Error(Format('new db failed, error is %s, chainDir is %s', [E.Message, FChainDir]), 'method', 'NewDb');
      raise;
    end;
  end;
end;

function TChain.PrepareOnroadDb: TLevelDB;
var
  LDirName, LAbsoluteDirName: string;
begin
  LDirName := 'onroad';
  LAbsoluteDirName := TPath.Combine(FChainDir, LDirName);
  FLog.Info('clear onroad db', ['dir', LAbsoluteDirName]);
  try
    if TDirectory.Exists(LAbsoluteDirName) then
      TDirectory.Delete(LAbsoluteDirName, True);
    Result := NewDb(LDirName);
  except
    on E: Exception do
    begin
      FLog.Error('PrepareOnroadDb failed', ['error', E.Message]);
      raise;
    end;
  end;
end;

procedure TChain.SetConsensus(AVerifier: IConsensusVerifier; APeriodTimeIndex: ITimeIndex);
begin
  FLog.Info('Start set consensus', ['method', 'SetConsensus']);
  FVerifier := AVerifier;
  try
    FStateDB.SetTimeIndex(APeriodTimeIndex);
  except
    on E: Exception do
    begin
      Crit(Format('c.stateDB.SetConsensus failed. Error: %s', [E.Message]), ['method', 'SetConsensus']);
    end;
  end;
  FLog.Info('set consensus finished', ['method', 'SetConsensus']);
end;

procedure TChain.NewDbAndRecover;
var
  LStores: TArray<IStorage>;
begin
  try
    FMetaDB := NewDb('chain_meta');
    FIndexDB := TIndexDB.Create(FChainDir);
    FBlockDB := TBlockDB.Create(FChainDir);
    FStateDB := TStateDB.Create(Self, FChainCfg, FChainDir);
    if FChainCfg.OpenPlugins then
    begin
      FPlugins := TPlugins.Create(FChainDir, Self);
      Self.Register(FPlugins);
    end;
    LStores := [FBlockDB, FStateDB.Store, FStateDB.RedoStore, FIndexDB.Store];
    if FChainCfg.OpenPlugins then
      LStores := LStores + [FPlugins.Store];
    FFlusher := TFlusher.Create(LStores, FFlushMu, FChainDir);
    FFlusher.Recover;
    FCache := TCache.Create(Self);
  except
    on E: Exception do
    begin
      FLog.Error(Format('newDbAndRecover failed, error is %s', [E.Message]), 'method', 'newDbAndRecover');
      raise;
    end;
  end;
end;

function TChain.CheckAndInitData: Byte;
begin
  try
    Result := TChainGenesis.CheckLedger(Self, FGenesisSnapshotBlock, FGenesisAccountBlocks);
    if Result = TChainGenesis.LedgerInvalid then
      Exit;
    if Result = TChainGenesis.LedgerEmpty then
    begin
      TChainGenesis.InitLedger(Self, FGenesisSnapshotBlock, FGenesisAccountBlocks);
      Result := TChainGenesis.LedgerValid;
    end;
  except
    on E: Exception do
    begin
      FLog.Error(Format('CheckAndInitData failed, error is %s', [E.Message]), 'method', 'checkAndInitData');
      raise;
    end;
  end;
end;

function TChain.CheckForkPoints: Boolean;
var
  LLatest: ISnapshotBlock;
  LActivePoints: TArray<TUpgradePoint>;
  LRollbackForkPoint: IUpgradePoint;
  I: Integer;
  LForkPoint: IUpgradePoint;
  LSb: ISnapshotBlock;
begin
  try
    LLatest := Self.GetLatestSnapshotBlock;
    LActivePoints := TUpgrade.GetActivePoints(LLatest.Height);
    LRollbackForkPoint := nil;
    for I := High(LActivePoints) downto 0 do
    begin
      LForkPoint := LActivePoints[I];
      LSb := Self.GetSnapshotBlockByHeight(LForkPoint.Height);
      if LSb = nil then
        Continue;
      if LSb.ComputeHash = LSb.Hash then
        Break;
      LRollbackForkPoint := LForkPoint;
    end;
    if LRollbackForkPoint <> nil then
      raise Exception.CreateFmt('error fork point check, %d', [LRollbackForkPoint.Height]);
    Result := True;
  except
    on E: Exception do
    begin
      FLog.Error(Format('CheckForkPoints failed, error is %s', [E.Message]), 'method', 'CheckForkPoints');
      raise;
    end;
  end;
end;

procedure TChain.InitCache;
begin
  try
    FCache.Init;
    FStateDB.Init;
    FIndexDB.Init(Self);
    FSyncCache := TSyncCache.Create(TPath.Combine(FChainDir, 'sync_cache'));
  except
    on E: Exception do
    begin
      FLog.Error(Format('InitCache failed, error is %s', [E.Message]), 'method', 'initCache');
      raise;
    end;
  end;
end;

procedure TChain.CloseAndCleanData;
begin
  try
    FBlockDB.Close;
    FIndexDB.Close;
    FStateDB.Close;
    FFlusher.Close;
    if FChainCfg.OpenPlugins then
      FPlugins.Close;
    CleanAllData;
  except
    on E: Exception do
    begin
      FLog.Error(Format('CloseAndCleanData failed, error is %s', [E.Message]), 'method', 'closeAndCleanData');
      raise;
    end;
  end;
end;

procedure TChain.CleanAllData;
begin
  try
    TDirectory.Delete(FChainDir, True);
  except
    on E: Exception do
    begin
      FLog.Error(Format('CleanAllData failed, error is %s', [E.Message]), 'method', 'cleanAllData');
      raise;
    end;
  end;
end;

function TChain.DefaultConfig: TChainConfig;
begin
  Result := TChainConfig.Create;
  Result.LedgerGc := True;
  Result.LedgerGcRetain := 24 * 3600;
  Result.OpenPlugins := False;
end;

procedure TChain.DBs(out AIndexDB: TIndexDB; out ABlockDB: TBlockDB; out AStateDB: TStateDB);
begin
  AIndexDB := FIndexDB;
  ABlockDB := FBlockDB;
  AStateDB := FStateDB;
end;

function TChain.Flusher: TFlusher;
begin
  Result := FFlusher;
end;

procedure TChain.ResetLog(ADir, ALvl: string);
var
  LH: TLogHandler;
begin
  LH := TCommon.LogHandler(ADir, 'chain_logs', 'chain.log', ALvl);
  FLog.SetHandler(LH);
  FBlockDB.SetLog(LH);
end;

function TChain.GetStatus: TArray<IDBStatus>;
begin
  Result := FCache.GetStatus + FIndexDB.GetStatus + FBlockDB.GetStatus + FStateDB.GetStatus;
end;

procedure TChain.SetCacheLevelForConsensus(ALevel: TUInt32);
begin
  FStateDB.SetCacheLevelForConsensus(ALevel);
end;

procedure TChain.StopWrite;
begin
  FFlushMu.BeginWrite;
end;

procedure TChain.RecoverWrite;
begin
  FFlushMu.EndWrite;
end;

end.
