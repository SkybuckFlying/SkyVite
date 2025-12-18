unit Vendor.Github.Com.Allegro.BigCache.Bytes;

interface

uses
	System.SysUtils;

function BytesToString( const ParaB : TBytes ) : string;

implementation

function BytesToString( const ParaB : TBytes ) : string;
begin
	Result := TEncoding.UTF8.GetString( ParaB );
end;

end.
