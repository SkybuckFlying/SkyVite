unit Ledger.Chain.Cache.Cache;

interface

uses
  Ledger.Chain.Cache.Account.Block,
  Ledger.Chain.Cache.Dataset,
  Ledger.Chain.Cache.Hot.Data,
  Ledger.Chain.Cache.Init,
  Ledger.Chain.Cache.Interface,
  Ledger.Chain.Cache.Interfaces Ledger.Chain.Cache.DataSet,
  Ledger.Chain.Cache.Quota,
  Ledger.Chain.Cache.Quota.List,
  Ledger.Chain.Cache.QuotaList Interfaces,
  Ledger.Chain.Cache.Snapshot.Block,
  Ledger.Chain.Cache.Unconfirmed,
  Ledger.Chain.Cache.Unconfirmed.Pool,
  Ledger.Chain.Cache.UnconfirmedPool Ledger.Chain.Cache.HotData,
  System.SysUtils System.Classes System.SyncObjs;

type
  TCache = class
  private
    mChain: IChain;
    mDs: TDataSet;
    mMu: TRTLCriticalSection;
    mUnconfirmedPool: TUnconfirmedPool;
    mHd: THotData;
    mQuotaList: TQuotaList;
  public
    constructor Create(ParaChain: IChain);
    destructor Destroy; override;
    function GetStatus: TArray<IDBStatus>;
  end;

implementation

{ TCache }

constructor TCache.Create(ParaChain: IChain);
begin
  inherited Create;
  mDs := TDataSet.Create;
  mChain := ParaChain;
  mUnconfirmedPool := TUnconfirmedPool.Create(mDs);
  mHd := THotData.Create(mDs);
  mQuotaList := TQuotaList.Create(mChain);
  InitializeCriticalSection(mMu);
end;

destructor TCache.Destroy;
begin
  EnterCriticalSection(mMu);
  try
    mDs.Free;
    mDs := nil;
    mUnconfirmedPool := nil;
    mHd := nil;
  finally
    LeaveCriticalSection(mMu);
  end;
  DeleteCriticalSection(mMu);
  inherited Destroy;
end;

function TCache.GetStatus: TArray<IDBStatus>;
var
  vDsCacheStatus: TArray<IDBStatus>;
begin
  vDsCacheStatus := mDs.GetStatus;
  SetLength(Result, 1);
  Result[0] := TDBStatus.Create('blockCache.ds.cache', vDsCacheStatus[0].Count, vDsCacheStatus[0].Size, '');
end;

end.
