{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallAixPpc64;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesAixPpc64;

function Fstat( ParaFd : Integer; ParaStat : PZStat_t ) : Integer;
function Fstatat( ParaDirfd : Integer; ParaPath : string; ParaStat : PZStat_t; ParaFlags : Integer ) : Integer;
function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
function Stat( ParaPath : string; ParaStatptr : PZStat_t ) : Integer;

implementation

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallAixPpc64;

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

procedure FixStatTimFields( ParaStat : PZStat_t );
begin
	ParaStat.Atim.Nsec := ParaStat.Atim.Nsec shr 32;
	ParaStat.Mtim.Nsec := ParaStat.Mtim.Nsec shr 32;
	ParaStat.Ctim.Nsec := ParaStat.Ctim.Nsec shr 32;
end;

function Fstat( ParaFd : Integer; ParaStat : PZStat_t ) : Integer;
var
	vErr : Integer;
begin
	vErr := fstat( ParaFd, ParaStat );
	if vErr <> 0 then
	begin
		Result := vErr;
		Exit;
	end;
	FixStatTimFields( ParaStat );
	Result := 0;
end;

function Fstatat( ParaDirfd : Integer; ParaPath : string; ParaStat : PZStat_t; ParaFlags : Integer ) : Integer;
var
	vErr : Integer;
begin
	vErr := fstatat( ParaDirfd, ParaPath, ParaStat, ParaFlags );
	if vErr <> 0 then
	begin
		Result := vErr;
		Exit;
	end;
	FixStatTimFields( ParaStat );
	Result := 0;
end;

function Lstat( ParaPath : string; ParaStat : PZStat_t ) : Integer;
var
	vErr : Integer;
begin
	vErr := lstat( ParaPath, ParaStat );
	if vErr <> 0 then
	begin
		Result := vErr;
		Exit;
	end;
	FixStatTimFields( ParaStat );
	Result := 0;
end;

function Stat( ParaPath : string; ParaStatptr : PZStat_t ) : Integer;
var
	vErr : Integer;
begin
	vErr := stat( ParaPath, ParaStatptr );
	if vErr <> 0 then
	begin
		Result := vErr;
		Exit;
	end;
	FixStatTimFields( ParaStatptr );
	Result := 0;
end;

end.
