unit Ledger.Chain.SnapshotBlock.Test;

interface

uses
  Common.Types,
  DUnitX.TestFramework,
  Interfaces.Core,
  Ledger.Chain,
  Ledger.Chain.Account,
  Ledger.Chain.Account.Block,
  Ledger.Chain.Account.Block.Test,
  Ledger.Chain.Account.Test,
  Ledger.Chain.Builtin.Contract,
  Ledger.Chain.Builtin.Contract.Test,
  Ledger.Chain.Chain,
  Ledger.Chain.Chain.Test,
  Ledger.Chain.Check,
  Ledger.Chain.Delete,
  Ledger.Chain.Delete.Test,
  Ledger.Chain.Event.Manager,
  Ledger.Chain.Fork,
  Ledger.Chain.Insert,
  Ledger.Chain.Insert.Test,
  Ledger.Chain.Interface,
  Ledger.Chain.Meta,
  Ledger.Chain.Onroad,
  Ledger.Chain.Onroad.Test,
  Ledger.Chain.Snapshot.Block,
  Ledger.Chain.State,
  Ledger.Chain.State.Test,
  Ledger.Chain.Sync.Ledger,
  Ledger.Chain.Test,
  Ledger.Chain.Unconfirmed,
  Ledger.Chain.Unconfirmed.Test,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  [TestFixture]
  TSnapshotBlockTest = class(TObject)
  public
    [Test]
    procedure TestChain_SnapshotBlock;
    [Test]
    procedure TestSnapshotBlocks;
    [Test]
    procedure TestChain_GetSeedConfirmedSnapshotBlock;
  end;

implementation

uses
  System.Math,
  Crypto,
  Ledger.Chain.Utils;

procedure CheckSnapshotBlock(snapshotBlock: ISnapshotBlock; queryBlock: TFunc<ISnapshotBlock>; onlyHeader: Boolean);
var
  querySnapshotBlock: ISnapshotBlock;
  addr: TAddress;
  hashHeight, hashHeight2: IHashHeight;
begin
  querySnapshotBlock := queryBlock();
  if snapshotBlock = nil then
  begin
    Assert.IsNull(querySnapshotBlock);
    Exit;
  end;
  Assert.IsNotNull(querySnapshotBlock);

  Assert.AreEqual(snapshotBlock.Hash, querySnapshotBlock.Hash);
  if not onlyHeader then
  begin
    Assert.AreEqual(snapshotBlock.SnapshotContent.Count, querySnapshotBlock.SnapshotContent.Count);
    for addr in snapshotBlock.SnapshotContent.Keys do
    begin
      hashHeight := snapshotBlock.SnapshotContent[addr];
      hashHeight2 := querySnapshotBlock.SnapshotContent[addr];
      Assert.AreEqual(hashHeight.Hash, hashHeight2.Hash);
      Assert.AreEqual(hashHeight.Height, hashHeight2.Height);
    end;
  end;
end;

procedure CheckSnapshotBlocks(snapshotBlockList: TArray<ISnapshotBlock>;
  getBlocks: TFunc<Integer, Integer, TArray<ISnapshotBlock>>; higher, onlyHeader: Boolean);
var
  sbListLen, start, end, blocksLen, index: Integer;
  blocks: TArray<ISnapshotBlock>;
  prevBlock, block, snapshotBlock: ISnapshotBlock;
  addr: TAddress;
  hashHeight, hashHeight2: IHashHeight;
begin
  sbListLen := Length(snapshotBlockList);
  start := 0;
  end := -1;

  while True do
  begin
    start := end + 1;
    end := start + 9;
    if start >= sbListLen then
      Break;

    if end >= sbListLen then
      end := sbListLen - 1;

    blocks := getBlocks(start, end);
    blocksLen := Length(blocks);
    Assert.AreEqual(end - start + 1, blocksLen);

    prevBlock := nil;
    index := 0;
    while index < blocksLen do
    begin
      if higher then
        block := blocks[index]
      else
        block := blocks[blocksLen - index - 1];
      snapshotBlock := snapshotBlockList[start + index];

      if (prevBlock <> nil) and ((not prevBlock.Hash.IsEqual(block.PrevHash)) or (prevBlock.Height <> block.Height - 1)) then
        Assert.Fail('Chain is broken');

      Assert.AreEqual(snapshotBlock.Hash, block.Hash);
      if not onlyHeader then
      begin
        Assert.AreEqual(snapshotBlock.SnapshotContent.Count, block.SnapshotContent.Count);
        for addr in snapshotBlock.SnapshotContent.Keys do
        begin
          hashHeight := snapshotBlock.SnapshotContent[addr];
          hashHeight2 := block.SnapshotContent[addr];
          Assert.AreEqual(hashHeight.Hash, hashHeight2.Hash);
          Assert.AreEqual(hashHeight.Height, hashHeight2.Height);
        end;
      end;

      Inc(index);
      prevBlock := block;
    end;
  end;
