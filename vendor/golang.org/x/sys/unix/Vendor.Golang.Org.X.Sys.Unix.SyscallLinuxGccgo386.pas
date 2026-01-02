{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinuxGccgo386;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux;

function seek( ParaFd : Integer; ParaOffset : Int64; ParaWhence : Integer; out ParaErr : Integer ) : Int64;
function socketcall( ParaCall : Integer; ParaA0, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5 : UIntPtr; out ParaErr : Integer ) : Integer;
function rawsocketcall( ParaCall : Integer; ParaA0, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5 : UIntPtr; out ParaErr : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallLinux,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function seek( ParaFd : Integer; ParaOffset : Int64; ParaWhence : Integer; out ParaErr : Integer ) : Int64;
var
	vOffsetLow, vOffsetHigh : uint32;
	vNewoffset : Int64;
begin
	vOffsetLow := uint32( ParaOffset and $FFFFFFFF );
	vOffsetHigh := uint32( ( ParaOffset shr 32 ) and $FFFFFFFF );
	Syscall6( SYS__LLSEEK, UIntPtr( ParaFd ), UIntPtr( vOffsetHigh ), UIntPtr( vOffsetLow ), UIntPtr( @vNewoffset ), UIntPtr( ParaWhence ), 0, ParaErr );
	Result := vNewoffset;
end;

function socketcall( ParaCall : Integer; ParaA0, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5 : UIntPtr; out ParaErr : Integer ) : Integer;
var
	vR1, vR2 : UIntPtr;
begin
	vR1 := Syscall( SYS_SOCKETCALL, UIntPtr( ParaCall ), UIntPtr( @ParaA0 ), 0, ParaErr );
	Result := Integer( vR1 );
end;

function rawsocketcall( ParaCall : Integer; ParaA0, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5 : UIntPtr; out ParaErr : Integer ) : Integer;
var
	vR1, vR2 : UIntPtr;
begin
	vR1 := RawSyscall( SYS_SOCKETCALL, UIntPtr( ParaCall ), UIntPtr( @ParaA0 ), 0, ParaErr );
	Result := Integer( vR1 );
end;

end.
