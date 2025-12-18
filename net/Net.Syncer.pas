unit Net.Syncer;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	System.SyncObjs,
	System.TimeSpan,
	System.Threading,
	Common.Types,
	Interfaces,
	Interfaces.Core.Snapshot.Block,
	Interfaces.Core.Hash.Height,
	Log15.Logger,
	Net.Interface,
	unit_GoLang_Compatibility_version_006;

const
	Const_MinHeightDifference = 100;
	Const_WaitEnoughPeers = 5000; // ms
	Const_EnoughPeers = 3;
	Const_CheckChainInterval = 1000;
	Const_SyncTaskSize = 100;
	Const_MaxBatchChunkSize = 500 * Const_SyncTaskSize;

type
	TSyncer = class(TInterfacedObject, ISyncer)
	private
		mSbp : Boolean;
		mSyncing : Integer; // atomic
		mFrom, mTo : UInt64;
		mState : ISyncState;
		mTimeout : TTimeSpan;
		mPeers : TPeerSet;
		mEventChan : TGoChannel<TPeerEvent>;
		mTaskCanceled : Integer; // atomic
		mSk : TSkeleton;
		mSyncWG : TGoWaitGroup;
		mChain : ISyncChain;
		mDownloader : ISyncDownloader;
		mReader : ISyncCacheReader;
		mIrreader : IIrreversibleReader;
		mCurSubId : Integer;
		mSubs : TDictionary<Integer, TSyncStateCallback>;
		mMu : TCriticalSection;
		mRunning : Integer; // atomic
		mTerm : TGoChannel<Integer>;
		mLog : ILogger;

		function GetHeight : UInt64;
		function GetInitStart : TArray<THashHeight>;
		function GetEnd( ParaStart : TArray<THashHeight> ) : UInt64;
		function GetHashHeightList( ParaStart : TArray<THashHeight>; ParaEnd : UInt64 ) : TArray<THashHeightPoint>;
		function VerifyHashHeightList( ParaStart : TArray<THashHeight>; ParaPoints : TArray<THashHeightPoint> ) : THashHeight;
		
		function DoSync : Boolean;
		procedure DownloadLoop( ParaPoint : THashHeight; ParaEnd : UInt64; ParaPoints : TArray<THashHeightPoint> );
		procedure StartSync;
		procedure StopSync;
	public
		constructor Create
		(
			ParaChain : ISyncChain;
			ParaPeers : TPeerSet;
			ParaReader : ISyncCacheReader;
			ParaDownloader : ISyncDownloader;
			ParaIrreader : IIrreversibleReader;
			ParaTimeout : TTimeSpan;
			ParaBlackBlocks : TDictionary<THash, Pointer>
		);
		destructor Destroy; override;

		function Peek : TChunk;
		procedure Pop( ParaEndHash : THash );
		
		function SubscribeSyncStatus( ParaFn : TSyncStateCallback ) : Integer;
		procedure UnsubscribeSyncStatus( ParaSubId : Integer );
		function GetSyncState : TSyncState;
		procedure SetSyncState( ParaState : ISyncState );
		
		function Status : TSyncStatus;
		function Detail : TSyncDetail;

		procedure Stop;
		procedure Start;
		function Handle( ParaMsg : IMsg ) : Boolean;
	end;

function ShouldSync( ParaFrom, ParaTo : UInt64 ) : Boolean;

implementation

function ShouldSync( ParaFrom, ParaTo : UInt64 ) : Boolean;
begin
	Result := ParaTo >= ParaFrom + Const_MinHeightDifference;
end;

{ TSyncer }

constructor TSyncer.Create
(
	ParaChain : ISyncChain;
	ParaPeers : TPeerSet;
	ParaReader : ISyncCacheReader;
	ParaDownloader : ISyncDownloader;
	ParaIrreader : IIrreversibleReader;
	ParaTimeout : TTimeSpan;
	ParaBlackBlocks : TDictionary<THash, Pointer>
);
begin
	inherited Create;
	mSbp := False;
	mSyncing := 0;
	mFrom := 0;
	mTo := 0;
	mState := nil;
	mTimeout := ParaTimeout;
	mPeers := ParaPeers;
	mEventChan := TGoChannel<TPeerEvent>.Create( 1 );
	mTaskCanceled := 0;
	mSk := TSkeleton.Create( ParaPeers, TGid.Create, ParaBlackBlocks );
	mSyncWG := TGoWaitGroup.Create;
	mChain := ParaChain;
	mDownloader := ParaDownloader;
	mReader := ParaReader;
	mIrreader := ParaIrreader;
	mCurSubId := 0;
	mSubs := TDictionary<Integer, TSyncStateCallback>.Create;
	mMu := TCriticalSection.Create;
	mRunning := 0;
	mTerm := TGoChannel<Integer>.Create;
	mLog := TLogger.New( 'module', 'syncer' );

	mState := TSyncStateInit.Create( Self );
