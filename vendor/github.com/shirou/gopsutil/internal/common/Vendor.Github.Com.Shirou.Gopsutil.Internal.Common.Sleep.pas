{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Shirou.Gopsutil.Internal.Common.Sleep;

interface

{$IFDEF FPC}
uses
	SysUtils
;
{$ELSE}
uses
	System.SysUtils
;
{$ENDIF}

procedure Sleep( ParaIntervalMs : Cardinal );

implementation

procedure Sleep( ParaIntervalMs : Cardinal );
begin
	{$IFDEF MSWINDOWS}
	Winapi.Windows.Sleep( ParaIntervalMs );
	{$ELSE}
	SysUtils.Sleep( ParaIntervalMs );
	{$ENDIF}
end;

end.
