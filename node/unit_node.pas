unit unit_node;

{
This code defines a `TNode` class that manages the various components of a Vite node, including the wallet, Vite server, and RPC interfaces.
The `Prepare` method initializes the wallet and Vite server, while the `Start` method starts the Vite server and RPC interfaces.
The `Stop` method stops all components, and the `Wait` method waits for termination signals.

Note that this translation assumes the existence of several units and types, such as `Vite`, `Wallet`, `Config`, `Log`, `Monitor`, `NodeConfig`, `Pow`, `RemotePow`, `RPC`, `RPCApi`, and `Filters`.
You may need to implement or import these units and types for the code to compile and run correctly.
}


interface

uses
  SysUtils,
  Classes, Generics.Collections,
  Vite,
  Wallet,
  Config,
  Log,
  Monitor,
  NodeConfig,
  Pow,
  RemotePow,
  RPC,
  RPCApi,
  Filters;

type
  TNode = class
  private
    FConfig: TNodeConfig;
    FWalletConfig: TWalletConfig;
    FWalletManager: TWalletManager;
    FViteConfig: TViteConfig;
    FViteServer: TVite;
    FRPCAPIs: TList<TRPCApi>;
    FInProcessHandler: TRPCServer;
    FIPCEndpoint: string;
    FIPCListener: TIPCListener;
    FIPCHandler: TRPCServer;
    FHTTPEndpoint: string;
    FHTTPWhitelist: TStrings;
    FHTTPListener: THTTPListener;
    FHTTPHandler: TRPCServer;
    FPrivateHTTPEndpoint: string;
    FPrivateHTTPListener: THTTPListener;
    FPrivateHTTPHandler: TRPCServer;
    FWSEndpoint: string;
    FWSListener: TWebSocketListener;
    FWSHandler: TRPCServer;
    FWSCli: TWebSocketCli;
    FStop: TEvent;
    FLock: TReadWriteLock;
    FInstanceDirLock: TFileLock;
    function OpenDataDir: Boolean;
    function StartWallet: Boolean;
    function StartVite: Boolean;
    function StartRPC: Boolean;
    procedure StopWallet;
    procedure StopVite;
    procedure StopRPC;
  public
    constructor Create(const AConfig: TNodeConfig); reintroduce;
    function Prepare: Boolean;
    function Start: Boolean;
    procedure Stop;
    procedure Wait;
    function Vite: TVite;
    function Config: TNodeConfig;
    function ViteConfig: TViteConfig;
    function ViteServer: TVite;
    function WalletManager: TWalletManager;
  end;

implementation

uses
  Windows;

var
  Log: ILogger;

constructor TNode.Create(const AConfig: TNodeConfig);
begin
  FConfig := AConfig;
  FWalletConfig := AConfig.MakeWalletConfig;
  FViteConfig := AConfig.MakeViteConfig;
  FIPCEndpoint := AConfig.IPCEndpoint;
  FHTTPEndpoint := AConfig.HTTPEndpoint;
  FWSEndpoint := AConfig.WSEndpoint;
  FPrivateHTTPEndpoint := AConfig.PrivateHTTPEndpoint;
  FStop := TEvent.Create(nil, True, False, '');
  FLock := TReadWriteLock.Create;
end;

function TNode.Prepare: Boolean;
begin
  Result := False;
  FLock.BeginWrite;
  try
    Log.Info('Check dataDir is OK?');
    if not OpenDataDir then
	  Exit;
    Log.Info('DataDir is OK.');

    Log.Info('Begin Prepare node...');
    if FWalletConfig = nil then
      Exit(False);

    if FWalletManager <> nil then
      Exit(False);
    FWalletManager := TWalletManager.Create(FWalletConfig);

	if FViteServer <> nil then
      Exit(False);

    Log.Info('Begin Start Wallet...');
    if not StartWallet then
	  Exit;

    FViteServer := TVite.Create(FViteConfig, FWalletManager);
    if FViteServer = nil then
      Exit;

    RemotePow.InitRawUrl(FConfig.PowServerUrl);
    Pow.Init(FConfig.VMTestParamEnabled);

    if not FViteServer.Init then
      Exit;

    Result := True;
  finally
    FLock.EndWrite;
  end;
end;

function TNode.Start: Boolean;
begin
  Result := False;
  FLock.BeginWrite;
  try
    Log.Info('Begin Start Vite...');
    if not StartVite then
      Exit;

    Log.Info('Begin Start RPC...');
    if not StartRPC then
      Exit;

    Monitor.InitNTPChecker(Log);

    Result := True;
  finally
    FLock.EndWrite;
  end;
end;

procedure TNode.Stop;
var
  Msg: TMsg;
begin
  WriteLn('Preparing node shutdown...');
  FLock.BeginWrite;
  try
    FStop.SetEvent;

    Log.Info('Begin Stop Wallet...');
    StopWallet;

    Log.Info('Begin Stop Vite...');
    StopVite;

    Log.Info('Begin Stop RPC...');
    StopRPC;

    Log.Info('Begin release dataDir lock...');
    if FInstanceDirLock <> nil then
    begin
      FInstanceDirLock.Release;
      FInstanceDirLock := nil;
      Log.Info('The file lock has been released...');
    end;
  finally
    FLock.EndWrite;
  end;
end;

procedure TNode.Wait;
var
  Msg: TMsg;
