unit Cmd.NodeManager.SubCmdNodeManager;

interface

uses
	System.Classes,
	GoToDelphi.Dependencies.Cli,
	Cmd.NodeManager.NodeManager,
	Cmd.NodeManager.NodeMaker,
	Node.Node;

type
	TSubCmdNodeManager = class( TInterfacedObject, INodeManager )
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

{ TSubCmdNodeManager }

constructor TSubCmdNodeManager.Create( ParaCtx : TContext; ParaMaker : INodeMaker );
begin
	inherited Create;
	mCtx := ParaCtx;
	try
		mNode := ParaMaker.MakeNode( mCtx );
		if mNode = nil then
		begin
			raise Exception.Create( 'Failed to make node in SubCmdNodeManager' );
		end;
	except
		on E : Exception do
		begin
			raise Exception.Create( Format( 'Error creating SubCmdNodeManager: %s', [E.Message] ) );
		end;
	end;
end;

destructor TSubCmdNodeManager.Destroy;
begin
	mNode.Free;
	inherited Destroy;
end;

function TSubCmdNodeManager.GetNode : TNode;
begin
	Result := mNode;
end;

function TSubCmdNodeManager.Start : boolean;
begin
	// Start up the node but do not wait for it to close.
	Result := TNodeManagerAssist.StartNode( mNode );
end;

function TSubCmdNodeManager.Stop : boolean;
begin
	TNodeManagerAssist.StopNode( mNode );
	Result := true;
end;

end.
