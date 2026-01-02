{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallDragonfly;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesDragonfly;

function SupportsABI( ParaVer : uint32 ) : Boolean;
function Nametomib( ParaName : string; out ParaErr : Integer ) : TArray<T_C_int>;
function Pipe( ParaP : TArray<Integer> ) : Integer;
function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
function Pread( ParaFd : Integer; ParaP : TArray<Byte>; ParaOffset : Int64; out ParaErr : Integer ) : Integer;
function Pwrite( ParaFd : Integer; ParaP : TArray<Byte>; ParaOffset : Int64; out ParaErr : Integer ) : Integer;
function Accept4( ParaFd : Integer; ParaFlags : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
function Getfsstat( ParaBuf : TArray<TStatfs_t>; ParaFlags : Integer; out ParaErr : Integer ) : Integer;
function Uname( ParaUname : PZUtsname ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallDragonfly,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

var
	mOsreldate : uint32;
	mOsreldateOnce : Boolean = False;

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
var
	vR, vW : Integer;
	vErr : Integer;
begin
	if Length( ParaP ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vR := pipe( vW, vErr );
	if vErr = 0 then
	begin
		ParaP[0] := vR;
		ParaP[1] := vW;
	end;
	Result := vErr;
end;

function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
var
	vPp : array[0..1] of T_C_int;
	vR, vW : Integer;
	vErr : Integer;
begin
	if Length( ParaP ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vR := pipe2( @vPp, ParaFlags, vW, vErr );
	if vErr = 0 then
	begin
		ParaP[0] := vR;
		ParaP[1] := vW;
	end;
	Result := vErr;
end;

function Pread( ParaFd : Integer; ParaP : TArray<Byte>; ParaOffset : Int64; out ParaErr : Integer ) : Integer;
begin
	Result := extpread( ParaFd, ParaP, 0, ParaOffset, ParaErr );
end;

function Pwrite( ParaFd : Integer; ParaP : TArray<Byte>; ParaOffset : Int64; out ParaErr : Integer ) : Integer;
begin
	Result := extpwrite( ParaFd, ParaP, 0, ParaOffset, ParaErr );
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
	vR0 : UIntPtr;
begin
	if Length( ParaBuf ) > 0 then
	begin
		vP0 := @ParaBuf[0];
		vBufsize := SizeOf( TStatfs_t ) * Length( ParaBuf );
	end else
	begin
		vP0 := nil;
		vBufsize := 0;
	end;
	vR0 := Syscall( SYS_GETFSSTAT, UIntPtr( vP0 ), vBufsize, UIntPtr( ParaFlags ), ParaErr );
	Result := Integer( vR0 );
end;

function Uname( ParaUname : PZUtsname ) : Integer;
// Implementation of Uname for Dragonfly...
begin
	Result := 0; // Placeholder
end;

end.
