unit Common.Version;

interface

uses
  Common.Bytes,
  Common.Bytes.Test,
  Common.Condtimeout,
  Common.Condtimeout.Test,
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
  System.SysUtils;

type
  // TVersion provides a simple, thread-safe version counter.
  TVersion = record
  private
    mVersion: UInt64;
  public
    procedure Inc;
    function Val: UInt64;
  end;

implementation

uses
  System.SyncObjs;

{ TVersion }

procedure TVersion.Inc;
begin
  TInterlocked.Increment(mVersion);
end;

function TVersion.Val: UInt64;
begin
  Result := TInterlocked.Read(mVersion);
end;

end.
