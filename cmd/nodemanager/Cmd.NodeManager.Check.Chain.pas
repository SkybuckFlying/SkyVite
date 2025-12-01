unit Cmd.NodeManager.CheckChain;

interface

uses
	System.SysUtils,
	System.Classes,
	GoToDelphi.Dependencies.Cli,
	GoToDelphi.Helpers.Log15,
	Node.Node,
	Cmd.NodeManager.NodeMaker,
	Cmd.NodeManager.NodeManager;

type
	TCheckChainNodeManager = class( TInterfacedObject, INodeManager )
	private
		mCtx : TContext;
		mNode : TNode;
		mLog : ILog15;
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
	Cmd.NodeManager.Assist,
	Common,
	Ledger.Chain.Interfaces;

constructor TCheckChainNodeManager.Create( ParaCtx : TContext; ParaMaker : INodeMaker );
var
	vLedgerGc : boolean;
begin
	inherited Create;
	mCtx := ParaCtx;
	mLog := TLog15.New( 'module', 'checkChainCMD' );

	try
		mNode := ParaMaker.MakeNode( mCtx );
		if mNode = nil then
		begin
			// Exception will be raised by MakeNode on failure
			Exit;
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

	except
		on E : Exception do
		begin
			mLog.Error( Format( 'Failed to create CheckChainNodeManager: %s', [E.Message] ) );
			raise;
		end;
	end;
end;

destructor TCheckChainNodeManager.Destroy;
begin
	mNode.Free;
	inherited Destroy;
end;

function TCheckChainNodeManager.GetNode : TNode;
begin
	Result := mNode;
end;

function TCheckChainNodeManager.Start : boolean;
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
		Writeln( 'start check.' );

		// check recent blocks
		mLog.Info( 'start check recent blocks' );
		if not vChain.CheckRecentBlocks( vError ) then
		begin
			TCrit.Crit( vError, 'check_chain', 'recent_blocks' );
		end;
		mLog.Info( 'finish checking recent blocks' );
		Writeln( 'check recent blocks success.' );

		// check redo
		mLog.Info( 'start check redo' );
		if not vChain.CheckRedo( vError ) then
		begin
			TCrit.Crit( vError, 'check_chain', 'redo' );
		end;
		mLog.Info( 'finish checking redo' );
		Writeln( 'check redo success.' );

		// check onroad
		mLog.Info( 'start check onroad' );
		if not vChain.CheckOnRoad( vError ) then
		begin
			TCrit.Crit( vError, 'check_chain', 'onroad' );
		end;
		mLog.Info( 'finish checking onroad' );
		Writeln( 'check onroad success.' );

		Writeln( 'check success.' );
		Result := true;
	except
		on E : Exception do
		begin
			mLog.Error( Format( 'Error during chain check: %s', [E.Message] ) );
			Result := false;
		end;
	end;
end;

function TCheckChainNodeManager.Stop : boolean;
begin
	TNodeManagerAssist.StopNode( mNode );
	Result := true;
end;

end.