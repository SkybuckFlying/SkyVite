unit Cmd.NodeManager.PluginDataNodeManager;

interface

uses
	System.Classes,
	GoToDelphi.Dependencies.Cli,
	Cmd.NodeManager.NodeManager,
	Cmd.NodeManager.NodeMaker,
	Node.Node;

type
	TPluginDataNodeManager = class( TInterfacedObject, INodeManager )
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
	Cmd.NodeManager.Assist,
	Ledger.Chain.Interfaces,
	Node.Config;

{ TPluginDataNodeManager }

constructor TPluginDataNodeManager.Create( ParaCtx : TContext; ParaMaker : INodeMaker );
var
	vLedgerGc, vOpenPlugins : boolean;
begin
	inherited Create;
	mCtx := ParaCtx;

	try
		mNode := ParaMaker.MakeNode( mCtx );
		if mNode = nil then
		begin
			raise Exception.Create( 'Failed to make node in PluginDataNodeManager' );
		end;

		// single mode
		mNode.Config.Single := true;
		mNode.ViteConfig.Net.Single := true;

		// no miner
		mNode.Config.MinerEnabled := false;
		mNode.ViteConfig.Producer.Producer := false;

		// no ledger gc
		vLedgerGc := false;
		mNode.Config.SetLedgerGc( vLedgerGc );
		mNode.ViteConfig.Chain.LedgerGc := vLedgerGc;

		// open plugins
		vOpenPlugins := true;
		mNode.Config.SetOpenPlugins( vOpenPlugins );
		mNode.ViteConfig.Chain.OpenPlugins := vOpenPlugins;

	except
		on E : Exception do
		begin
			// Log or handle the exception
			raise Exception.Create( Format( 'Error creating PluginDataNodeManager: %s', [E.Message] ) );
		end;
	end;
end;

destructor TPluginDataNodeManager.Destroy;
begin
	mNode.Free;
	inherited Destroy;
end;

function TPluginDataNodeManager.GetNode : TNode;
begin
	Result := mNode;
end;

function TPluginDataNodeManager.Start : boolean;
var
	vChain : IChain;
	vError : string;
begin
	Result := TNodeManagerAssist.StartNode( mNode );
	if not Result then
	begin
		Exit;
	end;

	try
		vChain := mNode.Vite.Chain;
		if not vChain.Plugins.RebuildData( vError ) then
		begin
			Result := false;
			// Maybe log the error here
			Exit;
		end;
		Result := true;
	except
		on E : Exception do
		begin
			// Log the exception
			Result := false;
		end;
	end;
end;

function TPluginDataNodeManager.Stop : boolean;
begin
	TNodeManagerAssist.StopNode( mNode );
	Result := true;
end;

end.
