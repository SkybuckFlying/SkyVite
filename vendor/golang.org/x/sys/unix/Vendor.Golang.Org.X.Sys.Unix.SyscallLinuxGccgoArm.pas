{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinuxGccgoArm;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux;

function seek( ParaFd : Integer; ParaOffset : Int64; ParaWhence : Integer; out ParaErr : Integer ) : Int64;

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

end.
