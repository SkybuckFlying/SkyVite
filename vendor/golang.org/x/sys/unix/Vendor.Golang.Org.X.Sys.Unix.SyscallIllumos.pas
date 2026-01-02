{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallIllumos;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesIllumos;

function Readv( ParaFd : Integer; ParaIovs : TArray<TArray<Byte>>; out ParaErr : Integer ) : Integer;
function Preadv( ParaFd : Integer; ParaIovs : TArray<TArray<Byte>>; ParaOff : Int64; out ParaErr : Integer ) : Integer;
function Writev( ParaFd : Integer; ParaIovs : TArray<TArray<Byte>>; out ParaErr : Integer ) : Integer;
function Pwritev( ParaFd : Integer; ParaIovs : TArray<TArray<Byte>>; ParaOff : Int64; out ParaErr : Integer ) : Integer;
function Accept4( ParaFd : Integer; ParaFlags : Integer; out ParaSa : ISockaddr; out ParaErr : Integer ) : Integer;
function Putmsg( ParaFd : Integer; ParaCl : TArray<Byte>; ParaData : TArray<Byte>; ParaFlags : Integer ) : Integer;
function Getmsg( ParaFd : Integer; ParaCl : TArray<Byte>; ParaData : TArray<Byte>; out ParaRetCl : TArray<Byte>; out ParaRetData : TArray<Byte>; out ParaFlags : Integer; out ParaErr : Integer ) : Integer;
function IoctlSetIntRetInt( ParaFd : Integer; ParaReq : UInt; ParaArg : Integer; out ParaErr : Integer ) : Integer;
function IoctlSetString( ParaFd : Integer; ParaReq : UInt; ParaVal : string ) : Integer;
function IoctlLifreq( ParaFd : Integer; ParaReq : UInt; ParaL : PZLifreq ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.ZsyscallIllumos,
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix;

type
	TIovecHelper = record helper for TIovec
		procedure SetLen( ParaLength : Integer );
	end;

procedure TIovecHelper.SetLen( ParaLength : Integer );
begin
	Self.Len := UInt64( ParaLength );
end;

function Bytes2iovec( ParaBs : TArray<TArray<Byte>> ) : TArray<TIovec>;
var
	vI : Integer;
begin
	SetLength( Result, Length( ParaBs ) );
	for vI := 0 to Length( ParaBs ) - 1 do
	begin
		Result[vI].SetLen( Length( ParaBs[vI] ) );
		if Length( ParaBs[vI] ) > 0 then
		begin
			Result[vI].Base := PInt8( @ParaBs[vI][0] );
		end else
		begin
			Result[vI].Base := nil;
		end;
	end;
end;

function Readv( ParaFd : Integer; ParaIovs : TArray<TArray<Byte>>; out ParaErr : Integer ) : Integer;
var
	vIovecs : TArray<TIovec>;
begin
	vIovecs := Bytes2iovec( ParaIovs );
	Result := readv( ParaFd, vIovecs, ParaErr );
end;

function Preadv( ParaFd : Integer; ParaIovs : TArray<TArray<Byte>>; ParaOff : Int64; out ParaErr : Integer ) : Integer;
var
	vIovecs : TArray<TIovec>;
begin
	vIovecs := Bytes2iovec( ParaIovs );
	Result := preadv( ParaFd, vIovecs, ParaOff, ParaErr );
end;

function Writev( ParaFd : Integer; ParaIovs : TArray<TArray<Byte>>; out ParaErr : Integer ) : Integer;
var
	vIovecs : TArray<TIovec>;
begin
	vIovecs := Bytes2iovec( ParaIovs );
	Result := writev( ParaFd, vIovecs, ParaErr );
end;

function Pwritev( ParaFd : Integer; ParaIovs : TArray<TArray<Byte>>; ParaOff : Int64; out ParaErr : Integer ) : Integer;
var
	vIovecs : TArray<TIovec>;
begin
	vIovecs := Bytes2iovec( ParaIovs );
	Result := pwritev( ParaFd, vIovecs, ParaOff, ParaErr );
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

function Putmsg( ParaFd : Integer; ParaCl : TArray<Byte>; ParaData : TArray<Byte>; ParaFlags : Integer ) : Integer;
var
	vClp, vDatap : T_strbuf;
	vPClp, vPDatap : PZ_strbuf;
begin
	vPClp := nil;
	vPDatap := nil;
	if Length( ParaCl ) > 0 then
	begin
		vClp.Len := Int32( Length( ParaCl ) );
		vClp.Buf := PInt8( @ParaCl[0] );
		vPClp := @vClp;
	end;
	if Length( ParaData ) > 0 then
	begin
		vDatap.Len := Int32( Length( ParaData ) );
		vDatap.Buf := PInt8( @ParaData[0] );
		vPDatap := @vDatap;
	end;
	Result := putmsg( ParaFd, vPClp, vPDatap, ParaFlags );
end;

function Getmsg( ParaFd : Integer; ParaCl : TArray<Byte>; ParaData : TArray<Byte>; out ParaRetCl : TArray<Byte>; out ParaRetData : TArray<Byte>; out ParaFlags : Integer; out ParaErr : Integer ) : Integer;
var
	vClp, vDatap : T_strbuf;
	vPClp, vPDatap : PZ_strbuf;
begin
	vPClp := nil;
	vPDatap := nil;
	if Length( ParaCl ) > 0 then
	begin
		vClp.Maxlen := Int32( Length( ParaCl ) );
		vClp.Buf := PInt8( @ParaCl[0] );
		vPClp := @vClp;
	end;
	if Length( ParaData ) > 0 then
	begin
		vDatap.Maxlen := Int32( Length( ParaData ) );
		vDatap.Buf := PInt8( @ParaData[0] );
		vPDatap := @vDatap;
	end;

	Result := getmsg( ParaFd, vPClp, vPDatap, @ParaFlags, ParaErr );
	if ParaErr <> 0 then
	begin
		ParaRetCl := nil;
		ParaRetData := nil;
		Exit;
	end;

	if Length( ParaCl ) > 0 then
	begin
		ParaRetCl := Copy( ParaCl, 0, vClp.Len );
	end;
	if Length( ParaData ) > 0 then
	begin
		ParaRetData := Copy( ParaData, 0, vDatap.Len );
	end;
end;

function IoctlSetIntRetInt( ParaFd : Integer; ParaReq : UInt; ParaArg : Integer; out ParaErr : Integer ) : Integer;
begin
	Result := ioctlRet( ParaFd, ParaReq, UIntPtr( ParaArg ), ParaErr );
end;

function IoctlSetString( ParaFd : Integer; ParaReq : UInt; ParaVal : string ) : Integer;
var
	vBs : TArray<Byte>;
	vErr : Integer;
begin
	vBs := TEncoding.UTF8.GetBytes( ParaVal + #0 );
	Result := ioctl( ParaFd, ParaReq, UIntPtr( @vBs[0] ), vErr );
end;

function IoctlLifreq( ParaFd : Integer; ParaReq : UInt; ParaL : PZLifreq ) : Integer;
var
	vErr : Integer;
begin
	Result := ioctl( ParaFd, ParaReq, UIntPtr( ParaL ), vErr );
end;

end.
