unit Vendor.Github.Com.Allegro.BigCache.Clock;

interface

uses
	System.SysUtils,
	System.DateUtils;

type
	IClock = interface
		['{B1E2D3C4-F5E6-4D7C-A8B9-C0E1D2A3B4C5}']
		function Epoch : Int64;
	end;

	TSystemClock = class(TInterfacedObject, IClock)
	public
		function Epoch : Int64;
	end;

implementation

{ TSystemClock }

function TSystemClock.Epoch : Int64;
begin
	Result := DateTimeToUnix( Now );
end;

end.
