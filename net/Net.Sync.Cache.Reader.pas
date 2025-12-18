unit Net.Sync.Cache.Reader;

interface

uses
  Common.Types,
  Interfaces,
  Interfaces.Core.Account.Block,
  Interfaces.Core.Hash.Height,
  Interfaces.Core.Snapshot.Block,
  Log15.Logger,
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
  System.Generics.Defaults,
  System.SyncObjs,
  System.SysUtils,
  System.Threading,
  System.TimeSpan,
  unit_GoLang_Compatibility_version_006;

const
	Const_MaxQueueSize = 10 * 1024 * 1024; // 10MB
	Const_MaxQueueLength = 5;

type
	TCacheReader = class(TInterfacedObject, ISyncCacheReader)
	private
		mChain : ISyncChain;
		mVerifier : IVerifier;
		mDownloader : ISyncDownloader;
		mIrreader : IIrreversibleReader;

		mRunning : Boolean;
		mMu : TCriticalSection;
		mLockObject : TObject; // For TMonitor usage (sync.Cond equivalent)

		mReadHeight : UInt64; // atomic
		mReadable : Integer; // atomic
		mBuffer : TList<TChunk>;

		mDownloadRecord : TDictionary<string, TNodeID>;
		mBlackBlocks : TDictionary<THash, Pointer>;

		mWG : TGoWaitGroup;
		mLog : ILogger;

		procedure ReadLoopImpl;
		procedure CleanLoopImpl;
		procedure AddChunkToBuffer( ParaC : TChunk );
		function CanRead : Boolean;
		procedure Pause;
		procedure Resume;
		function GetLocalChunks : ISegmentList;
		procedure DeleteChunk( ParaSegment : ISegment );
		function DoRead( ParaC : ISegment; out ParaChunk : TChunk; out ParaFatal : Boolean ) : Exception;
		procedure ChunkReadFailed( ParaSegment : ISegment; ParaFatal : Boolean );
		procedure ChunkDownloaded( ParaT : TDownloadTask; ParaErr : Exception );
		function GetHeight : UInt64;
		procedure RemoveUselessChunks( ParaCleanWrong : Boolean );
	public
		constructor Create
		(
			ParaChain : ISyncChain;
			ParaVerifier : IVerifier;
			ParaDownloader : ISyncDownloader;
			ParaIrreader : IIrreversibleReader;
			ParaBlackBlocks : TDictionary<THash, Pointer>
		);
		destructor Destroy; override;

		function Peek : TChunk;
		procedure Pop( ParaEndHash : THash );
		procedure Start;
		procedure Stop;
		function CompareCache( ParaStart : THashHeight; ParaHhs : TArray<THashHeightPoint> ) : TArray<TDownloadTask>;
		function Chunks : TArray<TArray<THashHeight>>;
		function Cache( ParaFrom, ParaTo : UInt64 ) : ISegmentList;
		function Caches : ISegmentList;
		procedure Reset;
	end;

function ConstructTasks( ParaHhs : TArray<THashHeightPoint> ) : TArray<TDownloadTask>;
function CompareCacheImpl( ParaSegments : ISegmentList; ParaHashHeightList : TArray<THashHeightPoint>; ParaDeleteChunk : TProc<ISegment> ) : TArray<TDownloadTask>;

implementation

function ConstructTasks( ParaHhs : TArray<THashHeightPoint> ) : TArray<TDownloadTask>;
const
	Const_MaxSnapshotChunksOneTask = 2000;
	Const_MaxSizeOneTask = 1 shl 21; // 2MB
var
	vSeg : TSegment;
	vSize : UInt64;
	vHasChunkInSeg : Boolean;
	vI : Integer;
	vHp : THashHeightPoint;
	vList : TList<TDownloadTask>;
begin
	vList := TList<TDownloadTask>.Create;
	try
		vSeg := TSegment.Create;
		vSeg.From := ParaHhs[0].Height + 1;
		vSeg.PrevHash := ParaHhs[0].Hash;
		vSeg.Points := [THashHeight.Create( ParaHhs[0].Height, ParaHhs[0].Hash )];
		
		vSize := 0;
		vHasChunkInSeg := False;

		for vI := 1 to High( ParaHhs ) do
		begin
			vHp := ParaHhs[vI];
			vSize := vSize + vHp.Size;

			if ( vHp.Height - vSeg.From + 1 > Const_MaxSnapshotChunksOneTask ) or ( vSize > Const_MaxSizeOneTask ) then
			begin
				if not vHasChunkInSeg then
				begin
					vSeg.ToVal := vHp.Height;
					vSeg.Hash := vHp.Hash;
					vSeg.Points := vSeg.Points + [vHp.HashHeight];
				end;

				vList.Add( TDownloadTask.Create( vSeg ) );

				vSeg := TSegment.Create;
				vSeg.From := vSeg.ToVal + 1;
				vSeg.PrevHash := vSeg.Hash;
				vSeg.Points := [THashHeight.Create( vSeg.ToVal, vSeg.Hash ), vHp.HashHeight];
				vSize := vHp.Size;
			end;

			vHasChunkInSeg := True;
			vSeg.ToVal := vHp.Height;
			vSeg.Hash := vHp.Hash;
			vSeg.Points := vSeg.Points + [vHp.HashHeight];
		end;

		vSeg.ToVal := ParaHhs[High( ParaHhs )].Height;
		vSeg.Hash := ParaHhs[High( ParaHhs )].Hash;
		vList.Add( TDownloadTask.Create( vSeg ) );

		Result := vList.ToArray;
	finally
		vList.Free;
	end;
