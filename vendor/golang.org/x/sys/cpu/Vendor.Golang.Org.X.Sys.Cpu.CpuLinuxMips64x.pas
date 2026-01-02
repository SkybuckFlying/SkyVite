unit Vendor.Golang.Org.X.Sys.Cpu.CpuLinuxMips64x;

interface

procedure DoInit;

implementation

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure DoInit;
begin
  // MIPS64X.HasMSA := isSet(hwCap, hwcap_MIPS_MSA);
end;

end.
