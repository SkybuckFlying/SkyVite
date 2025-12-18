unit Rpc.Endpoints;

interface

uses
  Common.Log,
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
  RPC.Errors,
  RPC.Health,
  Rpc.Http,
  RPC.Http.Test,
  RPC.Inproc,
  Rpc.Ipc,
  RPC.IPC.Unix,
  RPC.IPC.Windows,
  RPC.Json,
  RPC.Json.Test,
  Rpc.Server,
  RPC.Server.Test,
  RPC.Subscription,
  RPC.Subscription.Test,
  RPC.Types,
  RPC.Utils,
  RPC.Utils.Test,
  Rpc.Websocket,
  System.Classes,
  System.Net.Sockets,
  System.Net.URL,
  System.SysUtils;

type
  TRpcApi = record
    Namespace: string;
    Service: TObject;
    Public: Boolean;
  end;

  THttpTimeouts = record
    ReadTimeout: Cardinal;
    WriteTimeout: Cardinal;
    IdleTimeout: Cardinal;
  end;

procedure StartHttpEndpoint(const ParaEndpoint, ParaPrivateEndpoint: string;
  const ParaApis: TArray<TRpcApi>; const ParaModules: TArray<string>;
  const ParaCors, ParaVhosts: TArray<string>; const ParaTimeouts: THttpTimeouts;
  const ParaExposeAll: Boolean; out ParaListener, ParaPrivateListener: TSocket;
  out ParaHandler, ParaPrivateHandler: TRpcServer);

procedure StartWsEndpoint(const ParaEndpoint: string; const ParaApis: TArray<TRpcApi>;
  const ParaModules: TArray<string>; const ParaWsOrigins: TArray<string>;
  const ParaExposeAll: Boolean; out ParaListener: TSocket; out ParaHandler: TRpcServer);

procedure StartIpcEndpoint(const ParaIpcEndpoint: string;
  const ParaApis: TArray<TRpcApi>; out ParaListener: TSocket; out ParaHandler: TRpcServer);

procedure StartWsCliEndpoint(const ParaU: TURI; const ParaApis: TArray<TRpcApi>;
  const ParaModules: TArray<string>;
  const ParaExposeAll: Boolean; out ParaWsCli: TWebSocketCli; out ParaServer: TRpcServer);

implementation

uses
  System.Threading,
  System.Generics.Collections;

procedure StartHttpEndpoint(const ParaEndpoint, ParaPrivateEndpoint: string;
  const ParaApis: TArray<TRpcApi>; const ParaModules: TArray<string>;
  const ParaCors, ParaVhosts: TArray<string>; const ParaTimeouts: THttpTimeouts;
  const ParaExposeAll: Boolean; out ParaListener, ParaPrivateListener: TSocket;
  out ParaHandler, ParaPrivateHandler: TRpcServer);
var
  vWhitelist: TDictionary<string, Boolean>;
  vModule: string;
  vApi: TRpcApi;
  vPrivateBind: Boolean;
begin
  vWhitelist := TDictionary<string, Boolean>.Create;
  try
    for vModule in ParaModules do
    begin
      vWhitelist.Add(vModule, True);
    end;
    ParaHandler := TRpcServer.Create;
    ParaPrivateHandler := TRpcServer.Create;
    vPrivateBind := False;
    for vApi in ParaApis do
    begin
      if ParaExposeAll or vWhitelist.ContainsKey(vApi.Namespace) or
        (vWhitelist.Count = 0 and vApi.Public) then
      begin
        ParaHandler.RegisterName(vApi.Namespace, vApi.Service);
        TLog.Debug('HTTP registered', ['namespace', vApi.Namespace]);
      end
      else if not vApi.Public then
      begin
        ParaPrivateHandler.RegisterName(vApi.Namespace, vApi.Service);
        vPrivateBind := True;
        TLog.Debug('Private HTTP API registered', ['namespace', vApi.Namespace]);
      end;
    end;
    ParaListener := TSocket.Create(TTcp.Create);
    ParaListener.Bind(ParaEndpoint);
    ParaListener.Listen;
    TTask.Run(
      procedure
      begin
        THttpServer.Create(ParaCors, ParaVhosts, ParaTimeouts, ParaHandler).Serve(ParaListener);
      end);
    if vPrivateBind and (ParaPrivateEndpoint <> '') then
    begin
      ParaPrivateListener := TSocket.Create(TTcp.Create);
      ParaPrivateListener.Bind(ParaPrivateEndpoint);
      ParaPrivateListener.Listen;
      TTask.Run(
        procedure
        begin
          THttpServer.Create(ParaCors, ParaVhosts, ParaTimeouts, ParaPrivateHandler).Serve(ParaPrivateListener);
        end);
    end;
  finally
    vWhitelist.Free;
  end;
