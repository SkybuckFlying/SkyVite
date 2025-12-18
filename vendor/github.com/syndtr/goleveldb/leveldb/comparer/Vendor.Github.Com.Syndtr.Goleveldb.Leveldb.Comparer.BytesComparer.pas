unit Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.BytesComparer;

interface

uses
	System.SysUtils,
	Vendor.Github.Com.Syndtr.Goleveldb.Leveldb.Comparer.Comparer;

type
	TBytesComparer = class( TInterfacedObject, IBasicComparer, IComparer )
	public
		function Compare( const a, b : TBytes ) : Integer;
		function Name : string;
		function Separator( const dst, a, b : TBytes ) : TBytes;
		function Successor( const dst, b : TBytes ) : TBytes;
	end;

var
	DefaultComparer : IComparer;

implementation

{ TBytesComparer }

function TBytesComparer.Compare( const a, b : TBytes ) : Integer;
var
	lenA, lenB, n, i : Integer;
begin
	lenA := Length( a );
	lenB := Length( b );
	n := lenA;
	if lenB < n then n := lenB;
	
	for i := 0 to n - 1 do
	begin
		if a[ i ] < b[ i ] then Exit( -1 );
		if a[ i ] > b[ i ] then Exit( 1 );
	end;
	
	if lenA < lenB then Result := -1
	else if lenA > lenB then Result := 1
	else Result := 0;
end;

function TBytesComparer.Name : string;
begin
	Result := 'leveldb.BytewiseComparator';
end;

function TBytesComparer.Separator( const dst, a, b : TBytes ) : TBytes;
var
	i, n : Integer;
	c : Byte;
begin
	i := 0;
	n := Length( a );
	if Length( b ) < n then n := Length( b );
	
	while ( i < n ) and ( a[ i ] = b[ i ] ) do
		Inc( i );
	
	if i >= n then
	begin
		// Do not shorten
	end
	else
	begin
		c := a[ i ];
		if ( c < $FF ) and ( c + 1 < b[ i ] ) then
		begin
			Result := Copy( dst );
			Result := Result + Copy( a, 0, i + 1 );
			Result[ Length( Result ) - 1 ] := Result[ Length( Result ) - 1 ] + 1;
			Exit;
		end;
	end;
	Result := nil;
end;

function TBytesComparer.Successor( const dst, b : TBytes ) : TBytes;
var
	i : Integer;
	c : Byte;
begin
	for i := 0 to Length( b ) - 1 do
	begin
		c := b[ i ];
		if c <> $FF then
		begin
			Result := Copy( dst );
			Result := Result + Copy( b, 0, i + 1 );
			Result[ Length( Result ) - 1 ] := Result[ Length( Result ) - 1 ] + 1;
			Exit;
		end;
	end;
	Result := nil;
end;

initialization
	DefaultComparer := TBytesComparer.Create;

end.
