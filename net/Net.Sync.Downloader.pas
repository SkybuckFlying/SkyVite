unit Net.Sync.Downloader;

interface

uses
  Common.Types,
  Interfaces,
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
  Net.Vnode,
  Net.Vnode.Endpoint,
  Net.Vnode.Endpoint.Test,
  Net.Vnode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.Vnode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  System.Classes,
  System.Generics.Collections,
  System.Generics.Defaults,
  System.SyncObjs,
  System.SysUtils,
  System.Threading,
  System.TimeSpan,
  unit_GoLang_Compatibility_version_006;

type
	TReqState = ( reqWaiting, reqPending, reqDone, reqError, reqCancel );

	TExecutor = class(TInterfacedObject, ISyncDownloader)
	private
		mMu : TCriticalSection;
		mTasks : TList<TDownloadTask>;
		mLockObject : TObject; // For System.TMonitor (sync.Cond equivalent)
		mMax, mBatch : Integer;

		mPool : TDownloadConnPool;
		mFactory : ISyncConnInitiator;
		mDialing : TDictionary<string, Pointer>;
		// mDialer : TSysSocketDialer; // Simplified

		mListeners : TList<TTaskListener>;
		mRunning : Boolean;
		mWG : TGoWaitGroup;

		mLog : ILogger;

		procedure LoopImpl;
		procedure RunTask( ParaT : TDownloadTask );
		procedure DoJob( ParaC : TSyncConn; ParaT : TDownloadTask );
		function CreateConn( ParaP : TPeer ) : TSyncConn;
		procedure DoWork( ParaT : TDownloadTask );
		procedure Notify( ParaT : TDownloadTask; ParaErr : Exception );
	public
		constructor Create( ParaMax, ParaBatch : Integer; ParaPeers : TPeerSet; ParaFactory : ISyncConnInitiator );
		destructor Destroy; override;

		procedure Start;
		procedure Stop;
		function Status : TDownloaderStatus;
		function Download( ParaT : TDownloadTask; ParaMust : Boolean ) : Boolean;
		procedure CancelAllTasks;
		procedure CancelTask( ParaT : TDownloadTask );
		procedure AddListener( ParaListener : TTaskListener );
		procedure AddBlackList( ParaId : TNodeID );
	end;

implementation

{ TExecutor }

constructor TExecutor.Create( ParaMax, ParaBatch : Integer; ParaPeers : TPeerSet; ParaFactory : ISyncConnInitiator );
begin
	inherited Create;
	mMax := ParaMax;
	mBatch := ParaBatch;
	mTasks := TList<TDownloadTask>.Create;
	mPool := TDownloadConnPool.Create( ParaPeers );
	mFactory := ParaFactory;
	mDialing := TDictionary<string, Pointer>.Create;
	mListeners := TList<TTaskListener>.Create;
	mMu := TCriticalSection.Create;
	mLockObject := TObject.Create;
	mWG := TGoWaitGroup.Create;
	mLog := TLogger.New( 'module', 'downloader' );
end;

destructor TExecutor.Destroy;
begin
	Stop;
	mWG.Free;
	mLockObject.Free;
	mListeners.Free;
	mDialing.Free;
	mPool.Free;
	mTasks.Free;
	mMu.Free;
	inherited Destroy;
end;

procedure TExecutor.Start;
begin
	mMu.Enter;
	try
		if mRunning then Exit;
		mRunning := True;
		mTasks.Clear;
	finally
		mMu.Leave;
	end;

	mWG.Add( 1 );
	TGo.Run( procedure begin LoopImpl; end );
end;

procedure TExecutor.Stop;
begin
	mMu.Enter;
	try
		if not mRunning then Exit;
		mRunning := False;
	finally
		mMu.Leave;
	end;

	System.TMonitor.PulseAll( mLockObject );
	mWG.Wait;
end;

procedure TExecutor.AddListener( ParaListener : TTaskListener );
begin
	mListeners.Add( ParaListener );
