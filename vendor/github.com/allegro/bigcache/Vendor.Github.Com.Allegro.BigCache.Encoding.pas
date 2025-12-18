unit Vendor.Github.Com.Allegro.BigCache.Encoding;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Allegro.BigCache.BigCache,
  Vendor.Github.Com.Allegro.BigCache.Bytes,
  Vendor.Github.Com.Allegro.BigCache.BytesAppEngine,
  Vendor.Github.Com.Allegro.BigCache.Clock,
  Vendor.Github.Com.Allegro.BigCache.Config,
  Vendor.Github.Com.Allegro.BigCache.EntryNotFoundError,
  Vendor.Github.Com.Allegro.BigCache.Fnv,
  Vendor.Github.Com.Allegro.BigCache.Hash,
  Vendor.Github.Com.Allegro.BigCache.Iterator,
  Vendor.Github.Com.Allegro.BigCache.Logger,
  Vendor.Github.Com.Allegro.BigCache.Shard,
  Vendor.Github.Com.Allegro.BigCache.Stats,
  Vendor.Github.Com.Allegro.BigCache.Utils;

const
	Const_TimestampSizeInBytes = 8;
	Const_HashSizeInBytes      = 8;
	Const_KeySizeInBytes       = 2;
	Const_HeadersSizeInBytes   = Const_TimestampSizeInBytes + Const_HashSizeInBytes + Const_KeySizeInBytes;

function WrapEntry( ParaTimestamp : UInt64; ParaHash : UInt64; ParaKey : string; ParaEntry : TBytes; var ParaBuffer : TBytes ) : TBytes;
function ReadEntry( const ParaData : TBytes ) : TBytes;
function ReadTimestampFromEntry( const ParaData : TBytes ) : UInt64;
function ReadKeyFromEntry( const ParaData : TBytes ) : string;
function ReadHashFromEntry( const ParaData : TBytes ) : UInt64;
procedure ResetKeyFromEntry( var ParaData : TBytes );

implementation

function WrapEntry( ParaTimestamp : UInt64; ParaHash : UInt64; ParaKey : string; ParaEntry : TBytes; var ParaBuffer : TBytes ) : TBytes;
var
	vKeyBytes : TBytes;
	vKeyLength : Integer;
	vBlobLength : Integer;
begin
	vKeyBytes := TEncoding.UTF8.GetBytes( ParaKey );
	vKeyLength := Length( vKeyBytes );
	vBlobLength := Length( ParaEntry ) + Const_HeadersSizeInBytes + vKeyLength;

	if vBlobLength > Length( ParaBuffer ) then
	begin
		SetLength( ParaBuffer, vBlobLength );
	end;

	Move( ParaTimestamp, ParaBuffer[0], 8 );
	Move( ParaHash, ParaBuffer[8], 8 );
	Move( vKeyLength, ParaBuffer[16], 2 );
	Move( vKeyBytes[0], ParaBuffer[Const_HeadersSizeInBytes], vKeyLength );
	Move( ParaEntry[0], ParaBuffer[Const_HeadersSizeInBytes + vKeyLength], Length( ParaEntry ) );

	Result := Copy( ParaBuffer, 0, vBlobLength );
end;

function ReadEntry( const ParaData : TBytes ) : TBytes;
var
	vKeyLength : Word;
begin
	Move( ParaData[16], vKeyLength, 2 );
	Result := Copy( ParaData, Const_HeadersSizeInBytes + vKeyLength, Length( ParaData ) - ( Const_HeadersSizeInBytes + vKeyLength ) );
end;

function ReadTimestampFromEntry( const ParaData : TBytes ) : UInt64;
begin
	Move( ParaData[0], Result, 8 );
end;

function ReadKeyFromEntry( const ParaData : TBytes ) : string;
var
	vKeyLength : Word;
	vKeyBytes : TBytes;
begin
	Move( ParaData[16], vKeyLength, 2 );
	vKeyBytes := Copy( ParaData, Const_HeadersSizeInBytes, vKeyLength );
	Result := BytesToString( vKeyBytes );
end;

function ReadHashFromEntry( const ParaData : TBytes ) : UInt64;
begin
	Move( ParaData[8], Result, 8 );
end;

procedure ResetKeyFromEntry( var ParaData : TBytes );
var
	vZero : UInt64;
begin
	vZero := 0;
	Move( vZero, ParaData[8], 8 );
end;

end.
