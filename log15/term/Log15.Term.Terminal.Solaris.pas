unit Log15.Term.Terminal.Solaris;

interface

{$IFDEF SOLARIS}
uses
	Posix.SysIoctl,
	Posix.Termios;

const
	Const_IOCtlReadTermios = TCGETS;

type
	TTermios = termios;
{$ENDIF}

implementation

end.
