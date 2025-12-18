unit Log15.Term.Terminal.Darwin;

{$IFDEF DARWIN}
interface

uses
  Log15.Term.Terminal.AppEngine,
  Log15.Term.Terminal.Freebsd,
  Log15.Term.Terminal.Linux,
  Log15.Term.Terminal.Netbsd,
  Log15.Term.Terminal.NotWindows,
  Log15.Term.Terminal.Openbsd,
  Log15.Term.Terminal.Solaris,
  Log15.Term.Terminal.Windows,
  Posix.Termios;

const
  ioctlReadTermios = $40487413;

type
  TTermios = Posix.Termios.Termios;

implementation

end.
{$ENDIF}
