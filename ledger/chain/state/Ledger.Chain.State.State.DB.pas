unit Ledger.Chain.State.StateDB;

interface

uses
  Common.Config,
  Common.DB.XLevelDB,
  Common.Types,
  GoToDelphi.Helpers.GoCache,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.DB,
  Ledger.Chain.State.Cache,
  Ledger.Chain.State.Delete,
  Ledger.Chain.State.Interface,
  Ledger.Chain.State.Interface.Mock,
  Ledger.Chain.State.Iteration,
  Ledger.Chain.State.Redo,
  Ledger.Chain.State.Redo.Cache,
  Ledger.Chain.State.Round.Cache,
  Ledger.Chain.State.Round.Cache.Test,
  Ledger.Chain.State.RoundCache,
  Ledger.Chain.State.Storage.Database,
  Ledger.Chain.State.Transform.Iterator,
  Ledger.Chain.State.Write,
  Ledger.Chain.Utils,
  Log15,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  System.SyncObjs,
  System.SysUtils;

const
  ConsensusNoCache = 0;
  ConsensusReadCache = 1;

type
  TStateDB = class
  private
    mChain: IChain;
    mChainCfg: TChainConfig;
    mVmLogWhiteListSet: TDictionary<TAddress, Boolean>;
    mVmLogAll: Boolean;
    mStore: TStore;
    mCache: TGoCache;
    mLog: ILogger;
    mRedo: TRedo;
    mUseCache: Boolean;
    mConsensusCacheLevel: TUInt32;
    mRoundCache: TRoundCache;
    procedure SetConsensusCacheLevel(ParaLevel: TUInt32);
    function GetStore: TStore;
    function GetRedoStore: TStore;
    function GetRedo: IRedo;
    procedure VmLogWhiteListSetParser(const ParaList: TArray<TAddress>);
    function GetSnapshotBalanceListInternal(
      ParaBalanceMap: TDictionary<TAddress, TBigInteger>;
      ParaSnapshotBlockHash: THash;
      ParaAddrList: TArray<TAddress>;
      ParaTokenId: TTokenTypeId
    ): Boolean;
  public
    constructor Create(ParaChain: IChain; ParaChainCfg: TChainConfig; ParaChainDir: string);
    constructor CreateWithStore(ParaChain: IChain; ParaChainCfg: TChainConfig; ParaStore, ParaRedoStore: TStore);
    destructor Destroy; override;
    procedure Init;
    procedure Close;
    procedure SetTimeIndex(ParaPeriodTimeIndex: ITimeIndex);
    function GetStorageValue(ParaAddr: TAddress; ParaKey: TBytes): TBytes;
    function GetBalance(ParaAddr: TAddress; ParaTokenTypeId: TTokenTypeId): TBigInteger;
    function GetBalanceMap(ParaAddr: TAddress): TDictionary<TTokenTypeId, TBigInteger>;
    function GetCode(ParaAddr: TAddress): TBytes;
    function GetContractMeta(ParaAddr: TAddress): IContractMeta;
    procedure IterateContracts(ParaIterateFunc: TFunc<TAddress, IContractMeta, Exception, Boolean>);
    function HasContractMeta(ParaAddr: TAddress): Boolean;
    function GetContractList(ParaGid: TGid): TArray<TAddress>;
    function GetVmLogList(ParaLogHash: THash): IVmLogList;
    function GetCallDepth(ParaSendBlockHash: THash): Word;
    function GetSnapshotBalanceList(
      ParaBalanceMap: TDictionary<TAddress, TBigInteger>;
      ParaSnapshotBlockHash: THash;
      ParaAddrList: TArray<TAddress>;
      ParaTokenId: TTokenTypeId
    ): Boolean;
    function GetSnapshotValue(ParaSnapshotBlockHeight: TUInt64; ParaAddr: TAddress; ParaKey: TBytes): TBytes;
    function GetStatus: TArray<IDBStatus>;
    function ShouldCacheContractData(ParaAddr: TAddress): Boolean;
    property ConsensusCacheLevel: TUInt32 write SetConsensusCacheLevel;
    property Store: TStore read GetStore;
    property RedoStore: TStore read GetRedoStore;
    property Redo: IRedo read GetRedo;
  end;

implementation

uses
  System.IOUtils,
  Common.DB.XLevelDB.Util,
  Common.Binary;

{ TStateDB }

constructor TStateDB.Create(ParaChain: IChain; ParaChainCfg: TChainConfig; ParaChainDir: string);
var
  vStore, vRedoStore: TStore;
