unit Common.Lifecycle;

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
  Common.Lock,
  Common.Lock.Test,
  Common.Log,
  Common.Mock,
  Common.Mock.Test,
  Common.Utils,
  Common.Version,
  System.SysUtils;

const
  // Lifecycle status constants
  ConstStatusOrigin = 0;
  ConstStatusIniting = 1;
  ConstStatusInited = 2;
  ConstStatusStarting = 3;
  ConstStatusStarted = 4;
  ConstStatusStopping = 5;
  ConstStatusStopped = 6;

type
  // TLifecycleStatus provides atomic state management for a component's lifecycle.
  // It is a Delphi translation of Go's LifecycleStatus struct.
  TLifecycleStatus = record
  private
    mStatus: Integer; // 0:origin 1:initing 2:inited 3:starting 4:started 5:stopping 6:stopped
  public
    function PreInit: Boolean;
    function PostInit: Boolean;
    function PreStart: Boolean;
    function PostStart: Boolean;
    function PreStop: Boolean;
    function PostStop: Boolean;
    function Stopped: Boolean;
    function GetStatus: Integer;
  end;

  // ILifecycle defines the standard methods for a component that has a lifecycle.
  ILifecycle = interface
    ['{A8B7C6D5-E4F3-4A2B-8C1D-5E4F3A2B1C0D}']
    procedure Init;
    procedure Start;
    procedure Stop;
    function GetStatus: Integer;
  end;

implementation

uses
  System.SyncObjs;

{ TLifecycleStatus }

function TLifecycleStatus.PreInit: Boolean;
begin
  Result := TInterlocked.CompareExchange(mStatus, ConstStatusIniting, ConstStatusOrigin) = ConstStatusOrigin;
end;

function TLifecycleStatus.PostInit: Boolean;
begin
  Result := TInterlocked.CompareExchange(mStatus, ConstStatusInited, ConstStatusIniting) = ConstStatusIniting;
end;

function TLifecycleStatus.PreStart: Boolean;
begin
  Result := TInterlocked.CompareExchange(mStatus, ConstStatusStarting, ConstStatusInited) = ConstStatusInited;
end;

function TLifecycleStatus.PostStart: Boolean;
begin
  Result := TInterlocked.CompareExchange(mStatus, ConstStatusStarted, ConstStatusStarting) = ConstStatusStarting;
end;

function TLifecycleStatus.PreStop: Boolean;
begin
  Result := TInterlocked.CompareExchange(mStatus, ConstStatusStopping, ConstStatusStarted) = ConstStatusStarted;
end;

function TLifecycleStatus.PostStop: Boolean;
begin
  Result := TInterlocked.CompareExchange(mStatus, ConstStatusStopped, ConstStatusStopping) = ConstStatusStopping;
end;

function TLifecycleStatus.Stopped: Boolean;
var
  vCurrentStatus: Integer;
begin
  vCurrentStatus := TInterlocked.Add(mStatus, 0); // Atomic read
  Result := (vCurrentStatus = ConstStatusStopped) or (vCurrentStatus = ConstStatusStopping);
end;

function TLifecycleStatus.GetStatus: Integer;
begin
  Result := TInterlocked.Add(mStatus, 0); // Atomic read
end;

end.
