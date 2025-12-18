unit Vendor.Github.Com.Allegro.BigCache.Bytes;

interface

uses
  System.SysUtils,
  Vendor.Github.Com.Allegro.BigCache.BigCache,
  Vendor.Github.Com.Allegro.BigCache.BytesAppEngine,
  Vendor.Github.Com.Allegro.BigCache.Clock,
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

function BytesToString( const ParaB : TBytes ) : string;

implementation

function BytesToString( const ParaB : TBytes ) : string;
begin
	Result := TEncoding.UTF8.GetString( ParaB );
end;

end.
