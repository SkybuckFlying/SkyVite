unit Log15.Term.Terminal.Windows;

interface

uses
  Log15.Term.Terminal.AppEngine,
  Log15.Term.Terminal.Darwin,
  Log15.Term.Terminal.Freebsd,
  Log15.Term.Terminal.Linux,
  Log15.Term.Terminal.Netbsd,
  Log15.Term.Terminal.NotWindows,
  Log15.Term.Terminal.Openbsd,
  Log15.Term.Terminal.Solaris,
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
