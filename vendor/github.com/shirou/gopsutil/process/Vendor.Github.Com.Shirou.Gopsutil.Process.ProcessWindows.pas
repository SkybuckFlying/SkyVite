unit Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessWindows;

interface

uses
	Winapi.Windows,
	Winapi.PsAPI,
	System.SysUtils,
	System.Classes,
	System.Win.Registry,
	System.Math,
	Vendor.Github.Com.Shirou.Gopsutil.Process.Process;

type
	TProcessBasicInformation64 = record
		Reserved1       : UInt64;
		PebBaseAddress  : UInt64;
		Reserved2       : UInt64;
		Reserved3       : UInt64;
		UniqueProcessId : UInt64;
		Reserved4       : UInt64;
	end;

	TRtlUserProcessParameters64 = record
		Reserved1 : array[ 0..15 ] of Byte;
		Reserved2 : array[ 0..9 ] of UInt64;
		ImagePathNameLength : Word;
		ImagePathNameMaximumLength : Word;
		padding1 : DWORD;
		ImagePathAddress : UInt64;
		CommandLineLength : Word;
		CommandLineMaximumLength : Word;
		padding2 : DWORD;
		CommandLineAddress : UInt64;
		EnvironmentAddress : UInt64;
	end;

	TProcessEnvironmentBlock64 = record
		Reserved1 : array[ 0..1 ] of Byte;
		BeingDebugged : Byte;
		Reserved2 : Byte;
		padding1 : DWORD;
		Reserved3 : array[ 0..1 ] of UInt64;
		Ldr : UInt64;
		ProcessParameters : UInt64;
	end;

function NtQueryInformationProcess(
	ProcessHandle : HANDLE;
	ProcessInformationClass : Integer;
	ProcessInformation : Pointer;
	ProcessInformationLength : ULONG;
	ReturnLength : PULONG
) : Integer; stdcall; external 'ntdll.dll';

function NtReadVirtualMemory(
	ProcessHandle : HANDLE;
	BaseAddress : Pointer;
	Buffer : Pointer;
	NumberOfBytesToRead : SIZE_T;
	NumberOfBytesRead : PSIZE_T
) : Integer; stdcall; external 'ntdll.dll';

function WinPids : TArray<Int32>;
function WinPidExists( ParaPid : Int32 ) : Boolean;
function WinProcessName( ParaPid : Int32 ) : string;
function WinProcessExe( ParaPid : Int32 ) : string;
function WinProcessCmdline( ParaPid : Int32 ) : string;
function WinProcessPpid( ParaPid : Int32 ) : Int32;
function WinProcessUsername( ParaPid : Int32 ) : string;
function WinProcessCreateTime( ParaPid : Int32 ) : Int64;
function WinProcessMemoryInfo( ParaPid : Int32 ) : TMemoryInfoStat;
function WinProcessIOCounters( ParaPid : Int32 ) : TIOCountersStat;

implementation

uses
	Winapi.TlHelp32;

function WinPids : TArray<Int32>;
var
	vPids : array[ 0..4095 ] of DWORD;
	vRead : DWORD;
	vI    : Integer;
begin
	if EnumProcesses( @vPids[ 0 ], SizeOf( vPids ), vRead ) then
	begin
		SetLength( Result, vRead div SizeOf( DWORD ) );
		for vI := 0 to High( Result ) do
			Result[ vI ] := Int32( vPids[ vI ] );
	end
	else
		SetLength( Result, 0 );
end;

function WinPidExists( ParaPid : Int32 ) : Boolean;
var
	vHandle : THandle;
begin
	if ParaPid = 0 then Exit( True );
	vHandle := OpenProcess( PROCESS_QUERY_LIMITED_INFORMATION, False, ParaPid );
	if vHandle <> 0 then
	begin
		CloseHandle( vHandle );
		Exit( True );
	end;
	Result := GetLastError = ERROR_ACCESS_DENIED;
end;

function WinProcessName( ParaPid : Int32 ) : string;
var
	vSnapshot : THandle;
	vEntry    : TProcessEntry32;
begin
	Result := '';
	vSnapshot := CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
	if vSnapshot <> INVALID_HANDLE_VALUE then
	try
		vEntry.dwSize := SizeOf( vEntry );
		if Process32First( vSnapshot, vEntry ) then
		repeat
			if vEntry.th32ProcessID = DWORD( ParaPid ) then
			begin
				Result := string( vEntry.szExeFile );
				Break;
			end;
		until not Process32Next( vSnapshot, vEntry );
	finally
		CloseHandle( vSnapshot );
	end;
end;

function WinProcessExe( ParaPid : Int32 ) : string;
var
	vHandle : THandle;
	vBuf    : array[ 0..MAX_PATH ] of WideChar;
	vSize   : DWORD;
begin
	Result := '';
	vHandle := OpenProcess( PROCESS_QUERY_LIMITED_INFORMATION, False, ParaPid );
	if vHandle <> 0 then
	try
		vSize := MAX_PATH;
		if QueryFullProcessImageNameW( vHandle, 0, vBuf, vSize ) then
			Result := string( vBuf );
	finally
		CloseHandle( vHandle );
	end;
end;

function WinProcessPpid( ParaPid : Int32 ) : Int32;
var
	vSnapshot : THandle;
	vEntry    : TProcessEntry32;
