unit contract;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  Vite.Common, Vite.Ledger, Vite.Interfaces, Vite.Producer, onroad.pool, big_int;

type
  TContractWorker = class
  private
    FAddress: TAddress;
    FManager: TManager;
    FGid: TGid;
    FContractAddressList: TArray<TAddress>;
    FStatus: Integer;
    FStatusMutex: TMutex;
    FIsCancel: Boolean;
    FNewBlockCond: TCondition;
    FWg: TCountdownEvent;
    FContractTaskProcessors: TArray<TContractTaskProcessor>;
    FBlackList: TDictionary<TAddress, TInferiorState>;
    FBlackListMutex: TRTLCriticalSection;
    FWorkingAddrList: TDictionary<TAddress, Boolean>;
    FWorkingAddrListMutex: TRTLCriticalSection;
    FContractTaskPQueue: TContractTaskPQueue;
    FCtpMutex: TRTLCriticalSection;
    FSelectivePendingCache: TDictionary<TAddress, TCallerPendingMap>;
    FLog: TLogger;
    procedure GetAndSortAllAddrQuota;
    procedure WakeupOneTp;
    procedure WakeupAllTps;
    procedure PushContractTask(t: TContractTask);
    function PopContractTask: TContractTask;
    procedure ClearWorkingAddrList;
    procedure ClearSelectiveBlocksCache;
    function AddContractIntoWorkingList(addr: TAddress): Boolean;
    procedure RemoveContractFromWorkingList(addr: TAddress);
    procedure ClearContractBlackList;
    procedure RestrictContract(addr: TAddress; state: TInferiorState);
    function IsContractInBlackList(addr: TAddress): Boolean;
    function ReleaseContract(addr: TAddress): Boolean;
    function AcquireOnRoadBlocks(contractAddr: TAddress): TAccountBlock;
    procedure RestrictContractCaller(contract, caller: TAddress; state: TInferiorState);
    function ReleaseContractCallers(contract: TAddress; state: TInferiorState): Integer;
    function VerifyConfirmedTimes(contractAddr: PAddress; fromHash: PHash; sbHeight: UInt64): Boolean;
  public
    constructor Create(manager: TManager);
    destructor Destroy; override;
    procedure Start(accEvent: TAccountStartEvent);
    procedure Stop;
    function Close: Boolean;
    function Status: Integer;
    function GetStakeQuota(addr: TAddress): UInt64;
    function GetStakeQuotas(beneficialList: TArray<TAddress>): TDictionary<TAddress, UInt64>;
  end;

implementation

{ TContractWorker }

constructor TContractWorker.Create(manager: TManager);
var
  i: Integer;
begin
  inherited Create;
  FManager := manager;
  FStatus := csCreate;
  FIsCancel := False;
  FNewBlockCond := TCondition.Create;
  FWg := TCountdownEvent.Create;
  FBlackList := TDictionary<TAddress, TInferiorState>.Create;
  InitializeCriticalSection(FBlackListMutex);
  FWorkingAddrList := TDictionary<TAddress, Boolean>.Create;
  InitializeCriticalSection(FWorkingAddrListMutex);
  FContractTaskPQueue := TContractTaskPQueue.Create;
  InitializeCriticalSection(FCtpMutex);
  FSelectivePendingCache := TDictionary<TAddress, TCallerPendingMap>.Create;
  FLog := TSlog.New('worker', 'contract');
  SetLength(FContractTaskProcessors, ContractTaskProcessorSize);
  for i := 0 to High(FContractTaskProcessors) do
    FContractTaskProcessors[i] := TContractTaskProcessor.Create(Self, i);
end;

destructor TContractWorker.Destroy;
var
  processor: TContractTaskProcessor;
