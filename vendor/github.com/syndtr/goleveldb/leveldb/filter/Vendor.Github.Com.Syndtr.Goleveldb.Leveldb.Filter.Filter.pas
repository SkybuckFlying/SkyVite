unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter.Filter;

interface

uses
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Filter.Bloom;

type
	IBuffer = interface
		['{F5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F6F}']
		function Alloc( ParaN : Integer ) : TBytes;
		procedure Write( const ParaP : TBytes; out ParaN : Integer );
		procedure WriteByte( ParaC : Byte );
	end;

	IFilterGenerator = interface
		['{E9A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F70}']
		procedure Add( const ParaKey : TBytes );
		procedure Generate( const ParaBuffer : IBuffer );
	end;

	IFilter = interface
		['{D5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F71}']
		function Name : string;
		function NewGenerator : IFilterGenerator;
		function Contains( const ParaFilter, ParaKey : TBytes ) : Boolean;
	end;

implementation

end.
