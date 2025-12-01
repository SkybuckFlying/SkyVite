unit Ledger.Chain.BuiltinContract.Test;

interface

uses
  DUnitX.TestFramework,
  Ledger.Chain,
  Common.Types,
  Interfaces.Core;

type
  [TestFixture]
  TBuiltinContractTest = class
  public
    [Test]
    procedure TestChain_BuiltinContract;
    [Test]
    procedure TestVoteList;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  System.SyncObjs,
  Ledger.Chain.Test.Utils;

procedure NewStorageDatabase(ParaMu: TRTLCriticalSection; ParaChain: IChain; ParaAccounts: TDictionary<TAddress, TAccount>; ParaSnapshotBlockList: TArray<ISnapshotBlock>);
var
  LSbLen, I, LIndex: Integer;
  LSnapshotBlock, LPrevSnapshotBlock: ISnapshotBlock;
  LAccount: TAccount;
  LSD, LPrevSd: IStorageDatabase;
  LKV: TDictionary<string, TBytes>;
  LIter: IStorageIterator;
  LCurrent: TUInt64;
  LNext: TUInt64;
  LKeyStr: string;
  LConfirmedBlockHashMap: TDictionary<THash, Boolean>;
  LKVSetMap: TDictionary<THash, TDictionary<string, TBytes>>;
  LHash: THash;
  LKVSetList: TArray<TKVSet>;
  LKVSet: TKVSet;
  LK: string;
  LV: TBytes;
  LQueryValue: TBytes;
begin
  LSbLen := Length(ASnapshotBlockList);
  if LSbLen <= 10 then
    Exit;

  for I := LSbLen - 6 downto Max(0, LSbLen - 11) do
  begin
    LIndex := I;
    LSnapshotBlock := ASnapshotBlockList[LIndex];
    LPrevSnapshotBlock := ASnapshotBlockList[LIndex - 1];

    for LAccount in AAccounts.Values do
    begin
      LSD := AChain.StateDB.NewStorageDatabase(LSnapshotBlock.Hash, LAccount.Addr);
      Assert.AreEqual(LSD.Address, LAccount.Addr);

      LPrevSd := AChain.StateDB.NewStorageDatabase(LPrevSnapshotBlock.Hash, LAccount.Addr);
      Assert.AreEqual(LPrevSd.Address, LAccount.Addr);

      LKV := TDictionary<string, TBytes>.Create;
      LIter := LPrevSd.NewStorageIterator(nil);
      LCurrent := 0;
      while LIter.Next do
      begin
        LNext := BytesToUInt64(LIter.Key);
        Assert.AreEqual(LCurrent + 1, LNext);
        Inc(LCurrent);

        LKeyStr := string(LIter.Key);
        LKV.Add(LKeyStr, LIter.Value);
      end;

      if ParaMu <> nil then
        ParaMu.Acquire;
      try
        LConfirmedBlockHashMap := LAccount.ConfirmedBlockMap[LSnapshotBlock.Hash];
        LKVSetMap := TDictionary<THash, TDictionary<string, TBytes>>.Create;
        for LHash in LConfirmedBlockHashMap.Keys do
          LKVSetMap.Add(LHash, LAccount.KvSetMap[LHash]);

        LKVSetList := LAccount.NewKvSetList(LKVSetMap);
        for LKVSet in LKVSetList do
        begin
          for LK in LKVSet.Kv.Keys do
            LKV.AddOrSetValue(LK, LKVSet.Kv[LK]);
        end;
      finally
        if ParaMu <> nil then
          ParaMu.Release;
      end;


      CheckIterator(LKV, function: IStorageIterator
        begin
          Result := LSD.NewStorageIterator(nil);
        end);

      for LK in LKV.Keys do
      begin
        LV := LKV[LK];
        LQueryValue := LSD.GetValue(TEncoding.UTF8.GetBytes(LK));
        Assert.IsTrue(CompareMem(LV, LQueryValue, Length(LV)), 'Addr: ' + LAccount.Addr.ToString + ', snapshot height: ' + IntToStr(LSnapshotBlock.Height) + ', key: ' + LK + ', value: ' + THex.Encode(LV) + ', query value: ' + THex.Encode(LQueryValue));
      end;
    end;
  end;
end;

procedure testBuiltInContract(t: TTest; chainInstance: IChain; accounts: TDictionary<TAddress, TAccount>; snapshotBlockList: TArray<ISnapshotBlock>);
var
  mu: TRTLCriticalSection;
  wg: TCountdownEvent;
  testCount: integer;
  maxTestCount: integer;
