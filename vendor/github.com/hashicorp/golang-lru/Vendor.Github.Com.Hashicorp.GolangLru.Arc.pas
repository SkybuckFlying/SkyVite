unit Vendor.Github.Com.Hashicorp.GolangLru.Arc;

interface

uses
	System.Classes,
	System.SysUtils,
	System.SyncObjs,
	Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.LruInterface,
	Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.Lru;

type
	TARCCache = class
	private
		mSize : Integer;
		mP    : Integer;
		mT1   : ILRUCache;
		mB1   : ILRUCache;
		mT2   : ILRUCache;
		mB2   : ILRUCache;
		mLock : TLightweightMvx;

		procedure Replace( ParaB2ContainsKey : Boolean );
	public
		constructor Create( ParaSize : Integer );
		destructor Destroy; override;

		function Add( ParaKey, ParaValue : TObject ) : Boolean;
		function Get( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
		function Contains( ParaKey : TObject ) : Boolean;
		procedure Purge;
	end;

implementation

{ TARCCache }

constructor TARCCache.Create( ParaSize : Integer );
begin
	inherited Create;
	mSize := ParaSize;
	mP := 0;
	mT1 := TLRU.Create( ParaSize, nil );
	mB1 := TLRU.Create( ParaSize, nil );
	mT2 := TLRU.Create( ParaSize, nil );
	mB2 := TLRU.Create( ParaSize, nil );
end;

destructor TARCCache.Destroy;
begin
	inherited;
end;

function TARCCache.Get( ParaKey : TObject; out ParaValue : TObject ) : Boolean;
begin
	mLock.BeginWrite;
	try
		if mT1.Peek( ParaKey, ParaValue ) then
		begin
			mT1.Remove( ParaKey );
			mT2.Add( ParaKey, ParaValue );
			Exit( True );
		end;

		if mT2.Get( ParaKey, ParaValue ) then
			Exit( True );

		ParaValue := nil;
		Result := False;
	finally
		mLock.EndWrite;
	end;
end;

function TARCCache.Add( ParaKey, ParaValue : TObject ) : Boolean;
var
	vDelta, vB1Len, vB2Len : Integer;
begin
	mLock.BeginWrite;
	try
		if mT1.Contains( ParaKey ) then
		begin
			mT1.Remove( ParaKey );
			mT2.Add( ParaKey, ParaValue );
			Exit( False );
		end;

		if mT2.Contains( ParaKey ) then
		begin
			mT2.Add( ParaKey, ParaValue );
			Exit( False );
		end;

		if mB1.Contains( ParaKey ) then
		begin
			vDelta := 1;
			vB1Len := mB1.Len;
			vB2Len := mB2.Len;
			if vB2Len > vB1Len then
				vDelta := vB2Len div vB1Len;
			
			if mP + vDelta >= mSize then
				mP := mSize
			else
				Inc( mP, vDelta );

			if mT1.Len + mT2.Len >= mSize then
				Replace( False );

			mB1.Remove( ParaKey );
			mT2.Add( ParaKey, ParaValue );
			Exit( False );
		end;

		if mB2.Contains( ParaKey ) then
		begin
			vDelta := 1;
			vB1Len := mB1.Len;
			vB2Len := mB2.Len;
			if vB1Len > vB2Len then
				vDelta := vB1Len div vB2Len;

			if vDelta >= mP then
				mP := 0
			else
				Dec( mP, vDelta );

			if mT1.Len + mT2.Len >= mSize then
				Replace( True );

			mB2.Remove( ParaKey );
			mT2.Add( ParaKey, ParaValue );
			Exit( False );
		end;

		if mT1.Len + mT2.Len >= mSize then
			Replace( False );

		if mB1.Len > mSize - mP then
		begin
			mB1.RemoveOldest( ParaKey, ParaValue );
		end;
		if mB2.Len > mP then
		begin
			mB2.RemoveOldest( ParaKey, ParaValue );
		end;

		mT1.Add( ParaKey, ParaValue );
		Result := False;
	finally
		mLock.EndWrite;
	end;
end;

procedure TARCCache.Replace( ParaB2ContainsKey : Boolean );
var
	vT1Len : Integer;
	vK, vV : TObject;
begin
	vT1Len := mT1.Len;
	if ( vT1Len > 0 ) and ( ( vT1Len > mP ) or ( ( vT1Len = mP ) and ParaB2ContainsKey ) ) then
	begin
		if mT1.RemoveOldest( vK, vV ) then
			mB1.Add( vK, nil );
	end
	else
	begin
		if mT2.RemoveOldest( vK, vV ) then
			mB2.Add( vK, nil );
	end;
end;

function TARCCache.Contains( ParaKey : TObject ) : Boolean;
begin
	mLock.BeginRead;
	try
		Result := mT1.Contains( ParaKey ) or mT2.Contains( ParaKey );
	finally
		mLock.EndRead;
	end;
end;

procedure TARCCache.Purge;
begin
	mLock.BeginWrite;
	try
		mT1.Purge;
		mT2.Purge;
		mB1.Purge;
		mB2.Purge;
	finally
		mLock.EndWrite;
	end;
end;

end.
