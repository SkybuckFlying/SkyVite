unit Vendor.Github.Com.Allegro.BigCache.BigCache;

interface

uses
	System.SysUtils,
	System.Classes,
	System.TimeSpan,
	Vendor.Github.Com.Allegro.BigCache.Config,
	Vendor.Github.Com.Allegro.BigCache.Shard,
	Vendor.Github.Com.Allegro.BigCache.Hash,
	Vendor.Github.Com.Allegro.BigCache.Clock,
	Vendor.Github.Com.Allegro.BigCache.Stats,
	Vendor.Github.Com.Allegro.BigCache.Iterator;

type
	TBigCache = class
	private
		mShards       : TArray<TcacheShard>;
		mLifeWindow   : UInt64;
		mClock        : IClock;
		mHash         : IHasher;
		mConfig       : TConfig;
		mShardMask    : UInt64;
		mMaxShardSize : UInt32;
		mClose        : TSimpleEvent;

		procedure CleanUp( ParaCurrentTimestamp : UInt64 );
		function GetShard( ParaHashedKey : UInt64 ) : TcacheShard;
		procedure ProvidedOnRemove( ParaWrappedEntry : TBytes; ParaReason : TRemoveReason );
		procedure ProvidedOnRemoveWithReason( ParaWrappedEntry : TBytes; ParaReason : TRemoveReason );
		procedure NotProvidedOnRemove( ParaWrappedEntry : TBytes; ParaReason : TRemoveReason );
	public
		constructor Create( ParaConfig : TConfig; ParaClock : IClock = nil );
		destructor Destroy; override;
		
		function Get( ParaKey : string ) : TBytes;
		function SetItem( ParaKey : string; ParaEntry : TBytes ) : Error;
		function Delete( ParaKey : string ) : Error;
		procedure Reset;
		function Len : Integer;
		function Capacity : Integer;
		function Stats : TStats;
		function Iterator : TEntryInfoIterator;
		procedure Close;
	end;

function NewBigCache( ParaConfig : TConfig ) : TBigCache;

implementation

uses
	System.Threading,
	Vendor.Github.Com.Allegro.BigCache.Encoding,
	Vendor.Github.Com.Allegro.BigCache.Utils;

function NewBigCache( ParaConfig : TConfig ) : TBigCache;
begin
	try
		Result := TBigCache.Create( ParaConfig );
	except
		on E: EOutOfMemory do
		begin
			raise Exception.Create( 'Memory allocation failed during BigCache initialization' );
		end;
	end;
end;

{ TBigCache }

constructor TBigCache.Create( ParaConfig : TConfig; ParaClock : IClock );
var
	vClock : IClock;
	vOnRemove : TOnRemoveCallbackInternal;
	vIndex : Integer;
begin
	inherited Create;
	if not IsPowerOfTwo( ParaConfig.mShards ) then
	begin
		raise Exception.Create( 'Shards number must be power of two' );
	end;

	if ParaClock <> nil then
	begin
		vClock := ParaClock;
	end else
	begin
		vClock := TSystemClock.Create;
	end;

	mConfig := ParaConfig;
	mLifeWindow := UInt64( ParaConfig.mLifeWindow.TotalSeconds );
	mClock := vClock;
	mHash := ParaConfig.mHasher;
	mShardMask := UInt64( ParaConfig.mShards - 1 );
	mMaxShardSize := UInt32( ParaConfig.MaximumShardSize );
	mClose := TSimpleEvent.Create;

	SetLength( mShards, ParaConfig.mShards );

	if Assigned( ParaConfig.mOnRemove ) then
	begin
		vOnRemove := ProvidedOnRemove;
	end else if Assigned( ParaConfig.mOnRemoveWithReason ) then
	begin
		vOnRemove := ProvidedOnRemoveWithReason;
	end else
	begin
		vOnRemove := NotProvidedOnRemove;
	end;

	for vIndex := 0 to ParaConfig.mShards - 1 do
	begin
		mShards[vIndex] := InitNewShard( ParaConfig, vOnRemove, vClock );
	end;

	if ParaConfig.mCleanWindow.Ticks > 0 then
	begin
		TTask.Run( procedure
		begin
			while mClose.WaitFor( ParaConfig.mCleanWindow ) = wrTimeout do
			begin
				CleanUp( UInt64( TSystemClock.Create.Epoch ) );
			end;
		end );
	end;
