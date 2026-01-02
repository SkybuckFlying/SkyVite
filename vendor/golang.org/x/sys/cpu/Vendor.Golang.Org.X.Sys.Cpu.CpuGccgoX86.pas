unit Vendor.Golang.Org.X.Sys.Cpu.CpuGccgoX86;

interface

uses
  System.SysUtils;

procedure cpuid(eaxArg, ecxArg: UInt32; out eax, ebx, ecx, edx: UInt32);
function xgetbv(out eax, edx: UInt32): Boolean;

implementation

procedure cpuid(eaxArg, ecxArg: UInt32; out eax, ebx, ecx, edx: UInt32);
begin
  eax := 0; ebx := 0; ecx := 0; edx := 0;
end;

function xgetbv(out eax, edx: UInt32): Boolean;
begin
  eax := 0; edx := 0;
  Result := False;
end;

end.
