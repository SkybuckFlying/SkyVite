unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter;

interface

uses
	System.SysUtils,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter.Filter,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Key;

type
	TInternalFilterGenerator = class( TInterfacedObject, IFilterGenerator )
	private
		mGen : IFilterGenerator;
	public
		constructor Create( const ParaGen : IFilterGenerator );
		procedure Add( const ParaKey : TBytes );
		procedure Generate( const ParaBuffer : IBuffer );
	end;

	TInternalFilter = class( TInterfacedObject, IFilter )
	private
		mFilter : IFilter;
	public
		constructor Create( const ParaFilter : IFilter );
		function Name : string;
		function NewGenerator : IFilterGenerator;
		function Contains( const ParaFilter, ParaKey : TBytes ) : Boolean;
	end;

implementation

{ TInternalFilterGenerator }

constructor TInternalFilterGenerator.Create( const ParaGen : IFilterGenerator );
begin
	inherited Create;
	mGen := ParaGen;
end;

procedure TInternalFilterGenerator.Add( const ParaKey : TBytes );
begin
	mGen.Add( TInternalKey( ParaKey ).Ukey );
end;

procedure TInternalFilterGenerator.Generate( const ParaBuffer : IBuffer );
begin
	mGen.Generate( ParaBuffer );
end;

{ TInternalFilter }

constructor TInternalFilter.Create( const ParaFilter : IFilter );
begin
	inherited Create;
	mFilter := ParaFilter;
end;

function TInternalFilter.Name : string;
begin
	Result := mFilter.Name;
end;

function TInternalFilter.NewGenerator : IFilterGenerator;
begin
	Result := TInternalFilterGenerator.Create( mFilter.NewGenerator );
end;

function TInternalFilter.Contains( const ParaFilter, ParaKey : TBytes ) : Boolean;
begin
	Result := mFilter.Contains( ParaFilter, TInternalKey( ParaKey ).Ukey );
end;

end.
