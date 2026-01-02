unit Vendor.Golang.Org.X.Sys.Unix.Str;

interface

uses
  System.SysUtils;

function Itoa(Val: Integer): string;
function Uitoa(Val: UInt): string;

implementation

function Itoa(Val: Integer): string;
begin
  Result := IntToStr(Val);
end;

function Uitoa(Val: UInt): string;
begin
  Result := UIntToStr(Val);
end;

end.
