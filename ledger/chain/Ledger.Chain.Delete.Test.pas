unit Ledger.Chain.Delete.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Types,
  Interfaces.Core,
  Ledger.Chain,
  Ledger.Chain.Test;

type
  [TestFixture]
  TDeleteTest = class(TObject)
  private
    FChainInstance: TChain;
    FAccounts: TDictionary<TAddress, TAccount>;
    FSnapshotBlockList: TArray<ISnapshotBlock>;
    procedure TestInsertAndDelete;
    procedure TestDeleteMany;
    procedure TestDeleteSnapshotBlocks(ADeleteCount: Integer);
    procedure TestDeleteAccountBlocks;
    procedure DeleteSnapshotBlocks(ACount: TUInt64);
    procedure DeleteAccountBlocks;
    procedure DeleteMemAccountBlock(AAccounts: TDictionary<TAddress, TAccount>; AAccount: TAccount; AToBlock: IAccountBlock; AOnRoadBlocksCache: TDictionary<THash, Boolean>; ADeletedHashMap: TDictionary<THash, Boolean>);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestChain_DeleteSnapshotBlocks;
  end;

implementation

uses
  System.Math,
  Ledger.Chain.Utils;

{ TDeleteTest }

procedure TDeleteTest.Setup;
begin
  // Corresponds to SetUp(t, 50, 960, 1)
  // This assumes a global or accessible TestSetup function similar to the Go code.
  TestSetup(50, 960, 1, FChainInstance, FAccounts, FSnapshotBlockList);
end;

procedure TDeleteTest.TearDown;
begin
  // Corresponds to TearDown(chainInstance)
  TestTearDown(FChainInstance);
  FAccounts.Free;
end;

procedure TDeleteTest.TestChain_DeleteSnapshotBlocks;
var
  I: Integer;
begin
  for I := 0 to 0 do // for i := 0; i < 1; i++
  begin
    TestInsertAndDelete;
  end;
end;

procedure TDeleteTest.TestInsertAndDelete;
var
  I: Integer;
begin
  FSnapshotBlockList := TestDeleteMany;

  for I := 0 to 2 do // for i := 0; i < 3; i++
  begin
    TestDeleteSnapshotBlocks(Random(3));
    TestDeleteAccountBlocks;
    TestDeleteSnapshotBlocks(Random(3));
  end;
end;

procedure TDeleteTest.TestDeleteMany;
var
  NewBlocks: TArray<ISnapshotBlock>;
  DeleteCount: Integer;
begin
  NewBlocks := InsertAccountBlockAndSnapshot(FChainInstance, FAccounts, 150, 3, False);
  FSnapshotBlockList := Concat(FSnapshotBlockList, NewBlocks);
  DeleteCount := 35;

  DeleteSnapshotBlocks(DeleteCount);
  // FChainInstance.stateDB.Store().CompactRange(*util.BytesPrefix([]byte{chain_utils.StorageHistoryKeyPrefix}))
  // Compaction is a DB-specific operation, might need a specific implementation in the Delphi DB layer.

  SetLength(FSnapshotBlockList, Length(FSnapshotBlockList) - DeleteCount);

  TestChainAll(Self, FChainInstance, FAccounts, FSnapshotBlockList);
end;

procedure TDeleteTest.TestDeleteSnapshotBlocks(ADeleteCount: Integer);
var
  InsertCount, SnapshotPerNum, LackNum: Integer;
  NewBlocks: TArray<ISnapshotBlock>;
begin
  InsertCount := Random(100);
  SnapshotPerNum := Random(3);

  NewBlocks := InsertAccountBlockAndSnapshot(FChainInstance, FAccounts, InsertCount, SnapshotPerNum, False);
  FSnapshotBlockList := Concat(FSnapshotBlockList, NewBlocks);

  if ADeleteCount > Length(FSnapshotBlockList) then
  begin
    LackNum := ADeleteCount - Length(FSnapshotBlockList) + 10;
    NewBlocks := InsertAccountBlockAndSnapshot(FChainInstance, FAccounts, LackNum * 20, 20, False);
    FSnapshotBlockList := Concat(FSnapshotBlockList, NewBlocks);
  end;

  TestChainAll(Self, FChainInstance, FAccounts, FSnapshotBlockList);

  DeleteSnapshotBlocks(ADeleteCount);

  SetLength(FSnapshotBlockList, Length(FSnapshotBlockList) - ADeleteCount);

  TestChainAll(Self, FChainInstance, FAccounts, FSnapshotBlockList);
