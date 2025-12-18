unit Vendor.Github.Com.Shirou.Gopsutil.Net.NetUnix;

interface

uses
  Vendor.Github.Com.Shirou.Gopsutil.Net.Net,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetAix,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetDarwin,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetFallback,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Net.NetWindows;

function UnixConnections( const ParaKind : string ) : TArray<TConnectionStat>;

implementation

function UnixConnections( const ParaKind : string ) : TArray<TConnectionStat>;
begin
	SetLength( Result, 0 );
end;

end.
