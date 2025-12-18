unit Ledger.Chain.DB.Write;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	Common.Types,
	Common.DB.XLevelDB.Batch,
	Interfaces.Core.Account.Block,
	Ledger.Chain.DB.Store;

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
