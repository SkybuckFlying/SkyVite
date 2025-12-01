unit Ledger.Chain.Insert.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain,
  Ledger.Chain.Test,
  VM.Quota;

type
  [TestFixture]
  TInsertTest = class(TObject)
  private
    FChainInstance: TChain;
    FAccounts: TDictionary<TAddress, TAccount>;
    FSnapshotBlockList: TArray<ISnapshotBlock>;

    // Helper methods translated from Go test
    function InsertAccountBlockAndSnapshot(ABlockCount, ASnapshotPerBlockNum: Integer; ATestQuery: Boolean): TArray<ISnapshotBlock>;
    procedure InsertAccountBlocks(AMonitor: TObject; ABlockCount: Integer);
    procedure Snapshot(ASnapshotBlock: ISnapshotBlock);
    procedure DeleteInvalidBlocks(AInvalidBlocks: TArray<IAccountBlock>);
    function CreateVmBlock(AAccount: TAccount): IVmAccountBlock;
    function GetRandomAccount: TAccount;
    function CreateVmLogList: TArray<IVmLog>;
    function CreateKeyValue(ALatestHeight: TUInt64): TDictionary<string, TBytes>;
    function CreateContractMeta: IContractMeta;
    function CreateSnapshotContent(ASnapshotAll: Boolean): ISnapshotContent;
    function CreateSnapshotBlock(ASnapshotAll: Boolean; ASeed: TUInt64): ISnapshotBlock;
    procedure TestRedo;

  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestInsertAccountBlocks;
    [Test]
    procedure BenchmarkChain_InsertAccountBlock;
  end;

implementation

uses
  System.Math,
  System.DateUtils,
  Crypto,
  Ledger.Chain.Utils;

{ TInsertTest }

procedure TInsertTest.Setup;
begin
  // Corresponds to SetUp(t, 10, 1000, 10)
  TestSetup(10, 1000, 10, FChainInstance, FAccounts, FSnapshotBlockList);
  FSnapshotBlockList := [];
end;

procedure TInsertTest.TearDown;
begin
  TestTearDown(FChainInstance);
  FAccounts.Free;
end;

procedure TInsertTest.TestInsertAccountBlocks;
var
  LMonitor: TObject;
  LDone: Boolean;
  LTask1, LTask2: ITask;
begin
  LMonitor := TObject.Create;
  LDone := False;

  // Task 1: The verifier task
  LTask1 := TTask.Run(procedure
  var
    LCount: Integer;
    LAddr: TAddress;
    LAccount: TAccount;
    LBlock: IAccountBlock;
    LSb: ISnapshotBlock;
    LMaxHeight, H: TUInt64;
    LHsb: ISnapshotBlock;
    LExisted: Boolean;
    I: Integer;
  begin
    while not LDone do
    begin
      TMonitor.Enter(LMonitor);
      try
        LCount := 0;
        for LAddr in FAccounts.Keys do
        begin
          LAccount := FAccounts[LAddr];
          LBlock := FChainInstance.GetLatestAccountBlock(LAddr);
          Assert.IsNotNull(LBlock, 'Latest block is nil');
          Assert.IsFalse(LBlock.Hash.IsZero, 'Latest block hash is zero');
          Assert.AreEqual(LAccount.LatestBlock.Hash, LBlock.Hash, 'Chain latest block differs from account latest block');
          Inc(LCount);
          if LCount >= 5 then
            Break;
        end;
      finally
        TMonitor.Exit(LMonitor);
      end;

      for I := 0 to 2 do
      begin
        LSb := FChainInstance.GetLatestSnapshotBlock;
        LMaxHeight := LSb.Height;
        H := 0;
        while H = 0 do
          H := Random(LMaxHeight);

        LHsb := FChainInstance.GetSnapshotBlockByHeight(H);
        if LHsb = nil then
        begin
          LExisted := FChainInstance.IsSnapshotBlockExisted(LSb.Hash);
          if LExisted then
            Assert.Fail(Format('hsb is nil, height is %d, latest height is %d', [H, LSb.Height]));
        end
        else
          Assert.AreEqual(H, LHsb.Height, 'Snapshot block height mismatch');
      end;
    end;
  end);

  // Task 2: The block producer/deleter task
  LTask2 := TTask.Run(procedure
  var
    I, Num: Integer;
    DeleteCount: TUInt64;
    SnapshotBlock: ISnapshotBlock;
    InvalidBlocks: TArray<IAccountBlock>;
  begin
    for I := 1 to 100 do
    begin
      Num := Random(100);
      if (Num > 90) and (Length(FSnapshotBlockList) > 0) then
      begin
        DeleteCount := TUInt64(Random(5));
        TMonitor.Enter(LMonitor);
        try
          // Assuming TDeleteTest is accessible or these methods are moved
          // For now, this will require refactoring to access DeleteSnapshotBlocks
          // TDeleteTest.DeleteSnapshotBlocks(DeleteCount);
          if Integer(DeleteCount) <= Length(FSnapshotBlockList) then
            SetLength(FSnapshotBlockList, Length(FSnapshotBlockList) - Integer(DeleteCount));
        finally
          TMonitor.Exit(LMonitor);
        end;
      end
      else if Num > 80 then
      begin
        TMonitor.Enter(LMonitor);
        try
          // TDeleteTest.DeleteAccountBlocks;
        finally
          TMonitor.Exit(LMonitor);
        end;
      end
      else
      begin
        InsertAccountBlocks(LMonitor, Random(23));
        TMonitor.Enter(LMonitor);
        try
          SnapshotBlock := CreateSnapshotBlock(False, 0);
          FSnapshotBlockList := Concat(FSnapshotBlockList, [SnapshotBlock]);
          Snapshot(SnapshotBlock);
          InvalidBlocks := FChainInstance.InsertSnapshotBlock(SnapshotBlock);
          DeleteInvalidBlocks(InvalidBlocks);
        finally
          TMonitor.Exit(LMonitor);
        end;
      end;
    end;
    LDone := True;
  end);

  TTask.WaitForAll([LTask1, LTask2]);
  FreeAndNil(LMonitor);

  // TestRedo;
