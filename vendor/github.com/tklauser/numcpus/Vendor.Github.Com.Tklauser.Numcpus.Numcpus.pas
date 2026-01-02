unit Vendor.Github.Com.Tklauser.Numcpus.Numcpus;

interface

uses
  System.SysUtils;

var
  /// <summary>
  /// ErrNotSupported is the error returned when the function is not supported.
  /// </summary>
  ErrNotSupported: Exception;

/// <summary>
/// GetKernelMax returns the maximum number of CPUs allowed by the kernel
/// configuration. This function is only supported on Linux systems.
/// </summary>
function GetKernelMax: Integer;

/// <summary>
/// GetOffline returns the number of offline CPUs, i.e. CPUs that are not online
/// because they have been hotplugged off or exceed the limit of CPUs allowed by
/// the kernel configuration (see GetKernelMax). This function is only supported
/// on Linux systems.
/// </summary>
function GetOffline: Integer;

/// <summary>
/// GetOnline returns the number of CPUs that are online and being scheduled.
/// </summary>
function GetOnline: Integer;

/// <summary>
/// GetPossible returns the number of possible CPUs, i.e. CPUs that
/// have been allocated resources and can be brought online if they are present.
/// </summary>
function GetPossible: Integer;

/// <summary>
/// GetPresent returns the number of CPUs present in the system.
/// </summary>
function GetPresent: Integer;

implementation

uses
  Vendor.Github.Com.Tklauser.Numcpus.NumcpusInternal;

function GetKernelMax: Integer;
begin
  Result := getKernelMax_internal;
end;

function GetOffline: Integer;
begin
  Result := getOffline_internal;
end;

function GetOnline: Integer;
begin
  Result := getOnline_internal;
end;

function GetPossible: Integer;
begin
  Result := getPossible_internal;
end;

function GetPresent: Integer;
begin
  Result := getPresent_internal;
end;

initialization
  ErrNotSupported := Exception.Create('function not supported');

finalization
  ErrNotSupported.Free;

end.
