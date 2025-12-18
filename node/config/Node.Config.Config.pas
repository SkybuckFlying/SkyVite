unit Node.Config.Config;

interface

uses
  Common.Config.Config,
  Common.Types,
  Crypto.Ed25519,
  Node.Config.Config.Test,
  Node.Config.Defaults,
  System.Classes,
  System.Generics.Collections,
  System.IOUtils,
  System.JSON,
  System.SysUtils,
  unit_GoLang_Compatibility_version_006;

type
	TNodeConfig = class
	public
		NetSelect : string;
		DataDir : string;
		KeyStoreDir : string;

		// chain
		LedgerGcRetain : UInt64;
		LedgerGc : PBoolean;
		OpenPlugins : PBoolean;
		VmLogWhiteList : TArray<TAddress>;
		VmLogAll : PBoolean;

		// genesis
		GenesisFile : string;

		// net
		Single : Boolean;
		ListenInterface : string;
		Port : Integer;
		FilePort : Integer;
		PublicAddress : string;
		FilePublicAddress : string;
		Identity : string;
		NetID : Integer;
		PeerKey : string;
		Discover : Boolean;
		MaxPeers : Integer;
		MinPeers : Integer;
		MaxInboundRatio : Integer;
		MaxPendingPeers : Integer;
		BootNodes : TArray<string>;
		BootSeeds : TArray<string>;
		StaticNodes : TArray<string>;
		AccessControl : string;
		AccessAllowKeys : TArray<string>;
		AccessDenyKeys : TArray<string>;
		BlackBlockHashList : TArray<string>;
		WhiteBlockList : TArray<string>;
		ForwardStrategy : string;

		// producer
		EntropyStorePath : string;
		EntropyStorePassword : string;
		CoinBase : string;
		MinerEnabled : Boolean;

		// rpc
		RPCEnabled : Boolean;
		IPCEnabled : Boolean;
		WSEnabled : Boolean;
		TxDexEnable : PBoolean;

		IPCPath : string;
		HttpHost : string;
		HttpPort : Integer;
		HttpVirtualHosts : TArray<string>;
		WSHost : string;
		WSPort : Integer;
		PrivateHttpPort : Integer;

		HTTPCors : TArray<string>;
		WSOrigins : TArray<string>;
		PublicModules : TArray<string>;
		WSExposeAll : Boolean;
		HttpExposeAll : Boolean;
		TestTokenHexPrivKey : string;
		TestTokenTti : string;

		PowServerUrl : string;

		// Log level
		LogLevel : string;
		ErrorLogDir : string;

		// VM
		VMTestEnabled : Boolean;
		VMTestParamEnabled : Boolean;
		QuotaTestParamEnabled : Boolean;
		VMDebug : Boolean;

		// subscribe
		SubscribeEnabled : Boolean;

		// dashboard
		DashboardTargetURL : string;

		// reward
		RewardAddr : string;

		// metrics
		MetricsEnable : PBoolean;
		InfluxDBEnable : PBoolean;
		InfluxDBEndpoint : PString;
		InfluxDBDatabase : PString;
		InfluxDBUsername : PString;
		InfluxDBPassword : PString;
		InfluxDBHostTag : PString;

		constructor Create;
		function MakeWalletConfig : TWalletConfig;
		function MakeViteConfig : TViteConfig;
		function MakeNetConfig : TNetConfig;
		function MakeRewardConfig : TNodeRewardConfig;
		function MakeVmConfig : TVmConfig;
		function MakeSubscribeConfig : TSubscribeConfig;
		function MakeMinerConfig : TProducerConfig;
		function MakeChainConfig : TChainConfig;

		function HTTPEndpoint : string;
		function WSEndpoint : string;
		function PrivateHTTPEndpoint : string;
		function IPCEndpoint : string;
		function RunLogDir : string;

		procedure DataDirPathAbs;
		procedure ParseFromFile( const ParaFilename : string );
		procedure SetPrivateKey( const ParaPrivateKey : string );
		function GetPrivateKey : TEd25519PrivateKey;
	end;

implementation

{ TNodeConfig }

constructor TNodeConfig.Create;
begin
	inherited Create;
	// Initialize default values...
end;

function TNodeConfig.MakeWalletConfig : TWalletConfig;
begin
	Result := TWalletConfig.Create;
	Result.DataDir := KeyStoreDir;
end;

function TNodeConfig.MakeViteConfig : TViteConfig;
begin
	Result := TViteConfig.Create;
	try
		Result.Chain := MakeChainConfig;
		Result.Producer := MakeMinerConfig;
		Result.DataDir := DataDir;
		Result.Net := MakeNetConfig;
		Result.Vm := MakeVmConfig;
		Result.Subscribe := MakeSubscribeConfig;
		Result.NodeReward := MakeRewardConfig;
		Result.Genesis := TGenesisConfig.Make( GenesisFile );
		Result.LogLevel := LogLevel;
	except
		Result.Free;
		raise;
	end;
