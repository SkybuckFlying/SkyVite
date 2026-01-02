unit Vendor.Golang.Org.X.Sys.Cpu.CpuZos;

interface

procedure ArchInit;

implementation

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure ArchInit;
begin
  // doinit;
  Initialized := True;
end;

end.
