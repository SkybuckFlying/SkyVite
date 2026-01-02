unit Vendor.Golang.Org.X.Sys.Cpu.CpuLinux;

interface

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure ArchInit;

implementation

procedure ArchInit;
begin
  // if readHWCAP = nil then Exit;
  // doinit;
  Initialized := True;
end;

end.
