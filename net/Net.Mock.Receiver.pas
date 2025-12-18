unit Net.Mock.Receiver;

interface

uses
  Common.Types,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Snapshot.Block,
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
  Net.Sync.State.Test,
  Net.Syncer,
  Net.Syncer.Test,
  System.SysUtils;

type
	TMockReceiver = class(TInterfacedObject, IReceiver)
	public
		function ReceiveAccountBlock( ParaBlock : TAccountBlock; ParaSource : TBlockSource ) : Boolean;
		function ReceiveSnapshotBlock( ParaBlock : TSnapshotBlock; ParaSource : TBlockSource ) : Boolean;
	end;

implementation

{ TMockReceiver }

function TMockReceiver.ReceiveAccountBlock( ParaBlock : TAccountBlock; ParaSource : TBlockSource ) : Boolean;
begin
	Result := True;
end;

function TMockReceiver.ReceiveSnapshotBlock( ParaBlock : TSnapshotBlock; ParaSource : TBlockSource ) : Boolean;
begin
	Result := True;
end;

end.
