unit Log15.Term.Terminal.Openbsd;

interface

{$IFDEF OPENBSD}
uses
	Posix.SysIoctl,
	Posix.Termios;

const
	Const_IOCtlReadTermios = TIOCGETA;

type
	TTermios = termios;
{$ENDIF}

implementation

end.
