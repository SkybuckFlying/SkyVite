unit Vendor.Github.Com.Allegro.BigCache.Shard;

interface

uses
	System.SysUtils,
	System.Classes,
	System.SyncObjs,
	System.SyncObjs.Atomic,
	Vendor.Github.Com.Allegro.BigCache.Config,
	Vendor.Github.Com.Allegro.BigCache.Stats,
	Vendor.Github.Com.Allegro.BigCache.Clock,
	Vendor.Github.Com.Allegro.BigCache.Logger,
	Vendor.Github.Com.Allegro.BigCache.Queue.BytesQueue,
	Vendor.Github.Com.Allegro.BigCache.Encoding;

type
	TOnRemoveCallbackInternal = reference to procedure( ParaWrappedEntry : TBytes; ParaReason : TRemoveReason );

	TcacheShard = class
	private
		mHashmap     : TDictionary<UInt64, UInt32>;
		mEntries     : TBytesQueue;
		mLock        : TReadWriteSync;
		mEntryBuffer : TBytes;
		mOnRemove    : TOnRemoveCallbackInternal;

		mIsVerbose  : Boolean;
		mLogger     : ILogger;
		mClock      : IClock;
		mLifeWindow : UInt64;

		mStats      : TStats;

		procedure Hit;
		procedure Miss;
		procedure DelHit;
		procedure DelMiss;
		procedure Collision;
		function RemoveOldestEntry( ParaReason : TRemoveReason ) : Error;
	public
		constructor Create( ParaConfig : TConfig; ParaCallback : TOnRemoveCallbackInternal; ParaClock : IClock );
		destructor Destroy; override;
		
		function Get( ParaKey : string; ParaHashedKey : UInt64 ) : TBytes;
		function SetItem( ParaKey : string; ParaHashedKey : UInt64; ParaEntry : TBytes ) : Error;
		function Del( ParaKey : string; ParaHashedKey : UInt64 ) : Error;
		function OnEvict( ParaOldestEntry : TBytes; ParaCurrentTimestamp : UInt64; ParaEvict : TFunc<TRemoveReason, Error> ) : Boolean;
		procedure CleanUp( ParaCurrentTimestamp : UInt64 );
		function GetOldestEntry : TBytes;
		function GetEntry( ParaIndex : Integer ) : TBytes;
		procedure CopyKeys( out ParaKeys : TArray<UInt32>; out ParaNext : Integer );
		procedure Reset( ParaConfig : TConfig );
		function Len : Integer;
		function Capacity : Integer;
		function GetStats : TStats;
	end;

function InitNewShard( ParaConfig : TConfig; ParaCallback : TOnRemoveCallbackInternal; ParaClock : IClock ) : TcacheShard;

implementation

uses
	System.Generics.Collections;

function InitNewShard( ParaConfig : TConfig; ParaCallback : TOnRemoveCallbackInternal; ParaClock : IClock ) : TcacheShard;
begin
	try
		Result := TcacheShard.Create( ParaConfig, ParaCallback, ParaClock );
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed during shard initialization' );
		end;
	end;
end;

{ TcacheShard }

constructor TcacheShard.Create( ParaConfig : TConfig; ParaCallback : TOnRemoveCallbackInternal; ParaClock : IClock );
begin
	inherited Create;
	mHashmap := TDictionary<UInt64, UInt32>.Create( ParaConfig.InitialShardSize );
	mEntries := TBytesQueue.Create( ParaConfig.InitialShardSize * ParaConfig.mMaxEntrySize, ParaConfig.MaximumShardSize, ParaConfig.mVerbose );
	SetLength( mEntryBuffer, ParaConfig.mMaxEntrySize + Const_HeadersSizeInBytes );
	mOnRemove := ParaCallback;
	mIsVerbose := ParaConfig.mVerbose;
	mLogger := NewLogger( ParaConfig.mLogger );
	mClock := ParaClock;
	mLifeWindow := UInt64( ParaConfig.mLifeWindow.TotalSeconds );
	mLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TcacheShard.Destroy;
begin
	mHashmap.Free;
	mEntries.Free;
	mLock.Free;
	inherited;
