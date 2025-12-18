unit Vendor.Github.Com.Shirou.Gopsutil.Host.Host;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Math,
	Vendor.Github.Com.Shirou.Gopsutil.Host.Types;

type
	TInfoStat = record
		Hostname             : string;
		Uptime               : UInt64;
		BootTime             : UInt64;
		Procs                : UInt64;
		OS                   : string;
		Platform             : string;
		PlatformFamily       : string;
		PlatformVersion      : string;
		KernelVersion        : string;
		KernelArch           : string;
		VirtualizationSystem : string;
		VirtualizationRole   : string;
		HostID               : string;
		function Stringify : string;
	end;

	TUserStat = record
		User     : string;
		Terminal : string;
		Host     : string;
		Started  : Integer;
		function Stringify : string;
	end;

	TTemperatureStat = record
		SensorKey   : string;
		Temperature : Double;
		function Stringify : string;
	end;

function Info : TInfoStat;
function BootTime : UInt64;
function Uptime : UInt64;
function Users : TArray<TUserStat>;
function PlatformInformation( out ParaPlatform, ParaFamily, ParaVersion : string ) : Boolean;
function HostID : string;
function Virtualization( out ParaSystem, ParaRole : string ) : Boolean;
function KernelVersion : string;
function SensorsTemperatures : TArray<TTemperatureStat>;

implementation

uses
	{$IFDEF MSWINDOWS}
	Vendor.Github.Com.Shirou.Gopsutil.Host.HostWindows
	{$ELSE}
	Vendor.Github.Com.Shirou.Gopsutil.Host.HostFallback
	{$ENDIF}
	;

{ TInfoStat }

function TInfoStat.Stringify : string;
begin
	Result := Format( '{"hostname":"%s","os":"%s","platform":"%s","uptime":%d}', [ Hostname, OS, Platform, Uptime ] );
end;

{ TUserStat }

function TUserStat.Stringify : string;
begin
	Result := Format( '{"user":"%s","terminal":"%s"}', [ User, Terminal ] );
end;

{ TTemperatureStat }

function TTemperatureStat.Stringify : string;
begin
	Result := Format( '{"sensorKey":"%s","temperature":%.1f}', [ SensorKey, Temperature ] );
end;

{ Core functions }

function Info : TInfoStat;
var
	vPlatform, vFamily, vVersion : string;
	vVirtSystem, vVirtRole       : string;
begin
	Result.OS := {$IFDEF MSWINDOWS}'windows'{$ELSE}'unknown'{$ENDIF};
	Result.Hostname := GetEnvironmentVariable( 'COMPUTERNAME' ); // Simplified
	
	if PlatformInformation( vPlatform, vFamily, vVersion ) then
	begin
		Result.Platform := vPlatform;
		Result.PlatformFamily := vFamily;
		Result.PlatformVersion := vVersion;
	end;

	Result.KernelVersion := KernelVersion;
	Result.KernelArch := {$IFDEF MSWINDOWS}WinKernelArch{$ELSE}''{$ENDIF};
	
	if Virtualization( vVirtSystem, vVirtRole ) then
	begin
		Result.VirtualizationSystem := vVirtSystem;
		Result.VirtualizationRole := vVirtRole;
	end;

	Result.BootTime := BootTime;
	Result.Uptime := Uptime;
	Result.HostID := HostID;
	Result.Procs := 0; // Requires process enumeration
end;

function BootTime : UInt64;
begin
	{$IFDEF MSWINDOWS}
	Result := WinBootTime;
	{$ELSE}
	Result := 0;
	{$ENDIF}
end;

function Uptime : UInt64;
begin
	{$IFDEF MSWINDOWS}
	Result := WinUptime;
	{$ELSE}
	Result := 0;
	{$ENDIF}
end;

function Users : TArray<TUserStat>;
begin
	SetLength( Result, 0 );
end;

function PlatformInformation( out ParaPlatform, ParaFamily, ParaVersion : string ) : Boolean;
begin
	{$IFDEF MSWINDOWS}
	Result := WinPlatformInformation( ParaPlatform, ParaFamily, ParaVersion );
	{$ELSE}
	Result := False;
	{$ENDIF}
end;

function HostID : string;
begin
	{$IFDEF MSWINDOWS}
	Result := WinHostID;
	{$ELSE}
	Result := '';
	{$ENDIF}
end;

function Virtualization( out ParaSystem, ParaRole : string ) : Boolean;
begin
	Result := False;
end;

function KernelVersion : string;
var
	vP, vF, vV : string;
begin
	if PlatformInformation( vP, vF, vV ) then
		Result := vV
	else
		Result := '';
end;

function SensorsTemperatures : TArray<TTemperatureStat>;
begin
	SetLength( Result, 0 );
end;

end.
