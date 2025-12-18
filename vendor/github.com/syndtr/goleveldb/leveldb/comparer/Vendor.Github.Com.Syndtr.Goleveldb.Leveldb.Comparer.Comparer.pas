unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.Comparer;

interface

type
	IBasicComparer = interface
		['{C5A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F6D}']
		function Compare( const a, b : TBytes ) : Integer;
	end;

	IComparer = interface( IBasicComparer )
		['{E9A8B6C7-8D1F-4B1C-AF2A-1B2C3D4E5F6E}']
		function Name : string;
		function Separator( const dst, a, b : TBytes ) : TBytes;
		function Successor( const dst, b : TBytes ) : TBytes;
	end;

implementation

end.