begin
  for processor in FContractTaskProcessors do
    processor.Free;
  FNewBlockCond.Free;
  FWg.Free;
  FBlackList.Free;
  DeleteCriticalSection(FBlackListMutex);
  FWorkingAddrList.Free;
  DeleteCriticalSection(FWorkingAddrListMutex);
  FContractTaskPQueue.Free;
  DeleteCriticalSection(FCtpMutex);
  FSelectivePendingCache.Free;
  inherited;
end;

procedure TContractWorker.Start(accEvent: TAccountStartEvent);
var
  addressList: TArray<TAddress>;
  log: TLogger;
  addr: TAddress;
  q: UInt64;
  c: TContractTask;
  pendingTask: TArray<TContractTask>;
  count: Integer;
  pushContractTask: Boolean;
  callerCount: Integer;
  sortedTask: TArray<TContractTask>;
  task: TContractTask;
  v: TContractTaskProcessor;
begin
  FGid := accEvent.Gid;
  FAddress := accEvent.Address;
  FLog := TSlog.New('worker', 'contract', 'gid', accEvent.Gid);
  log := FLog.New('method', 'start');
  log.Info('Start() status=' + IntToStr(FStatus));
  FStatusMutex.Acquire;
  try
    if FStatus <> csStart then
    begin
      FIsCancel := False;
      addressList := FManager.Chain.GetContractList(FGid);
      if Length(addressList) = 0 then
      begin
        FLog.Info('newContractWorker addressList nil');
        Exit;
      end;
      FContractAddressList := addressList;
      log.Info(Format('get addresslist len %d', [Length(addressList)]));
      GetAndSortAllAddrQuota;
      log.Info(Format('getAndSortAllAddrQuota len %d', [FContractTaskPQueue.Count]));
      log.Info('addContractLis', 'gid', FGid, 'event', 'accountEvent');
      FManager.AddContractLis(FGid,
        procedure(address: TAddress)
        begin
          if IsContractInBlackList(address) then
            Exit;
          q := GetStakeQuota(address);
          c := TContractTask.Create;
          c.Addr := address;
          c.Quota := q;
          if not FIsCancel then
          begin
            PushContractTask(c);
            TSignalLog.Info(Format('signal to %s and wake it up', [string(address)]), 'event', 'accountEvent');
            WakeupOneTp;
          end;
        end);
      log.Info('addSnapshotEventLis', 'gid', FGid, 'event', 'snapshotEvent');
      FManager.AddSnapshotEventLis(FGid,
        procedure(latestHeight: UInt64)
        begin
          SetLength(pendingTask, Length(FContractAddressList));
          count := 0;
          for addr in FContractAddressList do
          begin
            pushContractTask := ReleaseContract(addr, callerCount);
            if pushContractTask then
            begin
              TSignalLog.Info(Format('release contract %s RETRY callers len %d', [string(addr), callerCount]), 'snapshot', latestHeight, 'event', 'snapshotEvent');
              q := GetStakeQuota(addr);
              pendingTask[count] := TContractTask.Create;
              pendingTask[count].Addr := addr;
              pendingTask[count].Quota := q;
              Inc(count);
            end;
          end;
          SetLength(sortedTask, count);
          System.Array.Copy(pendingTask, sortedTask, count);
          TArray.Sort<TContractTask>(sortedTask,
            function(i, j: TContractTask): Integer
            begin
              if i.Quota > j.Quota then
                Result := -1
              else
                Result := 1;
            end);
          for task in sortedTask do
          begin
            if FIsCancel then
              Break;
            TSignalLog.Info(Format('push contract %s %d', [string(task.Addr), task.Quota]), 'snapshot', latestHeight, 'event', 'snapshotEvent');
            PushContractTask(task);
            WakeupOneTp;
          end;
        end);
      log.Info('start all tp');
      for v in FContractTaskProcessors do
        TThread.CreateAnonymousThread(procedure
        begin
          v.Work;
        end).Start;
      log.Info('end start all tp');
      FStatus := csStart;
    end
    else
      WakeupAllTps;
    FLog.Info('end start');
  finally
    FStatusMutex.Release;
  end;
