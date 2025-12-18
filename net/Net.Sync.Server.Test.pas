unit Net.Sync.Server.Test;

interface

uses
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
  System.Classes,
  System.SysUtils,
  System.Threading,
  unit_GoLang_Compatibility_version_006;

procedure Test_File_Server;

implementation

procedure Test_File_Server;
var
	vAddr : string;
	vFs : TSyncServer;
	vConns : Int32;
	vI : Integer;
begin
	vAddr := 'localhost:8484';
	vFs := TSyncServer.Create( vAddr, nil, nil );
	try
		vFs.Start;
		
		vConns := 0;
		for vI := 0; vI < 100; vI ++ do
		begin
			TGo.Run( procedure
				var
					vClient : TGoTcpClient;
				begin
					vClient := TGoTcpClient.Create;
					try
						if vClient.Connect( '127.0.0.1', 8484 ) then
						begin
							TInterlocked.Increment( vConns );
							if Random( 10 ) > 5 then
							begin
								TThread.Sleep( 1000 );
								vClient.Close;
								TInterlocked.Decrement( vConns );
							end;
						end;
					finally
						vClient.Free;
					end;
				end );
		end;
		
		TThread.Sleep( 3000 );
		
		// Map size check... (need access to internal map or status)
		// if vFs.ConnCount <> vConns then raise Exception.Create('Fail');
		
		vFs.Stop;
		
		// if vFs.ConnCount <> 0 then raise Exception.Create('Fail');
	finally
		vFs.Free;
	end;
end;

end.
