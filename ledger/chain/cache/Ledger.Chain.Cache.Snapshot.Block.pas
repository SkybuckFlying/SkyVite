unit Ledger.Chain.Cache.SnapshotBlock;

interface

uses
  Ledger.Chain.Cache.Account.Block,
  Ledger.Chain.Cache.Cache,
  Ledger.Chain.Cache.Dataset,
  Ledger.Chain.Cache.Hot.Data,
  Ledger.Chain.Cache.Init,
  Ledger.Chain.Cache.Interface,
  Ledger.Chain.Cache.Quota,
  Ledger.Chain.Cache.Quota.List,
  Ledger.Chain.Cache.Unconfirmed,
  Ledger.Chain.Cache.Unconfirmed.Pool,
  System.SysUtils System.Classes,
  Vite.Common.Types Interfaces.Core Ledger.Chain.Cache.Cache;

type
  TCache = partial class
  public
    procedure InsertSnapshotBlock(ParaSnapshotBlock: TSnapshotBlock; ParaConfirmedBlocks: TArray<TAccountBlock>);
    procedure RollbackSnapshotBlocks(ParaDeletedChunks: TArray<TSnapshotChunk>; ParaUnconfirmedBlocks: TArray<TAccountBlock>);
    function IsSnapshotBlockExisted(ParaHash: TBytes): Boolean;
    function GetLatestSnapshotBlock: TSnapshotBlock;
    function GetSnapshotHeaderByHash(ParaHash: TBytes): TSnapshotBlock;
    function GetSnapshotBlockByHash(ParaHash: TBytes): TSnapshotBlock;
    function GetSnapshotHeaderByHeight(ParaHeight: UInt64): TSnapshotBlock;
    function GetSnapshotBlockByHeight(ParaHeight: UInt64): TSnapshotBlock;
  end;

implementation

{ TCache }

procedure TCache.InsertSnapshotBlock(ParaSnapshotBlock: TSnapshotBlock; ParaConfirmedBlocks: TArray<TAccountBlock>);
begin
  EnterCriticalSection(mMu);
  try
    mDs.InsertSnapshotBlock(ParaSnapshotBlock);
    mHd.SetLatestSnapshotBlock(ParaSnapshotBlock);
    mUnconfirmedPool.DeleteBlocks(ParaConfirmedBlocks);
    mQuotaList.NewNext(ParaConfirmedBlocks);

    if mDs.IsLarge then
    begin
      mDs.DeleteAccountBlocks(ParaConfirmedBlocks);
    end
    else
    begin
      mDs.DelayDeleteAccountBlocks(ParaConfirmedBlocks, 10 * 1000);
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TCache.RollbackSnapshotBlocks(ParaDeletedChunks: TArray<TSnapshotChunk>; ParaUnconfirmedBlocks: TArray<TAccountBlock>);
var
  vFirstSnapshotBlock: TSnapshotBlock;
  vSnapshotBlock: TSnapshotBlock;
  vChunk: TSnapshotChunk;
  vBlock: TAccountBlock;
begin
  vFirstSnapshotBlock := nil;
  for vChunk in ParaDeletedChunks do
  begin
    if Assigned(vChunk.SnapshotBlock) then
    begin
      vFirstSnapshotBlock := vChunk.SnapshotBlock;
      break;
    end;
  end;

  if not Assigned(vFirstSnapshotBlock) then
  begin
    vSnapshotBlock := mChain.QueryLatestSnapshotBlock;
  end
  else
  begin
    vSnapshotBlock := mChain.GetSnapshotBlockByHeight(vFirstSnapshotBlock.Height - 1);
  end;

  EnterCriticalSection(mMu);
  try
    mHd.SetLatestSnapshotBlock(vSnapshotBlock);
    mQuotaList.Rollback(ParaDeletedChunks);
    mUnconfirmedPool.DeleteAllBlocks;

    for vChunk in ParaDeletedChunks do
    begin
      if Assigned(vChunk.SnapshotBlock) then
      begin
        mDs.DeleteSnapshotBlock(vChunk.SnapshotBlock);
      end;
      mHd.DeleteAccountBlocks(vChunk.AccountBlocks);
      mDs.DeleteAccountBlocks(vChunk.AccountBlocks);
    end;

    for vBlock in ParaUnconfirmedBlocks do
    begin
      InternalInsertAccountBlock(vBlock);
    end;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.IsSnapshotBlockExisted(ParaHash: TBytes): Boolean;
begin
  EnterCriticalSection(mMu);
  try
    Result := mDs.IsSnapshotBlockExisted(ParaHash);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetLatestSnapshotBlock: TSnapshotBlock;
begin
  EnterCriticalSection(mMu);
  try
    Result := mHd.GetLatestSnapshotBlock;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetSnapshotHeaderByHash(ParaHash: TBytes): TSnapshotBlock;
begin
  EnterCriticalSection(mMu);
  try
    Result := mDs.GetSnapshotBlock(ParaHash);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetSnapshotBlockByHash(ParaHash: TBytes): TSnapshotBlock;
begin
  EnterCriticalSection(mMu);
  try
    Result := mDs.GetSnapshotBlock(ParaHash);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetSnapshotHeaderByHeight(ParaHeight: UInt64): TSnapshotBlock;
begin
  EnterCriticalSection(mMu);
  try
    Result := mDs.GetSnapshotBlockByHeight(ParaHeight);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetSnapshotBlockByHeight(ParaHeight: UInt64): TSnapshotBlock;
begin
  EnterCriticalSection(mMu);
  try
    Result := mDs.GetSnapshotBlockByHeight(ParaHeight);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

end.
