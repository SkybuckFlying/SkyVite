unit Vendor.Golang.Org.X.Sys.Unix.Fcntl;

interface

uses
  System.SysUtils;

function FcntlInt(FD: UIntPtr; Cmd, Arg: Integer): TTuple<Integer, Exception>;
// function FcntlFlock(FD: UIntPtr; Cmd: Integer; Lk: PFlock_t): Exception;

implementation

function FcntlInt(FD: UIntPtr; Cmd, Arg: Integer): TTuple<Integer, Exception>;
begin
  Result := Default(TTuple<Integer, Exception>);
end;

end.