end;

procedure StartWsEndpoint(const ParaEndpoint: string; const ParaApis: TArray<TRpcApi>;
  const ParaModules: TArray<string>; const ParaWsOrigins: TArray<string>;
  const ParaExposeAll: Boolean; out ParaListener: TSocket; out ParaHandler: TRpcServer);
var
  vWhitelist: TDictionary<string, Boolean>;
  vModule: string;
  vApi: TRpcApi;
begin
  vWhitelist := TDictionary<string, Boolean>.Create;
  try
    for vModule in ParaModules do
    begin
      vWhitelist.Add(vModule, True);
    end;
    ParaHandler := TRpcServer.Create;
    for vApi in ParaApis do
    begin
      if ParaExposeAll or vWhitelist.ContainsKey(vApi.Namespace) or
        (vWhitelist.Count = 0 and vApi.Public) then
      begin
        ParaHandler.RegisterName(vApi.Namespace, vApi.Service);
        TLog.Debug('WebSocket registered', ['service', vApi.Service, 'namespace', vApi.Namespace]);
      end;
    end;
    ParaListener := TSocket.Create(TTcp.Create);
    ParaListener.Bind(ParaEndpoint);
    ParaListener.Listen;
    TTask.Run(
      procedure
      begin
        TWsServer.Create(ParaWsOrigins, ParaHandler).Serve(ParaListener);
      end);
  finally
    vWhitelist.Free;
  end;
end;

procedure StartIpcEndpoint(const ParaIpcEndpoint: string;
  const ParaApis: TArray<TRpcApi>; out ParaListener: TSocket; out ParaHandler: TRpcServer);
var
  vApi: TRpcApi;
begin
  ParaHandler := TRpcServer.Create;
  for vApi in ParaApis do
  begin
    ParaHandler.RegisterName(vApi.Namespace, vApi.Service);
    TLog.Debug('IPC registered', ['namespace', vApi.Namespace]);
  end;
  ParaListener := TIpcListener.Create(ParaIpcEndpoint);
  TTask.Run(
    procedure
    begin
      ParaHandler.ServeListener(ParaListener);
    end);
end;

procedure StartWsCliEndpoint(const ParaU: TURI; const ParaApis: TArray<TRpcApi>;
  const ParaModules: TArray<string>;
  const ParaExposeAll: Boolean; out ParaWsCli: TWebSocketCli; out ParaServer: TRpcServer);
var
  vWhitelist: TDictionary<string, Boolean>;
  vModule: string;
  vApi: TRpcApi;
begin
  vWhitelist := TDictionary<string, Boolean>.Create;
  try
    for vModule in ParaModules do
    begin
      vWhitelist.Add(vModule, True);
    end;
    ParaServer := TRpcServer.Create;
    for vApi in ParaApis do
    begin
      if ParaExposeAll or vWhitelist.ContainsKey(vApi.Namespace) or
        (vWhitelist.Count = 0 and vApi.Public) then
      begin
        ParaServer.RegisterName(vApi.Namespace, vApi.Service);
        TLog.Debug('WebSocket registered', ['service', vApi.Service, 'namespace', vApi.Namespace]);
      end;
    end;
    ParaWsCli := TWebSocketCli.Create(ParaU, ParaServer);
    TTask.Run(
      procedure
      begin
        ParaWsCli.Handle;
      end);
  finally
    vWhitelist.Free;
  end;
end;

end.
