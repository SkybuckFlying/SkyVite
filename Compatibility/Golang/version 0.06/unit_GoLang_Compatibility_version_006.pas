unit unit_GoLang_Compatibility_version_006;

{

unit GoLang compatibility

version 0.01 to version 0.05 created and debugged on 24 and 25 november 2025 by AIs: Google Gemini Pro 3.0, Claude Sonnet 4.5, GPT-OSS-120B all prompted by Skybuck Flying

Test program must use a thread safe version of writeln for correct output !
Test program produces an exception to test it, this is normal, just click continue.

Question:

Why does this code use a monitor on a FLock : TObject and not just simply Self ?:

Gemini 3.0 Pro answer:
"

Using a private `FLock` object instead of `Self` is a standard "best practice" in concurrency programming, particularly when writing libraries or reusable classes.

Here is the detailed breakdown of why this approach is safer and superior:

### 1. Encapsulation and Safety (The Main Reason)
The most critical reason is to prevent **external interference**.

* **If you use `Self`:** The class instance is `public`. Any code consuming your unit can write `System.TMonitor.Enter(MyChannelInstance)`. If the consumer locks the object for their own reasons (e.g., to perform a transaction) and your internal code also tries to lock `Self`, you create a high risk of deadlocks or contention that you cannot control.
* **If you use `FLock`:** The `FLock` field is `private`. External code cannot see it or access it. This guarantees that **only** the internal logic of `TGoChannel` can acquire that lock or signal that monitor. It makes the class self-contained and robust.

### 2. Isolation of `Wait` and `Pulse` Logic
This code acts as a "Condition Variable" (waiting for the queue to have space or data).

* `System.TMonitor.Wait(Lock)` atomically releases the lock and puts the thread to sleep.
* `System.TMonitor.Pulse(Lock)` wakes up a thread waiting on that specific lock.

If you used `Self`, and an external user decided to use `TMonitor` on the channel instance for a different purpose (e.g., waiting for the channel to be destroyed or some other custom event), their `Pulse` calls could accidentally wake up your internal `Send`/`Receive` methods, or your internal `Pulse` could wake up their external logic. This is known as a **spurious wakeup** or cross-talk, leading to hard-to-debug race conditions.

### 3. Granularity
While this specific class only uses one lock, using private objects allows for **lock granularity**.

If you were to expand this class later, you might want one lock for the "Read Head" and a different lock for the "Write Head" (to allow simultaneous reading and writing). If you force yourself to use `Self`, you only have one lock available (the object instance itself). By using `FLock`, you establish a pattern where you can easily add `FLockRead` and `FLockWrite` later without breaking the interface.

### Summary
* **Using `Self`:** Publicly exposed lock. Dangerous. External code can hijack your synchronization logic.
* **Using `FLock`:** Private, internal lock. Safe. Guarantees that the synchronization logic works exactly as written, regardless of how the caller uses the class instance.

### Next Step
Would you like me to review the implementation of the `TGoChannel.Receive` method to ensure the `Wait` loop correctly handles the `PulseAll` from the `Close` method to prevent potential deadlocks?
"

}

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  System.Threading;

type
  EGoChannelClosed = class(Exception);

  TGoChannel<T> = class
  private
    FQueue: TQueue<T>;
    FLock: TObject;
    FClosed: Boolean;
    FCapacity: Integer;
  public
    class var StrictChannelExceptions: Boolean;
    constructor Create(BufferSize: Integer = 1);
    destructor Destroy; override;
    procedure Send(const Value: T);
    function Receive(out Value: T): Boolean; overload;
    function Receive: T; overload;
    procedure Close;
    function Len: Integer;
  end;

  TGoWaitGroup = class
  private
    FCount: Integer;
    FEvent: TEvent;
    FLock: TCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Delta: Integer);
    procedure Done;
    procedure Wait;
  end;

  IGoDefer = interface
    ['{19263852-8415-4981-9260-89B990430125}']
  end;

  TGo = class
  public
    class procedure Run(const Proc: TProc);
  end;

function Defer(const Proc: TProc): IGoDefer;

implementation

type
  TGoDeferImpl = class(TInterfacedObject, IGoDefer)
  private
    FProc: TProc;
  public
    constructor Create(const AProc: TProc);
    destructor Destroy; override;
  end;

