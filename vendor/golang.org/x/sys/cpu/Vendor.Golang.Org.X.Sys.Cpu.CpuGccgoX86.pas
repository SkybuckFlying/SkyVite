unit Vendor.Golang.Org.X.Sys.Cpu.CpuGccgoX86;

interface

function DarwinSupportsAVX512: Boolean;

implementation

function DarwinSupportsAVX512: Boolean;
begin
  Result := False;
end;

end.
