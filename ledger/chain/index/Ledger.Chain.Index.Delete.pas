unit Ledger.Chain.Index.Delete;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.Index,
  Common.DB.XLevelDB;

type
  TIndexDBHelper = class helper for TIndexDB
  public
    function RollbackAccountBlocks(ParaAccountBlocks: TArray<IAccountBlock>): Exception;
    function RollbackSnapshotBlocks(ParaDeletedSnapshotSegments: TArray<ISnapshotChunk>; ParaUnconfirmedBlocks: TArray<IAccountBlock>): Exception;
    procedure DeleteOnRoad(ParaToAddress: TAddress; ParaSendBlockHash: THash);
  private
    function Rollback(ParaBatch: IBatch; ParaDeletedSnapshotSegments: TArray<ISnapshotChunk>): Exception;
    procedure DeleteSnapshotBlock(ParaBatch: IBatch; ParaSnapshotBlock: ISnapshotBlock);
    function DeleteAccountBlocks(ParaBatch: IBatch; ParaBlocks: TArray<IAccountBlock>; ParaSendBlockHashMap: TDictionary<THash, IAccountBlock>): Exception;
    procedure DeleteSnapshotBlockHash(ParaBatch: IBatch; ParaSnapshotBlockHash: THash);
    procedure DeleteSnapshotBlockHeight(ParaBatch: IBatch; ParaSnapshotBlockHeight: UInt64);
    procedure DeleteAccountBlockHash(ParaBatch: IBatch; ParaAccountBlockHash: THash);
    procedure DeleteAccountBlockHeight(ParaBatch: IBatch; ParaAddr: TAddress; ParaHeight: UInt64);
    procedure DeleteReceiveInfo(ParaBatch: IBatch; ParaSendBlockHash: THash);
    procedure DeleteConfirmHeight(ParaBatch: IBatch; ParaAddr: TAddress; ParaHeight: UInt64);
    procedure DeleteConfirmCache(ParaBlockHash: THash);
  end;

implementation

uses
  Ledger.Chain.Utils,
  Ledger.Chain.Index.Insert,
  Ledger.Chain.Index.OnRoad;

{ TIndexDBHelper }

function TIndexDBHelper.RollbackAccountBlocks(ParaAccountBlocks: TArray<IAccountBlock>): Exception;
var
  vBatch: IBatch;
  vSnapshotChunk: ISnapshotChunk;
  vErr: Exception;
begin
  vBatch := mStore.NewBatch;
  vSnapshotChunk := TSnapshotChunk.Create;
  vSnapshotChunk.AccountBlocks := ParaAccountBlocks;
  vErr := Rollback(vBatch, [vSnapshotChunk]);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;

  mStore.RollbackAccountBlocks(vBatch, ParaAccountBlocks);
  Result := nil;
end;

function TIndexDBHelper.RollbackSnapshotBlocks(ParaDeletedSnapshotSegments: TArray<ISnapshotChunk>; ParaUnconfirmedBlocks: TArray<IAccountBlock>): Exception;
var
  vBatch: IBatch;
  vErr: Exception;
  vBlock: IAccountBlock;
begin
  vBatch := mStore.NewBatch;
  vErr := Rollback(vBatch, ParaDeletedSnapshotSegments);
  if vErr <> nil then
  begin
    Result := vErr;
    Exit;
  end;

  mStore.RollbackSnapshot(vBatch);

  for vBlock in ParaUnconfirmedBlocks do
  begin
    vErr := InsertAccountBlock(vBlock);
    if vErr <> nil then
    begin
      Result := vErr;
      Exit;
    end;
  end;

  Result := nil;
end;

procedure TIndexDBHelper.DeleteOnRoad(ParaToAddress: TAddress; ParaSendBlockHash: THash);
var
  vBatch: IBatch;
begin
  vBatch := mStore.NewBatch;
  DeleteOnRoad(vBatch, ParaToAddress, ParaSendBlockHash);
  mStore.WriteDirectly(vBatch);
end;

function TIndexDBHelper.Rollback(ParaBatch: IBatch; ParaDeletedSnapshotSegments: TArray<ISnapshotChunk>): Exception;
var
  vOpenSendBlock: TDictionary<THash, IAccountBlock>;
  vSeg: ISnapshotChunk;
  vErr: Exception;
  vSendBlockHash: THash;
  vSendBlock: IAccountBlock;
begin
  vOpenSendBlock := TDictionary<THash, IAccountBlock>.Create;
  try
    for vSeg in ParaDeletedSnapshotSegments do
    begin
      vErr := DeleteAccountBlocks(ParaBatch, vSeg.AccountBlocks, vOpenSendBlock);
      if vErr <> nil then
      begin
        Result := vErr;
        Exit;
      end;
      DeleteSnapshotBlock(ParaBatch, vSeg.SnapshotBlock);
    end;

    for vSendBlockHash in vOpenSendBlock.Keys do
    begin
      vSendBlock := vOpenSendBlock[vSendBlockHash];
      DeleteOnRoad(ParaBatch, vSendBlock.ToAddress, vSendBlockHash);
      DeleteReceiveInfo(ParaBatch, vSendBlockHash);
    end;
    Result := nil;
  finally
    vOpenSendBlock.Free;
  end;
