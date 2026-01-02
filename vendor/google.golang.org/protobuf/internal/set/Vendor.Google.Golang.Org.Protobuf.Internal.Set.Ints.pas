unit Vendor.Google.Golang.Org.Protobuf.Internal.Set.Ints;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TInt64s = UInt64;

  TInt64sHelper = record helper for TInt64s
  public
    function Len: Integer;
    function Has(N: UInt64): Boolean;
    procedure Set_(N: UInt64);
    procedure Clear(N: UInt64);
  end;

  TInts = record
  private
    FLo: TInt64s;
    FHi: TDictionary<UInt64, Pointer>; // Set implementation
  public
    function Len: Integer;
    function Has(N: UInt64): Boolean;
    procedure Set_(N: UInt64);
    procedure Clear(N: UInt64);
  end;

implementation

{ TInt64sHelper }

function TInt64sHelper.Len: Integer;
begin
  // Population count logic
  Result := 0; // Simplified
end;

function TInt64sHelper.Has(N: UInt64): Boolean;
begin
  Result := (Self and (UInt64(1) shl N)) > 0;
end;

procedure TInt64sHelper.Set_(N: UInt64);
begin
  Self := Self or (UInt64(1) shl N);
end;

procedure TInt64sHelper.Clear(N: UInt64);
begin
  Self := Self and not (UInt64(1) shl N);
end;

{ TInts }

function TInts.Len: Integer;
begin
  Result := FLo.Len;
  if FHi <> nil then Inc(Result, FHi.Count);
end;

function TInts.Has(N: UInt64): Boolean;
begin
  if N < 64 then Exit(FLo.Has(N));
  Result := (FHi <> nil) and FHi.ContainsKey(N);
end;

procedure TInts.Set_(N: UInt64);
begin
  if N < 64 then
  begin
    FLo.Set_(N);
    Exit;
  end;
  if FHi = nil then FHi := TDictionary<UInt64, Pointer>.Create;
  FHi.AddOrSetValue(N, nil);
end;

procedure TInts.Clear(N: UInt64);
begin
  if N < 64 then
  begin
    FLo.Clear(N);
    Exit;
  end;
  if FHi <> nil then FHi.Remove(N);
end;

end.
