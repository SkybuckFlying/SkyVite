{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

interface

uses
	System.SysUtils,
	System.SyncObjs,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesUnix;

type
	ISockaddr = interface
		['{A7B8C9D0-E1F2-43B4-A5B6-C7D8E9F0A1B2}']
		function Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
	end;

	TSockaddrInet4 = class(TInterfacedObject, ISockaddr)
	public
		Port : Integer;
		Addr : array[0..3] of Byte;
		Raw  : TRawSockaddrInet4;
		function Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
	end;

	TSockaddrInet6 = class(TInterfacedObject, ISockaddr)
	public
		Port   : Integer;
		ZoneId : uint32;
		Addr   : array[0..15] of Byte;
		Raw    : TRawSockaddrInet6;
		function Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
	end;

	TSockaddrUnix = class(TInterfacedObject, ISockaddr)
	public
		Name : string;
		Raw  : TRawSockaddrUnix;
		function Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
	end;

	Tmmapper = class
	private
		mLock : TCriticalSection;
		// mActive : TDictionary<Pointer, TArray<Byte>>; // Would need Generics.Collections
	public
		constructor Create;
		destructor Destroy; override;
		function Mmap( ParaFd : Integer; ParaOffset : Int64; ParaLength : Integer; ParaProt : Integer; ParaFlags : Integer; out ParaErr : Integer ) : TArray<Byte>;
		function Munmap( ParaData : TArray<Byte> ) : Integer;
	end;

function Clen( ParaN : TArray<Byte> ) : Integer;
function Read( ParaFd : Integer; ParaP : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Write( ParaFd : Integer; ParaP : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Bind( ParaFd : Integer; ParaSa : ISockaddr ) : Integer;
function Connect( ParaFd : Integer; ParaSa : ISockaddr ) : Integer;
function Getpeername( ParaFd : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
function Recvfrom( ParaFd : Integer; ParaP : TArray<Byte>; ParaFlags : Integer; out ParaFrom : ISockaddr; out ParaErr : Integer ) : Integer;
function Sendto( ParaFd : Integer; ParaP : TArray<Byte>; ParaFlags : Integer; ParaTo : ISockaddr ) : Integer;
function Socket( ParaDomain, ParaTyp, ParaProto : Integer; out ParaFd : Integer ) : Integer;
function CloseOnExec( ParaFd : Integer ) : Integer;
function SetNonblock( ParaFd : Integer; ParaNonblocking : Boolean ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallUnix;

function Clen( ParaN : TArray<Byte> ) : Integer;
var
	vI : Integer;
begin
	for vI := 0 to Length( ParaN ) - 1 do
	begin
		if ParaN[vI] = 0 then
		begin
			Result := vI;
			Exit;
		end;
	end;
	Result := Length( ParaN );
end;

function TSockaddrInet4.Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
begin
	if ( Port < 0 ) or ( Port > $FFFF ) then
	begin
		Result := EINVAL;
		Exit;
	end;
	Raw.Family := AF_INET;
	Raw.Port := uint16( ( ( Port and $FF ) shl 8 ) or ( ( Port shr 8 ) and $FF ) );
	Move( Addr[0], Raw.Addr[0], 4 );
	ParaPtr := @Raw;
	ParaLen := SizeofSockaddrInet4;
	Result := 0;
end;

function TSockaddrInet6.Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
begin
	if ( Port < 0 ) or ( Port > $FFFF ) then
	begin
		Result := EINVAL;
		Exit;
	end;
	Raw.Family := AF_INET6;
	Raw.Port := uint16( ( ( Port and $FF ) shl 8 ) or ( ( Port shr 8 ) and $FF ) );
	Raw.Scope_id := ZoneId;
	Move( Addr[0], Raw.Addr[0], 16 );
	ParaPtr := @Raw;
	ParaLen := SizeofSockaddrInet6;
	Result := 0;
end;

function TSockaddrUnix.Sockaddr( out ParaPtr : Pointer; out ParaLen : _Socklen ) : Integer;
var
	vN : Integer;
	vI : Integer;
	vSl : _Socklen;
begin
	vN := Length( Name );
	if vN >= Length( Raw.Path ) then
	begin
		Result := EINVAL;
		Exit;
	end;
	Raw.Family := AF_UNIX;
	for vI := 0 to vN - 1 do
	begin
		Raw.Path[vI] := int8( Ord( Name[vI + 1] ) );
	end;
	vSl := 2;
	if vN > 0 then
	begin
		vSl := vSl + _Socklen( vN ) + 1;
	end;
	if ( vN > 0 ) and ( Name[1] = '@' ) then
	begin
		Raw.Path[0] := 0;
		vSl := vSl - 1;
	end;
	ParaPtr := @Raw;
	ParaLen := vSl;
	Result := 0;
end;

constructor Tmmapper.Create;
begin
	mLock := TCriticalSection.Create;
end;

destructor Tmmapper.Destroy;
begin
	mLock.Free;
	inherited;
end;

function Tmmapper.Mmap( ParaFd : Integer; ParaOffset : Int64; ParaLength : Integer; ParaProt : Integer; ParaFlags : Integer; out ParaErr : Integer ) : TArray<Byte>;
begin
	// Implementation would call OS specific mmap
	Result := nil;
end;

function Tmmapper.Munmap( ParaData : TArray<Byte> ) : Integer;
begin
	Result := 0;
end;

function Read( ParaFd : Integer; ParaP : TArray<Byte>; out ParaErr : Integer ) : Integer;
begin
	Result := read( ParaFd, ParaP, ParaErr );
end;

function Write( ParaFd : Integer; ParaP : TArray<Byte>; out ParaErr : Integer ) : Integer;
begin
	Result := write( ParaFd, ParaP, ParaErr );
end;

function Bind( ParaFd : Integer; ParaSa : ISockaddr ) : Integer;
var
	vPtr : Pointer;
	vLen : _Socklen;
	vErr : Integer;
begin
	vErr := ParaSa.Sockaddr( vPtr, vLen );
	if vErr <> 0 then
	begin
		Result := vErr;
		Exit;
	end;
	Result := bind( ParaFd, vPtr, vLen );
end;

function Connect( ParaFd : Integer; ParaSa : ISockaddr ) : Integer;
var
	vPtr : Pointer;
	vLen : _Socklen;
	vErr : Integer;
begin
	vErr := ParaSa.Sockaddr( vPtr, vLen );
	if vErr <> 0 then
	begin
		Result := vErr;
		Exit;
	end;
	Result := connect( ParaFd, vPtr, vLen );
end;

function Getpeername( ParaFd : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
var
	vRsa : TRawSockaddrAny;
	vLen : T_Socklen;
begin
	vLen := SizeofSockaddrAny;
	ParaErr := getpeername( ParaFd, @vRsa, @vLen );
	if ParaErr <> 0 then
	begin
		Result := -1;
		Exit;
	end;
	ParaSa := AnyToSockaddr( ParaFd, @vRsa, ParaErr );
	Result := 0;
end;

function Recvfrom( ParaFd : Integer; ParaP : TArray<Byte>; ParaFlags : Integer; out ParaFrom : ISockaddr; out ParaErr : Integer ) : Integer;
var
	vRsa : TRawSockaddrAny;
	vLen : T_Socklen;
	vN : Integer;
begin
	vLen := SizeofSockaddrAny;
	vN := recvfrom( ParaFd, ParaP, ParaFlags, @vRsa, @vLen, ParaErr );
	if ParaErr <> 0 then
	begin
		Result := -1;
		Exit;
	end;
	if vRsa.Addr.Family <> AF_UNSPEC then
	begin
		ParaFrom := AnyToSockaddr( ParaFd, @vRsa, ParaErr );
	end;
	Result := vN;
end;

function Sendto( ParaFd : Integer; ParaP : TArray<Byte>; ParaFlags : Integer; ParaTo : ISockaddr ) : Integer;
var
	vPtr : Pointer;
	vLen : _Socklen;
	vErr : Integer;
begin
	vErr := ParaTo.Sockaddr( vPtr, vLen );
	if vErr <> 0 then
	begin
		Result := vErr;
		Exit;
	end;
	Result := sendto( ParaFd, ParaP, ParaFlags, vPtr, vLen );
end;

function Socket( ParaDomain, ParaTyp, ParaProto : Integer; out ParaFd : Integer ) : Integer;
begin
	ParaFd := socket( ParaDomain, ParaTyp, ParaProto, Result );
end;

function CloseOnExec( ParaFd : Integer ) : Integer;
begin
	Result := fcntl( ParaFd, F_SETFD, FD_CLOEXEC );
end;

function SetNonblock( ParaFd : Integer; ParaNonblocking : Boolean ) : Integer;
var
	vFlag : Integer;
	vErr : Integer;
begin
	vFlag := fcntl( ParaFd, F_GETFL, 0 );
	if vFlag = -1 then
	begin
		Result := -1; // Should get actual errno
		Exit;
	end;
	if ParaNonblocking then
	begin
		vFlag := vFlag or O_NONBLOCK;
	end else
	begin
		vFlag := vFlag and (not O_NONBLOCK);
	end;
	Result := fcntl( ParaFd, F_SETFL, vFlag );
end;

end.
