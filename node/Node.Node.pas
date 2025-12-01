unit Node.Node;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Net.URL,
  Vite,
  Cmd.Utils.Flock,
  Common.Config,
  Log15,
  Node.Config,
  Node.Errors,
  Pow,
  Pow.Remote,
  Rpc,
  RpcApi,
  RpcApi.Api.Filters,
  Wallet,
  System.Net.Sockets,
  GoToDelphi.Helpers.TChannel;

type
  TNode = class
  private
    mConfig: TNodeConfig;
    mWalletConfig: TWalletConfig;
    mWalletManager: TWalletManager;
    mViteConfig: TConfig;
    mViteServer: TVite;
    mRpcAPIs: TArray<TRpcAPI>;
    mInProcessHandler: TRpcServer;
    mIpcEndpoint: string;
    mIpcListener: TSocket;
    mIpcHandler: TRpcServer;
    mHttpEndpoint: string;
    mHttpWhitelist: TArray<string>;
    mHttpListener: TSocket;
    mHttpHandler: TRpcServer;
    mPrivateHttpEndpoint: string;
    mPrivateHttpListener: TSocket;
    mPrivateHttpHandler: TRpcServer;
    mWsEndpoint: string;
    mWsListener: TSocket;
    mWsHandler: TRpcServer;
    mWsCli: TWebSocketCli;
    mStop: IChannel<Integer>;
    mLock: TMultiReadSingleWrite;
    mInstanceDirLock: IReleaser;
    procedure OpenDataDir;
    procedure StartWallet;
    procedure StartVite;
    procedure StartRPC;
    procedure StopWallet;
    procedure StopVite;
    procedure StopRPC;
  public
    constructor Create(const ParaConf: TNodeConfig);
    destructor Destroy; override;
    function Prepare: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
    procedure Wait;
    function GetVite: TVite;
    function GetConfig: TNodeConfig;
    function GetViteConfig: TConfig;
    function GetViteServer: TVite;
    function GetWalletManager: TWalletManager;
    function Attach: TRpcClient;
  end;

function NewNode(const ParaConf: TNodeConfig): TNode;

implementation

uses
  System.IOUtils,
  System.Threading,
  System.Net.HttpClient,
  Vite.Net,
  Vite.Net.Info,
  Common.Log,
  Node.Rpc;

var
  gLog: ILogger;

{ TNode }

constructor TNode.Create(const ParaConf: TNodeConfig);
begin
  mConfig := ParaConf;
  mWalletConfig := ParaConf.MakeWalletConfig;
  mViteConfig := ParaConf.MakeViteConfig;
  mIpcEndpoint := ParaConf.IPCEndpoint;
  mHttpEndpoint := ParaConf.HTTPEndpoint;
  mWsEndpoint := ParaConf.WSEndpoint;
  mPrivateHttpEndpoint := ParaConf.PrivateHTTPEndpoint;
  mStop := TChannel<Integer>.Create;
  mLock.Create;
end;

destructor TNode.Destroy;
begin
  mLock.Free;
  inherited;
end;

function TNode.Prepare: Boolean;
begin
  Result := False;
  mLock.BeginWrite;
  try
    gLog.Info('Check dataDir is OK ? ');
    try
      OpenDataDir;
    except
      on E: Exception do
      begin
        gLog.Error(Format('Error opening data directory: %s', [E.Message]));
        Exit;
      end;
    end;
    gLog.Info('DataDir is OK. ');

    gLog.Info('Begin Prepare node... ');
    if mWalletConfig = nil then
    begin
      raise ErrWalletConfigNil;
    end;

    if mWalletManager <> nil then
    begin
      raise ErrNodeRunning;
    end;
    mWalletManager := TWalletManager.Create(mWalletConfig);

    if mViteServer <> nil then
    begin
      raise ErrNodeRunning;
    end;

    gLog.Info('Begin Start Wallet... ');
    try
      StartWallet;
    except
      on E: Exception do
      begin
        gLog.Error(Format('startWallet error: %s', [E.Message]));
        Exit;
      end;
    end;

    try
      mViteServer := TVite.Create(mViteConfig, mWalletManager);
    except
      on E: Exception do
      begin
        gLog.Error(Format('Vite new error: %s', [E.Message]));
        Exit;
      end;
    end;

    TRemote.InitRawUrl(GetConfig.PowServerUrl);
    TPow.Init(GetConfig.VMTestParamEnabled);

    try
      mViteServer.Init;
    except
      on E: Exception do
      begin
        gLog.Error(Format('ViteServer init error: %s', [E.Message]));
        Exit;
      end;
    end;
    Result := True;
  finally
    mLock.EndWrite;
  end;
