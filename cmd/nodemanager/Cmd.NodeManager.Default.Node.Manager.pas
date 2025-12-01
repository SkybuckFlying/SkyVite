unit Cmd.NodeManager.DefaultNodeManager;

interface

uses
	System.Classes,
	GoToDelphi.Dependencies.Cli,
	Node.Node,
	Cmd.NodeManager.NodeMaker,
	Cmd.NodeManager.NodeManager;

type
	TDefaultNodeManager = class( TInterfacedObject, INodeManager )
	private
		mCtx : TContext;
		mNode : TNode;
		function GetNode : TNode;
	public
		constructor Create( ParaCtx : TContext; ParaMaker : INodeMaker );
		destructor Destroy; override;

		function Start : boolean;
		function Stop : boolean;
		property Node : TNode read GetNode;
	end;

implementation

uses
	System.SysUtils,
	Cmd.NodeManager.Assist;

constructor TDefaultNodeManager.Create( ParaCtx : TContext; ParaMaker : INodeMaker );
begin
	inherited Create;
	mCtx := ParaCtx;
	try
		mNode := ParaMaker.MakeNode( mCtx );
		if mNode = nil then
		begin
			// MakeNode should raise an exception on failure.
			raise Exception.Create( 'Failed to make node in DefaultNodeManager' );
		end;
	except
		on E : Exception do
		begin
			// Log or handle the exception if necessary
			raise Exception.Create( Format( 'Error creating DefaultNodeManager: %s', [E.Message] ) );
		end;
	end;
end;

destructor TDefaultNodeManager.Destroy;
begin
	mNode.Free;
	inherited Destroy;
end;

function TDefaultNodeManager.GetNode : TNode;
begin
	Result := mNode;
end;

function TDefaultNodeManager.Start : boolean;
begin
	// 1: Start up the node
	Result := TNodeManagerAssist.StartNode( mNode );
	if not Result then
	begin
		Exit;
	end;

	// 2: Waiting for node to close
	TNodeManagerAssist.WaitNode( mNode );
end;

function TDefaultNodeManager.Stop : boolean;
begin
	TNodeManagerAssist.StopNode( mNode );
	Result := true;
end;

end.
