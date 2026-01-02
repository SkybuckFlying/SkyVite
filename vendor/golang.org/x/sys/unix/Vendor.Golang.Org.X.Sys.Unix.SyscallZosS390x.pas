{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallZosS390x;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesZosS390x;

function Fstat( ParaFd : Integer; ParaStat : PZStat_t ) : Integer;
function Ptsname( ParaFd : Integer; out ParaName : string ) : Integer;
function Close( ParaFd : Integer ) : Integer;
function Getrusage( ParaWho : Integer; ParaRusage : PRusage ) : Integer;
function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
function Stat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
function Open( ParaPath : string; ParaMode : Integer; ParaPerm : uint32; out ParaFd : Integer ) : Integer;
function Getgetcwd( ParaBuf : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Getwd( out ParaErr : Integer ) : string;
function Getgroups( out ParaErr : Integer ) : TArray<Integer>;
function Setgroups( ParaGids : TArray<Integer> ) : Integer;
function Wait4( ParaPid : Integer; var ParaWstatus : TWaitStatus; ParaOptions : Integer; ParaRusage : PRusage ) : Integer;
function Pipe( ParaP : TArray<Integer> ) : Integer;
function Utimes( ParaPath : string; ParaTv : TArray<TTimeval> ) : Integer;
function UtimesNano( ParaPath : string; ParaTs : TArray<TTimespec> ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallZosS390x,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

procedure CopyStat( ParaStat : PZStat_t; ParaStatLE : PZStat_LE_t );
begin
	ParaStat.Dev := uint64( ParaStatLE.Dev );
	ParaStat.Ino := uint64( ParaStatLE.Ino );
	ParaStat.Nlink := uint64( ParaStatLE.Nlink );
	ParaStat.Mode := uint32( ParaStatLE.Mode );
	ParaStat.Uid := uint32( ParaStatLE.Uid );
	ParaStat.Gid := uint32( ParaStatLE.Gid );
	ParaStat.Rdev := uint64( ParaStatLE.Rdev );
	ParaStat.Size := ParaStatLE.Size;
	ParaStat.Atim.Sec := Int64( ParaStatLE.Atim );
	ParaStat.Atim.Nsec := 0;
	ParaStat.Mtim.Sec := Int64( ParaStatLE.Mtim );
	ParaStat.Mtim.Nsec := 0;
	ParaStat.Ctim.Sec := Int64( ParaStatLE.Ctim );
	ParaStat.Ctim.Nsec := 0;
	ParaStat.Blksize := Int64( ParaStatLE.Blksize );
	ParaStat.Blocks := ParaStatLE.Blocks;
end;

function Fstat( ParaFd : Integer; ParaStat : PZStat_t ) : Integer;
var
	vStatLE : TStat_LE_t;
begin
	Result := fstat( ParaFd, @vStatLE );
	if Result = 0 then
	begin
		CopyStat( ParaStat, @vStatLE );
	end;
end;

function Ptsname( ParaFd : Integer; out ParaName : string ) : Integer;
var
	vR0 : UIntPtr;
	vErr : Integer;
begin
	vR0 := syscall_syscall( SYS___PTSNAME_A, UIntPtr( ParaFd ), 0, 0, vErr );
	if vErr <> 0 then
	begin
		Result := vErr;
		Exit;
	end;
	ParaName := string( PAnsiChar( vR0 ) );
	Result := 0;
end;

function Close( ParaFd : Integer ) : Integer;
var
	vErr : Integer;
	vI : Integer;
begin
	syscall_syscall( SYS_CLOSE, UIntPtr( ParaFd ), 0, 0, vErr );
	vI := 0;
	while ( vErr = EAGAIN ) and ( vI < 10 ) do
	begin
		syscall_syscall( SYS_USLEEP, 10, 0, 0, vErr );
		syscall_syscall( SYS_CLOSE, UIntPtr( ParaFd ), 0, 0, vErr );
		Inc( vI );
	end;
	Result := vErr;
end;

function Getrusage( ParaWho : Integer; ParaRusage : PRusage ) : Integer;
var
	vRuz : Trusage_zos;
begin
	Result := getrusage( ParaWho, @vRuz );
	if Result = 0 then
	begin
		ParaRusage.Utime.Sec := vRuz.Utime.Sec;
		ParaRusage.Utime.Usec := Int64( vRuz.Utime.Usec );
		ParaRusage.Stime.Sec := vRuz.Stime.Sec;
		ParaRusage.Stime.Usec := Int64( vRuz.Stime.Usec );
	end;
end;

function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
var
	vStatLE : TStat_LE_t;
begin
	Result := lstat( ParaPath, @vStatLE );
	if Result = 0 then
	begin
		CopyStat( ParaStat, @vStatLE );
	end;
end;

function Stat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
var
	vStatLE : TStat_LE_t;
begin
	Result := stat( ParaPath, @vStatLE );
	if Result = 0 then
	begin
		CopyStat( ParaStat, @vStatLE );
	end;
end;

function Open( ParaPath : string; ParaMode : Integer; ParaPerm : uint32; out ParaFd : Integer ) : Integer;
begin
	ParaFd := open( ParaPath, ParaMode, ParaPerm, Result );
end;

function Getgetcwd( ParaBuf : TArray<Byte>; out ParaErr : Integer ) : Integer;
var
	vP : Pointer;
	vR1, vR2 : UIntPtr;
begin
	if Length( ParaBuf ) > 0 then vP := @ParaBuf[0] else vP := nil;
	vR1 := syscall_syscall( SYS___GETCWD_A, UIntPtr( vP ), UIntPtr( Length( ParaBuf ) ), 0, ParaErr );
	Result := Clen( ParaBuf ) + 1;
end;

function Getwd( out ParaErr : Integer ) : string;
var
	vBuf : array[0..PathMax - 1] of Byte;
	vN : Integer;
begin
	vN := Getgetcwd( TArray<Byte>( @vBuf[0] ), ParaErr );
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
	vWpid := waitpid( ParaPid, @vStatus, ParaOptions, vErr );
	if vWpid <> -1 then
	begin
		ParaWstatus.Value := UInt32( vStatus );
	end;
	Result := vWpid;
end;

function Pipe( ParaP : TArray<Integer> ) : Integer;
var
	vPp : array[0..1] of T_C_int;
	vErr : Integer;
begin
	if Length( ParaP ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vErr := pipe( @vPp );
	if vErr = 0 then
	begin
		ParaP[0] := Integer( vPp[0] );
		ParaP[1] := Integer( vPp[1] );
	end;
	Result := vErr;
end;

function Utimes( ParaPath : string; ParaTv : TArray<TTimeval> ) : Integer;
begin
	if Length( ParaTv ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	Result := utimes( ParaPath, @ParaTv[0] );
end;

function UtimesNano( ParaPath : string; ParaTs : TArray<TTimespec> ) : Integer;
var
	vTv : array[0..1] of TTimeval;
begin
	if Length( ParaTs ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vTv[0] := NsecToTimeval( TimespecToNsec( ParaTs[0] ) );
	vTv[1] := NsecToTimeval( TimespecToNsec( ParaTs[1] ) );
	Result := utimes( ParaPath, @vTv[0] );
end;

end.
