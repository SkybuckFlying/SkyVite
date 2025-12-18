unit Ledger.Chain.Index.Insert;

interface

uses
  Common.DB.XLevelDB,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.FileManager,
  Ledger.Chain.Index,
  Ledger.Chain.Index.Account,
  Ledger.Chain.Index.Account.Block,
  Ledger.Chain.Index.Cache,
  Ledger.Chain.Index.Delete,
  Ledger.Chain.Index.Index.DB,
  Ledger.Chain.Index.Index.DB.Test,
  Ledger.Chain.Index.Interface,
  Ledger.Chain.Index.Onroad,
  Ledger.Chain.Index.Snapshot.Block,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  TIndexDBHelper = class helper for TIndexDB
  public
    function InsertAccountBlock(ParaAccountBlock: IAccountBlock): Exception;
    procedure InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock; ParaConfirmedBlocks: TArray<IAccountBlock>; ParaSnapshotBlockLocation: ILocation; ParaAbLocationsList: TDictionary<THash, ILocation>);
  private
    function InternalInsertAccountBlock(ParaBatch: IBatch; ParaAccountBlock: IAccountBlock): Exception;
    procedure InsertAbHashHeight(ParaBatch: IBatch; ParaBlock: IAccountBlock; ParaValue: TBytes);
    procedure InsertConfirmCache(ParaBlockHash: THash; ParaSnapshotHeight: UInt64);
    procedure InsertAbHeightLocation(ParaBatch: IBatch; ParaBlock: IAccountBlock; ParaLocation: ILocation);
    procedure InsertSbHashHeight(ParaBatch: IBatch; ParaHash: THash; ParaHeight: UInt64);
    procedure InsertSbHeightLocation(ParaBatch: IBatch; ParaBlock: ISnapshotBlock; ParaLocation: ILocation);
    procedure InsertReceiveInfo(ParaBatch: IBatch; ParaSendBlockHash: THash; ParaValue: TBytes);
  end;

implementation

uses
  Ledger.Chain.Utils,
  Ledger.Chain.Index.Account,
  Ledger.Chain.Index.OnRoad;

const
  UnreceivedFlag: TBytes = [0];

{ TIndexDBHelper }

function TIndexDBHelper.InsertAccountBlock(ParaAccountBlock: IAccountBlock): Exception;
var
  vBatch: IBatch;
  vErr: Exception;
begin
  vBatch := mStore.NewBatch;
  vErr := InternalInsertAccountBlock(vBatch, ParaAccountBlock);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;
  mStore.WriteAccountBlock(vBatch, ParaAccountBlock);
  Result := nil;
end;

procedure TIndexDBHelper.InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock; ParaConfirmedBlocks: TArray<IAccountBlock>; ParaSnapshotBlockLocation: ILocation; ParaAbLocationsList: TDictionary<THash, ILocation>);
var
  vBatch: IBatch;
  vHeightBytes: TBytes;
  vAddr: TAddress;
  vHashHeight: IHashHeight;
  vBlock: IAccountBlock;
begin
  vBatch := mStore.NewBatch;
  vHeightBytes := TChainUtils.Uint64ToBytes(ParaSnapshotBlock.Height);
  InsertSbHashHeight(vBatch, ParaSnapshotBlock.Hash, ParaSnapshotBlock.Height);
  InsertSbHeightLocation(vBatch, ParaSnapshotBlock, ParaSnapshotBlockLocation);

  for vAddr in ParaSnapshotBlock.SnapshotContent.Keys do
  begin
    vHashHeight := ParaSnapshotBlock.SnapshotContent[vAddr];
    vBatch.Put(TChainUtils.CreateConfirmHeightKey(vAddr, vHashHeight.Height).Bytes, vHeightBytes);
  end;

  for vBlock in ParaConfirmedBlocks do
  begin
    InsertAbHeightLocation(vBatch, vBlock, ParaAbLocationsList[vBlock.Hash]);
    if vBlock.BlockType = TBlockType.SendCreate then
    begin
      InsertConfirmCache(vBlock.Hash, ParaSnapshotBlock.Height);
    end;
  end;

  mStore.WriteSnapshot(vBatch, ParaConfirmedBlocks);
end;

function TIndexDBHelper.InternalInsertAccountBlock(ParaBatch: IBatch; ParaAccountBlock: IAccountBlock): Exception;
var
  vBlockHash: THash;
  vOk: Boolean;
  vErr: Exception;
  vAddrHeightValue: TBytes;
  vSendBlock: IAccountBlock;
