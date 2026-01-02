unit Vendor.Golang.Org.X.Sys.Cpu.CpuLinuxArm;

interface

procedure DoInit;

implementation

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure DoInit;
begin
  // ARM.HasSWP := isSet(hwCap, hwcap_SWP);
  // ...
end;

end.
