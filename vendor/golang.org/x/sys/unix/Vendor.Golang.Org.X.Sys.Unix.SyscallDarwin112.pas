{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallDarwin112;

interface

uses
	System.SysUtils;

const
	Const_SYS_GETDIRENTRIES64 = 344;

function Getdirentries( ParaFd : Integer; ParaBuf : TArray<Byte>; ParaBasep : PUintPtr; out ParaErr : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function Getdirentries( ParaFd : Integer; ParaBuf : TArray<Byte>; ParaBasep : PUintPtr; out ParaErr : Integer ) : Integer;
var
	vP : Pointer;
	vR0 : UIntPtr;
	vE1 : Integer;
begin
	if Length( ParaBuf ) > 0 then
	begin
		vP := @ParaBuf[0];
	end else
	begin
		vP := nil;
	end;
	
	vR0 := Syscall6( Const_SYS_GETDIRENTRIES64, UIntPtr( ParaFd ), UIntPtr( vP ), UIntPtr( Length( ParaBuf ) ), UIntPtr( ParaBasep ), 0, 0, vE1 );
	Result := Integer( vR0 );
	ParaErr := vE1;
end;

end.