constructor TGoDeferImpl.Create(const AProc: TProc);
begin
  inherited Create;
  FProc := AProc;
end;

destructor TGoDeferImpl.Destroy;
begin
  if Assigned(FProc) then
    FProc();
  inherited;
end;

function Defer(const Proc: TProc): IGoDefer;
begin
  Result := TGoDeferImpl.Create(Proc);
end;

{ TGoChannel<T> }

constructor TGoChannel<T>.Create(BufferSize: Integer);
begin
  inherited Create;
  if BufferSize < 1 then BufferSize := 1;
  FCapacity := BufferSize;
  FQueue := TQueue<T>.Create;
  FLock := TObject.Create;
  FClosed := False;
end;

destructor TGoChannel<T>.Destroy;
begin
  FQueue.Free;
  FLock.Free;
  inherited;
end;

procedure TGoChannel<T>.Send(const Value: T);
begin
  System.TMonitor.Enter(FLock);
  try
    if FClosed then
      raise EGoChannelClosed.Create('Cannot send to a closed channel');

    while (FQueue.Count >= FCapacity) and (not FClosed) do
      System.TMonitor.Wait(FLock, INFINITE);

    if FClosed then
    begin
      if StrictChannelExceptions then
        raise EGoChannelClosed.Create('Channel closed during send')
      else
        Exit;
    end;

    FQueue.Enqueue(Value);
    System.TMonitor.Pulse(FLock);
  finally
	System.TMonitor.Exit(FLock);
  end;
end;

function TGoChannel<T>.Receive(out Value: T): Boolean;
begin
  System.TMonitor.Enter(FLock);
  try
    while (FQueue.Count = 0) and (not FClosed) do
      System.TMonitor.Wait(FLock, INFINITE);

    if FQueue.Count > 0 then
    begin
      Value := FQueue.Dequeue;
      Result := True;
      System.TMonitor.Pulse(FLock);
    end
    else
    begin
      // Queue is empty AND Closed is true
      Result := False;
    end;
  finally
    System.TMonitor.Exit(FLock);
  end;
end;

function TGoChannel<T>.Receive: T;
var
  Temp: T;
begin
  if not Receive(Temp) then
    raise EGoChannelClosed.Create('Channel closed');
  Result := Temp;
end;

procedure TGoChannel<T>.Close;
begin
  System.TMonitor.Enter(FLock);
  try
    if not FClosed then
    begin
      FClosed := True;
      System.TMonitor.PulseAll(FLock);  // Keep PulseAll here to wake all waiting threads
    end;
  finally
    System.TMonitor.Exit(FLock);
  end;
end;

function TGoChannel<T>.Len: Integer;
begin
  System.TMonitor.Enter(FLock);
  try
    Result := FQueue.Count;
  finally
    System.TMonitor.Exit(FLock);
  end;
end;

{ TGoWaitGroup }

constructor TGoWaitGroup.Create;
begin
  inherited;
  FCount := 0;
  FLock := TCriticalSection.Create;
  FEvent := TEvent.Create(nil, True, False, '');
end;

destructor TGoWaitGroup.Destroy;
begin
  FEvent.Free;
  FLock.Free;
  inherited;
end;

procedure TGoWaitGroup.Add(Delta: Integer);
begin
  FLock.Enter;
  try
    Inc(FCount, Delta);
    if FCount > 0 then
      FEvent.ResetEvent
    else if FCount = 0 then
      FEvent.SetEvent;
      
    if FCount < 0 then
      raise Exception.Create('sync: negative WaitGroup counter');
  finally
    FLock.Leave;
  end;
end;

procedure TGoWaitGroup.Done;
begin
  Add(-1);
end;

procedure TGoWaitGroup.Wait;
begin
  FLock.Enter;
  try
	if FCount = 0 then Exit;
  finally
	FLock.Leave;
  end;
  FEvent.WaitFor(INFINITE);
end;

{ TGo }

class procedure TGo.Run(const Proc: TProc);
begin
  TTask.Run(Proc);
end;

initialization
  // Default to Go-like behavior (no exceptions on close during send)
  TGoChannel<Integer>.StrictChannelExceptions := False;
  TGoChannel<String>.StrictChannelExceptions := False;

end.
