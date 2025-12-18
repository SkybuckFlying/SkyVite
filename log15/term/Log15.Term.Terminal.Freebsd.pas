unit Log15.Term.Terminal.FreeBSD;

{$IFDEF FREEBSD}
interface

uses
  Log15.Term.Terminal.AppEngine,
  Log15.Term.Terminal.Darwin,
  Log15.Term.Terminal.Linux,
  Log15.Term.Terminal.Netbsd,
  Log15.Term.Terminal.NotWindows,
  Log15.Term.Terminal.Openbsd,
  Log15.Term.Terminal.Solaris,
  Log15.Term.Terminal.Windows,
  Posix.Termios;

const
  ioctlReadTermios = $402c7413;

type
  TTermios = Posix.Termios.Termios;

implementation

end.
{$ENDIF}