end;

destructor TBigCache.Destroy;
var
	vShard : TcacheShard;
begin
	Close;
	for vShard in mShards do
	begin
		vShard.Free;
	end;
	mClose.Free;
	inherited;
end;

procedure TBigCache.Close;
begin
	mClose.SetEvent;
end;

function TBigCache.Get( ParaKey : string ) : TBytes;
var
	vHashedKey : UInt64;
	vShard : TcacheShard;
begin
	vHashedKey := mHash.Sum64( ParaKey );
	vShard := GetShard( vHashedKey );
	Result := vShard.Get( ParaKey, vHashedKey );
end;

function TBigCache.SetItem( ParaKey : string; ParaEntry : TBytes ) : Error;
var
	vHashedKey : UInt64;
	vShard : TcacheShard;
begin
	vHashedKey := mHash.Sum64( ParaKey );
	vShard := GetShard( vHashedKey );
	Result := vShard.SetItem( ParaKey, vHashedKey, ParaEntry );
end;

function TBigCache.Delete( ParaKey : string ) : Error;
var
	vHashedKey : UInt64;
	vShard : TcacheShard;
begin
	vHashedKey := mHash.Sum64( ParaKey );
	vShard := GetShard( vHashedKey );
	Result := vShard.Del( ParaKey, vHashedKey );
end;

procedure TBigCache.Reset;
var
	vShard : TcacheShard;
begin
	for vShard in mShards do
	begin
		vShard.Reset( mConfig );
	end;
end;

function TBigCache.Len : Integer;
var
	vShard : TcacheShard;
begin
	Result := 0;
	for vShard in mShards do
	begin
		Inc( Result, vShard.Len );
	end;
end;

function TBigCache.Capacity : Integer;
var
	vShard : TcacheShard;
begin
	Result := 0;
	for vShard in mShards do
	begin
		Inc( Result, vShard.Capacity );
	end;
end;

function TBigCache.Stats : TStats;
var
	vShard : TcacheShard;
	vTmp : TStats;
begin
	FillChar( Result, SizeOf( Result ), 0 );
	for vShard in mShards do
	begin
		vTmp := vShard.GetStats;
		Inc( Result.mHits, vTmp.mHits );
		Inc( Result.mMisses, vTmp.mMisses );
		Inc( Result.mDelHits, vTmp.mDelHits );
		Inc( Result.mDelMisses, vTmp.mDelMisses );
		Inc( Result.mCollisions, vTmp.mCollisions );
	end;
end;

function TBigCache.Iterator : TEntryInfoIterator;
begin
	Result := TEntryInfoIterator.Create( Self );
end;

procedure TBigCache.CleanUp( ParaCurrentTimestamp : UInt64 );
var
	vShard : TcacheShard;
begin
	for vShard in mShards do
	begin
		vShard.CleanUp( ParaCurrentTimestamp );
	end;
end;

function TBigCache.GetShard( ParaHashedKey : UInt64 ) : TcacheShard;
begin
	Result := mShards[ParaHashedKey and mShardMask];
end;

procedure TBigCache.ProvidedOnRemove( ParaWrappedEntry : TBytes; ParaReason : TRemoveReason );
begin
	mConfig.mOnRemove( ReadKeyFromEntry( ParaWrappedEntry ), ReadEntry( ParaWrappedEntry ) );
end;

procedure TBigCache.ProvidedOnRemoveWithReason( ParaWrappedEntry : TBytes; ParaReason : TRemoveReason );
begin
	if ( mConfig.mOnRemoveFilter = 0 ) or ( ( 1 shl Ord( ParaReason ) ) and mConfig.mOnRemoveFilter > 0 ) then
	begin
		mConfig.mOnRemoveWithReason( ReadKeyFromEntry( ParaWrappedEntry ), ReadEntry( ParaWrappedEntry ), ParaReason );
	end;
end;

procedure TBigCache.NotProvidedOnRemove( ParaWrappedEntry : TBytes; ParaReason : TRemoveReason );
begin
end;

end.
