unit unit_chain_v2;

// Code Generator.
// https://zzzcode.ai/code-generator?id=0c7a2760-dd0b-4f43-9b77-69ec40f437d6&mode=edit
// Translate GO to Delphi, Direct
// Translate GO code to Delphi code
// copy and paste go struct again for second part.

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  GoViteCommon, GoViteConfig, GoViteTypes, GoViteUpgrade, GoViteInterfaces,
  GoViteLedger, GoViteChainBlock, GoViteChainCache, GoViteChainFlusher,
  GoViteChainGenesis, GoViteChainIndex, GoViteChainPlugins, GoViteChainState,
  GoViteSyncCache, GoViteLog;

type
  TChain = class
  private
    FGenesisCfg: TGenesisConfig;
	FChainCfg: TChainConfig;
	FGenesisSnapshotBlock: TSnapshotBlock;
    FGenesisAccountBlocks: TArray<IVmAccountBlock>;
    FGenesisAccountBlockHash: TDictionary<THash, Boolean>;

    FDataDir: string;
    FChainDir: string;
    FVerifier: IConsensusVerifier;

    FLog: TLog;

    FEventManager: TEventManager;
    FCache: TChainCache;

    FMetaDB: TLevelDB;
    FIndexDB: TIndexDB;
    FBlockDB: TBlockDB;
    FStateDB: TStateDB;

    FSyncCache: ISyncCache;

    FFlusher: TChainFlusher;

    FFlushMu: TRTLCriticalSection;

    FPlugins: TChainPlugins;

    FStatus: Cardinal;
  public
    constructor Create(const ADataDir: string; AChainCfg: PChainConfig = nil; AGenesisCfg: PGenesisConfig = nil);
    destructor Destroy; override;

    procedure Init;
    procedure Start;
    procedure Stop;
    procedure Destroy;

    property Plugins: TChainPlugins read FPlugins;
  end;

implementation

constructor TChain.Create(const ADataDir: string; AChainCfg: PChainConfig = nil; AGenesisCfg: PGenesisConfig = nil);
begin
  inherited Create;
  FDataDir := ADataDir;
  FChainDir := TPath.Combine(ADataDir, 'ledger');
  FLog := TLog.Create('chain');

  if AChainCfg = nil then
    FChainCfg := DefaultConfig
  else
    FChainCfg := AChainCfg^;

  if AGenesisCfg = nil then
    FGenesisCfg := MainnetGenesis
  else
    FGenesisCfg := AGenesisCfg^;

  FEventManager := TEventManager.Create(Self);
  UpdateDexFundOwner(FGenesisCfg);
  FGenesisAccountBlocks := NewGenesisAccountBlocks(FGenesisCfg);
  FGenesisSnapshotBlock := NewGenesisSnapshotBlock(FGenesisAccountBlocks);
  FGenesisAccountBlockHash := VmBlocksToHashMap(FGenesisAccountBlocks);
end;

destructor TChain.Destroy;
begin
  FCache.Destroy;
  FStateDB.Close;
  FIndexDB.Close;
  FBlockDB.Close;
  FSyncCache.Close;

  FFlusher.Free;
  FCache.Free;
  FStateDB.Free;
  FIndexDB.Free;
  FBlockDB.Free;
  FSyncCache.Free;

  inherited Destroy;
end;

procedure TChain.Init;
begin
  FLog.Info('Begin initializing', 'method', 'Init');

  if not NewDbAndRecover then
	raise Exception.Create('Failed to initialize database');

  var Status := CheckAndInitData;
  if Status <> LedgerValid then
    raise Exception.CreateFmt('The genesis state is incorrect. You can fix the problem by removing the database manually. The directory of the database is %s.', [FChainDir]);

  if not InitCache then
    raise Exception.Create('Failed to initialize cache');

  if not CheckForkPoints then
    raise Exception.Create('Failed to check fork points');

  FLog.Info('Complete initialization', 'method', 'Init');
end;

procedure TChain.Start;
begin
  if InterlockedCompareExchange(FStatus, Start, Stop) <> Stop then
    Exit;

  FFlusher.Start;
  FLog.Info('Start flusher', 'method', 'Start');
end;

procedure TChain.Stop;
begin
  if InterlockedCompareExchange(FStatus, Stop, Start) <> Start then
    Exit;

  FFlusher.Stop;
  FLog.Info('Stop flusher', 'method', 'Stop');
end;

procedure TChain.Destroy;
begin
  FLog.Info('Begin to destroy', 'method', 'Close');

  FCache.Destroy;
  FLog.Info('Close cache', 'method', 'Close');

  FStateDB.Close;
  FLog.Info('Close stateDB', 'method', 'Close');

  FIndexDB.Close;
  FLog.Info('Close indexDB', 'method', 'Close');

  FBlockDB.Close;
  FLog.Info('Close blockDB', 'method', 'Close');

  FSyncCache.Close;
  FLog.Info('Close syncCache', 'method', 'Close');

  FFlusher := nil;
  FCache := nil;
  FStateDB := nil;
  FIndexDB := nil;
  FBlockDB := nil;
  FSyncCache := nil;

  FLog.Info('Complete destruction', 'method', 'Close');
