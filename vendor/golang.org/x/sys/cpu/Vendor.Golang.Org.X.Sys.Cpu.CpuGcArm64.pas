unit Vendor.Golang.Org.X.Sys.Cpu.CpuGcArm64;

interface

function GetIsar0: UInt64;
function GetIsar1: UInt64;
function GetPfr0: UInt64;

implementation

function GetIsar0: UInt64; external;
function GetIsar1: UInt64; external;
function GetPfr0: UInt64; external;

end.
