{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwinCgo;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu
;
{$ENDIF}

function perCPUTimes : TArray<TTimesStat>;
function allCPUTimes : TArray<TTimesStat>;

implementation

const
	ConstClocksPerSec = 100.0;

function perCPUTimes : TArray<TTimesStat>;
begin
	Result := nil;
end;

function allCPUTimes : TArray<TTimesStat>;
begin
	Result := nil;
end;

end.
