unit V2.Ledger.OnRoad.Contract.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  System.SyncObjs,
  V2.Common,
  V2.Common.Types,
  V2.Interfaces.Core,
  V2.Ledger.OnRoad,
  V2.Log15;

type
  TTestChainDb = class;
  TTestContractWorker = class;

  TTestProcessor = class
  private
    FWorker: TTestContractWorker;
    FID: Integer;
    FLog: ILogger;
    procedure Work;
  public
    constructor Create(AWorker: TTestContractWorker; AID: Integer);
  end;

  TTestContractWorker = class
  private
    FChain: TTestChainDb;
    FTestProcessors: TArray<TTestProcessor>;
    FIsCancel: Boolean;
    FStatus: Integer;
    FStatusMutex: TMutex;
    FNewBlockCond: TConditionVariable;
    FWg: TCountdownEvent;
    FBlackList: TDictionary<TAddress, Boolean>;
    FBlackListMutex: TCriticalSection;
    FWorkingAddrList: TDictionary<TAddress, Boolean>;
    FWorkingAddrListMutex: TCriticalSection;
    FTestPendingCache: TDictionary<TAddress, TCallerPendingMap>;
    FContractTaskPQueue: TContractTaskPQueue;
    FCTPMutex: TCriticalSection;
    procedure InitContractTask;
    procedure PushContractTask(ATask: TContractTask);
    function PopContractTask: TContractTask;
    procedure WakeupOneTp;
    procedure WakeupAllTps;
    procedure AddContractIntoWorkingList(AAddr: TAddress): Boolean;
    procedure RemoveContractFromWorkingList(AAddr: TAddress);
    function IsContractInBlackList(AAddr: TAddress): Boolean;
    procedure AddContractIntoBlackList(AAddr: TAddress);
    function AcquireNewOnroadBlocks(AContractAddr: TAddress): IAccountBlock;
    procedure DeletePendingOnroadBlock(AContractAddr: TAddress; ASendBlock: IAccountBlock);
    procedure AddContractCallerToInferiorList(AContract, ACaller: TAddress; AState: TInferiorState);
  public
    constructor Create(AChain: TTestChainDb);
    destructor Destroy; override;
    procedure Work;
    procedure Stop;
  end;

  TTestChainDb = class
  private
    FDB: TDictionary<TAddress, TArray<IAccountBlock>>;
    FQuotaMap: TDictionary<TAddress, TUInt64>;
    FQuotaMutex: TCriticalSection;
    FBlockFn: TProc<TAddress>;
    FBreaker: TEvent;
    procedure WriteOnroad;
    function DeleteOnroad(AContractAddr, ASendHash: THash): Boolean;
    function ModifyQuotaMap_Sub(AAddr: TAddress): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start;
    procedure Stop;
    procedure SetNewSignal(AFunc: TProc<TAddress>);
    function GetOnRoadBlockByAddr(AAddr: TAddress; APageNum, APageCount: Integer): TArray<IAccountBlock>;
    function GetQuotaMap(AAddr: TAddress): TUInt64;
    function CheckQuota(AAddr: TAddress): Boolean;
    function InsertIntoChain(AContractAddr: TAddress; ASendHash: THash): Boolean;
  end;

  [TestFixture]
  TContractTest = class(TObject)
  public
    [Test]
    procedure TestSelectivePendingCache;
  end;

var
  Contract1, Contract2, Contract3: TAddress;
  Caller1, Caller2, Caller3: TAddress;
  ContractList: TArray<TAddress>;
  GeneralList: TArray<TAddress>;
  TestDefaultQuota: TUInt64;
  TestLog: ILogger;
  Signal: ILogger;


implementation

uses System.Math, System.Diagnostics;

{ TContractTest }

procedure TContractTest.TestSelectivePendingCache;
var
  Chain: TTestChainDb;
  Worker: TTestContractWorker;
  WorkerTask: ITask;
