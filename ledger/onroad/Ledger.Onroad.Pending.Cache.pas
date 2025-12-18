unit pending_cache;

interface

uses
  Ledger.Onroad.Access,
  Ledger.Onroad.Access.Test,
  Ledger.Onroad.Chain.Events,
  Ledger.Onroad.ChainDB.Test,
  Ledger.Onroad.Contract,
  Ledger.Onroad.Contract.Test,
  Ledger.Onroad.Manager,
  Ledger.Onroad.Manager.Test,
  Ledger.Onroad.Pending.Cache.Test,
  Ledger.Onroad.Reader,
  Ledger.Onroad.Reader.Test,
  Ledger.Onroad.Task.Pqueue,
  Ledger.Onroad.Task.Pqueue.Test,
  Ledger.Onroad.TaskProcessor,
  Ledger.Onroad.TaskProcessor.Test,
  Ledger.Onroad.Utils,
  Ledger.Onroad.Utils.Test,
  Ledger.Onroad.Worker,
  System.SysUtils System.Classes System.Generics.Collections System.SyncObjs,
  Vite.Common Vite.Ledger;

const
  DefaultPullCount = 5;

type
  TInferiorState = (isRetry, isOut);

  TCallerPendingMap = class
  private
    FPmap: TDictionary<TAddress, TList<TAccountBlock>>;
    FInferiorList: TDictionary<TAddress, TInferiorState>;
    FAddrMutex: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    function IsPendingMapNotSufficient: Boolean;
    function Len: Integer;
    function GetOnePending: TAccountBlock;
    function AddPendingMap(sendBlock: TAccountBlock): Boolean;
    procedure ClearPendingMap;
    procedure AddIntoInferiorList(caller: TAddress; state: TInferiorState);
    function ReleaseCallerByState(state: TInferiorState): Integer;
    function LenOfCallersByState(state: TInferiorState): Integer;
    function ExistInInferiorList(caller: TAddress): Boolean;
    procedure RemoveFromInferiorList(caller: TAddress);
    function IsInferiorStateRetry(caller: TAddress): Boolean;
    function IsInferiorStateOut(caller: TAddress): Boolean;
  end;

implementation

{ TCallerPendingMap }

constructor TCallerPendingMap.Create;
begin
  inherited Create;
  FPmap := TDictionary<TAddress, TList<TAccountBlock>>.Create;
  FInferiorList := TDictionary<TAddress, TInferiorState>.Create;
  InitializeCriticalSection(FAddrMutex);
end;

destructor TCallerPendingMap.Destroy;
begin
  FPmap.Free;
  FInferiorList.Free;
  DeleteCriticalSection(FAddrMutex);
  inherited;
end;

function TCallerPendingMap.AddPendingMap(sendBlock: TAccountBlock): Boolean;
var
  caller: TAddress;
  value: TList<TAccountBlock>;
  ok: Boolean;
  l: TList<TAccountBlock>;
  pre: TAccountBlock;
begin
  EnterCriticalSection(FAddrMutex);
  try
    caller := sendBlock.AccountAddress;
    ok := FPmap.TryGetValue(caller, value);
    if not ok or (value = nil) then
    begin
      l := TList<TAccountBlock>.Create;
      l.Add(sendBlock);
      FPmap.Add(caller, l);
      Result := False;
      Exit;
    end;

    l := FPmap[caller];
    if l.Count > 0 then
    begin
      pre := l[l.Count - 1];
      if pre.Height = sendBlock.Height then
      begin
        Result := True;
        Exit;
      end;
      if pre.Height < sendBlock.Height then
      begin
        l.Add(sendBlock);
        Result := False;
        Exit;
      end;
    end;
    l.Clear;
    l.Add(sendBlock);
    Result := False;
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

procedure TCallerPendingMap.AddIntoInferiorList(caller: TAddress; state: TInferiorState);
begin
  EnterCriticalSection(FAddrMutex);
  try
    FInferiorList.AddOrSetValue(caller, state);
    FPmap.Remove(caller);
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

procedure TCallerPendingMap.ClearPendingMap;
begin
  EnterCriticalSection(FAddrMutex);
  try
    FPmap.Clear;
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

function TCallerPendingMap.ExistInInferiorList(caller: TAddress): Boolean;
begin
  EnterCriticalSection(FAddrMutex);
  try
    Result := FInferiorList.ContainsKey(caller);
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

function TCallerPendingMap.GetOnePending: TAccountBlock;
var
  list: TList<TAccountBlock>;
  front: TAccountBlock;
begin
  EnterCriticalSection(FAddrMutex);
  try
    for list in FPmap.Values do
    begin
      if list.Count > 0 then
      begin
        front := list[0];
        list.Delete(0);
        Result := front;
        Exit;
      end;
    end;
    Result := nil;
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

function TCallerPendingMap.IsInferiorStateOut(caller: TAddress): Boolean;
var
  state: TInferiorState;
  ok: Boolean;
begin
  EnterCriticalSection(FAddrMutex);
  try
    ok := FInferiorList.TryGetValue(caller, state);
    Result := ok and (state = isOut);
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

function TCallerPendingMap.IsInferiorStateRetry(caller: TAddress): Boolean;
var
  state: TInferiorState;
  ok: Boolean;
begin
  EnterCriticalSection(FAddrMutex);
  try
    ok := FInferiorList.TryGetValue(caller, state);
    Result := ok and (state = isRetry);
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

function TCallerPendingMap.IsPendingMapNotSufficient: Boolean;
var
  count: Integer;
  list: TList<TAccountBlock>;
begin
  EnterCriticalSection(FAddrMutex);
  try
    if FPmap = nil then
    begin
      Result := True;
      Exit;
    end;
    count := 0;
    for list in FPmap.Values do
      count := count + list.Count;
    Result := count < DefaultPullCount;
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

function TCallerPendingMap.Len: Integer;
var
  count: Integer;
  list: TList<TAccountBlock>;
begin
  EnterCriticalSection(FAddrMutex);
  try
    count := 0;
    for list in FPmap.Values do
      count := count + list.Count;
    Result := count;
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

function TCallerPendingMap.LenOfCallersByState(state: TInferiorState): Integer;
var
  count: Integer;
  s: TInferiorState;
begin
  EnterCriticalSection(FAddrMutex);
  try
    count := 0;
    for s in FInferiorList.Values do
    begin
      if s = state then
        Inc(count);
    end;
    Result := count;
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

function TCallerPendingMap.ReleaseCallerByState(state: TInferiorState): Integer;
var
  count: Integer;
  callersToRemove: TList<TAddress>;
  caller: TAddress;
  s: TInferiorState;
begin
  count := 0;
  callersToRemove := TList<TAddress>.Create;
  try
    EnterCriticalSection(FAddrMutex);
    try
      for caller in FInferiorList.Keys do
      begin
        s := FInferiorList[caller];
        if s = state then
        begin
          callersToRemove.Add(caller);
          Inc(count);
        end;
      end;
      for caller in callersToRemove do
        FInferiorList.Remove(caller);
    finally
      LeaveCriticalSection(FAddrMutex);
    end;
  finally
    callersToRemove.Free;
  end;
  Result := count;
end;

procedure TCallerPendingMap.RemoveFromInferiorList(caller: TAddress);
begin
  EnterCriticalSection(FAddrMutex);
  try
    FInferiorList.Remove(caller);
  finally
    LeaveCriticalSection(FAddrMutex);
  end;
end;

end.
