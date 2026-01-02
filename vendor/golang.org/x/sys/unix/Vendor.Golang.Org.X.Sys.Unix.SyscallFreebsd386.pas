{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallFreebsd386;

interface

uses
	Vendor.Golang.Org.X.Sys.Unix.ZtypesFreebsd;

function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
function PtraceGetFsBase( ParaPid : Integer; var ParaFsbase : Int64 ) : Integer;
function PtraceIO( ParaReq : Integer; ParaPid : Integer; ParaAddr : UIntPtr; ParaOut : TArray<Byte>; ParaCountin : Integer; out ParaCount : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallFreebsd,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

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

procedure SetKevent( ParaK : PZKevent_t; ParaFd : Integer; ParaMode : Integer; ParaFlags : Integer );
begin
	ParaK.Ident := UInt32( ParaFd );
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
	Self.Len := UInt32( ParaLength );
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

function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
var
	vWrittenOut : UInt64;
	vR1 : UIntPtr;
begin
	vWrittenOut := 0;
	vR1 := Syscall9( SYS_SENDFILE, UIntPtr( ParaInfd ), UIntPtr( ParaOutfd ), UIntPtr( ParaOffset ), UIntPtr( ParaOffset shr 32 ), UIntPtr( ParaCount ), 0, UIntPtr( @vWrittenOut ), 0, 0, ParaErr );
	Result := Integer( vWrittenOut );
end;

function PtraceGetFsBase( ParaPid : Integer; var ParaFsbase : Int64 ) : Integer;
begin
	Result := ptrace( PTRACE_GETFSBASE, ParaPid, UIntPtr( @ParaFsbase ), 0 );
end;

function PtraceIO( ParaReq : Integer; ParaPid : Integer; ParaAddr : UIntPtr; ParaOut : TArray<Byte>; ParaCountin : Integer; out ParaCount : Integer ) : Integer;
var
	vIoDesc : TPtraceIoDesc;
begin
	vIoDesc.Op := Int32( ParaReq );
	vIoDesc.Offs := PByte( ParaAddr );
	vIoDesc.Addr := @ParaOut[0];
	vIoDesc.Len := UInt32( ParaCountin );
	Result := ptrace( PTRACE_IO, ParaPid, UIntPtr( @vIoDesc ), 0 );
	ParaCount := Integer( vIoDesc.Len );
end;

end.
