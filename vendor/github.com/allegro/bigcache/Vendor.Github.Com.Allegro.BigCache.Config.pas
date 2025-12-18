unit Vendor.Github.Com.Allegro.BigCache.Config;

interface

uses
	System.Classes,
	System.SysUtils,
	System.TimeSpan,
	Vendor.Github.Com.Allegro.BigCache.Hash,
	Vendor.Github.Com.Allegro.BigCache.Logger,
	Vendor.Github.Com.Allegro.BigCache.Fnv;

type
	TRemoveReason = (
		Expired,
		NoSpace,
		Deleted
	);

	TOnRemoveCallback = reference to procedure( ParaKey : string; ParaEntry : TBytes );
	TOnRemoveWithReasonCallback = reference to procedure( ParaKey : string; ParaEntry : TBytes; ParaReason : TRemoveReason );

	TConfig = record
	public
		mShards             : Integer;
		mLifeWindow         : TTimeSpan;
		mCleanWindow        : TTimeSpan;
		mMaxEntriesInWindow : Integer;
		mMaxEntrySize       : Integer;
		mVerbose            : Boolean;
		mHasher             : IHasher;
		mHardMaxCacheSize   : Integer;
		mOnRemove           : TOnRemoveCallback;
		mOnRemoveWithReason : TOnRemoveWithReasonCallback;
		mOnRemoveFilter     : Integer;
		mLogger             : ILogger;

		function InitialShardSize : Integer;
		function MaximumShardSize : Integer;
		function OnRemoveFilterSet( const ParaReasons : array of TRemoveReason ) : TConfig;
	end;

function DefaultConfig( ParaEviction : TTimeSpan ) : TConfig;

implementation

const
	Const_MinimumEntriesInShard = 10;

function DefaultConfig( ParaEviction : TTimeSpan ) : TConfig;
begin
	Result.mShards := 1024;
	Result.mLifeWindow := ParaEviction;
	Result.mCleanWindow := TTimeSpan.Zero;
	Result.mMaxEntriesInWindow := 1000 * 10 * 60;
	Result.mMaxEntrySize := 500;
	Result.mVerbose := True;
	Result.mHasher := NewDefaultHasher;
	Result.mHardMaxCacheSize := 0;
	Result.mLogger := DefaultLogger;
end;

{ TConfig }

function TConfig.InitialShardSize : Integer;
begin
	if mShards > 0 then
	begin
		Result := mMaxEntriesInWindow div mShards;
	end else
	begin
		Result := 0;
	end;
	
	if Result < Const_MinimumEntriesInShard then
	begin
		Result := Const_MinimumEntriesInShard;
	end;
end;

function TConfig.MaximumShardSize : Integer;
var
	vMaxShardSize : Integer;
begin
	vMaxShardSize := 0;

	if mHardMaxCacheSize > 0 then
	begin
		// Assuming a conversion helper exists or implementing inline
		vMaxShardSize := ( mHardMaxCacheSize * 1024 * 1024 ) div mShards;
	end;

	Result := vMaxShardSize;
end;

function TConfig.OnRemoveFilterSet( const ParaReasons : array of TRemoveReason ) : TConfig;
var
	vIndex : Integer;
begin
	mOnRemoveFilter := 0;
	for vIndex := Low( ParaReasons ) to High( ParaReasons ) do
	begin
		mOnRemoveFilter := mOnRemoveFilter or ( 1 shl Ord( ParaReasons[vIndex] ) );
	end;
	Result := Self;
end;

end.
