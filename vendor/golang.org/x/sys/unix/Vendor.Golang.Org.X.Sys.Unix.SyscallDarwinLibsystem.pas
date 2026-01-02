{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallDarwinLibsystem;

interface

uses
	System.SysUtils;

function syscall_syscall( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;
function syscall_syscall6( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; ParaA4 : UIntPtr; ParaA5 : UIntPtr; ParaA6 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;
function syscall_syscall6X( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; ParaA4 : UIntPtr; ParaA5 : UIntPtr; ParaA6 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;
function syscall_syscall9( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; ParaA4 : UIntPtr; ParaA5 : UIntPtr; ParaA6 : UIntPtr; ParaA7 : UIntPtr; ParaA8 : UIntPtr; ParaA9 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;
function syscall_rawSyscall( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;
function syscall_rawSyscall6( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; ParaA4 : UIntPtr; ParaA5 : UIntPtr; ParaA6 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;
function syscall_syscallPtr( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer;

implementation

// Implementation would be platform specific (e.g. assembly or external libSystem calls)
function syscall_syscall( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer; begin Result := 0; end;
function syscall_syscall6( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; ParaA4 : UIntPtr; ParaA5 : UIntPtr; ParaA6 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer; begin Result := 0; end;
function syscall_syscall6X( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; ParaA4 : UIntPtr; ParaA5 : UIntPtr; ParaA6 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer; begin Result := 0; end;
function syscall_syscall9( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; ParaA4 : UIntPtr; ParaA5 : UIntPtr; ParaA6 : UIntPtr; ParaA7 : UIntPtr; ParaA8 : UIntPtr; ParaA9 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer; begin Result := 0; end;
function syscall_rawSyscall( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer; begin Result := 0; end;
function syscall_rawSyscall6( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; ParaA4 : UIntPtr; ParaA5 : UIntPtr; ParaA6 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer; begin Result := 0; end;
function syscall_syscallPtr( ParaFn : UIntPtr; ParaA1 : UIntPtr; ParaA2 : UIntPtr; ParaA3 : UIntPtr; out ParaR1 : UIntPtr; out ParaR2 : UIntPtr ) : Integer; begin Result := 0; end;

end.
