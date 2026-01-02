{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Internal.Common.CommonWindows;

interface

{$IFDEF FPC}
uses
	SysUtils, Windows
;
{$ELSE}
uses
	System.SysUtils, Winapi.Windows
;
{$ENDIF}

const
	PDH_FMT_DOUBLE = $00000200;

function CreateQuery : THandle;
function GetCounterValue( ParaCounter : THandle ) : Double;

implementation

function CreateQuery : THandle;
begin
	Result := 0;
end;

function GetCounterValue( ParaCounter : THandle ) : Double;
begin
	Result := 0.0;
end;

end.
