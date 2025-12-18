unit Vendor.Github.Com.Golang.Protobuf.Proto.Wire;

interface

uses
	System.Classes,
	System.SysUtils,
	Vendor.Github.Com.Golang.Protobuf.Proto.Proto;

function Size( ParaM : IMessage ) : Integer;
function Marshal( ParaM : IMessage ) : TBytes;
function Unmarshal( ParaB : TBytes; ParaM : IMessage ) : HRESULT;

implementation

function Size( ParaM : IMessage ) : Integer;
begin
	Result := 0;
end;

function Marshal( ParaM : IMessage ) : TBytes;
begin
	SetLength( Result, 0 );
end;

function Unmarshal( ParaB : TBytes; ParaM : IMessage ) : HRESULT;
begin
	Result := 0;
end;

end.
