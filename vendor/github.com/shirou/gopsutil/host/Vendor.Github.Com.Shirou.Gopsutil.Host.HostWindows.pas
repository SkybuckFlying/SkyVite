unit Vendor.Github.Com.Shirou.Gopsutil.Host.HostWindows;

interface

uses
	Winapi.Windows,
	System.SysUtils,
	System.Classes,
	System.Win.Registry,
	System.Math,
	Vendor.Github.Com.Shirou.Gopsutil.Host.Types;

type
	TOSVersionInfoExW = record
		dwOSVersionInfoSize : DWORD;
		dwMajorVersion      : DWORD;
		dwMinorVersion      : DWORD;
		dwBuildNumber       : DWORD;
		dwPlatformId        : DWORD;
		szCSDVersion        : array[ 0..127 ] of WideChar;
		wServicePackMajor   : Word;
		wServicePackMinor   : Word;
		wSuiteMask          : Word;
		wProductType        : Byte;
		wReserved           : Byte;
	end;

function NtQuerySystemInformation(
	ParaSystemInformationClass : Integer;
	ParaSystemInformation      : Pointer;
	ParaSystemInformationLength : DWORD;
	ParaReturnLength           : PDWORD
) : Integer; stdcall; external 'ntdll.dll';

function RtlGetVersion( var ParalpVersionInformation : TOSVersionInfoExW ) : Integer; stdcall; external 'ntdll.dll';

function WinHostID : string;
function WinUptime : UInt64;
function WinBootTime : UInt64;
function WinPlatformInformation( out ParaPlatform, ParaFamily, ParaVersion : string ) : Boolean;
function WinKernelArch : string;

implementation

function WinHostID : string;
var
	vReg : TRegistry;
begin
	Result := '';
	vReg := TRegistry.Create( KEY_READ or KEY_WOW64_64KEY );
	try
		vReg.RootKey := HKEY_LOCAL_MACHINE;
		if vReg.OpenKey( 'SOFTWARE\Microsoft\Cryptography', False ) then
		begin
			Result := vReg.ReadString( 'MachineGuid' ).ToLower;
			vReg.CloseKey;
		end;
	finally
		vReg.Free;
	end;
end;

function WinUptime : UInt64;
begin
	// GetTickCount64 returns milliseconds
	Result := GetTickCount64 div 1000;
end;

function WinBootTime : UInt64;
var
	vUptimeSec : UInt64;
	vNow       : TDateTime;
	vUnixNow   : Int64;
begin
	vUptimeSec := WinUptime;
	vNow := Now;
	vUnixNow := DateTimeToUnix( vNow, False );
	Result := vUnixNow - vUptimeSec;
end;

function WinPlatformInformation( out ParaPlatform, ParaFamily, ParaVersion : string ) : Boolean;
var
	vOSInfo : TOSVersionInfoExW;
	vReg    : TRegistry;
begin
	Result := False;
	FillChar( vOSInfo, SizeOf( vOSInfo ), 0 );
	vOSInfo.dwOSVersionInfoSize := SizeOf( vOSInfo );
	
	if RtlGetVersion( vOSInfo ) <> 0 then
		Exit;

	vReg := TRegistry.Create( KEY_READ or KEY_WOW64_64KEY );
	try
		vReg.RootKey := HKEY_LOCAL_MACHINE;
		if vReg.OpenKey( 'SOFTWARE\Microsoft\Windows NT\CurrentVersion', False ) then
		begin
			ParaPlatform := vReg.ReadString( 'ProductName' );
			if not ParaPlatform.StartsWith( 'Microsoft' ) then
				ParaPlatform := 'Microsoft ' + ParaPlatform;
			
			if vReg.ValueExists( 'CSDVersion' ) then
				ParaPlatform := ParaPlatform + ' ' + vReg.ReadString( 'CSDVersion' );
			vReg.CloseKey;
		end;
	finally
		vReg.Free;
	end;

	case vOSInfo.wProductType of
		1: ParaFamily := 'Standalone Workstation';
		2: ParaFamily := 'Server (Domain Controller)';
		3: ParaFamily := 'Server';
	else
		ParaFamily := 'Unknown';
	end;

	ParaVersion := Format( '%d.%d.%d Build %d', [ vOSInfo.dwMajorVersion, vOSInfo.dwMinorVersion, vOSInfo.dwBuildNumber, vOSInfo.dwBuildNumber ] );
	Result := True;
end;

function WinKernelArch : string;
var
	vSysInfo : TSystemInfo;
begin
	GetNativeSystemInfo( vSysInfo );
	case vSysInfo.wProcessorArchitecture of
		PROCESSOR_ARCHITECTURE_INTEL:
		begin
			if vSysInfo.wProcessorLevel < 3 then Exit( 'i386' );
			if vSysInfo.wProcessorLevel > 6 then Exit( 'i686' );
			Result := Format( 'i%d86', [ vSysInfo.wProcessorLevel ] );
		end;
		PROCESSOR_ARCHITECTURE_ARM: Result := 'arm';
		PROCESSOR_ARCHITECTURE_ARM64: Result := 'aarch64';
		PROCESSOR_ARCHITECTURE_IA64: Result := 'ia64';
		PROCESSOR_ARCHITECTURE_AMD64: Result := 'x86_64';
	else
		Result := 'unknown';
	end;
end;

end.