end;

procedure TContractWorker.Stop;
var
  log: TLogger;
begin
  log := FLog.New('method', 'stop');
  log.Info('Stop() status=' + IntToStr(FStatus));
  FStatusMutex.Acquire;
  try
    if FStatus = csStart then
    begin
      log.Info('removeContractLis', 'gid', FGid, 'event', 'accountEvent');
      FManager.RemoveContractLis(FGid);
      log.Info('removeSnapshotEventLis', 'gid', FGid, 'event', 'snapshotEvent');
      FManager.RemoveSnapshotEventLis(FGid);
      FIsCancel := True;
      FNewBlockCond.BroadcastAll;
      log.Info('stop all task');
      FWg.Wait;
      log.Info('end stop all task');
      ClearContractBlackList;
      ClearWorkingAddrList;
      ClearSelectiveBlocksCache;
      FStatus := csStop;
    end;
    FLog.Info('stopped');
  finally
    FStatusMutex.Release;
  end;
end;

function TContractWorker.Close: Boolean;
begin
  Stop;
  Result := True;
end;

function TContractWorker.Status: Integer;
begin
  FStatusMutex.Acquire;
  try
    Result := FStatus;
  finally
    FStatusMutex.Release;
  end;
end;

procedure TContractWorker.GetAndSortAllAddrQuota;
var
  quotas: TDictionary<TAddress, UInt64>;
  i: Integer;
  addr: TAddress;
  quota: UInt64;
  task: TContractTask;
begin
  quotas := GetStakeQuotas(FContractAddressList);
  SetLength(FContractTaskPQueue, quotas.Count);
  i := 0;
  for addr in quotas.Keys do
  begin
    quota := quotas[addr];
    task := TContractTask.Create;
    task.Addr := addr;
    task.Index := i;
    task.Quota := quota;
    FContractTaskPQueue[i] := task;
    Inc(i);
  end;
  FContractTaskPQueue.Init;
end;

procedure TContractWorker.WakeupOneTp;
begin
  FNewBlockCond.Signal;
end;

procedure TContractWorker.WakeupAllTps;
begin
  FLog.Info('wakeupAllTps');
  FNewBlockCond.BroadcastAll;
end;

procedure TContractWorker.PushContractTask(t: TContractTask);
var
  v: TContractTask;
begin
  EnterCriticalSection(FCtpMutex);
  try
    for v in FContractTaskPQueue do
    begin
      if v.Addr = t.Addr then
      begin
        v.Quota := t.Quota;
        FContractTaskPQueue.Fix(v.Index);
        Exit;
      end;
    end;
    FContractTaskPQueue.Push(t);
  finally
    LeaveCriticalSection(FCtpMutex);
  end;
end;

function TContractWorker.PopContractTask: TContractTask;
begin
  EnterCriticalSection(FCtpMutex);
  try
    if FContractTaskPQueue.Count > 0 then
      Result := FContractTaskPQueue.Pop as TContractTask
    else
      Result := nil;
  finally
    LeaveCriticalSection(FCtpMutex);
  end;
end;

procedure TContractWorker.ClearWorkingAddrList;
begin
  EnterCriticalSection(FWorkingAddrListMutex);
  try
    FWorkingAddrList.Clear;
  finally
    LeaveCriticalSection(FWorkingAddrListMutex);
  end;
end;

procedure TContractWorker.ClearSelectiveBlocksCache;
begin
  FSelectivePendingCache.Clear;
end;

function TContractWorker.AddContractIntoWorkingList(addr: TAddress): Boolean;
var
  result, ok: Boolean;
begin
  EnterCriticalSection(FWorkingAddrListMutex);
  try
    ok := FWorkingAddrList.TryGetValue(addr, result);
    if result and ok then
      Result := False
    else
    begin
      FWorkingAddrList.AddOrSetValue(addr, True);
      Result := True;
    end;
  finally
    LeaveCriticalSection(FWorkingAddrListMutex);
  end;
