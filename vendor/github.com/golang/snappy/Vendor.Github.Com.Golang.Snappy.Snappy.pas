unit Vendor.Github.Com.Golang.Snappy.Snappy;

interface

uses
  System.Classes,
  System.Hash,
  System.SysUtils,
  Vendor.Github.Com.Golang.Snappy.Decode,
  Vendor.Github.Com.Golang.Snappy.DecodeAsm,
  Vendor.Github.Com.Golang.Snappy.DecodeOther,
  Vendor.Github.Com.Golang.Snappy.Encode,
  Vendor.Github.Com.Golang.Snappy.EncodeAsm,
  Vendor.Github.Com.Golang.Snappy.EncodeOther;

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
