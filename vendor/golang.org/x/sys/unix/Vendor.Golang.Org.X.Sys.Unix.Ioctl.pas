unit Vendor.Golang.Org.X.Sys.Unix.Ioctl;

interface

uses
  System.SysUtils;

function IoctlSetInt(FD: Integer; Req: UInt; Value: Integer): Exception;
function IoctlGetInt(FD: Integer; Req: UInt): TTuple<Integer, Exception>;

implementation

function IoctlSetInt(FD: Integer; Req: UInt; Value: Integer): Exception;
begin
  Result := nil;
end;

function IoctlGetInt(FD: Integer; Req: UInt): TTuple<Integer, Exception>;
begin
  Result := Default(TTuple<Integer, Exception>);
end;

end.
