unit Ledger.Chain.Cache.Quota;

interface

uses
  System.SysUtils, System.Classes,
  Vite.Common.Types, Interfaces.Core, Ledger.Chain.Cache.Cache;

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
