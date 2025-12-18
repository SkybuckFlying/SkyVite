unit Vendor.Github.Com.GoOle.GoOle.Utility;

interface

uses
	System.Classes,
	System.SysUtils;

function BstrToString( ParaStr : PWideChar ) : string;
function LpOleStrToString( ParaStr : PWideChar ) : string;

implementation

function BstrToString( ParaStr : PWideChar ) : string;
begin
	Result := string( ParaStr );
end;

function LpOleStrToString( ParaStr : PWideChar ) : string;
begin
	Result := string( ParaStr );
end;

end.
