unit Vendor.Golang.Org.X.Sys.Cpu.CpuGccgoArm64;

interface

function GetIsar0: UInt64;
function GetIsar1: UInt64;
function GetPfr0: UInt64;

implementation

function GetIsar0: UInt64; begin Result := 0; end;
function GetIsar1: UInt64; begin Result := 0; end;
function GetPfr0: UInt64; begin Result := 0; end;

end.
