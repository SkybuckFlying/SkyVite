unit unit_node_config;

{
This is a Go programming language configuration file parser in the `config` package. It provides methods to parse and validate a JSON-formatted configuration file, as well as methods to get various settings from the parsed configuration.

The `Config` struct contains fields for different configuration options such as:

*   Network settings like hostnames, ports, and encryption keys
*   Ledger settings like GC retention policy and VM log storage
*   Data directory paths and IPC endpoints
*   Private key and other security-related settings

The `ParseFromFile` method reads a JSON-formatted file and unmarshals it into the `Config` struct. The `DataDirPathAbs` method resolves the data directory path to an absolute path, so that changes to the current working directory do not affect the node.

Some of the notable methods in this code include:

*   `MakeChainConfig`: Creates a new chain configuration based on the settings in the parsed config
*   `HTTPEndpoint`, `WSEndpoint`, and `PrivateHTTPEndpoint`: Return the HTTP, WebSocket, and private HTTP endpoints for the node, respectively
*   `SetPrivateKey` and `GetPrivateKey`: Set and get the private key for the node
*   `IPCEndpoint`: Returns the IPC endpoint path

The code also includes some utility methods like `json.Unmarshal` to unmarshal JSON data into a Go struct, `filepath.Join` to join paths together, and `ioutil.ReadFile` to read a file into a byte slice.

Overall, this is a comprehensive configuration file parser for a blockchain node written in the Go programming language.
}


interface

type
  TConfig = record
	NetSelect: string;

	DataDir: string;

	KeyStoreDir: string;

	LedgerGcRetain: UInt64;
	LedgerGc: ^Boolean;
	OpenPlugins: ^Boolean;
	VmLogWhiteList: array of types.Address;
	VmLogAll: ^Boolean;

	GenesisFile: string;

	Single: Boolean;
	ListenInterface: string;
    Port: Integer;
    FilePort: Integer;
    PublicAddress: string;
    FilePublicAddress: string;
    Identity: string;
    NetID: Integer;
    PeerKey: string;
    Discover: Boolean;
    MaxPeers: Integer;
    MinPeers: Integer;
    MaxInboundRatio: Integer;
    MaxPendingPeers: Integer;
    BootNodes: array of string;
    BootSeeds: array of string;
    StaticNodes: array of string;
	AccessControl: string;
    AccessAllowKeys: array of string;
    AccessDenyKeys: array of string;
    BlackBlockHashList: array of string;
    WhiteBlockList: array of string;
    ForwardStrategy: string;

    EntropyStorePath: string;
    EntropyStorePassword: string;
    CoinBase: string;
    MinerEnabled: Boolean;

	RPCEnabled: Boolean;
    IPCEnabled: Boolean;
    WSEnabled: Boolean;
    TxDexEnable: ^Boolean;

    IPCPath: string;
    HttpHost: string;
    HttpPort: Integer;
    HttpVirtualHosts: array of string;
    WSHost: string;
    WSPort: Integer;
    PrivateHttpPort: Integer;

    HTTPCors: array of string;
    WSOrigins: array of string;
    PublicModules: array of string;
    WSExposeAll: Boolean;
    HttpExposeAll: Boolean;
    TestTokenHexPrivKey: string;
    TestTokenTti: string;

    PowServerUrl: string;

    LogLevel: string;
    ErrorLogDir: string;

    VMTestEnabled: Boolean;
    VMTestParamEnabled: Boolean;
	QuotaTestParamEnabled: Boolean;
    VMDebug: Boolean;

    SubscribeEnabled: Boolean;

    DashboardTargetURL: string;

    RewardAddr: string;

    MetricsEnable: ^Boolean;
    InfluxDBEnable: ^Boolean;
    InfluxDBEndpoint: ^string;
    InfluxDBDatabase: ^string;
    InfluxDBUsername: ^string;
    InfluxDBPassword: ^string;
	InfluxDBHostTag: ^string;
  end;


function Config.MakeWalletConfig: config.Wallet;
begin
  Result := config.Wallet.Create;
  Result.DataDir := Self.KeyStoreDir;
end;

function Config.MakeViteConfig: config.Config;
begin
  Result := config.Config.Create;
  Result.Chain := Self.MakeChainConfig;
  Result.Producer := Self.MakeMinerConfig;
  Result.DataDir := Self.DataDir;
  Result.Net := Self.MakeNetConfig;
  Result.Vm := Self.MakeVmConfig;
  Result.Subscribe := Self.MakeSubscribeConfig;
  Result.NodeReward := Self.MakeRewardConfig;
  Result.Genesis := config.MakeGenesisConfig(Self.GenesisFile);
  Result.LogLevel := Self.LogLevel;
end;

function Config.MakeNetConfig: config.Net;
var
  datadir: string;
begin
  datadir := TPath.Combine(Self.DataDir, config.DefaultNetDirName);
  Result := config.Net.Create;
  Result.Single := Self.Single;
  Result.Name := Self.Identity;
  Result.NetID := Self.NetID;
  Result.ListenInterface := Self.ListenInterface;
  Result.Port := Self.Port;
  Result.FilePort := Self.FilePort;
  Result.PublicAddress := Self.PublicAddress;
  Result.FilePublicAddress := Self.FilePublicAddress;
  Result.DataDir := datadir;
  Result.PeerKey := Self.PeerKey;
  Result.Discover := Self.Discover;
  Result.BootNodes := Self.BootNodes;
  Result.BootSeeds := Self.BootSeeds;
  Result.StaticNodes := Self.StaticNodes;
  Result.MaxPeers := Self.MaxPeers;
  Result.MaxInboundRatio := Self.MaxInboundRatio;
  Result.MinPeers := Self.MinPeers;
  Result.MaxPendingPeers := Self.MaxPendingPeers;
  Result.ForwardStrategy := Self.ForwardStrategy;
  Result.AccessControl := Self.AccessControl;
  Result.AccessAllowKeys := Self.AccessAllowKeys;
  Result.AccessDenyKeys := Self.AccessDenyKeys;
  Result.BlackBlockHashList := Self.BlackBlockHashList;
  Result.WhiteBlockList := Self.WhiteBlockList;
  Result.MineKey := nil;
