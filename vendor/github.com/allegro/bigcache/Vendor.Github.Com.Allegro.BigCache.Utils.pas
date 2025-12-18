unit Vendor.Github.Com.Allegro.BigCache.Utils;

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
  Vendor.Github.Com.Allegro.BigCache.Hash,
  Vendor.Github.Com.Allegro.BigCache.Iterator,
  Vendor.Github.Com.Allegro.BigCache.Logger,
  Vendor.Github.Com.Allegro.BigCache.Shard,
  Vendor.Github.Com.Allegro.BigCache.Stats;

function Max( ParaA, ParaB : Integer ) : Integer;
function ConvertMBToBytes( ParaValue : Integer ) : Integer;
function IsPowerOfTwo( ParaNumber : Integer ) : Boolean;

implementation

function Max( ParaA, ParaB : Integer ) : Integer;
begin
	if ParaA > ParaB then
	begin
		Result := ParaA;
	end else
	begin
		Result := ParaB;
	end;
end;

function ConvertMBToBytes( ParaValue : Integer ) : Integer;
begin
	Result := ParaValue * 1024 * 1024;
end;

function IsPowerOfTwo( ParaNumber : Integer ) : Boolean;
begin
	Result := ( ParaNumber > 0 ) and ( ( ParaNumber and ( ParaNumber - 1 ) ) = 0 );
end;

end.
