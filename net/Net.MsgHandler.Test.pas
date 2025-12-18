unit Net.MsgHandler.Test;

interface

uses
  Common.Types,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Snapshot.Block,
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
  Net.Mock.Chain,
  Net.Mock.Codec,
  Net.Mock.Net,
  Net.Mock.Receiver,
  Net.MsgHandler,
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
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

procedure Test_SplitAccountMap;
procedure Test_SplitAccountMap_Min;
procedure TestCheckHandler;

implementation

function RandInt( ParaM, ParaN : Integer ) : Integer;
begin
	Result := Random( ParaN - ParaM ) + ParaM;
end;

function MockHash : THash;
var
	vBytes : TBytes;
begin
	SetLength( vBytes, 32 );
	// Random.Read(vBytes);
	Result := THash.Create( vBytes );
end;

procedure Test_SplitAccountMap;
begin
	// mblocks, total := mockAccountMap(100, 1000, 100, 1000)
    // ...
end;

procedure Test_SplitAccountMap_Min;
begin
    // ...
end;

type
	TMockSnapshotReader = class(TInterfacedObject, ISnapshotReader)
	private
		mBlocksByHash : TDictionary<THash, TSnapshotBlock>;
		mBlocksByHeight : TDictionary<UInt64, TSnapshotBlock>;
	public
		constructor Create;
		destructor Destroy; override;
		function GetSnapshotBlockByHeight( ParaHeight : UInt64 ) : TSnapshotBlock;
		function GetSnapshotBlockByHash( ParaHash : THash ) : TSnapshotBlock;
		function GetSnapshotBlocks( ParaBlockHash : THash; ParaHigher : Boolean; ParaCount : UInt64 ) : TArray<TSnapshotBlock>;
		function GetSnapshotBlocksByHeight( ParaHeight : UInt64; ParaHigher : Boolean; ParaCount : UInt64 ) : TArray<TSnapshotBlock>;
	end;

constructor TMockSnapshotReader.Create;
begin
	inherited Create;
	mBlocksByHash := TDictionary<THash, TSnapshotBlock>.Create;
	mBlocksByHeight := TDictionary<UInt64, TSnapshotBlock>.Create;
end;

destructor TMockSnapshotReader.Destroy;
begin
	mBlocksByHash.Free;
	mBlocksByHeight.Free;
	inherited Destroy;
end;

function TMockSnapshotReader.GetSnapshotBlockByHeight( ParaHeight : UInt64 ) : TSnapshotBlock;
begin
	mBlocksByHeight.TryGetValue( ParaHeight, Result );
end;

function TMockSnapshotReader.GetSnapshotBlockByHash( ParaHash : THash ) : TSnapshotBlock;
begin
	mBlocksByHash.TryGetValue( ParaHash, Result );
end;

function TMockSnapshotReader.GetSnapshotBlocks( ParaBlockHash : THash; ParaHigher : Boolean; ParaCount : UInt64 ) : TArray<TSnapshotBlock>;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

function TMockSnapshotReader.GetSnapshotBlocksByHeight( ParaHeight : UInt64; ParaHigher : Boolean; ParaCount : UInt64 ) : TArray<TSnapshotBlock>;
begin
	raise ENotImplemented.Create( 'implement me' );
end;

procedure TestCheckHandler;
begin
    // ...
end;

end.
