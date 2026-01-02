unit Vendor.Go.Uber.Org.Atomic.Value;

interface

uses
  System.SysUtils, System.SyncObjs;

type
  /// <summary>
  /// Value shadows the type of the same name from sync/atomic
  /// </summary>
  TValue = class
  private
    FV: TObject;
    FMu: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;

    function Load: TObject;
    procedure Store(Val: TObject);
  end;

implementation

{ TValue }

constructor TValue.Create;
begin
  FMu := TCriticalSection.Create;
end;

destructor TValue.Destroy;
begin
  FMu.Free;
  inherited;
end;

function TValue.Load: TObject;
begin
  FMu.Enter;
  try
    Result := FV;
  finally
    FMu.Leave;
  end;
end;

procedure TValue.Store(Val: TObject);
begin
  FMu.Enter;
  try
    FV := Val;
  finally
    FMu.Leave;
  end;
end;

end.
