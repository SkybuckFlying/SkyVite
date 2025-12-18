unit Vendor.Github.Com.Patrickmn.GoCache.Cache;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Generics.Collections,
	System.SyncObjs;

type
	TItem = record
	public
		mObject     : TObject;
		mExpiration : Int64;
	end;

	TCache = class
	private
		mItems             : TDictionary<string, TItem>;
		mMu                : TLightweightMvx;
		mDefaultExpiration : TTimeSpan;
		mCleanupInterval   : TTimeSpan;
	public
		constructor Create( ParaDefaultExpiration, ParaCleanupInterval : TTimeSpan );
		destructor Destroy; override;

		procedure SetValue( ParaK : string; ParaX : TObject; ParaD : TTimeSpan );
		function Get( ParaK : string; out ParaX : TObject ) : Boolean;
		procedure Delete( ParaK : string );
		procedure Flush;
	end;

implementation

uses
	System.TimeSpan;

{ TCache }

constructor TCache.Create( ParaDefaultExpiration, ParaCleanupInterval : TTimeSpan );
begin
	inherited Create;
	mItems := TDictionary<string, TItem>.Create;
	mDefaultExpiration := ParaDefaultExpiration;
	mCleanupInterval := ParaCleanupInterval;
end;

destructor TCache.Destroy;
begin
	mItems.Free;
	inherited;
end;

procedure TCache.SetValue( ParaK : string; ParaX : TObject; ParaD : TTimeSpan );
var
	vItem : TItem;
begin
	mMu.BeginWrite;
	try
		vItem.mObject := ParaX;
		// Simplified expiration logic
		vItem.mExpiration := 0;
		mItems.AddOrSetValue( ParaK, vItem );
	finally
		mMu.EndWrite;
	end;
end;

function TCache.Get( ParaK : string; out ParaX : TObject ) : Boolean;
var
	vItem : TItem;
begin
	mMu.BeginRead;
	try
		if mItems.TryGetValue( ParaK, vItem ) then
		begin
			ParaX := vItem.mObject;
			Exit( True );
		end;
		ParaX := nil;
		Result := False;
	finally
		mMu.EndRead;
	end;
end;

procedure TCache.Delete( ParaK : string );
begin
	mMu.BeginWrite;
	try
		mItems.Remove( ParaK );
	finally
		mMu.EndWrite;
	end;
end;

procedure TCache.Flush;
begin
	mMu.BeginWrite;
	try
		mItems.Clear;
	finally
		mMu.EndWrite;
	end;
end;

end.
