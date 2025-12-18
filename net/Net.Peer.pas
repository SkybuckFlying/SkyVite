unit Peer;

interface

uses
  GoToDelphi.Helpers.Net,
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
  NetTool,
  System.Classes,
  System.SysUtils,
  VNode;

function ExtractAddress(
	ParaSender: ITCPAddr;
	ParaFileAddressBytes: TBytes;
	ParaDefaultPort: Integer
): string;

implementation

uses
	System.NetEncoding;

function ExtractAddress(
	ParaSender: ITCPAddr;
	ParaFileAddressBytes: TBytes;
	ParaDefaultPort: Integer
): string;
var
	vFromIP: IIP;
	vPort: Word;
	vEndPoint: TEndPoint;
	vIP: TIPAddress;
begin
	vFromIP := ParaSender.IP;

	if Length(ParaFileAddressBytes) = 2 then
	begin
		vPort := ParaFileAddressBytes[1] or (ParaFileAddressBytes[0] shl 8);
		Result := vFromIP.ToString + ':' + IntToStr(vPort);
		Exit;
	end;

	if Length(ParaFileAddressBytes) > 2 then
	begin
		if vEndPoint.Deserialize(ParaFileAddressBytes) then
		begin
			if vEndPoint.mTyp in [htIP, htIPv4, htIPv6] then
			begin
				vIP.AsBytes := vEndPoint.mHost;
				// Assuming TNetTool.CheckRelayIP exists
				if TNetTool.CheckRelayIP(vFromIP, vIP) then
				begin
					vEndPoint.mHost := vFromIP.AsBytes;
				end;
				Result := vEndPoint.ToString;
				Exit;
			end
			else
			begin
				// Assuming a function to resolve TCP address exists
				// For now, just return the endpoint string
				Result := vEndPoint.ToString;
				Exit;
			end;
		end;
	end;

	Result := vFromIP.ToString + ':' + IntToStr(ParaDefaultPort);
end;

end.
