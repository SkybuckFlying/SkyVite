{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallOpenbsd;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesOpenbsd;

function Pipe( ParaP : TArray<Integer> ) : Integer;
function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
function Getdirentries( ParaFd : Integer; ParaBuf : TArray<Byte>; ParaBasep : PUintPtr; out ParaErr : Integer ) : Integer;
function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
function Getfsstat( ParaBuf : TArray<TStatfs_t>; ParaFlags : Integer; out ParaErr : Integer ) : Integer;
function Ppoll( ParaFds : TArray<TPollFd>; ParaTimeout : PZTimespec; ParaSigmask : PZSigset_t; out ParaErr : Integer ) : Integer;
function Uname( ParaUname : PZUtsname ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallOpenbsd,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function Pipe( ParaP : TArray<Integer> ) : Integer;
begin
	Result := Pipe2( ParaP, 0 );
end;

function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
var
	vPp : array[0..1] of T_C_int;
	vErr : Integer;
begin
	if Length( ParaP ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vErr := pipe2( @vPp, ParaFlags );
	if vErr = 0 then
	begin
		ParaP[0] := Integer( vPp[0] );
		ParaP[1] := Integer( vPp[1] );
	end;
	Result := vErr;
end;

function Getdirentries( ParaFd : Integer; ParaBuf : TArray<Byte>; ParaBasep : PUintPtr; out ParaErr : Integer ) : Integer;
var
	vN : Integer;
	vOff : Int64;
begin
	vN := Getdents( ParaFd, ParaBuf, ParaErr );
	if ( ParaErr <> 0 ) or ( ParaBasep = nil ) then
	begin
		Result := vN;
		Exit;
	end;

	vOff := Seek( ParaFd, 0, 1, ParaErr );
	if ParaErr <> 0 then
	begin
		ParaBasep^ := UIntPtr( -1 );
		Result := vN;
		Exit;
	end;
	ParaBasep^ := UIntPtr( vOff );
	if SizeOf( ParaBasep^ ) = 8 then
	begin
		Result := vN;
		Exit;
	end;
	if ( vOff shr 32 ) <> 0 then
	begin
		ParaErr := EIO;
	end;
	Result := vN;
end;

function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
begin
	ParaErr := ENOSYS;
	Result := -1;
end;

function Getfsstat( ParaBuf : TArray<TStatfs_t>; ParaFlags : Integer; out ParaErr : Integer ) : Integer;
var
	vP0 : Pointer;
	vBufsize : UIntPtr;
	vR0 : UIntPtr;
begin
	vP0 := nil;
	vBufsize := 0;
	if Length( ParaBuf ) > 0 then
	begin
		vP0 := @ParaBuf[0];
		vBufsize := SizeOf( TStatfs_t ) * Length( ParaBuf );
	end;
	vR0 := Syscall( SYS_GETFSSTAT, UIntPtr( vP0 ), vBufsize, UIntPtr( ParaFlags ), ParaErr );
	Result := Integer( vR0 );
end;

function Ppoll( ParaFds : TArray<TPollFd>; ParaTimeout : PZTimespec; ParaSigmask : PZSigset_t; out ParaErr : Integer ) : Integer;
begin
	if Length( ParaFds ) = 0 then
	begin
		Result := ppoll( nil, 0, ParaTimeout, ParaSigmask, ParaErr );
	end else
	begin
		Result := ppoll( @ParaFds[0], Length( ParaFds ), ParaTimeout, ParaSigmask, ParaErr );
	end;
end;

function Uname( ParaUname : PZUtsname ) : Integer;
begin
	Result := 0; // Placeholder
end;

end.
