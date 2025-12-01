unit Common.Lock;

interface

uses
  System.SysUtils;

type
  // TNonBlockLock is a spinlock that tries to acquire a lock without blocking,
  // yielding the thread after a certain number of attempts. It is a Delphi
  // translation of the NonBlockLock in Go.
  TNonBlockLock = record
  private
    mB: Integer; // 0 = unlocked, 1 = locked
  public
    function TryLock: Boolean;
    procedure Lock;
    function UnLock: Boolean;
  end;

implementation

uses
  System.Threading,
  System.SyncObjs;

{ TNonBlockLock }

function TNonBlockLock.TryLock: Boolean;
begin
  Result := TInterlocked.CompareExchange(mB, 1, 0) = 0;
end;

procedure TNonBlockLock.Lock;
var
  vSpinCount: Integer;
begin
  vSpinCount := 0;
  while true do
  begin
    if Self.TryLock then
    begin
      Exit;
    end;

    // Spin for a while before sleeping to avoid excessive context switching.
    vSpinCount := vSpinCount + 1;
    if vSpinCount > 2000 then
    begin
      TThread.Sleep(1);
      vSpinCount := 0;
    end;
  end;
end;

function TNonBlockLock.UnLock: Boolean;
begin
  Result := TInterlocked.CompareExchange(mB, 0, 1) = 1;
end;

end.
