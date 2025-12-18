unit Vendor.Github.Com.Allegro.BigCache.Hash;

interface
uses
  Vendor.Github.Com.Allegro.BigCache.BigCache,
  Vendor.Github.Com.Allegro.BigCache.Bytes,
  Vendor.Github.Com.Allegro.BigCache.BytesAppEngine,
  Vendor.Github.Com.Allegro.BigCache.Clock,
  Vendor.Github.Com.Allegro.BigCache.Config,
  Vendor.Github.Com.Allegro.BigCache.Encoding,
  Vendor.Github.Com.Allegro.BigCache.EntryNotFoundError,
  Vendor.Github.Com.Allegro.BigCache.Fnv,
  Vendor.Github.Com.Allegro.BigCache.Iterator,
  Vendor.Github.Com.Allegro.BigCache.Logger,
  Vendor.Github.Com.Allegro.BigCache.Shard,
  Vendor.Github.Com.Allegro.BigCache.Stats,
  Vendor.Github.Com.Allegro.BigCache.Utils;

type
	IHasher = interface
		['{D1E2F3A4-B5C6-4D7E-8F90-A1B2C3D4E5F6}']
		function Sum64( ParaKey : string ) : UInt64;
	end;

implementation

end.
