unit Cmd.NodeManager.RecoverNodeManager;

interface

uses
	System.Classes,
	GoToDelphi.Dependencies.Cli,
	Cmd.NodeManager.NodeManager,
	Cmd.NodeManager.NodeMaker,
	Node.Node,
	Ledger.Chain.Interfaces;

const
	ConstCountPerDelete = 10000;

type
	TRecoverNodeManager = class( TInterfacedObject, INodeManager )
	private
		mCtx : TContext;
		mNode : TNode;
		mChain : IChain;
		function GetNode : TNode;
		function GetDeleteToHeight : UInt64;
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
	Cmd.Utils.Flags,
	Common.Upgrade,
	Ledger.Chain.Chain,
	Node.Config,
	Common.DB.XLevelDB.Errors;

{ TRecoverNodeManager }

constructor TRecoverNodeManager.Create( ParaCtx : TContext; ParaMaker : INodeMaker );
begin
	inherited Create;
	mCtx := ParaCtx;
	try
		mNode := ParaMaker.MakeNode( mCtx );
		if mNode = nil then
		begin
			raise Exception.Create( 'Failed to make node in RecoverNodeManager' );
		end;
	except
		on E : Exception do
		begin
			raise Exception.Create( Format( 'Error creating RecoverNodeManager: %s', [E.Message] ) );
		end;
	end;
end;

destructor TRecoverNodeManager.Destroy;
begin
	mNode.Free;
	inherited Destroy;
end;

function TRecoverNodeManager.GetDeleteToHeight : UInt64;
begin
	Result := 0;
	if mCtx.GlobalIsSet( LedgerDeleteToHeight.Name ) then
	begin
		Result := mCtx.GlobalUint64( LedgerDeleteToHeight.Name );
	end;
end;

function TRecoverNodeManager.GetNode : TNode;
begin
	Result := mNode;
end;

function TRecoverNodeManager.Start : boolean;
var
	vViteConfig : TViteConfig;
	vDataDir : string;
	vChainCfg : TChainConfig;
	vGenesisCfg : TGenesisConfig;
	vDeleteToHeight : UInt64;
	vError : string;
begin
	Result := false;
	try
		vViteConfig := mNode.ViteConfig;
		vDataDir := vViteConfig.DataDir;
		vChainCfg := vViteConfig.Chain;
		vGenesisCfg := vViteConfig.Genesis;

		// set upgrade
		TUpgrade.InitUpgradeBox( vGenesisCfg.UpgradeCfg.MakeUpgradeBox );

		mChain := TChain.Create( vDataDir, vChainCfg, vGenesisCfg );

		if not mChain.Init( vError ) then
		begin
			raise Exception.Create( vError );
		end;

		if not mChain.Start( vError ) then
		begin
			raise Exception.Create( vError );
		end;

		vDeleteToHeight := GetDeleteToHeight;

		if vDeleteToHeight <= 0 then
		begin
			raise ELevelDBException.Create( 'deleteToHeight is 0.' );
		end;

		Writeln( Format( 'Latest snapshot block height is %d', [mChain.GetLatestSnapshotBlock.Height] ) );
		Writeln( Format( 'Delete target height is %d', [vDeleteToHeight] ) );
		Writeln( Format( 'Start deleting, don''t shut down. View the deletion process through the log in %s', [vViteConfig.RunLogDir] ) );

		if not mChain.DeleteSnapshotBlocksToHeight(vDeleteToHeight, vError) then
		begin
			Writeln(Format('Delete to %d height failed. error is ' + vError, [vDeleteToHeight]));
			Exit;
		end;

		// TODO: Implement TrieGc logic
		{
			if not c.TrieGc.Check(checkResult, checkErr) then
			begin
				Writeln(Format('Check trie failed! error is %s', [checkErr]));
			end
			else if not checkResult then
			begin
				Writeln('Rebuild data...');
				if not c.TrieGc.Recover(err) then
				begin
					Writeln(Format('Rebuild data failed! error is %s', [err]));
				end
				else
				begin
					Writeln('Rebuild data successed!');
				end;
			end;
		}

		Writeln(Format('Latest snapshot block height is %d', [mChain.GetLatestSnapshotBlock.Height]));
		Result := true;
	except
		on E : Exception do
		begin
			// Log error
			Writeln(E.Message);
		end;
	end;
end;

function TRecoverNodeManager.Stop : boolean;
begin
	if Assigned( mChain ) then
	begin
		mChain.Stop;
	end;
	Result := true;
end;

end.