end;

procedure TContractWorker.RemoveContractFromWorkingList(addr: TAddress);
begin
  EnterCriticalSection(FWorkingAddrListMutex);
  try
    FWorkingAddrList.AddOrSetValue(addr, False);
  finally
    LeaveCriticalSection(FWorkingAddrListMutex);
  end;
end;

procedure TContractWorker.ClearContractBlackList;
begin
  EnterCriticalSection(FBlackListMutex);
  try
    FBlackList.Clear;
  finally
    LeaveCriticalSection(FBlackListMutex);
  end;
end;

procedure TContractWorker.RestrictContract(addr: TAddress; state: TInferiorState);
begin
  EnterCriticalSection(FBlackListMutex);
  try
    FBlackList.AddOrSetValue(addr, state);
  finally
    LeaveCriticalSection(FBlackListMutex);
  end;
  if state = isOut then
    FSelectivePendingCache.Remove(addr);
end;

function TContractWorker.IsContractInBlackList(addr: TAddress): Boolean;
begin
  EnterCriticalSection(FBlackListMutex);
  try
    Result := FBlackList.ContainsKey(addr);
  finally
    LeaveCriticalSection(FBlackListMutex);
  end;
end;

function TContractWorker.ReleaseContract(addr: TAddress): Boolean;
var
  s: TInferiorState;
  ok: Boolean;
  count: Integer;
begin
  EnterCriticalSection(FBlackListMutex);
  try
    ok := FBlackList.TryGetValue(addr, s);
    if ok then
    begin
      if s = isOut then
      begin
        Result := False;
        Exit;
      end;
      if s = isRetry then
        FBlackList.Remove(addr);
    end;
    count := ReleaseContractCallers(addr, isRetry);
    if not ok and (count <= 0) then
    begin
      Result := False;
      Exit;
    end;
    Result := True;
  finally
    LeaveCriticalSection(FBlackListMutex);
  end;
end;

function TContractWorker.AcquireOnRoadBlocks(contractAddr: TAddress): TAccountBlock;
var
  addNewCount: Integer;
  revertHappened: Boolean;
  value: TCallerPendingMap;
  p: TCallerPendingMap;
  blocks: TArray<TAccountBlock>;
  v: TAccountBlock;
  isExist: Boolean;
  sendBlock: TAccountBlock;
  isFront: Boolean;
begin
  addNewCount := 0;
  revertHappened := False;
  if not FSelectivePendingCache.TryGetValue(contractAddr, value) then
  begin
    p := TCallerPendingMap.Create;
    FSelectivePendingCache.Add(contractAddr, p);
    blocks := FManager.GetAllCallersFrontOnRoad(FGid, contractAddr);
    if Length(blocks) <= 0 then
    begin
      Result := nil;
      Exit;
    end;
    for v in blocks do
    begin
      isExist := p.AddPendingMap(v);
      if not isExist then
        Inc(addNewCount);
    end;
  end
  else
  begin
    p := value;
    sendBlock := p.GetOnePending;
    if sendBlock <> nil then
    begin
      isFront := FManager.IsFrontOnRoadOfCaller(FGid, contractAddr, sendBlock.AccountAddress, sendBlock.Hash);
      if isFront then
      begin
        Result := sendBlock;
        Exit;
      end;
      revertHappened := True;
      p.ClearPendingMap;
    end;
    blocks := FManager.GetAllCallersFrontOnRoad(FGid, contractAddr);
    for v in blocks do
    begin
      if p.ExistInInferiorList(v.AccountAddress) then
        Continue;
      isExist := p.AddPendingMap(v);
      if not isExist then
        Inc(addNewCount);
    end;
  end;
  FLog.Info(Format('acquire new %d current %d, revert[%s]', [addNewCount, p.Len, BoolToStr(revertHappened, True)]), 'contract', contractAddr, 'waitSBCallerLen', p.LenOfCallersByState(isRetry));
  Result := p.GetOnePending;
