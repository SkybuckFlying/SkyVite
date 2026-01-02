{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinuxArm;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux;

function Pipe( ParaP : TArray<Integer> ) : Integer;
function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
function Seek( ParaFd : Integer; ParaOffset : Int64; ParaWhence : Integer; out ParaErr : Integer ) : Int64;
function Time( ParaT : PZTime_t ) : TTime_t;
function Utime( ParaPath : string; ParaBuf : PZUtimbuf ) : Integer;
function Fadvise( ParaFd : Integer; ParaOffset : Int64; ParaLength : Int64; ParaAdvice : Integer ) : Integer;
function Fstatfs( ParaFd : Integer; ParaBuf : PZStatfs_t ) : Integer;
function Statfs( ParaPath : string; ParaBuf : PZStatfs_t ) : Integer;
function Getrlimit( ParaResource : Integer; ParaRlim : PZRlimit ) : Integer;
function Setrlimit( ParaResource : Integer; ParaRlim : PZRlimit ) : Integer;
function Poll( ParaFds : TArray<TPollFd>; ParaTimeout : Integer; out ParaErr : Integer ) : Integer;
function SyncFileRange( ParaFd : Integer; ParaOff : Int64; ParaN : Int64; ParaFlags : Integer ) : Integer;
function KexecFileLoad( ParaKernelFd : Integer; ParaInitrdFd : Integer; ParaCmdline : string; ParaFlags : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallLinux,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix,
	Vendor.Golang.Org.X.Sys.Unix.SyscallLinux;

function SetTimespec( ParaSec : Int64; ParaNsec : Int64 ) : TTimespec;
begin
	Result.Sec := Int32( ParaSec );
	Result.Nsec := Int32( ParaNsec );
end;

function SetTimeval( ParaSec : Int64; ParaUsec : Int64 ) : TTimeval;
begin
	Result.Sec := Int32( ParaSec );
	Result.Usec := Int32( ParaUsec );
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
	vErr := pipe2( @vPp, 0 );
	if vErr = ENOSYS then
	begin
		vErr := pipe( @vPp );
	end;
	if vErr = 0 then
	begin
		ParaP[0] := Integer( vPp[0] );
		ParaP[1] := Integer( vPp[1] );
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

function Seek( ParaFd : Integer; ParaOffset : Int64; ParaWhence : Integer; out ParaErr : Integer ) : Int64;
begin
	Result := seek( ParaFd, ParaOffset, ParaWhence, ParaErr );
end;

function Time( ParaT : PZTime_t ) : TTime_t;
var
	vTv : TTimeval;
	vErr : Integer;
begin
	vErr := Gettimeofday( @vTv );
	if vErr <> 0 then
	begin
		Result := 0;
		Exit;
	end;
	if ParaT <> nil then
	begin
		ParaT^ := TTime_t( vTv.Sec );
	end;
	Result := TTime_t( vTv.Sec );
end;

function Utime( ParaPath : string; ParaBuf : PZUtimbuf ) : Integer;
var
	vTv : array[0..1] of TTimeval;
begin
	vTv[0].Sec := ParaBuf.Actime;
	vTv[1].Sec := ParaBuf.Modtime;
	Result := Utimes( ParaPath, [ vTv[0], vTv[1] ] );
end;

function Fadvise( ParaFd : Integer; ParaOffset : Int64; ParaLength : Int64; ParaAdvice : Integer ) : Integer;
var
	vErr : Integer;
begin
	Result := Syscall6( SYS_ARM_FADVISE64_64, UIntPtr( ParaFd ), UIntPtr( ParaAdvice ), UIntPtr( ParaOffset ), UIntPtr( ParaOffset shr 32 ), UIntPtr( ParaLength ), UIntPtr( ParaLength shr 32 ), vErr );
end;

function Fstatfs( ParaFd : Integer; ParaBuf : PZStatfs_t ) : Integer;
var
	vErr : Integer;
begin
	Result := Syscall( SYS_FSTATFS64, UIntPtr( ParaFd ), SizeOf( TStatfs_t ), UIntPtr( ParaBuf ), vErr );
end;

function Statfs( ParaPath : string; ParaBuf : PZStatfs_t ) : Integer;
var
	vPathp : PByte;
	vErr : Integer;
begin
	vPathp := BytePtrFromString( ParaPath );
	Result := Syscall( SYS_STATFS64, UIntPtr( vPathp ), SizeOf( TStatfs_t ), UIntPtr( ParaBuf ), vErr );
end;

type
	Trlimit32 = record
		Cur : uint32;
		Max : uint32;
	end;

const
	rlimInf32 = uint32( $FFFFFFFF );
	rlimInf64 = uint64( $FFFFFFFFFFFFFFFF );

function Getrlimit( ParaResource : Integer; ParaRlim : PZRlimit ) : Integer;
var
	vRl : Trlimit32;
	vErr : Integer;
begin
	vErr := prlimit( 0, ParaResource, nil, ParaRlim );
	if vErr <> ENOSYS then
	begin
		Result := vErr;
		Exit;
	end;

	vErr := getrlimit( ParaResource, @vRl );
	if vErr <> 0 then
	begin
		Result := vErr;
		Exit;
	end;

	if vRl.Cur = rlimInf32 then
	begin
		ParaRlim.Cur := rlimInf64;
	end else
	begin
		ParaRlim.Cur := uint64( vRl.Cur );
	end;

	if vRl.Max = rlimInf32 then
	begin
		ParaRlim.Max := rlimInf64;
	end else
	begin
		ParaRlim.Max := uint64( vRl.Max );
	end;
	Result := 0;
end;

function Setrlimit( ParaResource : Integer; ParaRlim : PZRlimit ) : Integer;
var
	vRl : Trlimit32;
	vErr : Integer;
begin
	vErr := prlimit( 0, ParaResource, ParaRlim, nil );
	if vErr <> ENOSYS then
	begin
		Result := vErr;
		Exit;
	end;

	if ParaRlim.Cur = rlimInf64 then
	begin
		vRl.Cur := rlimInf32;
	end else if ParaRlim.Cur < uint64( rlimInf32 ) then
	begin
		vRl.Cur := uint32( ParaRlim.Cur );
	end else
	begin
		Result := EINVAL;
		Exit;
	end;

	if ParaRlim.Max = rlimInf64 then
	begin
		vRl.Max := rlimInf32;
	end else if ParaRlim.Max < uint64( rlimInf32 ) then
	begin
		vRl.Max := uint32( ParaRlim.Max );
	end else
	begin
		Result := EINVAL;
		Exit;
	end;

	Result := setrlimit( ParaResource, @vRl );
end;

function Poll( ParaFds : TArray<TPollFd>; ParaTimeout : Integer; out ParaErr : Integer ) : Integer;
begin
	if Length( ParaFds ) = 0 then
	begin
		Result := poll( nil, 0, ParaTimeout, ParaErr );
	end else
	begin
		Result := poll( @ParaFds[0], Length( ParaFds ), ParaTimeout, ParaErr );
	end;
end;

function SyncFileRange( ParaFd : Integer; ParaOff : Int64; ParaN : Int64; ParaFlags : Integer ) : Integer;
begin
	Result := armSyncFileRange( ParaFd, ParaFlags, ParaOff, ParaN );
end;

function KexecFileLoad( ParaKernelFd : Integer; ParaInitrdFd : Integer; ParaCmdline : string; ParaFlags : Integer ) : Integer;
var
	vCmdlineLen : Integer;
begin
	vCmdlineLen := Length( ParaCmdline );
	if vCmdlineLen > 0 then
	begin
		vCmdlineLen := vCmdlineLen + 1;
	end;
	Result := kexecFileLoad( ParaKernelFd, ParaInitrdFd, vCmdlineLen, ParaCmdline, ParaFlags );
end;

type
	TIovecHelper = record helper for TIovec
		procedure SetLen( ParaLength : Integer );
	end;

	TMsghdrHelper = record helper for TMsghdr
		procedure SetControllen( ParaLength : Integer );
		procedure SetIovlen( ParaLength : Integer );
	end;

	TCmsghdrHelper = record helper for TCmsghdr
		procedure SetLen( ParaLength : Integer );
	end;

procedure TIovecHelper.SetLen( ParaLength : Integer );
begin
	Self.Len := uint32( ParaLength );
end;

procedure TMsghdrHelper.SetControllen( ParaLength : Integer );
begin
	Self.Controllen := uint32( ParaLength );
end;

procedure TMsghdrHelper.SetIovlen( ParaLength : Integer );
begin
	Self.Iovlen := uint32( ParaLength );
end;

procedure TCmsghdrHelper.SetLen( ParaLength : Integer );
begin
	Self.Len := uint32( ParaLength );
end;

end.
