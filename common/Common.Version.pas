unit Common.Version;

interface

uses
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