begin
  Chain := TTestChainDb.Create;
  Worker := TTestContractWorker.Create(Chain);
  try
    WorkerTask := TTask.Run(procedure
    begin
      Worker.Work;
    end);

    Chain.Start; // This will run for a fixed duration and then stop the worker
  finally
    Worker.Free;
    Chain.Free;
  end;
end;

{ TTestProcessor }

constructor TTestProcessor.Create(AWorker: TTestContractWorker; AID: Integer);
begin
  inherited Create;
  FWorker := AWorker;
  FID := AID;
  FLog := TestLog.New('processor', AID);
end;

procedure TTestProcessor.Work;
var
  ContractTask: TContractTask;
  SendBlock: IAccountBlock;
begin
  FLog.Info('processor start work');
  FWorker.FWg.Add;
  try
    while not FWorker.FIsCancel do
    begin
      FWorker.FStatusMutex.Lock;
      FWorker.FNewBlockCond.WaitFor(FWorker.FStatusMutex);
      FWorker.FStatusMutex.Unlock;

      if FWorker.FIsCancel then Break;

      while True do
      begin
        ContractTask := FWorker.PopContractTask;
        if ContractTask = nil then Break;

        if not FWorker.AddContractIntoWorkingList(ContractTask.Addr) then Continue;

        while True do
        begin
          SendBlock := FWorker.AcquireNewOnroadBlocks(ContractTask.Addr);
          if SendBlock = nil then Break;

          if not FWorker.FChain.CheckQuota(ContractTask.Addr) then
          begin
            FWorker.AddContractIntoBlackList(ContractTask.Addr);
            Break;
          end;

          if FWorker.FChain.InsertIntoChain(ContractTask.Addr, SendBlock.Hash) then
          begin
            FWorker.DeletePendingOnroadBlock(ContractTask.Addr, SendBlock);
          end
          else
          begin
            FWorker.AddContractCallerToInferiorList(ContractTask.Addr, SendBlock.AccountAddress, RETRY);
          end;
        end;
        FWorker.RemoveContractFromWorkingList(ContractTask.Addr);
      end;
    end;
  finally
    FWorker.FWg.Done;
    FLog.Info('processor stop work');
  end;
end;

{ TTestContractWorker }

constructor TTestContractWorker.Create(AChain: TTestChainDb);
var
  I: Integer;
begin
  inherited Create;
  FChain := AChain;
  FTestPendingCache := TDictionary<TAddress, TCallerPendingMap>.Create;
  FBlackList := TDictionary<TAddress, Boolean>.Create;
  FWorkingAddrList := TDictionary<TAddress, Boolean>.Create;
  FStatus := create;
  FIsCancel := False;
  FStatusMutex := TMutex.Create;
  FNewBlockCond := TConditionVariable.Create;
  FWg := TCountdownEvent.Create(0);
  FBlackListMutex := TCriticalSection.Create;
  FWorkingAddrListMutex := TCriticalSection.Create;
  FCTPMutex := TCriticalSection.Create;

  SetLength(FTestProcessors, 2);
  for I := 0 to High(FTestProcessors) do
    FTestProcessors[I] := TTestProcessor.Create(Self, I);
end;

destructor TTestContractWorker.Destroy;
var
  Processor: TTestProcessor;
begin
  for Processor in FTestProcessors do
    Processor.Free;
  FTestPendingCache.Free;
  FBlackList.Free;
  FWorkingAddrList.Free;
  FStatusMutex.Free;
  FNewBlockCond.Free;
  FWg.Free;
  FBlackListMutex.Free;
  FWorkingAddrListMutex.Free;
  FCTPMutex.Free;
  inherited;
end;

