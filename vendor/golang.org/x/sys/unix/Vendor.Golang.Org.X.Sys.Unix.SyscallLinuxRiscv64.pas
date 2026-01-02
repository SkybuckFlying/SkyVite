{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinuxRiscv64;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux;

function EpollCreate( ParaSize : Integer ) : Integer;
function Select( ParaNfd : Integer; ParaR : PZFdSet; ParaW : PZFdSet; ParaE : PZFdSet; ParaTimeout : PZTimeval ) : Integer;
function Stat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
function Lchown( ParaPath : string; ParaUid : Integer; ParaGid : Integer ) : Integer;
function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
function Ustat( ParaDev : Integer; ParaUbuf : PZUstat_t ) : Integer;
function Time( ParaT : PZTime_t ) : TTime_t;
function Utime( ParaPath : string; ParaBuf : PZUtimbuf ) : Integer;
function Pipe( ParaP : TArray<Integer> ) : Integer;
function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
function InotifyInit : Integer;
function Pause : Integer;
function Poll( ParaFds : TArray<TPollFd>; ParaTimeout : Integer; out ParaErr : Integer ) : Integer;
function Renameat( ParaOlddirfd : Integer; ParaOldpath : string; ParaNewdirfd : Integer; ParaNewpath : string ) : Integer;
function KexecFileLoad( ParaKernelFd : Integer; ParaInitrdFd : Integer; ParaCmdline : string; ParaFlags : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallLinux,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix,
	Vendor.Golang.Org.X.Sys.Unix.SyscallLinux;

function EpollCreate( ParaSize : Integer ) : Integer;
var
	vErr : Integer;
begin
	if ParaSize <= 0 then
	begin
		Result := EINVAL;
		Exit;
	end;
	Result := EpollCreate1( 0, vErr );
end;

function Select( ParaNfd : Integer; ParaR : PZFdSet; ParaW : PZFdSet; ParaE : PZFdSet; ParaTimeout : PZTimeval ) : Integer;
var
	vTs : TTimespec;
	vPTs : PZTimespec;
	vErr : Integer;
begin
	vPTs := nil;
	if ParaTimeout <> nil then
	begin
		vTs.Sec := ParaTimeout.Sec;
		vTs.Nsec := ParaTimeout.Usec * 1000;
		vPTs := @vTs;
	end;
	Result := Pselect( ParaNfd, ParaR, ParaW, ParaE, vPTs, nil, vErr );
end;

function Stat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
begin
	Result := Fstatat( AT_FDCWD, ParaPath, ParaStat, 0 );
end;

function Lchown( ParaPath : string; ParaUid : Integer; ParaGid : Integer ) : Integer;
begin
	Result := Fchownat( AT_FDCWD, ParaPath, ParaUid, ParaGid, AT_SYMLINK_NOFOLLOW );
end;

function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
begin
	Result := Fstatat( AT_FDCWD, ParaPath, ParaStat, AT_SYMLINK_NOFOLLOW );
end;

function Ustat( ParaDev : Integer; ParaUbuf : PZUstat_t ) : Integer;
begin
	Result := ENOSYS;
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

function InotifyInit : Integer;
var
	vErr : Integer;
begin
	Result := InotifyInit1( 0, vErr );
end;

function Pause : Integer;
var
	vErr : Integer;
begin
	Result := ppoll( nil, 0, nil, nil, vErr );
end;

function Poll( ParaFds : TArray<TPollFd>; ParaTimeout : Integer; out ParaErr : Integer ) : Integer;
var
	vTs : TTimespec;
	vPTs : PZTimespec;
begin
	vPTs := nil;
	if ParaTimeout >= 0 then
	begin
		vTs := NsecToTimespec( Int64( ParaTimeout ) * 1000000 );
		vPTs := @vTs;
	end;
	if Length( ParaFds ) = 0 then
	begin
		Result := ppoll( nil, 0, vPTs, nil, ParaErr );
	end else
	begin
		Result := ppoll( @ParaFds[0], Length( ParaFds ), vPTs, nil, ParaErr );
	end;
end;

function Renameat( ParaOlddirfd : Integer; ParaOldpath : string; ParaNewdirfd : Integer; ParaNewpath : string ) : Integer;
begin
	Result := Renameat2( ParaOlddirfd, ParaOldpath, ParaNewdirfd, ParaNewpath, 0 );
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
	Self.Len := uint64( ParaLength );
end;

procedure TMsghdrHelper.SetControllen( ParaLength : Integer );
begin
	Self.Controllen := uint64( ParaLength );
end;

procedure TMsghdrHelper.SetIovlen( ParaLength : Integer );
begin
	Self.Iovlen := uint64( ParaLength );
end;

procedure TCmsghdrHelper.SetLen( ParaLength : Integer );
begin
	Self.Len := uint64( ParaLength );
end;

end.
