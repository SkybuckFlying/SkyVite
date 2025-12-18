unit Net.VNode.Mock;

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
  Net.VNode.EndPoint,
  Net.Vnode.Endpoint.Test,
  Net.VNode.Host,
  Net.Vnode.Host.Test,
  Net.Vnode.Mock,
  Net.Vnode.Mode,
  Net.VNode.Node,
  Net.Vnode.Node.PB,
  Net.Vnode.Node.Test,
  System.SysUtils;

function MockIP: TBytes;
function MockPort: Integer;
function MockRest: TBytes;
function MockNet: Integer;
function MockNode(ParaDomain, ParaExt: Boolean): TNode;

implementation

uses
  System.Math;

function MockIP: TBytes;
var
  vIsIPv4: Boolean;
  vLen: Integer;
begin
  vIsIPv4 := Random > 0.5;
  if vIsIPv4 then
    vLen := 4
  else
    vLen := 16;
  SetLength(Result, vLen);
  for var i := 0 to vLen - 1 do
    Result[i] := Byte(Random(256));
end;

function MockPort: Integer;
begin
  Result := Random(65536);
end;

function MockRest: TBytes;
var
  vLen: Integer;
begin
  vLen := Random(1001);
  SetLength(Result, vLen);
  for var i := 0 to vLen - 1 do
    Result[i] := Byte(Random(256));
end;

function MockNet: Integer;
begin
  Result := Random(1001);
end;

function MockNode(ParaDomain, ParaExt: Boolean): TNode;
var
  vNode: TNode;
  vIP: TBytes;
begin
  vNode := TNode.Create;
  vNode.ID := TNodeID.RandomNodeID;
  vNode.EndPoint.Port := MockPort;
  vNode.Net := MockNet;

  if ParaDomain then
  begin
    vNode.EndPoint.Host := TEncoding.UTF8.GetBytes('www.vite.org');
    vNode.EndPoint.Typ := htDomain;
  end
  else
  begin
    vIP := MockIP;
    vNode.EndPoint.Host := vIP;
    if Length(vIP) = 4 then
      vNode.EndPoint.Typ := htIPv4
    else
      vNode.EndPoint.Typ := htIPv6;
  end;

  if ParaExt then
    vNode.Ext := MockRest;

  Result := vNode;
end;

end.
