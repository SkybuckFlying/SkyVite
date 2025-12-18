unit Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwin;

interface

uses
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwinCgo,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwinNocgo,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDragonfly,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDragonflyAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFallback,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsdArm,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuSolaris,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuWindows;

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
