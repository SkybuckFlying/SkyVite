unit Vendor.Golang.Org.X.Sys.Cpu.CpuAix;

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