begin
  try
    vStore := TStore.Create(TPath.Combine(ParaChainDir, 'state'), 'stateDb');
    try
      vRedoStore := TStore.Create(TPath.Combine(ParaChainDir, 'state_redo'), 'stateDbRedo');
      try
        CreateWithStore(ParaChain, ParaChainCfg, vStore, vRedoStore);
      except
        vRedoStore.Free;
        raise;
      end;
    except
      vStore.Free;
      raise;
    end;
  except
    on E: Exception do
      raise;
  end;
end;

constructor TStateDB.CreateWithStore(ParaChain: IChain; ParaChainCfg: TChainConfig; ParaStore, ParaRedoStore: TStore);
var
  vStorageRedo: TRedo;
begin
  inherited Create;
  mChain := ParaChain;
  mChainCfg := ParaChainCfg;
  VmLogWhiteListSetParser(mChainCfg.VmLogWhiteList);
  mVmLogAll := mChainCfg.VmLogAll;
  mLog := TLog15.New('module', 'stateDB');
  mStore := ParaStore;
  mUseCache := False;
  mConsensusCacheLevel := ConsensusNoCache;
  vStorageRedo := TRedo.CreateWithStore(ParaChain, ParaRedoStore);
  mRedo := vStorageRedo;
  NewCache;
  mRoundCache := TRoundCache.Create(ParaChain, Self, 3);
end;

destructor TStateDB.Destroy;
begin
  if mCache <> nil then
  begin
    mCache.Flush;
    mCache.Free;
  end;
  if mStore <> nil then
    mStore.Free;
  if mRedo <> nil then
    mRedo.Free;
  if mRoundCache <> nil then
    mRoundCache.Free;
  inherited Destroy;
end;

procedure TStateDB.Init;
begin
  try
    InitCache;
    // if err := sDB.roundCache.Init(); err != nil then
    // raise Exception.Create(err.Error);
  finally
    EnableCache;
  end;
end;

procedure TStateDB.Close;
begin
  if mCache <> nil then
  begin
    mCache.Flush;
    mCache.Free;
    mCache := nil;
  end;
  if mStore <> nil then
  begin
    mStore.Close;
    mStore.Free;
    mStore := nil;
  end;
  if mRedo <> nil then
  begin
    mRedo.Close;
    mRedo.Free;
    mRedo := nil;
  end;
  if mRoundCache <> nil then
  begin
    mRoundCache.Free;
    mRoundCache := nil;
  end;
end;

procedure TStateDB.SetTimeIndex(ParaPeriodTimeIndex: ITimeIndex);
begin
  mRoundCache.Init(ParaPeriodTimeIndex);
end;

function TStateDB.GetStorageValue(ParaAddr: TAddress; ParaKey: TBytes): TBytes;
begin
  Result := mStore.Get(TChainUtils.CreateStorageValueKey(ParaAddr, ParaKey).Bytes);
end;

function TStateDB.GetBalance(ParaAddr: TAddress; ParaTokenTypeId: TTokenTypeId): TBigInteger;
var
  vValue: TBytes;
begin
  vValue := GetValue(TChainUtils.CreateBalanceKey(ParaAddr, ParaTokenTypeId).Bytes, ConstBalancePrefix);
  if Length(vValue) > 0 then
  begin
    Result := TBigInteger.FromBytes(vValue)
  end
  else
  begin
    Result := TBigInteger.Zero;
  end;
end;

function TStateDB.GetBalanceMap(ParaAddr: TAddress): TDictionary<TTokenTypeId, TBigInteger>;
var
  vIter: IIterator;
  vKey, vValue: TBytes;
  vTokenTypeIdBytes: TBytes;
  vTokenTypeId: TTokenTypeId;
begin
  Result := TDictionary<TTokenTypeId, TBigInteger>.Create;
  vIter := mStore.NewIterator(TBytesPrefix.Create(TChainUtils.CreateBalanceKeyPrefix(ParaAddr)));
  try
    while vIter.Next do
    begin
      vKey := vIter.Key;
      SetLength(vTokenTypeIdBytes, SizeOf(TTokenTypeId));
      System.Move(vKey[1 + SizeOf(TAddress)], vTokenTypeIdBytes[0], SizeOf(TTokenTypeId));
      vTokenTypeId := TTokenTypeId.FromBytes(vTokenTypeIdBytes);
      vValue := vIter.Value;
      Result.Add(vTokenTypeId, TBigInteger.FromBytes(vValue));
    end;
  finally
    vIter := nil;
  end;
end;

function TStateDB.GetCode(ParaAddr: TAddress): TBytes;
begin
  Result := mStore.Get(TChainUtils.CreateCodeKey(ParaAddr).Bytes);
end;

function TStateDB.GetContractMeta(ParaAddr: TAddress): IContractMeta;
var
  vValue: TBytes;
