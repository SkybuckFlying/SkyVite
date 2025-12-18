unit Vendor.Github.Com.Shirou.Gopsutil.Host.HostPosix;

interface

uses
	Vendor.Github.Com.Shirou.Gopsutil.Host.Host;

function PosixUsers : TArray<TUserStat>;

implementation

function PosixUsers : TArray<TUserStat>;
begin
	SetLength( Result, 0 );
end;

end.
