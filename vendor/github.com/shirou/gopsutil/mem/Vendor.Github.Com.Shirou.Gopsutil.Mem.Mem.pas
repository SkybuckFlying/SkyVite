unit Vendor.Github.Com.Shirou.Gopsutil.Mem.Mem;

interface

uses
	System.SysUtils,
	System.Classes;

type
	/// <summary>
	/// Memory usage statistics. Total, Available and Used contain numbers of bytes
	/// for human consumption.
	/// </summary>
	TVirtualMemoryStat = record
		Total          : UInt64;
		Available      : UInt64;
		Used           : UInt64;
		UsedPercent    : Double;
		Free           : UInt64;
		Active         : UInt64;
		Inactive       : UInt64;
		Wired          : UInt64;
		Laundry        : UInt64;
		Buffers        : UInt64;
		Cached         : UInt64;
		Writeback      : UInt64;
		Dirty          : UInt64;
		WritebackTmp   : UInt64;
		Shared         : UInt64;
		Slab           : UInt64;
		SReclaimable   : UInt64;
		SUnreclaim     : UInt64;
		PageTables     : UInt64;
		SwapCached     : UInt64;
		CommitLimit    : UInt64;
		CommittedAS    : UInt64;
		HighTotal      : UInt64;
		HighFree       : UInt64;
		LowTotal       : UInt64;
		LowFree        : UInt64;
		SwapTotal      : UInt64;
		SwapFree       : UInt64;
		Mapped         : UInt64;
		VMallocTotal   : UInt64;
		VMallocUsed    : UInt64;
		VMallocChunk   : UInt64;
		HugePagesTotal : UInt64;
		HugePagesFree  : UInt64;
		HugePageSize   : UInt64;
		function Stringify : string;
	end;

	TSwapMemoryStat = record
		Total       : UInt64;
		Used        : UInt64;
		Free        : UInt64;
		UsedPercent : Double;
		Sin         : UInt64;
		Sout        : UInt64;
		PgIn        : UInt64;
		PgOut       : UInt64;
		PgFault     : UInt64;
		PgMajFault  : UInt64;
		function Stringify : string;
	end;

function VirtualMemory : TVirtualMemoryStat;
function SwapMemory : TSwapMemoryStat;

implementation

uses
	{$IFDEF MSWINDOWS}
	Vendor.Github.Com.Shirou.Gopsutil.Mem.MemWindows
	{$ELSE}
	Vendor.Github.Com.Shirou.Gopsutil.Mem.MemFallback
	{$ENDIF}
	;

{ TVirtualMemoryStat }

function TVirtualMemoryStat.Stringify : string;
begin
	Result := Format( '{"total":%d,"available":%d,"used":%d,"usedPercent":%.1f}', [ Total, Available, Used, UsedPercent ] );
end;

{ TSwapMemoryStat }

function TSwapMemoryStat.Stringify : string;
begin
	Result := Format( '{"total":%d,"used":%d,"free":%d,"usedPercent":%.1f}', [ Total, Used, Free, UsedPercent ] );
end;

{ Core functions }

function VirtualMemory : TVirtualMemoryStat;
begin
	{$IFDEF MSWINDOWS}
	Result := WinVirtualMemory;
	{$ELSE}
	FillChar( Result, SizeOf( Result ), 0 );
	{$ENDIF}
end;

function SwapMemory : TSwapMemoryStat;
begin
	{$IFDEF MSWINDOWS}
	Result := WinSwapMemory;
	{$ELSE}
	FillChar( Result, SizeOf( Result ), 0 );
	{$ENDIF}
end;

end.
