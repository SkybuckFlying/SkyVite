unit Net.Discovery.MockSocket;

interface

uses
  GoToDelphi.Helpers.TChannel,
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
  System.Net.UDP,
  System.SysUtils;

type
  TFindNodeResultChannel = TChannel<TArray<TVNodeEndPoint>>;
  TPingCallback = procedure(ParaNode: TNode; ParaError: TObject);

  ISender = interface
    ['{3A8C6E3A-6D4C-4B8A-9F3A-3C6D4E8A9B3A}']
    function findNode(ParaTarget: TNodeID; ParaCount: Integer; ParaNode: TNode): TFindNodeResultChannel;
    procedure ping(ParaNode: TNode; ParaCallback: TPingCallback);
    function pong(ParaEcho: TBytes; ParaNode: TNode): TObject;
    function sendNodes(ParaEps: TArray<TVNodeEndPoint>; ParaAddr: TUDPAddr): TObject;
  end;

  IReceiver = interface
    ['{B3C6D4E8-A9B3-4A8C-6E3A-3A8C6D4E8A9F}']
    function start: TObject;
    function stop: TObject;
  end;

  ISocket = interface(ISender, IReceiver)
    ['{A9F3A3C6-D4E8-A9B3-4A8C-6E3A3A8C6D4E}']
  end;

  TMockSender = class(TInterfacedObject, ISender)
  public
    function findNode(ParaTarget: TNodeID; ParaCount: Integer; ParaNode: TNode): TFindNodeResultChannel;
    procedure ping(ParaNode: TNode; ParaCallback: TPingCallback);
    function pong(ParaEcho: TBytes; ParaNode: TNode): TObject;
    function sendNodes(ParaEps: TArray<TVNodeEndPoint>; ParaAddr: TUDPAddr): TObject;
  end;

  TMockReceiver = class(TInterfacedObject, IReceiver)
  public
    function start: TObject;
    function stop: TObject;
  end;

  TMockSocket = class(TInterfacedObject, ISocket)
  private
    mSender: ISender;
    mReceiver: IReceiver;
  public
    constructor Create;
    function findNode(ParaTarget: TNodeID; ParaCount: Integer; ParaNode: TNode): TFindNodeResultChannel;
    procedure ping(ParaNode: TNode; ParaCallback: TPingCallback);
    function pong(ParaEcho: TBytes; ParaNode: TNode): TObject;
    function sendNodes(ParaEps: TArray<TVNodeEndPoint>; ParaAddr: TUDPAddr): TObject;
    function start: TObject;
    function stop: TObject;
  end;

implementation

{ TMockSender }

function TMockSender.findNode(ParaTarget: TNodeID; ParaCount: Integer; ParaNode: TNode): TFindNodeResultChannel;
begin
  Result := nil;
end;

procedure TMockSender.ping(ParaNode: TNode; ParaCallback: TPingCallback);
begin
end;

function TMockSender.pong(ParaEcho: TBytes; ParaNode: TNode): TObject;
begin
  Result := nil;
end;

function TMockSender.sendNodes(ParaEps: TArray<TVNodeEndPoint>; ParaAddr: TUDPAddr): TObject;
begin
  Result := nil;
end;

{ TMockReceiver }

function TMockReceiver.start: TObject;
begin
  Result := nil;
end;

function TMockReceiver.stop: TObject;
begin
  Result := nil;
end;

{ TMockSocket }

constructor TMockSocket.Create;
begin
  inherited Create;
  mSender := TMockSender.Create;
  mReceiver := TMockReceiver.Create;
end;

function TMockSocket.findNode(ParaTarget: TNodeID; ParaCount: Integer; ParaNode: TNode): TFindNodeResultChannel;
begin
  Result := mSender.findNode(ParaTarget, ParaCount, ParaNode);
end;

procedure TMockSocket.ping(ParaNode: TNode; ParaCallback: TPingCallback);
begin
  mSender.ping(ParaNode, ParaCallback);
end;

function TMockSocket.pong(ParaEcho: TBytes; ParaNode: TNode): TObject;
begin
  Result := mSender.pong(ParaEcho, ParaNode);
end;

function TMockSocket.sendNodes(ParaEps: TArray<TVNodeEndPoint>; ParaAddr: TUDPAddr): TObject;
begin
  Result := mSender.sendNodes(ParaEps, ParaAddr);
end;

function TMockSocket.start: TObject;
begin
  Result := mReceiver.start;
end;

function TMockSocket.stop: TObject;
begin
  Result := mReceiver.stop;
end;

end.
