unit Node.Node;

interface

uses
  Common.Config.Config,
  Log15.Logger,
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
  Net.Connector.Connector,
  Net.Database.Database,
  Net.Database.Database.Test,
  Net.Discovery.Booter,
  Net.Discovery.Booter.Test,
  Net.Discovery.Bucket.Test,
  Net.Discovery.Discovery,
  Net.Discovery.Discovery.Test,
  Net.Discovery.Finder,
  Net.Discovery.Message,
  Net.Discovery.Message.Test,
  Net.Discovery.Mock.Socket,
  Net.Discovery.Node,
  Net.Discovery.Node.Test,
  Net.Discovery.Pool,
  Net.Discovery.Pool.Test,
  Net.Discovery.Protos.Message.PB,
  Net.Discovery.Simular.Simular,
  Net.Discovery.Socket,
  Net.Discovery.Socket.Test,
  Net.Discovery.Table,
  Net.Discovery.Table.Test,
  Net.Fetcher,
  Net.Fetcher.Test,
  Net.Finder,
  Net.Handshaker,
  Net.Handshaker.Test,
  Net.Interface,
  Net.Message,
  Net.Message.Test,
  Net.Mock.Chain,
  Net.Mock.Codec,
  Net.Mock.Net,
  Net.Mock.Receiver,
  Net.MsgHandler,
  Net.MsgHandler.Test,
  Net.Net,
  Net.Netool.Blacklist,
  Net.Netool.Net,
  Net.Netool.Net.Test,
  Net.Peer,
  Net.Peer.Error,
  Net.Peer.Test,
  Net.Skeleton,
  Net.Skeleton.Test,
  Net.Sync.Cache.Reader,
  Net.Sync.Cache.Reader.Test,
  Net.Sync.Conn,
  Net.Sync.Conn.Test,
  Net.Sync.Downloader,
  Net.Sync.Downloader.Test,
  Net.Sync.Server,
  Net.Sync.Server.Test,
  Net.Sync.State,
  Net.Sync.State.Test,
  Net.Syncer,
  Net.Syncer.Test,
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  Node.Config.Config,
  Node.Errors,
  Node.RPC,
  RPC,
  System.Classes,
  System.IOUtils,
  System.SyncObjs,
  System.SysUtils,
  unit_GoLang_Compatibility_version_006,
  Vite,
  Wallet;

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
