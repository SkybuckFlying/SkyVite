{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinuxMips64x;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux;

function Select( ParaNfd : Integer; ParaR : PZFdSet; ParaW : PZFdSet; ParaE : PZFdSet; ParaTimeout : PZTimeval ) : Integer;
function Time( ParaT : PZTime_t ) : TTime_t;
function Pipe( ParaP : TArray<Integer> ) : Integer;
function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
function Ioperm( ParaFrom : Integer; ParaNum : Integer; ParaOn : Integer ) : Integer;
function Iopl( ParaLevel : Integer ) : Integer;
function Fstat( ParaFd : Integer; ParaS : PZStat_t ) : Integer;
function Fstatat( ParaDirfd : Integer; ParaPath : string; ParaS : PZStat_t; ParaFlags : Integer ) : Integer;
function Lstat( ParaPath : string; ParaS : PZStat_t ) : Integer;
function Stat( ParaPath : string; ParaS : PZStat_t ) : Integer;
function InotifyInit : Integer;
function Poll( ParaFds : TArray<TPollFd>; ParaTimeout : Integer; out ParaErr : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallLinux,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix,
	Vendor.Golang.Org.X.Sys.Unix.SyscallLinux;

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

function Ioperm( ParaFrom : Integer; ParaNum : Integer; ParaOn : Integer ) : Integer;
begin
	Result := ENOSYS;
end;

function Iopl( ParaLevel : Integer ) : Integer;
begin
	Result := ENOSYS;
end;

type
	T_stat_t = record
		Dev        : uint32;
		Pad0       : array[0..2] of int32;
		Ino        : uint64;
		Mode       : uint32;
		Nlink      : uint32;
		Uid        : uint32;
		Gid        : uint32;
		Rdev       : uint32;
		Pad1       : array[0..2] of uint32;
		Size       : int64;
		Atime      : uint32;
		Atime_nsec : uint32;
		Mtime      : uint32;
		Mtime_nsec : uint32;
		Ctime      : uint32;
		Ctime_nsec : uint32;
		Blksize    : uint32;
		Pad2       : uint32;
		Blocks     : int64;
	end;
	P_stat_t = ^T_stat_t;

procedure fillStat_t( ParaS : PZStat_t; ParaSt : P_stat_t );
begin
	ParaS.Dev := ParaSt.Dev;
	ParaS.Ino := ParaSt.Ino;
	ParaS.Mode := ParaSt.Mode;
	ParaS.Nlink := ParaSt.Nlink;
	ParaS.Uid := ParaSt.Uid;
	ParaS.Gid := ParaSt.Gid;
	ParaS.Rdev := ParaSt.Rdev;
	ParaS.Size := ParaSt.Size;
	ParaS.Atim.Sec := ParaSt.Atime;
	ParaS.Atim.Nsec := ParaSt.Atime_nsec;
	ParaS.Mtim.Sec := ParaSt.Mtime;
	ParaS.Mtim.Nsec := ParaSt.Mtime_nsec;
	ParaS.Ctim.Sec := ParaSt.Ctime;
	ParaS.Ctim.Nsec := ParaSt.Ctime_nsec;
	ParaS.Blksize := ParaSt.Blksize;
	ParaS.Blocks := ParaSt.Blocks;
end;

function Fstat( ParaFd : Integer; ParaS : PZStat_t ) : Integer;
var
	vSt : T_stat_t;
begin
	Result := fstat( ParaFd, @vSt );
	if Result = 0 then
	begin
		fillStat_t( ParaS, @vSt );
	end;
end;

function Fstatat( ParaDirfd : Integer; ParaPath : string; ParaS : PZStat_t; ParaFlags : Integer ) : Integer;
var
	vSt : T_stat_t;
begin
	Result := fstatat( ParaDirfd, ParaPath, @vSt, ParaFlags );
	if Result = 0 then
	begin
		fillStat_t( ParaS, @vSt );
	end;
end;

function Lstat( ParaPath : string; ParaS : PZStat_t ) : Integer;
var
	vSt : T_stat_t;
begin
	Result := lstat( ParaPath, @vSt );
	if Result = 0 then
	begin
		fillStat_t( ParaS, @vSt );
	end;
end;

function Stat( ParaPath : string; ParaS : PZStat_t ) : Integer;
var
	vSt : T_stat_t;
begin
	Result := stat( ParaPath, @vSt );
	if Result = 0 then
	begin
		fillStat_t( ParaS, @vSt );
	end;
end;

function InotifyInit : Integer;
var
	vErr : Integer;
begin
	Result := InotifyInit1( 0, vErr );
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