begin
  while True do
  begin
    if WaitForSingleObject(FStop.Handle, INFINITE) = WAIT_OBJECT_0 then
      Break;
    if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
    begin
      if Msg.message = WM_QUIT then
        Break
	  else
        DispatchMessage(Msg);
    end;
  end;
  Stop;
end;

function TNode.Vite: TVite;
begin
  Result := FViteServer;
end;

function TNode.Config: TNodeConfig;
begin
  Result := FConfig;
end;

function TNode.ViteConfig: TViteConfig;
begin
  Result := FViteConfig;
end;

function TNode.ViteServer: TVite;
begin
  Result := FViteServer;
end;

function TNode.WalletManager: TWalletManager;
begin
  Result := FWalletManager;
end;

function TNode.StartWallet: Boolean;
var
  Error: Boolean;
begin
  Result := False;
  Error := FWalletManager.Start;
  if Error then
    Exit;

  if FConfig.EntropyStorePath <> '' then
  begin
    Error := FWalletManager.AddEntropyStore(FConfig.EntropyStorePath);
    if Error then
      Exit;

    Error := FWalletManager.Unlock(FConfig.EntropyStorePath, FConfig.EntropyStorePassword);
    if Error then
      Exit;
  end;

  Result := True;
end;

function TNode.StartVite: Boolean;
begin
  Result := FViteServer.Start;
end;

function TNode.StartRPC: Boolean;
var
  PublicApis, CustomApis, AllApis: TList<TRPCApi>;
begin
  Result := False;

  if FConfig.SubscribeEnabled then
  begin
    Filters.Es := TEventSystem.Create(FViteServer);
    Filters.Es.Start;
  end;

  try
    RPCApi.Init(FConfig.DataDir, FConfig.LogLevel, FConfig.TestTokenHexPrivKey,
      FConfig.TestTokenTti, FConfig.NetID, FConfig.TxDexEnable);

    PublicApis := RPCApi.GetPublicApis(FViteServer);
    CustomApis := RPCApi.GetApis(FViteServer, FConfig.PublicModules);
    AllApis := RPCApi.MergeApis(PublicApis, CustomApis);

    if not StartInProcess(AllApis) then
      Exit;

    if FConfig.IPCEnabled then
    begin
      if not StartIPC(AllApis) then
        Exit;
    end;

    if FConfig.RPCEnabled then
    begin
      if not StartHTTP(FHTTPEndpoint, FPrivateHTTPEndpoint, AllApis, nil,
        FConfig.HTTPCors, FConfig.HttpVirtualHosts, FConfig.HttpTimeouts,
        FConfig.HttpExposeAll) then
        Exit;
    end;

    if FConfig.WSEnabled then
    begin
      if not StartWS(FWSEndpoint, AllApis, nil, FConfig.WSOrigins,
        FConfig.WSExposeAll) then
		Exit;
    end;

    if FConfig.DashboardTargetURL <> '' then
	begin
      var
        TargetUrl: string;
        Uri: TUri;
      begin
        TargetUrl := FConfig.DashboardTargetURL + '/ws/gvite/' +
          IntToStr(FConfig.NetID) + '@' + FViteServer.Net.Info.ID.ToString;
        Uri := TUri.Create(TargetUrl);
        try
          if (Uri.Scheme <> 'ws') and (Uri.Scheme <> 'wss') then
            raise Exception.Create('DashboardTargetURL need match WebSocket Protocol.');

          var
            Cli: TWebSocketCli;
            Server: TRPCServer;
          begin
            Cli := nil;
            Server := nil;
            if not RPCApi.StartWSCliEndpoint(Uri, AllApis, nil, FConfig.WSExposeAll, Cli, Server) then
            begin
              Cli.Free;
              Server.Free;
              Exit;
            end;
            FWSCli := Cli;
          end;
        finally
          Uri.Free;
        end;
      end;
    end;

    Result := True;
  except
    on E: Exception do
    begin
      if Filters.Es <> nil then
        Filters.Es.Stop;
      raise;
    end;
  end;
end;

procedure TNode.StopWallet;
begin
  if FWalletManager <> nil then
    FWalletManager.Stop;
end;

procedure TNode.StopVite;
begin
  if FViteServer <> nil then
    FViteServer.Stop;
end;

procedure TNode.StopRPC;
begin
  StopWS;
  StopHTTP;
  StopIPC;
  if Filters.Es <> nil then
    Filters.Es.Stop;
end;

function TNode.OpenDataDir: Boolean;
var
  LockDir: string;
begin
  Result := False;
  if FConfig.DataDir = '' then
    Exit(True);

  if not ForceDirectories(FConfig.DataDir) then
    Exit;
  Log.Info(Format('Open NodeServer.DataDir:%s', [FConfig.DataDir]));

  LockDir := IncludeTrailingPathDelimiter(FConfig.DataDir) + 'LOCK';
  Log.Info(Format('Try to Lock NodeServer.DataDir,lockDir:%s', [LockDir]));
  FInstanceDirLock := TFileLock.Create(LockDir);
  if FInstanceDirLock.Acquire then
  begin
    Log.Info(Format('Directory locked successfully,lockDir:%s', [LockDir]));
    Result := True;
  end
  else
  begin
    Log.Error(Format('Directory locked failed,lockDir:%s', [LockDir]));
    FInstanceDirLock.Free;
  end;

  if not ForceDirectories(FWalletConfig.DataDir) then
    Exit;
  Log.Info(Format('Open NodeServer.walletConfig.DataDir:%s', [FWalletConfig.DataDir]));
end;

end.



