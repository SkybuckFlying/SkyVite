unit Vendor.Github.Com.Allegro.BigCache.Iterator;

interface

uses
	System.Classes,
	System.SysUtils,
	System.SyncObjs,
	Vendor.Github.Com.Allegro.BigCache.Config,
	Vendor.Github.Com.Allegro.BigCache.Encoding;

type
	EIteratorError = class(Exception);

	TEntryInfo = record
	private
		mTimestamp : UInt64;
		mHash      : UInt64;
		mKey       : string;
		mValue     : TBytes;
	public
		property Key : string read mKey;
		property Hash : UInt64 read mHash;
		property Timestamp : UInt64 read mTimestamp;
		property Value : TBytes read mValue;
		
		constructor Create( ParaTimestamp : UInt64; ParaHash : UInt64; ParaKey : string; ParaValue : TBytes );
	end;

	TBigCache = class; // Forward declaration

	TEntryInfoIterator = class
	private
		mMutex         : TCriticalSection;
		mCache         : TBigCache;
		mCurrentShard  : Integer;
		mCurrentIndex  : Integer;
		mElements      : TArray<UInt32>;
		mElementsCount : Integer;
		mValid         : Boolean;
	public
		constructor Create( ParaCache : TBigCache );
		destructor Destroy; override;
		function SetNext : Boolean;
		function GetValue : TEntryInfo;
	end;

implementation

uses
	Vendor.Github.Com.Allegro.BigCache.BigCache,
	Vendor.Github.Com.Allegro.BigCache.Shard;

{ TEntryInfo }

constructor TEntryInfo.Create( ParaTimestamp : UInt64; ParaHash : UInt64; ParaKey : string; ParaValue : TBytes );
begin
	mTimestamp := ParaTimestamp;
	mHash := ParaHash;
	mKey := ParaKey;
	mValue := ParaValue;
end;

{ TEntryInfoIterator }

constructor TEntryInfoIterator.Create( ParaCache : TBigCache );
begin
	inherited Create;
	mMutex := TCriticalSection.Create;
	mCache := ParaCache;
	mCurrentShard := 0;
	mCurrentIndex := -1;
	mCache.mShards[0].CopyKeys( mElements, mElementsCount );
end;

destructor TEntryInfoIterator.Destroy;
begin
	mMutex.Free;
	inherited;
end;

function TEntryInfoIterator.SetNext : Boolean;
var
	vIndex : Integer;
begin
	mMutex.Acquire;
	try
		mValid := False;
		Inc( mCurrentIndex );

		if mElementsCount > mCurrentIndex then
		begin
			mValid := True;
			Exit( True );
		end;

		for vIndex := mCurrentShard + 1 to mCache.mConfig.mShards - 1 do
		begin
			mCache.mShards[vIndex].CopyKeys( mElements, mElementsCount );

			if mElementsCount > 0 then
			begin
				mCurrentIndex := 0;
				mCurrentShard := vIndex;
				mValid := True;
				Exit( True );
			end;
		end;
		Result := False;
	finally
		mMutex.Release;
	end;
end;

function TEntryInfoIterator.GetValue : TEntryInfo;
var
	vEntry : TBytes;
begin
	mMutex.Acquire;
	try
		if not mValid then
		begin
			raise EIteratorError.Create( 'Iterator is in invalid state. Use SetNext() to move to next position' );
		end;

		vEntry := mCache.mShards[mCurrentShard].GetEntry( mElements[mCurrentIndex] );
		
		Result := TEntryInfo.Create(
			ReadTimestampFromEntry( vEntry ),
			ReadHashFromEntry( vEntry ),
			ReadKeyFromEntry( vEntry ),
			ReadEntry( vEntry )
		);
	finally
		mMutex.Release;
	end;
end;

end.
