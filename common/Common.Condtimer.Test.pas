unit Common.CondTimer.Test;

interface

uses
	System.SysUtils,
	System.Threading,
	System.Diagnostics,
	DUnitX.TestFramework,
	Common.CondTimer;

type
	[TestFixture]
	TCondTimerTests = class(TObject)
	public
		[Test]
		procedure TestTimerWakesWaiter;
		[Test]
		procedure TestStopReleasesWaiter;
		[Test]
		procedure TestTimerDoesNotSignalAfterStop;
		[Test]
		procedure TestMultipleWaitersReleasedOnStop;
	end;

implementation

{ TCondTimerTests }

procedure TCondTimerTests.TestTimerWakesWaiter;
var
	vCondTimer : ICondTimer;
	vTask : ITask;
	vWasSignaled : Boolean;
	vStopwatch : TStopwatch;
begin
	// Arrange
	vCondTimer := NewCondTimer;
	vWasSignaled := False;

	// Act
	vTask := TTask.Run(
		procedure
		begin
			vCondTimer.Wait;
			vWasSignaled := True;
		end);

	vStopwatch := TStopwatch.StartNew;
	vCondTimer.Start(100); // Start a timer that signals every 100ms
	vTask.Wait(1000); // Wait for the task to complete, with a timeout
	vStopwatch.Stop;
	vCondTimer.Stop;

	// Assert
	Assert.IsTrue(vWasSignaled, 'The waiting task should have been signaled by the timer.');
	Assert.IsTrue(vStopwatch.ElapsedMilliseconds >= 100, 'Elapsed time should be at least the timer interval.');
end;

procedure TCondTimerTests.TestStopReleasesWaiter;
var
	vCondTimer : ICondTimer;
	vTask : ITask;
	vWaitStartedEvent : TEvent;
	vWasReleased : Boolean;
begin
	// Arrange
	vCondTimer := NewCondTimer;
	vWasReleased := False;
	vWaitStartedEvent := TEvent.Create;

	// Act
	vCondTimer.Start(50); // Start a fast timer

	vTask := TTask.Run(
		procedure
		begin
			vWaitStartedEvent.SetEvent;
			vCondTimer.Wait; // This should be woken up by Stop's broadcast
			vWasReleased := True;
		end);

	vWaitStartedEvent.WaitFor(500); // Ensure the task is in the Wait call
	TThread.Sleep(120); // Let the timer run a couple of times

	vCondTimer.Stop; // This should release the waiting task
	vTask.Wait(500);

	// Assert
	Assert.IsTrue(vWasReleased, 'The waiting task should be released when the timer is stopped.');
end;

procedure TCondTimerTests.TestTimerDoesNotSignalAfterStop;
var
	vCondTimer : ICondTimer;
	vTask : ITask;
	vWasSignaled : Boolean;
begin
	// Arrange
	vCondTimer := NewCondTimer;
	vWasSignaled := False;

	// Act
	vCondTimer.Start(50);
	TThread.Sleep(120); // Let it run
	vCondTimer.Stop;

	// Now that it's stopped, wait and see if we get a signal (we shouldn't)
	vTask := TTask.Run(
		procedure
		begin
			vCondTimer.Wait; // This should block
			vWasSignaled := True;
		end);

	vTask.Wait(200); // Wait for a short period

	// Assert
	Assert.IsFalse(vWasSignaled, 'The timer should not signal after being stopped.');

	// Cleanup: signal the task to unblock it for a clean exit
	vCondTimer.Signal;
	vTask.Wait(100);
end;

procedure TCondTimerTests.TestMultipleWaitersReleasedOnStop;
var
	vCondTimer : ICondTimer;
	vTasks : TArray<ITask>;
	vReleaseCount : Integer;
	vIndex : Integer;
begin
	// Arrange
	vCondTimer := NewCondTimer;
	vReleaseCount := 0;
	SetLength(vTasks, 5);

	// Act
	vCondTimer.Start(100);

	for vIndex := 0 to High(vTasks) do
	begin
		vTasks[vIndex] := TTask.Run(
			procedure
			begin
				vCondTimer.Wait;
				TInterlocked.Increment(vReleaseCount);
			end);
	end;

	TThread.Sleep(250); // Let some timer signals pass
	vCondTimer.Stop; // This should release all waiters

	TTask.WaitForAll(vTasks, 1000);

	// Assert
	Assert.AreEqual(Length(vTasks), vReleaseCount, 'All waiting tasks should have been released by Stop.');
end;

initialization
	TDUnitX.RegisterTestFixture(TCondTimerTests);
end.