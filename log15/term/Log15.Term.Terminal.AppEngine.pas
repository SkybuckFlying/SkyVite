unit Log15.Term.Terminal.AppEngine;

{$IFDEF APPENGINE}
interface
uses
  Log15.Term.Terminal.Darwin,
  Log15.Term.Terminal.Freebsd,
  Log15.Term.Terminal.Linux,
  Log15.Term.Terminal.Netbsd,
  Log15.Term.Terminal.NotWindows,
  Log15.Term.Terminal.Openbsd,
  Log15.Term.Terminal.Solaris,
  Log15.Term.Terminal.Windows;

function IsTty(fd: UIntPtr): Boolean;

implementation

function IsTty(fd: UIntPtr): Boolean;
begin
  Result := False;
end;

end.
{$ENDIF}
