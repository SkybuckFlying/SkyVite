unit Vendor.Go.Uber.Org.Atomic.String;

interface

uses
  System.SysUtils, System.SyncObjs;

type
  /// <summary>
  /// String is an atomic type-safe wrapper for string values.
  /// </summary>
  TString = class
  private
    FV: string;
    FMu: TCriticalSection;
  public
    constructor Create(Val: string = '');
    destructor Destroy; override;

    function Load: string;
    procedure Store(Val: string);
    function ToString: string; override;
  end;

implementation

{ TString }

constructor TString.Create(Val: string);
begin
  FMu := TCriticalSection.Create;
  FV := Val;
end;

destructor TString.Destroy;
begin
  FMu.Free;
  inherited;
end;

function TString.Load: string;
begin
  FMu.Enter;
  try
    Result := FV;
  finally
    FMu.Leave;
  end;
end;

procedure TString.Store(Val: string);
begin
  FMu.Enter;
  try
    FV := Val;
  finally
    FMu.Leave;
  end;
end;

function TString.ToString: string;
begin
  Result := Load;
end;

end.
