{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallDarwin;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesDarwin;

type
	TSockaddrDatalink = class(TInterfacedObject, ISockaddr)
	public
		Len    : uint8;
		Family : uint8;
		Index  : uint16;
		_Type  : uint8;
		Nlen   : uint8;
		Alen   : uint8;
		Slen   : uint8;
		Data   : array[0..11] of Int8;
		Raw    : TRawSockaddrDatalink;
		function Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
	end;

	TSockaddrCtl = class(TInterfacedObject, ISockaddr)
	public
		ID   : uint32;
		Unit : uint32;
		Raw  : TRawSockaddrCtl;
		function Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
	end;

function Nametomib( ParaName : string; out ParaErr : Integer ) : TArray<T_C_int>;
function PtraceAttach( ParaPid : Integer ) : Integer;
function PtraceDetach( ParaPid : Integer ) : Integer;
function Pipe( ParaP : TArray<Integer> ) : Integer;
function Getfsstat( ParaBuf : TArray<TStatfs_t>; ParaFlags : Integer; out ParaErr : Integer ) : Integer;
function Getxattr( ParaPath : string; ParaAttr : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Lgetxattr( ParaLink : string; ParaAttr : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Fgetxattr( ParaFd : Integer; ParaAttr : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Setxattr( ParaPath : string; ParaAttr : string; ParaData : TArray<Byte>; ParaFlags : Integer ) : Integer;
function Lsetxattr( ParaLink : string; ParaAttr : string; ParaData : TArray<Byte>; ParaFlags : Integer ) : Integer;
function Fsetxattr( ParaFd : Integer; ParaAttr : string; ParaData : TArray<Byte>; ParaFlags : Integer ) : Integer;
function Removexattr( ParaPath : string; ParaAttr : string ) : Integer;
function Lremovexattr( ParaLink : string; ParaAttr : string ) : Integer;
function Fremovexattr( ParaFd : Integer; ParaAttr : string ) : Integer;
function Listxattr( ParaPath : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Llistxattr( ParaLink : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Flistxattr( ParaFd : Integer; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallDarwin,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

function TSockaddrCtl.Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
begin
	Raw.Sc_len := SizeofSockaddrCtl;
	Raw.Sc_family := AF_SYSTEM;
	Raw.Ss_sysaddr := AF_SYS_CONTROL;
	Raw.Sc_id := ID;
	Raw.Sc_unit := Unit;
	ParaPtr := @Raw;
	ParaLen := SizeofSockaddrCtl;
	Result := 0;
end;

function TSockaddrDatalink.Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
begin
	// Implementation for Datalink...
	ParaPtr := @Raw;
	ParaLen := SizeofSockaddrDatalink;
	Result := 0;
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

function PtraceAttach( ParaPid : Integer ) : Integer;
begin
	Result := ptrace( PT_ATTACH, ParaPid, 0, 0 );
end;

function PtraceDetach( ParaPid : Integer ) : Integer;
begin
	Result := ptrace( PT_DETACH, ParaPid, 0, 0 );
end;

function Pipe( ParaP : TArray<Integer> ) : Integer;
var
	vX : array[0..1] of Int32;
	vErr : Integer;
begin
	if Length( ParaP ) <> 2 then
	begin
		Result := EINVAL;
		Exit;
	end;
	vErr := pipe( @vX );
	if vErr = 0 then
	begin
		ParaP[0] := Integer( vX[0] );
		ParaP[1] := Integer( vX[1] );
	end;
	Result := vErr;
end;

function Getfsstat( ParaBuf : TArray<TStatfs_t>; ParaFlags : Integer; out ParaErr : Integer ) : Integer;
var
	vP0 : Pointer;
	vBufsize : UIntPtr;
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
	Result := getfsstat( vP0, vBufsize, ParaFlags, ParaErr );
end;

function XattrPointer( ParaDest : TArray<Byte> ) : PByte;
begin
	if Length( ParaDest ) > 0 then
	begin
		Result := @ParaDest[0];
	begin else
	begin
		Result := nil;
	end;
end;

function Getxattr( ParaPath : string; ParaAttr : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
begin
	Result := getxattr( ParaPath, ParaAttr, XattrPointer( ParaDest ), Length( ParaDest ), 0, 0, ParaErr );
end;

// ... other xattr functions ...

end.
