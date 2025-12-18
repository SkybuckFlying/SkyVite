unit Ledger.Chain.Index.IndexDB;

interface

uses
  <<<<<<< HEAD,
  Common.DB.XLevelDB.Cache,
  Common.Log,
  Common.Types,
  GoToDelphi.Helpers.GoCache,
  Interfaces,
  Ledger.Chain.DB,
  Ledger.Chain.Index.Account,
  Ledger.Chain.Index.Account.Block,
  Ledger.Chain.Index.Cache,
  Ledger.Chain.Index.Delete,
  Ledger.Chain.Index.Index.DB.Test,
  Ledger.Chain.Index.Insert,
  Ledger.Chain.Index.Interface,
  Ledger.Chain.Index.Onroad,
  Ledger.Chain.Index.Snapshot.Block,
  System.Classes,
  System.Generics.Collections,
  System.JSON,
  System.SysUtils;

type
=======
  System.SysUtils, System.Classes, System.Generics.Collections,
  GoToDelphi.Helpers.GoCache,
  Common.Types,
  Interfaces.Chain,
  Ledger.Chain.Db.Store,
  Common.Log;

type
  IChain = interface;

>>>>>>> origin/AI0002
  TIndexDB = class
  private
    mStore: TStore;
    mLatestAccountId: UInt64;
<<<<<<< HEAD
    mCache: TGoCache;
    mSendCreateBlockHashCache: TLruCache;
    mAccountCache: TLruCache;
    mLog: ILogger;
    procedure InitAccountId;
  public
    constructor Create(const ParaChainDir: string);
    destructor Destroy; override;
    function Init(ParaChain: IChain): Exception;
    function CleanAllData: Exception;
    function Store: TStore;
    function Close: Exception;
    function GetStatus: TArray<IDBStatus>;
=======
    mCache: TGoCache<string, TBytes>;
    mSendCreateBlockHashCache: TGoCache<THash, UInt64>;
    mAccountCache: TGoCache<TAddress, Pointer>;
    mLog: ILogger;
    procedure InitAccountId;
    function QueryLatestAccountId: TPair<UInt64, Exception>;
    procedure NewCache;
    function InitCache(ParaChain: IChain): Exception;
  public
    constructor Create(const ParaChainDir: string);
    destructor Destroy; override;
    procedure Init(ParaChain: IChain);
    procedure CleanAllData;
    function Store: TStore;
    procedure Close;
    function GetStatus: TArray<IDBStatus>;
    function GetAddrHeightByHash(const ParaBlockHash: THash): TPair<TAddress, UInt64>;
>>>>>>> origin/AI0002
  end;

implementation

uses
  System.IOUtils,
<<<<<<< HEAD
  Ledger.Chain.Index.Cache,
  Ledger.Chain.Index.Account;
=======
  System.JSON,
  Common.Helper.Common,
  Ledger.Chain.Utils,
  Common.Db.XLevelDB.Util;
>>>>>>> origin/AI0002

{ TIndexDB }

constructor TIndexDB.Create(const ParaChainDir: string);
var
<<<<<<< HEAD
  vErr: Exception;
begin
  inherited Create;
  mStore := TStore.Create(TPath.Combine(ParaChainDir, 'index'), 'indexDb');
  mLog := TLogger.New('module', 'indexDB');
  mStore.RegisterAfterRecover(InitAccountId);
  InitAccountId;
  vErr := NewCache;
  if vErr <> nil then
  begin
    raise vErr;
  end;
=======
  vStore: TStore;
  vErr: Exception;
begin
  inherited Create;
  vStore := TStore.Create(TPath.Combine(ParaChainDir, 'index'), 'indexDb');
  mStore := vStore;
  mLog := TLogger.Create('module', 'indexDB');
  vStore.RegisterAfterRecover(InitAccountId);
  InitAccountId;
  NewCache;
>>>>>>> origin/AI0002
end;

destructor TIndexDB.Destroy;
begin
  mStore.Free;
  mCache.Free;
  mSendCreateBlockHashCache.Free;
  mAccountCache.Free;
<<<<<<< HEAD
  inherited Destroy;
end;

