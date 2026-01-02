unit Vendor.Golang.Org.X.Sys.Unix.DevLinux;

interface

function Major(Dev: UInt64): UInt32;
function Minor(Dev: UInt64): UInt32;
function Mkdev(AMajor, AMinor: UInt32): UInt64;

implementation

function Major(Dev: UInt64): UInt32;
begin
  Result := UInt32((Dev and $00000000000FFF00) shr 8);
  Result := Result or UInt32((Dev and $FFFFF00000000000) shr 32);
end;

function Minor(Dev: UInt64): UInt32;
begin
  Result := UInt32(Dev and $00000000000000FF);
  Result := Result or UInt32((Dev and $00000FFFFFF00000) shr 12);
end;

function Mkdev(AMajor, AMinor: UInt32): UInt64;
begin
  Result := (UInt64(AMajor) and $00000FFF) shl 8;
  Result := Result or ((UInt64(AMajor) and $FFFFF000) shl 32);
  Result := Result or (UInt64(AMinor) and $000000FF);
  Result := Result or ((UInt64(AMinor) and $FFFFFF00) shl 12);
end;

end.