end;

procedure TContractWorker.RestrictContractCaller(contract, caller: TAddress; state: TInferiorState);
var
  value: TCallerPendingMap;
begin
  if FSelectivePendingCache.TryGetValue(contract, value) and (value <> nil) then
    value.AddIntoInferiorList(caller, state);
end;

function TContractWorker.ReleaseContractCallers(contract: TAddress; state: TInferiorState): Integer;
var
  value: TCallerPendingMap;
begin
  if FSelectivePendingCache.TryGetValue(contract, value) and (value <> nil) then
    Result := value.ReleaseCallerByState(state)
  else
    Result := 0;
end;

function TContractWorker.GetStakeQuota(addr: TAddress): UInt64;
var
  quota: TBigInt;
begin
  if TAddress.IsBuiltinContractAddrInUseWithoutQuota(addr) then
  begin
    Result := System.Math.MaxUInt64;
    Exit;
  end;
  FManager.Chain.GetStakeQuota(addr, quota);
  if quota = nil then
    Result := 0
  else
    Result := quota.Current;
end;

function TContractWorker.GetStakeQuotas(beneficialList: TArray<TAddress>): TDictionary<TAddress, UInt64>;
var
  quotas: TDictionary<TAddress, UInt64>;
  commonContractAddressList: TArray<TAddress>;
  addr: TAddress;
  commonQuotas: TDictionary<TAddress, TBigInt>;
  k: TAddress;
  v: TBigInt;
  quotasMap: TDictionary<TAddress, TBigInt>;
begin
  quotas := TDictionary<TAddress, UInt64>.Create;
  if FGid = TAddress.DELEGATE_GID then
  begin
    for addr in beneficialList do
    begin
      if TAddress.IsBuiltinContractAddrInUseWithoutQuota(addr) then
        quotas.Add(addr, System.Math.MaxUInt64)
      else
        commonContractAddressList := commonContractAddressList + [addr];
    end;
    commonQuotas := FManager.Chain.GetStakeQuotas(commonContractAddressList);
    for k in commonQuotas.Keys do
    begin
      v := commonQuotas[k];
      if v = nil then
        Continue;
      quotas.Add(k, v.Current);
    end;
  end
  else
  begin
    quotasMap := FManager.Chain.GetStakeQuotas(beneficialList);
    for k in quotasMap.Keys do
    begin
      v := quotasMap[k];
      if v = nil then
        Continue;
      quotas.Add(k, v.Current);
    end;
  end;
  Result := quotas;
end;

function TContractWorker.VerifyConfirmedTimes(contractAddr: PAddress; fromHash: PHash; sbHeight: UInt64): Boolean;
var
  meta: PContractMeta;
  sendConfirmedTimes: UInt64;
  isSeedCountOk: Boolean;
begin
  meta := FManager.Chain.GetContractMeta(contractAddr^);
  if meta = nil then
    raise Exception.Create('contract meta is nil');
  if meta.SendConfirmedTimes = 0 then
  begin
    Result := True;
    Exit;
  end;
  sendConfirmedTimes := FManager.Chain.GetConfirmedTimes(fromHash^);
  if sendConfirmedTimes < meta.SendConfirmedTimes then
    raise Exception.Create('sendBlock confirmedTimes is not ready');
  if TUpgrade.IsSeedUpgrade(sbHeight) and (meta.SeedConfirmedTimes > 0) then
  begin
    isSeedCountOk := FManager.Chain.IsSeedConfirmedNTimes(fromHash^, meta.SeedConfirmedTimes);
    if not isSeedCountOk then
      raise Exception.Create('sendBlock seed confirmedTimes is not ready');
  end;
  Result := True;
end;

end.