end;

procedure TIndexDBHelper.DeleteSnapshotBlock(ParaBatch: IBatch; ParaSnapshotBlock: ISnapshotBlock);
var
  vAddr: TAddress;
  vHashHeight: IHashHeight;
begin
  if ParaSnapshotBlock <> nil then
  begin
    DeleteSnapshotBlockHash(ParaBatch, ParaSnapshotBlock.Hash);
    DeleteSnapshotBlockHeight(ParaBatch, ParaSnapshotBlock.Height);

    for vAddr in ParaSnapshotBlock.SnapshotContent.Keys do
    begin
      vHashHeight := ParaSnapshotBlock.SnapshotContent[vAddr];
      DeleteConfirmHeight(ParaBatch, vAddr, vHashHeight.Height);
    end;
  end;
end;

function TIndexDBHelper.DeleteAccountBlocks(ParaBatch: IBatch; ParaBlocks: TArray<IAccountBlock>; ParaSendBlockHashMap: TDictionary<THash, IAccountBlock>): Exception;
var
  vBlock: IAccountBlock;
  vSendBlock: IAccountBlock;
begin
  Result := nil;
  for vBlock in ParaBlocks do
  begin
    DeleteAccountBlockHash(ParaBatch, vBlock.Hash);
    DeleteAccountBlockHeight(ParaBatch, vBlock.AccountAddress, vBlock.Height);

    if vBlock.IsReceiveBlock then
    begin
      if ParaSendBlockHashMap.ContainsKey(vBlock.FromBlockHash) then
      begin
        ParaSendBlockHashMap.Remove(vBlock.FromBlockHash);
        DeleteReceiveInfo(ParaBatch, vBlock.FromBlockHash);
      end
      else
      begin
        InsertOnRoad(ParaBatch, vBlock.AccountAddress, vBlock.FromBlockHash);
        InsertReceiveInfo(ParaBatch, vBlock.FromBlockHash, UnreceivedFlag);
      end;

      for vSendBlock in vBlock.SendBlockList do
      begin
        DeleteAccountBlockHash(ParaBatch, vSendBlock.Hash);
        ParaSendBlockHashMap.Add(vSendBlock.Hash, vSendBlock);
        if vSendBlock.BlockType = TBlockType.SendCreate then
        begin
          DeleteConfirmCache(vSendBlock.Hash);
        end;
      end;
    end
    else
    begin
      ParaSendBlockHashMap.Add(vBlock.Hash, vBlock);
      if vBlock.BlockType = TBlockType.SendCreate then
      begin
        DeleteConfirmCache(vBlock.Hash);
      end;
    end;
  end;
end;

procedure TIndexDBHelper.DeleteSnapshotBlockHash(ParaBatch: IBatch; ParaSnapshotBlockHash: THash);
var
  vKey: TBytes;
begin
  vKey := TChainUtils.CreateSnapshotBlockHashKey(ParaSnapshotBlockHash).Bytes;
  mCache.Delete(string(vKey));
  ParaBatch.Delete(vKey);
end;

procedure TIndexDBHelper.DeleteSnapshotBlockHeight(ParaBatch: IBatch; ParaSnapshotBlockHeight: UInt64);
var
  vKey: TBytes;
begin
  vKey := TChainUtils.CreateSnapshotBlockHeightKey(ParaSnapshotBlockHeight).Bytes;
  mCache.Delete(string(vKey));
  ParaBatch.Delete(vKey);
end;

procedure TIndexDBHelper.DeleteAccountBlockHash(ParaBatch: IBatch; ParaAccountBlockHash: THash);
var
  vKey: TBytes;
begin
  vKey := TChainUtils.CreateAccountBlockHashKey(ParaAccountBlockHash).Bytes;
  mCache.Delete(string(vKey));
  ParaBatch.Delete(vKey);
end;

procedure TIndexDBHelper.DeleteAccountBlockHeight(ParaBatch: IBatch; ParaAddr: TAddress; ParaHeight: UInt64);
var
  vKey: TBytes;
begin
  vKey := TChainUtils.CreateAccountBlockHeightKey(ParaAddr, ParaHeight).Bytes;
  mCache.Delete(string(vKey));
  ParaBatch.Delete(vKey);
end;

procedure TIndexDBHelper.DeleteReceiveInfo(ParaBatch: IBatch; ParaSendBlockHash: THash);
var
  vKey: TBytes;
begin
  vKey := TChainUtils.CreateReceiveKey(ParaSendBlockHash).Bytes;
  ParaBatch.Delete(vKey);
  mCache.Delete(string(vKey));
end;

procedure TIndexDBHelper.DeleteConfirmHeight(ParaBatch: IBatch; ParaAddr: TAddress; ParaHeight: UInt64);
var
  vKey: TBytes;
begin
  vKey := TChainUtils.CreateConfirmHeightKey(ParaAddr, ParaHeight).Bytes;
  ParaBatch.Delete(vKey);
end;

procedure TIndexDBHelper.DeleteConfirmCache(ParaBlockHash: THash);
begin
  mSendCreateBlockHashCache.Remove(ParaBlockHash);
end;

end.