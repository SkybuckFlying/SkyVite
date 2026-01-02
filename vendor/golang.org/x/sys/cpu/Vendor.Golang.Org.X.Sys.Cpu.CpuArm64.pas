unit Vendor.Golang.Org.X.Sys.Cpu.CpuArm64;

interface

uses
  System.SysUtils,
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

const
  cacheLineSize = 64;

procedure archInit;
procedure initOptions;

implementation

procedure initOptions;
begin
  // Initialization of CPU feature options for ARM64
end;

procedure setMinimalFeatures;
begin
  ARM64.HasASIMD := True;
  ARM64.HasFP := True;
end;

procedure archInit;
begin
  // ARM64 specific initialization
  setMinimalFeatures;
  Initialized := True;
end;

end.
