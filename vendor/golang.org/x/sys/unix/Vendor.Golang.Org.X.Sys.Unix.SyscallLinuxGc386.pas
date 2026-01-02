{$MODE DELPHIUNICODE}
unit Vendor.Golang.Org.X.Sys.Unix.SyscallLinuxGc386;

interface

uses
	System.SysUtils;

function seek( ParaFd : Integer; ParaOffset : Int64; ParaWhence : Integer; out ParaErr : Integer ) : Int64;
function socketcall( ParaCall : Integer; ParaA0, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5 : UIntPtr; out ParaErr : Integer ) : Integer;
function rawsocketcall( ParaCall : Integer; ParaA0, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5 : UIntPtr; out ParaErr : Integer ) : Integer;

implementation

function seek( ParaFd : Integer; ParaOffset : Int64; ParaWhence : Integer; out ParaErr : Integer ) : Int64;
begin
	Result := 0;
	ParaErr := 0;
end;

function socketcall( ParaCall : Integer; ParaA0, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5 : UIntPtr; out ParaErr : Integer ) : Integer;
begin
	Result := 0;
	ParaErr := 0;
end;

function rawsocketcall( ParaCall : Integer; ParaA0, ParaA1, ParaA2, ParaA3, ParaA4, ParaA5 : UIntPtr; out ParaErr : Integer ) : Integer;
begin
	Result := 0;
	ParaErr := 0;
end;

end.
