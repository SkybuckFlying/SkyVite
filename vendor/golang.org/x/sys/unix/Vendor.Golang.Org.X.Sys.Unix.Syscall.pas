unit Vendor.Golang.Org.X.Sys.Unix.Syscall;

interface

uses
  System.SysUtils;

function ByteSliceFromString(const S: string): TTuple<TBytes, Exception>;
function BytePtrFromString(const S: string): TTuple<PByte, Exception>;
function ByteSliceToString(const S: TBytes): string;
function BytePtrToString(P: PByte): string;

implementation

function ByteSliceFromString(const S: string): TTuple<TBytes, Exception>;
begin
  Result := TTuple<TBytes, Exception>.Create(TEncoding.UTF8.GetBytes(S + #0), nil);
end;

function BytePtrFromString(const S: string): TTuple<PByte, Exception>;
var
  B: TBytes;
begin
  B := TEncoding.UTF8.GetBytes(S + #0);
  Result := TTuple<PByte, Exception>.Create(@B[0], nil);
end;

function ByteSliceToString(const S: TBytes): string;
begin
  Result := TEncoding.UTF8.GetString(S).TrimRight([#0]);
end;

function BytePtrToString(P: PByte): string;
begin
  Result := PChar(P);
end;

end.
