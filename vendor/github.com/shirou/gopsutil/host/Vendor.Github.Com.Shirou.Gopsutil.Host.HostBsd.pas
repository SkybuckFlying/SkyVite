{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Host.HostBsd;

interface

{$IFDEF FPC}
uses
	SysUtils
;
{$ELSE}
uses
	System.SysUtils
;
{$ENDIF}

function BootTimeWithContext : UInt64;
function UptimeWithContext : UInt64;

implementation

function BootTimeWithContext : UInt64;
begin
	Result := 0;
end;

function UptimeWithContext : UInt64;
begin
	Result := 0;
end;

end.