procedure TTestContractWorker.Work;
begin
  FStatusMutex.Lock;
  try
    if FStatus <> start then
    begin
      FIsCancel := False;
      InitContractTask;
      FChain.SetNewSignal(procedure(AAddr: TAddress)
      var
        NewAddr: TAddress;
        C: TContractTask;
      begin
        if IsContractInBlackList(AAddr) then Exit;
        NewAddr := ContractList[Random(Length(ContractList))];
        C := TContractTask.Create;
        C.Addr := NewAddr;
        C.Quota := FChain.GetQuotaMap(NewAddr);
        PushContractTask(C);
        WakeupOneTp;
      end);

      for var P in FTestProcessors do
        TTask.Run(P.Work);

      FStatus := start;
    end
    else
    begin
      WakeupAllTps;
    end;
  finally
    FStatusMutex.Unlock;
  end;
end;

procedure TTestContractWorker.Stop;
begin
  FStatusMutex.Lock;
  try
    if FStatus = start then
    begin
      FIsCancel := True;
      FNewBlockCond.Broadcast;
      // Clear caches
      FWg.Wait;
      FStatus := stop;
    end;
  finally
    FStatusMutex.Unlock;
  end;
end;

procedure TTestContractWorker.InitContractTask;
var
  I: Integer;
  V: TAddress;
begin
  FContractTaskPQueue := TContractTaskPQueue.Create;
  for I := 0 to High(ContractList) do
  begin
    V := ContractList[I];
    FContractTaskPQueue.Push(TContractTask.Create(V, I, FChain.GetQuotaMap(V)));
  end;
end;

procedure TTestContractWorker.PushContractTask(ATask: TContractTask);
begin
  FCTPMutex.Acquire;
  try
    // Simplified push for test
    FContractTaskPQueue.Push(ATask);
    Signal.Info(Format('heap push, addr=%s, quota=%d', [ATask.Addr.ToString, ATask.Quota]));
  finally
    FCTPMutex.Release;
  end;
end;

function TTestContractWorker.PopContractTask: TContractTask;
begin
  FCTPMutex.Acquire;
  try
    if FContractTaskPQueue.Count > 0 then
      Result := FContractTaskPQueue.Pop
    else
      Result := nil;
  finally
    FCTPMutex.Release;
  end;
end;

procedure TTestContractWorker.WakeupOneTp;
begin
  TestLog.Info('wakeupOneTp');
  FNewBlockCond.Signal;
end;

procedure TTestContractWorker.WakeupAllTps;
begin
  TestLog.Info('WakeupAllTPs');
  FNewBlockCond.Broadcast;
end;

function TTestContractWorker.AddContractIntoWorkingList(AAddr: TAddress): Boolean;
begin
  FWorkingAddrListMutex.Acquire;
  try
    if FWorkingAddrList.ContainsKey(AAddr) and FWorkingAddrList[AAddr] then
      Result := False
    else
    begin
      FWorkingAddrList.AddOrSetValue(AAddr, True);
      Result := True;
    end;
  finally
    FWorkingAddrListMutex.Release;
  end;
end;

procedure TTestContractWorker.RemoveContractFromWorkingList(AAddr: TAddress);
begin
  FWorkingAddrListMutex.Acquire;
  try
    FWorkingAddrList.AddOrSetValue(AAddr, False);
  finally
    FWorkingAddrListMutex.Release;
  end;
end;

function TTestContractWorker.IsContractInBlackList(AAddr: TAddress): Boolean;
begin
  FBlackListMutex.Acquire;
  try
    Result := FBlackList.ContainsKey(AAddr);
  finally
    FBlackListMutex.Release;
  end;
end;

procedure TTestContractWorker.AddContractIntoBlackList(AAddr: TAddress);
begin
  FBlackListMutex.Acquire;
  try
    FBlackList.AddOrSetValue(AAddr, True);
    FTestPendingCache.Remove(AAddr);
  finally
    FBlackListMutex.Release;
  end;
end;

function TTestContractWorker.AcquireNewOnroadBlocks(AContractAddr: TAddress): IAccountBlock;
var
  PendingMap: TCallerPendingMap;
  Blocks: TArray<IAccountBlock>;
  V: IAccountBlock;
