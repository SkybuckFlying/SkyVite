unit Cmd.NodeManager.ExportNodeManager;

interface

uses
  Cmd.NodeManager.Assist,
  Cmd.NodeManager.Check.Chain,
  Cmd.NodeManager.Default.Node.Manager,
  Cmd.NodeManager.Full.Node.Maker,
  Cmd.NodeManager.Local.Node.Maker,
  Cmd.NodeManager.Node.Maker,
  Cmd.NodeManager.Node.Manager,
  Cmd.NodeManager.NodeMaker,
  Cmd.NodeManager.Plugin.Data.Node.Manager,
  Cmd.NodeManager.Recover.Node.Manager,
  Cmd.NodeManager.SubCmd.Node.Manager,
  GoToDelphi.Dependencies.Cli,
  GoToDelphi.Helpers.BigInt,
  Node.Node,
  System.Classes;

type
	TExportNodeManager = class(TInterfacedObject, INodeManager)
	private
		mCtx : TContext;
		mNode : TNode;
		function GetSbHeight : UInt64;
		function GetNode: TNode;
	public
		constructor Create( ParaCtx : TContext; ParaMaker : INodeMaker );
		destructor Destroy; override;
		function Start : boolean;
		function Stop: boolean;
		property Node: TNode read GetNode;
	end;

var
	digits : TBigInt;

implementation

uses
	System.SysUtils,
	Cmd.Utils.Flags;

constructor TExportNodeManager.Create( ParaCtx : TContext; ParaMaker : INodeMaker );
var
	vLedgerGc : boolean;
begin
	inherited Create;
	mCtx := ParaCtx;

	try
		mNode := ParaMaker.MakeNode( mCtx );
		if mNode = nil then
		begin
			raise Exception.Create( 'Failed to make node in ExportNodeManager' );
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
			// In a real scenario, log this error.
			raise Exception.Create( Format( 'Error creating ExportNodeManager: %s', [E.Message] ) );
		end;
	end;
end;

destructor TExportNodeManager.Destroy;
begin
	mNode.Free;
	inherited Destroy;
end;

function TExportNodeManager.GetSbHeight : UInt64;
begin
	Result := 0;
	if mCtx.GlobalIsSet( ExportSbHeightFlags.Name ) then
	begin
		Result := mCtx.GlobalUint64( ExportSbHeightFlags.Name );
	end;
end;

function TExportNodeManager.Start : boolean;
begin
	// The original Go code for this function is empty.
	Result := true;
end;

function TExportNodeManager.Stop: boolean;
begin
  Result := true;
end;

function TExportNodeManager.GetNode: TNode;
begin
  Result := mNode;
end;

initialization
	digits := TBigInt.NewString( '1000000000000000000' );
end.
