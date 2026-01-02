unit Vendor.Golang.Org.X.Sys.Cpu.CpuLinuxS390x;

interface

procedure InitS390Xbase;

implementation

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure InitS390Xbase;
begin
  // S390X.HasZARCH := has(hwcap_ZARCH);
  // ...
end;

end.
