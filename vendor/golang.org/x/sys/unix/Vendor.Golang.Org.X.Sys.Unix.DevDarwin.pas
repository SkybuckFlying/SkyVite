unit Vendor.Golang.Org.X.Sys.Unix.DevDarwin;

interface

function Major(Dev: UInt64): UInt32;
function Minor(Dev: UInt64): UInt32;
function Mkdev(AMajor, AMinor: UInt32): UInt64;

implementation

function Major(Dev: UInt64): UInt32;
begin
  Result := UInt32((Dev shr 24) and $FF);
end;

function Minor(Dev: UInt64): UInt32;
begin
  Result := UInt32(Dev and $FFFFFF);
end;

function Mkdev(AMajor, AMinor: UInt32): UInt64;
begin
  Result := (UInt64(AMajor) shl 24) or UInt64(AMinor);
end;

end.
