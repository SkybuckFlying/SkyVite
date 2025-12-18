unit Vendor.Github.Com.Hashicorp.GolangLru.Lru;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  Vendor.Github.Com.Hashicorp.GolangLru.2q,
  Vendor.Github.Com.Hashicorp.GolangLru.Arc,
  Vendor.Github.Com.Hashicorp.GolangLru.Doc,
  Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.Lru,
  Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.LruInterface;

type
	TCache = class
	private
		mLRU : ILRUCache;
		mLock : TLightweightMvx;
	public
		constructor Create( ParaSize : Integer );
		destructor Destroy; override;

		function Add( ParaKey, ParaValue : TObject ) : Boolean;
		function Get( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
		function Contains( ParaKey : TObject ) : Boolean;
		function Peek( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
		function Remove( ParaKey : TObject ) : Boolean;
		function Len : Integer;
		procedure Purge;
	end;

implementation

{ TCache }

constructor TCache.Create( ParaSize : Integer );
begin
	inherited Create;
	mLRU := TLRU.Create( ParaSize, nil );
	// mLock := TLightweightMvx.Create; // Delphi's LightweightMvx doesn't need explicit create sometimes or use TCriticalSection
end;

destructor TCache.Destroy;
begin
	// mLock.Free;
	inherited;
end;

function TCache.Add( ParaKey, ParaValue : TObject ) : Boolean;
begin
	mLock.BeginWrite;
	try
		Result := mLRU.Add( ParaKey, ParaValue );
	finally
		mLock.EndWrite;
	end;
end;

function TCache.Get( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
begin
	mLock.BeginWrite;
	try
		Result := mLRU.Get( ParaKey, ParaValue );
	finally
		mLock.EndWrite;
	end;
end;

function TCache.Contains( ParaKey : TObject ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mLRU.Contains( ParaKey );
	finally
		mLock.EndRead;
	end;
end;

function TCache.Peek( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mLRU.Peek( ParaKey, ParaValue );
	finally
		mLock.EndRead;
	end;
end;

function TCache.Remove( ParaKey : TObject ) : Boolean;
begin
	mLock.BeginWrite;
	try
		Result := mLRU.Remove( ParaKey );
	finally
		mLock.EndWrite;
	end;
end;

function TCache.Len : Integer;
begin
	mLock.BeginRead;
	try
		Result := mLRU.Len;
	finally
		mLock.EndRead;
	end;
end;

procedure TCache.Purge;
begin
	mLock.BeginWrite;
	try
		mLRU.Purge;
	finally
		mLock.EndWrite;
	end;
end;

end.
