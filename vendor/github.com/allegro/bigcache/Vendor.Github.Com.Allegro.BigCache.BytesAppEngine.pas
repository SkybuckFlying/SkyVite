{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Allegro.BigCache.BytesAppEngine;

interface

implementation

{$IFDEF FPC}
uses
	SysUtils;
{$ELSE}
uses
	System.SysUtils;
{$ENDIF}

function bytesToString
(
	ParaB : TBytes
) : string;
begin
	Result := TEncoding.UTF8.GetString( ParaB );
end;

end.