end;

procedure TChain.SetConsensus(AVerifier: IConsensusVerifier; APeriodTimeIndex: ITimeIndex);
begin
  FLog.Info('Start set consensus', 'method', 'SetConsensus');
  FVerifier := AVerifier;

  if not FStateDB.SetTimeIndex(APeriodTimeIndex) then
    raise Exception.Create('Failed to set consensus');

  FLog.Info('Set consensus finished', 'method', 'SetConsensus');
end;

procedure TChain.NewDbAndRecover;
begin
  FMetaDB := NewDb('chain_meta');
  FIndexDB := TIndexDB.Create(FChainDir);
  FBlockDB := TBlockDB.Create(FChainDir);
  FStateDB := TStateDB.Create(Self, FChainCfg, FChainDir);
  if FChainCfg.OpenPlugins then
  begin
    FPlugins := TPlugins.Create(FChainDir, Self);
    Register(FPlugins);
  end;
  FFlusher := TFlusher.Create([FBlockDB, FStateDB.Store, FStateDB.RedoStore, FIndexDB.Store], FFlushMu, FChainDir);
  FFlusher.Recover;
  FCache := TCache.Create(Self);
end;

procedure TChain.CheckAndInitData;
var
  Status: Byte;
begin
  Status := CheckLedger(Self, FGenesisSnapshotBlock, FGenesisAccountBlocks);
  if Status = LedgerInvalid then
    Exit;
  if Status = LedgerEmpty then
  begin
    InitLedger(Self, FGenesisSnapshotBlock, FGenesisAccountBlocks);
    Status := LedgerValid;
  end;
end;

procedure TChain.CheckForkPoints;
var
  Latest: TSnapshotBlock;
  ActivePoints: TArray<TUpgradePoint>;
  I: Integer;
  ForkPoint: TUpgradePoint;
  SB: TSnapshotBlock;
  RollbackForkPoint: TUpgradePoint;
begin
  Latest := GetLatestSnapshotBlock;
  ActivePoints := GetActivePoints(Latest.Height);
  for I := Length(ActivePoints) - 1 downto 0 do
  begin
    ForkPoint := ActivePoints[I];
    SB := GetSnapshotBlockByHeight(ForkPoint.Height);
    if SB = nil then
      Continue;
    if SB.ComputeHash = SB.Hash then
      Break;
    RollbackForkPoint := ForkPoint;
  end;
  if RollbackForkPoint <> nil then
	raise Exception.CreateFmt('Error fork point check, %d', [RollbackForkPoint.Height]);
end;

procedure TChain.InitCache;
begin
  FCache.Init;
  FStateDB.Init;
  FIndexDB.Init(Self);
  FSyncCache := TSyncCache.Create(Path.Combine(FChainDir, 'sync_cache'));
end;

procedure TChain.CloseAndCleanData;
begin
  FBlockDB.Close;
  FIndexDB.Close;
  FStateDB.Close;
  FFlusher.Close;
  if FChainCfg.OpenPlugins then
	FPlugins.Close;
  CleanAllData;
end;

procedure TChain.CleanAllData;
begin
  TDirectory.Delete(FChainDir, True);
end;

function TChain.DefaultConfig: TChainConfig;
begin
  Result := TChainConfig.Create;
  Result.LedgerGc := True;
  Result.LedgerGcRetain := 24 * 3600;
  Result.OpenPlugins := False;
end;

procedure TChain.DBs: (TIndexDB, TBlockDB, TStateDB);
begin
  Result := (FIndexDB, FBlockDB, FStateDB);
end;

function TChain.Flusher: TFlusher;
begin
  Result := FFlusher;
end;

procedure TChain.ResetLog(const ADir, ALvl: string);
begin
  FLog.SetHandler(TLogHandler.Create(ADir, 'chain_logs', 'chain.log', ALvl));
  FBlockDB.SetLog(FLog);
end;

function TChain.GetStatus: TArray<IDBStatus>;
var
  StatusList: TArray<IDBStatus>;
begin
  SetLength(StatusList, 0);
  StatusList := StatusList + FCache.GetStatus;
  StatusList := StatusList + FIndexDB.GetStatus;
  StatusList := StatusList + FBlockDB.GetStatus;
  StatusList := StatusList + FStateDB.GetStatus;
  Result := StatusList;
end;

procedure TChain.SetCacheLevelForConsensus(const ALevel: Cardinal);
begin
  FStateDB.SetCacheLevelForConsensus(ALevel);
end;

procedure TChain.StopWrite;
begin
  FFlushMu.Lock;
end;

procedure TChain.RecoverWrite;
begin
  FFlushMu.Unlock;
end;


end.

