unit Net;

interface

uses
  Common.Config,
  Ledger.Chain,
  Ledger.Consensus,
  Ledger.Pool,
  Ledger.Verifier,
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
  System.SysUtils;

type
  INet = interface(IInterface)
    ['{9D0E1F2A-3B4C-5D6E-7F8A-9B0C1D2E3F4A}']
    procedure Start;
    procedure Stop;
  end;

  TNet = class(TInterfacedObject, INet)
  public
    class function Create(ParaNetConfig: TNetConfig; ParaChain: IChain; ParaVerifier: IVerifier; ParaConsensus: IConsensus; ParaPool: IBlockPool): INet;
    procedure Start;
    procedure Stop;
  end;

implementation

{ TNet }

class function TNet.Create(ParaNetConfig: TNetConfig; ParaChain: IChain; ParaVerifier: IVerifier; ParaConsensus: IConsensus; ParaPool: IBlockPool): INet;
begin
  // not implemented
  Result := nil;
end;

procedure TNet.Start;
begin
  // not implemented
end;

procedure TNet.Stop;
begin
  // not implemented
end;

end.
