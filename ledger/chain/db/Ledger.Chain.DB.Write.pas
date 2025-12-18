unit Ledger.Chain.DB.Write;

interface

uses
  Common.DB.XLevelDB.Batch,
  Common.Types,
  Interfaces.Core.Account.Block,
  Ledger.Chain.DB.Flush,
  Ledger.Chain.DB.Flush.Test,
  Ledger.Chain.DB.Mem.DB.Test,
  Ledger.Chain.DB.Rollback,
  Ledger.Chain.DB.Store,
  Ledger.Chain.DB.Store.Test,
  Ledger.Chain.DB.Unconfirmed.Batch,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
	TWriteHelper = class helper for TStore
	public
		procedure WriteDirectly( ParaBatch : TBatch );
		procedure WriteAccountBlock( ParaBatch : TBatch; ParaBlock : TAccountBlock );
		procedure WriteAccountBlockByHash( ParaBatch : TBatch; ParaBlockHash : THash );
		procedure WriteSnapshot( ParaSnapshotBatch : TBatch; ParaAccountBlocks : TArray<TAccountBlock> );
		procedure WriteSnapshotByHash( ParaSnapshotBatch : TBatch; ParaBlockHashList : TArray<THash> );
	end;

implementation

{ TWriteHelper }

procedure TWriteHelper.WriteDirectly( ParaBatch : TBatch );
begin
	PutMemDb( ParaBatch );
	mSnapshotBatch.Append( ParaBatch );
end;

procedure TWriteHelper.WriteAccountBlock( ParaBatch : TBatch; ParaBlock : TAccountBlock );
begin
	WriteAccountBlockByHash( ParaBatch, ParaBlock.Hash );
end;

procedure TWriteHelper.WriteAccountBlockByHash( ParaBatch : TBatch; ParaBlockHash : THash );
begin
	// write store.memDb
	PutMemDb( ParaBatch );

	// write store.unconfirmedBatch
	mUnconfirmedBatchs.Put( ParaBlockHash, ParaBatch );
end;

procedure TWriteHelper.WriteSnapshot( ParaSnapshotBatch : TBatch; ParaAccountBlocks : TArray<TAccountBlock> );
var
	vAccountBlockHashList : TArray<THash>;
	vIndex : Integer;
begin
	SetLength( vAccountBlockHashList, Length( ParaAccountBlocks ) );

	for vIndex := 0 to High( ParaAccountBlocks ) do
	begin
		vAccountBlockHashList[vIndex] := ParaAccountBlocks[vIndex].Hash;
	end;

	WriteSnapshotByHash( ParaSnapshotBatch, vAccountBlockHashList );
end;

procedure TWriteHelper.WriteSnapshotByHash( ParaSnapshotBatch : TBatch; ParaBlockHashList : TArray<THash> );
var
	vBlockHash : THash;
	vBatch : TBatch;
begin
	// write store.memDb
	PutMemDb( ParaSnapshotBatch );

	for vBlockHash in ParaBlockHashList do
	begin
		if not mUnconfirmedBatchs.Get( vBlockHash, vBatch ) then
		begin
			raise Exception.Create( Format( 'store.WriteSnapshot failed, account block hash %s batch is not existed', [vBlockHash.ToString] ) );
		end;

		// patch
		mSnapshotBatch.Append( vBatch );

		// remove
		mUnconfirmedBatchs.Remove( vBlockHash );
	end;

	// write store snapshot batch
	mSnapshotBatch.Append( ParaSnapshotBatch );
end;

end.
