unit Vendor.Golang.Org.X.Sys.Unix.SockcmsgDragonfly;

interface

function CmsgAlignOf(Salen: Integer): Integer;

implementation

function CmsgAlignOf(Salen: Integer): Integer;
begin
  Result := (Salen + 4 - 1) and not (4 - 1); // Simplified
end;

end.
