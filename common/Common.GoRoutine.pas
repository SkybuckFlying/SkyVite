unit Common.Goroutine;

interface

uses
  System.SysUtils;

type
  TGoProc = reference to procedure;

// Go runs a procedure in a background task with panic/exception handling.
// This is a Delphi equivalent of Go's `go` keyword with a `recover` block.
procedure Go(const ParaFn: TGoProc);

implementation

uses
  System.Threading,
  Log15; // Assuming a Delphi Log15 unit is available

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
        glog.Error('panic', 'err', E.Message, 'withstack', E.StackTrace);
      end;

      // Re-raise the exception. This causes the TTask to enter a Faulted state,
      // which is the correct way to propagate the error.
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
  // In a real application, a logger instance would likely be managed
  // by a dependency injection container or a central service locator.
  // For this direct translation, we initialize it globally.
  try
    glog := NewLogger('module', 'error');
  except
    // If logger initialization fails, glog will be nil, and errors won't be logged.
    glog := nil;
  end;
end.