begin
  Result := nil;
  vBlockHash := ParaAccountBlock.Hash;

  vOk := HasAccount(ParaAccountBlock.AccountAddress);
  if not vOk then
  begin
    CreateAccount(ParaBatch, ParaAccountBlock.AccountAddress);
  end;

  vAddrHeightValue := TBytes.Concat(ParaAccountBlock.AccountAddress.Bytes, TChainUtils.Uint64ToBytes(ParaAccountBlock.Height));
  InsertAbHashHeight(ParaBatch, ParaAccountBlock, vAddrHeightValue);
  ParaBatch.Put(TChainUtils.CreateAccountBlockHeightKey(ParaAccountBlock.AccountAddress, ParaAccountBlock.Height).Bytes, vBlockHash.Bytes);

  if ParaAccountBlock.IsReceiveBlock then
  begin
    if ParaAccountBlock.BlockType <> TBlockType.GenesisReceive then
    begin
      InsertReceiveInfo(ParaBatch, ParaAccountBlock.FromBlockHash, vBlockHash.Bytes);
      DeleteOnRoad(ParaBatch, ParaAccountBlock.AccountAddress, ParaAccountBlock.FromBlockHash);
    end;
  end
  else
  begin
    InsertReceiveInfo(ParaBatch, ParaAccountBlock.Hash, UnreceivedFlag);
    InsertOnRoad(ParaBatch, ParaAccountBlock.ToAddress, ParaAccountBlock.Hash);
    if ParaAccountBlock.BlockType = TBlockType.SendCreate then
    begin
      InsertConfirmCache(ParaAccountBlock.Hash, 0);
    end;
  end;

  for vSendBlock in ParaAccountBlock.SendBlockList do
  begin
    InsertReceiveInfo(ParaBatch, vSendBlock.Hash, UnreceivedFlag);
    InsertAbHashHeight(ParaBatch, vSendBlock, vAddrHeightValue);
    InsertOnRoad(ParaBatch, vSendBlock.ToAddress, vSendBlock.Hash);
    if vSendBlock.BlockType = TBlockType.SendCreate then
    begin
      InsertConfirmCache(vSendBlock.Hash, 0);
    end;
  end;
end;

procedure TIndexDBHelper.InsertAbHashHeight(ParaBatch: IBatch; ParaBlock: IAccountBlock; ParaValue: TBytes);
var
  vKey: TBytes;
begin
  vKey := TChainUtils.CreateAccountBlockHashKey(ParaBlock.Hash).Bytes;
  mCache.Set(string(vKey), ParaValue);
  ParaBatch.Put(vKey, ParaValue);
end;

procedure TIndexDBHelper.InsertConfirmCache(ParaBlockHash: THash; ParaSnapshotHeight: UInt64);
begin
  mSendCreateBlockHashCache.Add(ParaBlockHash, TObject(ParaSnapshotHeight));
end;

procedure TIndexDBHelper.InsertAbHeightLocation(ParaBatch: IBatch; ParaBlock: IAccountBlock; ParaLocation: ILocation);
var
  vKey: TBytes;
  vValue: TBytes;
begin
  vKey := TChainUtils.CreateAccountBlockHeightKey(ParaBlock.AccountAddress, ParaBlock.Height).Bytes;
  vValue := TBytes.Concat(ParaBlock.Hash.Bytes, TChainUtils.SerializeLocation(ParaLocation));
  mCache.Set(string(vKey), vValue);
  ParaBatch.Put(vKey, vValue);
end;

procedure TIndexDBHelper.InsertSbHashHeight(ParaBatch: IBatch; ParaHash: THash; ParaHeight: UInt64);
var
  vKey: TBytes;
  vValue: TBytes;
begin
  vKey := TChainUtils.CreateSnapshotBlockHashKey(ParaHash).Bytes;
  vValue := TChainUtils.Uint64ToBytes(ParaHeight);
  mCache.Set(string(vKey), vValue);
  ParaBatch.Put(vKey, vValue);
end;

procedure TIndexDBHelper.InsertSbHeightLocation(ParaBatch: IBatch; ParaBlock: ISnapshotBlock; ParaLocation: ILocation);
var
  vKey: TBytes;
  vValue: TBytes;
begin
  vKey := TChainUtils.CreateSnapshotBlockHeightKey(ParaBlock.Height).Bytes;
  vValue := TBytes.Concat(ParaBlock.Hash.Bytes, TChainUtils.SerializeLocation(ParaLocation));
  mCache.Set(string(vKey), vValue);
  ParaBatch.Put(vKey, vValue);
end;

procedure TIndexDBHelper.InsertReceiveInfo(ParaBatch: IBatch; ParaSendBlockHash: THash; ParaValue: TBytes);
var
  vKey: TBytes;
begin
  vKey := TChainUtils.CreateReceiveKey(ParaSendBlockHash).Bytes;
  mCache.Set(string(vKey), ParaValue);
  ParaBatch.Put(vKey, ParaValue);
end;

end.
