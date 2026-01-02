unit Vendor.Go.Uber.Org.Atomic.Uint32;

interface

uses
  System.SysUtils, System.SyncObjs, System.JSON;

type
  /// <summary>
  /// Uint32 is an atomic wrapper around uint32.
  /// </summary>
  TUint32 = class
  private
    FV: UInt32;
  public
    constructor Create(Val: UInt32 = 0);

    function Load: UInt32;
    function Add(Delta: UInt32): UInt32;
    function Sub(Delta: UInt32): UInt32;
    function Inc: UInt32;
    function Dec: UInt32;
    function CAS(Old, NewVal: UInt32): Boolean;
    procedure Store(Val: UInt32);
    function Swap(Val: UInt32): UInt32;
    function MarshalJSON: TJSONValue;
    procedure UnmarshalJSON(AValue: TJSONValue);
    function ToString: string; override;
  end;

implementation

{ TUint32 }

constructor TUint32.Create(Val: UInt32);
begin
  FV := Val;
end;

function TUint32.Load: UInt32;
begin
  Result := TInterlocked.Read(FV);
end;

function TUint32.Add(Delta: UInt32): UInt32;
begin
  Result := TInterlocked.Add(Integer(FV), Delta);
end;

function TUint32.Sub(Delta: UInt32): UInt32;
begin
  Result := TInterlocked.Add(Integer(FV), -Integer(Delta));
end;

function TUint32.Inc: UInt32;
begin
  Result := TInterlocked.Increment(Integer(FV));
end;

function TUint32.Dec: UInt32;
begin
  Result := TInterlocked.Decrement(Integer(FV));
end;

function TUint32.CAS(Old, NewVal: UInt32): Boolean;
begin
  Result := TInterlocked.CompareExchange(Integer(FV), Integer(NewVal), Integer(Old)) = Integer(Old);
end;

procedure TUint32.Store(Val: UInt32);
begin
  TInterlocked.Exchange(Integer(FV), Integer(Val));
end;

function TUint32.Swap(Val: UInt32): UInt32;
begin
  Result := TInterlocked.Exchange(Integer(FV), Integer(Val));
end;

function TUint32.MarshalJSON: TJSONValue;
begin
  Result := TJSONNumber.Create(Load);
end;

procedure TUint32.UnmarshalJSON(AValue: TJSONValue);
begin
  if AValue is TJSONNumber then
    Store(TJSONNumber(AValue).AsInt);
end;

function TUint32.ToString: string;
begin
  Result := UIntToStr(Load);
end;

end.
