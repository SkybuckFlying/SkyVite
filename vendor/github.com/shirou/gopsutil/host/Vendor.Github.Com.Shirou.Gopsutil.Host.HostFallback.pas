unit Vendor.Github.Com.Shirou.Gopsutil.Host.HostFallback;

interface

function FallbackHostID : string;
function FallbackUptime : UInt64;
function FallbackBootTime : UInt64;
function FallbackPlatformInformation( out ParaPlatform, ParaFamily, ParaVersion : string ) : Boolean;
function FallbackKernelVersion : string;

implementation

function FallbackHostID : string;
begin
	Result := '';
end;

function FallbackUptime : UInt64;
begin
	Result := 0;
end;

function FallbackBootTime : UInt64;
begin
	Result := 0;
end;

function FallbackPlatformInformation( out ParaPlatform, ParaFamily, ParaVersion : string ) : Boolean;
begin
	Result := False;
end;

function FallbackKernelVersion : string;
begin
	Result := '';
end;

end.
