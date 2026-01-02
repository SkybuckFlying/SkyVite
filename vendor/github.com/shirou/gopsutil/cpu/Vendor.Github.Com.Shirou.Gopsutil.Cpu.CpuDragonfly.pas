{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDragonfly;

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

function Times( ParaPercpu : Boolean ) : TArray<TTimesStat>;
function Info : TArray<TInfoStat>;
function Counts( ParaLogical : Boolean ) : Integer;

implementation

function Times( ParaPercpu : Boolean ) : TArray<TTimesStat>;
begin
	Result := nil;
end;

function Info : TArray<TInfoStat>;
begin
	Result := nil;
end;

function Counts( ParaLogical : Boolean ) : Integer;
begin
	Result := 0;
end;

end.