end;

procedure TInsertTest.BenchmarkChain_InsertAccountBlock;
begin
  Assert.Ignore('Benchmark test not implemented yet');
end;

procedure TInsertTest.TestRedo;
var
  I: TUInt64;
  RedoLogList: TArray<string>; // Assuming string representation for logs
  HasRedo: Boolean;
begin
  for I := 1 to FChainInstance.GetLatestSnapshotBlock.Height + 1 do
  begin
    // Redo log query logic needs to be implemented in stateDB
    // (RedoLogList, HasRedo) := FChainInstance.FStateDB.Redo.QueryLog(I);
    // if HasRedo then
    //   WriteLn(Format('%d %d %s', [I, Length(RedoLogList), BoolToStr(HasRedo, True)]));
  end;
end;

function TInsertTest.InsertAccountBlockAndSnapshot(ABlockCount, ASnapshotPerBlockNum: Integer; ATestQuery: Boolean): TArray<ISnapshotBlock>;
var
  CountInserted, InsertCount: Integer;
  SnapshotBlock: ISnapshotBlock;
  InvalidBlocks: TArray<IAccountBlock>;
begin
  Result := [];
  CountInserted := 0;
  while CountInserted < ABlockCount do
  begin
    InsertCount := ASnapshotPerBlockNum;
    if InsertCount = 0 then
      InsertCount := 10;
    if InsertCount > ABlockCount - CountInserted then
      InsertCount := ABlockCount - CountInserted;

    InsertAccountBlocks(nil, InsertCount);
    Inc(CountInserted, InsertCount);

    SnapshotBlock := FChainInstance.InsertSnapshotBlock(False);
    Result := Concat(Result, [SnapshotBlock]);
    Snapshot(SnapshotBlock);
    DeleteInvalidBlocks(FChainInstance.FilterUnconfirmedBlocks(SnapshotBlock, True));

    if ATestQuery then
    begin
      // testUnconfirmedNoTesting(FChainInstance, FAccounts);
      // testAccountBlockNoTesting(FChainInstance, FAccounts);
      // testSnapshotBlockNoTesting(FChainInstance, FAccounts, Result);
    end;
  end;
end;

procedure TInsertTest.InsertAccountBlocks(AMonitor: TObject; ABlockCount: Integer);
var
  I: Integer;
  Account: TAccount;
  VmBlock: IVmAccountBlock;
begin
  for I := 1 to ABlockCount do
  begin
    if AMonitor <> nil then
      TMonitor.Enter(AMonitor);
    try
      Account := GetRandomAccount;
      VmBlock := CreateVmBlock(Account);
      Account.InsertBlock(VmBlock, FAccounts);
      FChainInstance.InsertAccountBlock(VmBlock);
    finally
      if AMonitor <> nil then
        TMonitor.Exit(AMonitor);
    end;
  end;
end;

procedure TInsertTest.Snapshot(ASnapshotBlock: ISnapshotBlock);
var
  Addr: TAddress;
  HashHeight: IHashHeight;
begin
  for Addr in ASnapshotBlock.SnapshotContent.Keys do
  begin
    HashHeight := ASnapshotBlock.SnapshotContent[Addr];
    if FAccounts.ContainsKey(Addr) then
      FAccounts[Addr].Snapshot(ASnapshotBlock.Hash, HashHeight);
  end;
end;

procedure TInsertTest.DeleteInvalidBlocks(AInvalidBlocks: TArray<IAccountBlock>);
var
  I: Integer;
  Ab: IAccountBlock;
begin
  for I := High(AInvalidBlocks) downto 0 do
  begin
    Ab := AInvalidBlocks[I];
    FAccounts[Ab.AccountAddress].DeleteAccountBlock(FAccounts, Ab.Hash);
    FAccounts[Ab.AccountAddress].RollbackLatestBlock;
  end;
end;

