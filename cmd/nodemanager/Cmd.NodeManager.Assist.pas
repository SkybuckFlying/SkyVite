unit Cmd.NodeManager.Assist;

interface

uses
  Cmd.NodeManager.Check.Chain,
  Cmd.NodeManager.Default.Node.Manager,
  Cmd.NodeManager.Export.Node.Manager,
  Cmd.NodeManager.Full.Node.Maker,
  Cmd.NodeManager.Local.Node.Maker,
  Cmd.NodeManager.Node.Maker,
  Cmd.NodeManager.Node.Manager,
  Cmd.NodeManager.Plugin.Data.Node.Manager,
  Cmd.NodeManager.Recover.Node.Manager,
  Cmd.NodeManager.SubCmd.Node.Manager,
  GoToDelphi.Helpers.Log15,
  Node.Node,
  System.SysUtils;

type
	{
		TNodeManagerAssist provides helper functions to manage a node's lifecycle.
	}
	TNodeManagerAssist = class
	public
		class function StartNode( ParaNode : TNode ) : boolean;
		class procedure WaitNode( ParaNode : TNode );
		class procedure StopNode( ParaNode : TNode );
	end;

implementation

uses
	Common;

var
	log : ILog15;

{ TNodeManagerAssist }

class function TNodeManagerAssist.StartNode( ParaNode : TNode ) : boolean;
var
	vError : string;
begin
	Result := false;
	try
		log.Info( 'Starting prepare node...' );
		if not ParaNode.Prepare( vError ) then
		begin
			vError := Format( 'Failed to prepare node, %s', [vError] );
			log.Error( vError );
			Writeln( vError );
			Exit;
		end;

		log.Info( 'Starting Node...' );
		if not ParaNode.Start( vError ) then
		begin
			vError := Format( 'Failed to start node, %s', [vError] );
			Writeln( vError );
			TCrit.Crit( vError );
			Exit;
		end;

		ParaNode.Wait();
		Result := true;
	except
		on E : Exception do
		begin
			log.Error( Format( 'Failed to start node due to an exception: %s', [E.Message] ) );
			Writeln( Format( 'Failed to start node due to an exception: %s', [E.Message] ) );
		end;
	end;
end;

class procedure TNodeManagerAssist.StopNode( ParaNode : TNode );
var
	vError : string;
begin
	log.Warn( 'Stopping node...' );

	// Stop the node Extenders
	log.Warn( 'Stopping node extenders...' );

	if not ParaNode.Stop( vError ) then
	begin
		log.Error( Format( 'Failed to stop node, %s', [vError] ) );
	end;
end;

class procedure TNodeManagerAssist.WaitNode( ParaNode : TNode );
begin
	ParaNode.Wait();
end;

initialization
	log := TLog15.New( 'module', 'gvite/node_manager' );
end.