end;

function TNodeConfig.MakeNetConfig : TNetConfig;
begin
	Result := TNetConfig.Create;
	Result.Single := Single;
	Result.Name := Identity;
	Result.NetID := NetID;
	Result.ListenInterface := ListenInterface;
	Result.Port := Port;
	Result.FilePort := FilePort;
	Result.PublicAddress := PublicAddress;
	Result.FilePublicAddress := FilePublicAddress;
	Result.DataDir := TPath.Combine( DataDir, 'net' );
	Result.PeerKey := PeerKey;
	Result.Discover := Discover;
	Result.BootNodes := BootNodes;
	Result.BootSeeds := BootSeeds;
	Result.StaticNodes := StaticNodes;
	Result.MaxPeers := MaxPeers;
	Result.MaxInboundRatio := MaxInboundRatio;
	Result.MinPeers := MinPeers;
	Result.MaxPendingPeers := MaxPendingPeers;
	Result.ForwardStrategy := ForwardStrategy;
	Result.AccessControl := AccessControl;
	Result.AccessAllowKeys := AccessAllowKeys;
	Result.AccessDenyKeys := AccessDenyKeys;
	Result.BlackBlockHashList := BlackBlockHashList;
	Result.WhiteBlockList := WhiteBlockList;
end;

function TNodeConfig.MakeRewardConfig : TNodeRewardConfig;
begin
	Result := TNodeRewardConfig.Create;
	Result.RewardAddr := RewardAddr;
	Result.Name := Identity;
end;

function TNodeConfig.MakeVmConfig : TVmConfig;
begin
	Result := TVmConfig.Create;
	Result.IsVmTest := VMTestEnabled;
	Result.IsUseVmTestParam := VMTestParamEnabled;
	Result.IsUseQuotaTestParam := QuotaTestParamEnabled;
	Result.IsVmDebug := VMDebug;
end;

function TNodeConfig.MakeSubscribeConfig : TSubscribeConfig;
begin
	Result := TSubscribeConfig.Create;
	Result.IsSubscribe := SubscribeEnabled;
end;

function TNodeConfig.MakeMinerConfig : TProducerConfig;
begin
	Result := TProducerConfig.Create;
	Result.Producer := MinerEnabled;
	Result.Coinbase := CoinBase;
	Result.EntropyStorePath := EntropyStorePath;
	// Result.Parse; // Logic for parsing coinbase etc.
end;

function TNodeConfig.MakeChainConfig : TChainConfig;
begin
	Result := TChainConfig.Create;
	Result.LedgerGcRetain := LedgerGcRetain;
	if LedgerGc <> nil then Result.LedgerGc := LedgerGc^ else Result.LedgerGc := True;
	if OpenPlugins <> nil then Result.OpenPlugins := OpenPlugins^ else Result.OpenPlugins := False;
	Result.VmLogWhiteList := VmLogWhiteList;
	if VmLogAll <> nil then Result.VmLogAll := VmLogAll^ else Result.VmLogAll := False;
end;

function TNodeConfig.HTTPEndpoint : string;
begin
	if HttpHost = '' then Exit( '' );
	Result := Format( '%s:%d', [HttpHost, HttpPort] );
end;

function TNodeConfig.WSEndpoint : string;
begin
	if WSHost = '' then Exit( '' );
	Result := Format( '%s:%d', [WSHost, WSPort] );
end;

function TNodeConfig.PrivateHTTPEndpoint : string;
begin
	if PrivateHttpPort = 0 then Exit( '' );
	Result := Format( '127.0.0.1:%d', [PrivateHttpPort] );
end;

function TNodeConfig.IPCEndpoint : string;
begin
	if IPCPath = '' then Exit( '' );
	if IPCPath.StartsWith( '\\.\pipe\' ) then Result := IPCPath else Result := '\\.\pipe\' + IPCPath;
end;

function TNodeConfig.RunLogDir : string;
begin
	Result := TPath.Combine( DataDir, 'runlog', FormatDateTime( 'yyyy-mm-dd"T"hh-nn', Now ) );
end;

procedure TNodeConfig.DataDirPathAbs;
begin
	if DataDir <> '' then DataDir := TPath.GetFullPath( DataDir );
	if KeyStoreDir <> '' then KeyStoreDir := TPath.GetFullPath( KeyStoreDir );
end;

procedure TNodeConfig.ParseFromFile( const ParaFilename : string );
begin
	// JSON Unmarshal logic...
end;

procedure TNodeConfig.SetPrivateKey( const ParaPrivateKey : string );
begin
	PeerKey := ParaPrivateKey;
end;

function TNodeConfig.GetPrivateKey : TEd25519PrivateKey;
begin
	// HexToBytes logic...
	Result := nil;
end;

end.
