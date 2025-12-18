unit Vendor.Github.Com.Allegro.BigCache.Logger;

interface

type
	ILogger = interface
		['{FAD1E2B3-C4D5-4E6F-A7B8-C9D0E1F2A3B4}']
		procedure Printf( ParaFormat : string; const ParaArgs : array of const );
	end;

	TDefaultLogger = class(TInterfacedObject, ILogger)
	public
		procedure Printf( ParaFormat : string; const ParaArgs : array of const );
	end;

function NewLogger( ParaCustom : ILogger ) : ILogger;
function DefaultLogger : ILogger;

implementation

uses
	System.SysUtils;

function DefaultLogger : ILogger;
begin
	Result := TDefaultLogger.Create;
end;

function NewLogger( ParaCustom : ILogger ) : ILogger;
begin
	if ParaCustom <> nil then
	begin
		Result := ParaCustom;
	end else
	begin
		Result := DefaultLogger;
	end;
end;

{ TDefaultLogger }

procedure TDefaultLogger.Printf( ParaFormat : string; const ParaArgs : array of const );
begin
	WriteLn( Format( ParaFormat, ParaArgs ) );
end;

end.
