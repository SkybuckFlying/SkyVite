{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.GoOle.GoOle.ErrorWindows;

interface

function errstr( ParaErrno : Integer ) : string;

implementation

{$IFDEF FPC}
uses
	SysUtils
;
{$ELSE}
uses
	System.SysUtils
;
{$ENDIF}

// errstr converts error code to string.
function errstr( ParaErrno : Integer ) : string;
begin
	Result := SysErrorMessage( ParaErrno );
end;

end.
