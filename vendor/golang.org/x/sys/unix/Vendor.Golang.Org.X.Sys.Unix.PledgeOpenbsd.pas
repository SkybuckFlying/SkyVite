unit Vendor.Golang.Org.X.Sys.Unix.PledgeOpenbsd;

interface

uses
  System.SysUtils;

function Pledge(const Promises, Execpromises: string): Exception;

implementation

function Pledge(const Promises, Execpromises: string): Exception;
begin
  Result := nil;
end;

end.
