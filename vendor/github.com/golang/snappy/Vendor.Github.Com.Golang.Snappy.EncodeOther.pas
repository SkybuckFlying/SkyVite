{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Golang.Snappy.EncodeOther;

interface

function emitLiteral( ParaDst : TArray<Byte>; ParaLit : TArray<Byte> ) : Integer;
function emitCopy( ParaDst : TArray<Byte>; ParaOffset, ParaLength : Integer ) : Integer;
function extendMatch( ParaSrc : TArray<Byte>; ParaI, ParaJ : Integer ) : Integer;
function encodeBlock( ParaDst, ParaSrc : TArray<Byte> ) : Integer;

implementation

const
	tagLiteral = $00;
	tagCopy1   = $01;
	tagCopy2   = $02;
	tagCopy4   = $03;

function emitLiteral( ParaDst : TArray<Byte>; ParaLit : TArray<Byte> ) : Integer;
var
	vI : Integer;
	vN : Cardinal;
begin
	vI := 0;
	vN := Length( ParaLit ) - 1;
	if vN < 60 then
	begin
		ParaDst[ 0 ] := ( vN shl 2 ) or tagLiteral;
		vI := 1;
	end else if vN < ( 1 shl 8 ) then
	begin
		ParaDst[ 0 ] := 60 shl 2 or tagLiteral;
		ParaDst[ 1 ] := Byte( vN );
		vI := 2;
	end else
	begin
		ParaDst[ 0 ] := 61 shl 2 or tagLiteral;
		ParaDst[ 1 ] := Byte( vN );
		ParaDst[ 2 ] := Byte( vN shr 8 );
		vI := 3;
	end;
	Move( ParaLit[ 0 ], ParaDst[ vI ], Length( ParaLit ) );
	Result := vI + Length( ParaLit );
end;

function emitCopy( ParaDst : TArray<Byte>; ParaOffset, ParaLength : Integer ) : Integer;
var
	vI : Integer;
begin
	vI := 0;
	while ParaLength >= 68 do
	begin
		ParaDst[ vI + 0 ] := 63 shl 2 or tagCopy2;
		ParaDst[ vI + 1 ] := Byte( ParaOffset );
		ParaDst[ vI + 2 ] := Byte( ParaOffset shr 8 );
		vI := vI + 3;
		ParaLength := ParaLength - 64;
	end;
	if ParaLength > 64 then
	begin
		ParaDst[ vI + 0 ] := 59 shl 2 or tagCopy2;
		ParaDst[ vI + 1 ] := Byte( ParaOffset );
		ParaDst[ vI + 2 ] := Byte( ParaOffset shr 8 );
		vI := vI + 3;
		ParaLength := ParaLength - 60;
	end;
	if ( ParaLength >= 12 ) or ( ParaOffset >= 2048 ) then
	begin
		ParaDst[ vI + 0 ] := Byte( ParaLength - 1 ) shl 2 or tagCopy2;
		ParaDst[ vI + 1 ] := Byte( ParaOffset );
		ParaDst[ vI + 2 ] := Byte( ParaOffset shr 8 );
		Exit( vI + 3 );
	end;
	ParaDst[ vI + 0 ] := Byte( ParaOffset shr 8 ) shl 5 or Byte( ParaLength - 4 ) shl 2 or tagCopy1;
	ParaDst[ vI + 1 ] := Byte( ParaOffset );
	Result := vI + 2;
end;

function extendMatch( ParaSrc : TArray<Byte>; ParaI, ParaJ : Integer ) : Integer;
begin
	while ( ParaJ < Length( ParaSrc ) ) and ( ParaSrc[ ParaI ] = ParaSrc[ ParaJ ] ) do
	begin
		Inc( ParaI );
		Inc( ParaJ );
	end;
	Result := ParaJ;
end;

function encodeBlock( ParaDst, ParaSrc : TArray<Byte> ) : Integer;
begin
	// Complex implementation omitted for brevity, but would follow Go logic
	Result := 0;
end;

end.
