{$MODE DELPHIUNICODE}
unit Vendor.Github.Com.Golang.Snappy.EncodeAsm;

interface

function emitLiteral( ParaDst, ParaLit : TArray<Byte> ) : Integer;
function emitCopy( ParaDst : TArray<Byte>; ParaOffset, ParaLength : Integer ) : Integer;
function extendMatch( ParaSrc : TArray<Byte>; ParaI, ParaJ : Integer ) : Integer;
function encodeBlock( ParaDst, ParaSrc : TArray<Byte> ) : Integer;

implementation

function emitLiteral( ParaDst, ParaLit : TArray<Byte> ) : Integer;
begin
	Result := 0;
end;

function emitCopy( ParaDst : TArray<Byte>; ParaOffset, ParaLength : Integer ) : Integer;
begin
	Result := 0;
end;

function extendMatch( ParaSrc : TArray<Byte>; ParaI, ParaJ : Integer ) : Integer;
begin
	Result := 0;
end;

function encodeBlock( ParaDst, ParaSrc : TArray<Byte> ) : Integer;
begin
	Result := 0;
end;

end.
