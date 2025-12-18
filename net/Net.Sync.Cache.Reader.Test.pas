unit Net.Sync.Cache.Reader.Test;

interface

uses
  Common.Types,
  Interfaces,
  Interfaces.Core.Hash.Height,
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
  Net.MsgHandler.Test,
  Net.Net,
  Net.Peer,
  Net.Peer.Error,
  Net.Peer.Test,
  Net.Skeleton,
  Net.Skeleton.Test,
  Net.Sync.Cache.Reader,
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

procedure TestChunkRead;
procedure TestChunkRead2;
procedure TestConstructTasks1;
procedure TestCompareCache;

implementation

function RandomHash : THash;
var
	vBytes : TBytes;
begin
	SetLength( vBytes, 32 );
	// Random.Read(vBytes);
	Result := THash.Create( vBytes );
end;

procedure TestChunkRead;
var
	vFrom, vTo : UInt64;
	vPrevHash, vHash, vEndHash : THash;
	vChunk : TChunk;
	vI : UInt64;
begin
	vFrom := 101;
	vTo := 200;
	vPrevHash := THash.Empty;
	vEndHash := THash.Empty;
	vChunk := TChunk.Create( vPrevHash, vFrom - 1, vEndHash, vTo, TBlockSource.RemoteSync );
	try
		for vI := vFrom to vTo do
		begin
			vHash := RandomHash;
			vChunk.AddSnapshotBlock( TSnapshotBlock.Create( vHash, vPrevHash, vI ) );
			vPrevHash := vHash;
		end;
	finally
		vChunk.Free;
	end;
end;

procedure TestChunkRead2;
var
	vFrom, vTo : UInt64;
	vPrevHash, vHash, vEndHash : THash;
	vChunk : TChunk;
begin
	vFrom := 101;
	vTo := 200;
	vPrevHash := THash.Empty;
	vEndHash := THash.Empty;
	vChunk := TChunk.Create( vPrevHash, vFrom - 1, vEndHash, vTo, TBlockSource.RemoteSync );
	try
		vHash := RandomHash;
		try
			vChunk.AddSnapshotBlock( TSnapshotBlock.Create( vHash, vPrevHash, vFrom + 1 ) );
			raise Exception.Create( 'error should not be nil' );
		except
			on E: Exception do ; // expected
		end;
	finally
		vChunk.Free;
	end;
end;

procedure TestConstructTasks1;
var
	vHhs : TList<THashHeightPoint>;
	vStart, vEnd, vStep, vI : UInt64;
	vHash, vStartHash : THash;
	vTs : TArray<TDownloadTask>;
	vPrevHeight : UInt64;
	vPrevHashVal : THash;
	vTT : TDownloadTask;
begin
	vHhs := TList<THashHeightPoint>.Create;
	try
		vStart := 100;
		vEnd := 10000;
		vStep := 100;
		vHash := RandomHash;
		vStartHash := vHash;

		vI := vStart;
		while vI <= vEnd do
		begin
			vHhs.Add( THashHeightPoint.Create( THashHeight.Create( vI, vHash ), UInt64( Random( 1 shl 19 ) ) + ( 1 shl 18 ) ) );
			vHash := RandomHash;
			Inc( vI, vStep );
		end;

		vTs := ConstructTasks( vHhs.ToArray );

		vPrevHeight := vStart;
		vPrevHashVal := vStartHash;
		for vTT in vTs do
		begin
			if vTT.ToVal <= vTT.From then Raise Exception.Create('wrong start and end');
			if ( vTT.PrevHash <> vPrevHashVal ) or ( vTT.From <> vPrevHeight + 1 ) then Raise Exception.Create('not continuous');
			
			vPrevHeight := vTT.ToVal;
			vPrevHashVal := vTT.Hash;
		end;
	finally
		vHhs.Free;
	end;
end;

procedure TestCompareCache;
type
	TUseCase = record
		Segments : ISegmentList;
		HashHeightList : TArray<THashHeightPoint>;
		ResultSegments : ISegmentList;
		DeletedSegments : TArray<Integer>;
	end;
var
	vUseCases : TArray<TUseCase>;
	vCase : TUseCase;
begin
	// complex test cases...
end;

end.
