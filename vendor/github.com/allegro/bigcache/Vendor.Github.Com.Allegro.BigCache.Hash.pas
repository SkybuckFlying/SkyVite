unit Vendor.Github.Com.Allegro.BigCache.Hash;

interface

type
	IHasher = interface
		['{D1E2F3A4-B5C6-4D7E-8F90-A1B2C3D4E5F6}']
		function Sum64( ParaKey : string ) : UInt64;
	end;

implementation

end.
