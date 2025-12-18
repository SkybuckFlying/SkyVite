unit Common.CondTimeout.Test;

interface

uses
  Common.Bytes,
  Common.Bytes.Test,
  Common.CondTimeout,
  Common.Condtimer,
  Common.Condtimer.Test,
  Common.Default.Params,
  Common.GoRoutine,
  Common.GoRoutine.Test,
  Common.Lifecycle,
  Common.Lock,
  Common.Lock.Test,
  Common.Log,
  Common.Mock,
  Common.Mock.Test,
  Common.Utils,
  Common.Version,
  DUnitX.TestFramework,
  System.Diagnostics,
  System.SysUtils,
  System.Threading;

type
	[TestFixture]
	TCondTimeoutTests = class(TObject)
	public
		[Test]
		procedure TestSignalWakesWaiter;
		[Test]
		procedure TestBroadcastWakesAllWaiters;
		[Test]
		procedure TestWaitTimeoutReturnsFalseOnTimeout;
		[Test]
		procedure TestWaitTimeoutReturnsTrueOnSignal;
		[Test]
		procedure TestWaitTimeoutReturnsTrueOnBroadcast;
		[Test]
		procedure TestWaitAfterSignalReturnsImmediately;
	end;

implementation

{ TCondTimeoutTests }

procedure TCondTimeoutTests.TestSignalWakesWaiter;
var
	vCond: ICondTimeout;
	vTask: ITask;
	vWasSignaled: Boolean;
begin
	vCond := NewTimeoutCond;
	vWasSignaled := False;

	vTask := TTask.Run(
		procedure
		begin
			vCond.Wait;
			vWasSignaled := True;
		end);

	TThread.Sleep(100);
	vCond.Signal;
	vTask.Wait(1000);

	Assert.IsTrue(vWasSignaled, 'The waiting task should have been signaled and completed.');
end;

procedure TCondTimeoutTests.TestBroadcastWakesAllWaiters;
var
	vCond: ICondTimeout;
	vTasks: TArray<ITask>;
	vSignalCount: Integer;
	vIndex: Integer;
begin
	vCond := NewTimeoutCond;
	vSignalCount := 0;
	SetLength(vTasks, 5);

	for vIndex := 0 to High(vTasks) do
	begin
		vTasks[vIndex] := TTask.Run(
			procedure
			begin
				vCond.Wait;
				TInterlocked.Increment(vSignalCount);
			end);
	end;

	TThread.Sleep(100);
	vCond.Broadcast;
	TTask.WaitForAll(vTasks, 2000);

	Assert.AreEqual(Length(vTasks), vSignalCount, 'All waiting tasks should have been woken by Broadcast.');
end;

procedure TCondTimeoutTests.TestWaitTimeoutReturnsFalseOnTimeout;
var
	vCond: ICondTimeout;
	vStopwatch: TStopwatch;
	vResult: Boolean;
begin
	vCond := NewTimeoutCond;

	vStopwatch := TStopwatch.StartNew;
	vResult := vCond.WaitTimeout(200);
	vStopwatch.Stop;

	Assert.IsFalse(vResult, 'WaitTimeout should return False when no signal occurs.');
	Assert.IsTrue(vStopwatch.ElapsedMilliseconds >= 200, 'Elapsed time should be at least the timeout value.');
end;

procedure TCondTimeoutTests.TestWaitTimeoutReturnsTrueOnSignal;
var
	vCond: ICondTimeout;
	vTask: ITask;
	vResult: Boolean;
begin
	vCond := NewTimeoutCond;
	vResult := True;

	vTask := TTask.Run(
		procedure
		begin
			TThread.Sleep(50);
			vCond.Signal;
		end);

	vResult := vCond.WaitTimeout(500);
	vTask.Wait;

	Assert.IsTrue(vResult, 'WaitTimeout should return True when a signal occurs.');
end;

procedure TCondTimeoutTests.TestWaitTimeoutReturnsTrueOnBroadcast;
var
	vCond: ICondTimeout;
	vTask: ITask;
	vResult: Boolean;
begin
	vCond := NewTimeoutCond;
	vResult := True;

	vTask := TTask.Run(
		procedure
		begin
			TThread.Sleep(50);
			vCond.Broadcast;
		end);

	vResult := vCond.WaitTimeout(500);
	vTask.Wait;

	Assert.IsTrue(vResult, 'WaitTimeout should return True when a broadcast occurs.');
end;

procedure TCondTimeoutTests.TestWaitAfterSignalReturnsImmediately;
var
	vCond: ICondTimeout;
	vStopwatch: TStopwatch;
begin
	vCond := NewTimeoutCond;

	vCond.Signal;
	vStopwatch := TStopwatch.StartNew;
	vCond.Wait;
	vStopwatch.Stop;

	Assert.IsTrue(vStopwatch.ElapsedMilliseconds < 50, 'Wait after a signal should return almost immediately.');
end;

initialization
	TDUnitX.RegisterTestFixture(TCondTimeoutTests);
end.
