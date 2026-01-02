unit Vendor.Golang.Org.X.Sys.Unix.PagesizeUnix;

interface

function Getpagesize: Integer;

implementation

function Getpagesize: Integer;
begin
  Result := 4096; // Simplified
end;

end.
