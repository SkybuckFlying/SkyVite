unit Vendor.Go.Uber.Org.Atomic.Uint64;

interface

uses
  System.SysUtils, System.SyncObjs, System.JSON;

type
  /// <summary>
  /// Uint64 is an atomic wrapper around uint64.
  /// </summary>
  TUint64 = class
  private
    FV: UInt64;
  public
    constructor Create(Val: UInt64 = 0);

    function Load: UInt64;
    function Add(Delta: UInt64): UInt64;
    function Sub(Delta: UInt64): UInt64;
    function Inc: UInt64;
    function Dec: UInt64;
    function CAS(Old, NewVal: UInt64): Boolean;
    procedure Store(Val: UInt64);
    function Swap(Val: UInt64): UInt64;
    function MarshalJSON: TJSONValue;
    procedure UnmarshalJSON(AValue: TJSONValue);
    function ToString: string; override;
  end;

implementation

{ TUint64 }

constructor TUint64.Create(Val: UInt64);
begin
  FV := Val;
end;

function TUint64.Load: UInt64;
begin
  Result := TInterlocked.Read(FV);
end;

function TUint64.Add(Delta: UInt64): UInt64;
begin
  Result := TInterlocked.Add(Int64(FV), Int64(Delta));
end;

function TUint64.Sub(Delta: UInt64): UInt64;
begin
  Result := TInterlocked.Add(Int64(FV), -Int64(Delta));
end;

function TUint64.Inc: UInt64;
begin
  Result := TInterlocked.Increment(Int64(FV));
end;

function TUint64.Dec: UInt64;
begin
  Result := TInterlocked.Decrement(Int64(FV));
end;

function TUint64.CAS(Old, NewVal: UInt64): Boolean;
begin
  Result := TInterlocked.CompareExchange(Int64(FV), Int64(NewVal), Int64(Old)) = Int64(Old);
end;

procedure TUint64.Store(Val: UInt64);
begin
  TInterlocked.Exchange(Int64(FV), Int64(Val));
end;

function TUint64.Swap(Val: UInt64): UInt64;
begin
  Result := TInterlocked.Exchange(Int64(FV), Int64(Val));
end;

function TUint64.MarshalJSON: TJSONValue;
begin
  Result := TJSONNumber.Create(Load);
end;

procedure TUint64.UnmarshalJSON(AValue: TJSONValue);
begin
  if AValue is TJSONNumber then
    Store(TJSONNumber(AValue).AsInt64);
end;

function TUint64.ToString: string;
begin
  Result := UIntToStr(Load);
end;

end.
