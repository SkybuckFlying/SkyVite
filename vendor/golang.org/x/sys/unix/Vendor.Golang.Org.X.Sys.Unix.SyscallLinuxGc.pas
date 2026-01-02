{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinuxGc;

interface

uses
	System.SysUtils;

function SyscallNoError( ParaTrap : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;
function RawSyscallNoError( ParaTrap : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;

implementation

function SyscallNoError( ParaTrap : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;
begin
	Result := 0;
end;

function RawSyscallNoError( ParaTrap : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;
begin
	Result := 0;
end;

end.
