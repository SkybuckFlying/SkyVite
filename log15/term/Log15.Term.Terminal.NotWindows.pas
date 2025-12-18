unit Log15.Term.Terminal.NotWindows;

interface

{$IFNDEF MSWINDOWS}
uses
  Log15.Term.Terminal.AppEngine,
  Log15.Term.Terminal.Darwin,
  Log15.Term.Terminal.Freebsd,
  Log15.Term.Terminal.Linux,
  Log15.Term.Terminal.Linux // Assuming common types or similar,
  Log15.Term.Terminal.Netbsd,
  Log15.Term.Terminal.Openbsd,
  Log15.Term.Terminal.Solaris,
  Log15.Term.Terminal.Windows,
  Posix.SysIoctl,
  Posix.Unistd;

function IsTty( ParaFD : Integer ) : Boolean;
{$ENDIF}

implementation

{$IFNDEF MSWINDOWS}
function IsTty( ParaFD : Integer ) : Boolean;
var
	vTermios : termios;
begin
	// ioctl(fd, TCGETS, &termios)
	Result := fpIoctl( ParaFD, TCGETS, @vTermios ) = 0;
end;
{$ENDIF}

end.
