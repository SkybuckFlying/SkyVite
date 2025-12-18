unit Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessPosix;

interface

uses
  Vendor.Github.Com.Shirou.Gopsutil.Process.Process,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessBsd,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwin,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwin386,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwinAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwinArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwinCgo,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwinNocgo,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFallback,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsdArm,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessOpenbsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessOpenbsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessOpenbsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessSolaris,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessWindows,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessWindows386,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessWindowsAmd64;

function PosixPids : TArray<Int32>;

implementation

function PosixPids : TArray<Int32>;
begin
	SetLength( Result, 0 );
end;

end.
