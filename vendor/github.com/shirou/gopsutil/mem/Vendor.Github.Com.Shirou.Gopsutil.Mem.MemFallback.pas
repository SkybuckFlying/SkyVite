unit Vendor.Github.Com.Shirou.Gopsutil.Mem.MemFallback;

interface

uses
  Vendor.Github.Com.Shirou.Gopsutil.Mem.Mem,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemDarwin,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemDarwinCgo,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemDarwinNocgo,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemOpenbsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemOpenbsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemOpenbsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemSolaris,
  Vendor.Github.Com.Shirou.Gopsutil.Mem.MemWindows;

function FallbackVirtualMemory : TVirtualMemoryStat;
function FallbackSwapMemory : TSwapMemoryStat;

implementation

function FallbackVirtualMemory : TVirtualMemoryStat;
begin
	FillChar( Result, SizeOf( Result ), 0 );
end;

function FallbackSwapMemory : TSwapMemoryStat;
begin
	FillChar( Result, SizeOf( Result ), 0 );
end;

end.
