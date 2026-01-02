unit Vendor.Golang.Org.X.Sys.Unix.Gccgo;

interface

uses
  System.SysUtils;

function Syscall(Trap, A1, A2, A3: UIntPtr): TTuple<UIntPtr, UIntPtr, Exception>;

implementation

function Syscall(Trap, A1, A2, A3: UIntPtr): TTuple<UIntPtr, UIntPtr, Exception>;
begin
  Result := Default(TTuple<UIntPtr, UIntPtr, Exception>);
end;

end.
