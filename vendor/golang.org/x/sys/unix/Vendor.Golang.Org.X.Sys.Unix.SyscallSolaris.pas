{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallSolaris;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesSolaris;

function Pipe( ParaP : TArray<Integer> ) : Integer;
function Pipe2( ParaP : TArray<Integer>; ParaFlags : Integer ) : Integer;
function Getsockname( ParaFd : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
function Getwd( out ParaErr : Integer ) : string;
function Getgroups( out ParaErr : Integer ) : TArray<Integer>;
function Setgroups( ParaGids : TArray<Integer> ) : Integer;
function ReadDirent( ParaFd : Integer; ParaBuf : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Wait4( ParaPid : Integer; var ParaWstatus : TWaitStatus; ParaOptions : Integer; ParaRusage : PRusage ) : Integer;
function Gethostname( out ParaErr : Integer ) : string;
function Utimes( ParaPath : string; ParaTv : TArray<TTimeval> ) : Integer;
function UtimesNano( ParaPath : string; ParaTs : TArray<TTimespec> ) : Integer;
function UtimesNanoAt( ParaDirfd : Integer; ParaPath : string; ParaTs : TArray<TTimespec>; ParaFlags : Integer ) : Integer;
function Futimesat( ParaDirfd : Integer; ParaPath : string; ParaTv : TArray<TTimeval> ) : Integer;
function Futimes( ParaFd : Integer; ParaTv : TArray<TTimeval> ) : Integer;
function Accept( ParaFd : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
function Recvmsg( ParaFd : Integer; ParaP : TArray<Byte>; ParaOob : TArray<Byte>; ParaFlags : Integer; out ParaOobn : Integer; out ParaRecvflags : Integer; out ParaFrom : ISockaddr; out ParaErr : Integer ) : Integer;
function Sendmsg( ParaFd : Integer; ParaP : TArray<Byte>; ParaOob : TArray<Byte>; ParaTo : ISockaddr; ParaFlags : Integer ) : Integer;
function SendmsgN( ParaFd : Integer; ParaP : TArray<Byte>; ParaOob : TArray<Byte>; ParaTo : ISockaddr; ParaFlags : Integer; out ParaErr : Integer ) : Integer;
function Acct( ParaPath : string ) : Integer;
function Mkdev( ParaMajor, ParaMinor : uint32 ) : uint64;
function Major( ParaDev : uint64 ) : uint32;
function Minor( ParaDev : uint64 ) : uint32;
function Poll( ParaFds : TArray<TPollFd>; ParaTimeout : Integer; out ParaErr : Integer ) : Integer;
function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
function Mmap( ParaFd : Integer; ParaOffset : Int64; ParaLength : Integer; ParaProt : Integer; ParaFlags : Integer; out ParaErr : Integer ) : TArray<Byte>;
function Munmap( ParaB : TArray<Byte> ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallSolaris,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function Pipe( ParaP : TArray<Integer> ) : Integer;
var
	vPp : array[0..1] of T_C_int;
	vN : Integer;
	vErr : Integer;
begin
	if Length( ParaP ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vN := pipe( @vPp, vErr );
	if vN <> 0 then
	begin
		Result := vErr;
		Exit;
	end;
	ParaP[0] := Integer( vPp[0] );
	ParaP[1] := Integer( vPp[1] );
	Result := 0;
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

function Getsockname( ParaFd : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
var
	vRsa : TRawSockaddrAny;
	vLen : T_Socklen;
begin
	vLen := SizeofSockaddrAny;
	ParaErr := getsockname( ParaFd, @vRsa, @vLen );
	if ParaErr <> 0 then
	begin
		Result := -1;
		Exit;
	end;
	ParaSa := AnyToSockaddr( ParaFd, @vRsa, ParaErr );
	Result := 0;
end;

function Getwd( out ParaErr : Integer ) : string;
var
	vBuf : array[0..PathMax - 1] of Byte;
	vN : Integer;
begin
	vN := Getcwd( @vBuf[0], PathMax, ParaErr );
	if ParaErr <> 0 then
	begin
		Result := '';
		Exit;
	end;
	vN := Clen( vBuf );
	if vN < 1 then
	begin
		ParaErr := EINVAL;
		Result := '';
		Exit;
	end;
	Result := TEncoding.UTF8.GetString( vBuf, 0, vN );
end;

function Getgroups( out ParaErr : Integer ) : TArray<Integer>;
var
	vN : Integer;
	vA : TArray<T_Gid_t>;
	vI : Integer;
begin
	vN := getgroups( 0, nil, ParaErr );
	if ( vN < 0 ) or ( vN > 1024 ) then
	begin
		if ParaErr = 0 then ParaErr := EINVAL;
		Result := nil;
		Exit;
	end else if vN = 0 then
	begin
		Result := nil;
		Exit;
	end;

	SetLength( vA, vN );
	vN := getgroups( vN, @vA[0], ParaErr );
	if vN = -1 then
	begin
		Result := nil;
		Exit;
	end;
	SetLength( Result, vN );
	for vI := 0 to vN - 1 do
	begin
		Result[vI] := Integer( vA[vI] );
	end;
end;

function Setgroups( ParaGids : TArray<Integer> ) : Integer;
var
	vA : TArray<T_Gid_t>;
	vI : Integer;
begin
	if Length( ParaGids ) = 0 then
	begin
		Result := setgroups( 0, nil );
		Exit;
	end;
	SetLength( vA, Length( ParaGids ) );
	for vI := 0 to Length( ParaGids ) - 1 do
	begin
		vA[vI] := T_Gid_t( ParaGids[vI] );
	end;
	Result := setgroups( Length( vA ), @vA[0] );
end;

function ReadDirent( ParaFd : Integer; ParaBuf : TArray<Byte>; out ParaErr : Integer ) : Integer;
var
	vBasep : UIntPtr;
begin
	Result := Getdents( ParaFd, ParaBuf, @vBasep, ParaErr );
end;

function Wait4( ParaPid : Integer; var ParaWstatus : TWaitStatus; ParaOptions : Integer; ParaRusage : PRusage ) : Integer;
var
	vStatus : T_C_int;
	vRpid : Int32;
	vErr : Integer;
begin
	vRpid := wait4( Int32( ParaPid ), @vStatus, ParaOptions, ParaRusage, vErr );
	if vRpid = -1 then
	begin
		Result := -1;
		Exit;
	end;
	ParaWstatus.Value := UInt32( vStatus );
	Result := Integer( vRpid );
end;

function Gethostname( out ParaErr : Integer ) : string;
var
	vBuf : array[0..MaxHostNameLen - 1] of Byte;
	vN : Integer;
begin
	ParaErr := gethostname( @vBuf[0], MaxHostNameLen );
	if ParaErr <> 0 then
	begin
		Result := '';
		Exit;
	end;
	vN := Clen( vBuf );
	if vN < 1 then
	begin
		ParaErr := EFAULT;
		Result := '';
		Exit;
	end;
	Result := TEncoding.UTF8.GetString( vBuf, 0, vN );
end;

function Utimes( ParaPath : string; ParaTv : TArray<TTimeval> ) : Integer;
begin
	if Length( ParaTv ) = 0 then
	begin
		Result := utimes( ParaPath, nil );
	end else if Length( ParaTv ) <> 2 then
	begin
		Result := EINVAL;
	end else
	begin
		Result := utimes( ParaPath, @ParaTv[0] );
	end;
end;

function UtimesNano( ParaPath : string; ParaTs : TArray<TTimespec> ) : Integer;
begin
	if Length( ParaTs ) = 0 then
	begin
		Result := utimensat( AT_FDCWD, ParaPath, nil, 0 );
	end else if Length( ParaTs ) <> 2 then
	begin
		Result := EINVAL;
	end else
	begin
		Result := utimensat( AT_FDCWD, ParaPath, @ParaTs[0], 0 );
	end;
end;

function UtimesNanoAt( ParaDirfd : Integer; ParaPath : string; ParaTs : TArray<TTimespec>; ParaFlags : Integer ) : Integer;
begin
	if Length( ParaTs ) = 0 then
	begin
		Result := utimensat( ParaDirfd, ParaPath, nil, ParaFlags );
	end else if Length( ParaTs ) <> 2 then
	begin
		Result := EINVAL;
	end else
	begin
		Result := utimensat( ParaDirfd, ParaPath, @ParaTs[0], ParaFlags );
	end;
end;

function Futimesat( ParaDirfd : Integer; ParaPath : string; ParaTv : TArray<TTimeval> ) : Integer;
var
	vPathp : PByte;
	vErr : Integer;
begin
	vPathp := BytePtrFromString( ParaPath );
	if Length( ParaTv ) = 0 then
	begin
		Result := futimesat( ParaDirfd, vPathp, nil );
	end else if Length( ParaTv ) <> 2 then
	begin
		Result := EINVAL;
	end else
	begin
		Result := futimesat( ParaDirfd, vPathp, @ParaTv[0] );
	end;
end;

function Futimes( ParaFd : Integer; ParaTv : TArray<TTimeval> ) : Integer;
begin
	if Length( ParaTv ) = 0 then
	begin
		Result := futimesat( ParaFd, nil, nil );
	end else if Length( ParaTv ) <> 2 then
	begin
		Result := EINVAL;
	end else
	begin
		Result := futimesat( ParaFd, nil, @ParaTv[0] );
	end;
end;

function Accept( ParaFd : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
var
	vRsa : TRawSockaddrAny;
	vLen : T_Socklen;
	vNfd : Integer;
begin
	vLen := SizeofSockaddrAny;
	vNfd := accept( ParaFd, @vRsa, @vLen, ParaErr );
	if vNfd = -1 then
	begin
		Result := -1;
		Exit;
	end;
	ParaSa := AnyToSockaddr( ParaFd, @vRsa, ParaErr );
	Result := vNfd;
end;

function Recvmsg( ParaFd : Integer; ParaP : TArray<Byte>; ParaOob : TArray<Byte>; ParaFlags : Integer; out ParaOobn : Integer; out ParaRecvflags : Integer; out ParaFrom : ISockaddr; out ParaErr : Integer ) : Integer;
var
	vMsg : TMsghdr;
	vRsa : TRawSockaddrAny;
	vIov : TIovec;
	vDummy : Int8;
	vN : Integer;
begin
	vMsg.Name := PByte( @vRsa );
	vMsg.Namelen := uint32( SizeofSockaddrAny );
	if Length( ParaP ) > 0 then
	begin
		vIov.Base := PInt8( @ParaP[0] );
		vIov.Len := UInt64( Length( ParaP ) );
	end;
	if Length( ParaOob ) > 0 then
	begin
		if Length( ParaP ) = 0 then
		begin
			vIov.Base := @vDummy;
			vIov.Len := 1;
		end;
		vMsg.Accrightslen := Int32( Length( ParaOob ) );
	end;
	vMsg.Iov := @vIov;
	vMsg.Iovlen := 1;
	vN := recvmsg( ParaFd, @vMsg, ParaFlags, ParaErr );
	if vN = -1 then
	begin
		Result := -1;
		Exit;
	end;
	ParaOobn := Integer( vMsg.Accrightslen );
	if vRsa.Addr.Family <> AF_UNSPEC then
	begin
		ParaFrom := AnyToSockaddr( ParaFd, @vRsa, ParaErr );
	end;
	Result := vN;
end;

function Sendmsg( ParaFd : Integer; ParaP : TArray<Byte>; ParaOob : TArray<Byte>; ParaTo : ISockaddr; ParaFlags : Integer ) : Integer;
var
	vErr : Integer;
begin
	Result := SendmsgN( ParaFd, ParaP, ParaOob, ParaTo, ParaFlags, vErr );
end;

function SendmsgN( ParaFd : Integer; ParaP : TArray<Byte>; ParaOob : TArray<Byte>; ParaTo : ISockaddr; ParaFlags : Integer; out ParaErr : Integer ) : Integer;
var
	vPtr : Pointer;
	vSalen : T_Socklen;
	vMsg : TMsghdr;
	vIov : TIovec;
	vDummy : Int8;
begin
	if ParaTo <> nil then
	begin
		ParaTo.Sockaddr( vPtr, vSalen );
	end;
	vMsg.Name := PByte( vPtr );
	vMsg.Namelen := uint32( vSalen );
	if Length( ParaP ) > 0 then
	begin
		vIov.Base := PInt8( @ParaP[0] );
		vIov.Len := UInt64( Length( ParaP ) );
	end;
	if Length( ParaOob ) > 0 then
	begin
		if Length( ParaP ) = 0 then
		begin
			vIov.Base := @vDummy;
			vIov.Len := 1;
		end;
		vMsg.Accrightslen := Int32( Length( ParaOob ) );
	end;
	vMsg.Iov := @vIov;
	vMsg.Iovlen := 1;
	Result := sendmsg( ParaFd, @vMsg, ParaFlags, ParaErr );
end;

function Acct( ParaPath : string ) : Integer;
var
	vPathp : PByte;
	vErr : Integer;
begin
	if ParaPath = '' then
	begin
		Result := acct( nil );
	end else
	begin
		vPathp := BytePtrFromString( ParaPath );
		Result := acct( vPathp );
	end;
end;

function Mkdev( ParaMajor, ParaMinor : uint32 ) : uint64;
begin
	Result := __makedev( NEWDEV, uint( ParaMajor ), uint( ParaMinor ) );
end;

function Major( ParaDev : uint64 ) : uint32;
begin
	Result := uint32( __major( NEWDEV, ParaDev ) );
end;

function Minor( ParaDev : uint64 ) : uint32;
begin
	Result := uint32( __minor( NEWDEV, ParaDev ) );
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

function Sendfile( ParaOutfd : Integer; ParaInfd : Integer; var ParaOffset : Int64; ParaCount : Integer; out ParaErr : Integer ) : Integer;
begin
	Result := sendfile( ParaOutfd, ParaInfd, @ParaOffset, ParaCount, ParaErr );
end;

var
	mMapper : Tmmapper;

function Mmap( ParaFd : Integer; ParaOffset : Int64; ParaLength : Integer; ParaProt : Integer; ParaFlags : Integer; out ParaErr : Integer ) : TArray<Byte>;
begin
	Result := mMapper.Mmap( ParaFd, ParaOffset, ParaLength, ParaProt, ParaFlags, ParaErr );
end;

function Munmap( ParaB : TArray<Byte> ) : Integer;
begin
	Result := mMapper.Munmap( ParaB );
end;

end.
