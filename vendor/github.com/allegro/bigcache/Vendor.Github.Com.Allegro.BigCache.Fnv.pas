unit Vendor.Github.Com.Allegro.BigCache.Fnv;

interface

uses
  Vendor.Github.Com.Allegro.BigCache.BigCache,
  Vendor.Github.Com.Allegro.BigCache.Bytes,
  Vendor.Github.Com.Allegro.BigCache.BytesAppEngine,
  Vendor.Github.Com.Allegro.BigCache.Clock,
  Vendor.Github.Com.Allegro.BigCache.Config,
  Vendor.Github.Com.Allegro.BigCache.Encoding,
  Vendor.Github.Com.Allegro.BigCache.EntryNotFoundError,
  Vendor.Github.Com.Allegro.BigCache.Hash,
  Vendor.Github.Com.Allegro.BigCache.Iterator,
  Vendor.Github.Com.Allegro.BigCache.Logger,
  Vendor.Github.Com.Allegro.BigCache.Shard,
  Vendor.Github.Com.Allegro.BigCache.Stats,
  Vendor.Github.Com.Allegro.BigCache.Utils;

type
	Tfnv64a = class(TInterfacedObject, IHasher)
	public
		function Sum64( ParaKey : string ) : UInt64;
	end;

function NewDefaultHasher : IHasher;

implementation

const
	Const_Offset64 = UInt64(14695981039346656037);
	Const_Prime64 = UInt64(1099511628211);

function NewDefaultHasher : IHasher;
begin
	Result := Tfnv64a.Create;
end;

{ Tfnv64a }

function Tfnv64a.Sum64( ParaKey : string ) : UInt64;
var
	vHash : UInt64;
	vIndex : Integer;
begin
	vHash := Const_Offset64;
	for vIndex := 1 to Length( ParaKey ) do
	begin
		vHash := vHash xor UInt64( Ord( ParaKey[vIndex] ) );
		vHash := vHash * Const_Prime64;
	end;
	Result := vHash;
end;

end.
