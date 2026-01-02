unit Vendor.Github.Com.Tklauser.GoSysconf.SysconfSolaris;

interface

uses
  System.SysUtils;

function sysconf(name: Integer): Int64;

implementation

uses
  Vendor.Github.Com.Tklauser.GoSysconf.Constants;

function sysconf(name: Integer): Int64;
begin
  if name < 0 then
    raise Exception.Create('invalid parameter value');

  // In Go this calls unix.Sysconf(name)
  // For conversion, we return -1 as it's platform specific
  Result := -1;
end;

end.
