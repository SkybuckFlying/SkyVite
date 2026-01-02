unit Vendor.Golang.Org.X.Sys.Unix.ReaddirentGetdirentries;

interface

uses
  System.SysUtils;

function ReadDirent(FD: Integer; var Buf: TBytes): TTuple<Integer, Exception>;

implementation

function ReadDirent(FD: Integer; var Buf: TBytes): TTuple<Integer, Exception>;
begin
  // Result := Getdirentries(FD, Buf, Base);
  Result := Default(TTuple<Integer, Exception>);
end;

end.
