unit Vendor.Github.Com.Golang.Snappy.Decode;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.Golang.Snappy.Snappy;

function DecodedLen( ParaSrc : TBytes ) : Integer;
function Decode( ParaDst, ParaSrc : TBytes ) : TBytes;

implementation

function DecodedLen( ParaSrc : TBytes ) : Integer;
begin
	// Simplified DecodedLen
	Result := 0;
end;

function Decode( ParaDst, ParaSrc : TBytes ) : TBytes;
begin
	// Simplified Decode
	Result := ParaDst;
end;

end.
