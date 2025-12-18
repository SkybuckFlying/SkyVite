unit Vendor.Github.Com.Shirou.Gopsutil.Host.HostPosix;

interface

uses
  Vendor.Github.Com.Shirou.Gopsutil.Host.Host,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostBsd,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwin,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwin386,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwinAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwinArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwinCgo,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostDarwinNocgo,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFallback,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsdArm,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostFreebsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinux386,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxArm,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxMips,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxMips64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxMips64le,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxMipsle,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxPpc64le,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxRiscv64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostLinuxS390x,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostOpenbsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostOpenbsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostOpenbsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostSolaris,
  Vendor.Github.Com.Shirou.Gopsutil.Host.HostWindows,
  Vendor.Github.Com.Shirou.Gopsutil.Host.Types;

function PosixUsers : TArray<TUserStat>;

implementation

function PosixUsers : TArray<TUserStat>;
begin
	SetLength( Result, 0 );
end;

end.