end;

procedure TDeleteTest.TestDeleteAccountBlocks;
begin
  DeleteAccountBlocks;
  TestChainAll(Self, FChainInstance, FAccounts, FSnapshotBlockList);
end;

procedure TDeleteTest.DeleteSnapshotBlocks(ACount: TUInt64);
var
  SnapshotBlocksToDelete: TArray<ISnapshotBlock>;
  SnapshotChunksDeleted: TArray<ISnapshotChunk>;
  DeletedBlocks: TDictionary<TAddress, TArray<IAccountBlock>>;
  Chunk: ISnapshotChunk;
  AccountBlock: IAccountBlock;
  Addr: TAddress;
  Blocks: TArray<IAccountBlock>;
  Prev: IAccountBlock;
  Block: IAccountBlock;
  HasStorageRedoLog: Boolean;
  Account: TAccount;
begin
  if ACount <= 0 then
    Exit;

  SnapshotBlocksToDelete := FChainInstance.GetSnapshotBlocks(FChainInstance.GetLatestSnapshotBlock.Hash, False, ACount);

  SnapshotChunksDeleted := FChainInstance.DeleteSnapshotBlocksToHeight(SnapshotBlocksToDelete[High(SnapshotBlocksToDelete)].Height);

  if (Length(SnapshotBlocksToDelete) <> Length(SnapshotChunksDeleted)) and
     (Length(SnapshotBlocksToDelete) + 1 <> Length(SnapshotChunksDeleted)) then
  begin
    raise Exception.CreateFmt('snapshotBlocksToDelete length: %d, snapshotChunksDeleted length: %d', [Length(SnapshotBlocksToDelete), Length(SnapshotChunksDeleted)]);
  end;

  DeletedBlocks := TDictionary<TAddress, TArray<IAccountBlock>>.Create;
  try
    for Chunk in SnapshotChunksDeleted do
    begin
      for AccountBlock in Chunk.AccountBlocks do
      begin
        if not DeletedBlocks.ContainsKey(AccountBlock.AccountAddress) then
          DeletedBlocks.Add(AccountBlock.AccountAddress, []);
        DeletedBlocks[AccountBlock.AccountAddress] := Concat(DeletedBlocks[AccountBlock.AccountAddress], [AccountBlock]);
      end;
    end;

    for Addr in DeletedBlocks.Keys do
    begin
      Blocks := DeletedBlocks[Addr];
      Prev := nil;
      for Block in Blocks do
      begin
        if Prev = nil then
        begin
          Prev := Block;
          Continue;
        end;
        if not Prev.Hash.IsEqual(Block.PrevHash) then
          raise Exception.CreateFmt('%s not a chain', [Addr.ToString]);
        if Block.Height - 1 <> Prev.Height then
          raise Exception.CreateFmt('%s not a chain', [Addr.ToString]);
        Prev := Block;
      end;
    end;
  finally
    DeletedBlocks.Free;
  end;

  HasStorageRedoLog := Length(SnapshotChunksDeleted[0].AccountBlocks) <= 0;
  for Account in FAccounts.Values do
  begin
    Account.DeleteSnapshotBlocks(FAccounts, SnapshotBlocksToDelete, HasStorageRedoLog);
  end;
end;

procedure TDeleteTest.DeleteAccountBlocks;
var
  UnconfirmedBlocks: TArray<IAccountBlock>;
  UnconfirmedBlock: IAccountBlock;
  Account: TAccount;
  DeletedAccountBlocks: TArray<IAccountBlock>;
  OnRoadBlocksCache: TDictionary<THash, Boolean>;
  DeletedHashMap: TDictionary<THash, Boolean>;
  FromBlockHash: THash;
  OnRoadSendBlock: IAccountBlock;
  DeletedBlock: IAccountBlock;