function TIndexDB.Init(ParaChain: IChain): Exception;
begin
  Result := InitCache(ParaChain);
=======
  inherited;
>>>>>>> origin/AI0002
end;

procedure TIndexDB.InitAccountId;
var
<<<<<<< HEAD
  vErr: Exception;
begin
  mLatestAccountId := QueryLatestAccountId(vErr);
  if vErr <> nil then
  begin
    raise vErr;
  end;
end;

function TIndexDB.CleanAllData: Exception;
var
  vErr: Exception;
begin
  mLatestAccountId := 0;
  vErr := mStore.Clean;
  if vErr <> nil then
  begin
    Result := Exception.CreateFmt('iDB.store.Clean failed, error is %s', [vErr.Message]);
    Exit;
  end;
  Result := nil;
=======
  vPair: TPair<UInt64, Exception>;
begin
  vPair := QueryLatestAccountId;
  if vPair.Value <> nil then
    raise vPair.Value;
  mLatestAccountId := vPair.Key;
end;

procedure TIndexDB.CleanAllData;
begin
  mLatestAccountId := 0;
  mStore.Clean;
>>>>>>> origin/AI0002
end;

function TIndexDB.Store: TStore;
begin
  Result := mStore;
end;

<<<<<<< HEAD
function TIndexDB.Close: Exception;
var
  vErr: Exception;
begin
  vErr := mCache.Close;
  if vErr <> nil then
  begin
    Result := Exception.CreateFmt('iDB.cache.Close failed, error is %s', [vErr.Message]);
    Exit;
  end;
  mCache := nil;

  vErr := mStore.Close;
  if vErr <> nil then
  begin
    Result := Exception.CreateFmt('iDB.store.Close failed, error is %s', [vErr.Message]);
    Exit;
  end;
  mStore := nil;

  Result := nil;
=======
procedure TIndexDB.Close;
begin
  mCache.Free;
  mCache := nil;
  mStore.Close;
  mStore := nil;
>>>>>>> origin/AI0002
end;

function TIndexDB.GetStatus: TArray<IDBStatus>;
var
<<<<<<< HEAD
  vIDBCacheStatus: TBytes;
  vErr: Exception;
  vStatusList: TArray<IDBStatus>;
  vDBStatus: IDBStatus;
begin
  try
    vIDBCacheStatus := TEncoding.UTF8.GetBytes(TJSONObject.Create(mCache.Stats).ToString);
  except
    on E: Exception do
    begin
      vIDBCacheStatus := TEncoding.UTF8.GetBytes('Error: ' + E.Message);
    end;
  end;

  vStatusList := mStore.GetStatus;

  SetLength(Result, 5);

  vDBStatus := TDBStatus.Create;
  vDBStatus.Name := 'indexDB.cache';
  vDBStatus.Count := mCache.Len;
  vDBStatus.Size := mCache.Capacity;
  vDBStatus.Status := TEncoding.UTF8.GetString(vIDBCacheStatus);
  Result[0] := vDBStatus;

  vDBStatus := TDBStatus.Create;
  vDBStatus.Name := 'indexDB.sendCreateBlockHashCache';
  vDBStatus.Count := mSendCreateBlockHashCache.Len;
  vDBStatus.Size := mSendCreateBlockHashCache.Len * (THash.HashSize + 8);
  vDBStatus.Status := '';
  Result[1] := vDBStatus;

  vDBStatus := TDBStatus.Create;
  vDBStatus.Name := 'indexDB.accountCache';
  vDBStatus.Count := mAccountCache.Len;
  vDBStatus.Size := mAccountCache.Len * TAddress.AddressSize;
  vDBStatus.Status := '';
  Result[2] := vDBStatus;

  vDBStatus := TDBStatus.Create;
  vDBStatus.Name := 'indexDB.store.mem';
  vDBStatus.Count := vStatusList[0].Count;
  vDBStatus.Size := vStatusList[0].Size;
  vDBStatus.Status := vStatusList[0].Status;
  Result[3] := vDBStatus;

  vDBStatus := TDBStatus.Create;
  vDBStatus.Name := 'indexDB.store.levelDB';
  vDBStatus.Count := vStatusList[1].Count;
  vDBStatus.Size := vStatusList[1].Size;
  vDBStatus.Status := vStatusList[1].Status;
  Result[4] := vDBStatus;
