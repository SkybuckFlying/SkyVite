unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Hash;

interface

uses
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Buffer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.BufferPool,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Crc32,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Range,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util.Util;

function Hash( const ParaData : TBytes; ParaSeed : UInt32 ) : UInt32;

implementation

function Hash( const ParaData : TBytes; ParaSeed : UInt32 ) : UInt32;
const
	m = UInt32( $C6A4A793 );
	r = UInt32( 24 );
var
	h : UInt32;
	i, n : Integer;
begin
	h := ParaSeed xor ( UInt32( Length( ParaData ) ) * m );
	i := 0;
	n := Length( ParaData ) - ( Length( ParaData ) mod 4 );
	
	while i < n do
	begin
		h := h + PUint32( @ParaData[ i ] )^;
		h := h * m;
		h := h xor ( h shr 16 );
		Inc( i, 4 );
	end;

	case Length( ParaData ) - i of
		3:
		begin
			h := h + ( UInt32( ParaData[ i + 2 ] ) shl 16 );
			h := h + ( UInt32( ParaData[ i + 1 ] ) shl 8 );
			h := h + UInt32( ParaData[ i ] );
			h := h * m;
			h := h xor ( h shr r );
		end;
		2:
		begin
			h := h + ( UInt32( ParaData[ i + 1 ] ) shl 8 );
			h := h + UInt32( ParaData[ i ] );
			h := h * m;
			h := h xor ( h shr r );
		end;
		1:
		begin
			h := h + UInt32( ParaData[ i ] );
			h := h * m;
			h := h xor ( h shr r );
		end;
	end;

	Result := h;
end;

end.
