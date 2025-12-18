unit Cmd.NodeManager.FullNodeMaker;

interface

uses
  Cmd.NodeManager.Assist,
  Cmd.NodeManager.BaseNodeMaker,
  Cmd.NodeManager.Check.Chain,
  Cmd.NodeManager.Default.Node.Manager,
  Cmd.NodeManager.Export.Node.Manager,
  Cmd.NodeManager.Local.Node.Maker,
  Cmd.NodeManager.Node.Maker,
  Cmd.NodeManager.Node.Manager,
  Cmd.NodeManager.Plugin.Data.Node.Manager,
  Cmd.NodeManager.Recover.Node.Manager,
  Cmd.NodeManager.SubCmd.Node.Manager,
  GoToDelphi.Dependencies.Cli,
  Node.Config,
  Node.Node,
  System.Classes;

type
	TFullNodeMaker = class( TBaseNodeMaker )
	public
		function MakeNode( ParaCtx : TContext ) : TNode; override;
		function MakeNodeConfig( ParaCtx : TContext ) : TConfig; override;
	end;

implementation

uses
	System.SysUtils,
	GoToDelphi.Helpers.Log15,
    Common;

{ TFullNodeMaker }

function TFullNodeMaker.MakeNode( ParaCtx : TContext ) : TNode;
var
	vNodeConfig : TConfig;
begin
	Result := nil;
	try
		vNodeConfig := MakeNodeConfig( ParaCtx );
		TLog15.New.Info( Format( 'NodeConfig info: %s', [vNodeConfig.ToString] ) );

		Result := TNode.Create( vNodeConfig );
	except
		on E : Exception do
		begin
			TLog15.New.Error( Format( 'Failed to create the node: %s', [E.Message] ) );
			raise;
		end;
	end;
end;

function TFullNodeMaker.MakeNodeConfig( ParaCtx : TContext ) : TConfig;
begin
	Result := TConfig.CreateDefaultNodeConfig;
	TLog15.New.Info( Format( 'DefaultNodeconfig: %s', [Result.ToString] ) );

	try
		// 1: Load config file.
		LoadNodeConfigFromFile( ParaCtx, Result );
		TLog15.New.Info( Format( 'After load config file: %s', [Result.ToString] ) );

		// 2: Apply flags, Overwrite the configuration file configuration
		MappingNodeConfig( ParaCtx, Result );
		TLog15.New.Info( Format( 'After mapping cmd input: %s', [Result.ToString] ) );

		// 3: Override any default configs for hard coded networks.
		OverrideNodeConfigs( ParaCtx, Result );
		TLog15.New.Info( Format( 'Last override config: %s', [Result.ToString] ) );
		TLog15.New.Info( Format( 'NodeServer.DataDir:%s', [Result.DataDir] ) );
		TLog15.New.Info( Format( 'NodeServer.KeyStoreDir:%s', [Result.KeyStoreDir] ) );

		// 4: Config log to file
		MakeRunLogFile( Result );
	except
		on E : Exception do
		begin
			// Handle or re-raise
			raise;
		end;
	end;
end;

end.
