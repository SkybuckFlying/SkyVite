{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinux;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux;

function Access( ParaPath : string; ParaMode : uint32 ) : Integer;
function Chmod( ParaPath : string; ParaMode : uint32 ) : Integer;
function Chown( ParaPath : string; ParaUid : Integer; ParaGid : Integer ) : Integer;
function Creat( ParaPath : string; ParaMode : uint32; out ParaFd : Integer ) : Integer;
function FanotifyMark( ParaFd : Integer; ParaFlags : UInt; ParaMask : uint64; ParaDirFd : Integer; ParaPathname : string ) : Integer;
function Fchmodat( ParaDirfd : Integer; ParaPath : string; ParaMode : uint32; ParaFlags : Integer ) : Integer;
function Link( ParaOldpath : string; ParaNewpath : string ) : Integer;
function Mkdir( ParaPath : string; ParaMode : uint32 ) : Integer;
function Mknod( ParaPath : string; ParaMode : uint32; ParaDev : Integer ) : Integer;
function Open( ParaPath : string; ParaMode : Integer; ParaPerm : uint32; out ParaFd : Integer ) : Integer;
function Openat( ParaDirfd : Integer; ParaPath : string; ParaFlags : Integer; ParaMode : uint32; out ParaFd : Integer ) : Integer;
function Openat2( ParaDirfd : Integer; ParaPath : string; ParaHow : PZOpenHow; out ParaFd : Integer ) : Integer;
function Ppoll( ParaFds : TArray<TPollFd>; ParaTimeout : PZTimespec; ParaSigmask : PZSigset_t; out ParaErr : Integer ) : Integer;
function Readlink( ParaPath : string; ParaBuf : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Rename( ParaOldpath : string; ParaNewpath : string ) : Integer;
function Rmdir( ParaPath : string ) : Integer;
function Symlink( ParaOldpath : string; ParaNewpath : string ) : Integer;
function Unlink( ParaPath : string ) : Integer;
function Utimes( ParaPath : string; ParaTv : TArray<TTimeval> ) : Integer;
function UtimesNano( ParaPath : string; ParaTs : TArray<TTimespec> ) : Integer;
function UtimesNanoAt( ParaDirfd : Integer; ParaPath : string; ParaTs : TArray<TTimespec>; ParaFlags : Integer ) : Integer;
function Getwd( out ParaErr : Integer ) : string;
function Getgroups( out ParaErr : Integer ) : TArray<Integer>;
function Setgroups( ParaGids : TArray<Integer> ) : Integer;
function Wait4( ParaPid : Integer; var ParaWstatus : TWaitStatus; ParaOptions : Integer; ParaRusage : PRusage ) : Integer;
function Mkfifo( ParaPath : string; ParaMode : uint32 ) : Integer;
function Mkfifoat( ParaDirfd : Integer; ParaPath : string; ParaMode : uint32 ) : Integer;
function Accept( ParaFd : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
function Accept4( ParaFd : Integer; ParaFlags : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
function Reboot( ParaCmd : Integer ) : Integer;
function Mount( ParaSource : string; ParaTarget : string; ParaFstype : string; ParaFlags : UIntPtr; ParaData : string ) : Integer;
function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
function Dup2( ParaOldfd : Integer; ParaNewfd : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallLinux,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function Access( ParaPath : string; ParaMode : uint32 ) : Integer;
begin
	Result := Faccessat( AT_FDCWD, ParaPath, ParaMode, 0 );
end;

function Chmod( ParaPath : string; ParaMode : uint32 ) : Integer;
begin
	Result := Fchmodat( AT_FDCWD, ParaPath, ParaMode, 0 );
end;

function Chown( ParaPath : string; ParaUid : Integer; ParaGid : Integer ) : Integer;
begin
	Result := Fchownat( AT_FDCWD, ParaPath, ParaUid, ParaGid, 0 );
end;

function Creat( ParaPath : string; ParaMode : uint32; out ParaFd : Integer ) : Integer;
begin
	Result := Open( ParaPath, O_CREAT or O_WRONLY or O_TRUNC, ParaMode, ParaFd );
end;

function FanotifyMark( ParaFd : Integer; ParaFlags : UInt; ParaMask : uint64; ParaDirFd : Integer; ParaPathname : string ) : Integer;
var
	vP : PByte;
	vErr : Integer;
begin
	if ParaPathname = '' then
	begin
		Result := fanotifyMark( ParaFd, ParaFlags, ParaMask, ParaDirFd, nil );
	end else
	begin
		vP := BytePtrFromString( ParaPathname );
		Result := fanotifyMark( ParaFd, ParaFlags, ParaMask, ParaDirFd, vP );
	end;
end;

function Fchmodat( ParaDirfd : Integer; ParaPath : string; ParaMode : uint32; ParaFlags : Integer ) : Integer;
begin
	if ( ParaFlags and (not AT_SYMLINK_NOFOLLOW) ) <> 0 then
	begin
		Result := EINVAL;
		Exit;
	end else if ( ParaFlags and AT_SYMLINK_NOFOLLOW ) <> 0 then
	begin
		Result := EOPNOTSUPP;
		Exit;
	end;
	Result := fchmodat( ParaDirfd, ParaPath, ParaMode );
end;

function Link( ParaOldpath : string; ParaNewpath : string ) : Integer;
begin
	Result := Linkat( AT_FDCWD, ParaOldpath, AT_FDCWD, ParaNewpath, 0 );
end;

function Mkdir( ParaPath : string; ParaMode : uint32 ) : Integer;
begin
	Result := Mkdirat( AT_FDCWD, ParaPath, ParaMode );
end;

function Mknod( ParaPath : string; ParaMode : uint32; ParaDev : Integer ) : Integer;
begin
	Result := Mknodat( AT_FDCWD, ParaPath, ParaMode, ParaDev );
end;

function Open( ParaPath : string; ParaMode : Integer; ParaPerm : uint32; out ParaFd : Integer ) : Integer;
begin
	Result := openat( AT_FDCWD, ParaPath, ParaMode or O_LARGEFILE, ParaPerm, ParaFd );
end;

function Openat( ParaDirfd : Integer; ParaPath : string; ParaFlags : Integer; ParaMode : uint32; out ParaFd : Integer ) : Integer;
begin
	Result := openat( ParaDirfd, ParaPath, ParaFlags or O_LARGEFILE, ParaMode, ParaFd );
end;

function Openat2( ParaDirfd : Integer; ParaPath : string; ParaHow : PZOpenHow; out ParaFd : Integer ) : Integer;
begin
	Result := openat2( ParaDirfd, ParaPath, ParaHow, SizeofOpenHow, ParaFd );
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

function Readlink( ParaPath : string; ParaBuf : TArray<Byte>; out ParaErr : Integer ) : Integer;
begin
	Result := Readlinkat( AT_FDCWD, ParaPath, ParaBuf, ParaErr );
end;

function Rename( ParaOldpath : string; ParaNewpath : string ) : Integer;
begin
	Result := Renameat( AT_FDCWD, ParaOldpath, AT_FDCWD, ParaNewpath );
end;

function Rmdir( ParaPath : string ) : Integer;
begin
	Result := Unlinkat( AT_FDCWD, ParaPath, AT_REMOVEDIR );
end;

function Symlink( ParaOldpath : string; ParaNewpath : string ) : Integer;
begin
	Result := Symlinkat( ParaOldpath, AT_FDCWD, ParaNewpath );
end;

function Unlink( ParaPath : string ) : Integer;
begin
	Result := Unlinkat( AT_FDCWD, ParaPath, 0 );
end;

function Utimes( ParaPath : string; ParaTv : TArray<TTimeval> ) : Integer;
var
	vTs : array[0..1] of TTimespec;
	vErr : Integer;
begin
	if Length( ParaTv ) = 0 then
	begin
		vErr := utimensat( AT_FDCWD, ParaPath, nil, 0 );
		if vErr <> ENOSYS then
		begin
			Result := vErr;
			Exit;
		end;
		Result := utimes( ParaPath, nil );
		Exit;
	end;
	if Length( ParaTv ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vTs[0] := NsecToTimespec( TimevalToNsec( ParaTv[0] ) );
	vTs[1] := NsecToTimespec( TimevalToNsec( ParaTv[1] ) );
	vErr := utimensat( AT_FDCWD, ParaPath, @vTs[0], 0 );
	if vErr <> ENOSYS then
	begin
		Result := vErr;
		Exit;
	end;
	Result := utimes( ParaPath, @ParaTv[0] );
end;

function UtimesNano( ParaPath : string; ParaTs : TArray<TTimespec> ) : Integer;
var
	vTv : array[0..1] of TTimeval;
	vErr : Integer;
	vI : Integer;
begin
	if Length( ParaTs ) = 0 then
	begin
		vErr := utimensat( AT_FDCWD, ParaPath, nil, 0 );
		if vErr <> ENOSYS then
		begin
			Result := vErr;
			Exit;
		end;
		Result := utimes( ParaPath, nil );
		Exit;
	end;
	if Length( ParaTs ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vErr := utimensat( AT_FDCWD, ParaPath, @ParaTs[0], 0 );
	if vErr <> ENOSYS then
	begin
		Result := vErr;
		Exit;
	end;
	for vI := 0 to 1 do
	begin
		vTv[vI] := NsecToTimeval( TimespecToNsec( ParaTs[vI] ) );
	end;
	Result := utimes( ParaPath, @vTv[0] );
end;

function UtimesNanoAt( ParaDirfd : Integer; ParaPath : string; ParaTs : TArray<TTimespec>; ParaFlags : Integer ) : Integer;
begin
	if Length( ParaTs ) = 0 then
	begin
		Result := utimensat( ParaDirfd, ParaPath, nil, ParaFlags );
		Exit;
	end;
	if Length( ParaTs ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	Result := utimensat( ParaDirfd, ParaPath, @ParaTs[0], ParaFlags );
end;

function Getwd( out ParaErr : Integer ) : string;
var
	vBuf : array[0..PathMax - 1] of Byte;
	vN : Integer;
begin
	vN := Getcwd( @vBuf[0], PathMax, ParaErr );
	if ParaErr <> 0 then
	begin
		Result := '';
		Exit;
	end;
	if ( vN < 1 ) or ( vN > PathMax ) or ( vBuf[vN - 1] <> 0 ) then
	begin
		ParaErr := EINVAL;
		Result := '';
		Exit;
	end;
	Result := TEncoding.UTF8.GetString( vBuf, 0, vN - 1 );
end;

function Getgroups( out ParaErr : Integer ) : TArray<Integer>;
var
	vN : Integer;
	vA : TArray<T_Gid_t>;
	vI : Integer;
begin
	vN := getgroups( 0, nil, ParaErr );
	if ParaErr <> 0 then
	begin
		Result := nil;
		Exit;
	end;
	if vN = 0 then
	begin
		Result := nil;
		Exit;
	end;
	if ( vN < 0 ) or ( vN > ( 1 shl 20 ) ) then
	begin
		ParaErr := EINVAL;
		Result := nil;
		Exit;
	end;
	SetLength( vA, vN );
	vN := getgroups( vN, @vA[0], ParaErr );
	if ParaErr <> 0 then
	begin
		Result := nil;
		Exit;
	end;
	SetLength( Result, vN );
	for vI := 0 to vN - 1 do
	begin
		Result[vI] := Integer( vA[vI] );
	end;
end;

function Setgroups( ParaGids : TArray<Integer> ) : Integer;
var
	vA : TArray<T_Gid_t>;
	vI : Integer;
begin
	if Length( ParaGids ) = 0 then
	begin
		Result := setgroups( 0, nil );
		Exit;
	end;
	SetLength( vA, Length( ParaGids ) );
	for vI := 0 to Length( ParaGids ) - 1 do
	begin
		vA[vI] := T_Gid_t( ParaGids[vI] );
	end;
	Result := setgroups( Length( vA ), @vA[0] );
end;

function Wait4( ParaPid : Integer; var ParaWstatus : TWaitStatus; ParaOptions : Integer; ParaRusage : PRusage ) : Integer;
var
	vStatus : T_C_int;
	vWpid : Integer;
	vErr : Integer;
begin
	vWpid := wait4( ParaPid, @vStatus, ParaOptions, ParaRusage, vErr );
	ParaWstatus.Value := UInt32( vStatus );
	Result := vWpid;
end;

function Mkfifo( ParaPath : string; ParaMode : uint32 ) : Integer;
begin
	Result := Mknod( ParaPath, ParaMode or S_IFIFO, 0 );
end;

function Mkfifoat( ParaDirfd : Integer; ParaPath : string; ParaMode : uint32 ) : Integer;
begin
	Result := Mknodat( ParaDirfd, ParaPath, ParaMode or S_IFIFO, 0 );
end;

function Accept( ParaFd : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
var
	vRsa : TRawSockaddrAny;
	vLen : T_Socklen;
	vNfd : Integer;
begin
	vLen := SizeofSockaddrAny;
	vNfd := accept4( ParaFd, @vRsa, @vLen, 0, ParaErr );
	if ParaErr = ENOSYS then
	begin
		vNfd := accept( ParaFd, @vRsa, @vLen, ParaErr );
	end;
	if ParaErr <> 0 then
	begin
		Result := 0;
		Exit;
	end;
	ParaSa := AnyToSockaddr( ParaFd, @vRsa, ParaErr );
	if ParaErr <> 0 then
	begin
		Close( vNfd );
		Result := 0;
	end else
	begin
		Result := vNfd;
	end;
end;

function Accept4( ParaFd : Integer; ParaFlags : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
var
	vRsa : TRawSockaddrAny;
	vLen : T_Socklen;
	vNfd : Integer;
begin
	vLen := SizeofSockaddrAny;
	vNfd := accept4( ParaFd, @vRsa, @vLen, ParaFlags, ParaErr );
	if ParaErr <> 0 then
	begin
		Result := 0;
		Exit;
	end;
	ParaSa := AnyToSockaddr( ParaFd, @vRsa, ParaErr );
	if ParaErr <> 0 then
	begin
		Close( vNfd );
		Result := 0;
	end else
	begin
		Result := vNfd;
	end;
end;

function Reboot( ParaCmd : Integer ) : Integer;
begin
	Result := reboot( LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2, ParaCmd, '' );
end;

function Mount( ParaSource : string; ParaTarget : string; ParaFstype : string; ParaFlags : UIntPtr; ParaData : string ) : Integer;
var
	vDatap : PByte;
begin
	if ParaData = '' then
	begin
		Result := mount( ParaSource, ParaTarget, ParaFstype, ParaFlags, nil );
	end else
	begin
		vDatap := BytePtrFromString( ParaData );
		Result := mount( ParaSource, ParaTarget, ParaFstype, ParaFlags, vDatap );
	end;
end;

function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
begin
	Result := sendfile( ParaOutfd, ParaInfd, @ParaOffset, ParaCount, ParaErr );
end;

function Dup2( ParaOldfd : Integer; ParaNewfd : Integer ) : Integer;
begin
	// Simplified...
	Result := dup2( ParaOldfd, ParaNewfd );
end;

end.
