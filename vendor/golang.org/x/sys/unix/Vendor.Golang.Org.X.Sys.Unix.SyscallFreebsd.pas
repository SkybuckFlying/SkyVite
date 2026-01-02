{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallFreebsd;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesFreebsd;

function SupportsABI( ParaVer : uint32 ) : Boolean;
function Nametomib( ParaName : string; out ParaErr : Integer ) : TArray<T_C_int>;
function Pipe( ParaP : TArray<Integer> ) : Integer;
function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
function Accept4( ParaFd : Integer; ParaFlags : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
function Getfsstat( ParaBuf : TArray<TStatfs_t>; ParaFlags : Integer; out ParaErr : Integer ) : Integer;
function Uname( ParaUname : PZUtsname ) : Integer;
function Stat( ParaPath : string; ParaSt : PZStat_t ) : Integer;
function Lstat( ParaPath : string; ParaSt : PZStat_t ) : Integer;
function Fstat( ParaFd : Integer; ParaSt : PZStat_t ) : Integer;
function Fstatat( ParaFd : Integer; ParaPath : string; ParaSt : PZStat_t; ParaFlags : Integer ) : Integer;
function Statfs( ParaPath : string; ParaSt : PZStatfs_t ) : Integer;
function Fstatfs( ParaFd : Integer; ParaSt : PZStatfs_t ) : Integer;
function Getdents( ParaFd : Integer; ParaBuf : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Getdirentries( ParaFd : Integer; ParaBuf : TArray<Byte>; ParaBasep : PUintPtr; out ParaErr : Integer ) : Integer;
function Mknod( ParaPath : string; ParaMode : uint32; ParaDev : uint64 ) : Integer;
function Mknodat( ParaFd : Integer; ParaPath : string; ParaMode : uint32; ParaDev : uint64 ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallFreebsd,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

var
	mOsreldate : uint32;
	mOsreldateOnce : Boolean = False;

const
	Const_ino64First = 1200031;

function SupportsABI( ParaVer : uint32 ) : Boolean;
var
	vErr : Integer;
begin
	if not mOsreldateOnce then
	begin
		mOsreldate := SysctlUint32( 'kern.osreldate', vErr );
		mOsreldateOnce := True;
	end;
	Result := mOsreldate >= ParaVer;
end;

function Nametomib( ParaName : string; out ParaErr : Integer ) : TArray<T_C_int>;
var
	vSiz : Integer;
	vBuf : array[0..CTL_MAXNAME + 1] of T_C_int;
	vN : UIntPtr;
	vP : PByte;
	vBytes : TArray<Byte>;
begin
	vSiz := SizeOf( T_C_int );
	vN := CTL_MAXNAME;
	vP := @vBuf[0];
	vBytes := ByteSliceFromString( ParaName );
	
	ParaErr := sysctl( [0, 3], vP, @vN, @vBytes[0], Length( ParaName ) );
	if ParaErr <> 0 then
	begin
		Result := nil;
		Exit;
	end;
	
	SetLength( Result, vN div vSiz );
	Move( vBuf[0], Result[0], vN );
end;

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

function Getfsstat( ParaBuf : TArray<TStatfs_t>; ParaFlags : Integer; out ParaErr : Integer ) : Integer;
var
	vP0 : Pointer;
	vBufsize : UIntPtr;
	vSysno : UIntPtr;
	vR0 : UIntPtr;
begin
	vP0 := nil;
	vBufsize := 0;
	if Length( ParaBuf ) > 0 then
	begin
		vP0 := @ParaBuf[0];
		vBufsize := SizeOf( TStatfs_t ) * Length( ParaBuf );
	end;
	
	vSysno := SYS_GETFSSTAT;
	if SupportsABI( Const_ino64First ) then
	begin
		vSysno := SYS_GETFSSTAT_FREEBSD12;
	end;
	
	vR0 := Syscall( vSysno, UIntPtr( vP0 ), vBufsize, UIntPtr( ParaFlags ), ParaErr );
	Result := Integer( vR0 );
end;

function Uname( ParaUname : PZUtsname ) : Integer;
begin
	Result := 0; // Placeholder
end;

function Stat( ParaPath : string; ParaSt : PZStat_t ) : Integer;
begin
	if SupportsABI( Const_ino64First ) then
	begin
		Result := fstatat_freebsd12( AT_FDCWD, ParaPath, ParaSt, 0 );
	end else
	begin
		Result := stat( ParaPath, ParaSt );
	end;
end;

function Lstat( ParaPath : string; ParaSt : PZStat_t ) : Integer;
begin
	if SupportsABI( Const_ino64First ) then
	begin
		Result := fstatat_freebsd12( AT_FDCWD, ParaPath, ParaSt, AT_SYMLINK_NOFOLLOW );
	end else
	begin
		Result := lstat( ParaPath, ParaSt );
	end;
end;

function Fstat( ParaFd : Integer; ParaSt : PZStat_t ) : Integer;
begin
	if SupportsABI( Const_ino64First ) then
	begin
		Result := fstat_freebsd12( ParaFd, ParaSt );
	end else
	begin
		Result := fstat( ParaFd, ParaSt );
	end;
end;

function Fstatat( ParaFd : Integer; ParaPath : string; ParaSt : PZStat_t; ParaFlags : Integer ) : Integer;
begin
	if SupportsABI( Const_ino64First ) then
	begin
		Result := fstatat_freebsd12( ParaFd, ParaPath, ParaSt, ParaFlags );
	end else
	begin
		Result := fstatat( ParaFd, ParaPath, ParaSt, ParaFlags );
	end;
end;

function Statfs( ParaPath : string; ParaSt : PZStatfs_t ) : Integer;
begin
	if SupportsABI( Const_ino64First ) then
	begin
		Result := statfs_freebsd12( ParaPath, ParaSt );
	end else
	begin
		Result := statfs( ParaPath, ParaSt );
	end;
end;

function Fstatfs( ParaFd : Integer; ParaSt : PZStatfs_t ) : Integer;
begin
	if SupportsABI( Const_ino64First ) then
	begin
		Result := fstatfs_freebsd12( ParaFd, ParaSt );
	end else
	begin
		Result := fstatfs( ParaFd, ParaSt );
	end;
end;

function Getdents( ParaFd : Integer; ParaBuf : TArray<Byte>; out ParaErr : Integer ) : Integer;
begin
	Result := Getdirentries( ParaFd, ParaBuf, nil, ParaErr );
end;

function Getdirentries( ParaFd : Integer; ParaBuf : TArray<Byte>; ParaBasep : PUintPtr; out ParaErr : Integer ) : Integer;
var
	vBase : UInt64;
begin
	if SupportsABI( Const_ino64First ) then
	begin
		if ( ParaBasep = nil ) or ( SizeOf( ParaBasep^ ) = 8 ) then
		begin
			Result := getdirentries_freebsd12( ParaFd, ParaBuf, PUint64( ParaBasep ), ParaErr );
		end else
		begin
			vBase := UInt64( ParaBasep^ );
			Result := getdirentries_freebsd12( ParaFd, ParaBuf, @vBase, ParaErr );
			ParaBasep^ := UIntPtr( vBase );
		end;
	end else
	begin
		Result := getdirentries( ParaFd, ParaBuf, ParaBasep, ParaErr );
	end;
end;

function Mknod( ParaPath : string; ParaMode : uint32; ParaDev : uint64 ) : Integer;
begin
	if SupportsABI( Const_ino64First ) then
	begin
		Result := mknodat_freebsd12( AT_FDCWD, ParaPath, ParaMode, ParaDev );
	end else
	begin
		Result := mknod( ParaPath, ParaMode, Integer( ParaDev ) );
	end;
end;

function Mknodat( ParaFd : Integer; ParaPath : string; ParaMode : uint32; ParaDev : uint64 ) : Integer;
begin
	if SupportsABI( Const_ino64First ) then
	begin
		Result := mknodat_freebsd12( ParaFd, ParaPath, ParaMode, ParaDev );
	end else
	begin
		Result := mknodat( ParaFd, ParaPath, ParaMode, Integer( ParaDev ) );
	end;
end;

end.
