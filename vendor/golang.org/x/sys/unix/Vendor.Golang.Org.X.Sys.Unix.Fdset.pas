unit Vendor.Golang.Org.X.Sys.Unix.Fdset;

interface

uses
  System.SysUtils;

const
  NFDBITS = 64; // Simplified

type
  TFdSet = record
    Bits: array[0..15] of UIntPtr; // Simplified
    procedure Set_(FD: Integer);
    procedure Clear(FD: Integer);
    function IsSet(FD: Integer): Boolean;
    procedure Zero;
  end;

implementation

procedure TFdSet.Set_(FD: Integer);
begin
  Bits[FD div NFDBITS] := Bits[FD div NFDBITS] or (UIntPtr(1) shl (UIntPtr(FD) mod NFDBITS));
end;

procedure TFdSet.Clear(FD: Integer);
begin
  Bits[FD div NFDBITS] := Bits[FD div NFDBITS] and not (UIntPtr(1) shl (UIntPtr(FD) mod NFDBITS));
end;

function TFdSet.IsSet(FD: Integer): Boolean;
begin
  Result := (Bits[FD div NFDBITS] and (UIntPtr(1) shl (UIntPtr(FD) mod NFDBITS))) <> 0;
end;

procedure TFdSet.Zero;
var
  I: Integer;
begin
  for I := Low(Bits) to High(Bits) do Bits[I] := 0;
end;

end.
