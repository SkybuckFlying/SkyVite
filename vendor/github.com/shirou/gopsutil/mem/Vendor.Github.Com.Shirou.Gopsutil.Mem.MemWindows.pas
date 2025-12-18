unit Vendor.Github.Com.Shirou.Gopsutil.Mem.MemWindows;

interface

uses
	Winapi.Windows,
	System.SysUtils,
	Vendor.Github.Com.Shirou.Gopsutil.Mem.Mem;

function WinVirtualMemory : TVirtualMemoryStat;
function WinSwapMemory : TSwapMemoryStat;

implementation

type
	TMemoryStatusEx = record
		cbSize                  : DWORD;
		dwMemoryLoad            : DWORD;
		ullTotalPhys            : UInt64;
		ullAvailPhys            : UInt64;
		ullTotalPageFile        : UInt64;
		ullAvailPageFile        : UInt64;
		ullTotalVirtual         : UInt64;
		ullAvailVirtual         : UInt64;
		ullAvailExtendedVirtual : UInt64;
	end;

	TPerformanceInformation = record
		cb                : DWORD;
		commitTotal       : SIZE_T;
		commitLimit       : SIZE_T;
		commitPeak        : SIZE_T;
		physicalTotal     : SIZE_T;
		physicalAvailable : SIZE_T;
		systemCache       : SIZE_T;
		kernelTotal       : SIZE_T;
		kernelPaged       : SIZE_T;
		kernelNonpaged    : SIZE_T;
		pageSize          : SIZE_T;
		handleCount       : DWORD;
		processCount      : DWORD;
		threadCount       : DWORD;
	end;

function GlobalMemoryStatusEx( var lpBuffer : TMemoryStatusEx ) : BOOL; stdcall; external kernel32;
function GetPerformanceInfo( pPerformanceInformation : Pointer; cb : DWORD ) : BOOL; stdcall; external 'psapi.dll';

function WinVirtualMemory : TVirtualMemoryStat;
var
	vMemInfo : TMemoryStatusEx;
begin
	FillChar( vMemInfo, SizeOf( vMemInfo ), 0 );
	vMemInfo.cbSize := SizeOf( vMemInfo );
	if GlobalMemoryStatusEx( vMemInfo ) then
	begin
		Result.Total := vMemInfo.ullTotalPhys;
		Result.Available := vMemInfo.ullAvailPhys;
		Result.Free := vMemInfo.ullAvailPhys;
		Result.UsedPercent := vMemInfo.dwMemoryLoad;
		Result.Used := Result.Total - Result.Available;
	end
	else
		FillChar( Result, SizeOf( Result ), 0 );
end;

function WinSwapMemory : TSwapMemoryStat;
var
	vPerfInfo : TPerformanceInformation;
	vTot, vUsed : UInt64;
begin
	FillChar( vPerfInfo, SizeOf( vPerfInfo ), 0 );
	vPerfInfo.cb := SizeOf( vPerfInfo );
	if GetPerformanceInfo( @vPerfInfo, vPerfInfo.cb ) then
	begin
		vTot := UInt64( vPerfInfo.commitLimit ) * vPerfInfo.pageSize;
		vUsed := UInt64( vPerfInfo.commitTotal ) * vPerfInfo.pageSize;
		
		Result.Total := vTot;
		Result.Used := vUsed;
		Result.Free := vTot - vUsed;
		if vTot > 0 then
			Result.UsedPercent := ( Double( vUsed ) / vTot ) * 100
		else
			Result.UsedPercent := 0;
	end
	else
		FillChar( Result, SizeOf( Result ), 0 );
end;

end.
