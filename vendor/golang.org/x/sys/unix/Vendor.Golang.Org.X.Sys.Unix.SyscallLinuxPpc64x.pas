{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinuxPpc64x;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesLinux;

function Pipe( ParaP : TArray<Integer> ) : Integer;
function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
function Poll( ParaFds : TArray<TPollFd>; ParaTimeout : Integer; out ParaErr : Integer ) : Integer;
function SyncFileRange( ParaFd : Integer; ParaOff : Int64; ParaN : Int64; ParaFlags : Integer ) : Integer;
function KexecFileLoad( ParaKernelFd : Integer; ParaInitrdFd : Integer; ParaCmdline : string; ParaFlags : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallLinux,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

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
	Result := syncFileRange2( ParaFd, ParaFlags, ParaOff, ParaN );
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
