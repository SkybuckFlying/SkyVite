unit Net.Sync.Server;

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
  System.SyncObjs,
  System.SysUtils,
  System.Threading,
  unit_GoLang_Compatibility_version_006;

type
	TSyncServer = class
	private
		// mListener : ISocketListener;
		mMu : TCriticalSection;
		mSConnMap : TDictionary<TNodeID, TSyncConn>;
		mChain : ILedgerReader; // Or a specific interface for reading blocks
		mFactory : ISyncConnReceiver;
		mRunning : Integer; // atomic
		mWG : TGoWaitGroup;
		mLog : ILogger;

		procedure ListenLoopImpl;
		procedure HandleConn( ParaConn : Pointer ); // Simplified socket handle
		procedure AddConn( ParaC : TSyncConn );
		procedure DeleteConn( ParaC : TSyncConn );
	public
		constructor Create( ParaAddr : string; ParaChain : ILedgerReader; ParaFactory : ISyncConnReceiver );
		destructor Destroy; override;

		function Status : TDownloaderStatus;
		procedure Start;
		procedure Stop;
	end;

implementation

{ TSyncServer }

constructor TSyncServer.Create( ParaAddr : string; ParaChain : ILedgerReader; ParaFactory : ISyncConnReceiver );
begin
	inherited Create;
	mChain := ParaChain;
	mFactory := ParaFactory;
	mSConnMap := TDictionary<TNodeID, TSyncConn>.Create;
	mMu := TCriticalSection.Create;
	mWG := TGoWaitGroup.Create;
	mLog := TLogger.New( 'module', 'server' );
	mRunning := 0;
end;

destructor TSyncServer.Destroy;
begin
	Stop;
	mWG.Free;
	mSConnMap.Free;
	mMu.Free;
	inherited Destroy;
end;

procedure TSyncServer.Start;
begin
	if TInterlocked.CompareExchange( mRunning, 1, 0 ) = 0 then
	begin
		// Start listener...
		mWG.Add( 1 );
		TGo.Run( procedure begin ListenLoopImpl; end );
	end;
end;

procedure TSyncServer.Stop;
begin
	if TInterlocked.CompareExchange( mRunning, 0, 1 ) = 1 then
	begin
		// Close listener...
		mMu.Enter;
		try
			// Close all mapped connections
		finally
			mMu.Leave;
		end;
		mWG.Wait;
	end;
end;

function TSyncServer.Status : TDownloaderStatus;
begin
	// status logic
end;

procedure TSyncServer.ListenLoopImpl;
begin
	try
		while TInterlocked.Read( mRunning ) = 1 do
		begin
			// Accept and handle...
			TThread.Sleep( 1000 );
		end;
	finally
		mWG.Done;
	end;
end;

procedure TSyncServer.HandleConn( ParaConn : Pointer );
begin
	// handle protocol logic
end;

procedure TSyncServer.AddConn( ParaC : TSyncConn );
begin
	mMu.Enter;
	try
		mSConnMap.AddOrSetValue( ParaC.mPeer.Id, ParaC );
	finally
		mMu.Leave;
	end;
end;

procedure TSyncServer.DeleteConn( ParaC : TSyncConn );
begin
	mMu.Enter;
	try
		mSConnMap.Remove( ParaC.mPeer.Id );
	finally
		mMu.Leave;
	end;
end;

end.
