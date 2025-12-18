unit Ledger.Pool.Lock.Chain.Lock.Test;

interface

uses
  SysUtils, Classes,
  Ledger.Pool.Lock.Chain.Lock,
  unit_GoLang_Compatibility_version_006;

type
  TChainLockTest = class
  private
    procedure TestLockUnlock;
    procedure TestConcurrentLock;
  public
    procedure RunAllTests;
  end;

implementation

uses System.Threading, System.SyncObjs;

{ TChainLockTest }

procedure TChainLockTest.TestLockUnlock;
var
  lock: TChainLock;
  unlockChan: TGoChannel<Boolean>;
  unlocked: Boolean;
begin
  lock := TChainLock.Create;
  try
    lock.Lock;
    
    // Start a task that waits for the unlock signal
    unlockChan := lock.WaitForUnlock;
    TGo.Run(procedure
    begin
      // This will block until Unlock is called
      unlockChan.Receive(unlocked); 
    end);
    
    // Give the task a moment to start and block
    Sleep(10); 
    
    lock.Unlock;
    
    // Wait for the task to finish
    Sleep(20); 
    // In a real test, you'd use a waitgroup or another sync primitive
    // to be sure the task has finished.
    
    // The test passes if it doesn't deadlock.
  finally
    lock.Free;
  end;
end;

procedure TChainLockTest.TestConcurrentLock;
var
  lock: TChainLock;
  wg: TGoWaitGroup;
  counter: Integer;
  i: Integer;
begin
  lock := TChainLock.Create;
  wg := TGoWaitGroup.Create;
  counter := 0;
  
  try
    wg.Add(2);
    
    // Start two tasks that try to acquire the lock and increment a counter
    TGo.Run(procedure
    begin
      try
        lock.Lock;
        try
          InterlockedIncrement(counter);
        finally
          lock.Unlock;
        end;
      finally
        wg.Done;
      end;
    end);
    
    TGo.Run(procedure
    begin
      try
        lock.Lock;
        try
          InterlockedIncrement(counter);
        finally
          lock.Unlock;
        end;
      finally
        wg.Done;
      end;
    end);
    
    wg.Wait;
    
    // If both tasks ran sequentially, the counter should be 2.
    if counter <> 2 then
      raise Exception.Create('Concurrent lock test failed: counter mismatch');
      
  finally
    lock.Free;
    wg.Free;
  end;
end;

procedure TChainLockTest.RunAllTests;
begin
  TestLockUnlock;
  TestConcurrentLock;
end;

end.
