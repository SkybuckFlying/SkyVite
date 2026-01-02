unit Vendor.Go.Uber.Org.Atomic.Uintptr;

interface

uses
  System.SysUtils, System.SyncObjs, System.JSON;

type
  /// <summary>
  /// Uintptr is an atomic wrapper around uintptr.
  /// </summary>
  TUintptr = class
  private
    FV: UIntPtr;
  public
    constructor Create(Val: UIntPtr = 0);

    function Load: UIntPtr;
    function Add(Delta: UIntPtr): UIntPtr;
    function Sub(Delta: UIntPtr): UIntPtr;
    function Inc: UIntPtr;
    function Dec: UIntPtr;
    function CAS(Old, NewVal: UIntPtr): Boolean;
    procedure Store(Val: UIntPtr);
    function Swap(Val: UIntPtr): UIntPtr;
    function MarshalJSON: TJSONValue;
    procedure UnmarshalJSON(AValue: TJSONValue);
    function ToString: string; override;
  end;

implementation

{ TUintptr }

constructor TUintptr.Create(Val: UIntPtr);
begin
  FV := Val;
end;

function TUintptr.Load: UIntPtr;
begin
  // TInterlocked doesn't have Read for UIntPtr directly in all versions, 
  // but it usually has pointers or 64-bit/32-bit.
  Result := UIntPtr(TInterlocked.Read(Int64(FV)));
end;

function TUintptr.Add(Delta: UIntPtr): UIntPtr;
begin
  Result := UIntPtr(TInterlocked.Add(Int64(FV), Int64(Delta)));
end;

function TUintptr.Sub(Delta: UIntPtr): UIntPtr;
begin
  Result := UIntPtr(TInterlocked.Add(Int64(FV), -Int64(Delta)));
end;

function TUintptr.Inc: UIntPtr;
begin
  Result := UIntPtr(TInterlocked.Increment(Int64(FV)));
end;

function TUintptr.Dec: UIntPtr;
begin
  Result := UIntPtr(TInterlocked.Decrement(Int64(FV)));
end;

function TUintptr.CAS(Old, NewVal: UIntPtr): Boolean;
begin
  Result := TInterlocked.CompareExchange(Pointer(FV), Pointer(NewVal), Pointer(Old)) = Pointer(Old);
end;

procedure TUintptr.Store(Val: UIntPtr);
begin
  TInterlocked.Exchange(Pointer(FV), Pointer(Val));
end;

function TUintptr.Swap(Val: UIntPtr): UIntPtr;
begin
  Result := UIntPtr(TInterlocked.Exchange(Pointer(FV), Pointer(Val)));
end;

function TUintptr.MarshalJSON: TJSONValue;
begin
  Result := TJSONNumber.Create(Int64(Load));
end;

procedure TUintptr.UnmarshalJSON(AValue: TJSONValue);
begin
  if AValue is TJSONNumber then
    Store(UIntPtr(TJSONNumber(AValue).AsInt64));
end;

function TUintptr.ToString: string;
begin
  Result := UIntToStr(Load);
end;

end.
