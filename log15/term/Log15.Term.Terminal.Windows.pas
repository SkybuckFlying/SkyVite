unit Log15.Term.Terminal.Windows;

interface

uses
	Winapi.Windows;

function IsTty( ParaFD : THandle ) : Boolean;

implementation

function IsTty( ParaFD : THandle ) : Boolean;
var
	vSt : DWORD;
begin
	Result := GetConsoleMode( ParaFD, vSt );
end;

end.
