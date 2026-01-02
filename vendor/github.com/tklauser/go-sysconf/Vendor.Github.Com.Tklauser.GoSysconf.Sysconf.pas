unit Vendor.Github.Com.Tklauser.GoSysconf.Sysconf;

interface

uses
  System.SysUtils;

/// <summary>
/// Sysconf returns the value of a sysconf(3) runtime system parameter.
/// The name parameter should be a SC_* constant define in this package. The
/// implementation is GOOS-specific and certain SC_* constants might not be
/// defined for all GOOSes.
/// </summary>
function Sysconf(name: Integer): Int64;

implementation

uses
  Vendor.Github.Com.Tklauser.GoSysconf.SysconfInternal;

function Sysconf(name: Integer): Int64;
var
  val: Int64;
  err: Exception;
begin
  try
    Result := sysconf_internal(name);
  except
    on E: Exception do
      raise Exception.CreateFmt('sysconf: %s', [E.Message]);
  end;
end;

end.
