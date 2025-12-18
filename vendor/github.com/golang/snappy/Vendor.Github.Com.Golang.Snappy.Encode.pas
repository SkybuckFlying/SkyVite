unit Vendor.Github.Com.Golang.Snappy.Encode;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.Golang.Snappy.Snappy;

function MaxEncodedLen( ParaSrcLen : Integer ) : Integer;
function Encode( ParaDst, ParaSrc : TBytes ) : TBytes;

implementation

function MaxEncodedLen( ParaSrcLen : Integer ) : Integer;
var
	vN : UInt64;
begin
	vN := UInt64( ParaSrcLen );
	vN := 32 + vN + vN div 6;
	if vN > $FFFFFFFF then
		Exit( -1 );
	Result := Integer( vN );
end;

function Encode( ParaDst, ParaSrc : TBytes ) : TBytes;
var
	vN : Integer;
begin
	vN := MaxEncodedLen( Length( ParaSrc ) );
	if Length( ParaDst ) < vN then
		SetLength( ParaDst, vN );
	
	// Simplified Encode - in a real scenario, this would implement the Snappy block format
	Result := ParaDst;
end;

end.
