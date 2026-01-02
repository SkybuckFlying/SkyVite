{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallDarwinArm64;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesDarwin;

function Fstat( ParaFd : Integer; ParaStat : PZStat_t ) : Integer;
function Fstatat( ParaFd : Integer; ParaPath : string; ParaStat : PZStat_t; ParaFlags : Integer ) : Integer;
function Fstatfs( ParaFd : Integer; ParaStat : PZStatfs_t ) : Integer;
function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
function Stat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
function Statfs( ParaPath : string; ParaStat : PZStatfs_t ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallDarwin;

function SetTimespec( ParaSec : Int64; ParaNsec : Int64 ) : TTimespec;
begin
	Result.Sec := ParaSec;
	Result.Nsec := ParaNsec;
end;

function SetTimeval( ParaSec : Int64; ParaUsec : Int64 ) : TTimeval;
begin
	Result.Sec := ParaSec;
	Result.Usec := Int32( ParaUsec );
end;

procedure SetKevent( ParaK : PZKevent_t; ParaFd : Integer; ParaMode : Integer; ParaFlags : Integer );
begin
	ParaK.Ident := UInt64( ParaFd );
	ParaK.Filter := Int16( ParaMode );
	ParaK.Flags := UInt16( ParaFlags );
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
	Self.Len := UInt64( ParaLength );
end;

procedure TMsghdrHelper.SetControllen( ParaLength : Integer );
begin
	Self.Controllen := UInt32( ParaLength );
end;

procedure TMsghdrHelper.SetIovlen( ParaLength : Integer );
begin
	Self.Iovlen := Int32( ParaLength );
end;

procedure TCmsghdrHelper.SetLen( ParaLength : Integer );
begin
	Self.Len := UInt32( ParaLength );
end;

function Fstat( ParaFd : Integer; ParaStat : PZStat_t ) : Integer;
var
	vErr : Integer;
begin
	Result := fstat( ParaFd, ParaStat, vErr );
end;

function Fstatat( ParaFd : Integer; ParaPath : string; ParaStat : PZStat_t; ParaFlags : Integer ) : Integer;
var
	vErr : Integer;
begin
	Result := fstatat( ParaFd, ParaPath, ParaStat, ParaFlags, vErr );
end;

function Fstatfs( ParaFd : Integer; ParaStat : PZStatfs_t ) : Integer;
var
	vErr : Integer;
begin
	Result := fstatfs( ParaFd, ParaStat, vErr );
end;

function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
var
	vErr : Integer;
begin
	Result := lstat( ParaPath, ParaStat, vErr );
end;

function Stat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
var
	vErr : Integer;
begin
	Result := stat( ParaPath, ParaStat, vErr );
end;

function Statfs( ParaPath : string; ParaStat : PZStatfs_t ) : Integer;
var
	vErr : Integer;
begin
	Result := statfs( ParaPath, ParaStat, vErr );
end;

end.
