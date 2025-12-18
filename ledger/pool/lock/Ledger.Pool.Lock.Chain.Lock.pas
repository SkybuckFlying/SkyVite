unit Ledger.Pool.Lock.Chain.Lock;

interface

uses
  SysUtils, Classes, SyncObjs,
  unit_GoLang_Compatibility_version_006;

type
  TChainLock = class
  private
    FLock: TCriticalSection;
    FUnlockChan: TGoChannel<Boolean>;
    FLocked: Boolean;
    
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Lock;
    procedure Unlock;
    function WaitForUnlock: TGoChannel<Boolean>;
  end;

implementation

{ TChainLock }

constructor TChainLock.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FUnlockChan := TGoChannel<Boolean>.Create(1); // Buffered channel of size 1
  FLocked := False;
end;

destructor TChainLock.Destroy;
begin
  FLock.Free;
  FUnlockChan.Free;
  inherited;
end;

procedure TChainLock.Lock;
begin
  FLock.Enter;
  try
    if FLocked then
    begin
      // This behavior might need to be more sophisticated,
      // e.g., waiting on a condition variable.
      // For now, we'll just raise an exception if it's already locked.
      raise Exception.Create('Lock already held');
    end;
    FLocked := True;
  finally
    FLock.Leave;
  end;
end;

procedure TChainLock.Unlock;
begin
  FLock.Enter;
  try
    if not FLocked then
      Exit; // Or raise an error
      
    FLocked := False;
  finally
    FLock.Leave;
  end;
  
  // Signal any waiters
  FUnlockChan.Send(True);
end;

function TChainLock.WaitForUnlock: TGoChannel<Boolean>;
begin
  Result := FUnlockChan;
end;

end.
