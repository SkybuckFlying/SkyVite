unit Vendor.Golang.Org.X.Sys.Cpu.CpuArm64;

interface

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure ArchInit;

implementation

procedure ArchInit;
begin
  Initialized := True;
end;

end.
