unit Vendor.Github.Com.Hashicorp.GolangLru.TwoQueue;

interface

uses
	System.Classes,
	System.SysUtils,
	System.SyncObjs,
	Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.LruInterface,
	Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.Lru;

type
	TTwoQueueCache = class
	private
		mSize        : Integer;
		mRecentSize  : Integer;
		mRecent      : ILRUCache;
		mFrequent    : ILRUCache;
		mRecentEvict : ILRUCache;
		mLock        : TLightweightMvx;

		procedure EnsureSpace( ParaRecentEvict : Boolean );
	public
		constructor Create( ParaSize : Integer );
		destructor Destroy; override;

		function Add( ParaKey, ParaValue : TObject ) : Boolean;
		function Get( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
		function Contains( ParaKey : TObject ) : Boolean;
		procedure Purge;
	end;

implementation

{ TTwoQueueCache }

constructor TTwoQueueCache.Create( ParaSize : Integer );
begin
	inherited Create;
	mSize := ParaSize;
	mRecentSize := Round( ParaSize * 0.25 );
	mRecent := TLRU.Create( ParaSize, nil );
	mFrequent := TLRU.Create( ParaSize, nil );
	mRecentEvict := TLRU.Create( Round( ParaSize * 0.50 ), nil );
end;

destructor TTwoQueueCache.Destroy;
begin
	inherited;
end;

function TTwoQueueCache.Get( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
begin
	mLock.BeginWrite;
	try
		if mFrequent.Get( ParaKey, ParaValue ) then
			Exit( True );

		if mRecent.Peek( ParaKey, ParaValue ) then
		begin
			mRecent.Remove( ParaKey );
			mFrequent.Add( ParaKey, ParaValue );
			Exit( True );
		end;

		ParaValue := nil;
		Result := False;
	finally
		mLock.EndWrite;
	end;
end;

function TTwoQueueCache.Add( ParaKey, ParaValue : TObject ) : Boolean;
begin
	mLock.BeginWrite;
	try
		if mFrequent.Contains( ParaKey ) then
		begin
			mFrequent.Add( ParaKey, ParaValue );
			Exit( False );
		end;

		if mRecent.Contains( ParaKey ) then
		begin
			mRecent.Remove( ParaKey );
			mFrequent.Add( ParaKey, ParaValue );
			Exit( False );
		end;

		if mRecentEvict.Contains( ParaKey ) then
		begin
			EnsureSpace( True );
			mRecentEvict.Remove( ParaKey );
			mFrequent.Add( ParaKey, ParaValue );
			Exit( False );
		end;

		EnsureSpace( False );
		mRecent.Add( ParaKey, ParaValue );
		Result := False;
	finally
		mLock.EndWrite;
	end;
end;

procedure TTwoQueueCache.EnsureSpace( ParaRecentEvict : Boolean );
var
	vRecentLen, vFreqLen : Integer;
	vK, vV : TObject;
begin
	vRecentLen := mRecent.Len;
	vFreqLen := mFrequent.Len;
	if vRecentLen + vFreqLen < mSize then
		Exit;

	if ( vRecentLen > 0 ) and ( ( vRecentLen > mRecentSize ) or ( ( vRecentLen = mRecentSize ) and not ParaRecentEvict ) ) then
	begin
		if mRecent.RemoveOldest( vK, vV ) then
			mRecentEvict.Add( vK, nil );
		Exit;
	end;

	mFrequent.RemoveOldest( vK, vV );
end;

function TTwoQueueCache.Contains( ParaKey : TObject ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mFrequent.Contains( ParaKey ) or mRecent.Contains( ParaKey );
	finally
		mLock.EndRead;
	end;
end;

procedure TTwoQueueCache.Purge;
begin
	mLock.BeginWrite;
	try
		mRecent.Purge;
		mFrequent.Purge;
		mRecentEvict.Purge;
	finally
		mLock.EndWrite;
	end;
end;

end.