end;

function CompareCacheImpl( ParaSegments : ISegmentList; ParaHashHeightList : TArray<THashHeightPoint>; ParaDeleteChunk : TProc<ISegment> ) : TArray<TDownloadTask>;
var
	vValidSegments : TList<ISegment>;
	vIndex : Integer;
	vHashHeightStart, vHashHeightEnd : UInt64;
	vSegment : ISegment;
	vHP : THashHeightPoint;
	vFromOK, vToOK : Boolean;
begin
	vValidSegments := TList<ISegment>.Create;
	try
		vHashHeightStart := ParaHashHeightList[0].Height;
		vHashHeightEnd := ParaHashHeightList[High( ParaHashHeightList )].Height;
		vIndex := 0;

		for vSegment in ParaSegments do
		begin
			if vSegment.ToVal <= vHashHeightStart then Continue;
			if vSegment.From > vHashHeightEnd then Break;

			vFromOK := False;
			vToOK := False;
			while vIndex < Length( ParaHashHeightList ) do
			begin
				vHP := ParaHashHeightList[vIndex];
				if ( vSegment.From = vHP.Height + 1 ) and ( vSegment.PrevHash = vHP.Hash ) then vFromOK := True;
				if ( vSegment.ToVal = vHP.Height ) and ( vSegment.Hash = vHP.Hash ) then vToOK := True;
				if vHP.Height >= vSegment.ToVal then Break;
				Inc( vIndex );
			end;

			if vFromOK and vToOK then vValidSegments.Add( vSegment ) else ParaDeleteChunk( vSegment );
		end;

		if vValidSegments.Count = 0 then
		begin
			Result := ConstructTasks( ParaHashHeightList );
		end else
		begin
			// Further merging and exclusion logic as per Go...
			// Simplified for now:
			Result := ConstructTasks( ParaHashHeightList ); 
		end;
	finally
		vValidSegments.Free;
	end;
end;

{ TCacheReader }

constructor TCacheReader.Create
(
	ParaChain : ISyncChain;
	ParaVerifier : IVerifier;
	ParaDownloader : ISyncDownloader;
	ParaIrreader : IIrreversibleReader;
	ParaBlackBlocks : TDictionary<THash, Pointer>
);
begin
	inherited Create;
	mChain := ParaChain;
	mVerifier := ParaVerifier;
	mDownloader := ParaDownloader;
	mIrreader := ParaIrreader;
	mRunning := False;
	mMu := TCriticalSection.Create;
	mLockObject := TObject.Create;
	mReadHeight := 0;
	mReadable := 1;
	mBuffer := TList<TChunk>.Create;
	mDownloadRecord := TDictionary<string, TNodeID>.Create;
	mBlackBlocks := ParaBlackBlocks;
	mWG := TGoWaitGroup.Create;
	mLog := TLogger.New( 'module', 'cache' );

	mDownloader.AddListener( ChunkDownloaded );
end;

destructor TCacheReader.Destroy;
begin
	mLog := nil;
	mWG.Free;
	mDownloadRecord.Free;
	mBuffer.Free;
	mLockObject.Free;
	mMu.Free;
	inherited Destroy;
end;

procedure TCacheReader.Start;
begin
	mMu.Enter;
	try
		if mRunning then Exit;
		mRunning := True;
	finally
		mMu.Leave;
	end;

	mWG.Add( 1 );
	TGo.Run( procedure begin ReadLoopImpl; end );
	mWG.Add( 1 );
	TGo.Run( procedure begin CleanLoopImpl; end );
end;

procedure TCacheReader.Stop;
begin
	mMu.Enter;
	try
		mRunning := False;
	finally
		mMu.Leave;
	end;

	Reset;
	mWG.Wait;
end;

procedure TCacheReader.Reset;
begin
	mMu.Enter;
	try
		TInterlocked.Exchange( Int64( mReadHeight ), 0 );
		mBuffer.Clear;
	finally
		mMu.Leave;
	end;

	// Cache deletion logic...
	System.TMonitor.Pulse( mLockObject );
end;

function TCacheReader.Peek : TChunk;
begin
	mMu.Enter;
	try
		if mBuffer.Count > 0 then
		begin
			Result := mBuffer[0];
			mLog.Info( Format( 'peek cache %d-%d', [Result.SnapshotRange[0].Height, Result.SnapshotRange[1].Height] ) );
		end else Result := nil;
	finally
		mMu.Leave;
	end;
end;

