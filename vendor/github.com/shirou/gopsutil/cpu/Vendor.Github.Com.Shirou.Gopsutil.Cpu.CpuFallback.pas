unit Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFallback;

interface

uses
	Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu;

function FallbackTimes( ParaPercpu : Boolean ) : TArray<TTimesStat>;
function FallbackInfo : TArray<TInfoStat>;
function FallbackCounts( ParaLogical : Boolean ) : Integer;

implementation

function FallbackTimes( ParaPercpu : Boolean ) : TArray<TTimesStat>;
begin
	SetLength( Result, 0 );
end;

function FallbackInfo : TArray<TInfoStat>;
begin
	SetLength( Result, 0 );
end;

function FallbackCounts( ParaLogical : Boolean ) : Integer;
begin
	Result := 0;
end;

end.
