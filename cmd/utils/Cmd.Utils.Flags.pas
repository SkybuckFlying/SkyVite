unit Cmd.Utils.Flags;

interface

uses
  Cli,
  Cmd.Utils.Cli,
  Cmd.Utils.CustomFlags,
  Cmd.Utils.Customflags.Test,
  Cmd.Utils.Path;

// Config settings
var
	ConfigFileFlag: TStringFlag;

// General settings
var
	DataDirFlag: TDirectoryFlag;
	KeyStoreDirFlag: TDirectoryFlag;

// Network Settings
var
	TestNetFlag: TBoolFlag;
	DevNetFlag: TBoolFlag;
	MainNetFlag: TBoolFlag;
	IdentityFlag: TStringFlag;
	NetworkIdFlag: TUint64Flag;
	MaxPeersFlag: TUint64Flag;
	MaxPendingPeersFlag: TUint64Flag;
	ListenPortFlag: TIntFlag;
	NodeKeyHexFlag: TStringFlag;
	DiscoveryFlag: TStringFlag;

// IPC Settings
var
	IPCEnabledFlag: TBoolFlag;
	IPCPathFlag: TDirectoryFlag;

// HTTP RPC Settings
var
	RPCEnabledFlag: TBoolFlag;
	RPCListenAddrFlag: TStringFlag;
	RPCPortFlag: TIntFlag;

// WS Settings
var
	WSEnabledFlag: TBoolFlag;
	WSListenAddrFlag: TStringFlag;
	WSPortFlag: TIntFlag;

// Console Settings
var
	JSPathFlag: TStringFlag;
	ExecFlag: TStringFlag;
	PreloadJSFlag: TStringFlag;

// Producer
var
	MinerFlag: TBoolFlag;
	CoinBaseFlag: TStringFlag;
	MinerIntervalFlag: TIntFlag;

// Log Lvl
var
	LogLvlFlag: TStringFlag;

// VM
var
	VMTestFlag: TBoolFlag;
	VMTestParamFlag: TBoolFlag;
	QuotaTestParamFlag: TBoolFlag;
	VMDebugFlag: TBoolFlag;

// Subscribe
var
	SubscribeFlag: TBoolFlag;

// Ledger
var
	LedgerDeleteToHeight: TUint64Flag;

// Trie
var
	RecoverTrieFlag: TBoolFlag;

// Export sb height
var
	ExportSbHeightFlags: TUint64Flag;

// Net
var
	SingleFlag: TBoolFlag;
	FilePortFlag: TIntFlag;

// Stat
var
	PProfEnabledFlag: TBoolFlag;
	PProfPortFlag: TUint64Flag;

// Load
var
	LoadFromDirFlag: TStringFlag;

function MigrateFlags(ParaAction: TActionProc): TActionProc;
function MergeFlags(const ParaFlagsSet: array of TFlagArray): TFlagArray;

var
	ConfigFlags: TFlagArray;
	GeneralFlags: TFlagArray;
	P2pFlags: TFlagArray;
	IpcFlags: TFlagArray;
	HttpFlags: TFlagArray;
	WsFlags: TFlagArray;
	ConsoleFlags: TFlagArray;
	ProducerFlags: TFlagArray;
	LogFlags: TFlagArray;
	VmFlags: TFlagArray;
	NetFlags: TFlagArray;
	StatFlags: TFlagArray;
	LedgerFlags: TFlagArray;
	ExportFlags: TFlagArray;
	LoadLedgerFlags: TFlagArray;

implementation

uses
	System.Generics.Collections;

function MigrateFlags(ParaAction: TActionProc): TActionProc;
begin
	Result := procedure(ParaCtx: TContext)
	var
		vName: string;
	begin
		for vName in ParaCtx.FCommandFlags.Keys do
		begin
			if ParaCtx.FCommandFlags.ContainsKey(vName) then
			begin
				ParaCtx.FGlobalFlags.AddOrSetValue(vName, ParaCtx.FCommandFlags[vName]);
			end;
		end;
		ParaAction(ParaCtx);
	end;
end;

function MergeFlags(const ParaFlagsSet: array of TFlagArray): TFlagArray;
var
	vFlagMap: TDictionary<string, TFlag>;
	vFlags: TFlagArray;
	vFS: TFlagArray;
	vFlag: TFlag;
	vIndex: Integer;
begin
	vFlagMap := TDictionary<string, TFlag>.Create;
	try
		for vFS in ParaFlagsSet do
		begin
			for vFlag in vFS do
			begin
				vFlagMap.AddOrSetValue(vFlag.GetName, vFlag);
			end;
		end;

		SetLength(vFlags, vFlagMap.Count);
		vIndex := 0;
		for vFlag in vFlagMap.Values do
		begin
			vFlags[vIndex] := vFlag;
			Inc(vIndex);
		end;
		Result := vFlags;
	finally
		vFlagMap.Free;
	end;
end;

