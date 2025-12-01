unit Cmd.GvitePlugins.LoadPlugins;

interface

uses
	System.Classes,
	System.SysUtils,
	Cli,
	Cmd.NodeManager,
	Cmd.SubCmdExport,
	Cmd.SubCmdLedger,
	Cmd.SubCmdLoadLedger,
	Cmd.SubCmdPluginData,
	Cmd.SubCmdRecover,
	Cmd.SubCmdRpc,
	Cmd.SubCmdVirtualNode,
	Cmd.Utils,
	Log15,
	Version,
	System.IOUtils,
	System.DateUtils;

procedure Loading;

implementation

uses
	GoToDelphi.Helpers.Runtime,
	System.Net.HttpClient;

var
	gLog: ILogger;
	gApp: IApp;

procedure BeforeAction( const ParaCtx: IContext );
var
	vMax: Integer;
	vPprofPort: Cardinal;
	vListenAddress, vVisitAddress: string;
begin
	vMax := NumCPU + 1;
	gLog.Info('runtime num', ['max', vMax]);
	SetGOMAXPROCS(vMax);

	if ParaCtx.GlobalIsSet(Utils.PProfEnabledFlag.Name) then
	begin
		vPprofPort := ParaCtx.GlobalUint(Utils.PProfPortFlag.Name);
		if vPprofPort = 0 then
		begin
			vPprofPort := 8080;
		end;
		vListenAddress := Format('%s:%d', ['0.0.0.0', vPprofPort]);
		vVisitAddress := Format('http://localhost:%d/debug/pprof', [vPprofPort]);

		TThread.CreateAnonymousThread(
			procedure
			var
				vServer: THTTPServer;
			begin
				gLog.Info('Enable chain performance analysis tool, you can visit the address of `' + vVisitAddress + '`');
				try
					vServer := THTTPServer.Create;
					try
						// This is a placeholder for a proper HTTP server implementation.
						// A real implementation would require a library like Indy or WebBroker
						// to listen for and handle HTTP requests.
						// vServer.Bind(vListenAddress);
						// vServer.Listen;
					finally
						vServer.Free;
					end;
				except
					on E: Exception do
					begin
						gLog.Error('PProf server failed', ['error', E.Message]);
					end;
				end;
			end
		).Start;
	end;
end;

procedure Action( const ParaCtx: IContext );
var
	vArgs: TArray<string>;
	vNodeManager: INodeManager;
begin
	vArgs := ParaCtx.Args;
	if Length(vArgs) > 0 then
	begin
		raise Exception.Create(Format('invalid command: %s', [vArgs[0]]));
	end;

	try
		vNodeManager := TNodeManager.NewDefaultNodeManager(ParaCtx, TFullNodeMaker.Create);
		vNodeManager.Start;
	except
		on E: Exception do
		begin
			raise Exception.Create(Format('new node error, %s', [E.Message]));
		end;
	end;
end;

procedure AfterAction( const ParaCtx: IContext );
begin
end;

procedure Loading;
var
	vArgs: TArray<string>;
	vIndex: Integer;
begin
	SetLength(vArgs, ParamCount + 1);
	for vIndex := 0 to ParamCount do
	begin
		vArgs[vIndex] := ParamStr(vIndex);
	end;

	if gApp.Run(vArgs) <> 0 then
	begin
		WriteLn(StdErr, gApp.LastError.Message);
		Halt(1);
	end;
end;

initialization
	gLog := TLogger.New('module', 'gvite/main');

	gApp := TCli.NewApp;
	gApp.Name := TPath.GetFileName(ParamStr(0));
	gApp.HideVersion := False;
	gApp.Version := VITE_BUILD_VERSION;
	gApp.Compiled := Now;
	gApp.Authors := [
		TAuthor.Create('Vite Labs', 'info@vite.org')
	];
	gApp.Copyright := 'Copyright 2018-2024 The go-vite Authors';
	gApp.Usage := 'the go-vite cli application';

	gApp.Commands := [
		versionCommand,
		licenseCommand,
		LedgerRecoverCommand,
		ExportCommand,
		PluginDataCommand,
		RpcCommand,
		LoadLedgerCommand,
		QueryLedgerCommand,
		VirtualNodeCommand
	];
	gApp.SortCommands;

	gApp.MergeFlags(Utils.StatFlags);

	gApp.Before := BeforeAction;
	gApp.Action := Action;
	gApp.After := AfterAction;
end.
