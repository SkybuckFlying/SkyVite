{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwinCgo;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.Shirou.Gopsutil.Host.Types
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.Shirou.Gopsutil.Host.Types
;
{$ENDIF}

function SensorsTemperaturesWithContext : TArray<TTemperatureStat>;

implementation

function SensorsTemperaturesWithContext : TArray<TTemperatureStat>;
begin
	Result := nil;
end;

end.
