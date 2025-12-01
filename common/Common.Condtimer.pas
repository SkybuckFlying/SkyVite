unit Common.CondTimer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Threading;

type
  ICondTimer = interface
    ['{C2A7B3D8-D8E1-4B3B-A7D8-B3D8C2A7B3D8}']
    procedure Wait;
    procedure Broadcast;
    procedure Signal;
    procedure Start(const ParaInterval: Cardinal);
    procedure Stop;
  end;

function NewCondTimer: ICondTimer;

implementation

uses
  System.SyncObjs;

type
  TCondTimer = class(TInterfacedObject, ICondTimer)
  private
    mCond: TConditionVariable;
    mMutex: TCriticalSection;
    mNotifyNum: Integer;
    mClosedEvent: TEvent;
    mTimerTask: ITask;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Wait;
    procedure Broadcast;
    procedure Signal;
    procedure Start(const ParaInterval: Cardinal);
    procedure Stop;
  end;

function NewCondTimer: ICondTimer;
begin
  Result := TCondTimer.Create;
end;

{ TCondTimer }

constructor TCondTimer.Create;
begin
  inherited Create;
  try
    mMutex := TCriticalSection.Create;
    mCond := TConditionVariable.Create;
    mClosedEvent := TEvent.Create(nil, True, False, '');
  except
    on E: EOutOfMemory do
    begin
      if Assigned(mMutex) then
      begin
        mMutex.Free;
      end;
      if Assigned(mCond) then
      begin
        mCond.Free;
      end;
      raise;
    end;
  end;
end;

destructor TCondTimer.Destroy;
begin
  Stop;
  if Assigned(mMutex) then
  begin
    mMutex.Free;
  end;
  if Assigned(mCond) then
  begin
    mCond.Free;
  end;
  if Assigned(mClosedEvent) then
  begin
    mClosedEvent.Free;
  end;
  inherited Destroy;
end;

procedure TCondTimer.Wait;
var
  vOld: Integer;
begin
  vOld := TInterlocked.Exchange(mNotifyNum, 0);
  if vOld > 0 then
  begin
    Exit;
  end;

  mMutex.Acquire;
  try
    mCond.WaitFor(mMutex, INFINITE);
  finally
    mMutex.Release;
  end;
end;

procedure TCondTimer.Broadcast;
begin
  TInterlocked.Increment(mNotifyNum);
  mCond.WakeAll;
end;

procedure TCondTimer.Signal;
begin
  TInterlocked.Increment(mNotifyNum);
  mCond.Wake;
end;

procedure TCondTimer.Start(const ParaInterval: Cardinal);
begin
  mMutex.Acquire;
  try
    if Assigned(mTimerTask) and (mTimerTask.Status = TTaskStatus.Running) then
    begin
      Exit;
    end;

    mClosedEvent.ResetEvent;

    mTimerTask := TTask.Run(
      procedure
      begin
        while mClosedEvent.WaitFor(ParaInterval) <> wrSignaled do
        begin
          Self.Broadcast;
        end;
      end);
  finally
    mMutex.Release;
  end;
end;

procedure TCondTimer.Stop;
begin
  mMutex.Acquire;
  try
    if Assigned(mClosedEvent) then
    begin
      mClosedEvent.SetEvent;
    end;

    if Assigned(mTimerTask) then
    begin
      mTimerTask.Wait;
      mTimerTask := nil;
    end;
  finally
    mMutex.Release;
  end;

  Broadcast;
end;

end.