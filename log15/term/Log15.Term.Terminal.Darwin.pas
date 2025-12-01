unit Log15.Term.Terminal.Darwin;

{$IFDEF DARWIN}
interface

uses
  Posix.Termios;

const
  ioctlReadTermios = $40487413;

type
  TTermios = Posix.Termios.Termios;

implementation

end.
{$ENDIF}
