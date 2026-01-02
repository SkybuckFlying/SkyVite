{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallUnixGcPpc64x;

interface

uses
	System.SysUtils;

function Syscall( ParaTrap, ParaA1, ParaA2, ParaA3 : UIntPtr; out ParaErr : Integer ) : UIntPtr;
function Syscall6( ParaTrap, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5, ParaA6 : UIntPtr; out ParaErr : Integer ) : UIntPtr;
function RawSyscall( ParaTrap, ParaA1, ParaA2, ParaA3 : UIntPtr; out ParaErr : Integer ) : UIntPtr;
function RawSyscall6( ParaTrap, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5, ParaA6 : UIntPtr; out ParaErr : Integer ) : UIntPtr;

implementation

function Syscall( ParaTrap, ParaA1, ParaA2, ParaA3 : UIntPtr; out ParaErr : Integer ) : UIntPtr;
begin
	Result := 0;
	ParaErr := 0;
end;

function Syscall6( ParaTrap, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5, ParaA6 : UIntPtr; out ParaErr : Integer ) : UIntPtr;
begin
	Result := 0;
	ParaErr := 0;
end;

function RawSyscall( ParaTrap, ParaA1, ParaA2, ParaA3 : UIntPtr; out ParaErr : Integer ) : UIntPtr;
begin
	Result := 0;
	ParaErr := 0;
end;

function RawSyscall6( ParaTrap, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5, ParaA6 : UIntPtr; out ParaErr : Integer ) : UIntPtr;
begin
	Result := 0;
	ParaErr := 0;
end;

end.
