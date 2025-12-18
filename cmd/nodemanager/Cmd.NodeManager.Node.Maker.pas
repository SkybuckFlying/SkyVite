unit Cmd.NodeManager.NodeMaker;

interface

uses
  Cmd.NodeManager.Assist,
  Cmd.NodeManager.Check.Chain,
  Cmd.NodeManager.Default.Node.Manager,
  Cmd.NodeManager.Export.Node.Manager,
  Cmd.NodeManager.Full.Node.Maker,
  Cmd.NodeManager.Local.Node.Maker,
  Cmd.NodeManager.Node.Manager,
  Cmd.NodeManager.Plugin.Data.Node.Manager,
  Cmd.NodeManager.Recover.Node.Manager,
  Cmd.NodeManager.SubCmd.Node.Manager,
  GoToDelphi.Dependencies.Cli,
  Node.Config,
  Node.Node;

type
	{
		INodeMaker is an interface for creating a node and its configuration.
	}
	INodeMaker = interface
		['{E3B4B5B6-F28A-4A56-8A3E-79B655A9A22E}']
		function MakeNode( ParaCtx : TContext ) : TNode;
		function MakeNodeConfig( ParaCtx : TContext ) : TConfig;
	end;

implementation

end.