end;

end.
=======
  vCacheStatus: TJSONObject;
  vStatusList: TArray<IDBStatus>;
  vStoreStatus: TArray<IDBStatus>;
begin
  vCacheStatus := TJSONObject.Create;
  try
    // TGoCache does not have stats, so create empty status
  finally
    vCacheStatus.Free;
  end;

  vStoreStatus := mStore.GetStatus;

  SetLength(Result, 4 + Length(vStoreStatus));
  Result[0] := TDBStatus.Create('indexDB.cache', mCache.ItemCount, 0, vCacheStatus.ToString);
  Result[1] := TDBStatus.Create('indexDB.sendCreateBlockHashCache', mSendCreateBlockHashCache.ItemCount, mSendCreateBlockHashCache.ItemCount * (SizeOf(THash) + 8), '');
  Result[2] := TDBStatus.Create('indexDB.accountCache', mAccountCache.ItemCount, mAccountCache.ItemCount * SizeOf(TAddress), '');
  Result[3] := TDBStatus.Create('indexDB.store.mem', vStoreStatus[0].Count, vStoreStatus[0].Size, vStoreStatus[0].Status);
  Result[4] := TDBStatus.Create('indexDB.store.levelDB', vStoreStatus[1].Count, vStoreStatus[1].Size, vStoreStatus[1].Status);
end;

function TIndexDB.QueryLatestAccountId: TPair<UInt64, Exception>;
var
  vStartKey, vEndKey: TBytes;
  vIter: IStorageIterator;
  vLatestAccountId: UInt64;
  vKey: TBytes;
begin
  vStartKey := CreateAccountIdKey(1);
  vEndKey := CreateAccountIdKey(MaxUint64);
  vIter := mStore.NewIterator(TRange.Create(vStartKey, vEndKey));
  try
    vLatestAccountId := 0;
    if vIter.Last then
    begin
      vKey := vIter.Key;
      vLatestAccountId := BytesToUint64(Copy(vKey, 1, Length(vKey) - 1));
    end;
    if vIter.Error <> nil then
    begin
      Result := TPair<UInt64, Exception>.Create(0, vIter.Error);
      Exit;
    end;
    Result := TPair<UInt64, Exception>.Create(vLatestAccountId, nil);
  finally
    vIter.Release;
  end;
end;

procedure TIndexDB.NewCache;
begin
  mCache := TGoCache<string, TBytes>.Create(0, 0);
  mSendCreateBlockHashCache := TGoCache<THash, UInt64>.Create(0, 0);
  mAccountCache := TGoCache<TAddress, Pointer>.Create(0, 0);
end;

function TIndexDB.InitCache(ParaChain: IChain): Exception;
begin
  Result := nil;
  // not implemented yet
end;

procedure TIndexDB.Init(ParaChain: IChain);
begin
  InitCache(ParaChain);
end;

function TIndexDB.GetAddrHeightByHash(const ParaBlockHash: THash): TPair<TAddress, UInt64>;
var
  vKey: TBytes;
  vValue: TBytes;
  vErr: Exception;
  vAddr: TAddress;
  vHeight: UInt64;
  vPair: TPair<TBytes, Exception>;
begin
  vKey := CreateAccountBlockHashKey(ParaBlockHash);
  vPair := Self.Store.Get(vKey);
  if vPair.Value <> nil then
  begin
    Result := TPair<TAddress, UInt64>.Create(nil, 0);
    Exit;
  end;
  vValue := vPair.Key;

  if Length(vValue) <= 0 then
  begin
    Result := TPair<TAddress, UInt64>.Create(nil, 0);
    Exit;
  end;

  vAddr := TAddress.FromBytes(Copy(vValue, 0, TAddress.Size));
  vHeight := BytesToUint64(Copy(vValue, TAddress.Size, Length(vValue) - TAddress.Size));
  Result := TPair<TAddress, UInt64>.Create(vAddr, vHeight);
end;

end.
>>>>>>> origin/AI0002
