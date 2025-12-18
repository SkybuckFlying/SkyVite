unit Common.CondTimeout;

interface

uses
  Common.Bytes,
  Common.Bytes.Test,
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
  Common.Version,
  GoToDelphi.Helpers.TChannel,
  System.SysUtils;

const
  ConstTimeoutErr = 'timeout';

type
  ICondTimeout = interface
    ['{B5A5A03B-3B79-4A4A-9D7A-7A3B3B5A5A03}']
    procedure Wait;
    function WaitTimeout(const ParaTimeout: Cardinal): Boolean;
    procedure Broadcast;
    procedure Signal;
    function GetLocker: TObject;
    property Locker: TObject read GetLocker;
  end;

function NewTimeoutCond: ICondTimeout;

implementation

uses
  System.SyncObjs,
  System.Threading;

type
  TCondTimeout = class(TInterfacedObject, ICondTimeout)
  private
    mNotifyNum: Integer;
    mLocker: TCriticalSection;
    mSignal: TChannel<Byte>;
    function GetLocker: TObject;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Wait;
    function WaitTimeout(const ParaTimeout: Cardinal): Boolean;
    procedure Broadcast;
    procedure Signal;
  end;

function NewTimeoutCond: ICondTimeout;
begin
  Result := TCondTimeout.Create;
end;

{ TCondTimeout }

constructor TCondTimeout.Create;
begin
  inherited Create;
  try
    mLocker := TCriticalSection.Create;
    mSignal := TChannel<Byte>.Create;
  except
    on E: EOutOfMemory do
    begin
      if Assigned(mLocker) then
      begin
        mLocker.Free;
      end;
      raise;
    end;
  end;
end;

destructor TCondTimeout.Destroy;
begin
  if Assigned(mLocker) then
  begin
    mLocker.Free;
  end;
  if Assigned(mSignal) then
  begin
    mSignal.Free;
  end;
  inherited Destroy;
end;

function TCondTimeout.GetLocker: TObject;
begin
  Result := mLocker;
end;

procedure TCondTimeout.Wait;
var
  vOld: Integer;
  vValue: Byte;
  vChannel: TChannel<Byte>;
begin
  vOld := TInterlocked.Exchange(mNotifyNum, 0);
  if vOld > 0 then
  begin
    Exit;
  end;

  mLocker.Acquire;
  try
    vChannel := mSignal;
  finally
    mLocker.Release;
  end;

  vChannel.Receive(vValue);
end;

function TCondTimeout.WaitTimeout(const ParaTimeout: Cardinal): Boolean;
var
  vOld: Integer;
  vValue: Byte;
  vChannel: TChannel<Byte>;
begin
  vOld := TInterlocked.Exchange(mNotifyNum, 0);
  if vOld > 0 then
  begin
    Result := True;
    Exit;
  end;

  mLocker.Acquire;
  try
    vChannel := mSignal;
  finally
    mLocker.Release;
  end;

  Result := vChannel.TryReceive(vValue, ParaTimeout);
end;

procedure TCondTimeout.Broadcast;
var
  vOldSignal: TChannel<Byte>;
begin
  TInterlocked.Increment(mNotifyNum);
  mLocker.Acquire;
  try
    vOldSignal := mSignal;
    mSignal := TChannel<Byte>.Create;
    vOldSignal.Close;
  finally
    mLocker.Release;
  end;
end;

procedure TCondTimeout.Signal;
begin
  TInterlocked.Increment(mNotifyNum);
  mLocker.Acquire;
  try
    mSignal.TrySend(1);
  finally
    mLocker.Release;
  end;
end;

end.
