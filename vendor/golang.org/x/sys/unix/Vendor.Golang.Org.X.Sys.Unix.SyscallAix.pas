unit Vendor.Golang.Org.X.Sys.Unix.SyscallAix;

interface

uses
  System.SysUtils;

function Access(const Path: string; Mode: UInt32): Exception;
function Chmod(const Path: string; Mode: UInt32): Exception;
function Getwd: TTuple<string, Exception>;

implementation

function Access(const Path: string; Mode: UInt32): Exception;
begin
  Result := nil;
end;

function Chmod(const Path: string; Mode: UInt32): Exception;
begin
  Result := nil;
end;

function Getwd: TTuple<string, Exception>;
begin
  Result := TTuple<string, Exception>.Create(GetCurrentDir, nil);
end;

end.
