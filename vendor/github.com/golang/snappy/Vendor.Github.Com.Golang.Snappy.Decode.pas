unit Vendor.Github.Com.Golang.Snappy.Decode;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Golang.Snappy.DecodeAsm,
  Vendor.Github.Com.Golang.Snappy.DecodeOther,
  Vendor.Github.Com.Golang.Snappy.Encode,
  Vendor.Github.Com.Golang.Snappy.EncodeAsm,
  Vendor.Github.Com.Golang.Snappy.EncodeOther,
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
