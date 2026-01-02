unit Vendor.Go.Uber.Org.Atomic.Time;

interface

uses
  System.SysUtils, System.SyncObjs;

type
  /// <summary>
  /// Time is an atomic type-safe wrapper for TDateTime values.
  /// </summary>
  TTime = class
  private
    FV: TDateTime;
    FMu: TCriticalSection;
  public
    constructor Create(Val: TDateTime = 0);
    destructor Destroy; override;

    function Load: TDateTime;
    procedure Store(Val: TDateTime);
  end;

implementation

{ TTime }

constructor TTime.Create(Val: TDateTime);
begin
  FMu := TCriticalSection.Create;
  FV := Val;
end;

destructor TTime.Destroy;
begin
  FMu.Free;
  inherited;
end;

function TTime.Load: TDateTime;
begin
  FMu.Enter;
  try
    Result := FV;
  finally
    FMu.Leave;
  end;
end;

procedure TTime.Store(Val: TDateTime);
begin
  FMu.Enter;
  try
    FV := Val;
  finally
    FMu.Leave;
  end;
end;

end.
