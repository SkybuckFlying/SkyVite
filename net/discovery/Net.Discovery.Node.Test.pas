unit Net.Discovery.Node.Test;

interface

uses
  DUnitX.TestFramework,
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
  System.Net.Sockets,
  System.SysUtils;

type
  [TestFixture]
  TNodeTest = class(TObject)
  public
    [Test]
    procedure TestExtractEndPoint;
  end;

implementation

uses
  System.Net.IP,
  System.Types;

{ TNodeTest }

procedure TNodeTest.TestExtractEndPoint;
type
  TSampleHandle = reference to function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception;

  TSample = record
    Sender: TSocketAddress;
    FromStr: string;
    Handle: TSampleHandle;
  end;
var
  vSamples: TArray<TSample>;
  vSamp: TSample;
  vFromEP: TVNodeEndPoint;
  vPair: TPair<TVNodeEndPoint, TSocketAddress>;
  vErr: Exception;
begin
  vSamples := [
    (Sender: TSocketAddress.Create('127.0.0.1', 8483); FromStr: 'vite.org';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if ParaE.Typ.IsA(THostIP) then
         Result := Exception.Create('should be domain');
       if ParaE.ToString <> 'vite.org:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;),
    (Sender: TSocketAddress.Create('193.110.91.250', 8483); FromStr: '0.0.0.0:8483';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if not ParaE.Typ.IsA(THostIPv4) then
         Result := Exception.Create('should be ipv4');
       if ParaE.ToString <> '193.110.91.250:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;),
    (Sender: TSocketAddress.Create('193.110.91.250', 8483); FromStr: '127.0.0.1:8483';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if not ParaE.Typ.IsA(THostIPv4) then
         Result := Exception.Create('should be ipv4');
       if ParaE.ToString <> '193.110.91.250:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;),
    (Sender: TSocketAddress.Create('192.168.1.36', 8483); FromStr: '127.0.0.1:8483';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if not ParaE.Typ.IsA(THostIPv4) then
         Result := Exception.Create('should be ipv4');
       if ParaE.ToString <> '192.168.1.36:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;),
    (Sender: TSocketAddress.Create('192.168.1.36', 8483); FromStr: '0.0.0.0:8888';
     Handle: function(ParaE: TVNodeEndPoint; ParaAddr: TSocketAddress): Exception
     begin
       Result := nil;
       if not ParaE.Typ.IsA(THostIPv4) then
         Result := Exception.Create('should be ipv4');
       if ParaE.ToString <> '192.168.1.36:8483' then
         Result := Exception.Create(Format('error endpoint: %s', [ParaE.ToString]));
     end;)
  ];

  for vSamp in vSamples do
  begin
    vFromEP := TVNodeEndPoint.ParseEndPoint(vSamp.FromStr);
    Assert.IsNotNull(vFromEP, Format('Failed to parse endpoint: %s', [vSamp.FromStr]));
    try
      vPair := extractEndPoint(vSamp.Sender, vFromEP);
      vErr := vSamp.Handle(vPair.Key, vPair.Value);
      Assert.IsNull(vErr, vErr.Message);
    finally
      vFromEP.Free;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TNodeTest);
end.
