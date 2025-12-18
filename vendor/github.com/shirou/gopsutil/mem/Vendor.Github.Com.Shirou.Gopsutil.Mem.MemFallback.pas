unit Vendor.Github.Com.Shirou.Gopsutil.Mem.MemFallback;

interface

uses
	Vendor.Github.Com.Shirou.Gopsutil.Mem.Mem;

function FallbackVirtualMemory : TVirtualMemoryStat;
function FallbackSwapMemory : TSwapMemoryStat;

implementation

function FallbackVirtualMemory : TVirtualMemoryStat;
begin
	FillChar( Result, SizeOf( Result ), 0 );
end;

function FallbackSwapMemory : TSwapMemoryStat;
begin
	FillChar( Result, SizeOf( Result ), 0 );
end;

end.
