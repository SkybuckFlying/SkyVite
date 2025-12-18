unit Vendor.Github.Com.Golang.Snappy.Snappy;

interface

uses
	System.Classes,
	System.SysUtils,
	System.Hash;

const
	tagLiteral = $00;
	tagCopy1   = $01;
	tagCopy2   = $02;
	tagCopy4   = $03;

	checksumSize    = 4;
	chunkHeaderSize = 4;
	magicBody       = 'sNaPpY';

	maxBlockSize = 65536;
	maxEncodedLenOfMaxBlockSize = 76490;

function HashCRC( ParaB : TBytes ) : UInt32;

implementation

function HashCRC( ParaB : TBytes ) : UInt32;
var
	vC : UInt32;
begin
	vC := THashCRC32.GetHashBytes( ParaB );
	Result := ( ( vC shr 15 ) or ( vC shl 17 ) ) + $A282EAD8;
end;

end.
