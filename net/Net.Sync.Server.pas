unit Net.Sync.Server;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	System.SyncObjs,
	System.Threading,
	Common.Types,
	Interfaces,
	Net.Interface,
	Net.Sync.Conn,
	Net.Vnode,
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
