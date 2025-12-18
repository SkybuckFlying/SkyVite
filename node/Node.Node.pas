unit Node.Node;

interface

uses
	System.SysUtils,
	System.Classes,
	System.SyncObjs,
	System.IOUtils,
	Common.Config.Config,
	Log15.Logger,
	Node.Config.Config,
	Vite,
	Wallet,
	RPC,
	unit_GoLang_Compatibility_version_006;

type
	TNode = class
	private
		mConfig : TNodeConfig;
		mWalletConfig : TWalletConfig;
		mWalletManager : TWalletManager;
		mViteConfig : TViteConfig;
		mViteServer : TVite;

		mLog : ILogger;
		mStopChan : TGoChannel<Boolean>;
		mLock : TLightweightMux; // sync.RWMutex equivalent

		procedure StartWallet;
		procedure StartVite;
		procedure StartRPC;
		procedure StopWallet;
		procedure StopVite;
		procedure StopRPC;
		function OpenDataDir : Boolean;
	public
		constructor Create( ParaConf : TNodeConfig );
		destructor Destroy; override;

		procedure Prepare;
		procedure Start;
		procedure Stop;
		procedure Wait;

		property ViteServer : TVite read mViteServer;
		property WalletManager : TWalletManager read mWalletManager;
	end;

implementation

{ TNode }

constructor TNode.Create( ParaConf : TNodeConfig );
begin
	inherited Create;
	mConfig := ParaConf;
	mWalletConfig := ParaConf.MakeWalletConfig;
	mViteConfig := ParaConf.MakeViteConfig;
	mStopChan := TGoChannel<Boolean>.Create( 1 );
	mLog := TLogger.New( 'module', 'gvite/node' );
end;

destructor TNode.Destroy;
begin
	Stop;
	mStopChan.Free;
	mViteConfig.Free;
	mWalletConfig.Free;
	inherited Destroy;
end;

procedure TNode.Prepare;
begin
	mLock.Lock;
	try
		mLog.Info( 'Check dataDir is OK ?' );
		if not OpenDataDir then raise Exception.Create( 'DataDir error' );
		
		mLog.Info( 'Begin Prepare node...' );
		mWalletManager := TWalletManager.Create( mWalletConfig );
		
		mLog.Info( 'Begin Start Wallet...' );
		StartWallet;
		
		mViteServer := TVite.New( mViteConfig, mWalletManager );
		mViteServer.Init;
	finally
		mLock.Unlock;
	end;
end;

procedure TNode.Start;
begin
	mLock.Lock;
	try
		mLog.Info( 'Begin Start Vite...' );
		StartVite;
		mLog.Info( 'Begin Start RPC...' );
		StartRPC;
	finally
		mLock.Unlock;
	end;
end;

procedure TNode.Stop;
begin
	mLock.Lock;
	try
		mLog.Info( 'Begin Stop Wallet...' );
		StopWallet;
		mLog.Info( 'Begin Stop Vite...' );
		StopVite;
		mLog.Info( 'Begin Stop RPC...' );
		StopRPC;
		
		if not mStopChan.IsClosed then mStopChan.Close;
	finally
		mLock.Unlock;
	end;
end;

procedure TNode.Wait;
begin
	// Wait logic using channels or signals
	mStopChan.Receive;
end;

function TNode.OpenDataDir : Boolean;
begin
	if mConfig.DataDir <> '' then
	begin
		ForceDirectories( mConfig.DataDir );
		mLog.Info( Format( 'Open DataDir: %s', [mConfig.DataDir] ) );
	end;
	Result := True;
end;

procedure TNode.StartWallet;
begin
	mWalletManager.Start;
end;

procedure TNode.StartVite;
begin
	mViteServer.Start;
end;

procedure TNode.StartRPC;
begin
	// RPC setup logic
end;

procedure TNode.StopWallet;
begin
	if mWalletManager <> nil then mWalletManager.Stop;
end;

procedure TNode.StopVite;
begin
	if mViteServer <> nil then mViteServer.Stop;
end;

procedure TNode.StopRPC;
begin
	// RPC stop logic
end;

end.