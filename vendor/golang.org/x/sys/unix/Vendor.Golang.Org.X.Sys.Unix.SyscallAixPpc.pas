{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallAixPpc;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesAixPpc;

//sysnb	Getrlimit(resource int, rlim *Rlimit) (err error) = getrlimit64
//sysnb	Setrlimit(resource int, rlim *Rlimit) (err error) = setrlimit64
//sys	Seek(fd int, offset int64, whence int) (off int64, err error) = lseek64

//sys	mmap(addr uintptr, length uintptr, prot int, flags int, fd int, offset int64) (xaddr uintptr, err error)

function Fstat( ParaFd : Integer; ParaStat : PZStat_t ) : Integer;
function Fstatat( ParaDirfd : Integer; ParaPath : string; ParaStat : PZStat_t; ParaFlags : Integer ) : Integer;
function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
function Stat( ParaPath : string; ParaStatptr : PZStat_t ) : Integer;

implementation

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallAixPpc;

function setTimespec( ParaSec : Int64; ParaNsec : Int64 ) : TTimespec;
begin
	Result.mSec := Int32( ParaSec );
	Result.mNsec := Int32( ParaNsec );
end;

function setTimeval( ParaSec : Int64; ParaUsec : Int64 ) : TTimeval;
begin
	Result.mSec := Int32( ParaSec );
	Result.mUsec := Int32( ParaUsec );
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
	Self.mLen := UInt32( ParaLength );
end;

procedure TMsghdrHelper.SetControllen( ParaLength : Integer );
begin
	Self.mControllen := UInt32( ParaLength );
end;

procedure TMsghdrHelper.SetIovlen( ParaLength : Integer );
begin
	Self.mIovlen := Int32( ParaLength );
end;

procedure TCmsghdrHelper.SetLen( ParaLength : Integer );
begin
	Self.mLen := UInt32( ParaLength );
end;

function Fstat( ParaFd : Integer; ParaStat : PZStat_t ) : Integer;
begin
	Result := fstat( ParaFd, ParaStat );
end;

function Fstatat( ParaDirfd : Integer; ParaPath : string; ParaStat : PZStat_t; ParaFlags : Integer ) : Integer;
begin
	Result := fstatat( ParaDirfd, ParaPath, ParaStat, ParaFlags );
end;

function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
begin
	Result := lstat( ParaPath, ParaStat );
end;

function Stat( ParaPath : string; ParaStatptr : PZStat_t ) : Integer;
begin
	Result := stat( ParaPath, ParaStatptr );
end;

end.
