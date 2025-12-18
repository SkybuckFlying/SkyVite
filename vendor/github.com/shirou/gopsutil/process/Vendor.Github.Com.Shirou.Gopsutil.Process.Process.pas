unit Vendor.Github.Com.Shirou.Gopsutil.Process.Process;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	System.SyncObjs,
	Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu;

type
	TNumCtxSwitchesStat = record
		Voluntary   : Int64;
		Involuntary : Int64;
		function Stringify : string;
	end;

	TMemoryInfoStat = record
		RSS    : UInt64;
		VMS    : UInt64;
		HWM    : UInt64;
		Data   : UInt64;
		Stack  : UInt64;
		Locked : UInt64;
		Swap   : UInt64;
		function Stringify : string;
	end;

	TIOCountersStat = record
		ReadCount  : UInt64;
		WriteCount : UInt64;
		ReadBytes  : UInt64;
		WriteBytes : UInt64;
		function Stringify : string;
	end;

	TProcess = class
	private
		mPid            : Int32;
		mName           : string;
		mStatus         : string;
		mParent         : Int32;
		mParentLock     : TCriticalSection;
		mNumCtxSwitches : TNumCtxSwitchesStat;
		mUids           : TArray<Int32>;
		mGids           : TArray<Int32>;
		mNumThreads     : Int32;
		mMemInfo        : TMemoryInfoStat;
		mCreateTime     : Int64;

		mLastCPUTimes   : TTimesStat;
		mLastCPUTime    : TDateTime;
	public
		constructor Create( ParaPid : Int32 );
		destructor Destroy; override;

		property Pid : Int32 read mPid;
		
		function Name : string;
		function Exe : string;
		function Cmdline : string;
		function Ppid : Int32;
		function Status : string;
		function Username : string;
		function CreateTime : Int64;
		function MemoryInfo : TMemoryInfoStat;
		function IOCounters : TIOCountersStat;
		function CPUPercent : Double;
		
		class function Pids : TArray<Int32>;
		class function Processes : TArray<TProcess>;
		class function Exists( ParaPid : Int32 ) : Boolean;
	end;

implementation

uses
	{$IFDEF MSWINDOWS}
	Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessWindows
	{$ELSE}
	Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFallback
	{$ENDIF}
	;

{ TNumCtxSwitchesStat }

function TNumCtxSwitchesStat.Stringify : string;
begin
	Result := Format( '{"voluntary":%d,"involuntary":%d}', [ Voluntary, Involuntary ] );
end;

{ TMemoryInfoStat }

function TMemoryInfoStat.Stringify : string;
begin
	Result := Format( '{"rss":%d,"vms":%d}', [ RSS, VMS ] );
end;

{ TIOCountersStat }

function TIOCountersStat.Stringify : string;
begin
	Result := Format( '{"readCount":%d,"readBytes":%d}', [ ReadCount, ReadBytes ] );
end;

{ TProcess }

constructor TProcess.Create( ParaPid : Int32 );
begin
	inherited Create;
	mPid := ParaPid;
	mParentLock := TCriticalSection.Create;
end;

destructor TProcess.Destroy;
begin
	mParentLock.Free;
	inherited;
end;

function TProcess.Name : string;
begin
	{$IFDEF MSWINDOWS}
	Result := WinProcessName( mPid );
	{$ELSE}
	Result := '';
	{$ENDIF}
end;

function TProcess.Exe : string;
begin
	{$IFDEF MSWINDOWS}
	Result := WinProcessExe( mPid );
	{$ELSE}
	Result := '';
	{$ENDIF}
end;

function TProcess.Cmdline : string;
begin
	{$IFDEF MSWINDOWS}
	Result := WinProcessCmdline( mPid );
	{$ELSE}
	Result := '';
	{$ENDIF}
end;

function TProcess.Ppid : Int32;
begin
	{$IFDEF MSWINDOWS}
	Result := WinProcessPpid( mPid );
	{$ELSE}
	Result := 0;
	{$ENDIF}
end;

function TProcess.Status : string;
begin
	Result := ''; // Stub
end;

function TProcess.Username : string;
begin
	{$IFDEF MSWINDOWS}
	Result := WinProcessUsername( mPid );
	{$ELSE}
	Result := '';
	{$ENDIF}
end;

function TProcess.CreateTime : Int64;
begin
	{$IFDEF MSWINDOWS}
	Result := WinProcessCreateTime( mPid );
	{$ELSE}
	Result := 0;
	{$ENDIF}
end;

function TProcess.MemoryInfo : TMemoryInfoStat;
begin
	{$IFDEF MSWINDOWS}
	Result := WinProcessMemoryInfo( mPid );
	{$ELSE}
	FillChar( Result, SizeOf( Result ), 0 );
	{$ENDIF}
end;

function TProcess.IOCounters : TIOCountersStat;
begin
	{$IFDEF MSWINDOWS}
	Result := WinProcessIOCounters( mPid );
	{$ELSE}
	FillChar( Result, SizeOf( Result ), 0 );
	{$ENDIF}
end;

function TProcess.CPUPercent : Double;
begin
	Result := 0; // Stub: Requires interval logic
end;

class function TProcess.Pids : TArray<Int32>;
begin
	{$IFDEF MSWINDOWS}
	Result := WinPids;
	{$ELSE}
	SetLength( Result, 0 );
	{$ENDIF}
end;

class function TProcess.Processes : TArray<TProcess>;
var
	vPids : TArray<Int32>;
	vI    : Integer;
begin
	vPids := Pids;
	SetLength( Result, Length( vPids ) );
	for vI := 0 to High( vPids ) do
		Result[ vI ] := TProcess.Create( vPids[ vI ] );
end;

class function TProcess.Exists( ParaPid : Int32 ) : Boolean;
begin
	{$IFDEF MSWINDOWS}
	Result := WinPidExists( ParaPid );
	{$ELSE}
	Result := False;
	{$ENDIF}
end;

end.