begin
  vValue := GetValueInCache(TChainUtils.CreateContractMetaKey(ParaAddr).Bytes, ConstContractAddrPrefix);
  if Length(vValue) > 0 then
  begin
    Result := TContractMeta.Create;
    Result.Deserialize(vValue);
  end
  else
  begin
    Result := nil;
  end;
end;

procedure TStateDB.IterateContracts(ParaIterateFunc: TFunc<TAddress, IContractMeta, Exception, Boolean>);
var
  vItems: TDictionary<string, TGoCacheItem>;
  vKeyStr: string;
  vItem: TGoCacheItem;
  vKey: TBytes;
  vAddr: TAddress;
  vMeta: IContractMeta;
  vErr: Exception;
begin
  vItems := mCache.Items;
  for vKeyStr in vItems.Keys do
  begin
    if vKeyStr.StartsWith(ConstContractAddrPrefix) then
    begin
      vItem := vItems[vKeyStr];
      vKey := TEncoding.UTF8.GetBytes(vKeyStr);
      try
        vAddr := TAddress.FromBytes(Copy(vKey, 2, Length(vKey) - 2));
        vMeta := TContractMeta.Create;
        vMeta.Deserialize(TBytes(vItem.Object));
        if not ParaIterateFunc(vAddr, vMeta, nil) then
        begin
          Exit;
        end;
      except
        on E: Exception do
        begin
          vErr := E;
          if not ParaIterateFunc(Default(TAddress), nil, vErr) then
          begin
            Exit;
          end;
        end;
      end;
    end;
  end;
end;

function TStateDB.HasContractMeta(ParaAddr: TAddress): Boolean;
var
  vValue: TBytes;
begin
  vValue := GetValueInCache(TChainUtils.CreateContractMetaKey(ParaAddr).Bytes, ConstContractAddrPrefix);
  Result := Length(vValue) > 0;
end;

function TStateDB.GetContractList(ParaGid: TGid): TArray<TAddress>;
var
  vIter: IIterator;
  vContractList: TList<TAddress>;
  vKey: TBytes;
  vAddr: TAddress;
begin
  vContractList := TList<TAddress>.Create;
  vIter := mStore.NewIterator(TBytesPrefix.Create(TChainUtils.CreateGidContractPrefixKey(ParaGid)));
  try
    while vIter.Next do
    begin
      vKey := vIter.Key;
      vAddr := TAddress.FromBytes(Copy(vKey, Length(vKey) - SizeOf(TAddress), SizeOf(TAddress)));
      vContractList.Add(vAddr);
    end;
  finally
    vIter := nil;
  end;
  Result := vContractList.ToArray;
  vContractList.Free;
end;

function TStateDB.GetVmLogList(ParaLogHash: THash): IVmLogList;
var
  vValue: TBytes;
begin
  vValue := mStore.Get(TChainUtils.CreateVmLogListKey(ParaLogHash).Bytes);
  if Length(vValue) > 0 then
  begin
    Result := TVmLogList.Create;
    Result.Deserialize(vValue);
  end
  else
  begin
    Result := nil;
  end;
end;

function TStateDB.GetCallDepth(ParaSendBlockHash: THash): Word;
var
  vValue: TBytes;
begin
  vValue := mStore.Get(TChainUtils.CreateCallDepthKey(ParaSendBlockHash).Bytes);
  if Length(vValue) > 0 then
  begin
    Result := TBigEndian.ToUInt16(vValue)
  end
  else
  begin
    Result := 0;
  end;
end;

function TStateDB.GetSnapshotBalanceList(
  ParaBalanceMap: TDictionary<TAddress, TBigInteger>;
  ParaSnapshotBlockHash: THash;
  ParaAddrList: TArray<TAddress>;
  ParaTokenId: TTokenTypeId
): Boolean;
var
  vCacheBalanceMap: TDictionary<TAddress, TBigInteger>;
  vNotFoundAddressList: TArray<TAddress>;
  vAddr: TAddress;
  vBalance: TBigInteger;
begin
  if (mConsensusCacheLevel = ConsensusReadCache) and (ParaTokenId = TViteTokenId) then
  begin
    vCacheBalanceMap := mRoundCache.GetSnapshotViteBalanceList(ParaSnapshotBlockHash, ParaAddrList, vNotFoundAddressList);
    if vCacheBalanceMap <> nil then
    begin
      if Length(vNotFoundAddressList) > 0 then
      begin
        if not GetSnapshotBalanceListInternal(vCacheBalanceMap, ParaSnapshotBlockHash, vNotFoundAddressList, ParaTokenId) then
        begin
          Exit(False);
        end;
      end;
      for vAddr in vCacheBalanceMap.Keys do
      begin
        vBalance := vCacheBalanceMap[vAddr];
        ParaBalanceMap.Add(vAddr, vBalance);
      end;
      Exit(True);
    end;
  end;
  Result := GetSnapshotBalanceListInternal(ParaBalanceMap, ParaSnapshotBlockHash, ParaAddrList, ParaTokenId);
