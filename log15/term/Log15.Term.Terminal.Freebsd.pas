unit Log15.Term.Terminal.FreeBSD;

{$IFDEF FREEBSD}
interface

uses
  Posix.Termios;

const
  ioctlReadTermios = $402c7413;

type
  TTermios = Posix.Termios.Termios;

implementation

end.
{$ENDIF}
