unit Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFallback;

interface

uses
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwin,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwinCgo,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwinNocgo,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDragonfly,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDragonflyAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsdArm,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuSolaris,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuWindows;

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
