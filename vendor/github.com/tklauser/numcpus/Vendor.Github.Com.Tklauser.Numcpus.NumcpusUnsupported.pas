unit Vendor.Github.Com.Tklauser.Numcpus.NumcpusUnsupported;

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
  Result := 0;
  raise ErrNotSupported;
end;

function getPossible: Integer;
begin
  Result := 0;
  raise ErrNotSupported;
end;

function getPresent: Integer;
begin
  Result := 0;
  raise ErrNotSupported;
end;

end.
