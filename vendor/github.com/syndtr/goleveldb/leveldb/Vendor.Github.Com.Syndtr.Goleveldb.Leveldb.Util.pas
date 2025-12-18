unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Util;

interface

uses
	System.SysUtils;

function Shorten( const ParaStr : string ) : string;
function ShortenB( ParaBytes : Integer ) : string;
function SShortenB( ParaBytes : Integer ) : string;
function SInt( ParaX : Integer ) : string;
function MinInt( ParaA, ParaB : Integer ) : Integer;
function MaxInt( ParaA, ParaB : Integer ) : Integer;
function EnsureBuffer( const ParaB : TBytes; ParaN : Integer ) : TBytes;

function PutUvarint( var ParaBuf : TBytes; ParaX : UInt64 ) : Integer;
function Uvarint( const ParaBuf : TBytes; out ParaX : UInt64 ) : Integer;

implementation

const
	BUNITS : array[ 0..4 ] of string = ( '', 'Ki', 'Mi', 'Gi', 'Ti' );

function Shorten( const ParaStr : string ) : string;
begin
	if Length( ParaStr ) <= 8 then
		Result := ParaStr
	else
		Result := Copy( ParaStr, 1, 3 ) + '..' + Copy( ParaStr, Length( ParaStr ) - 2, 3 );
end;

function ShortenB( ParaBytes : Integer ) : string;
var
	vI : Integer;
begin
	vI := 0;
	while ( ParaBytes > 1024 ) and ( vI < 4 ) do
	begin
		ParaBytes := ParaBytes div 1024;
		Inc( vI );
	end;
	Result := Format( '%d%sB', [ ParaBytes, BUNITS[ vI ] ] );
end;

function SShortenB( ParaBytes : Integer ) : string;
var
	vSign : string;
	vI : Integer;
begin
	if ParaBytes = 0 then
		Exit( '~' );
	
	vSign := '+';
	if ParaBytes < 0 then
	begin
		vSign := '-';
		ParaBytes := -ParaBytes;
	end;
	
	vI := 0;
	while ( ParaBytes > 1024 ) and ( vI < 4 ) do
	begin
		ParaBytes := ParaBytes div 1024;
		Inc( vI );
	end;
	Result := Format( '%s%d%sB', [ vSign, ParaBytes, BUNITS[ vI ] ] );
end;

function SInt( ParaX : Integer ) : string;
var
	vSign : string;
begin
	if ParaX = 0 then
		Exit( '~' );
	
	vSign := '+';
	if ParaX < 0 then
	begin
		vSign := '-';
		ParaX := -ParaX;
	end;
	Result := Format( '%s%d', [ vSign, ParaX ] );
end;

function MinInt( ParaA, ParaB : Integer ) : Integer;
begin
	if ParaA < ParaB then Result := ParaA else Result := ParaB;
end;

function MaxInt( ParaA, ParaB : Integer ) : Integer;
begin
	if ParaA > ParaB then Result := ParaA else Result := ParaB;
end;

function EnsureBuffer( const ParaB : TBytes; ParaN : Integer ) : TBytes;
begin
	if Length( ParaB ) < ParaN then
		SetLength( Result, ParaN )
	else
		Result := ParaB;
	// In Go, slice shortening is often used. 
	// In Delphi, we copy the bytes if we want to return exactly N bytes from ParaB.
	if Length( Result ) > ParaN then
		SetLength( Result, ParaN );
end;

function PutUvarint( var ParaBuf : TBytes; ParaX : UInt64 ) : Integer;
begin
	Result := 0;
	while ParaX >= $80 do
	begin
		SetLength( ParaBuf, Result + 1 );
		ParaBuf[ Result ] := Byte( ParaX ) or $80;
		ParaX := ParaX shr 7;
		Inc( Result );
	end;
	SetLength( ParaBuf, Result + 1 );
	ParaBuf[ Result ] := Byte( ParaX );
	Inc( Result );
end;

function Uvarint( const ParaBuf : TBytes; out ParaX : UInt64 ) : Integer;
var
	vB : Byte;
	vS : Cardinal;
begin
	ParaX := 0;
	vS := 0;
	for Result := 0 to Length( ParaBuf ) - 1 do
	begin
		vB := ParaBuf[ Result ];
		if vB < $80 then
		begin
			if ( Result > 9 ) or ( ( Result = 9 ) and ( vB > 1 ) ) then
			begin
				ParaX := 0;
				Exit( -( Result + 1 ) ); // Overflow
			end;
			ParaX := ParaX or ( UInt64( vB ) shl vS );
			Inc( Result );
			Exit;
		end;
		ParaX := ParaX or ( UInt64( vB and $7F ) shl vS );
		vS := vS + 7;
	end;
	Result := 0;
end;

end.