end;

destructor TSyncer.Destroy;
begin
	mSubs.Free;
	mMu.Free;
	mSk.Free;
	mSyncWG.Free;
	mEventChan.Free;
	mTerm.Free;
	inherited Destroy;
end;

function TSyncer.Peek : TChunk;
begin
	if mReader = nil then
	begin
		Result := nil;
		Exit;
	end;
	Result := mReader.Peek;
end;

procedure TSyncer.Pop( ParaEndHash : THash );
begin
	if mReader <> nil then
	begin
		mReader.Pop( ParaEndHash );
	end;
end;

function TSyncer.Handle( ParaMsg : IMsg ) : Boolean;
begin
	Result := True;
	case ParaMsg.Code of
		CodeHashList:
		begin
			mLog.Info( Format( 'receive HashHeightList from %s', [ParaMsg.Sender.ToString] ) );
			mSk.ReceiveHashList( ParaMsg, ParaMsg.Sender );
		end;
	end;
end;

function TSyncer.SubscribeSyncStatus( ParaFn : TSyncStateCallback ) : Integer;
begin
	mMu.Enter;
	try
		Inc( mCurSubId );
		mSubs.Add( mCurSubId, ParaFn );
		Result := mCurSubId;
	finally
		mMu.Leave;
	end;
end;

procedure TSyncer.UnsubscribeSyncStatus( ParaSubId : Integer );
begin
	mMu.Enter;
	try
		mSubs.Remove( ParaSubId );
	finally
		mMu.Leave;
	end;
end;

function TSyncer.GetSyncState : TSyncState;
begin
	Result := mState.State;
end;

procedure TSyncer.SetSyncState( ParaState : ISyncState );
var
	vSubs : TArray<TSyncStateCallback>;
	vSub : TSyncStateCallback;
	vIndex : Integer;
begin
	mState := ParaState;

	mMu.Enter;
	try
		SetLength( vSubs, mSubs.Count );
		vIndex := 0;
		for vSub in mSubs.Values do
		begin
			vSubs[vIndex] := vSub;
			Inc( vIndex );
		end;
	finally
		mMu.Leave;
	end;

	for vSub in vSubs do
	begin
		vSub( mState.State );
	end;
end;

procedure TSyncer.Start;
begin
	if TInterlocked.CompareExchange( mRunning, 1, 0 ) <> 0 then
	begin
		Exit;
	end;

	TGo.Run( procedure begin StartSync; end );
end;

procedure TSyncer.StartSync;
var
	vEvent : TPeerEvent;
	vStartTime : Cardinal;
	vSyncPeer : TPeer;
	vCurrent : UInt64;
	vRetrySync : Integer;
	vLastCheckTime : TDateTime;
	vOldHeight : UInt64;
begin
	mTerm.Free;
	mTerm := TGoChannel<Integer>.Create;
	
	mPeers.Sub( mEventChan );
	try
		if mPeers.Count < Const_EnoughPeers then
		begin
			vStartTime := TThread.GetTickCount;
			while True do
			begin
				if mEventChan.Receive( vEvent, 100 ) then
				begin
					if vEvent.Count >= Const_EnoughPeers then Break;
				end;
				
				if TThread.GetTickCount - vStartTime > Const_WaitEnoughPeers then Break;
				
				if mTerm.IsClosed then
				begin
					mState.Cancel;
					Exit;
				end;
			end;
		end;

		vRetrySync := 0;
