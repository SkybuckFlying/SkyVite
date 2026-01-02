unit Vendor.Golang.Org.X.Sys.Unix.AffinityLinux;

interface

uses
  System.SysUtils;

const
  CPU_SETSIZE = 1024; // _CPU_SETSIZE
  NCPUBITS = 64;      // _NCPUBITS
  CPUSetSize = CPU_SETSIZE div NCPUBITS;

type
  TCPUMask = UInt64;
  TCPUSet = array[0..CPUSetSize-1] of TCPUMask;
  PCPUSet = ^TCPUSet;

function SchedGetaffinity(PID: Integer; Set_: PCPUSet): Exception;
function SchedSetaffinity(PID: Integer; Set_: PCPUSet): Exception;

implementation

function SchedGetaffinity(PID: Integer; Set_: PCPUSet): Exception;
begin
  Result := nil;
end;

function SchedSetaffinity(PID: Integer; Set_: PCPUSet): Exception;
begin
  Result := nil;
end;

end.
