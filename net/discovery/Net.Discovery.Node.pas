unit Net.Discovery.Node;

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
  Net.NetTool,
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
  Net.VNode,
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
  System.DateUtils,
  System.Net.Sockets,
  System.SysUtils,
  System.Threading;

type
  TNode = class(TVNode)
  private
    mAddr: TSocketAddress;
    mParseAt: Int64; // last time addr parsed
    mFinding: Integer;
  public
    checkAt: Int64;
    addAt: Int64;
    activeAt: Int64;
    findAt: Int64;

    constructor Create;
    destructor Destroy; override;

    function udpAddr: TSocketAddress;
    procedure update(ParaN2: TNode);
    function needCheck: Boolean;
    function couldFind: Boolean;
    procedure findDone;
  end;

function extractEndPoint(ParaAddr: TSocketAddress; ParaFrom: TVNodeEndPoint): TPair<TVNodeEndPoint, TSocketAddress>;
function nodeFromEndPoint(ParaE: TVNodeEndPoint): TNode;
function udpAddrToEndPoint(ParaAddr: TSocketAddress): TVNodeEndPoint;
function nodeFromPing(ParaRes: TPacket): TNode;
function nodeFromPong(ParaRes: TPacket): TNode;

implementation

{ TNode }

constructor TNode.Create;
begin
  inherited Create;
  mAddr := TSocketAddress.Create;
end;

destructor TNode.Destroy;
begin
  mAddr.Free;
  inherited Destroy;
end;

function TNode.udpAddr: TSocketAddress;
var
  vNow: Int64;
  vResolvedAddr: TSocketAddress;
begin
  vNow := DateTimeToUnix(Now);

  // 15min
  if ((vNow - mParseAt) > 900) or (mAddr.IP.IsEmpty) then
  begin
    try
      vResolvedAddr := TSocketAddress.Create(Address);
      mAddr.Assign(vResolvedAddr);
      mParseAt := vNow;
    except
      on E: Exception do
      begin
        // Handle or log the exception
        Result := nil;
        Exit;
      end;
    end;
  end;

  Result := mAddr;
end;

procedure TNode.update(ParaN2: TNode);
begin
  Self.ID := ParaN2.ID;
  Self.Ext := ParaN2.Ext;
  Self.Net := ParaN2.Net;
  Self.EndPoint := ParaN2.EndPoint;
end;

function TNode.needCheck: Boolean;
var
  vNow: Int64;
begin
  // 10 minutes
  vNow := DateTimeToUnix(Now);
  Result := (vNow - checkAt) > (60 * 10);
end;

function TNode.couldFind: Boolean;
var
  vNow: Int64;
begin
  vNow := DateTimeToUnix(Now);
  // 1 minute
  if (vNow - findAt) < 60 then
  begin
    Result := False;
    Exit;
  end;

  if TInterlocked.CompareExchange(mFinding, 1, 0) <> 0 then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
end;

procedure TNode.findDone;
begin
  TInterlocked.Exchange(mFinding, 0);
  findAt := DateTimeToUnix(Now);
end;

function extractEndPoint(ParaAddr: TSocketAddress; ParaFrom: TVNodeEndPoint): TPair<TVNodeEndPoint, TSocketAddress>;
var
  vErr: Exception;
  vDone: Boolean;
  vAddr2: TSocketAddress;
  vE: TVNodeEndPoint;
begin
  vDone := False;
  if Assigned(ParaFrom) then
  begin
    try
      vAddr2 := TSocketAddress.Create(ParaFrom.ToString);
      if ParaFrom.Typ.IsA(THostDomain) or (TNetTool.CheckRelayIP(ParaAddr.IP, ParaFrom.Host) = nil) then
      begin
        vDone := True;
        vE := ParaFrom;
      end;
    except
      on E: Exception do
        vErr := E;
    end;
  end;

  if not vDone then
  begin
    vE := udpAddrToEndPoint(ParaAddr);
    vAddr2 := ParaAddr;
  end;

  Result := TPair<TVNodeEndPoint, TSocketAddress>.Create(vE, vAddr2);
end;

function nodeFromEndPoint(ParaE: TVNodeEndPoint): TNode;
var
  vUdp: TSocketAddress;
begin
  try
    vUdp := TSocketAddress.Create(ParaE.ToString);
    Result := TNode.Create;
    Result.EndPoint := ParaE;
    Result.mAddr.Assign(vUdp);
    Result.mParseAt := DateTimeToUnix(Now);
  except
    on E: Exception do
    begin
      Result := nil;
    end;
  end;
end;

function udpAddrToEndPoint(ParaAddr: TSocketAddress): TVNodeEndPoint;
begin
  Result := TVNodeEndPoint.Create;
  if ParaAddr.IP.IsIPv4 then
  begin
    Result.Host := ParaAddr.IP.GetAddressBytes;
    Result.Typ := THostIPv4.Create;
  end
  else
  begin
    Result.Host := ParaAddr.IP.GetAddressBytes;
    Result.Typ := THostIPv6.Create;
  end;
  Result.Port := ParaAddr.Port;
end;

function nodeFromPing(ParaRes: TPacket): TNode;
var
  vP: TPingPacketBody;
  vPair: TPair<TVNodeEndPoint, TSocketAddress>;
begin
  vP := ParaRes.body as TPingPacketBody;
  vPair := extractEndPoint(ParaRes.from, vP.from);

  Result := TNode.Create;
  Result.ID := ParaRes.id;
  Result.EndPoint := vPair.Key;
  Result.Net := vP.net;
  Result.Ext := vP.ext;
  Result.mAddr.Assign(vPair.Value);
  Result.mParseAt := DateTimeToUnix(Now);
end;

function nodeFromPong(ParaRes: TPacket): TNode;
var
  vP: TPongPacketBody;
  vPair: TPair<TVNodeEndPoint, TSocketAddress>;
begin
  vP := ParaRes.body as TPongPacketBody;
  vPair := extractEndPoint(ParaRes.from, vP.from);

  Result := TNode.Create;
  Result.ID := ParaRes.id;
  Result.EndPoint := vPair.Key;
  Result.Net := vP.net;
  Result.Ext := vP.ext;
  Result.mAddr.Assign(vPair.Value);
  Result.mParseAt := DateTimeToUnix(Now);
end;

end.
