unit Vendor.Golang.Org.X.Sys.Cpu.CpuGccgoS390x;

interface

uses
  Vendor.Golang.Org.X.Sys.Cpu.Cpu;

function HaveAsmFunctions: Boolean;

implementation

function HaveAsmFunctions: Boolean;
begin
  Result := False;
end;

end.
