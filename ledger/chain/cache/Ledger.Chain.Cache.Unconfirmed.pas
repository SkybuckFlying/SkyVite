unit Ledger.Chain.Cache.Unconfirmed;

interface

uses
  System.SysUtils, System.Classes,
  Vite.Common.Types, Interfaces.Core, Ledger.Chain.Cache.Cache;

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