begin
  UnconfirmedBlocks := FChainInstance.Cache.GetUnconfirmedBlocks;
  if Length(UnconfirmedBlocks) <= 0 then
    Exit;

  UnconfirmedBlock := UnconfirmedBlocks[Random(Length(UnconfirmedBlocks))];
  Account := FAccounts[UnconfirmedBlock.AccountAddress];
  DeletedAccountBlocks := FChainInstance.DeleteAccountBlocks(Account.Addr, UnconfirmedBlock.Hash);

  OnRoadBlocksCache := TDictionary<THash, Boolean>.Create;
  DeletedHashMap := TDictionary<THash, Boolean>.Create;
  try
    DeleteMemAccountBlock(FAccounts, Account, UnconfirmedBlock, OnRoadBlocksCache, DeletedHashMap);

    for FromBlockHash in OnRoadBlocksCache.Keys do
    begin
      OnRoadSendBlock := nil;
      for Account in FAccounts.Values do
      begin
        if Account.SendBlocksMap.ContainsKey(FromBlockHash) then
        begin
          OnRoadSendBlock := Account.SendBlocksMap[FromBlockHash];
          Break;
        end;
      end;
      if OnRoadSendBlock <> nil then
      begin
        FAccounts[OnRoadSendBlock.ToAddress].AddOnRoadBlock(OnRoadSendBlock);
      end;
    end;

    if DeletedHashMap.Count <> Length(DeletedAccountBlocks) then
      raise Exception.Create('error');

    for DeletedBlock in DeletedAccountBlocks do
    begin
      if not DeletedHashMap.ContainsKey(DeletedBlock.Hash) then
        raise Exception.Create('error');
    end;

  finally
    OnRoadBlocksCache.Free;
    DeletedHashMap.Free;
  end;
end;

procedure TDeleteTest.DeleteMemAccountBlock(AAccounts: TDictionary<TAddress, TAccount>; AAccount: TAccount; AToBlock: IAccountBlock; AOnRoadBlocksCache: TDictionary<THash, Boolean>; ADeletedHashMap: TDictionary<THash, Boolean>);
type
  TDeleteSendBlockProc = reference to procedure(ASendBlock: IAccountBlock);
var
  DeleteSendBlock: TDeleteSendBlockProc;
  BlockToDelete: IAccountBlock;
  SendBlock: IAccountBlock;
begin
  DeleteSendBlock := procedure(ASendBlock: IAccountBlock)
  var
    ToAccount: TAccount;
    BlockNeedDelete: IAccountBlock;
  begin
    AOnRoadBlocksCache.Remove(ASendBlock.Hash);
    ToAccount := AAccounts[ASendBlock.ToAddress];
    BlockNeedDelete := nil;
    for BlockNeedDelete in ToAccount.ReceiveBlocksMap.Values do
    begin
      if BlockNeedDelete.FromBlockHash.IsEqual(ASendBlock.Hash) then
      begin
        DeleteMemAccountBlock(AAccounts, ToAccount, BlockNeedDelete, AOnRoadBlocksCache, ADeletedHashMap);
        Break;
      end;
    end;
    if BlockNeedDelete = nil then
    begin
      ToAccount.DeleteOnRoad(ASendBlock.Hash);
    end;
  end;

  while True do
  begin
    BlockToDelete := AAccount.LatestBlock;
    if (BlockToDelete = nil) or (BlockToDelete.Height < AToBlock.Height) then
      Break;

    if BlockToDelete.IsSendBlock then
      DeleteSendBlock(BlockToDelete)
    else
      AOnRoadBlocksCache.AddOrSetValue(BlockToDelete.FromBlockHash, True);

    for SendBlock in BlockToDelete.SendBlockList do
      DeleteSendBlock(SendBlock);

    ADeletedHashMap.AddOrSetValue(BlockToDelete.Hash, True);

    AAccount.DeleteAccountBlock(AAccounts, BlockToDelete.Hash);
    AAccount.RollbackLatestBlock;

    if BlockToDelete.Height <= AToBlock.Height then
      Break;
  end;
end;

initialization
  RegisterTest(TDeleteTest.Suite);

end.
