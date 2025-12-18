unit Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuLinux;

interface

uses
	Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu;

function LinuxTimes( ParaPercpu : Boolean ) : TArray<TTimesStat>;
function LinuxInfo : TArray<TInfoStat>;
function LinuxCounts( ParaLogical : Boolean ) : Integer;

implementation

function LinuxTimes( ParaPercpu : Boolean ) : TArray<TTimesStat>;
begin
	SetLength( Result, 0 );
end;

function LinuxInfo : TArray<TInfoStat>;
begin
	SetLength( Result, 0 );
end;

function LinuxCounts( ParaLogical : Boolean ) : Integer;
begin
	Result := 0;
end;

end.