end;

function TcacheShard.Get( ParaKey : string; ParaHashedKey : UInt64 ) : TBytes;
var
	vItemIndex : UInt32;
	vWrappedEntry : TBytes;
	vEntryKey : string;
begin
	mLock.BeginRead;
	try
		if not mHashmap.TryGetValue( ParaHashedKey, vItemIndex ) then
		begin
			Miss;
			raise Exception.Create( 'Entry not found' );
		end;

		vWrappedEntry := mEntries.Get( Integer( vItemIndex ) );
		vEntryKey := ReadKeyFromEntry( vWrappedEntry );
		
		if ParaKey <> vEntryKey then
		begin
			if mIsVerbose then
			begin
				mLogger.Printf( 'Collision detected. Both %s and %s have the same hash %x', [ ParaKey, vEntryKey, ParaHashedKey ] );
			end;
			Collision;
			raise Exception.Create( 'Entry not found' );
		end;
		
		Result := ReadEntry( vWrappedEntry );
		Hit;
	finally
		mLock.EndRead;
	end;
end;

function TcacheShard.SetItem( ParaKey : string; ParaHashedKey : UInt64; ParaEntry : TBytes ) : Error;
var
	vCurrentTimestamp : UInt64;
	vPreviousIndex : UInt32;
	vPreviousEntry : TBytes;
	vOldestEntry : TBytes;
	vWrapped : TBytes;
	vIndex : Integer;
begin
	vCurrentTimestamp := UInt64( mClock.Epoch );

	mLock.BeginWrite;
	try
		if mHashmap.TryGetValue( ParaHashedKey, vPreviousIndex ) then
		begin
			try
				vPreviousEntry := mEntries.Get( Integer( vPreviousIndex ) );
				ResetKeyFromEntry( vPreviousEntry );
			except
				// Ignore if not found
			end;
		end;

		try
			vOldestEntry := mEntries.Peek;
			OnEvict( vOldestEntry, vCurrentTimestamp, function( ParaReason : TRemoveReason ) : Error
			begin
				Result := RemoveOldestEntry( ParaReason );
			end );
		except
			// Ignore if queue empty
		end;

		vWrapped := WrapEntry( vCurrentTimestamp, ParaHashedKey, ParaKey, ParaEntry, mEntryBuffer );

		while True do
		begin
			try
				vIndex := mEntries.Push( vWrapped );
				mHashmap.AddOrSetValue( ParaHashedKey, UInt32( vIndex ) );
				Result := nil;
				Exit;
			except
				if RemoveOldestEntry( NoSpace ) <> nil then
				begin
					Result := TError.Create( 'entry is bigger than max shard size' );
					Exit;
				end;
			end;
		end;
	finally
		mLock.EndWrite;
	end;
end;

function TcacheShard.Del( ParaKey : string; ParaHashedKey : UInt64 ) : Error;
var
	vItemIndex : UInt32;
	vWrappedEntry : TBytes;
begin
	mLock.BeginRead;
	try
		if not mHashmap.TryGetValue( ParaHashedKey, vItemIndex ) then
		begin
			DelMiss;
			Result := TError.Create( 'Entry not found' );
			Exit;
		end;

		if not mEntries.CheckGet( Integer( vItemIndex ) ) then
		begin
			DelMiss;
			Result := TError.Create( 'Entry not found' );
			Exit;
		end;
	finally
		mLock.EndRead;
	end;

	mLock.BeginWrite;
	try
		if not mHashmap.TryGetValue( ParaHashedKey, vItemIndex ) then
		begin
			DelMiss;
			Result := TError.Create( 'Entry not found' );
			Exit;
		end;

		vWrappedEntry := mEntries.Get( Integer( vItemIndex ) );
		mHashmap.Remove( ParaHashedKey );
		mOnRemove( vWrappedEntry, Deleted );
		ResetKeyFromEntry( vWrappedEntry );
		DelHit;
		Result := nil;
	finally
		mLock.EndWrite;
	end;
end;

function TcacheShard.OnEvict( ParaOldestEntry : TBytes; ParaCurrentTimestamp : UInt64; ParaEvict : TFunc<TRemoveReason, Error> ) : Boolean;
var
	vOldestTimestamp : UInt64;
