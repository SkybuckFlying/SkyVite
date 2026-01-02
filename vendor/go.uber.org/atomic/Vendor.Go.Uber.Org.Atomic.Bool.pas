unit Vendor.Go.Uber.Org.Atomic.Bool;

interface

uses
  System.SysUtils, System.SyncObjs, System.JSON,
  Vendor.Go.Uber.Org.Atomic.Uint32;

type
  /// <summary>
  /// Bool is an atomic type-safe wrapper for bool values.
  /// </summary>
  TBool = class
  private
    FV: TUint32;
    function Truthy(N: UInt32): Boolean;
    function BoolToInt(B: Boolean): UInt32;
  public
    constructor Create(Val: Boolean = False);
    destructor Destroy; override;

    function Load: Boolean;
    procedure Store(Val: Boolean);
    function CAS(Old, NewVal: Boolean): Boolean;
    function Swap(Val: Boolean): Boolean;
    function Toggle: Boolean;
    function MarshalJSON: TJSONValue;
    procedure UnmarshalJSON(AValue: TJSONValue);
    function ToString: string; override;
  end;

implementation

{ TBool }

constructor TBool.Create(Val: Boolean);
begin
  FV := TUint32.Create(BoolToInt(Val));
end;

destructor TBool.Destroy;
begin
  FV.Free;
  inherited;
end;

function TBool.BoolToInt(B: Boolean): UInt32;
begin
  if B then Result := 1 else Result := 0;
end;

function TBool.Truthy(N: UInt32): Boolean;
begin
  Result := (N = 1);
end;

function TBool.Load: Boolean;
begin
  Result := Truthy(FV.Load);
end;

procedure TBool.Store(Val: Boolean);
begin
  FV.Store(BoolToInt(Val));
end;

function TBool.CAS(Old, NewVal: Boolean): Boolean;
begin
  Result := FV.CAS(BoolToInt(Old), BoolToInt(NewVal));
end;

function TBool.Swap(Val: Boolean): Boolean;
begin
  Result := Truthy(FV.Swap(BoolToInt(Val)));
end;

function TBool.Toggle: Boolean;
var
  OldVal: Boolean;
begin
  while True do
  begin
    OldVal := Load;
    if CAS(OldVal, not OldVal) then
      Exit(OldVal);
  end;
end;

function TBool.MarshalJSON: TJSONValue;
begin
  Result := TJSONBool.Create(Load);
end;

procedure TBool.UnmarshalJSON(AValue: TJSONValue);
begin
  if AValue is TJSONBool then
    Store(TJSONBool(AValue).AsBoolean);
end;

function TBool.ToString: string;
begin
  Result := BoolToStr(Load, True);
end;

end.
