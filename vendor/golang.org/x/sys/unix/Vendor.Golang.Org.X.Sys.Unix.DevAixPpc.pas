unit Vendor.Golang.Org.X.Sys.Unix.DevAixPpc;

interface

function Major(Dev: UInt64): UInt32;
function Minor(Dev: UInt64): UInt32;
function Mkdev(AMajor, AMinor: UInt32): UInt64;

implementation

function Major(Dev: UInt64): UInt32;
begin
  Result := UInt32((Dev shr 16) and $FFFF);
end;

function Minor(Dev: UInt64): UInt32;
begin
  Result := UInt32(Dev and $FFFF);
end;

function Mkdev(AMajor, AMinor: UInt32): UInt64;
begin
  Result := UInt64((UInt64(AMajor) shl 16) or AMinor);
end;

end.