end;

function TExecutor.Status : TDownloaderStatus;
var
	vI : Integer;
begin
	mMu.Enter;
	try
		SetLength( Result.Tasks, mTasks.Count );
		for vI := 0 to mTasks.Count - 1 do Result.Tasks[vI] := mTasks[vI].ToString;
		Result.Connections := mPool.GetConnections;
	finally
		mMu.Leave;
	end;
end;

function TExecutor.Download( ParaT : TDownloadTask; ParaMust : Boolean ) : Boolean;
begin
	if ParaT.From > ParaT.ToVal then
	begin
		mLog.Warn( Format( 'from is larger than to: %s', [ParaT.ToString] ) );
		Exit( True );
	end;

	System.TMonitor.Enter( mLockObject );
	try
		if not ParaMust then
		begin
			while ( mTasks.Count >= mMax ) and mRunning do
			begin
				System.TMonitor.Wait( mLockObject, INFINITE );
			end;
		end;

		if not mRunning then Exit( False );

		mTasks.Add( ParaT );
		// Sort tasks? Simplified.
		System.TMonitor.Pulse( mLockObject );
		Result := True;
	finally
		System.TMonitor.Exit( mLockObject );
	end;
end;

procedure TExecutor.CancelTask( ParaT : TDownloadTask );
var
	vI : Integer;
begin
	mMu.Enter;
	try
		for vI := 0 to mTasks.Count - 1 do
		begin
			if mTasks[vI] = ParaT then
			begin
				mTasks.Delete( vI );
				System.TMonitor.Pulse( mLockObject );
				Break;
			end;
		end;
	finally
		mMu.Leave;
	end;
end;

procedure TExecutor.CancelAllTasks;
begin
	mMu.Enter;
	try
		mTasks.Clear;
	finally
		mMu.Leave;
	end;
	System.TMonitor.PulseAll( mLockObject );
end;

procedure TExecutor.LoopImpl;
var
	vBatch : Integer;
	vPeerCount : Integer;
	vTotal : Integer;
begin
	try
		while True do
		begin
			System.TMonitor.Enter( mLockObject );
			try
				while ( mTasks.Count = 0 ) and mRunning do
				begin
					System.TMonitor.Wait( mLockObject, INFINITE );
				end;
				if not mRunning then Break;
				
				vTotal := mTasks.Count;
				vBatch := mBatch;
				vPeerCount := mPool.Peers.Count;
				if vBatch > vPeerCount then vBatch := vPeerCount;
				
				// RunTasks implementation...
			finally
				System.TMonitor.Exit( mLockObject );
			end;
			
			TThread.Sleep( 100 );
		end;
	finally
		mWG.Done;
	end;
end;

procedure TExecutor.RunTask( ParaT : TDownloadTask );
begin
	// ParaT.Pending;
	TGo.Run( procedure begin DoWork( ParaT ); end );
end;

procedure TExecutor.DoWork( ParaT : TDownloadTask );
var
	vP : TPeer;
	vC : TSyncConn;
	vErr : Exception;
begin
	vErr := nil;
	if mPool.ChooseSource( ParaT, vP, vC ) then
	begin
		// logic
	end;
	
	// Notify and error handling
end;

procedure TExecutor.DoJob( ParaC : TSyncConn; ParaT : TDownloadTask );
begin
	// download logic
end;

function TExecutor.CreateConn( ParaP : TPeer ) : TSyncConn;
begin
	// create conn and handshake
	Result := nil;
end;

procedure TExecutor.Notify( ParaT : TDownloadTask; ParaErr : Exception );
var
	vL : TTaskListener;
begin
	for vL in mListeners do vL( ParaT, ParaErr );
end;

procedure TExecutor.AddBlackList( ParaId : TNodeID );
begin
	mPool.BlockPeer( ParaId, TTimeSpan.FromSeconds( 60 ) );
end;

end.
