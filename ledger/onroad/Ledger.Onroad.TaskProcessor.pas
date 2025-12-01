unit taskprocessor;

interface

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Threading,
  Vite.Common, Vite.Ledger, Vite.Interfaces, Vite.Generator, Vite.Vm.Quota,
  onroad.contract, onroad.task_pqueue;

type
  TContractTaskProcessor = class
  private
    FTaskID: Integer;
    FWorker: TContractWorker;
    FLog: TLogger;
    procedure ProcessOneAddress(task: TContractTask): Boolean;
    procedure RestrictContract(addr: TAddress; state: TInferiorState);
  public
    constructor Create(worker: TContractWorker; index: Integer);
    procedure Work;
  end;

implementation

{ TContractTaskProcessor }

constructor TContractTaskProcessor.Create(worker: TContractWorker; index: Integer);
begin
  inherited Create;
  FTaskID := index;
  FWorker := worker;
  FLog := TSlog.New('tp', index);
end;

procedure TContractTaskProcessor.Work;
var
  task: TContractTask;
  canContinue: Boolean;
begin
  FWorker.Wg.Add;
  try
    FLog.Info('work() t');
    while True do
    begin
      if FWorker.IsCancel then
      begin
        FLog.Info('found cancel true');
        Break;
      end;
      task := FWorker.PopContractTask;
      if task <> nil then
      begin
        TSignalLog.Info(Format('tp=%d wakeup, pop addr %s quota %d', [FTaskID, string(task.Addr), task.Quota]));
        if FWorker.IsContractInBlackList(task.Addr) or not FWorker.AddContractIntoWorkingList(task.Addr) then
          Continue;
        canContinue := ProcessOneAddress(task);
        FWorker.RemoveContractFromWorkingList(task.Addr);
        if canContinue then
        begin
          task.Quota := FWorker.GetStakeQuota(task.Addr);
          FWorker.PushContractTask(task);
        end;
        Continue;
      end;
      if FWorker.IsCancel then
      begin
        FLog.Info('found cancel true');
        Break;
      end;
      FWorker.NewBlockCond.WaitFor(TTimeSpan.FromMilliseconds(FTaskID * 2 + 500));
    end;
    FLog.Info('work end t');
  finally
    FWorker.Wg.Done;
  end;
end;

procedure TContractTaskProcessor.ProcessOneAddress(task: TContractTask): Boolean;
var
  sBlock: TAccountBlock;
  blog: TLogger;
  completeBlockHash: PHash;
  completeBlockHeight: UInt64;
  completeBlock: TAccountBlock;
  addrState: PEnvPrepareForGenerator;
  gen: IGenerator;
  genResult: IGenResult;
  q: TQuota;
  quotaSatisfyRetry: Boolean;
  snapshotHeightWaited: Integer;
