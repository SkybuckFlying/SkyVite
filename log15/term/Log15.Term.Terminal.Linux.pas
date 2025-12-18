unit Log15.Term.Terminal.Linux;

interface

{$IFDEF LINUX}
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
