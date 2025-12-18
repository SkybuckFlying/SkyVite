unit Vendor.Github.Com.Golang.Protobuf.Proto.Registry;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.Golang.Protobuf.Proto.Proto;

procedure RegisterMessage( ParaName : string; ParaM : IMessage );
function LookupMessage( ParaName : string ) : IMessage;

implementation

procedure RegisterMessage( ParaName : string; ParaM : IMessage );
begin
end;

function LookupMessage( ParaName : string ) : IMessage;
begin
	Result := nil;
end;

end.
