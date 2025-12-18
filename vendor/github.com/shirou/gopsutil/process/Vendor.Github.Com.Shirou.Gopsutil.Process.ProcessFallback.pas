unit Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFallback;

interface

uses
  Vendor.Github.Com.Shirou.Gopsutil.Process.Process,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessBsd,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwin,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwin386,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwinAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwinArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwinCgo,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessDarwinNocgo,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsd,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsdArm,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessFreebsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessLinux,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessOpenbsd,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessOpenbsd386,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessOpenbsdAmd64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessOpenbsdArm64,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessPosix,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessSolaris,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessWindows,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessWindows386,
  Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessWindowsAmd64;

function FallbackPids : TArray<Int32>;
function FallbackPidExists( ParaPid : Int32 ) : Boolean;
function FallbackProcessName( ParaPid : Int32 ) : string;
function FallbackProcessExe( ParaPid : Int32 ) : string;
function FallbackProcessCmdline( ParaPid : Int32 ) : string;
function FallbackProcessPpid( ParaPid : Int32 ) : Int32;
function FallbackProcessUsername( ParaPid : Int32 ) : string;
function FallbackProcessCreateTime( ParaPid : Int32 ) : Int64;
function FallbackProcessMemoryInfo( ParaPid : Int32 ) : TMemoryInfoStat;
function FallbackProcessIOCounters( ParaPid : Int32 ) : TIOCountersStat;

implementation

function FallbackPids : TArray<Int32>;
begin
	SetLength( Result, 0 );
end;

function FallbackPidExists( ParaPid : Int32 ) : Boolean;
begin
	Result := False;
end;

function FallbackProcessName( ParaPid : Int32 ) : string;
begin
	Result := '';
end;

function FallbackProcessExe( ParaPid : Int32 ) : string;
begin
	Result := '';
end;

function FallbackProcessCmdline( ParaPid : Int32 ) : string;
begin
	Result := '';
end;

function FallbackProcessPpid( ParaPid : Int32 ) : Int32;
begin
	Result := 0;
end;

function FallbackProcessUsername( ParaPid : Int32 ) : string;
begin
	Result := '';
end;

function FallbackProcessCreateTime( ParaPid : Int32 ) : Int64;
begin
	Result := 0;
end;

function FallbackProcessMemoryInfo( ParaPid : Int32 ) : TMemoryInfoStat;
begin
	FillChar( Result, SizeOf( Result ), 0 );
end;

function FallbackProcessIOCounters( ParaPid : Int32 ) : TIOCountersStat;
begin
	FillChar( Result, SizeOf( Result ), 0 );
end;

end.
