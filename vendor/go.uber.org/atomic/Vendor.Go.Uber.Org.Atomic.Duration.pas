unit Vendor.Go.Uber.Org.Atomic.Duration;

interface

uses
  System.SysUtils, System.SyncObjs, System.JSON, System.TimeSpan,
  Vendor.Go.Uber.Org.Atomic.Int64;

type
  /// <summary>
  /// Duration is an atomic type-safe wrapper for time.Duration values.
  /// </summary>
  TDuration = class
  private
    FV: TInt64;
  public
    constructor Create(Val: TTimeSpan);
    destructor Destroy; override;

    function Load: TTimeSpan;
    procedure Store(Val: TTimeSpan);
    function CAS(Old, NewVal: TTimeSpan): Boolean;
    function Swap(Val: TTimeSpan): TTimeSpan;
    function Add(Delta: TTimeSpan): TTimeSpan;
    function Sub(Delta: TTimeSpan): TTimeSpan;
    function MarshalJSON: TJSONValue;
    procedure UnmarshalJSON(AValue: TJSONValue);
    function ToString: string; override;
  end;

implementation

{ TDuration }

constructor TDuration.Create(Val: TTimeSpan);
begin
  FV := TInt64.Create(Val.Ticks);
end;

destructor TDuration.Destroy;
begin
  FV.Free;
  inherited;
end;

function TDuration.Load: TTimeSpan;
begin
  Result := TTimeSpan.FromTicks(FV.Load);
end;

procedure TDuration.Store(Val: TTimeSpan);
begin
  FV.Store(Val.Ticks);
end;

function TDuration.CAS(Old, NewVal: TTimeSpan): Boolean;
begin
  Result := FV.CAS(Old.Ticks, NewVal.Ticks);
end;

function TDuration.Swap(Val: TTimeSpan): TTimeSpan;
begin
  Result := TTimeSpan.FromTicks(FV.Swap(Val.Ticks));
end;

function TDuration.Add(Delta: TTimeSpan): TTimeSpan;
begin
  Result := TTimeSpan.FromTicks(FV.Add(Delta.Ticks));
end;

function TDuration.Sub(Delta: TTimeSpan): TTimeSpan;
begin
  Result := TTimeSpan.FromTicks(FV.Sub(Delta.Ticks));
end;

function TDuration.MarshalJSON: TJSONValue;
begin
  Result := TJSONNumber.Create(FV.Load);
end;

procedure TDuration.UnmarshalJSON(AValue: TJSONValue);
begin
  if AValue is TJSONNumber then
    Store(TTimeSpan.FromTicks(TJSONNumber(AValue).AsInt64));
end;

function TDuration.ToString: string;
begin
  Result := Load.ToString;
end;

end.
