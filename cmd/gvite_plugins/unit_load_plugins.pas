unit unit_load_plugins;

interface

uses unit_default_node_manager;

procedure Loading;

implementation


uses
  unit_cli,
  SysUtils;

{
  HttpServer,
  CliApp,
  Version,
  Log;
}


//var
//  log: TLogger;
//  app: unit_cli.TApp;

// Skybuck: for now the App/console input options will be ignored.

{
procedure Init;
begin
  app.Name := ExtractFileName(ParamStr(0));
  app.HideVersion := False;
  app.Version := VITE_BUILD_VERSION;
  app.Compiled := Now;
  app.Authors := [
	TCliAuthor.Create('Vite Labs', 'info@vite.org')
  ];
  app.Copyright := 'Copyright 2018-2024 The go-vite Authors';
  app.Usage := 'the go-vite cli application';

  app.Commands := [
	versionCommand,
	licenseCommand,
	subcmd_recover.LedgerRecoverCommand,
	subcmd_export.ExportCommand,
	subcmd_plugin_data.PluginDataCommand,
	subcmd_rpc.RpcCommand,
	subcmd_loadledger.LoadLedgerCommand,
	subcmd_ledger.QueryLedgerCommand,
	subcmd_virtualnode.VirtualNodeCommand
  ];
  SortCommandsByName(app.Commands);

  app.Flags := utils.MergeFlags(app.Flags, app.Commands.Flags);
  app.Flags := utils.MergeFlags(app.Flags, utils.StatFlags);

  app.BeforeAction := BeforeAction;
  app.Action := Action;
  app.AfterAction := AfterAction;
end;
}

procedure Loading;
begin
{
  if app.Run(ParamStr(0), ParamStr(1), ParamStr(2), ParamStr(3]) <> 0 then
  begin
	WriteLn(StdErr, 'Error: ', app.ErrorMessage);
	ExitCode := 1;
  end;
}
	Action;
end;

// Skybuck: for now logging activity ignored.
{
procedure BeforeAction(Sender: TObject; Context: TCliContext);
var
  maxCPU: Integer;
begin
  maxCPU := Runtime.NumCPU + 1;
  log.Info('runtime num', 'max', maxCPU);
  Runtime.SetMaxProcs(maxCPU);

  if Context.HasFlag(utils.PProfEnabledFlag) then
  begin
	var pprofPort: Cardinal := Context.GetUIntFlag(utils.PProfPortFlag);
	var listenAddress: string;
	if pprofPort = 0 then
	  pprofPort := 8080;
	listenAddress := Format('0.0.0.0:%d', [pprofPort]);
	var visitAddress := Format('http://localhost:%d/debug/pprof', [pprofPort]);

	TThread.CreateAnonymousThread(
	  procedure
	  begin
		log.Info('Enable chain performance analysis tool, you can visit the address of `' + visitAddress + '`');
		HttpServer.ListenAndServe(listenAddress, nil);
	  end).Start;
  end;
end;
}


// Skybuck: the main thing. just creating the node manager for now.
{
procedure Action(Sender: TObject; Context: TCliContext);
var
  args: TArray<string>;
begin
  args := Context.Args;
  if Length(args) > 0 then
	raise Exception.Create('invalid command: "' + args[0] + '"');

  var nodeManager := nodemanager.NewDefaultNodeManager(Context, nodemanager.FullNodeMaker.Create);
  if nodeManager = nil then
	raise Exception.Create('new node error');

  nodeManager.Start;
end;
}

// Skybuck: new Action
procedure Action;
begin
  var nodeManager := nodemanager.NewDefaultNodeManager(Context, nodemanager.FullNodeMaker.Create);
  if nodeManager = nil then
	raise Exception.Create('new node error');

  nodeManager.Start;
end;


// Skybuck: nothing there, ignored.
{
procedure AfterAction(Sender: TObject; Context: TCliContext);
begin
end;
}

initialization

//	Init;




{
  //TODO: Whether the command name is fixed ？
  app.Name := ExtractFileName(ParamStr(0));
  app.HideVersion := False;
  app.Version := version.VITE_BUILD_VERSION;
  app.Compiled := Now;
  app.Authors := TAuthors.Create(
    TAuthor.Create('Vite Labs', 'info@vite.org')
  );
  app.Copyright := 'Copyright 2018-2024 The go-vite Authors';
  app.Usage := 'the go-vite cli application';

  //Import: Please add the New command here
  app.Commands := TCommands.Create(
	versionCommand,
    licenseCommand,
    subcmd_recover.LedgerRecoverCommand,
    subcmd_export.ExportCommand,
    subcmd_plugin_data.PluginDataCommand,
    subcmd_rpc.RpcCommand,
    subcmd_loadledger.LoadLedgerCommand,
    subcmd_ledger.QueryLedgerCommand,
    subcmd_virtualnode.VirtualNodeCommand
  );
  app.Commands.SortByName;

  //Import: Please add the New Flags here
  for element in app.Commands do
    app.Flags := MergeFlags(app.Flags, element.Flags);
  app.Flags := MergeFlags(app.Flags, StatFlags);

  app.Before := beforeAction;
  app.Action := action;
  app.After := afterAction;
}

procedure Loading;
begin
  if app.Run(ParamStr(0)) <> 0 then
  begin
    WriteLn(ErrOutput, 'Error: ', GetLastError);
    Halt(1);
  end;
end;

function beforeAction(ctx: TContext): TError;
var
  max: Integer;
begin
  max := System.CPUCount + 1;
  log.Info('runtime num', 'max', max);
  System.SetProcessAffinityMask(GetCurrentProcess, max);  // wrong.

  //TODO: we can add dashboard here
  if ctx.GlobalIsSet(PPROF_ENABLED_FLAG.Name) then
  begin
    var pprofPort := ctx.GlobalUint(PPROF_PORT_FLAG.Name);
    var listenAddress: string;
    if pprofPort = 0 then
      pprofPort := 8080;
    listenAddress := Format('%s:%d', ['0.0.0.0', pprofPort]);
    var visitAddress := Format('http://localhost:%d/debug/pprof', [pprofPort]);

    TThread.CreateAnonymousThread(
      procedure
      begin
        log.Info('Enable chain performance analysis tool, you can visit the address of `' + visitAddress + '`');
        HTTPServer := THTTPServer.Create(listenAddress, nil);
      end
    ).Start;
  end;

  Result := nil;
end;

function action(ctx: TContext): TError;
begin
  //Make sure No subCommands were entered,Only the flags
  if ctx.Args.Count > 0 then
    Result := Format('invalid command: %s', [ctx.Args[0]])
  else
  begin
    var nodeManager, err := nodemanager.NewDefaultNodeManager(ctx, nodemanager.FullNodeMaker);
    if err <> nil then
      Result := Format('new node error, %+v', [err])
    else
      Result := nodeManager.Start;
  end;
end;

function afterAction(ctx: TContext): TError;
begin
  Result := nil;
end;




end.
