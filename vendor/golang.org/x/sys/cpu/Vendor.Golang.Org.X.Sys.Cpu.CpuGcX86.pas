unit Vendor.Golang.Org.X.Sys.Cpu.CpuGcX86;

interface

function DarwinSupportsAVX512: Boolean;

implementation

function DarwinSupportsAVX512: Boolean; external;

end.
