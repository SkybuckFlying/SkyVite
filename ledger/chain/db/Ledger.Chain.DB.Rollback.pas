unit Ledger.Chain.Db.Rollback;

interface

uses
  System.SysUtils, System.Classes,
  Vite.Common.Types, Interfaces.Core, Ledger.Chain.Db.Store, Common.DB.XLevelDB;

type
  TStore = partial class
  public
    procedure RollbackAccountBlocks(ParaRollbackBatch: TLevelDBBatch; ParaAccountBlocks: TArray<TAccountBlock>);
    procedure RollbackAccountBlockByHash(ParaRollbackBatch: TLevelDBBatch; ParaBlockHashList: TArray<TBytes>);
    procedure RollbackSnapshot(ParaRollbackBatch: TLevelDBBatch);
  end;

implementation

{ TStore }

procedure TStore.RollbackAccountBlocks(ParaRollbackBatch: TLevelDBBatch; ParaAccountBlocks: TArray<TAccountBlock>);
var
  vBlock: TAccountBlock;
begin
  for vBlock in ParaAccountBlocks do
  begin
    mUnconfirmedBatchs.Remove(vBlock.Hash);
  end;
  PutMemDb(ParaRollbackBatch);
end;

procedure TStore.RollbackAccountBlockByHash(ParaRollbackBatch: TLevelDBBatch; ParaBlockHashList: TArray<TBytes>);
var
  vBlockHash: TBytes;
begin
  for vBlockHash in ParaBlockHashList do
  begin
    mUnconfirmedBatchs.Remove(vBlockHash);
  end;
  PutMemDb(ParaRollbackBatch);
end;

procedure TStore.RollbackSnapshot(ParaRollbackBatch: TLevelDBBatch);
begin
  PutMemDb(ParaRollbackBatch);
  mUnconfirmedBatchs.All(procedure(ParaBatch: TLevelDBBatch)
    begin
      mSnapshotBatch.Append(ParaBatch);
    end);
  mSnapshotBatch.Append(ParaRollbackBatch);
  mUnconfirmedBatchs.Clear;
end;

end.