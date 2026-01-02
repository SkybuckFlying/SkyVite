unit Vendor.Golang.Org.X.Sys.Cpu.CpuLinuxPpc64x;

interface

procedure DoInit;

implementation

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure DoInit;
begin
  // PPC64.IsPOWER8 := isSet(hwCap2, _PPC_FEATURE2_ARCH_2_07);
  // ...
end;

end.
