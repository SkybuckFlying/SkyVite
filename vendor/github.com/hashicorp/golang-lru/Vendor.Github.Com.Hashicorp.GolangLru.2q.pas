{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Hashicorp.GolangLru.2q;

interface

{$IFDEF FPC}
uses
	SysUtils, SyncObjs, Generics.Collections,
	Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.LruInterface
;
{$ELSE}
uses
	System.SysUtils, System.SyncObjs, System.Generics.Collections,
	Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.LruInterface
;
{$ENDIF}

const
	Default2QRecentRatio = 0.25;
	Default2QGhostEntries = 0.50;

type
	TTwoQueueCache = class
	private
		mSize       : Integer;
		mRecentSize : Integer;
		mRecent      : ILRUCache;
		mFrequent    : ILRUCache;
		mRecentEvict : ILRUCache;
		mLock        : TCriticalSection;

		procedure ensureSpace( ParaRecentEvict : Boolean );
	public
		constructor Create( ParaSize : Integer ); overload;
		constructor Create( ParaSize : Integer; ParaRecentRatio, ParaGhostRatio : Double ); overload;
		destructor Destroy; override;

		function Get( ParaKey : TValue ) : TValue;
		procedure Add( ParaKey, ParaValue : TValue );
		function Len : Integer;
		function Keys : TArray<TValue>;
		procedure Remove( ParaKey : TValue );
		procedure Purge;
		function Contains( ParaKey : TValue ) : Boolean;
		function Peek( ParaKey : TValue ) : TValue;
	end;

implementation

constructor TTwoQueueCache.Create( ParaSize : Integer );
begin
	Create( ParaSize, Default2QRecentRatio, Default2QGhostEntries );
end;

constructor TTwoQueueCache.Create( ParaSize : Integer; ParaRecentRatio, ParaGhostRatio : Double );
begin
	inherited Create;
	mSize := ParaSize;
	mRecentSize := Round( ParaSize * ParaRecentRatio );
	mLock := TCriticalSection.Create;
	// Allocation of LRUs would go here
end;

destructor TTwoQueueCache.Destroy;
begin
	mLock.Free;
	inherited;
end;

procedure TTwoQueueCache.ensureSpace( ParaRecentEvict : Boolean );
begin
end;

function TTwoQueueCache.Get( ParaKey : TValue ) : TValue;
begin
	Result := TValue.Empty;
end;

procedure TTwoQueueCache.Add( ParaKey, ParaValue : TValue );
begin
end;

function TTwoQueueCache.Len : Integer;
begin
	Result := 0;
end;

function TTwoQueueCache.Keys : TArray<TValue>;
begin
	SetLength( Result, 0 );
end;

procedure TTwoQueueCache.Remove( ParaKey : TValue );
begin
end;

procedure TTwoQueueCache.Purge;
begin
end;

function TTwoQueueCache.Contains( ParaKey : TValue ) : Boolean;
begin
	Result := False;
end;

function TTwoQueueCache.Peek( ParaKey : TValue ) : TValue;
begin
	Result := TValue.Empty;
end;

end.
