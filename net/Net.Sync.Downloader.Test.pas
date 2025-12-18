unit Net.Sync.Downloader.Test;

interface

uses
  Interfaces,
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
  System.Threading,
  unit_GoLang_Compatibility_version_006;

procedure TestExecutor_cancel;
procedure TestCancelTasks;
procedure TestRunTasks;
procedure TestAddTasks;
procedure TestMockQueue;

implementation

procedure TestExecutor_cancel;
begin
	// cancellation tests...
end;

procedure TestCancelTasks;
begin
	// task cancellation logic tests...
end;

procedure TestRunTasks;
begin
	// task running logic tests...
end;

procedure TestAddTasks;
begin
	// task addition logic tests...
end;

procedure TestMockQueue;
begin
	// mock queue concurrent tests...
end;

end.
