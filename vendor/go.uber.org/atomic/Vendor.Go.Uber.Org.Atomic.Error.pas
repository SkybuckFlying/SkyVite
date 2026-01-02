unit Vendor.Go.Uber.Org.Atomic.Error;

interface

uses
  System.SysUtils, System.SyncObjs;

type
  /// <summary>
  /// Error is an atomic type-safe wrapper for error values.
  /// </summary>
  TError = class
  private
    FV: TObject; // Placeholder for atomic value
    FMu: TCriticalSection;
    FError: Exception;
  public
    constructor Create(Val: Exception = nil);
    destructor Destroy; override;

    function Load: Exception;
    procedure Store(Val: Exception);
  end;

implementation

{ TError }

constructor TError.Create(Val: Exception);
begin
  FMu := TCriticalSection.Create;
  FError := Val;
end;

destructor TError.Destroy;
begin
  FMu.Free;
  inherited;
end;

function TError.Load: Exception;
begin
  FMu.Enter;
  try
    Result := FError;
  finally
    FMu.Leave;
  end;
end;

procedure TError.Store(Val: Exception);
begin
  FMu.Enter;
  try
    FError := Val;
  finally
    FMu.Leave;
  end;
end;

end.
