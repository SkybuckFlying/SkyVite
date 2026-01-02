unit Vendor.Github.Com.Tklauser.GoSysconf.SysconfUnsupported;

interface

uses
  System.SysUtils;

function sysconf(name: Integer): Int64;

implementation

function sysconf(name: Integer): Int64;
begin
  raise Exception.Create('unsupported on this OS');
end;

end.
