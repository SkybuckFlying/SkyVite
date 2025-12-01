unit Ledger.Chain.Db.Write;

interface

uses
  System.SysUtils, System.Classes,
  Vite.Common.Types, Interfaces.Core, Ledger.Chain.Db.Store, Common.DB.XLevelDB;

type
  TStore = partial class
  public
    procedure WriteDirectly(ParaBatch: TLevelDBBatch);
    procedure WriteAccountBlock(ParaBatch: TLevelDBBatch; ParaBlock: TAccountBlock);
    procedure WriteAccountBlockByHash(ParaBatch: TLevelDBBatch; ParaBlockHash: TBytes);
    procedure WriteSnapshot(ParaSnapshotBatch: TLevelDBBatch; ParaAccountBlocks: TArray<TAccountBlock>);
    procedure WriteSnapshotByHash(ParaSnapshotBatch: TLevelDBBatch; ParaBlockHashList: TArray<TBytes>);
  end;

implementation

{ TStore }

procedure TStore.WriteDirectly(ParaBatch: TLevelDBBatch);
begin
  PutMemDb(ParaBatch);
  mSnapshotBatch.Append(ParaBatch);
end;

procedure TStore.WriteAccountBlock(ParaBatch: TLevelDBBatch; ParaBlock: TAccountBlock);
begin
  WriteAccountBlockByHash(ParaBatch, ParaBlock.Hash);
end;

procedure TStore.WriteAccountBlockByHash(ParaBatch: TLevelDBBatch; ParaBlockHash: TBytes);
begin
  PutMemDb(ParaBatch);
  mUnconfirmedBatchs.Put(ParaBlockHash, ParaBatch);
end;

procedure TStore.WriteSnapshot(ParaSnapshotBatch: TLevelDBBatch; ParaAccountBlocks: TArray<TAccountBlock>);
var
  vAccountBlockHashList: TArray<TBytes>;
  i: Integer;
  vAccountBlock: TAccountBlock;
begin
  SetLength(vAccountBlockHashList, Length(ParaAccountBlocks));
  for i := 0 to High(ParaAccountBlocks) do
  begin
    vAccountBlock := ParaAccountBlocks[i];
    vAccountBlockHashList[i] := vAccountBlock.Hash;
  end;
  WriteSnapshotByHash(ParaSnapshotBatch, vAccountBlockHashList);
end;

procedure TStore.WriteSnapshotByHash(ParaSnapshotBatch: TLevelDBBatch; ParaBlockHashList: TArray<TBytes>);
var
  vBlockHash: TBytes;
  vPair: TPair<TLevelDBBatch, Boolean>;
  vBatch: TLevelDBBatch;
begin
  PutMemDb(ParaSnapshotBatch);
  for vBlockHash in ParaBlockHashList do
  begin
    vPair := mUnconfirmedBatchs.Get(vBlockHash);
    if not vPair.Value then
    begin
      raise Exception.CreateFmt('store.WriteSnapshot failed, account block hash %s batch is not existed', [vBlockHash.ToString]);
    end;
    vBatch := vPair.Key;
    mSnapshotBatch.Append(vBatch);
    mUnconfirmedBatchs.Remove(vBlockHash);
  end;
  mSnapshotBatch.Append(ParaSnapshotBatch);
end;

end.