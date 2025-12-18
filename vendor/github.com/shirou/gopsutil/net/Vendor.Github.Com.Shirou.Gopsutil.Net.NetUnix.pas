unit Vendor.Github.Com.Shirou.Gopsutil.Net.NetUnix;

interface

uses
	Vendor.Github.Com.Shirou.Gopsutil.Net.Net;

function UnixConnections( const ParaKind : string ) : TArray<TConnectionStat>;

implementation

function UnixConnections( const ParaKind : string ) : TArray<TConnectionStat>;
begin
	SetLength( Result, 0 );
end;

end.
