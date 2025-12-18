unit Vendor.Github.Com.Allegro.BigCache.Clock;

interface

uses
  System.DateUtils,
  System.SysUtils,
  Vendor.Github.Com.Allegro.BigCache.BigCache,
  Vendor.Github.Com.Allegro.BigCache.Bytes,
  Vendor.Github.Com.Allegro.BigCache.BytesAppEngine,
  Vendor.Github.Com.Allegro.BigCache.Config,
  Vendor.Github.Com.Allegro.BigCache.Encoding,
  Vendor.Github.Com.Allegro.BigCache.EntryNotFoundError,
  Vendor.Github.Com.Allegro.BigCache.Fnv,
  Vendor.Github.Com.Allegro.BigCache.Hash,
  Vendor.Github.Com.Allegro.BigCache.Iterator,
  Vendor.Github.Com.Allegro.BigCache.Logger,
  Vendor.Github.Com.Allegro.BigCache.Shard,
  Vendor.Github.Com.Allegro.BigCache.Stats,
  Vendor.Github.Com.Allegro.BigCache.Utils;

type
	IClock = interface
		['{B1E2D3C4-F5E6-4D7C-A8B9-C0E1D2A3B4C5}']
		function Epoch : Int64;
	end;

	TSystemClock = class(TInterfacedObject, IClock)
	public
		function Epoch : Int64;
	end;

implementation

{ TSystemClock }

function TSystemClock.Epoch : Int64;
begin
	Result := DateTimeToUnix( Now );
end;

end.
