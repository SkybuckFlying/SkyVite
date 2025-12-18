unit Monitor.Monitor.Test;

interface

uses
  DUnitX.TestFramework,
  Monitor.Monitor,
  Monitor.Ntp,
  Monitor.Ring,
  Monitor.Ring.Test;

type
  [TestFixture]
  TMonitorTests = class(TObject)
  public
    [Test]
    procedure TestMonitor;
  end;

implementation

uses
  System.Diagnostics,
  System.Threading;

{ TMonitorTests }

procedure TMonitorTests.TestMonitor;
var
  vStopwatch: TStopwatch;
begin
  // record the number of times event happened
  Monitor.Monitor.LogEvent('pool', 'insert');

  // record the time taken by sth
  vStopwatch := TStopwatch.StartNew;
  TThread.Sleep(100);
  Monitor.Monitor.LogTime('pool', 'insertTime1', vStopwatch);

  vStopwatch.Restart;
  TThread.Sleep(200);
  Monitor.Monitor.LogTime('pool', 'insertTime2', vStopwatch);

  // record average
  Monitor.Monitor.LogDuration('pool', 'insertDuration', 2000);

  // Allow some time for the background task to process the logs
  TThread.Sleep(1500);

  // You can add assertions here to check the statistics,
  // but since the loop runs in the background, it's hard to get deterministic results.
  // For example:
  // Assert.IsTrue(Pos('insert', Monitor.Monitor.StatJson) > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TMonitorTests);
end.