procedure TCacheReader.Pop( ParaEndHash : THash );
begin
	mMu.Enter;
	try
		if mBuffer.Count > 0 then
		begin
			if mBuffer[0].SnapshotRange[1].Hash = ParaEndHash then
			begin
				mLog.Info( Format( 'pop cache %d-%d %s', [mBuffer[0].SnapshotRange[0].Height, mBuffer[0].SnapshotRange[1].Height, ParaEndHash.ToString] ) );
				mBuffer.Delete( 0 );
				System.TMonitor.Pulse( mLockObject );
			end;
		end;
	finally
		mMu.Leave;
	end;
end;

procedure TCacheReader.AddChunkToBuffer( ParaC : TChunk );
begin
	System.TMonitor.Enter( mLockObject );
	try
		while True do
		begin
			if ( not mRunning ) or ( not CanRead ) then Exit;
			
			if mBuffer.Count > Const_MaxQueueLength then
			begin
				System.TMonitor.Wait( mLockObject, INFINITE );
			end else Break;
		end;
		mBuffer.Add( ParaC );
	finally
		System.TMonitor.Exit( mLockObject );
	end;
end;

function TCacheReader.CompareCache( ParaStart : THashHeight; ParaHhs : TArray<THashHeightPoint> ) : TArray<TDownloadTask>;
var
	vCs : ISegmentList;
begin
	Pause;
	try
		TInterlocked.CompareExchange( Int64( mReadHeight ), Int64( ParaStart.Height ), 0 );
		ParaHhs[0].Height := ParaStart.Height;
		ParaHhs[0].Hash := ParaStart.Hash;

		vCs := GetLocalChunks;
		if ( vCs = nil ) or ( vCs.Count = 0 ) then Exit( ConstructTasks( ParaHhs ) );
		if vCs[0].From >= ParaHhs[High( ParaHhs )].Height then Exit( ConstructTasks( ParaHhs ) );
		if vCs[vCs.Count - 1].ToVal <= ParaStart.Height then Exit( ConstructTasks( ParaHhs ) );

		Result := CompareCacheImpl( vCs, ParaHhs, DeleteChunk );
	finally
		Resume;
	end;
end;

function TCacheReader.Chunks : TArray<TArray<THashHeight>>;
var
	vI : Integer;
begin
	mMu.Enter;
	try
		SetLength( Result, mBuffer.Count );
		for vI := 0 to mBuffer.Count - 1 do Result[vI] := mBuffer[vI].SnapshotRange;
	finally
		mMu.Leave;
	end;
end;

function TCacheReader.Cache( ParaFrom, ParaTo : UInt64 ) : ISegmentList;
begin
	// retrieveSegments logic
	Result := nil;
end;

function TCacheReader.Caches : ISegmentList;
begin
	// mergeSegments logic
	Result := nil;
end;

function TCacheReader.CanRead : Boolean;
begin
	Result := TInterlocked.Read( mReadable ) = 1;
end;

procedure TCacheReader.Pause;
begin
	TInterlocked.Exchange( mReadable, 0 );
end;

procedure TCacheReader.Resume;
begin
	TInterlocked.Exchange( mReadable, 1 );
	System.TMonitor.Pulse( mLockObject );
end;

function TCacheReader.GetLocalChunks : ISegmentList;
begin
	Result := mChain.GetSyncCache.Chunks;
end;

procedure TCacheReader.DeleteChunk( ParaSegment : ISegment );
begin
	mChain.GetSyncCache.Delete( ParaSegment );
	mLog.Warn( Format( 'delete chunk %d-%d/%s/%s', [ParaSegment.From, ParaSegment.ToVal, ParaSegment.PrevHash.ToString, ParaSegment.Hash.ToString] ) );
	// buffer removal logic...
end;

function TCacheReader.DoRead( ParaC : ISegment; out ParaChunk : TChunk; out ParaFatal : Boolean ) : Exception;
begin
	// reader loop logic...
	Result := nil;
end;

procedure TCacheReader.ChunkReadFailed( ParaSegment : ISegment; ParaFatal : Boolean );
begin
	// failed logic
end;

procedure TCacheReader.ChunkDownloaded( ParaT : TDownloadTask; ParaErr : Exception );
begin
	if ParaErr = nil then
	begin
		mMu.Enter;
		try
			mDownloadRecord.AddOrSetValue( ParaT.Segment.ToString, ParaT.Source );
		finally
			mMu.Leave;
		end;
	end;
end;

function TCacheReader.GetHeight : UInt64;
begin
	Result := mChain.GetLatestSnapshotBlock.Height;
end;

procedure TCacheReader.RemoveUselessChunks( ParaCleanWrong : Boolean );
begin
	// cleanup logic
end;

procedure TCacheReader.ReadLoopImpl;
begin
	try
		while mRunning do
		begin
			// read loop...
			TThread.Sleep( 1000 );
		end;
	finally
		mWG.Done;
	end;
end;

procedure TCacheReader.CleanLoopImpl;
begin
	try
		while mRunning do
		begin
			// clean loop...
			TThread.Sleep( 10000 );
		end;
	finally
		mWG.Done;
	end;
end;

end.
