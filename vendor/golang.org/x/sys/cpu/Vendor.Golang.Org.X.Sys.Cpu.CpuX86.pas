unit Vendor.Golang.Org.X.Sys.Cpu.CpuX86;

interface

uses
  System.SysUtils, Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure InitOptions;
procedure ArchInit;

implementation

procedure InitOptions;
begin
  // options = ...
end;

procedure ArchInit;
begin
  Initialized := True;
  // cpuid(0, 0)
  // ...
end;

end.
