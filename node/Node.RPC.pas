unit Node.Rpc;

interface

uses
  Node.Node,
  Rpc;

procedure StartIPC(const ParaNode: TNode; const ParaAPIs: TArray<TRpcAPI>);
procedure StopIPC(const ParaNode: TNode);
procedure StartHTTP(
  const ParaNode: TNode;
  const ParaHttpEndpoint, ParaPrivateHttpEndpoint: string;
  const ParaAPIs: TArray<TRpcAPI>;
  const ParaModules: TArray<string>;
  const ParaCors: TArray<string>;
  const ParaVHosts: TArray<string>;
  const ParaTimeouts: THTTPTimeouts;
  const ParaExposeAll: Boolean
);
procedure StopHTTP(const ParaNode: TNode);
procedure StartWS(
  const ParaNode: TNode;
  const ParaEndpoint: string;
  const ParaAPIs: TArray<TRpcAPI>;
  const ParaModules: TArray<string>;
  const ParaOrigins: TArray<string>;
  const ParaExposeAll: Boolean
);
procedure StopWS(const ParaNode: TNode);
function Attach(const ParaNode: TNode): TRpcClient;
procedure StartInProcess(const ParaNode: TNode; const ParaAPIs: TArray<TRpcAPI>);
procedure StopInProcess(const ParaNode: TNode);

implementation

uses
  System.SysUtils,
  System.Classes,
  System.Net.Sockets,
  Common.Log;

var
  gLog: ILogger;

procedure StartIPC(const ParaNode: TNode; const ParaAPIs: TArray<TRpcAPI>);
var
  vListener: TSocket;
  vHandler: TRpcServer;
begin
  if ParaNode.GetConfig.IPCEndpoint = '' then
  begin
    Exit;
  end;
  TRpc.StartIPCEndpoint(ParaNode.GetConfig.IPCEndpoint, ParaAPIs, vListener, vHandler);
  ParaNode.mIpcListener := vListener;
  ParaNode.mIpcHandler := vHandler;
  gLog.Info('IPC endpoint opened', ['url', ParaNode.GetConfig.IPCEndpoint]);
end;

procedure StopIPC(const ParaNode: TNode);
begin
  if ParaNode.mIpcListener <> nil then
  begin
    ParaNode.mIpcListener.Close;
    ParaNode.mIpcListener := nil;
    gLog.Info('IPC endpoint closed', ['endpoint', ParaNode.GetConfig.IPCEndpoint]);
  end;
  if ParaNode.mIpcHandler <> nil then
  begin
    ParaNode.mIpcHandler.Stop;
    ParaNode.mIpcHandler := nil;
  end;
end;

procedure StartHTTP(
  const ParaNode: TNode;
  const ParaHttpEndpoint, ParaPrivateHttpEndpoint: string;
  const ParaAPIs: TArray<TRpcAPI>;
  const ParaModules: TArray<string>;
  const ParaCors: TArray<string>;
  const ParaVHosts: TArray<string>;
  const ParaTimeouts: THTTPTimeouts;
  const ParaExposeAll: Boolean
);
var
  vListener, vPrivateListener: TSocket;
  vHandler, vPrivateHandler: TRpcServer;
begin
  if ParaHttpEndpoint = '' then
  begin
    Exit;
  end;
  TRpc.StartHTTPEndpoint(ParaHttpEndpoint, ParaPrivateHttpEndpoint, ParaAPIs, ParaModules, ParaCors, ParaVHosts, ParaTimeouts, ParaExposeAll, vListener, vHandler, vPrivateListener, vPrivateHandler);
  gLog.Info('HTTP endpoint opened', ['url', Format('http://%s', [ParaHttpEndpoint]), 'cors', TString.Join(',', ParaCors), 'vhosts', TString.Join(',', ParaVHosts)]);
  ParaNode.mHttpEndpoint := ParaHttpEndpoint;
  ParaNode.mHttpListener := vListener;
  ParaNode.mHttpHandler := vHandler;
  ParaNode.mPrivateHttpListener := vPrivateListener;
  ParaNode.mPrivateHttpHandler := vPrivateHandler;
end;

procedure StopHTTP(const ParaNode: TNode);
begin
  if ParaNode.mHttpListener <> nil then
  begin
    ParaNode.mHttpListener.Close;
    ParaNode.mHttpListener := nil;
    gLog.Info('HTTP endpoint closed', ['url', Format('http://%s', [ParaNode.mHttpEndpoint])]);
  end;
  if ParaNode.mHttpHandler <> nil then
  begin
    ParaNode.mHttpHandler.Stop;
    ParaNode.mHttpHandler := nil;
  end;
  if ParaNode.mPrivateHttpListener <> nil then
  begin
    ParaNode.mPrivateHttpListener.Close;
    ParaNode.mPrivateHttpListener := nil;
  end;
  if ParaNode.mPrivateHttpHandler <> nil then
  begin
    ParaNode.mPrivateHttpHandler.Stop;
    ParaNode.mPrivateHttpHandler := nil;
  end;
end;

procedure StartWS(
  const ParaNode: TNode;
  const ParaEndpoint: string;
  const ParaAPIs: TArray<TRpcAPI>;
  const ParaModules: TArray<string>;
  const ParaOrigins: TArray<string>;
  const ParaExposeAll: Boolean
);
var
  vListener: TSocket;
  vHandler: TRpcServer;
begin
  if ParaEndpoint = '' then
  begin
    Exit;
  end;
  TRpc.StartWSEndpoint(ParaEndpoint, ParaAPIs, ParaModules, ParaOrigins, ParaExposeAll, vListener, vHandler);
  gLog.Info('WebSocket endpoint opened', ['url', Format('ws://%s', [vListener.LocalAddress])]);
  ParaNode.mWsEndpoint := ParaEndpoint;
  ParaNode.mWsListener := vListener;
  ParaNode.mWsHandler := vHandler;
end;

procedure StopWS(const ParaNode: TNode);
begin
  if ParaNode.mWsListener <> nil then
  begin
    ParaNode.mWsListener.Close;
    ParaNode.mWsListener := nil;
    gLog.Info('WebSocket endpoint closed', ['url', Format('ws://%s', [ParaNode.mWsEndpoint])]);
  end;
  if ParaNode.mWsHandler <> nil then
  begin
    ParaNode.mWsHandler.Stop;
    ParaNode.mWsHandler := nil;
  end;
  if ParaNode.mWsCli <> nil then
  begin
    ParaNode.mWsCli.Close;
  end;
end;

function Attach(const ParaNode: TNode): TRpcClient;
begin
  ParaNode.mLock.BeginRead;
  try
    Result := TRpc.DialInProc(ParaNode.mInProcessHandler);
  finally
    ParaNode.mLock.EndRead;
  end;
end;

procedure StartInProcess(const ParaNode: TNode; const ParaAPIs: TArray<TRpcAPI>);
var
  vHandler: TRpcServer;
  vAPI: TRpcAPI;
begin
  vHandler := TRpcServer.Create;
  for vAPI in ParaAPIs do
  begin
    vHandler.RegisterName(vAPI.Namespace, vAPI.Service);
    gLog.Debug('InProc registered', ['service', vAPI.Service, 'namespace', vAPI.Namespace]);
  end;
  ParaNode.mInProcessHandler := vHandler;
end;

procedure StopInProcess(const ParaNode: TNode);
begin
  if ParaNode.mInProcessHandler <> nil then
  begin
    ParaNode.mInProcessHandler.Stop;
    ParaNode.mInProcessHandler := nil;
  end;
end;

initialization
  gLog := TLog15.New(['module', 'gvite/node']);
end.