begin
  if not FTestPendingCache.TryGetValue(AContractAddr, PendingMap) then
  begin
    PendingMap := TCallerPendingMap.Create;
    FTestPendingCache.Add(AContractAddr, PendingMap);
  end;

  if PendingMap.IsPendingMapNotSufficient then
  begin
    Blocks := FChain.GetOnRoadBlockByAddr(AContractAddr, 0, 100);
    for V in Blocks do
      if not PendingMap.IsInferiorStateOut(V.AccountAddress) then
        PendingMap.AddPendingMap(V);
  end;
  Result := PendingMap.GetOnePending;
end;

procedure TTestContractWorker.DeletePendingOnroadBlock(AContractAddr: TAddress; ASendBlock: IAccountBlock);
begin
  FChain.DeleteOnroad(AContractAddr, ASendBlock.Hash);
end;

procedure TTestContractWorker.AddContractCallerToInferiorList(AContract, ACaller: TAddress; AState: TInferiorState);
var
  PendingCache: TCallerPendingMap;
begin
  if FTestPendingCache.TryGetValue(AContract, PendingCache) then
    PendingCache.AddIntoInferiorList(ACaller, AState);
end;

{ TTestChainDb }

constructor TTestChainDb.Create;
var
  I: Integer;
  V: TAddress;
begin
  inherited Create;
  FDB := TDictionary<TAddress, TArray<IAccountBlock>>.Create;
  FQuotaMap := TDictionary<TAddress, TUInt64>.Create;
  FQuotaMutex := TCriticalSection.Create;
  FBreaker := TEvent.Create(nil, True, False, '');

  for I := 0 to High(ContractList) do
  begin
    V := ContractList[I];
    FQuotaMap.Add(V, TestDefaultQuota - TUInt64(I));
  end;
end;

destructor TTestChainDb.Destroy;
begin
  FDB.Free;
  FQuotaMap.Free;
  FQuotaMutex.Free;
  FBreaker.Free;
  inherited;
end;

procedure TTestChainDb.Start;
var
  Stopwatch: TStopwatch;
begin
  TestLog.Info('writeOnroad start');
  Stopwatch := TStopwatch.StartNew;
  WriteOnroad;

  while Stopwatch.ElapsedMilliseconds < 2000 do
  begin
    if FBreaker.WaitFor(500) = TWaitResult.wrSignaled then
      Break;
    TestLog.Info('writeOnroad');
    WriteOnroad;
  end;

  var remain := 0;
  for var v in FDB.Values do
    remain := remain + Length(v);
  TestLog.Info('chain work stop', 'remain', remain);
end;

procedure TTestChainDb.Stop;
begin
  FBreaker.SetEvent;
end;

procedure TTestChainDb.SetNewSignal(AFunc: TProc<TAddress>);
begin
  FBlockFn := AFunc;
end;

function TTestChainDb.GetOnRoadBlockByAddr(AAddr: TAddress; APageNum, APageCount: Integer): TArray<IAccountBlock>;
var
  Blocks: TArray<IAccountBlock>;
  Index: Integer;
  AllBlocks: TArray<IAccountBlock>;
begin
  Result := [];
  if FDB.TryGetValue(AAddr, AllBlocks) then
  begin
    Index := 0;
    for var V in AllBlocks do
    begin
      if Index >= APageCount * APageNum then
      begin
        if Index >= APageCount * (APageNum + 1) then
          Exit(Result);
        Result := Concat(Result, [V]);
      end;
      Inc(Index);
    end;
  end;
end;

procedure TTestChainDb.WriteOnroad;
var
  Blocks: TArray<IAccountBlock>;
  I, Height: Integer;
  B: IAccountBlock;
  L: TArray<IAccountBlock>;
