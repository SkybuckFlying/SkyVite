{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Host.HostOpenbsd;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.Shirou.Gopsutil.Host.Types
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.Shirou.Gopsutil.Host.Types
;
{$ENDIF}

function HostIDWithContext : string;
function numProcs : UInt64;
function UsersWithContext : TArray<TUserStat>;
function PlatformInformationWithContext( out ParaPlatform, ParaFamily, ParaVersion : string ) : Boolean;
function VirtualizationWithContext( out ParaSystem, ParaRole : string ) : Boolean;
function SensorsTemperaturesWithContext : TArray<TTemperatureStat>;
function KernelVersionWithContext : string;

implementation

function HostIDWithContext : string;
begin
	Result := '';
end;

function numProcs : UInt64;
begin
	Result := 0;
end;

function UsersWithContext : TArray<TUserStat>;
begin
	Result := nil;
end;

function PlatformInformationWithContext( out ParaPlatform, ParaFamily, ParaVersion : string ) : Boolean;
begin
	Result := False;
end;

function VirtualizationWithContext( out ParaSystem, ParaRole : string ) : Boolean;
begin
	Result := False;
end;

function SensorsTemperaturesWithContext : TArray<TTemperatureStat>;
begin
	Result := nil;
end;

function KernelVersionWithContext : string;
begin
	Result := '';
end;

end.
