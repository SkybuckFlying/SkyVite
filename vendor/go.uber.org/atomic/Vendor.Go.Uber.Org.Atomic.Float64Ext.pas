unit Vendor.Go.Uber.Org.Atomic.Float64Ext;

interface

uses
  System.SysUtils,
  Vendor.Go.Uber.Org.Atomic.Float64;

type
  TFloat64Helper = class helper for TFloat64
  public
    function Add(Delta: Double): Double;
    function Sub(Delta: Double): Double;
    // ToString is already in TFloat64
  end;

implementation

{ TFloat64Helper }

function TFloat64Helper.Add(Delta: Double): Double;
var
  OldVal, NewVal: Double;
begin
  while True do
  begin
    OldVal := Load;
    NewVal := OldVal + Delta;
    // Note: This helper might need access to private FV of TFloat64 if CAS is not enough
    // But CAS is public.
    if CAS(OldVal, NewVal) then
      Exit(NewVal);
  end;
end;

function TFloat64Helper.Sub(Delta: Double): Double;
begin
  Result := Add(-Delta);
end;

end.
