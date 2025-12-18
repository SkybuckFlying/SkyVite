unit Tools.Queue.Queue.Test;

interface

uses
  DUnitX.TestFramework,
  GoToDelphi.Helpers.TChannel,
  System.Classes,
  System.Diagnostics,
  System.SysUtils,
  System.Threading,
  Tools.Queue.Queue;

type
  [TestFixture]
  TBlockQueueTests = class(TObject)
  public
    [Test]
    procedure TestBlockQueue_Add;
    [Test]
    procedure TestBlockQueue_Poll;
    [Test]
    procedure TestBlockQueue_Close;
    [Test]
    [Benchmark]
    procedure BenchmarkBlockQueue;
    [Test]
    [Benchmark]
    procedure BenchmarkChannel;
  end;

implementation

{ TBlockQueueTests }

procedure TBlockQueueTests.TestBlockQueue_Add;
const
  Total = 50;
var
  Q: IQueue;
  Tasks: array of ITask;
  Lock: TCriticalSection;
  I: Integer;
  K: Integer;
begin
  Q := NewBlockQueue(Total);
  Lock := TCriticalSection.Create;
  try
    I := 0;
    SetLength(Tasks, 5);
    for K := 0 to 4 do
    begin
      Tasks[K] := TTask.Run(procedure
      begin
        while True do
        begin
          Lock.Enter;
          try
            if I < Total then
            begin
              if not Q.Add(TObject(I)) then
                Fail('should add success');
              Inc(I);
            end
            else
              Break;
          finally
            Lock.Leave;
          end;
        end;
      end);
    end;
    TTask.WaitForAll(Tasks);

    Assert.AreEqual(Total, Q.Size, 'wrong size');

    if Q.Add(TObject(I)) then
      Fail('should add fail, because queue is full');
  finally
    Lock.Free;
  end;
end;

procedure TBlockQueueTests.TestBlockQueue_Poll;
const
  Total = 5;
var
  Q: IQueue;
  BlockTimeout: TTimeSpan;
  BlockedTime: TDateTime;
  V: TObject;
begin
  Q := NewBlockQueue(Total);
  BlockTimeout := TTimeSpan.FromSeconds(2);
  BlockedTime := Now;

  TTask.Run(procedure
  begin
    TThread.Sleep(BlockTimeout.TotalMilliseconds.Trunc);
    Q.Add(TObject(2));
    Q.Add(TObject(1));
  end);

  V := Q.Poll;

  Assert.IsTrue((Now - BlockedTime) * MSecsPerDay >= BlockTimeout.TotalMilliseconds, 'Poll did not block long enough');
  Assert.AreEqual(2, Integer(V), 'wrong value polled');
end;

procedure TBlockQueueTests.TestBlockQueue_Close;
const
  Total = 5;
var
  Q: IQueue;
  Pending: TChannel<Byte>;
begin
  Q := NewBlockQueue(Total);
  Pending := TChannel<Byte>.Create;
  try
    TTask.Run(procedure
    begin
      Q.Poll;
      Pending.Send(0);
    end);

    TTask.Run(procedure
    begin
      Q.Close;
    end);

    Pending.Receive;
  finally
    Pending.Free;
  end;
end;

procedure TBlockQueueTests.BenchmarkBlockQueue;
const
  Total = 10;
var
  Q: IQueue;
  Amount: Integer;
  I: Integer;
begin
  Q := NewBlockQueue(Total);
  Amount := 0;
  for I := 0 to 1000 - 1 do
  begin
    Q.Add(TObject(I));
    Amount := Amount + Integer(Q.Poll);
  end;
end;

procedure TBlockQueueTests.BenchmarkChannel;
const
  Total = 10;
var
  Channel: TChannel<TObject>;
  Amount: Integer;
  I: Integer;
begin
  Channel := TChannel<TObject>.Create(Total);
  try
    Amount := 0;
    for I := 0 to 1000 - 1 do
    begin
      Channel.Send(TObject(I));
      Amount := Amount + Integer(Channel.Receive);
    end;
  finally
    Channel.Free;
  end;
end;

end.
