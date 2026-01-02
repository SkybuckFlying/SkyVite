unit Vendor.Golang.Org.X.Sys.Unix.ReaddirentGetdents;

interface

uses
  System.SysUtils;

function ReadDirent(FD: Integer; var Buf: TBytes): TTuple<Integer, Exception>;

implementation

function ReadDirent(FD: Integer; var Buf: TBytes): TTuple<Integer, Exception>;
begin
  // Result := Getdents(FD, Buf);
  Result := Default(TTuple<Integer, Exception>);
end;

end.
