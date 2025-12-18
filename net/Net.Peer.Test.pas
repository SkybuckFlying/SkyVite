unit Net.Peer.Test;

interface

uses
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
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
  Net.Peer,
  Net.Peer.Error,
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
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Threading;

procedure TestPeerSet_Add;
procedure TestPeerSet_Del;
procedure TestPeerSet_SyncPeer;
procedure TestPeerSet_Pick;
procedure TestPeer_peers;
procedure TestPeer_peers2;

implementation

procedure TestPeerSet_Add;
var
	vM : TPeerSet;
	vP : TPeer;
begin
	vM := TPeerSet.Create;
	try
		vP := TPeer.Create;
		vP.Id := TRandomNodeID;
		
		// add first time
		if not vM.Add( vP ) then
		begin
			raise Exception.Create( 'Add failed' );
		end;

		// add repeatedly
		if vM.Add( vP ) then
		begin
			raise Exception.Create( 'Add repeatedly should fail' );
		end;
	finally
		vM.Free;
	end;
end;

procedure TestPeerSet_Del;
var
	vM : TPeerSet;
	vP, vP2 : TPeer;
begin
	vM := TPeerSet.Create;
	try
		vP := TPeer.Create;
		vP.Id := TRandomNodeID;
		
		if not vM.Add( vP ) then
		begin
			raise Exception.Create( 'Add failed' );
		end;

		vP2 := vM.Remove( vP.Id );
		if vP2 <> vP then
		begin
			raise Exception.Create( 'Remove failed' );
		end;

		if vM.Get( vP.Id ) <> nil then
		begin
			raise Exception.Create( 'Get after remove should fail' );
		end;
	finally
		vM.Free;
	end;
end;

procedure TestPeerSet_SyncPeer;
var
	vM : TPeerSet;
	vP : TPeer;
	vI : Integer;
begin
	vM := TPeerSet.Create;
	try
		if vM.SyncPeer <> nil then Raise Exception.Create('SyncPeer should be nil');
		if vM.BestPeer <> nil then Raise Exception.Create('BestPeer should be nil');

		for vI := 0 to 1 do
		begin
			vP := TPeer.Create;
			vP.Id := TRandomNodeID;
			vP.Height := vI;
			vM.Add( vP );
		end;

		vP := vM.SyncPeer;
		if ( vP = nil ) or ( vP.Height <> 1 ) then
		begin
			raise Exception.Create( 'Wrong sync peer height' );
		end;
	finally
		vM.Free;
	end;
end;

procedure TestPeerSet_Pick;
var
	vM : TPeerSet;
	vP : TPeer;
	vI : Integer;
	vPs : TArray<TPeer>;
	vTarget : Integer;
begin
	vM := TPeerSet.Create;
	try
		for vI := 0 to 9 do
		begin
			vP := TPeer.Create;
			vP.Id := TRandomNodeID;
			vP.Height := vI;
			vM.Add( vP );
		end;

		vTarget := 5;
		vPs := vM.Pick( vTarget );
		if Length( vPs ) <> 5 then
		begin
			raise Exception.Create( 'Wrong peer number' );
		end;
	finally
		vM.Free;
	end;
end;

procedure TestPeer_peers;
var
	vP : TPeer;
begin
	vP := TPeer.Create;
	try
		// Start background task for writing
		TTask.Run( procedure
		begin
			// simulated writing loop
		end );

		// Start background task for reading
		TTask.Run( procedure
		begin
			// simulated reading loop
		end );

		TThread.Sleep( 5000 );
	finally
		vP.Free;
	end;
end;

procedure TestPeer_peers2;
begin
    // ...
end;

end.
