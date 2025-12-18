unit Log15.Term.Terminal.Openbsd;

interface

{$IFDEF OPENBSD}
uses
  Log15.Term.Terminal.AppEngine,
  Log15.Term.Terminal.Darwin,
  Log15.Term.Terminal.Freebsd,
  Log15.Term.Terminal.Linux,
  Log15.Term.Terminal.Netbsd,
  Log15.Term.Terminal.NotWindows,
  Log15.Term.Terminal.Solaris,
  Log15.Term.Terminal.Windows,
  Posix.SysIoctl,
  Posix.Termios;

const
	Const_IOCtlReadTermios = TIOCGETA;

type
	TTermios = termios;
{$ENDIF}

implementation

end.
