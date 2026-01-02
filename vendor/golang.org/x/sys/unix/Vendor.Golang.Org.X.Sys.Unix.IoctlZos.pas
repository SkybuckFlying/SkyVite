unit Vendor.Golang.Org.X.Sys.Unix.IoctlZos;

interface

uses
  System.SysUtils;

function IoctlSetInt(FD: Integer; Req: UInt; Value: Integer): Exception;

implementation

function IoctlSetInt(FD: Integer; Req: UInt; Value: Integer): Exception;
begin
  Result := nil;
end;

end.
