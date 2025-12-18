unit Rpc.Inproc;

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
  Rpc.Client,
  RPC.Client.Example.Test,
  RPC.Client.Test,
  Rpc.Connection,
  RPC.Doc,
  RPC.Endpoints,
  RPC.Errors,
  RPC.Health,
  RPC.Http,
  RPC.Http.Test,
  RPC.IPC,
  RPC.IPC.Unix,
  RPC.IPC.Windows,
  Rpc.Json,
  RPC.Json.Test,
  Rpc.Server,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  RPC.Websocket,
  System.Classes,
  System.Net.Sockets,
  System.SysUtils;

function DialInProc(const ParaHandler: TRpcServer): TRpcClient;

implementation

uses
  System.Threading,
  System.IOUtils;

type
  TPipeConnection = class(TInterfacedObject, IConnection)
  private
    mInput, mOutput: TStream;
  public
    constructor Create(const ParaInput, ParaOutput: TStream);
    function Read(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
    function Write(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
    procedure Close;
    function GetStream: TStream;
    function GetRemoteAddress: string;
  end;

{ TPipeConnection }

constructor TPipeConnection.Create(const ParaInput, ParaOutput: TStream);
begin
  mInput := ParaInput;
  mOutput := ParaOutput;
end;

function TPipeConnection.Read(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
begin
  Result := mInput.Read(ParaBuffer, ParaOffset, ParaCount);
end;

function TPipeConnection.Write(const ParaBuffer: TBytes; const ParaOffset, ParaCount: Integer): Integer;
begin
  Result := mOutput.Write(ParaBuffer, ParaOffset, ParaCount);
end;

procedure TPipeConnection.Close;
begin
  // Do nothing
end;

function TPipeConnection.GetStream: TStream;
begin
  Result := mInput;
end;

function TPipeConnection.GetRemoteAddress: string;
begin
  Result := 'inproc';
end;

function DialInProc(const ParaHandler: TRpcServer): TRpcClient;
var
  vPipe1, vPipe2: TStream;
  vConn1, vConn2: IConnection;
begin
  // This is a simplified pipe implementation for in-process communication.
  // A more robust implementation would use anonymous pipes or a similar mechanism.
  vPipe1 := TMemoryStream.Create;
  vPipe2 := TMemoryStream.Create;
  vConn1 := TPipeConnection.Create(vPipe1, vPipe2);
  vConn2 := TPipeConnection.Create(vPipe2, vPipe1);
  TTask.Run(
    procedure
    var
      vCodec: TJsonCodec;
    begin
      vCodec := TJsonCodec.Create(vConn1);
      try
        ParaHandler.ServeCodec(vCodec, [omMethodInvocation, omSubscriptions]);
      finally
        vCodec.Free;
      end;
    end);
  Result := TRpcClient.Create(
    function: IConnection
    begin
      Result := vConn2;
    end);
end;

end.
