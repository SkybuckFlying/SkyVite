unit Vendor.Go.Uber.Org.Atomic.Int64;

interface

uses
  System.SysUtils, System.SyncObjs, System.JSON;

type
  /// <summary>
  /// Int64 is an atomic wrapper around int64.
  /// </summary>
  TInt64 = class
  private
    FV: Int64;
  public
    constructor Create(Val: Int64 = 0);

    function Load: Int64;
    function Add(Delta: Int64): Int64;
    function Sub(Delta: Int64): Int64;
    function Inc: Int64;
    function Dec: Int64;
    function CAS(Old, NewVal: Int64): Boolean;
    procedure Store(Val: Int64);
    function Swap(Val: Int64): Int64;
    function MarshalJSON: TJSONValue;
    procedure UnmarshalJSON(AValue: TJSONValue);
    function ToString: string; override;
  end;

implementation

{ TInt64 }

constructor TInt64.Create(Val: Int64);
begin
  FV := Val;
end;

function TInt64.Load: Int64;
begin
  Result := TInterlocked.Read(FV);
end;

function TInt64.Add(Delta: Int64): Int64;
begin
  Result := TInterlocked.Add(FV, Delta);
end;

function TInt64.Sub(Delta: Int64): Int64;
begin
  Result := TInterlocked.Add(FV, -Delta);
end;

function TInt64.Inc: Int64;
begin
  Result := TInterlocked.Increment(FV);
end;

function TInt64.Dec: Int64;
begin
  Result := TInterlocked.Decrement(FV);
end;

function TInt64.CAS(Old, NewVal: Int64): Boolean;
begin
  Result := TInterlocked.CompareExchange(FV, NewVal, Old) = Old;
end;

procedure TInt64.Store(Val: Int64);
begin
  TInterlocked.Exchange(FV, Val);
end;

function TInt64.Swap(Val: Int64): Int64;
begin
  Result := TInterlocked.Exchange(FV, Val);
end;

function TInt64.MarshalJSON: TJSONValue;
begin
  Result := TJSONNumber.Create(Load);
end;

procedure TInt64.UnmarshalJSON(AValue: TJSONValue);
begin
  if AValue is TJSONNumber then
    Store(TJSONNumber(AValue).AsInt64);
end;

function TInt64.ToString: string;
begin
  Result := IntToStr(Load);
end;

end.
