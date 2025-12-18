unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util;

interface

uses
	System.SysUtils;

type
	EReleased = class( Exception );
	EHasReleaser = class( Exception );

	IReleaser = interface
		['{F5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F6B}']
		procedure Release;
	end;

	IReleaseSetter = interface
		['{E9A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F6C}']
		procedure SetReleaser( const ParaReleaser : IReleaser );
	end;

	TBasicReleaser = class( TInterfacedObject, IReleaser, IReleaseSetter )
	private
		mReleaser : IReleaser;
		mReleased : Boolean;
	protected
		function GetReleased : Boolean; virtual;
	public
		function Released : Boolean;
		procedure Release; virtual;
		procedure SetReleaser( const ParaReleaser : IReleaser ); virtual;
	end;

	TNoopReleaser = class( TInterfacedObject, IReleaser )
	public
		procedure Release;
	end;

implementation

{ TBasicReleaser }

function TBasicReleaser.GetReleased : Boolean;
begin
	Result := mReleased;
end;

function TBasicReleaser.Released : Boolean;
begin
	Result := GetReleased;
end;

procedure TBasicReleaser.Release;
begin
	if not mReleased then
	begin
		if mReleaser <> nil then
		begin
			mReleaser.Release;
			mReleaser := nil;
		end;
		mReleased := true;
	end;
end;

procedure TBasicReleaser.SetReleaser( const ParaReleaser : IReleaser );
begin
	if mReleased then
		raise EReleased.Create( 'leveldb: resource already released' );
	
	if ( mReleaser <> nil ) and ( ParaReleaser <> nil ) then
		raise EHasReleaser.Create( 'leveldb: releaser already defined' );
	
	mReleaser := ParaReleaser;
end;

{ TNoopReleaser }

procedure TNoopReleaser.Release;
begin
	// No-op
end;

end.
