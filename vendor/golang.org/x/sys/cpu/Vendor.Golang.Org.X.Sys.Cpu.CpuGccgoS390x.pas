unit Vendor.Golang.Org.X.Sys.Cpu.CpuGccgoS390x;

interface

uses
  System.SysUtils;

function haveAsmFunctions: Boolean;

implementation

function haveAsmFunctions: Boolean;
begin
  Result := False;
end;

end.