label Prepare;
		vSyncPeer := mPeers.SyncPeer;
		if vSyncPeer = nil then
		begin
			mLog.Error( 'sync error: no peers' );
			mState.Error( syncErrorNoPeers );
			Exit;
		end;

		vCurrent := GetHeight;
		if not ShouldSync( vCurrent, vSyncPeer.Height ) then
		begin
			mLog.Info( Format( 'sync done: syncPeer %s at %d, our height: %d', [vSyncPeer.ToString, vSyncPeer.Height, vCurrent] ) );
			mState.Done;
			Exit;
		end;

		mFrom := vCurrent + 1;
		mTo := vSyncPeer.Height;

		if DoSync then
		begin
			mState.Sync;
			mLog.Info( Format( 'syncing: local %d to %d', [vCurrent, vSyncPeer.Height] ) );
		end else
		begin
			mLog.Warn( Format( 'failed to sync local %d to %d', [vCurrent, vSyncPeer.Height] ) );
			Exit;
		end;

		vLastCheckTime := Now;
		vOldHeight := vCurrent;

		while True do
		begin
			if mEventChan.TryReceive( vEvent ) then
			begin
				vSyncPeer := mPeers.BestPeer;
				if vSyncPeer <> nil then
				begin
					vCurrent := GetHeight;
					if vCurrent >= vSyncPeer.Height then
					begin
						mLog.Info( Format( 'sync done: bestPeer %s at %d, our height: %d', [vSyncPeer.ToString, vSyncPeer.Height, vCurrent] ) );
						mState.Done;
						Exit;
					end;
				end else
				begin
					mLog.Error( 'sync error: no peers' );
					mState.Error( syncErrorNoPeers );
					Exit;
				end;
			end;

			vCurrent := GetHeight;
			if vCurrent >= mTo then
			begin
				mState.Done;
				Exit;
			end;

			if vCurrent = vOldHeight then
			begin
				if SecondsBetween( Now, vLastCheckTime ) > mTimeout.TotalSeconds then
				begin
					mLog.Error( Format( 'sync error: stuck at %d', [vCurrent] ) );
					StopSync;

					if vRetrySync > 3 then
					begin
						mState.Error( syncErrorStuck );
						Exit;
					end else
					begin
						Inc( vRetrySync );
						goto Prepare;
					end;
				end;
			end else
			begin
				vOldHeight := vCurrent;
				vLastCheckTime := Now;
			end;

			if mTerm.IsClosed then
			begin
				mState.Cancel;
				Exit;
			end;

			TThread.Sleep( Const_CheckChainInterval );
		end;

	finally
		Stop;
	end;
end;

procedure TSyncer.Stop;
begin
	if TInterlocked.CompareExchange( mRunning, 0, 1 ) = 1 then
	begin
		mPeers.UnSub( mEventChan );
		mTerm.Close;
		StopSync;
	end;
end;

function TSyncer.GetHeight : UInt64;
begin
	Result := mChain.GetLatestSnapshotBlock.Height;
end;

function TSyncer.GetInitStart : TArray<THashHeight>;
var
	vStart : TList<THashHeight>;
	vBlock : TSnapshotBlock;
	vGenesis : TSnapshotBlock;
	vIrrevPoint : THashHeight;
	vIrrevHeight : UInt64;
	vHeight : UInt64;
	vIndex : Integer;
begin
	vStart := TList<THashHeight>.Create;
	try
		vGenesis := mChain.GetGenesisSnapshotBlock;

label StartLabel;
		vBlock := mIrreader.GetIrreversibleBlock;
		if vBlock <> nil then
		begin
			vIrrevHeight := ( vBlock.Height div Const_SyncTaskSize ) * Const_SyncTaskSize;
			if vIrrevHeight > vGenesis.Height then
			begin
				vBlock := mChain.GetSnapshotBlockByHeight( vIrrevHeight );
				if vBlock = nil then
				begin
					mLog.Error( Format( 'failed to find snapshot block at %d', [vIrrevHeight] ) );
					vBlock := vGenesis;
				end;
			end else
			begin
				vBlock := vGenesis;
			end;
		end else
		begin
			vBlock := vGenesis;
		end;
		vIrrevPoint := THashHeight.Create( vBlock.Height, vBlock.Hash );

		vHeight := ( GetHeight div Const_SyncTaskSize ) * Const_SyncTaskSize;
		for vIndex := 0 to 1 do
		begin
			if vHeight <= vIrrevPoint.Height then
			begin
				vStart.Add( vIrrevPoint );
				Result := vStart.ToArray;
				Exit;
			end else
			begin
				vBlock := mChain.GetSnapshotBlockByHeight( vHeight );
				if vBlock = nil then
				begin
					mLog.Error( Format( 'failed to find snapshot block at %d', [vHeight] ) );
					goto StartLabel;
				end else
				begin
					vStart.Add( THashHeight.Create( vHeight, vBlock.Hash ) );
					if vHeight > Const_SyncTaskSize then
					begin
						Dec( vHeight, Const_SyncTaskSize );
					end;
				end;
			end;
		end;

		vStart.Add( vIrrevPoint );
		Result := vStart.ToArray;
	finally
		vStart.Free;
	end;
end;

function TSyncer.GetEnd( ParaStart : TArray<THashHeight> ) : UInt64;
var
	vSyncPeer : TPeer;
	vSyncHeight : UInt64;
	vStartHeight : UInt64;
