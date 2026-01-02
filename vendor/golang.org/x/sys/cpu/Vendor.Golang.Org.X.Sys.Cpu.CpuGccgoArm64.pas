unit Vendor.Golang.Org.X.Sys.Cpu.CpuGccgoArm64;

interface

uses
  System.SysUtils;

function getisar0: UInt64;
function getisar1: UInt64;
function getpfr0: UInt64;

implementation

function getisar0: UInt64; begin Result := 0; end;
function getisar1: UInt64; begin Result := 0; end;
function getpfr0: UInt64; begin Result := 0; end;

end.
