unit Vendor.Golang.Org.X.Sys.Unix.IoctlLinux;

interface

uses
  System.SysUtils;

function IoctlRetInt(FD: Integer; Req: UInt): TTuple<Integer, Exception>;

implementation

function IoctlRetInt(FD: Integer; Req: UInt): TTuple<Integer, Exception>;
begin
  Result := Default(TTuple<Integer, Exception>);
end;

end.
