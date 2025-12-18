unit Vendor.Github.Com.Shirou.Gopsutil.Cpu.Cpu;

interface

uses
	System.SysUtils,
	System.Classes,
	System.SyncObjs,
	System.Math;

type
	/// <summary>
	/// TimesStat contains the amounts of time the CPU has spent performing different
	/// kinds of work. Time units are in seconds.
	/// </summary>
	TTimesStat = record
		CPU       : string;
		User      : Double;
		System    : Double;
		Idle      : Double;
		Nice      : Double;
		Iowait    : Double;
		Irq       : Double;
		Softirq   : Double;
		Steal     : Double;
		Guest     : Double;
		GuestNice : Double;
		function Total : Double;
		function Stringify : string;
	end;

	TInfoStat = record
		CPU        : Int32;
		VendorID   : string;
		Family     : string;
		Model      : string;
		Stepping   : Int32;
		PhysicalID : string;
		CoreID     : string;
		Cores      : Int32;
		ModelName  : string;
		Mhz        : Double;
		CacheSize  : Int32;
		Flags      : TArray<string>;
		Microcode  : string;
		function Stringify : string;
	end;

	TLastPercent = class
	private
		mLock            : TCriticalSection;
		mLastCPUTimes    : TArray<TTimesStat>;
		mLastPerCPUTimes : TArray<TTimesStat>;
	public
		constructor Create;
		destructor Destroy; override;
		procedure Lock;
		procedure Unlock;
		property LastCPUTimes : TArray<TTimesStat> read mLastCPUTimes write mLastCPUTimes;
		property LastPerCPUTimes : TArray<TTimesStat> read mLastPerCPUTimes write mLastPerCPUTimes;
	end;

var
	LastCPUPercent : TLastPercent;

function Times( ParaPercpu : Boolean ) : TArray<TTimesStat>; forward;
function Info : TArray<TInfoStat>; forward;
function Counts( ParaLogical : Boolean ) : Integer; forward;

function CalculateBusy( ParaT1, ParaT2 : TTimesStat ) : Double;
function CalculateAllBusy( ParaT1, ParaT2 : TArray<TTimesStat> ) : TArray<Double>;

implementation

uses
	{$IFDEF MSWINDOWS}
	Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuWindows
	{$ELSE}
	Vendor.Github.Com.Shirou.Gopsutil.Cpu.CpuFallback
	{$ENDIF}
	;

{ TTimesStat }

function TTimesStat.Total : Double;
begin
	Result := User + System + Nice + Iowait + Irq + Softirq + Steal + Idle;
end;

function TTimesStat.Stringify : string;
begin
	Result := Format( '{"cpu":"%s","user":%.1f,"system":%.1f,"idle":%.1f}', [ CPU, User, System, Idle ] );
end;

{ TInfoStat }

function TInfoStat.Stringify : string;
begin
	Result := Format( '{"modelName":"%s","cores":%d,"mhz":%.1f}', [ ModelName, Cores, Mhz ] );
end;

{ TLastPercent }

constructor TLastPercent.Create;
begin
	inherited Create;
	mLock := TCriticalSection.Create;
end;

destructor TLastPercent.Destroy;
begin
	mLock.Free;
	inherited;
end;

procedure TLastPercent.Lock;
begin
	mLock.Enter;
end;

procedure TLastPercent.Unlock;
begin
	mLock.Leave;
end;

{ Implementation of forward-declared functions }

function Times( ParaPercpu : Boolean ) : TArray<TTimesStat>;
begin
	{$IFDEF MSWINDOWS}
	Result := WinTimes( ParaPercpu );
	{$ELSE}
	Result := nil;
	{$ENDIF}
end;

function Info : TArray<TInfoStat>;
begin
	{$IFDEF MSWINDOWS}
	Result := WinInfo;
	{$ELSE}
	Result := nil;
	{$ENDIF}
end;

function Counts( ParaLogical : Boolean ) : Integer;
begin
	{$IFDEF MSWINDOWS}
	Result := WinCounts( ParaLogical );
	{$ELSE}
	Result := 0;
	{$ENDIF}
end;

{ Helper Functions }

function GetAllBusy( const ParaT : TTimesStat; out ParaAll, ParaBusy : Double ) : void;
begin
	ParaBusy := ParaT.User + ParaT.System + ParaT.Nice + ParaT.Iowait + ParaT.Irq + ParaT.Softirq + ParaT.Steal;
	ParaAll := ParaBusy + ParaT.Idle;
end;

function CalculateBusy( ParaT1, ParaT2 : TTimesStat ) : Double;
var
	vT1All, vT1Busy : Double;
	vT2All, vT2Busy : Double;
begin
	GetAllBusy( ParaT1, vT1All, vT1Busy );
	GetAllBusy( ParaT2, vT2All, vT2Busy );

	if vT2Busy <= vT1Busy then
		Exit( 0 );
	if vT2All <= vT1All then
		Exit( 100 );
	
	Result := Min( 100, Max( 0, ( vT2Busy - vT1Busy ) / ( vT2All - vT1All ) * 100 ) );
end;

function CalculateAllBusy( ParaT1, ParaT2 : TArray<TTimesStat> ) : TArray<Double>;
var
	vI : Integer;
begin
	if Length( ParaT1 ) <> Length( ParaT2 ) then
		raise Exception.CreateFmt( 'received two CPU counts: %d != %d', [ Length( ParaT1 ), Length( ParaT2 ) ] );

	SetLength( Result, Length( ParaT1 ) );
	for vI := 0 to High( ParaT1 ) do
		Result[ vI ] := CalculateBusy( ParaT1[ vI ], ParaT2[ vI ] );
end;

initialization
	LastCPUPercent := TLastPercent.Create;
finalization
	LastCPUPercent.Free;

end.
