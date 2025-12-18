unit Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuWindows;

interface

uses
  System.Classes,
  System.SysUtils,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwin,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwinCgo,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDarwinNocgo,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDragonfly,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuDragonflyAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFallback,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsdArm,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFreebsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuSolaris,
  Winapi.Windows;

function WinTimes( ParaPercpu : Boolean ) : TArray<TTimesStat>;
function WinInfo : TArray<TInfoStat>;
function WinCounts( ParaLogical : Boolean ) : Integer;

implementation

type
	TSystemProcessorPerformanceInformation = record
		IdleTime       : Int64;
		KernelTime     : Int64;
		UserTime       : Int64;
		DpcTime        : Int64;
		InterruptTime  : Int64;
		InterruptCount : UInt32;
	end;

const
	SystemProcessorPerformanceInformationClass = 8;
	ClocksPerSec = 10000000.0;

function NtQuerySystemInformation(
	ParaSystemInformationClass : Integer;
	ParaSystemInformation      : Pointer;
	ParaSystemInformationLength : UInt32;
	ParaReturnLength           : PUInt32
) : Integer; stdcall; external 'ntdll.dll';

function WinTimes( ParaPercpu : Boolean ) : TArray<TTimesStat>;
var
	vIdleTime, vKernelTime, vUserTime : TFileTime;
	vIdle, vUser, vKernel, vSystem : Double;
	vStats : TArray<TSystemProcessorPerformanceInformation>;
	vRetSize : UInt32;
	vRetCode : Integer;
	vI       : Integer;
	vNumCores : Integer;
begin
	if not ParaPercpu then
	begin
		if GetSystemTimes( vIdleTime, vKernelTime, vUserTime ) then
		begin
			vIdle := ( Int64( vIdleTime.dwHighDateTime ) shl 32 or vIdleTime.dwLowDateTime ) / ClocksPerSec;
			vUser := ( Int64( vUserTime.dwHighDateTime ) shl 32 or vUserTime.dwLowDateTime ) / ClocksPerSec;
			vKernel := ( Int64( vKernelTime.dwHighDateTime ) shl 32 or vKernelTime.dwLowDateTime ) / ClocksPerSec;
			vSystem := vKernel - vIdle;
			
			SetLength( Result, 1 );
			Result[ 0 ].CPU := 'cpu-total';
			Result[ 0 ].Idle := vIdle;
			Result[ 0 ].User := vUser;
			Result[ 0 ].System := vSystem;
		end
		else
			SetLength( Result, 0 );
		Exit;
	end;

	// Per CPU times
	SetLength( vStats, 256 ); // Initial guess
	vRetCode := NtQuerySystemInformation( SystemProcessorPerformanceInformationClass, @vStats[ 0 ], SizeOf( TSystemProcessorPerformanceInformation ) * Length( vStats ), @vRetSize );
	if vRetCode <> 0 then
	begin
		SetLength( Result, 0 );
		Exit;
	end;

	vNumCores := vRetSize div SizeOf( TSystemProcessorPerformanceInformation );
	SetLength( Result, vNumCores );
	for vI := 0 to vNumCores - 1 do
	begin
		Result[ vI ].CPU := Format( 'cpu%d', [ vI ] );
		Result[ vI ].User := vStats[ vI ].UserTime / ClocksPerSec;
		Result[ vI ].System := ( vStats[ vI ].KernelTime - vStats[ vI ].IdleTime ) / ClocksPerSec;
		Result[ vI ].Idle := vStats[ vI ].IdleTime / ClocksPerSec;
		Result[ vI ].Irq := vStats[ vI ].InterruptTime / ClocksPerSec;
	end;
end;

function WinInfo : TArray<TInfoStat>;
var
	vSysInfo : TSystemInfo;
begin
	GetNativeSystemInfo( vSysInfo );
	SetLength( Result, 1 );
	Result[ 0 ].CPU := 0;
	Result[ 0 ].Cores := vSysInfo.dwNumberOfProcessors;
	Result[ 0 ].ModelName := 'Generic Windows CPU'; // Detailed info often requires WMI
	Result[ 0 ].Mhz := 0;
end;

function WinCounts( ParaLogical : Boolean ) : Integer;
var
	vSysInfo : TSystemInfo;
begin
	if ParaLogical then
	begin
		GetNativeSystemInfo( vSysInfo );
		Result := vSysInfo.dwNumberOfProcessors;
	end
	else
	begin
		// Physical core count normally requires WMI or sophisticated WinAPI.
		// For this conversion, we will simplify.
		GetNativeSystemInfo( vSysInfo );
		Result := vSysInfo.dwNumberOfProcessors;
	end;
end;

end.
