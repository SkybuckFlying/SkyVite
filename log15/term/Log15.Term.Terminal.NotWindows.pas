unit Log15.Term.Terminal.NotWindows;

interface

{$IFNDEF MSWINDOWS}
uses
	Posix.SysIoctl,
	Posix.Unistd,
	Log15.Term.Terminal.Linux; // Assuming common types or similar

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
