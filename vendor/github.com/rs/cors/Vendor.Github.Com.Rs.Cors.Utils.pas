unit Vendor.Github.Com.Rs.Cors.Utils;

interface

uses
	System.SysUtils,
	System.Classes;

type
	TConverter = reference to function( const ParaS : string ) : string;

	TWildcard = record
		Prefix : string;
		Suffix : string;
		function Match( const ParaS : string ) : Boolean;
	end;

function Convert( const ParaS : TArray<string>; ParaC : TConverter ) : TArray<string>;
function ParseHeaderList( ParaHeaderList : string ) : TArray<string>;

implementation

{ TWildcard }

function TWildcard.Match( const ParaS : string ) : Boolean;
begin
	Result := ( Length( ParaS ) >= Length( Prefix ) + Length( Suffix ) ) and
		ParaS.StartsWith( Prefix ) and ParaS.EndsWith( Suffix );
end;

{ Functions }

function Convert( const ParaS : TArray<string>; ParaC : TConverter ) : TArray<string>;
var
	vI : Integer;
begin
	SetLength( Result, Length( ParaS ) );
	for vI := 0 to High( ParaS ) do
		Result[ vI ] := ParaC( ParaS[ vI ] );
end;

function ParseHeaderList( ParaHeaderList : string ) : TArray<string>;
var
	vL     : Integer;
	vH     : TBytes;
	vUpper : Boolean;
	vT     : Integer;
	vI     : Integer;
	vB     : Byte;
	vS     : string;
	vResultList : TStringList;
begin
	vL := Length( ParaHeaderList );
	if vL = 0 then
		Exit( nil );

	vResultList := TStringList.Create;
	try
		SetLength( vH, 0 );
		vUpper := True;
		
		for vI := 1 to vL do
		begin
			vB := Ord( ParaHeaderList[ vI ] );
			case vB of
				Ord( 'a' )..Ord( 'z' ):
				begin
					if vUpper then
						vB := vB - ( Ord( 'a' ) - Ord( 'A' ) );
					SetLength( vH, Length( vH ) + 1 );
					vH[ High( vH ) ] := vB;
				end;
				Ord( 'A' )..Ord( 'Z' ):
				begin
					if not vUpper then
						vB := vB + ( Ord( 'a' ) - Ord( 'A' ) );
					SetLength( vH, Length( vH ) + 1 );
					vH[ High( vH ) ] := vB;
				end;
				Ord( '-' ), Ord( '_' ), Ord( '.' ), Ord( '0' )..Ord( '9' ):
				begin
					SetLength( vH, Length( vH ) + 1 );
					vH[ High( vH ) ] := vB;
				end;
			end;

			if ( vB = Ord( ' ' ) ) or ( vB = Ord( ',' ) ) or ( vI = vL ) then
			begin
				if Length( vH ) > 0 then
				begin
					vS := TEncoding.ANSI.GetString( vH );
					vResultList.Add( vS );
					SetLength( vH, 0 );
					vUpper := True;
				end;
			end
			else
			begin
				vUpper := ( vB = Ord( '-' ) ) or ( vB = Ord( '_' ) );
			end;
		end;
		Result := vResultList.ToStringArray;
	finally
		vResultList.Free;
	end;
end;

end.
