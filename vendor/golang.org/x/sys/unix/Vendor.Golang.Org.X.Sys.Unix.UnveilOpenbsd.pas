{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.UnveilOpenbsd;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesOpenbsd;

function Unveil( ParaPath : string; ParaFlags : string ) : Integer;
function UnveilBlock : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallOpenbsd,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function Unveil( ParaPath : string; ParaFlags : string ) : Integer;
var
	vPathPtr : PByte;
	vFlagsPtr : PByte;
	vErr : Integer;
begin
	vPathPtr := BytePtrFromString( ParaPath );
	vFlagsPtr := BytePtrFromString( ParaFlags );
	Result := Syscall( SYS_UNVEIL, UIntPtr( vPathPtr ), UIntPtr( vFlagsPtr ), 0, vErr );
end;

function UnveilBlock : Integer;
var
	vErr : Integer;
begin
	Result := Syscall( SYS_UNVEIL, 0, 0, 0, vErr );
end;

end.