function TInsertTest.CreateVmBlock(AAccount: TAccount): IVmAccountBlock;
var
  CTxOptions: TCreateTxOptions;
  VmBlock: IVmAccountBlock;
  IsCreateSendBlock: Boolean;
  RandNum: Integer;
  ToAccount: TAccount;
begin
  CTxOptions := TCreateTxOptions.Create;
  CTxOptions.MockSignature := True;
  CTxOptions.KeyValue := CreateKeyValue(AAccount.GetLatestHeight);
  CTxOptions.VmLogList := CreateVmLogList;
  CTxOptions.Quota := Random(100);

  IsCreateSendBlock := True;
  if AAccount.HasOnRoadBlock then
  begin
    RandNum := Random(100);
    if RandNum > 50 then
      IsCreateSendBlock := False;
  end;

  if IsCreateSendBlock then
  begin
    ToAccount := GetRandomAccount;
    if ToAccount.BlocksMap.Count <= 0 then
      CTxOptions.ContractMeta := CreateContractMeta;
    VmBlock := AAccount.CreateSendBlock(ToAccount, CTxOptions);
  end
  else
  begin
    VmBlock := AAccount.CreateReceiveBlock(CTxOptions);
  end;
  Result := VmBlock;
end;

function TInsertTest.GetRandomAccount: TAccount;
begin
  // Simple way to get a "random" account from the dictionary
  Result := FAccounts.Values.First;
end;

function TInsertTest.CreateVmLogList: TArray<IVmLog>;
var
  TopicHash1, TopicHash2: THash;
  VmLog1, VmLog2: IVmLog;
begin
  TopicHash1 := THash.FromBytes(TEncoding.UTF8.GetBytes(IntToStr(MilliSecondOf(Now))));
  TopicHash2 := THash.FromBytes(TEncoding.UTF8.GetBytes(IntToStr(MilliSecondOf(Now))));
  VmLog1 := TCreate.VmLog([TopicHash1], TEncoding.UTF8.GetBytes(IntToStr(MilliSecondOf(Now))));
  VmLog2 := TCreate.VmLog([TopicHash2], TEncoding.UTF8.GetBytes(IntToStr(MilliSecondOf(Now))));
  Result := [VmLog1, VmLog2];
end;

function TInsertTest.CreateKeyValue(ALatestHeight: TUInt64): TDictionary<string, TBytes>;
begin
  Result := TDictionary<string, TBytes>.Create;
  Result.Add(string(TEncoding.UTF8.GetString(TChainUtils.Uint64ToBytes(ALatestHeight + 1))), TChainUtils.Uint64ToBytes(MilliSecondOf(Now)));
end;

function TInsertTest.CreateContractMeta: IContractMeta;
begin
  Result := TCreate.ContractMeta;
  Result.SendConfirmedTimes := 2;
  Result.Gid := TEncoding.UTF8.GetBytes(IntToStr(MilliSecondOf(Now)));
end;

function TInsertTest.CreateSnapshotContent(ASnapshotAll: Boolean): ISnapshotContent;
var
  UnconfirmedBlocks: TArray<IAccountBlock>;
  RandomNum, I: Integer;
  Block: IAccountBlock;
begin
  Result := TCreate.SnapshotContent;
  UnconfirmedBlocks := FChainInstance.Cache.GetUnconfirmedBlocks;

  if not ASnapshotAll and (Length(UnconfirmedBlocks) > 1) then
  begin
    RandomNum := Random(100);
    if RandomNum > 90 then
      SetLength(UnconfirmedBlocks, 0)
    else if RandomNum > 50 then
      SetLength(UnconfirmedBlocks, Random(Length(UnconfirmedBlocks)));
  end;

  for I := High(UnconfirmedBlocks) downto 0 do
  begin
    Block := UnconfirmedBlocks[I];
    if not Result.ContainsKey(Block.AccountAddress) then
      Result.Add(Block.AccountAddress, TCreate.HashHeight(Block.Hash, Block.Height));
  end;
end;

function TInsertTest.CreateSnapshotBlock(ASnapshotAll: Boolean; ASeed: TUInt64): ISnapshotBlock;
var
  LatestSb: ISnapshotBlock;
  NowTime: TDateTime;
  RandomNum: Integer;
begin
  Result := TCreate.SnapshotBlock;
  LatestSb := FChainInstance.GetLatestSnapshotBlock;
  RandomNum := Random(100);
  if RandomNum < 70 then
    NowTime := IncSecond(LatestSb.Timestamp, 1)
  else if RandomNum < 90 then
    NowTime := IncSecond(LatestSb.Timestamp, 2)
  else
    NowTime := IncSecond(LatestSb.Timestamp, 3);

  Result.PrevHash := LatestSb.Hash;
  Result.Height := LatestSb.Height + 1;
  Result.Timestamp := NowTime;
  Result.SnapshotContent := CreateSnapshotContent(ASnapshotAll);
  Result.Seed := ASeed;
  Result.Hash := Result.ComputeHash;
end;

initialization
  RegisterTest(TInsertTest.Suite);

end.
