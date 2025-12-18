unit Common.GoRoutine;

interface

uses
  Common.Bytes,
  Common.Bytes.Test,
  Common.Condtimeout,
  Common.Condtimeout.Test,
  Common.Condtimer,
  Common.Condtimer.Test,
  Common.Default.Params,
  Common.GoRoutine.Test,
  Common.Lifecycle,
  Common.Lock,
  Common.Lock.Test,
  Common.Log,
  Common.Mock,
  Common.Mock.Test,
  Common.Utils,
  Common.Version,
  System.SysUtils;

type
	TGoProc = reference to procedure;

// Go runs a procedure in a background task with panic/exception handling.
// This is a Delphi equivalent of Go's `go` keyword with a `recover` block.
procedure Go(const ParaFn: TGoProc);

implementation

uses
	System.Threading,
	Log15,
	Log15.Root;

var
	glog: ILogger;

// wrap executes the given procedure and catches any exceptions (panics).
procedure wrap(const ParaFn: TGoProc);
begin
	try
		ParaFn;
	except
		on E: Exception do
		begin
			// Log the error with stack trace.
			if Assigned(glog) then
			begin
				glog.Error('panic', ['err', E.Message, 'withstack', E.StackTrace]);
			end;

			// Re-raise the exception. This causes the TTask to enter a Faulted state.
			raise;
		end;
	end;
end;

procedure Go(const ParaFn: TGoProc);
begin
	TTask.Run(
		procedure
		begin
			wrap(ParaFn);
		end);
end;

initialization
	try
		glog := Log15.Root.New(['module', 'error']);
	except
		// If logger initialization fails, glog will be nil.
		glog := nil;
	end;

end.
