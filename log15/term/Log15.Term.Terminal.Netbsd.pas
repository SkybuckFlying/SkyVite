unit Log15.Term.Terminal.Netbsd;

interface

{$IFDEF NETBSD}
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
