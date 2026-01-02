unit Vendor.Golang.Org.X.Sys.Cpu.CpuLinuxArm64;

interface

procedure DoInit;

implementation

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure DoInit;
begin
  // ARM64.HasFP := isSet(hwCap, hwcap_FP);
  // ...
end;

end.
