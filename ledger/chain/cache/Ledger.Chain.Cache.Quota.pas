unit Ledger.Chain.Cache.Quota;

interface

uses
  Ledger.Chain.Cache.Account.Block,
  Ledger.Chain.Cache.Cache,
  Ledger.Chain.Cache.Dataset,
  Ledger.Chain.Cache.Hot.Data,
  Ledger.Chain.Cache.Init,
  Ledger.Chain.Cache.Interface,
  Ledger.Chain.Cache.Quota.List,
  Ledger.Chain.Cache.Snapshot.Block,
  Ledger.Chain.Cache.Unconfirmed,
  Ledger.Chain.Cache.Unconfirmed.Pool,
  System.SysUtils System.Classes,
  Vite.Common.Types Interfaces.Core Ledger.Chain.Cache.Cache;

type
  TCache = partial class
  public
    function GetQuotaUsedList(ParaAddr: TAddress): TArray<TQuotaInfo>;
    function GetGlobalQuota: TQuotaInfo;
    procedure ResetUnconfirmedQuotas(ParaUnconfirmedBlocks: TArray<TAccountBlock>);
  end;

implementation

{ TCache }

function TCache.GetQuotaUsedList(ParaAddr: TAddress): TArray<TQuotaInfo>;
begin
  EnterCriticalSection(mMu);
  try
    Result := mQuotaList.GetQuotaUsedList(ParaAddr);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetGlobalQuota: TQuotaInfo;
begin
  EnterCriticalSection(mMu);
  try
    Result := mQuotaList.GetGlobalQuota;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

procedure TCache.ResetUnconfirmedQuotas(ParaUnconfirmedBlocks: TArray<TAccountBlock>);
begin
  EnterCriticalSection(mMu);
  try
    mQuotaList.ResetUnconfirmedQuotas(ParaUnconfirmedBlocks);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

end.