end;

procedure CheckSubLedger(chainInstance: IChain; accounts: TDictionary<TAddress, TAccount>; snapshotBlockList: TArray<ISnapshotBlock>;
  getSubLedger: TFunc<Integer, Integer, TArray<ISnapshotChunk>>);
var
  start, end, i: Integer;
  sbListLen: Integer;
  segs: TArray<ISnapshotChunk>;
  startSnapshotBlock: ISnapshotBlock;
  seg: ISnapshotChunk;
  snapshotBlock: ISnapshotBlock;
  accountBlocks: TArray<IAccountBlock>;
  blockHashMap: TDictionary<THash, Boolean>;
  accountBlock: IAccountBlock;
  account: TAccount;
  confirmedBlockHashList: TDictionary<THash, Boolean>;
  hash: THash;
begin
  start := 0;
  end := -1;
  sbListLen := Length(snapshotBlockList);

  while True do
  begin
    start := end + 1;
    end := start + 9;

    if start >= sbListLen then
      Break;

    if end >= sbListLen then
      end := sbListLen - 1;

    segs := getSubLedger(start, end);
    startSnapshotBlock := snapshotBlockList[start];
    for i := 0 to Length(segs) - 1 do
    begin
      seg := segs[i];
      snapshotBlock := seg.SnapshotBlock;

      CheckSnapshotBlock(snapshotBlock, function: ISnapshotBlock
        begin
          Result := chainInstance.GetSnapshotBlockByHeight(startSnapshotBlock.Height + TUInt64(i));
        end, False);

      accountBlocks := seg.AccountBlocks;
      if i = 0 then
      begin
        Assert.AreEqual(0, Length(accountBlocks));
        Continue;
      end;

      blockHashMap := TDictionary<THash, Boolean>.Create;
      for accountBlock in accountBlocks do
        blockHashMap.Add(accountBlock.Hash, True);

      if snapshotBlock <> nil then
      begin
        for account in accounts.Values do
        begin
          confirmedBlockHashList := account.ConfirmedBlockMap[snapshotBlock.Hash];
          for hash in confirmedBlockHashList.Keys do
          begin
            if blockHashMap.ContainsKey(hash) then
              blockHashMap.Remove(hash)
            else
              Assert.Fail('Block not found in hash map');
          end;
        end;
      end
      else
      begin
        for account in accounts.Values do
        begin
          for hash in account.UnconfirmedBlocks.Keys do
          begin
            if blockHashMap.ContainsKey(hash) then
              blockHashMap.Remove(hash)
            else
              Assert.Fail('Block not found in hash map');
          end;
        end;
      end;

      Assert.AreEqual(0, blockHashMap.Count, 'Block hash map not empty');
    end;
  end;
end;

