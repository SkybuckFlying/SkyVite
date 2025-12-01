unit Cmd.NodeManager.NodeMaker;

interface

uses
	GoToDelphi.Dependencies.Cli,
	Node.Node,
	Node.Config;

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
