unit Vendor.Go.Uber.Org.Atomic.Float64;

interface

uses
  System.SysUtils, System.SyncObjs, System.JSON,
  Vendor.Go.Uber.Org.Atomic.Uint64;

type
  /// <summary>
  /// Float64 is an atomic type-safe wrapper for float64 values.
  /// </summary>
  TFloat64 = class
  private
    FV: TUint64;
    function FloatToBits(Val: Double): UInt64;
    function BitsToFloat(Bits: UInt64): Double;
  public
    constructor Create(Val: Double = 0.0);
    destructor Destroy; override;

    function Load: Double;
    procedure Store(Val: Double);
    function Swap(Val: Double): Double;
    function MarshalJSON: TJSONValue;
    procedure UnmarshalJSON(AValue: TJSONValue);
    function ToString: string; override;
  end;

implementation

{ TFloat64 }

constructor TFloat64.Create(Val: Double);
begin
  FV := TUint64.Create(FloatToBits(Val));
end;

destructor TFloat64.Destroy;
begin
  FV.Free;
  inherited;
end;

function TFloat64.FloatToBits(Val: Double): UInt64;
begin
  Move(Val, Result, SizeOf(Double));
end;

function TFloat64.BitsToFloat(Bits: UInt64): Double;
begin
  Move(Bits, Result, SizeOf(Double));
end;

function TFloat64.Load: Double;
begin
  Result := BitsToFloat(FV.Load);
end;

procedure TFloat64.Store(Val: Double);
begin
  FV.Store(FloatToBits(Val));
end;

function TFloat64.Swap(Val: Double): Double;
begin
  Result := BitsToFloat(FV.Swap(FloatToBits(Val)));
end;

function TFloat64.MarshalJSON: TJSONValue;
begin
  Result := TJSONNumber.Create(Load);
end;

procedure TFloat64.UnmarshalJSON(AValue: TJSONValue);
begin
  if AValue is TJSONNumber then
    Store(TJSONNumber(AValue).AsDouble);
end;

function TFloat64.ToString: string;
begin
  Result := FloatToStr(Load);
end;

end.
