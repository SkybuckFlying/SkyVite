{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.XattrBsd;

interface

uses
	System.SysUtils,
	Vendor.Golang.Org.X.Sys.Unix.ZtypesUnix;

function Getxattr( ParaFile : string; ParaAttr : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Fgetxattr( ParaFd : Integer; ParaAttr : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Lgetxattr( ParaLink : string; ParaAttr : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Fsetxattr( ParaFd : Integer; ParaAttr : string; ParaData : TArray<Byte>; ParaFlags : Integer ) : Integer;
function Setxattr( ParaFile : string; ParaAttr : string; ParaData : TArray<Byte>; ParaFlags : Integer ) : Integer;
function Lsetxattr( ParaLink : string; ParaAttr : string; ParaData : TArray<Byte>; ParaFlags : Integer ) : Integer;
function Removexattr( ParaFile : string; ParaAttr : string ) : Integer;
function Fremovexattr( ParaFd : Integer; ParaAttr : string ) : Integer;
function Lremovexattr( ParaLink : string; ParaAttr : string ) : Integer;
function Listxattr( ParaFile : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Flistxattr( ParaFd : Integer; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
function Llistxattr( ParaLink : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;

implementation

uses
	Vendor.Golang.Org.X.Sys.Unix.SyscallUnix; // Would need Extattr functions

function Xattrnamespace( ParaFullattr : string; out ParaNs : Integer; out ParaAttr : string ) : Integer;
var
	vS : Integer;
	vNamespace : string;
begin
	vS := Pos( '.', ParaFullattr );
	if vS = 0 then
	begin
		Result := ENOATTR;
		Exit;
	end;

	vNamespace := Copy( ParaFullattr, 1, vS - 1 );
	ParaAttr := Copy( ParaFullattr, vS + 1, Length( ParaFullattr ) - vS );

	if vNamespace = 'user' then
	begin
		ParaNs := EXTATTR_NAMESPACE_USER;
		Result := 0;
	end else if vNamespace = 'system' then
	begin
		ParaNs := EXTATTR_NAMESPACE_SYSTEM;
		Result := 0;
	end else
	begin
		Result := ENOATTR;
	end;
end;

function Getxattr( ParaFile : string; ParaAttr : string; ParaDest : TArray<Byte>; out ParaErr : Integer ) : Integer;
var
	vNs : Integer;
	vA : string;
	vD : Pointer;
begin
	if Length( ParaDest ) > 0 then vD := @ParaDest[0] else vD := nil;
	ParaErr := Xattrnamespace( ParaAttr, vNs, vA );
	if ParaErr <> 0 then
	begin
		Result := -1;
		Exit;
	end;
	// Result := ExtattrGetFile( ParaFile, vNs, vA, UIntPtr( vD ), Length( ParaDest ), ParaErr );
	Result := 0; // Placeholder
end;

// ... other functions ...

end.
