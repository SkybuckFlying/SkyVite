unit Ledger.Chain.DB.Flush;

interface

uses
	System.SysUtils,
	System.Classes,
	System.Generics.Collections,
	Common.Types,
	Common.DB.XLevelDB.Batch,
	Ledger.Chain.DB.Store;

type
	TStoreHelper = class helper for TStore
	private
		class var mBatchPool : TObjectStack<TBatch>;
		class function GetNewBatch : TBatch; static;
		procedure ReleaseFlushingBatch;
	public
		function Id : THash;
		procedure Prepare;
		procedure CancelPrepare;
		function RedoLog : TBytes;
		function Commit : Boolean;
		function PatchRedoLog( ParaRedoLog : TBytes ) : Boolean;
		procedure AfterCommit;
		procedure BeforeRecover( ParaRedoLog : TBytes );
		procedure AfterRecover;
	end;

implementation

uses
	Common.DB.Memdb;

{ TStoreHelper }

class function TStoreHelper.GetNewBatch : TBatch;
begin
	if ( mBatchPool <> nil ) and ( mBatchPool.Count > 0 ) then
	begin
		Result := mBatchPool.Pop;
	end else
	begin
		Result := TBatch.Create;
	end;
	Result.Reset;
end;

procedure TStoreHelper.ReleaseFlushingBatch;
begin
	if mFlushingBatch <> nil then
	begin
		if mBatchPool = nil then
		begin
			mBatchPool := TObjectStack<TBatch>.Create;
		end;
		mBatchPool.Push( mFlushingBatch );
		mFlushingBatch := nil;
	end;
end;

function TStoreHelper.Id : THash;
begin
	Result := mId;
end;

procedure TStoreHelper.Prepare;
begin
	if mFlushingBatch <> nil then
	begin
		raise Exception.Create( 'prepare repeatedly' );
	end;

	mFlushingBatch := mSnapshotBatch;
	mSnapshotBatch := GetNewBatch;
end;

procedure TStoreHelper.CancelPrepare;
var
	vCurrentSnapshotBatch : TBatch;
begin
	vCurrentSnapshotBatch := mSnapshotBatch;
	mSnapshotBatch := GetNewBatch;
	
	mSnapshotBatch.Append( mFlushingBatch );
	mSnapshotBatch.Append( vCurrentSnapshotBatch );

	ReleaseFlushingBatch;
end;

function TStoreHelper.RedoLog : TBytes;
begin
	Result := mFlushingBatch.Dump;
end;

function TStoreHelper.Commit : Boolean;
begin
	Result := mDB.Write( mFlushingBatch, nil );
end;

function TStoreHelper.PatchRedoLog( ParaRedoLog : TBytes ) : Boolean;
var
	vBatch : TBatch;
begin
	Result := False;
	vBatch := TBatch.Create;
	try
		if not vBatch.Load( ParaRedoLog ) then
		begin
			Exit;
		end;

		Result := mDB.Write( vBatch, nil );
	finally
		vBatch.Free;
	end;
end;

procedure TStoreHelper.AfterCommit;
begin
	ReleaseFlushingBatch;

	mMemDbMu.Enter;
	try
		mMemDb.Free;
		mMemDb := TMemDB.Create;

		mSnapshotBatch.Replay( mMemDb );

		mUnconfirmedBatchs.All(
			procedure( ParaBatch : TBatch )
			begin
				ParaBatch.Replay( mMemDb );
			end
		);
	finally
		mMemDbMu.Leave;
	end;
end;

procedure TStoreHelper.BeforeRecover( ParaRedoLog : TBytes );
begin
end;

procedure TStoreHelper.AfterRecover;
var
	vFunc : TProc;
begin
	for vFunc in mAfterRecoverFuncs do
	begin
		vFunc();
	end;
end;

initialization
	TStoreHelper.mBatchPool := nil;

finalization
	if TStoreHelper.mBatchPool <> nil then
	begin
		TStoreHelper.mBatchPool.Free;
	end;

end.
