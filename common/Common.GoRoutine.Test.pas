unit Common.Goroutine.Test;

interface

uses
  Common.Bytes,
  Common.Bytes.Test,
  Common.Condtimeout,
  Common.Condtimeout.Test,
  Common.Condtimer,
  Common.Condtimer.Test,
  Common.Default.Params,
  Common.Goroutine,
  Common.Lifecycle,
  Common.Lock,
  Common.Lock.Test,
  Common.Log,
  Common.Mock,
  Common.Mock.Test,
  Common.Utils,
  Common.Version,
  DUnitX.TestFramework,
  System.SysUtils,
  System.Threading;

type
	[TestFixture]
	TGoroutineTests = class(TObject)
	private
		type
			PTestRecord = ^TTestRecord;
			TTestRecord = record
				mData : string;
			end;
	public
		[Test]
		procedure TestGoExecutesProcedure;
		[Test]
		procedure TestGoCatchesAndPropagatesException;
		[Test]
		procedure TestGoHandlesNilPointerAccess;
	end;

implementation

{ TGoroutineTests }

procedure TGoroutineTests.TestGoExecutesProcedure;
var
	vEvent : TEvent;
	vTask : ITask;
begin
	// Arrange
	vEvent := TEvent.Create;

	// Act
	// We run the 'Go' call inside a task to wait for its completion.
	vTask := TTask.Run(
		procedure
		begin
			Go(
				procedure
				begin
					vEvent.SetEvent;
				end
				);
		end);

	// Assert
	Assert.IsTrue(vEvent.WaitFor(1000), 'The procedure passed to Go should be executed.');
	vTask.Wait; // Cleanup
end;

procedure TGoroutineTests.TestGoCatchesAndPropagatesException;
var
	vTask : ITask;
	vExceptionCaught : Boolean;
const
	ConstTestExceptionMessage = 'Test Panic';
begin
	// Arrange
	vExceptionCaught := False;

	// Act
	vTask := TTask.Run(
		procedure
		begin
			Go(
				procedure
				begin
					raise EAssertionFailed.Create(ConstTestExceptionMessage);
				end
				);
		end);

	try
	begin
		vTask.Wait;
	end;
	except
		on E : EAggregateException do
		begin
			Assert.AreEqual(1, E.InnerExceptions.Count, 'There should be one inner exception.');
			Assert.IsInstanceOf(EAssertionFailed, E.InnerExceptions[0], 'The exception type should be preserved.');
			Assert.AreEqual(ConstTestExceptionMessage, E.InnerExceptions[0].Message, 'The exception message should match.');
			vExceptionCaught := True;
		end;
	end;

	// Assert
	Assert.IsTrue(vExceptionCaught, 'The exception from the Go procedure should have been caught and propagated.');
end;

procedure TGoroutineTests.TestGoHandlesNilPointerAccess;
var
	vTask : ITask;
	vExceptionCaught : Boolean;
	vNilRecord : PTestRecord;
begin
	// Arrange
	vExceptionCaught := False;
	vNilRecord := nil;

	// Act
	vTask := TTask.Run(
		procedure
		begin
			Go(
				procedure
				begin
					// This will cause an access violation (nil pointer dereference)
					vNilRecord^.mData := 'crash';
				end
				);
		end);

	try
	begin
		vTask.Wait;
	end;
	except
		on E : EAggregateException do
		begin
			Assert.AreEqual(1, E.InnerExceptions.Count, 'There should be one inner exception.');
			Assert.IsInstanceOf(EAccessViolation, E.InnerExceptions[0], 'The exception should be an Access Violation.');
			vExceptionCaught := True;
		end;
	end;

	// Assert
	Assert.IsTrue(vExceptionCaught, 'The nil pointer access should have been caught and propagated as an exception.');
end;

initialization
	TDUnitX.RegisterTestFixture(TGoroutineTests);
end.
