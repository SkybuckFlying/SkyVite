unit Vendor.Golang.Org.X.Sys.Unix.PtraceIos;

interface

uses
  System.SysUtils;

function Ptrace(Request, Pid: Integer; Addr, Data: UIntPtr): Exception;

implementation

function Ptrace(Request, Pid: Integer; Addr, Data: UIntPtr): Exception;
begin
  // Result := ENOTSUP;
  Result := nil;
end;

end.
