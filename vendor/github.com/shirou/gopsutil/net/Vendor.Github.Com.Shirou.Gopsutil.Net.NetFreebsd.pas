{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Net.NetFreebsd;

interface

{$IFDEF FPC}
uses
	SysUtils,
	Vendor.Github.Com.Shirou.Gopsutil.Net.Types
;
{$ELSE}
uses
	System.SysUtils,
	Vendor.Github.Com.Shirou.Gopsutil.Net.Types
;
{$ENDIF}

function IOCounters( ParaPernic : Boolean ) : TArray<TIOCountersStat>;
function FilterCounters : TArray<TFilterStat>;
function ConntrackStats( ParaPercpu : Boolean ) : TArray<TConntrackStat>;
function ProtoCounters( ParaProtocols : TArray<string> ) : TArray<TProtoCountersStat>;

implementation

function IOCounters( ParaPernic : Boolean ) : TArray<TIOCountersStat>;
begin
	Result := nil;
end;

function FilterCounters : TArray<TFilterStat>;
begin
	Result := nil;
end;

function ConntrackStats( ParaPercpu : Boolean ) : TArray<TConntrackStat>;
begin
	Result := nil;
end;

function ProtoCounters( ParaProtocols : TArray<string> ) : TArray<TProtoCountersStat>;
begin
	Result := nil;
end;

end.
