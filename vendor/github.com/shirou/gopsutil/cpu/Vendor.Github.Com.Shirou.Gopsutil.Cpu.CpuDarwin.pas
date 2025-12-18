unit Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwin;

interface

uses
	Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu;

function DarwinTimes( ParaPercpu : Boolean ) : TArray<TTimesStat>;
function DarwinInfo : TArray<TInfoStat>;
function DarwinCounts( ParaLogical : Boolean ) : Integer;

implementation

function DarwinTimes( ParaPercpu : Boolean ) : TArray<TTimesStat>;
begin
	SetLength( Result, 0 );
end;

function DarwinInfo : TArray<TInfoStat>;
begin
	SetLength( Result, 0 );
end;

function DarwinCounts( ParaLogical : Boolean ) : Integer;
begin
	Result := 0;
end;

end.