end;

function TStateDB.GetSnapshotBalanceListInternal(
  ParaBalanceMap: TDictionary<TAddress, TBigInteger>;
  ParaSnapshotBlockHash: THash;
  ParaAddrList: TArray<TAddress>;
  ParaTokenId: TTokenTypeId
): Boolean;
var
  vSnapshotHeight: TUInt64;
  vIter: IIterator;
  vSeekKey: THistoryBalanceKey;
  vAddr: TAddress;
  vKey: THistoryBalanceKey;
begin
  vSnapshotHeight := mChain.GetSnapshotHeightByHash(ParaSnapshotBlockHash);
  if vSnapshotHeight <= 0 then
  begin
    Exit(True);
  end;

  vIter := mStore.NewIterator(TBytesPrefix.Create([HistoryBalanceKeyPrefix]));
  try
    vSeekKey := TChainUtils.CreateHistoryBalanceKey(Default(TAddress), ParaTokenId, vSnapshotHeight + 1);
    for vAddr in ParaAddrList do
    begin
      vSeekKey.AddressRefill(vAddr);
      vIter.Seek(vSeekKey.Bytes);
      if vIter.Prev then
      begin
        vKey := THistoryBalanceKey.Construct(vIter.Key);
        if (vKey <> nil) and vKey.EqualAddressAndTokenId(vAddr, ParaTokenId) then
        begin
          ParaBalanceMap.Add(vAddr, TBigInteger.FromBytes(vIter.Value));
        end;
      end;
    end;
  finally
    vIter := nil;
  end;
  Result := True;
end;

function TStateDB.GetSnapshotValue(ParaSnapshotBlockHeight: TUInt64; ParaAddr: TAddress; ParaKey: TBytes): TBytes;
var
  vStartHistoryStorageKey, vEndHistoryStorageKey: THistoryStorageValueKey;
  vIter: IIterator;
begin
  if mUseCache and ShouldCacheContractData(ParaAddr) and (ParaSnapshotBlockHeight = mChain.GetLatestSnapshotBlock.Height) then
  begin
    Result := GetValueInCache(ParaAddr.Bytes + ParaKey, ConstSnapshotValuePrefix);
    Exit;
  end;

  vStartHistoryStorageKey := TChainUtils.CreateHistoryStorageValueKey(ParaAddr, ParaKey, 0);
  vEndHistoryStorageKey := TChainUtils.CreateHistoryStorageValueKey(ParaAddr, ParaKey, ParaSnapshotBlockHeight + 1);

  vIter := mStore.NewIterator(TRange.Create(vStartHistoryStorageKey.Bytes, vEndHistoryStorageKey.Bytes));
  try
    if vIter.Last then
    begin
      Result := vIter.Value
    end
    else
    begin
      Result := nil;
    end;
  finally
    vIter := nil;
  end;
end;

function TStateDB.GetStatus: TArray<IDBStatus>;
var
  vStatusList: TArray<IDBStatus>;
begin
  vStatusList := mStore.GetStatus;
  Result := [
    TDBStatus.Create('stateDB.cache', mCache.ItemCount, mCache.ItemCount * 65, ''),
    TDBStatus.Create('stateDB.store.mem', vStatusList[0].Count, vStatusList[0].Size, vStatusList[0].Status),
    TDBStatus.Create('stateDB.store.levelDB', vStatusList[1].Count, vStatusList[1].Size, vStatusList[1].Status)
  ];
end;

function TStateDB.ShouldCacheContractData(ParaAddr: TAddress): Boolean;
begin
  Result := (ParaAddr = TAddressQuota) or (ParaAddr = TAddressGovernance) or (ParaAddr = TAddressAsset);
end;

procedure TStateDB.VmLogWhiteListSetParser(const ParaList: TArray<TAddress>);
var
  vItem: TAddress;
begin
  mVmLogWhiteListSet := TDictionary<TAddress, Boolean>.Create;
  for vItem in ParaList do
  begin
    mVmLogWhiteListSet.Add(vItem, True);
  end;
end;

procedure TStateDB.SetConsensusCacheLevel(ParaLevel: TUInt32);
begin
  TInterlocked.Exchange(mConsensusCacheLevel, ParaLevel);
end;

function TStateDB.GetStore: TStore;
begin
  Result := mStore;
end;

function TStateDB.GetRedoStore: TStore;
begin
  Result := mRedo.Store;
end;

function TStateDB.GetRedo: IRedo;
begin
  Result := mRedo;
end;

end.
