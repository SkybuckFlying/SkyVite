unit Net.Mock.Chain;

interface

uses
  Common.Types,
  Interfaces.Chain,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Snapshot.Block,
  Interfaces.Ledger.Reader,
  Net.Block.Feed,
  Net.Block.Feed.Test,
  Net.Broadcaster,
  Net.Broadcaster.Test,
  Net.Codec,
  Net.Codec.Test,
  Net.Fetcher,
  Net.Fetcher.Test,
  Net.Finder,
  Net.Handshaker,
  Net.Handshaker.Test,
  Net.Interface,
  Net.Message,
  Net.Message.Test,
  Net.Mock.Codec,
  Net.Mock.Net,
  Net.Mock.Receiver,
  Net.MsgHandler,
  Net.MsgHandler.Test,
  Net.Net,
  Net.Peer,
  Net.Peer.Error,
  Net.Peer.Test,
  Net.Skeleton,
  Net.Skeleton.Test,
  Net.Sync.Cache.Reader,
  Net.Sync.Cache.Reader.Test,
  Net.Sync.Conn,
  Net.Sync.Conn.Test,
  Net.Sync.Downloader,
  Net.Sync.Downloader.Test,
  Net.Sync.Server,
  Net.Sync.Server.Test,
  Net.Sync.State,
  Net.Sync.State.Test,
  Net.Syncer,
  Net.Syncer.Test,
  System.SysUtils;

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
