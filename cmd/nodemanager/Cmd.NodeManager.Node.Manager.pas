unit Cmd.NodeManager.NodeManager;

interface

uses
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
