unit Vendor.Github.Com.Shirou.Gopsutil.Process.ProcessPosix;

interface

uses
	Vendor.Github.Com.Shirou.Gopsutil.Process.Process;

function PosixPids : TArray<Int32>;

implementation

function PosixPids : TArray<Int32>;
begin
	SetLength( Result, 0 );
end;

end.
