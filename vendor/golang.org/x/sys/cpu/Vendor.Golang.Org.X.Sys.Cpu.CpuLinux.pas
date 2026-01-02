unit Vendor.Golang.Org.X.Sys.Cpu.CpuLinux;

interface

uses
  System.SysUtils,
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure archInit;

implementation

procedure archInit;
begin
  // Linux specific initialization
  Initialized := True;
end;

end.
