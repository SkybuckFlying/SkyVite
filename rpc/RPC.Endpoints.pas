unit Rpc.Endpoints;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Net.Sockets,
  System.Net.URL,
  Rpc.Server,
  Rpc.Http,
  Rpc.Websocket,
  Rpc.Ipc,
  Common.Log;

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
