unit Cmd.GvitePlugins.SubCmdDemo;

interface

uses
  Cli,
  Cmd.Gvite.Plugins.Load.Plugins,
  Cmd.Gvite.Plugins.MiscCmd,
  Cmd.NodeManager,
  Cmd.Utils,
  System.Classes,
  System.SysUtils;

var
	demoCommand: ICommand;

implementation

var
	demoFlags: TFlagArray;

procedure demoAction( const ParaCtx: IContext );
var
	vNodeManager: INodeManager;
begin
	try
		vNodeManager := TSubCmdNodeManager.Create(ParaCtx, TFullNodeMaker.Create);
		try
			vNodeManager.Start;
			//Tips: add your code here
			WriteLn('demo print');
		finally
			vNodeManager.Stop;
		end;
	except
		on E: Exception do
		begin
			WriteLn(Format('demo error %s', [E.Message]));
		end;
	end;
end;

initialization
	demoFlags := Utils.MergeFlags(ConfigFlags, GeneralFlags);

	demoCommand := TCommand.Create(
		'demo',
		'demo',
		'',
		'DEMO COMMANDS',
		'demo',
		MigrateFlags(demoAction),
		demoFlags
	);
end.
