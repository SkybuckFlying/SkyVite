unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Table;

interface

uses
  System.SysUtils,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Reader,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Table.Writer,
  Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util;

const
	BLOCK_TRAILER_LEN = 5;
	FOOTER_LEN        = 48;
	MAGIC = AnsiString( #$57#$FB#$80#$8B#$24#$75#$47#$DB );

	BLOCK_TYPE_NO_COMPRESSION     = 0;
	BLOCK_TYPE_SNAPPY_COMPRESSION = 1;

type
	TBlockHandle = record
		Offset, Length : UInt64;
		function Stringify : string;
	end;

function DecodeBlockHandle( const ParaSrc : TBytes; out ParaHandle : TBlockHandle ) : Integer;
function EncodeBlockHandle( var ParaDst : TBytes; const ParaHandle : TBlockHandle ) : Integer;

implementation

{ TBlockHandle }

function TBlockHandle.Stringify : string;
begin
	Result := Format( '{Offset: %d, Length: %d}', [ Offset, Length ] );
end;

function DecodeBlockHandle( const ParaSrc : TBytes; out ParaHandle : TBlockHandle ) : Integer;
var
	vN, vM : Integer;
	vOffset, vLength : UInt64;
begin
	vN := Uvarint( ParaSrc, vOffset );
	if vN <= 0 then Exit( 0 );
	
	vM := Uvarint( Copy( ParaSrc, vN, Length( ParaSrc ) - vN ), vLength );
	if vM <= 0 then Exit( 0 );
	
	ParaHandle.Offset := vOffset;
	ParaHandle.Length := vLength;
	Result := vN + vM;
end;

function EncodeBlockHandle( var ParaDst : TBytes; const ParaHandle : TBlockHandle ) : Integer;
var
	vN, vM : Integer;
	vBuf : TBytes;
begin
	SetLength( vBuf, 0 );
	vN := PutUvarint( vBuf, ParaHandle.Offset );
	vM := PutUvarint( vBuf, ParaHandle.Length ); // Note: PutUvarint appends to the buffer in our implementation if we adjust it, but here I'll redo it.
	
	// REDO: Our PutUvarint appends. Let's make it more robust.
	SetLength( ParaDst, 0 );
	vN := PutUvarint( ParaDst, ParaHandle.Offset );
	
	SetLength( vBuf, 0 );
	vM := PutUvarint( vBuf, ParaHandle.Length );
	ParaDst := ParaDst + vBuf;
	
	Result := vN + vM;
end;

end.
