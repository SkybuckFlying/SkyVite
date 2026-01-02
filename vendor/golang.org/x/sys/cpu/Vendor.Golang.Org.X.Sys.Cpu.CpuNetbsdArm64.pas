unit Vendor.Golang.Org.X.Sys.Cpu.CpuNetbsdArm64;

interface

procedure DoInit;

implementation

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

procedure DoInit;
begin
  Initialized := True;
end;

end.
