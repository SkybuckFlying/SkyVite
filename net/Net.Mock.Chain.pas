unit Net.Mock.Chain;

interface

uses
	System.SysUtils,
	Common.Types,
	Interfaces.Chain,
	Interfaces.Core.Snapshot.Block,
	Interfaces.Core.Account.Block,
	Interfaces.Ledger.Reader;

type
	TMockChain = class(TInterfacedObject, IChain)
	private
		mHeight : UInt64;
	public
		constructor Create( ParaHeight : UInt64 );

		function GetSnapshotBlockByHeight( ParaHeight : UInt64 ) : TSnapshotBlock;
		function GetSnapshotBlockByHash( ParaHash : THash ) : TSnapshotBlock;
		function GetSnapshotBlocks( ParaBlockHash : THash; ParaHigher : Boolean; ParaCount : UInt64 ) : TArray<TSnapshotBlock>;
		function GetSnapshotBlocksByHeight( ParaHeight : UInt64; ParaHigher : Boolean; ParaCount : UInt64 ) : TArray<TSnapshotBlock>;
		function GetAccountBlockByHeight( ParaAddr : TAddress; ParaHeight : UInt64 ) : TAccountBlock;
		function GetAccountBlockByHash( ParaBlockHash : THash ) : TAccountBlock;
		function GetAccountBlocks( ParaBlockHash : THash; ParaCount : UInt64 ) : TArray<TAccountBlock>;
		function GetAccountBlocksByHeight( ParaAddr : TAddress; ParaHeight : UInt64; ParaCount : UInt64 ) : TArray<TAccountBlock>;
		function GetLatestSnapshotBlock : TSnapshotBlock;
		function GetGenesisSnapshotBlock : TSnapshotBlock;
		function GetLedgerReaderByHeight( ParaStartHeight : UInt64; ParaEndHeight : UInt64 ) : ILedgerReader;
		function GetSyncCache : ISyncCache;
	end;

implementation

{ TMockChain }

constructor TMockChain.Create( ParaHeight : UInt64 );
begin
	inherited Create;
	mHeight := ParaHeight;
end;

function TMockChain.GetSnapshotBlockByHeight( ParaHeight : UInt64 ) : TSnapshotBlock;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockChain.GetSnapshotBlockByHash( ParaHash : THash ) : TSnapshotBlock;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockChain.GetSnapshotBlocks( ParaBlockHash : THash; ParaHigher : Boolean; ParaCount : UInt64 ) : TArray<TSnapshotBlock>;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockChain.GetSnapshotBlocksByHeight( ParaHeight : UInt64; ParaHigher : Boolean; ParaCount : UInt64 ) : TArray<TSnapshotBlock>;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockChain.GetAccountBlockByHeight( ParaAddr : TAddress; ParaHeight : UInt64 ) : TAccountBlock;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockChain.GetAccountBlockByHash( ParaBlockHash : THash ) : TAccountBlock;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockChain.GetAccountBlocks( ParaBlockHash : THash; ParaCount : UInt64 ) : TArray<TAccountBlock>;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockChain.GetAccountBlocksByHeight( ParaAddr : TAddress; ParaHeight : UInt64; ParaCount : UInt64 ) : TArray<TAccountBlock>;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockChain.GetLatestSnapshotBlock : TSnapshotBlock;
var
	vHash : THash;
begin
	Result := TSnapshotBlock.Create;
	vHash := THash.Create( [1, 1, 1] );
	Result.Hash := vHash;
	Result.Height := mHeight;
end;

function TMockChain.GetGenesisSnapshotBlock : TSnapshotBlock;
var
	vHash : THash;
begin
	Result := TSnapshotBlock.Create;
	vHash := THash.Create( [1, 0, 0] );
	Result.Hash := vHash;
	Result.Height := 1;
end;

function TMockChain.GetLedgerReaderByHeight( ParaStartHeight : UInt64; ParaEndHeight : UInt64 ) : ILedgerReader;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockChain.GetSyncCache : ISyncCache;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

end.
