unit Rpc.Ipc;

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
  RPC.IPC.Unix,
  RPC.IPC.Windows,
  RPC.Json,
  RPC.Json.Test,
  Rpc.Listener,
  RPC.Server,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  RPC.Websocket,
  System.SysUtils,
  Winapi.Windows;

type
  TIpcListener = class(TInterfacedObject, IListener)
  private
    mPipe: THandle;
    mEndpoint: string;
  public
    constructor Create(const ParaEndpoint: string);
    destructor Destroy; override;
    function Accept: IConnection;
    procedure Close;
    function Addr: string;
  end;

  TIpcConnection = class(TInterfacedObject, IConnection)
  private
    mPipe: THandle;
  public
    constructor Create(const ParaPipe: THandle);
    destructor Destroy; override;
    function Read(ParaBuffer: TBytes; ParaOffset, ParaCount: Integer): Integer;
    function Write(const ParaBuffer: TBytes; ParaOffset, ParaCount: Integer): Integer;
    procedure Close;
    function RemoteAddr: string;
  end;

implementation

uses
  System.IOUtils;

{ TIpcListener }

constructor TIpcListener.Create(const ParaEndpoint: string);
begin
  inherited Create;
  mEndpoint := ParaEndpoint;
  mPipe := CreateNamedPipe(
    PChar(mEndpoint),
    PIPE_ACCESS_DUPLEX,
    PIPE_TYPE_BYTE or PIPE_READMODE_BYTE or PIPE_WAIT,
    PIPE_UNLIMITED_INSTANCES,
    4096,
    4096,
    0,
    nil
  );
  if mPipe = INVALID_HANDLE_VALUE then
    RaiseLastOSError;
end;

destructor TIpcListener.Destroy;
begin
  Close;
  inherited;
end;

function TIpcListener.Accept: IConnection;
begin
  if ConnectNamedPipe(mPipe, nil) or (GetLastError = ERROR_PIPE_CONNECTED) then
    Result := TIpcConnection.Create(mPipe)
  else
    RaiseLastOSError;
end;

procedure TIpcListener.Close;
begin
  if mPipe <> INVALID_HANDLE_VALUE then
  begin
    DisconnectNamedPipe(mPipe);
    CloseHandle(mPipe);
    mPipe := INVALID_HANDLE_VALUE;
  end;
end;

function TIpcListener.Addr: string;
begin
  Result := mEndpoint;
end;

{ TIpcConnection }

constructor TIpcConnection.Create(const ParaPipe: THandle);
begin
  inherited Create;
  mPipe := ParaPipe;
end;

destructor TIpcConnection.Destroy;
begin
  Close;
  inherited;
end;

function TIpcConnection.Read(ParaBuffer: TBytes; ParaOffset, ParaCount: Integer): Integer;
var
  vBytesRead: DWord;
begin
  if not ReadFile(mPipe, ParaBuffer[ParaOffset], ParaCount, vBytesRead, nil) then
    RaiseLastOSError;
  Result := vBytesRead;
end;

function TIpcConnection.Write(const ParaBuffer: TBytes; ParaOffset, ParaCount: Integer): Integer;
var
  vBytesWritten: DWord;
begin
  if not WriteFile(mPipe, ParaBuffer[ParaOffset], ParaCount, vBytesWritten, nil) then
    RaiseLastOSError;
  Result := vBytesWritten;
end;

procedure TIpcConnection.Close;
begin
  if mPipe <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(mPipe);
    mPipe := INVALID_HANDLE_VALUE;
  end;
end;

function TIpcConnection.RemoteAddr: string;
begin
  Result := '';
end;

end.
