unit Vendor.Golang.Org.X.Sys.Cpu.CpuGcS390x;

interface

uses
  System.SysUtils;

function haveAsmFunctions: Boolean;

implementation

function haveAsmFunctions: Boolean;
begin
  Result := True;
end;

end.
