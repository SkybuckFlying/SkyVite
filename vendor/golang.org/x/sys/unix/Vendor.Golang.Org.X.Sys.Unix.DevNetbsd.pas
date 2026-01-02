unit Vendor.Golang.Org.X.Sys.Unix.DevNetbsd;

interface

function Major(Dev: UInt64): UInt32;
function Minor(Dev: UInt64): UInt32;
function Mkdev(AMajor, AMinor: UInt32): UInt64;

implementation

function Major(Dev: UInt64): UInt32;
begin
  Result := UInt32((Dev and $000FFF00) shr 8);
end;

function Minor(Dev: UInt64): UInt32;
begin
  Result := UInt32(Dev and $000000FF);
  Result := Result or UInt32((Dev and $FFF00000) shr 12);
end;

function Mkdev(AMajor, AMinor: UInt32): UInt64;
begin
  Result := (UInt64(AMajor) shl 8) and $000FFF00;
  Result := Result or ((UInt64(AMinor) shl 12) and $FFF00000);
  Result := Result or (UInt64(AMinor) and $000000FF);
end;

end.