begin
	vSyncPeer := mPeers.SyncPeer;
	if vSyncPeer = nil then
	begin
		Result := 0;
		Exit;
	end;

	vSyncHeight := vSyncPeer.Height;
	TInterlocked.Exchange( Int64( mTo ), Int64( vSyncHeight ) );

	vStartHeight := ParaStart[0].Height;
	Result := ( ( vStartHeight + Const_MaxBatchChunkSize ) div Const_MaxBatchChunkSize ) * Const_MaxBatchChunkSize;
	if Result > vSyncHeight then
	begin
		Result := vSyncHeight;
	end;
end;

function TSyncer.GetHashHeightList( ParaStart : TArray<THashHeight>; ParaEnd : UInt64 ) : TArray<THashHeightPoint>;
begin
	if ParaStart[0].Height >= ParaEnd then
	begin
		raise Exception.Create( Format( 'start %d is not small than end %d', [ParaStart[0].Height, ParaEnd] ) );
	end;

	mSk.Reset;
	Result := mSk.Construct( ParaStart, ParaEnd );
end;

function TSyncer.VerifyHashHeightList( ParaStart : TArray<THashHeight>; ParaPoints : TArray<THashHeightPoint> ) : THashHeight;
var
	vPoint : THashHeight;
begin
	if Length( ParaPoints ) = 0 then
	begin
		raise Exception.Create( 'hash height list is nil' );
	end;

	for vPoint in ParaStart do
	begin
		if vPoint.Height + 1 = ParaPoints[0].Height then
		begin
			Result := vPoint;
			Exit;
		end;
	end;

	raise Exception.Create( 'skeleton has no right start point' );
end;

function TSyncer.DoSync : Boolean;
var
	vStart : TArray<THashHeight>;
	vEnd : UInt64;
	vPoints : TArray<THashHeightPoint>;
	vStartPoint : THashHeight;
begin
	Result := False;
	try
		vStart := GetInitStart;
		vEnd := GetEnd( vStart );

		vPoints := GetHashHeightList( vStart, vEnd );
		vStartPoint := VerifyHashHeightList( vStart, vPoints );

		mReader.Reset;
		mFrom := vStartPoint.Height + 1;
		TGo.Run( procedure begin DownloadLoop( vStartPoint, vEnd, vPoints ); end );
		Result := True;
	except
		on E: Exception do
		begin
			mLog.Warn( 'Sync failed: ' + E.Message );
		end;
	end;
end;

procedure TSyncer.DownloadLoop( ParaPoint : THashHeight; ParaEnd : UInt64; ParaPoints : TArray<THashHeightPoint> );
var
	vPoint : THashHeight;
	vEnd : UInt64;
	vPoints : TArray<THashHeightPoint>;
	vTasks : TArray<TDownloadTask>;
	vTask : TDownloadTask;
	vStart : TArray<THashHeight>;
begin
	mSyncWG.Add( 1 );
	try
		TInterlocked.Exchange( mTaskCanceled, 0 );

		vPoint := ParaPoint;
		vEnd := ParaEnd;
		vPoints := ParaPoints;

		while True do
		begin
			mLog.Info( Format( 'construct skeleton: %d-%d', [vPoint.Height, vEnd] ) );

			vTasks := mReader.CompareCache( vPoint, vPoints );
			if Length( vTasks ) > 0 then
			begin
				for vTask in vTasks do
				begin
					if ( not mDownloader.Download( vTask, False ) ) or ( TInterlocked.Read( mTaskCanceled ) = 1 ) then
					begin
						mLog.Warn( 'break download loop' );
						mDownloader.CancelAllTasks;
						Exit;
					end;
				end;
			end;

			if vEnd mod Const_SyncTaskSize <> 0 then
			begin
				mLog.Info( Format( 'download loop done at end: %d', [vEnd] ) );
				Exit;
			end;

			vPoint := vPoints[High( vPoints )].HashHeight;
			vStart := [THashHeight.Create( vPoint.Height, vPoint.Hash )];
			vEnd := GetEnd( vStart );

			vPoints := GetHashHeightList( vStart, vEnd );
			VerifyHashHeightList( vStart, vPoints );
		end;
	finally
		mSyncWG.Done;
	end;
end;

procedure TSyncer.StopSync;
begin
	mLog.Warn( 'stop sync' );
	TInterlocked.Exchange( mTaskCanceled, 1 );
	mDownloader.CancelAllTasks;
	mReader.Reset;
	mSyncWG.Wait;
end;

function TSyncer.Status : TSyncStatus;
begin
	Result.From := mFrom;
	Result.To := mTo;
	Result.Current := GetHeight;
	Result.State := mState.State;
	Result.Status := Result.State.ToString;
end;

function TSyncer.Detail : TSyncDetail;
begin
	Result.SyncStatus := Status;
	Result.DownloaderStatus := mDownloader.Status;
	Result.Chunks := mReader.Chunks;
	Result.Caches := mReader.Caches;
end;

end.