end;

function TNode.Start: Boolean;
begin
  Result := False;
  mLock.BeginWrite;
  try
    gLog.Info('Begin Start Vite... ');
    try
      StartVite;
    except
      on E: Exception do
      begin
        gLog.Error(Format('ViteServer start error: %s', [E.Message]));
        Exit;
      end;
    end;

    gLog.Info('Begin Start RPC... ');
    try
      StartRPC;
    except
      on E: Exception do
      begin
        gLog.Error(Format('Node startRPC error: %s', [E.Message]));
        Exit;
      end;
    end;
    // TMonitor.InitNTPChecker(gLog); // ToDo
    Result := True;
  finally
    mLock.EndWrite;
  end;
end;

function TNode.Stop: Boolean;
begin
  WriteLn('Preparing node shutdown...');
  mLock.BeginWrite;
  try
    mStop.Send(0);

    gLog.Info('Begin Stop Wallet... ');
    try
      StopWallet;
    except
      on E: Exception do
      begin
        gLog.Error(Format('Node stopWallet error: %s', [E.Message]));
      end;
    end;

    gLog.Info('Begin Stop Vite... ');
    try
      StopVite;
    except
      on E: Exception do
      begin
        gLog.Error(Format('Node stopVite error: %s', [E.Message]));
      end;
    end;

    gLog.Info('Begin Stop RPD... ');
    try
      StopRPC;
    except
      on E: Exception do
      begin
        gLog.Error(Format('Node stopRPC error: %s', [E.Message]));
      end;
    end;

    gLog.Info('Begin relaeck dataDir lock... ');
    if mInstanceDirLock <> nil then
    begin
      try
        mInstanceDirLock.Release;
        gLog.Info('The file lock has been released...');
      except
        on E: Exception do
        begin
          gLog.Error(Format('Can''t release dataDir lock... err: %s', [E.Message]));
        end;
      end;
      mInstanceDirLock := nil;
    end;
  finally
    mLock.EndWrite;
  end;
  Result := True;
end;

procedure TNode.Wait;
var
  vSignal: Integer;
begin
  // In a real application, you would use a more sophisticated way to handle signals.
  // For this conversion, we will just wait on the stop channel.
  mStop.Receive(vSignal);
  TTask.Run(
    procedure
    begin
      Stop;
    end);
end;

function TNode.GetVite: TVite;
begin
  Result := mViteServer;
end;

function TNode.GetConfig: TNodeConfig;
begin
  Result := mConfig;
end;

function TNode.GetViteConfig: TConfig;
begin
  Result := mViteConfig;
end;

function TNode.GetViteServer: TVite;
begin
  Result := mViteServer;
end;

function TNode.GetWalletManager: TWalletManager;
begin
  Result := mWalletManager;
end;

function TNode.Attach: TRpcClient;
begin
  Result := Node.Rpc.Attach(Self);
end;

procedure TNode.OpenDataDir;
var
  vLockDir: string;
  vRelease: IReleaser;
  vErr: Exception;
begin
  if mConfig.DataDir = '' then
    Exit;

  TDirectory.CreateDirectory(mConfig.DataDir);
  gLog.Info(Format('Open NodeServer.DataDir:%s', [mConfig.DataDir]));

  vLockDir := TPath.Combine(mConfig.DataDir, 'LOCK');
  gLog.Info(Format('Try to Lock NodeServer.DataDir,lockDir:%s', [vLockDir]));
  try
    vRelease := TFlock.New(vLockDir);
    gLog.Info(Format('Directory locked successfully,lockDir:%s', [vLockDir]));
    mInstanceDirLock := vRelease;
  except
    on E: Exception do
    begin
      gLog.Error(Format('Directory locked failed,lockDir:%s', [vLockDir]));
      raise ConvertFileLockError(E);
    end;
  end;

  TDirectory.CreateDirectory(mWalletConfig.DataDir);
  gLog.Info(Format('Open NodeServer.walletConfig.DataDir:%s', [mWalletConfig.DataDir]));
end;

