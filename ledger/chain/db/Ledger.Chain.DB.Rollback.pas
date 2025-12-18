unit Ledger.Chain.DB.Rollback;

interface

uses
  Common.DB.XLevelDB.Batch,
  Common.Types,
  Interfaces.Core.Account.Block,
  Ledger.Chain.DB.Flush,
  Ledger.Chain.DB.Flush.Test,
  Ledger.Chain.DB.Mem.DB.Test,
  Ledger.Chain.DB.Store,
  Ledger.Chain.DB.Store.Test,
  Ledger.Chain.DB.Unconfirmed.Batch,
  Ledger.Chain.DB.Write,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
	TRollbackHelper = class helper for TStore
	public
		procedure RollbackAccountBlocks( ParaRollbackBatch : TBatch; ParaAccountBlocks : TArray<TAccountBlock> );
		procedure RollbackAccountBlockByHash( ParaRollbackBatch : TBatch; ParaBlockHashList : TArray<THash> );
		procedure RollbackSnapshot( ParaRollbackBatch : TBatch );
	end;

implementation

{ TRollbackHelper }

procedure TRollbackHelper.RollbackAccountBlocks( ParaRollbackBatch : TBatch; ParaAccountBlocks : TArray<TAccountBlock> );
var
	vBlock : TAccountBlock;
begin
	// delete store.unconfirmedBatchMap
	for vBlock in ParaAccountBlocks do
	begin
		mUnconfirmedBatchs.Remove( vBlock.Hash );
	end;

	// write store.memDb
	PutMemDb( ParaRollbackBatch );
end;

procedure TRollbackHelper.RollbackAccountBlockByHash( ParaRollbackBatch : TBatch; ParaBlockHashList : TArray<THash> );
var
	vBlockHash : THash;
begin
	// delete store.unconfirmedBatchMap
	for vBlockHash in ParaBlockHashList do
	begin
		// remove
		mUnconfirmedBatchs.Remove( vBlockHash );
	end;

	// write store.memDb
	PutMemDb( ParaRollbackBatch );
end;

procedure TRollbackHelper.RollbackSnapshot( ParaRollbackBatch : TBatch );
begin
	// write store.memDb
	PutMemDb( ParaRollbackBatch );

	// set store.snapshotBatch
	mUnconfirmedBatchs.All(
		procedure( ParaBatch : TBatch )
		begin
			mSnapshotBatch.Append( ParaBatch );
		end
	);

	mSnapshotBatch.Append( ParaRollbackBatch );

	// reset
	mUnconfirmedBatchs.Clear;
end;

end.