procedure testSnapshotBlock(t: TTest; chainInstance: IChain; accounts: TDictionary<TAddress, TAccount>; snapshotBlockList: TArray<ISnapshotBlock>);
begin
  t.Run('IsGenesisSnapshotBlock', procedure
    begin
      IsGenesisSnapshotBlock(chainInstance);
    end);
  t.Run('IsSnapshotBlockExisted', procedure
    begin
      IsSnapshotBlockExisted(chainInstance, snapshotBlockList);
    end);
  t.Run('GetGenesisSnapshotBlock', procedure
    begin
      GetGenesisSnapshotBlock(chainInstance);
    end);
  t.Run('GetLatestSnapshotBlock', procedure
    begin
      GetLatestSnapshotBlock(chainInstance);
    end);
  t.Run('GetSnapshotHeightByHash', procedure
    begin
      GetSnapshotHeightByHash(chainInstance, snapshotBlockList);
    end);
  t.Run('GetSnapshotHeaderByHeight', procedure
    begin
      GetSnapshotBlockByHeight(chainInstance, snapshotBlockList, True);
    end);
  t.Run('GetSnapshotBlockByHeight', procedure
    begin
      GetSnapshotBlockByHeight(chainInstance, snapshotBlockList, False);
    end);
  t.Run('GetSnapshotHeaderByHash', procedure
    begin
      GetSnapshotBlockByHash(chainInstance, snapshotBlockList, True);
    end);
  t.Run('GetSnapshotBlockByHash', procedure
    begin
      GetSnapshotBlockByHash(chainInstance, snapshotBlockList, False);
    end);
  t.Run('GetRangeSnapshotHeaders', procedure
    begin
      GetRangeSnapshotBlocks(chainInstance, snapshotBlockList, True);
    end);
  t.Run('GetRangeSnapshotBlocks', procedure
    begin
      GetRangeSnapshotBlocks(chainInstance, snapshotBlockList, False);
    end);
  t.Run('GetSnapshotHeaders', procedure
    begin
      GetSnapshotBlocks(chainInstance, snapshotBlockList, True);
    end);
  t.Run('GetSnapshotBlocks', procedure
    begin
      GetSnapshotBlocks(chainInstance, snapshotBlockList, False);
    end);
  t.Run('GetSnapshotHeadersByHeight', procedure
    begin
      GetSnapshotBlocksByHeight(chainInstance, snapshotBlockList, True);
    end);
  t.Run('GetSnapshotBlocksByHeight', procedure
    begin
      GetSnapshotBlocksByHeight(chainInstance, snapshotBlockList, False);
    end);
  t.Run('GetConfirmSnapshotHeaderByAbHash', procedure
    begin
      GetConfirmSnapshotBlockByAbHash(chainInstance, accounts, True);
    end);
  t.Run('GetConfirmSnapshotBlockByAbHash', procedure
    begin
      GetConfirmSnapshotBlockByAbHash(chainInstance, accounts, False);
    end);
  t.Run('QueryLatestSnapshotBlock', procedure
    begin
      QueryLatestSnapshotBlock(chainInstance);
    end);
  t.Run('GetSnapshotHeaderBeforeTime', procedure
    begin
      GetSnapshotHeaderBeforeTime(chainInstance, snapshotBlockList);
    end);
  t.Run('GetSnapshotHeadersAfterOrEqualTime', procedure
    begin
      GetSnapshotHeadersAfterOrEqualTime(chainInstance, snapshotBlockList);
    end);
  t.Run('GetSubLedger', procedure
    begin
      GetSubLedger(chainInstance, accounts, snapshotBlockList);
    end);
  t.Run('GetSubLedgerAfterHeight', procedure
    begin
      GetSubLedgerAfterHeight(chainInstance, accounts, snapshotBlockList);
    end);
end;

{ TSnapshotBlockTest }

procedure TSnapshotBlockTest.TestChain_SnapshotBlock;
var
  chainInstance: IChain;
  accounts: TDictionary<TAddress, TAccount>;
  snapshotBlockList: TArray<ISnapshotBlock>;
begin
  chainInstance := SetUp(10, 1234, 7, accounts, snapshotBlockList);
  testSnapshotBlock(Self, chainInstance, accounts, snapshotBlockList);
  TearDown(chainInstance);
end;

procedure TSnapshotBlockTest.TestSnapshotBlocks;
var
  chainInstance: IChain;
  latestSb: ISnapshotBlock;
  h: TUInt64;
  sb: ISnapshotBlock;
  l: ISnapshotBlockLocation;
begin
  chainInstance := SetUp(10, 0, 0, nil, nil);
  latestSb := chainInstance.GetLatestSnapshotBlock;
  for h := latestSb.Height downto 1 do
  begin
    sb := chainInstance.GetSnapshotBlockByHeight(h);
    if sb = nil then
    begin
      l := chainInstance.IndexDB.GetSnapshotBlockLocation(h);
      Assert.Fail(Format('Error: sb is nil, height is %d, location is %s', [h, l.ToString]));
    end;
  end;
end;

procedure TSnapshotBlockTest.TestChain_GetSeedConfirmedSnapshotBlock;
begin
  Assert.IsTrue(CheckGetSeedConfirmedSnapshotBlock(Self, False, 2, [2, 3, 4], [-1, -1, -1]));
  Assert.IsTrue(CheckGetSeedConfirmedSnapshotBlock(Self, True, 2, [2, 0, 4], [-1, -1, 3]));
  Assert.IsTrue(CheckGetSeedConfirmedSnapshotBlock(Self, True, 1, [0, 2, 0, 0, 2], [-1, 2, 2, 2, 2]));
  Assert.IsTrue(CheckGetSeedConfirmedSnapshotBlock(Self, True, 3, [0, 2, 0, 2, 2, 0, 2], [-1, -1, -1, -1, 5, 5, 5]));
end;

end.
