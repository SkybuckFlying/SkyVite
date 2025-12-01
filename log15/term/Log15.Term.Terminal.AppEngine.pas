unit Log15.Term.Terminal.AppEngine;

{$IFDEF APPENGINE}
interface

function IsTty(fd: UIntPtr): Boolean;

implementation

function IsTty(fd: UIntPtr): Boolean;
begin
  Result := False;
end;

end.
{$ENDIF}