end;

function Config.MakeRewardConfig: config.NodeReward;
begin
  Result := config.NodeReward.Create;
  Result.RewardAddr := Self.RewardAddr;
  Result.Name := Self.Identity;
end;

function Config.MakeVmConfig: config.Vm;
begin
  Result := config.Vm.Create;
  Result.IsVmTest := Self.VMTestEnabled;
  Result.IsUseVmTestParam := Self.VMTestParamEnabled;
  Result.IsUseQuotaTestParam := Self.QuotaTestParamEnabled;
  Result.IsVmDebug := Self.VMDebug;
end;

function Config.MakeSubscribeConfig: config.Subscribe;
begin
  Result := config.Subscribe.Create;
  Result.IsSubscribe := Self.SubscribeEnabled;
end;

function Config.MakeMinerConfig: config.Producer;
var
  cfg: config.Producer;
begin
  cfg := config.Producer.Create;
  cfg.Producer := Self.MinerEnabled;
  cfg.Coinbase := Self.CoinBase;
  cfg.EntropyStorePath := Self.EntropyStorePath;
  cfg.VirtualSnapshotVerifier := False;
  try
    cfg.Parse;
  except
    on E: Exception do
      raise E;
  end;
  Result := cfg;
end;

function Config.MakeChainConfig: config.Chain;
var
  ledgerGc: Boolean;
  openPlugins: Boolean;
  vmLogAll: Boolean;
begin
  ledgerGc := True;
  if Assigned(Self.LedgerGc) then
    ledgerGc := Self.LedgerGc^;
  openPlugins := False;
  if Assigned(Self.OpenPlugins) then
    openPlugins := Self.OpenPlugins^;
  vmLogAll := False;
  if Assigned(Self.VmLogAll) then
    vmLogAll := Self.VmLogAll^;
  Result := config.Chain.Create;
  Result.LedgerGcRetain := Self.LedgerGcRetain;
  Result.LedgerGc := ledgerGc;
  Result.OpenPlugins := openPlugins;
  Result.VmLogWhiteList := Self.VmLogWhiteList;
  Result.VmLogAll := vmLogAll;
end;

function Config.HTTPEndpoint: string;
begin
  if Self.HttpHost = '' then
    Result := ''
  else
    Result := Format('%s:%d', [Self.HttpHost, Self.HttpPort]);
end;

function Config.WSEndpoint: string;
begin
  if Self.WSHost = '' then
    Result := ''
  else
    Result := Format('%s:%d', [Self.WSHost, Self.WSPort]);
end;

function Config.PrivateHTTPEndpoint: string;
begin
  if Self.PrivateHttpPort = 0 then
    Result := ''
  else
    Result := Format('%s:%d', [common.DefaultHTTPHost, Self.PrivateHttpPort]);
end;

procedure Config.SetPrivateKey(privateKey: string);
begin
  Self.PeerKey := privateKey;
end;

function Config.GetPrivateKey: ed25519.PrivateKey;
var
  privateKey: TBytes;
begin
  if Self.PeerKey <> '' then
  begin
    privateKey := THex.DecodeString(Self.PeerKey);
    Result := ed25519.PrivateKey(privateKey);
  end
  else
    Result := nil;
end;

function Config.IPCEndpoint: string;
begin
  if Self.IPCPath = '' then
    Result := ''
  else
  begin
    if runtime.GOOS = 'windows' then
    begin
      if StartsText('\\.\pipe\', Self.IPCPath) then
        Result := Self.IPCPath
      else
        Result := '\\.\pipe\' + Self.IPCPath;
    end
    else
    begin
      if ExtractFileName(Self.IPCPath) = Self.IPCPath then
      begin
        if Self.DataDir = '' then
          Result := TPath.Combine(TPath.GetTempPath, Self.IPCPath)
        else
          Result := TPath.Combine(Self.DataDir, Self.IPCPath);
      end
      else
        Result := Self.IPCPath;
    end;
  end;
end;

function Config.RunLogDir: string;
begin
  Result := TPath.Combine(Self.DataDir, 'runlog', FormatDateTime('yyyy-mm-dd\hh-nn', Now));
end;

function Config.DataDirPathAbs: TError;
var
  absDataDir, absKeyStoreDir: string;
begin
  if Self.DataDir <> '' then
  begin
    absDataDir := TPath.GetFullPath(Self.DataDir);
    Self.DataDir := absDataDir;
  end;

  if Self.KeyStoreDir <> '' then
  begin
    absKeyStoreDir := TPath.GetFullPath(Self.KeyStoreDir);
    Self.KeyStoreDir := absKeyStoreDir;
  end;
end;

function Config.ParseFromFile(filename: string): TError;
var
  jsonConf: TBytes;
begin
  try
    jsonConf := TFile.ReadAllBytes(filename);
    TJson.JsonToObject<TConfig>(jsonConf, Self);
    Result := nil;
  except
    on E: Exception do
      Result := Exception.Create('read config file ' + filename + ' error');
  end;
end;


end.

