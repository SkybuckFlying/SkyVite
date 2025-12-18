unit Tools.Queue.Queue;

interface

uses
  Common.CondTimeout,
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  Tools.List.List,
  Tools.Queue.Queue.Test;

type
  IQueue = interface
    ['{F1F2F3F4-F5F6-F7F8-F9FAFBFCFDFE}']
    function Add(V: TObject): Boolean;
    function Poll: TObject;
    function Size: Integer;
    procedure Close;
  end;

  TBlockQueue = class(TInterfacedObject, IQueue)
  private
    FLock: TCriticalSection;
    FCond: ITimeoutCond;
    FList: IList;
    FClosed: Boolean;
    FMax: Integer;
  public
    constructor Create(AMax: Integer);
    destructor Destroy; override;
    function Add(V: TObject): Boolean;
    function Poll: TObject;
    function Size: Integer;
    procedure Close;
  end;

function NewBlockQueue(AMax: Integer): IQueue;

implementation

{ TBlockQueue }

constructor TBlockQueue.Create(AMax: Integer);
begin
  FLock := TCriticalSection.Create;
  FCond := TTimeoutCond.Create(FLock);
  FList := TList.Create;
  FMax := AMax;
  FClosed := False;
end;

destructor TBlockQueue.Destroy;
begin
  FLock.Free;
  inherited;
end;

function TBlockQueue.Add(V: TObject): Boolean;
begin
  FLock.Enter;
  try
    if not FClosed and (FList.Size < FMax) then
    begin
      FList.Append(V);
      FCond.Signal;
      Result := True;
    end
    else
      Result := False;
  finally
    FLock.Leave;
  end;
end;

function TBlockQueue.Poll: TObject;
begin
  FLock.Enter;
  try
    while (FList.Size = 0) and not FClosed do
    begin
      FCond.Wait;
    end;
    Result := FList.Shift;
  finally
    FLock.Leave;
  end;
end;

function TBlockQueue.Size: Integer;
begin
  FLock.Enter;
  try
    Result := FList.Size;
  finally
    FLock.Leave;
  end;
end;

procedure TBlockQueue.Close;
begin
  FLock.Enter;
  try
    if not FClosed then
    begin
      FClosed := True;
      FCond.Signal;
    end;
  finally
    FLock.Leave;
  end;
end;

function NewBlockQueue(AMax: Integer): IQueue;
begin
  Result := TBlockQueue.Create(AMax);
end;

end.
