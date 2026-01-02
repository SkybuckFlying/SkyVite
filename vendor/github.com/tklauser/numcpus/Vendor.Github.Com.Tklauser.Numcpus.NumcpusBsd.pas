unit Vendor.Github.Com.Tklauser.Numcpus.NumcpusBsd;

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

function getKernelMax: Integer;
begin
  Result := 0;
  raise ErrNotSupported;
end;

function getOffline: Integer;
begin
  Result := 0;
  raise ErrNotSupported;
end;

function getOnline: Integer;
begin
  // Placeholder for unix.SysctlUint32
  Result := 1;
end;

function getPossible: Integer;
begin
  // Placeholder for unix.SysctlUint32
  Result := 1;
end;

function getPresent: Integer;
begin
  // Placeholder for unix.SysctlUint32
  Result := 1;
end;

end.
