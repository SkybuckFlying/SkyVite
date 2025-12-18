unit Vendor.Github.Com.Shirou.Gopsutil.Net.NetFallback;

interface

uses
	Vendor.Github.Com.Shirou.Gopsutil.Net.Net;

function FallbackInterfaces : TArray<TInterfaceStat>;
function FallbackIOCounters( ParaPernic : Boolean ) : TArray<TIOCountersStat>;
function FallbackConnections( const ParaKind : string ) : TArray<TConnectionStat>;

implementation

function FallbackInterfaces : TArray<TInterfaceStat>;
begin
	SetLength( Result, 0 );
end;

function FallbackIOCounters( ParaPernic : Boolean ) : TArray<TIOCountersStat>;
begin
	SetLength( Result, 0 );
end;

function FallbackConnections( const ParaKind : string ) : TArray<TConnectionStat>;
begin
	SetLength( Result, 0 );
end;

end.