initialization
	ConfigFileFlag := TStringFlag.Create('config', 'Json configuration file', '');
	DataDirFlag := TDirectoryFlag.Create('datadir', 'use for store all files', '');
	KeyStoreDirFlag := TDirectoryFlag.Create('keystore', 'Directory for the keystore (default = inside the datadir)', '');
	TestNetFlag := TBoolFlag.Create('testnet', 'test network, networkdid==2', False);
	DevNetFlag := TBoolFlag.Create('devnet', 'develop network, networkdid>=3', False);
	MainNetFlag := TBoolFlag.Create('mainnet', 'main network, networkdid==1', False);
	IdentityFlag := TStringFlag.Create('identity', 'Custom node name', '');
	NetworkIdFlag := TUint64Flag.Create('networkid', 'Network identifier (integer, 1=MainNet, 2=TestNet, 3~12=DevNet,)', 0);
	MaxPeersFlag := TUint64Flag.Create('maxpeers', 'Maximum number of network peers (network disabled if set to 0)', 0);
	MaxPendingPeersFlag := TUint64Flag.Create('maxpendpeers', 'Maximum number of db connection attempts (defaults used if set to 0)', 0);
	ListenPortFlag := TIntFlag.Create('port', 'Network listening port', 0);
	NodeKeyHexFlag := TStringFlag.Create('nodekeyhex', 'P2P node key as hex', '');
	DiscoveryFlag := TStringFlag.Create('discovery', 'enable p2p discovery or not', '');
	IPCEnabledFlag := TBoolFlag.Create('ipc', 'Enable the IPC-RPC server', False);
	IPCPathFlag := TDirectoryFlag.Create('ipcpath', 'Filename for IPC socket/pipe within the datadir (explicit paths escape it)', '');
	RPCEnabledFlag := TBoolFlag.Create('rpc', 'Enable the HTTP-RPC server', False);
	RPCListenAddrFlag := TStringFlag.Create('rpcaddr', 'HTTP-RPC server listening interface', '');
	RPCPortFlag := TIntFlag.Create('rpcport', 'HTTP-RPC server listening port', 0);
	WSEnabledFlag := TBoolFlag.Create('ws', 'Enable the WS-RPC server', False);
	WSListenAddrFlag := TStringFlag.Create('wsaddr', 'WS-RPC server listening interface', '');
	WSPortFlag := TIntFlag.Create('wsport', 'WS-RPC server listening port', 0);
	JSPathFlag := TStringFlag.Create('jspath', 'JavaScript root path for `loadScript`', '.');
	ExecFlag := TStringFlag.Create('exec', 'Execute JavaScript statement', '');
	PreloadJSFlag := TStringFlag.Create('preload', 'Comma separated list of JavaScript files to preload into the console', '');
	MinerFlag := TBoolFlag.Create('miner', 'Enable the Miner', False);
	CoinBaseFlag := TStringFlag.Create('coinbase', 'Coinbase is an address into which the rewards for the SuperNode produce snapshot-block', '');
	MinerIntervalFlag := TIntFlag.Create('minerinterval', 'Miner Interval(unit: second)', 0);
	LogLvlFlag := TStringFlag.Create('loglevel', 'log level (info,eror,warn,dbug)', '');
	VMTestFlag := TBoolFlag.Create('vmtest', 'Enable the VM test ', False);
	VMTestParamFlag := TBoolFlag.Create('vmtestparam', 'Enable the VM test params ', False);
	QuotaTestParamFlag := TBoolFlag.Create('quotatestparam', 'Enable the VM quota test params ', False);
	VMDebugFlag := TBoolFlag.Create('vmdebug', 'Enable VM debug', False);
	SubscribeFlag := TBoolFlag.Create('subscribe', 'Enable Subscribe', False);
	LedgerDeleteToHeight := TUint64Flag.Create('del', 'Delete to height', 0);
	RecoverTrieFlag := TBoolFlag.Create('trie', 'Recover trie', False);
	ExportSbHeightFlags := TUint64Flag.Create('sbHeight', 'The snapshot block height', 0);
	SingleFlag := TBoolFlag.Create('single', 'Enable the NodeServer single ', False);
	FilePortFlag := TIntFlag.Create('fileport', 'File transfer listening port', 0);
	PProfEnabledFlag := TBoolFlag.Create('pprof', 'Enable chain performance analysis tool, you can visit the address[http://localhost:8080/debug/pprof]', False);
	PProfPortFlag := TUint64Flag.Create('pprofport', 'pporof visit `port`, you can visit the address[http://localhost:`port`/debug/pprof]', 0);
	LoadFromDirFlag := TStringFlag.Create('fromDir', 'from directory', '');

	ConfigFlags := [ConfigFileFlag];
	GeneralFlags := [DataDirFlag, KeyStoreDirFlag];
	P2pFlags := [DevNetFlag, TestNetFlag, MainNetFlag, IdentityFlag, NetworkIdFlag, MaxPeersFlag, MaxPendingPeersFlag, ListenPortFlag, NodeKeyHexFlag, DiscoveryFlag];
	IpcFlags := [IPCEnabledFlag, IPCPathFlag];
	HttpFlags := [RPCEnabledFlag, RPCListenAddrFlag, RPCPortFlag];
	WsFlags := [WSEnabledFlag, WSListenAddrFlag, WSPortFlag];
	ConsoleFlags := [JSPathFlag, ExecFlag, PreloadJSFlag];
	ProducerFlags := [MinerFlag, CoinBaseFlag, MinerIntervalFlag];
	LogFlags := [LogLvlFlag];
	VmFlags := [VMTestFlag, VMTestParamFlag, QuotaTestParamFlag, VMDebugFlag];
	NetFlags := [SingleFlag, FilePortFlag];
	StatFlags := [PProfEnabledFlag, PProfPortFlag];
	LedgerFlags := [LedgerDeleteToHeight, RecoverTrieFlag];
	ExportFlags := [ExportSbHeightFlags];
	LoadLedgerFlags := [LoadFromDirFlag];
end.
