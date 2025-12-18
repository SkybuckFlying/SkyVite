unit Vendor.Github.Com.Patrickmn.GoCache.Sharded;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.Patrickmn.GoCache.Cache;

type
	TShardedCache = class
	private
		mShards : TArray<TCache>;
		mSeed   : UInt32;
	public
		constructor Create( ParaDefaultExpiration, ParaCleanupInterval : TTimeSpan; ParaShards : Integer );
		destructor Destroy; override;

		function GetShard( ParaK : string ) : TCache;
	end;

implementation

uses
	System.TimeSpan,
	System.Hash;

{ TShardedCache }

constructor TShardedCache.Create( ParaDefaultExpiration, ParaCleanupInterval : TTimeSpan; ParaShards : Integer );
var
	vI : Integer;
begin
	inherited Create;
	SetLength( mShards, ParaShards );
	for vI := 0 to ParaShards - 1 do
		mShards[ vI ] := TCache.Create( ParaDefaultExpiration, ParaCleanupInterval );
	mSeed := UInt32( Random( $FFFFFFFF ) );
end;

destructor TShardedCache.Destroy;
var
	vCache : TCache;
begin
	for vCache in mShards do
		vCache.Free;
	inherited;
end;

function TShardedCache.GetShard( ParaK : string ) : TCache;
var
	vHash : UInt32;
begin
	vHash := THashBobJenkins.GetHashValue( ParaK );
	Result := mShards[ vHash mod Length( mShards ) ];
end;

end.