begin
  t.Run('NewStorageDatabase', procedure
    begin
      NewStorageDatabase(nil, chainInstance, accounts, snapshotBlockList);
    end);

  t.Run('ConcurrentWrite', procedure
    begin
      // return
      maxTestCount := 100;
      testCount := 0;
      InitCriticalSection(mu);
      wg := TCountdownEvent.Create(2);

      TTask.Run(procedure
        var
          snapshotBlock: ISnapshotBlock;
          invalidBlocks: TArray<ISnapshotBlock>;
        begin
          try
            while testCount < maxTestCount do
            begin
              // insert account blocks
              InsertAccountBlocks(mu, chainInstance, accounts, Random(100));
              //snapshotBlockList = append(snapshotBlockList, InsertAccountBlockAndSnapshot(chainInstance, accounts, rand.Intn(1000), rand.Intn(20), false)...)

              // insert snapshot block
              snapshotBlock := createSnapshotBlock(chainInstance, TCreateSbOption.Create(false));

              EnterCriticalSection(mu);
              try
                snapshotBlockList := snapshotBlockList + [snapshotBlock];
                Snapshot(accounts, snapshotBlock);
              finally
                LeaveCriticalSection(mu);
              end;


              invalidBlocks := chainInstance.InsertSnapshotBlock(snapshotBlock);

              EnterCriticalSection(mu);
              try
                DeleteInvalidBlocks(accounts, invalidBlocks);
              finally
                LeaveCriticalSection(mu);
              end;

              System.SysUtils.Sleep(100);
              InterlockedIncrement(testCount);
            end;
          finally
            wg.Signal;
          end;
        end);

      TTask.Run(procedure
        var
          testSnapshotBlock: TArray<ISnapshotBlock>;
        begin
          try
            while testCount < maxTestCount do
            begin
              EnterCriticalSection(mu);
              try
                testSnapshotBlock := snapshotBlockList;
              finally
                LeaveCriticalSection(mu);
              end;
              NewStorageDatabase(mu, chainInstance, accounts, testSnapshotBlock);
            end;
          finally
            wg.Signal;
          end;
        end);

      wg.WaitFor;
      DeleteCriticalSection(mu);
    end);

  t.Run('GetRegisterList', procedure
    begin
      //GetRegisterList(t, chainInstance);
    end);
end;


{ TBuiltinContractTest }

procedure TBuiltinContractTest.TestChain_BuiltinContract;
var
  LChain: IChain;
  LAccounts: TDictionary<TAddress, TAccount>;
  LSnapshotBlockList: TArray<ISnapshotBlock>;
begin
  LChain := SetUp(17, 2654, 9, LAccounts, LSnapshotBlockList);
  testBuiltInContract(Self, LChain, LAccounts, LSnapshotBlockList);
  TearDown(LChain);
end;

procedure TBuiltinContractTest.TestVoteList;
var
  chainInstance: IChain;
  block: ISnapshotBlock;
  voteMap: TDictionary<string, IVoteInfo>;
  voteInfo: IVoteInfo;
  addr: TAddress;
  latest: IAccountBlock;
  blocks: TArray<IAccountBlock>;
  i: integer;
begin
  Assert.Ignore('Skipped by default. This test can be used to inspect ledger vote data.');

  chainInstance, err := NewChainInstance(t, '/Users/liyanda/test_ledger/ledger4/devdata', false);
  Assert.IsNull(err, 'Failed to create chain instance');

  block := chainInstance.GetLatestSnapshotBlock();
  Assert.IsNotNull(block, 'Failed to get latest snapshot block');

  voteMap, err := chainInstance.GetVoteList(block.Hash, SNAPSHOT_GID);
  Assert.IsNull(err, 'Failed to get vote list');

  for voteInfo in voteMap.Values do
  begin
    addr := voteInfo.VoteAddr;
    latest, e := chainInstance.GetLatestAccountBlock(addr);
    Assert.IsNull(e, 'Failed to get latest account block');
    blocks, e := chainInstance.GetAccountBlocks(latest.Hash, 300);
    Assert.IsNull(e, 'Failed to get account blocks');
    for i := 0 to Length(blocks) - 1 do
    begin
      if blocks[i].ToAddress.ToString() = 'vite_00000000000000000000000000000000000000042d7ef71894' then
      begin
        //fmt.Printf("%s: %+v\n", blocks[i].AccountAddress, blocks[i].Data)
        break;
      end;
    end;
  end;
end;

end.