begin
  SetLength(Blocks, 10); // defaultPullCount
  for I := 0 to High(Blocks) do
  begin
    Height := Random(System.Math.MaxInt(255));
    B := TAccountBlock.Create;
    B.BlockType := SendCall;
    B.Height := TUInt64(Height);
    B.Hash := TDataHash.Create(TEncoding.UTF8.GetBytes(IntToStr(Height)));
    B.AccountAddress := GeneralList[Random(Length(GeneralList))];
    B.ToAddress := ContractList[Random(Length(ContractList))];
    Blocks[I] := B;
  end;

  for B in Blocks do
  begin
    if FDB.TryGetValue(B.ToAddress, L) then
      FDB[B.ToAddress] := Concat(L, [B])
    else
      FDB.Add(B.ToAddress, [B]);
  end;

  for var K in FDB.Keys do
    FQuotaMap[K] := FQuotaMap[K] + 1;

  if Assigned(FBlockFn) then
    for L in FDB.Values do
      for B in L do
        FBlockFn(B.ToAddress);
end;

function TTestChainDb.DeleteOnroad(AContractAddr, ASendHash: THash): Boolean;
var
  L: TArray<IAccountBlock>;
  I: Integer;
  V: IAccountBlock;
begin
  Result := False;
  if FDB.TryGetValue(AContractAddr, L) then
  begin
    for I := 0 to High(L) do
    begin
      V := L[I];
      if V.Hash.IsEqual(ASendHash) then
      begin
        if not ModifyQuotaMap_Sub(AContractAddr) then
          Exit(False);
        System.Delete(L, I, 1);
        FDB[AContractAddr] := L;
        Result := True;
        Break;
      end;
    end;
  end;
end;

function TTestChainDb.GetQuotaMap(AAddr: TAddress): TUInt64;
begin
  FQuotaMutex.Acquire;
  try
    Result := FQuotaMap[AAddr];
  finally
    FQuotaMutex.Release;
  end;
end;

function TTestChainDb.ModifyQuotaMap_Sub(AAddr: TAddress): Boolean;
var
  QUsed: TUInt64;
begin
  FQuotaMutex.Acquire;
  try
    QUsed := TUInt64(Random(10) + 1);
    if FQuotaMap[AAddr] < QUsed then
      Result := False
    else
    begin
      FQuotaMap[AAddr] := FQuotaMap[AAddr] - QUsed;
      Result := True;
    end;
  finally
    FQuotaMutex.Release;
  end;
end;

function TTestChainDb.CheckQuota(AAddr: TAddress): Boolean;
begin
  Result := FQuotaMap[AAddr] > 5;
end;

function TTestChainDb.InsertIntoChain(AContractAddr: TAddress; ASendHash: THash): Boolean;
begin
  Result := DeleteOnroad(AContractAddr, ASendHash);
end;

initialization
  Contract1 := BytesToAddress(TEncoding.UTF8.GetBytes(StringOfChar(#0, 19) + #1));
  Contract2 := BytesToAddress(TEncoding.UTF8.GetBytes(StringOfChar(#0, 19) + #2));
  Contract3 := BytesToAddress(TEncoding.UTF8.GetBytes(StringOfChar(#0, 19) + #3));
  Caller1 := BytesToAddress(TEncoding.UTF8.GetBytes(#1 + StringOfChar(#0, 19) + #1));
  Caller2 := BytesToAddress(TEncoding.UTF8.GetBytes(#1 + StringOfChar(#0, 19) + #2));
  Caller3 := BytesToAddress(TEncoding.UTF8.GetBytes(#1 + StringOfChar(#0, 19) + #3));
  ContractList := [Contract1, Contract2, Contract3];
  GeneralList := [Caller1, Caller2, Caller3];
  TestDefaultQuota := 20;
  TestLog := TLogger.Create('test', 'l');
  Signal := TestLog.New('signal', nil);
  RegisterTest(TContractTest.Suite);
end.
