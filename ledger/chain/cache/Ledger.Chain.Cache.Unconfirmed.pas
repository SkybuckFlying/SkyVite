unit Ledger.Chain.Cache.Unconfirmed;

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
  Ledger.Chain.Cache.Snapshot.Block,
  Ledger.Chain.Cache.Unconfirmed.Pool,
  System.SysUtils System.Classes,
  Vite.Common.Types Interfaces.Core Ledger.Chain.Cache.Cache;

type
  TCache = partial class
  public
    function GetUnconfirmedBlocks: TArray<TAccountBlock>;
    function GetUnconfirmedBlocksByAddress(ParaAddress: TAddress): TArray<TAccountBlock>;
  end;

implementation

{ TCache }

function TCache.GetUnconfirmedBlocks: TArray<TAccountBlock>;
begin
  EnterCriticalSection(mMu);
  try
    Result := mUnconfirmedPool.GetBlocks;
  finally
    LeaveCriticalSection(mMu);
  end;
end;

function TCache.GetUnconfirmedBlocksByAddress(ParaAddress: TAddress): TArray<TAccountBlock>;
begin
  EnterCriticalSection(mMu);
  try
    Result := mUnconfirmedPool.GetBlocksByAddress(ParaAddress);
  finally
    LeaveCriticalSection(mMu);
  end;
end;

end.
