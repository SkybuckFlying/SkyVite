{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallNetbsd;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesNetbsd;

function Pipe( ParaP : TArray<Integer> ) : Integer;
function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
function Getdirentries( ParaFd : Integer; ParaBuf : TArray<Byte>; ParaBasep : PUintPtr; out ParaErr : Integer ) : Integer;
function Uname( ParaUname : PZUtsname ) : Integer;
function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
function Fstatvfs( ParaFd : Integer; ParaBuf : PZStatvfs_t ) : Integer;
function Statvfs( ParaPath : string; ParaBuf : PZStatvfs_t ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallNetbsd,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function Pipe( ParaP : TArray<Integer> ) : Integer;
var
	vFd1, vFd2 : Integer;
	vErr : Integer;
begin
	if Length( ParaP ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vFd1 := pipe( vFd2, vErr );
	if vErr = 0 then
	begin
		ParaP[0] := vFd1;
		ParaP[1] := vFd2;
	end;
	Result := vErr;
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

function Uname( ParaUname : PZUtsname ) : Integer;
begin
	Result := 0; // Placeholder
end;

function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
begin
	ParaErr := ENOSYS;
	Result := -1;
end;

function Fstatvfs( ParaFd : Integer; ParaBuf : PZStatvfs_t ) : Integer;
begin
	Result := Fstatvfs1( ParaFd, ParaBuf, ST_WAIT );
end;

function Statvfs( ParaPath : string; ParaBuf : PZStatvfs_t ) : Integer;
begin
	Result := Statvfs1( ParaPath, ParaBuf, ST_WAIT );
end;

end.
