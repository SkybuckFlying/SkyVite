unit Cmd.NodeManager.NodeManager;

interface

uses
  Cmd.NodeManager.Assist,
  Cmd.NodeManager.Check.Chain,
  Cmd.NodeManager.Default.Node.Manager,
  Cmd.NodeManager.Export.Node.Manager,
  Cmd.NodeManager.Full.Node.Maker,
  Cmd.NodeManager.Local.Node.Maker,
  Cmd.NodeManager.Node.Maker,
  Cmd.NodeManager.Plugin.Data.Node.Manager,
  Cmd.NodeManager.Recover.Node.Manager,
  Cmd.NodeManager.SubCmd.Node.Manager,
  Node.Node;

type
	{
		INodeManager is an interface for managing a node's lifecycle.
	}
	INodeManager = interface
		['{C1B8E3A7-9A68-4E2D-881B-9C4B7D22C03F}']
		function Start : boolean;
		function Stop : boolean;
		function GetNode : TNode;
		property Node : TNode read GetNode;
	end;

implementation

end.
