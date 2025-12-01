unit Ledger.Chain.Cache.AccountBlock;

interface

uses
  System.SysUtils, System.Classes,
  Vite.Common.Types, Interfaces.Core, Ledger.Chain.Cache.Cache;

type
  TCache = partial class
  public
    procedure InsertAccountBlock(ParaBlock: TAccountBlock);
    procedure RollbackAccountBlocks(ParaAccountBlocks: TArray<TAccountBlock>);
    function IsAccountBlockExisted(ParaHash: TBytes): Boolean;
    function GetLatestAccountBlock(ParaAddress: TAddress): TAccountBlock;
    function GetAccountBlockByHeight(ParaAddr: TAddress; ParaHeight: UInt64): TAccountBlock;
    function GetAccountBlockByHash(ParaHash: TBytes): TAccountBlock;
  private
    procedure InternalInsertAccountBlock(ParaBlock: TAccountBlock);
  end;

implementation

{ TCache }

procedure TCache.InsertAccountBlock(ParaBlock: TAccountBlock);
begin
  EnterCriticalSection(mMu);
  try
    InternalInsertAccountBlock(ParaBlock);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TCache.RollbackAccountBlocks(ParaAccountBlocks: TArray<TAccountBlock>);
var
  vBlock: TAccountBlock;
begin
  EnterCriticalSection(mMu);
  try
    mUnconfirmedPool.DeleteBlocks(ParaAccountBlocks);

    for vBlock in ParaAccountBlocks do
    begin
      mQuotaList.Sub(vBlock.AccountAddress, vBlock.Quota, vBlock.QuotaUsed);
    end;

    mHd.DeleteAccountBlocks(ParaAccountBlocks);

    mDs.DeleteAccountBlocks(ParaAccountBlocks);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.IsAccountBlockExisted(ParaHash: TBytes): Boolean;
begin
  EnterCriticalSection(mMu);
  try
    Result := mDs.IsAccountBlockExisted(ParaHash);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetLatestAccountBlock(ParaAddress: TAddress): TAccountBlock;
begin
  EnterCriticalSection(mMu);
  try
    Result := mHd.GetLatestAccountBlock(ParaAddress);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetAccountBlockByHeight(ParaAddr: TAddress; ParaHeight: UInt64): TAccountBlock;
begin
  EnterCriticalSection(mMu);
  try
    Result := mDs.GetAccountBlockByHeight(ParaAddr, ParaHeight);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetAccountBlockByHash(ParaHash: TBytes): TAccountBlock;
begin
  EnterCriticalSection(mMu);
  try
    Result := mDs.GetAccountBlock(ParaHash);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TCache.InternalInsertAccountBlock(ParaBlock: TAccountBlock);
begin
  mDs.InsertAccountBlock(ParaBlock);
  mHd.InsertAccountBlock(ParaBlock);
  mUnconfirmedPool.InsertAccountBlock(ParaBlock);
  mQuotaList.Add(ParaBlock.AccountAddress, ParaBlock.Quota, ParaBlock.QuotaUsed);
end;

end.