procedure TNode.StartWallet;
begin
  mWalletManager.Start;
  if mConfig.EntropyStorePath <> '' then
  begin
    mWalletManager.AddEntropyStore(mConfig.EntropyStorePath);
    mWalletManager.Unlock(mConfig.EntropyStorePath, mConfig.EntropyStorePassword);
  end;
end;

procedure TNode.StartVite;
begin
  mViteServer.Start;
end;

procedure TNode.StartRPC;
var
  vPublicApis, vCustomApis, vApis: TArray<TRpcAPI>;
  vTargetURL: string;
  vURL: TURI;
  vCli: TWebSocketCli;
  vServer: TRpcServer;
begin
  if mConfig.SubscribeEnabled then
  begin
    TFilters.Es := TEventSystem.Create(GetVite);
    TFilters.Es.Start;
  end;
  try
    TRpcApi.Init(mConfig.DataDir, mConfig.LogLevel, mConfig.TestTokenHexPrivKey,
      mConfig.TestTokenTti, mConfig.NetID, mConfig.TxDexEnable);

    vPublicApis := TRpcApi.GetPublicApis(GetViteServer);
    vCustomApis := TRpcApi.GetApis(GetViteServer, mConfig.PublicModules);
    vApis := TRpcApi.MergeApis(vPublicApis, vCustomApis);

    try
      Node.Rpc.StartInProcess(Self, vApis);
    except
      on E: Exception do
      begin
        Node.Rpc.StopInProcess(Self);
        raise;
      end;
    end;

    if mConfig.IPCEnabled then
    begin
      try
        Node.Rpc.StartIPC(Self, vApis);
      except
        on E: Exception do
        begin
          Node.Rpc.StopIPC(Self);
          raise;
        end;
      end;
    end;

    if mConfig.RPCEnabled then
    begin
      try
        Node.Rpc.StartHTTP(Self, mHttpEndpoint, mPrivateHttpEndpoint, vApis, nil, mConfig.HTTPCors,
          mConfig.HttpVirtualHosts, THTTPTimeouts.Create, mConfig.HttpExposeAll);
      except
        on E: Exception do
        begin
          Node.Rpc.StopHTTP(Self);
          raise;
        end;
      end;
    end;

    if mConfig.WSEnabled then
    begin
      try
        Node.Rpc.StartWS(Self, mWsEndpoint, vApis, nil, mConfig.WSOrigins, mConfig.WSExposeAll);
      except
        on E: Exception do
        begin
          Node.Rpc.StopWS(Self);
          raise;
        end;
      end;
    end;

    if mConfig.DashboardTargetURL <> '' then
    begin
      vTargetURL := mConfig.DashboardTargetURL + '/ws/gvite/' +
        mConfig.NetID.ToString + '@' + GetVite.GetNet.GetInfo.ID.ToString;
      try
        vURL := TURI.Create(vTargetURL);
        if (vURL.Scheme <> 'ws') and (vURL.Scheme <> 'wss') then
        begin
          raise Exception.Create('DashboardTargetURL need match WebSocket Protocol.');
        end;

        vCli := TRpc.StartWSCliEndpoint(vURL, vApis, nil, mConfig.WSExposeAll, vServer);
        mWsCli := vCli;
      except
        on E: Exception do
        begin
          if vCli <> nil then
          begin
            vCli.Close;
          end;
          if vServer <> nil then
          begin
            vServer.Stop;
          end;
          raise;
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      if TFilters.Es <> nil then
      begin
        TFilters.Es.Stop;
      end;
      raise;
    end;
  end;
end;

procedure TNode.StopWallet;
begin
  if mWalletManager = nil then
  begin
    raise ErrNodeStopped;
  end;
  mWalletManager.Stop;
end;

procedure TNode.StopVite;
begin
  if mViteServer = nil then
  begin
    raise ErrNodeStopped;
  end;
  mViteServer.Stop;
end;

procedure TNode.StopRPC;
begin
  Node.Rpc.StopWS(Self);
  Node.Rpc.StopHTTP(Self);
  Node.Rpc.StopIPC(Self);
  Node.Rpc.StopInProcess(Self);
  if TFilters.Es <> nil then
  begin
    TFilters.Es.Stop;
  end;
end;

function NewNode(const ParaConf: TNodeConfig): TNode;
begin
  Result := TNode.Create(ParaConf);
end;

initialization
  gLog := TLog15.New(['module', 'gvite/node']);
end.