begin
	Result := 0;
	vSnapshot := CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );
	if vSnapshot <> INVALID_HANDLE_VALUE then
	try
		vEntry.dwSize := SizeOf( vEntry );
		if Process32First( vSnapshot, vEntry ) then
		repeat
			if vEntry.th32ProcessID = DWORD( ParaPid ) then
			begin
				Result := vEntry.th32ParentProcessID;
				Break;
			end;
		until not Process32Next( vSnapshot, vEntry );
	finally
		CloseHandle( vSnapshot );
	end;
end;

function WinProcessCmdline( ParaPid : Int32 ) : string;
var
	vHandle : THandle;
	vBasicInfo : TProcessBasicInformation64;
	vPeb       : TProcessEnvironmentBlock64;
	vParams    : TRtlUserProcessParameters64;
	vRetLen    : ULONG;
	vRead      : SIZE_T;
	vCmdBuf    : TArray<WideChar>;
begin
	Result := '';
	vHandle := OpenProcess( PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, ParaPid );
	if vHandle <> 0 then
	try
		// This assumes 64-bit to 64-bit for simplicity in this batch
		if NtQueryInformationProcess( vHandle, 0, @vBasicInfo, SizeOf( vBasicInfo ), @vRetLen ) = 0 then
		begin
			if NtReadVirtualMemory( vHandle, Pointer( vBasicInfo.PebBaseAddress ), @vPeb, SizeOf( vPeb ), @vRead ) = 0 then
			begin
				if NtReadVirtualMemory( vHandle, Pointer( vPeb.ProcessParameters ), @vParams, SizeOf( vParams ), @vRead ) = 0 then
				begin
					SetLength( vCmdBuf, vParams.CommandLineLength div 2 );
					if NtReadVirtualMemory( vHandle, Pointer( vParams.CommandLineAddress ), @vCmdBuf[ 0 ], vParams.CommandLineLength, @vRead ) = 0 then
						Result := string( vCmdBuf );
				end;
			end;
		end;
	finally
		CloseHandle( vHandle );
	end;
end;

function WinProcessUsername( ParaPid : Int32 ) : string;
var
	vHandle, vToken : THandle;
	vUser      : PTokenUser;
	vLen       : DWORD;
	vName, vDom : array[ 0..MAX_PATH ] of WideChar;
	vNameLen, vDomLen : DWORD;
	vUse       : SID_NAME_USE;
begin
	Result := '';
	vHandle := OpenProcess( PROCESS_QUERY_INFORMATION, False, ParaPid );
	if vHandle <> 0 then
	try
		if OpenProcessToken( vHandle, TOKEN_QUERY, vToken ) then
		try
			vLen := 0;
			GetTokenInformation( vToken, TokenUser, nil, 0, vLen );
			if vLen > 0 then
			begin
				GetMem( vUser, vLen );
				try
					if GetTokenInformation( vToken, TokenUser, vUser, vLen, vLen ) then
					begin
						vNameLen := MAX_PATH;
						vDomLen := MAX_PATH;
						if LookupAccountSidW( nil, vUser.User.Sid, vName, vNameLen, vDom, vDomLen, vUse ) then
							Result := string( vDom ) + '\' + string( vName );
					end;
				finally
					FreeMem( vUser );
				end;
			end;
		finally
			CloseHandle( vToken );
		end;
	finally
		CloseHandle( vHandle );
	end;
end;

function WinProcessCreateTime( ParaPid : Int32 ) : Int64;
var
	vHandle : THandle;
	vCreate, vExit, vKernel, vUser : TFileTime;
begin
	Result := 0;
	vHandle := OpenProcess( PROCESS_QUERY_LIMITED_INFORMATION, False, ParaPid );
	if vHandle <> 0 then
	try
		if GetProcessTimes( vHandle, vCreate, vExit, vKernel, vUser ) then
			Result := ( Int64( vCreate.dwHighDateTime ) shl 32 ) or vCreate.dwLowDateTime;
	finally
		CloseHandle( vHandle );
	end;
end;

function WinProcessMemoryInfo( ParaPid : Int32 ) : TMemoryInfoStat;
var
	vHandle : THandle;
	vCounters : TProcessMemoryCounters;
begin
	FillChar( Result, SizeOf( Result ), 0 );
	vHandle := OpenProcess( PROCESS_QUERY_LIMITED_INFORMATION, False, ParaPid );
	if vHandle <> 0 then
	try
		vCounters.cb := SizeOf( vCounters );
		if GetProcessMemoryInfo( vHandle, @vCounters, SizeOf( vCounters ) ) then
		begin
			Result.RSS := vCounters.WorkingSetSize;
			Result.VMS := vCounters.PagefileUsage;
		end;
	finally
		CloseHandle( vHandle );
	end;
end;

function WinProcessIOCounters( ParaPid : Int32 ) : TIOCountersStat;
var
	vHandle : THandle;
	vIOCounters : TIO_COUNTERS;
begin
	FillChar( Result, SizeOf( Result ), 0 );
	vHandle := OpenProcess( PROCESS_QUERY_LIMITED_INFORMATION, False, ParaPid );
	if vHandle <> 0 then
	try
		if GetProcessIoCounters( vHandle, vIOCounters ) then
		begin
			Result.ReadCount := vIOCounters.ReadOperationCount;
			Result.WriteCount := vIOCounters.WriteOperationCount;
			Result.ReadBytes := vIOCounters.ReadTransferCount;
			Result.WriteBytes := vIOCounters.WriteTransferCount;
		end;
	finally
		CloseHandle( vHandle );
	end;
end;

end.
