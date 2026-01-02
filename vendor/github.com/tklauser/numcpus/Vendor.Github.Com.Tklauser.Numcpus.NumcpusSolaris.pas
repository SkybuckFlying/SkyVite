unit Vendor.Github.Com.Tklauser.Numcpus.NumcpusSolaris;

interface

uses
  System.SysUtils;

function getKernelMax: Integer;
function getOffline: Integer;
function getOnline: Integer;
function getPossible: Integer;
function getPresent: Integer;

implementation

uses
  Vendor.Github.Com.Tklauser.Numcpus.Numcpus;

const
  _SC_NPROCESSORS_CONF = 14;
  _SC_NPROCESSORS_ONLN = 15;
  _SC_NPROCESSORS_MAX  = 516;

function getKernelMax: Integer;
begin
  // Placeholder for unix.Sysconf
  Result := 1;
end;

function getOffline: Integer;
begin
  Result := 0;
  raise ErrNotSupported;
end;

function getOnline: Integer;
begin
  // Placeholder for unix.Sysconf
  Result := 1;
end;

function getPossible: Integer;
begin
  // Placeholder for unix.Sysconf
  Result := 1;
end;

function getPresent: Integer;
begin
  // Placeholder for unix.Sysconf
  Result := 1;
end;

end.