begin
  FLog.Info('process', 'contract', task.Addr);
  sBlock := FWorker.AcquireOnRoadBlocks(task.Addr);
  if sBlock = nil then
  begin
    Result := False;
    Exit;
  end;
  blog := FLog.New('s', sBlock.Hash, 'caller', sBlock.AccountAddress, 'contract', task.Addr);

  completeBlockHash := nil;
  completeBlockHeight := sBlock.Height;
  if task.Addr.IsContractAddr then
  begin
    completeBlock := FWorker.Manager.Chain.GetCompleteBlockByHash(sBlock.Hash);
    if completeBlock = nil then
    begin
      blog.Error('GetCompleteBlockByHash failed');
      Result := True;
      Exit;
    end;
    completeBlockHash := @completeBlock.Hash;
    completeBlockHeight := completeBlock.Height;
  end;

  addrState := GetAddressStateForGenerator(FWorker.Manager.Chain, @task.Addr);
  if addrState = nil then
  begin
    blog.Error('failed to get contract state for generator');
    Result := True;
    Exit;
  end;

  if not FWorker.VerifyConfirmedTimes(@task.Addr, @sBlock.Hash, addrState.LatestSnapshotHeight) then
  begin
    blog.Info('verifyConfirmedTimes failed');
    FWorker.RestrictContractCaller(task.Addr, sBlock.AccountAddress, isRetry);
    Result := True;
    Exit;
  end;

  FLog.Info(Format('contract-prev: addr=%s hash=%s height=%d', [string(task.Addr), string(addrState.LatestAccountHash^), addrState.LatestAccountHeight]));

  gen := TGenerator.Create(FWorker.Manager.Chain, FWorker.Manager.SbpStatReader, task.Addr, addrState.LatestSnapshotHash, addrState.LatestAccountHash);
  genResult := gen.GenerateWithOnRoad(sBlock, @FWorker.Address, FWorker.Manager.Coinbase.Sign, nil);

  if (genResult = nil) then
  begin
    blog.Error('GenerateWithOnRoad failed');
    if (genResult <> nil) and (genResult.Err.Message = TErrVmRunPanic.Message) then
    begin
      RestrictContract(task.Addr, isRetry);
      Result := False;
      Exit;
    end;
    Result := True;
    Exit;
  end;

  if genResult.Err <> nil then
    blog.Info(Format('vm.Run error, can ignore, err:%s', [genResult.Err.Message]));

  if genResult.VMBlock <> nil then
  begin
    blog.Info(Format('insertBlockToPool %s, s[%s, p(%d,%s)]', [string(genResult.VMBlock.AccountBlock.Hash), string(sBlock.Hash), completeBlockHeight, string(completeBlockHash^)]));
    if not FWorker.Manager.InsertBlockToPool(genResult.VMBlock) then
    begin
      blog.Error('insertContractBlocksToPool failed');
      FWorker.RestrictContractCaller(task.Addr, sBlock.AccountAddress, isOut);
      Result := True;
      Exit;
    end;
    if genResult.IsRetry then
    begin
      blog.Info('impossible situation: vmBlock and vmRetry');
      RestrictContract(task.Addr, isOut);
      Result := False;
      Exit;
    end;
  end
  else
  begin
    if genResult.IsRetry then
    begin
      blog.Info('genResult.IsRetry true');
      if not TAddress.IsBuiltinContractAddrInUseWithoutQuota(task.Addr) then
      begin
        q := FWorker.Manager.Chain.GetStakeQuota(task.Addr);
        if q = nil then
        begin
          blog.Error('failed to get stake quota');
          Result := True;
          Exit;
        end;
        quotaSatisfyRetry := TQuotaChecker.CheckQuota(gen.GetVMDB, q, task.Addr, snapshotHeightWaited);
        if not quotaSatisfyRetry then
        begin
          blog.Info('Check quota is gone to be insufficient', 'snapshotHeightWaited', snapshotHeightWaited, 'quota', Format('(u:%d c:%d sc:%d a:%d sb:%s)', [q.StakeQuotaPerSnapshotBlock, q.Current, q.SnapshotCurrent, q.Avg, string(addrState.LatestSnapshotHash^)]));
          if snapshotHeightWaited >= 3 then
            RestrictContract(task.Addr, isOut)
          else
            RestrictContract(task.Addr, isRetry);
          Result := False;
          Exit;
        end;
      end;
      if genResult.Err <> nil then
      begin
        RestrictContract(task.Addr, isRetry);
        Result := False;
        Exit;
      end;
    end
    else
    begin
      blog.Info(Format('manager.DeleteDirect, contract %s hash %s', [string(task.Addr), string(sBlock.Hash)]));
      FWorker.Manager.DeleteDirect(sBlock);
      RestrictContract(task.Addr, isOut);
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;

procedure TContractTaskProcessor.RestrictContract(addr: TAddress; state: TInferiorState);
begin
  FWorker.RestrictContract(addr, state);
  FLog.Info('restrict contract', 'addr', addr, 'state', state);
end;

end.
