unit Vendor.Golang.Org.X.Sys.Cpu.Cpu;

interface

uses
  System.SysUtils;

var
  Initialized: Boolean;

type
  TCacheLinePad = record
    Data: array[0..63] of Byte; // Simplified
  end;

var
  X86: record
    HasAES: Boolean;
    HasAVX: Boolean;
    HasAVX2: Boolean;
    // ...
  end;

  ARM64: record
    HasFP: Boolean;
    HasASIMD: Boolean;
    // ...
  end;

implementation

end.
