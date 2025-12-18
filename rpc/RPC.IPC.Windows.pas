unit RPC_IPC_Windows;

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
  RPC.Client,
  RPC.Client.Example.Test,
  RPC.Client.Test,
  RPC.Doc,
  RPC.Endpoints,
  RPC.Errors,
  RPC.Health,
  RPC.Http,
  RPC.Http.Test,
  RPC.Inproc,
  RPC.IPC,
  RPC.IPC.Unix,
  RPC.Json,
  RPC.Json.Test,
  RPC.Server,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  RPC.Websocket,
  SysUtils Classes;

type
  THandleWrapper = class(TObject)
  private
    FHandle: THandle;
  public
    constructor Create(AHandle: THandle);
    property Handle: THandle read FHandle;
  end;

function ipcListen(const endpoint: string): THandleWrapper;
function newIPCConnection(const endpoint: string): THandleWrapper;

implementation

uses
  Windows, Synchapi;

const
  defaultPipeDialTimeout = 2000; // 2 seconds

{ THandleWrapper }

constructor THandleWrapper.Create(AHandle: THandle);
begin
  inherited Create;
  FHandle := AHandle;
end;

{ Functions }

function ipcListen(const endpoint: string): THandleWrapper;
var
  Pipe: THandle;
begin
  Pipe := CreateNamedPipe(
    PChar(endpoint),
    PIPE_ACCESS_DUPLEX,
    PIPE_TYPE_MESSAGE or PIPE_READMODE_MESSAGE or PIPE_WAIT,
    PIPE_UNLIMITED_INSTANCES,
    4096,
    4096,
    0,
    nil
  );
  if Pipe = INVALID_HANDLE_VALUE then
    RaiseLastOSError;

  Result := THandleWrapper.Create(Pipe);
end;

function newIPCConnection(const endpoint: string): THandleWrapper;
var
  Pipe: THandle;
  Timeout: DWord;
begin
  Timeout := defaultPipeDialTimeout;

  Pipe := CreateFile(
    PChar(endpoint),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    0,
    0
  );

  if Pipe = INVALID_HANDLE_VALUE then
  begin
    if GetLastError() <> ERROR_PIPE_BUSY then
      RaiseLastOSError;

    if not WaitNamedPipe(PChar(endpoint), Timeout) then
      RaiseLastOSError;

    Pipe := CreateFile(
      PChar(endpoint),
      GENERIC_READ or GENERIC_WRITE,
      0,
      nil,
      OPEN_EXISTING,
      0,
      0
    );
  end;

  if Pipe = INVALID_HANDLE_VALUE then
    RaiseLastOSError;

  Result := THandleWrapper.Create(Pipe);
end;

end.
