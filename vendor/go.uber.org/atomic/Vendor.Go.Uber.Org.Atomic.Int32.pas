unit Vendor.Go.Uber.Org.Atomic.Int32;

interface

uses
  System.SysUtils, System.SyncObjs, System.JSON;

type
  /// <summary>
  /// Int32 is an atomic wrapper around int32.
  /// </summary>
  TInt32 = class
  private
    FV: Int32;
  public
    constructor Create(Val: Int32 = 0);

    function Load: Int32;
    function Add(Delta: Int32): Int32;
    function Sub(Delta: Int32): Int32;
    function Inc: Int32;
    function Dec: Int32;
    function CAS(Old, NewVal: Int32): Boolean;
    procedure Store(Val: Int32);
    function Swap(Val: Int32): Int32;
    function MarshalJSON: TJSONValue;
    procedure UnmarshalJSON(AValue: TJSONValue);
    function ToString: string; override;
  end;

implementation

{ TInt32 }

constructor TInt32.Create(Val: Int32);
begin
  FV := Val;
end;

function TInt32.Load: Int32;
begin
  Result := TInterlocked.Read(FV);
end;

function TInt32.Add(Delta: Int32): Int32;
begin
  Result := TInterlocked.Add(FV, Delta);
end;

function TInt32.Sub(Delta: Int32): Int32;
begin
  Result := TInterlocked.Add(FV, -Delta);
end;

function TInt32.Inc: Int32;
begin
  Result := TInterlocked.Increment(FV);
end;

function TInt32.Dec: Int32;
begin
  Result := TInterlocked.Decrement(FV);
end;

function TInt32.CAS(Old, NewVal: Int32): Boolean;
begin
  Result := TInterlocked.CompareExchange(FV, NewVal, Old) = Old;
end;

procedure TInt32.Store(Val: Int32);
begin
  TInterlocked.Exchange(FV, Val);
end;

function TInt32.Swap(Val: Int32): Int32;
begin
  Result := TInterlocked.Exchange(FV, Val);
end;

function TInt32.MarshalJSON: TJSONValue;
begin
  Result := TJSONNumber.Create(Load);
end;

procedure TInt32.UnmarshalJSON(AValue: TJSONValue);
begin
  if AValue is TJSONNumber then
    Store(TJSONNumber(AValue).AsInt);
end;

function TInt32.ToString: string;
begin
  Result := IntToStr(Load);
end;

end.
