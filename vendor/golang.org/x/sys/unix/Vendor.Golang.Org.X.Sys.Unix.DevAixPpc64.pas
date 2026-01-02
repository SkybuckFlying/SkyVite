unit Vendor.Golang.Org.X.Sys.Unix.DevAixPpc64;

interface

function Major(Dev: UInt64): UInt32;
function Minor(Dev: UInt64): UInt32;
function Mkdev(AMajor, AMinor: UInt32): UInt64;

implementation

function Major(Dev: UInt64): UInt32;
begin
  Result := UInt32((Dev and $3FFFFFFF00000000) shr 32);
end;

function Minor(Dev: UInt64): UInt32;
begin
  Result := UInt32(Dev and $00000000FFFFFFFF);
end;

function Mkdev(AMajor, AMinor: UInt32): UInt64;
var
  DEVNO64: UInt64;
begin
  DEVNO64 := $8000000000000000;
  Result := (UInt64(AMajor) shl 32) or (UInt64(AMinor) and $00000000FFFFFFFF) or DEVNO64;
end;

end.
