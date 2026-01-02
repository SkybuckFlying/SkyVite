unit Vendor.Golang.Org.X.Sys.Cpu.HwcapLinux;

interface

uses
  System.SysUtils;

var
  HwCap: UInt;
  HwCap2: UInt;

function ReadHWCAP: Exception;

implementation

function ReadHWCAP: Exception;
begin
  // ioutil.ReadFile("/proc/self/auxv")
  Result := nil;
end;

end.
