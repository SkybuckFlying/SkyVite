unit Net.Sync.State.Test;

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
  Net.Syncer,
  Net.Syncer.Test,
  System.SysUtils;

procedure ExampleSyncState_MarshalText;
procedure TestSyncState_MarshalText;

implementation

procedure ExampleSyncState_MarshalText;
var
	vS : TSyncState;
begin
	vS := SyncInit;
	Writeln( SyncStateToString( vS ) );
	// Output: Sync Not Start
end;

procedure TestSyncState_MarshalText;
var
	vS : TSyncState;
	vStr : string;
begin
	vS := Syncing;
	vStr := SyncStateToString( vS );
	
	// mock unmarshal
	if vStr <> 'Synchronising' then raise Exception.Create( 'wrong state string' );
end;

end.