begin
	vOldestTimestamp := ReadTimestampFromEntry( ParaOldestEntry );
	if ParaCurrentTimestamp - vOldestTimestamp > mLifeWindow then
	begin
		ParaEvict( Expired );
		Result := True;
	end else
	begin
		Result := False;
	end;
end;

procedure TcacheShard.CleanUp( ParaCurrentTimestamp : UInt64 );
var
	vOldestEntry : TBytes;
begin
	mLock.BeginWrite;
	try
		while True do
		begin
			try
				vOldestEntry := mEntries.Peek;
				if not OnEvict( vOldestEntry, ParaCurrentTimestamp, function( ParaReason : TRemoveReason ) : Error
				begin
					Result := RemoveOldestEntry( ParaReason );
				end ) then
				begin
					Break;
				end;
			except
				Break;
			end;
		end;
	finally
		mLock.EndWrite;
	end;
end;

function TcacheShard.GetOldestEntry : TBytes;
begin
	mLock.BeginRead;
	try
		Result := mEntries.Peek;
	finally
		mLock.EndRead;
	end;
end;

function TcacheShard.GetEntry( ParaIndex : Integer ) : TBytes;
begin
	mLock.BeginRead;
	try
		Result := mEntries.Get( ParaIndex );
	finally
		mLock.EndRead;
	end;
end;

procedure TcacheShard.CopyKeys( out ParaKeys : TArray<UInt32>; out ParaNext : Integer );
var
	vValue : UInt32;
begin
	mLock.BeginRead;
	try
		SetLength( ParaKeys, mHashmap.Count );
		ParaNext := 0;
		for vValue in mHashmap.Values do
		begin
			ParaKeys[ParaNext] := vValue;
			Inc( ParaNext );
		end;
	finally
		mLock.EndRead;
	end;
end;

function TcacheShard.RemoveOldestEntry( ParaReason : TRemoveReason ) : Error;
var
	vOldest : TBytes;
	vHash : UInt64;
begin
	try
		vOldest := mEntries.Pop;
		vHash := ReadHashFromEntry( vOldest );
		mHashmap.Remove( vHash );
		mOnRemove( vOldest, ParaReason );
		Result := nil;
	except
		on E: Exception do
		begin
			Result := TError.Create( E.Message );
		end;
	end;
end;

procedure TcacheShard.Reset( ParaConfig : TConfig );
begin
	mLock.BeginWrite;
	try
		mHashmap.Clear;
		SetLength( mEntryBuffer, ParaConfig.mMaxEntrySize + Const_HeadersSizeInBytes );
		mEntries.Reset;
	finally
		mLock.EndWrite;
	end;
end;

function TcacheShard.Len : Integer;
begin
	mLock.BeginRead;
	try
		Result := mHashmap.Count;
	finally
		mLock.EndRead;
	end;
end;

function TcacheShard.Capacity : Integer;
begin
	mLock.BeginRead;
	try
		Result := mEntries.Capacity;
	finally
		mLock.EndRead;
	end;
end;

function TcacheShard.GetStats : TStats;
begin
	Result.mHits := TInterlocked.Read( mStats.mHits );
	Result.mMisses := TInterlocked.Read( mStats.mMisses );
	Result.mDelHits := TInterlocked.Read( mStats.mDelHits );
	Result.mDelMisses := TInterlocked.Read( mStats.mDelMisses );
	Result.mCollisions := TInterlocked.Read( mStats.mCollisions );
end;

procedure TcacheShard.Hit;
begin
	TInterlocked.Increment( mStats.mHits );
end;

procedure TcacheShard.Miss;
begin
	TInterlocked.Increment( mStats.mMisses );
end;

procedure TcacheShard.DelHit;
begin
	TInterlocked.Increment( mStats.mDelHits );
end;

procedure TcacheShard.DelMiss;
begin
	TInterlocked.Increment( mStats.mDelMisses );
end;

procedure TcacheShard.Collision;
begin
	TInterlocked.Increment( mStats.mCollisions );
end;

end.
