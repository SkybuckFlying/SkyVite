unit Vendor.Golang.Org.X.Sys.Unix.FcntlDarwin;

interface

uses
  System.SysUtils;

function FcntlInt(FD: UIntPtr; Cmd, Arg: Integer): TTuple<Integer, Exception>;

implementation

function FcntlInt(FD: UIntPtr; Cmd, Arg: Integer): TTuple<Integer, Exception>;
begin
  Result := Default(TTuple<Integer, Exception>);
end;

end.
