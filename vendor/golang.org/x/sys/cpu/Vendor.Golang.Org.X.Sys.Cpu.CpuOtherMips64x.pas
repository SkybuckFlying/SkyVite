unit Vendor.Golang.Org.X.Sys.Cpu.CpuOtherMips64x;

interface

procedure ArchInit;

implementation

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure ArchInit;
begin
  Initialized := True;
end;

end.
