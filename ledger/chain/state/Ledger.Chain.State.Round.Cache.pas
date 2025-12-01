unit Ledger.Chain.State.RoundCache;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.Math.BigInt,
  Common.DB.XLevelDB,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.Utils,
  Ledger.Consensus.Core,
  Ledger.Chain.State.StateDB,
  Ledger.Chain.State.Redo;

type
  TMemPool = class
  private
    mByteSliceList: TQueue<TBytes>;
    mByteSliceLimit: Integer;
    mIntSliceList: TQueue<TArray<Integer>>;
    mIntSliceLimit: Integer;
    mMutex: TRTLCriticalSection;
  public
    constructor Create(ParaByteSliceLimit, ParaIntSliceLimit: Integer);
    destructor Destroy; override;
    function GetByteSlice(ParaN: Integer): TBytes;
    function GetIntSlice(ParaN: Integer): TArray<Integer>;
    procedure Put(ParaX: TObject);
  end;

  TRoundCacheLogItem = record
    Storage: TArray<TArray<TBytes>>;
    BalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
  end;

  TRoundCacheSnapshotLog = class
  public
    LogMap: TDictionary<TAddress, TArray<TRoundCacheLogItem>>;
    SnapshotHeight: TUInt64;
    constructor Create(ParaCapacity: Integer; ParaSnapshotHeight: TUInt64);
    destructor Destroy; override;
  end;

  TRoundCacheRedoLogs = class
  public
    Logs: TList<TRoundCacheSnapshotLog>;
    constructor Create;
    destructor Destroy; override;
    procedure Add(ParaSnapshotHeight: TUInt64; ParaSnapshotLog: TSnapshotLog);
  end;

  TRedoCacheData = class
  private
    mCurrentData: TMemDB;
    mRedoLogs: TRoundCacheRedoLogs;
    mMutex: TRTLCriticalSection;
  public
    RoundIndex: TUInt64;
    LastSnapshotBlock: ISnapshotBlock;
    constructor Create(ParaRoundIndex: TUInt64; ParaLastSnapshotBlock: ISnapshotBlock; ParaCurrentData: TMemDB; ParaRedoLogs: TRoundCacheRedoLogs);
    destructor Destroy; override;
    property CurrentData: TMemDB read mCurrentData write mCurrentData;
    property RedoLogs: TRoundCacheRedoLogs read mRedoLogs write mRedoLogs;
  end;

  TRoundCacheStatus = (
    rcsStop,
    rcsInited
  );

  TRoundCache = class
  private
    mChain: IChain;
    mStateDB: IStateDB;
    mRoundCount: TUInt64;
    mTimeIndex: ITimeIndex;
    mLatestRoundIndex: TUInt64;
    mData: TList<TRedoCacheData>;
    mMutex: TRTLCriticalSection;
    mMemPool: TMemPool;
    mStatus: TRoundCacheStatus;
    function InitRounds(ParaStartRoundIndex, ParaEndRoundIndex: TUInt64): TList<TRedoCacheData>;
    function QueryCurrentData(ParaRoundIndex: TUInt64; out ParaLastSnapshotBlock: ISnapshotBlock): TMemDB;
    function QueryRedoLogs(ParaRoundIndex: TUInt64; out ParaIsStoreRedoLogs: Boolean): TRoundCacheRedoLogs;
    function BuildCurrentData(ParaPrevCurrentData: TMemDB; ParaRedoLogs: TRoundCacheRedoLogs): TMemDB;
    function RoundToLastSnapshotBlock(ParaRoundIndex: TUInt64): ISnapshotBlock;
    function GetRoundSnapshotBlocks(ParaRoundIndex: TUInt64): TArray<ISnapshotBlock>;
    procedure SetAllBalanceToCache(ParaRoundData: TMemDB; ParaSnapshotHash: THash);
    procedure SetBalanceToCache(ParaRoundData: TMemDB; ParaSnapshotHash: THash; ParaAddressList: TArray<TAddress>);
    procedure SetStorageToCache(ParaRoundData: TMemDB; ParaContractAddress: TAddress; ParaSnapshotHash: THash);
    procedure DestroyMemDb(ParaDb: TMemDB);
    function GetCurrentData(ParaSnapshotHash: THash): TMemDB;
  public
    constructor Create(ParaChain: IChain; ParaStateDB: IStateDB; ParaRoundCount: Byte);
    destructor Destroy; override;
    procedure Init(ParaTimeIndex: ITimeIndex);
    procedure InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock; ParaSnapshotLog: TSnapshotLog);
    procedure DeleteSnapshotBlocks(ParaSnapshotBlocks: TArray<ISnapshotBlock>);
    function GetSnapshotViteBalanceList(ParaSnapshotHash: THash; ParaAddrList: TArray<TAddress>; out ParaNotFoundAddressList: TArray<TAddress>): TDictionary<TAddress, TBigInteger>;
    function StorageIterator(ParaSnapshotHash: THash): IStorageIterator;
  end;

implementation

uses
  Common.DB.XLevelDB.MemDB,
  Common.DB.XLevelDB.Comparer,
  Common.DB.XLevelDB.Util,
  Ledger.Chain.State.Iteration; // For TTransformIterator

{ TMemPool }

constructor TMemPool.Create(ParaByteSliceLimit, ParaIntSliceLimit: Integer);
begin
  inherited Create;
  mByteSliceList := TQueue<TBytes>.Create;
  mIntSliceList := TQueue<TArray<Integer>>.Create;
  if ParaByteSliceLimit <= 0 then
  begin
    mByteSliceLimit := 3
  end
  else
  begin
    mByteSliceLimit := ParaByteSliceLimit;
  end;
  if ParaIntSliceLimit <= 0 then
  begin
    mIntSliceLimit := 3
  end
  else
  begin
    mIntSliceLimit := ParaIntSliceLimit;
  end;
  InitializeCriticalSection(mMutex);
end;

destructor TMemPool.Destroy;
begin
  mByteSliceList.Free;
  mIntSliceList.Free;
  DeleteCriticalSection(mMutex);
  inherited Destroy;
end;

function TMemPool.GetByteSlice(ParaN: Integer): TBytes;
begin
  EnterCriticalSection(mMutex);
  try
    if mByteSliceList.Count > 0 then
    begin
      Result := mByteSliceList.Dequeue;
      if Length(Result) < ParaN then
      begin
        SetLength(Result, ParaN);
      end;
      Exit;
    end;
  finally
    LeaveCriticalSection(mMutex);
  end;
  SetLength(Result, ParaN);
end;

function TMemPool.GetIntSlice(ParaN: Integer): TArray<Integer>;
begin
  EnterCriticalSection(mMutex);
  try
    if mIntSliceList.Count > 0 then
    begin
      Result := mIntSliceList.Dequeue;
      if Length(Result) < ParaN then
      begin
        SetLength(Result, ParaN);
      end;
      Exit;
    end;
  finally
    LeaveCriticalSection(mMutex);
  end;
  SetLength(Result, ParaN);
end;

procedure TMemPool.Put(ParaX: TObject);
begin
  EnterCriticalSection(mMutex);
  try
    if ParaX is TBytes then
    begin
      if mByteSliceList.Count < mByteSliceLimit then
      begin
        mByteSliceList.Enqueue(TBytes(ParaX))
      end
      else
      begin
        mByteSliceList.Dequeue; // Discard oldest
        mByteSliceList.Enqueue(TBytes(ParaX));
      end;
    end
    else if ParaX is TArray<Integer> then
    begin
      if mIntSliceList.Count < mIntSliceLimit then
      begin
        mIntSliceList.Enqueue(TArray<Integer>(ParaX))
      end
      else
      begin
        mIntSliceList.Dequeue; // Discard oldest
        mIntSliceList.Enqueue(TArray<Integer>(ParaX));
      end;
    end
    else
    begin
      raise Exception.CreateFmt('Unknown type: %s', [ParaX.ClassName]);
    end;
  finally
    LeaveCriticalSection(mMutex);
  end;
end;

{ TRoundCacheSnapshotLog }

constructor TRoundCacheSnapshotLog.Create(ParaCapacity: Integer; ParaSnapshotHeight: TUInt64);
begin
  inherited Create;
  LogMap := TDictionary<TAddress, TArray<TRoundCacheLogItem>>.Create(ParaCapacity);
  SnapshotHeight := ParaSnapshotHeight;
end;

destructor TRoundCacheSnapshotLog.Destroy;
begin
  LogMap.Free;
  inherited Destroy;
end;

{ TRoundCacheRedoLogs }

constructor TRoundCacheRedoLogs.Create;
begin
  inherited Create;
  Logs := TList<TRoundCacheSnapshotLog>.Create;
end;

destructor TRoundCacheRedoLogs.Destroy;
begin
  Logs.Free;
  inherited Destroy;
end;

procedure TRoundCacheRedoLogs.Add(ParaSnapshotHeight: TUInt64; ParaSnapshotLog: TSnapshotLog);
var
  vFilteredSnapshotLog: TRoundCacheSnapshotLog;
  vAddr: TAddress;
  vLogList: TArray<TLogItem>;
  vNeedSetStorage: Boolean;
  vFilteredLogList: TArray<TRoundCacheLogItem>;
  vIndex: Integer;
  vLogItem: TLogItem;
  vFilteredLogItem: TRoundCacheLogItem;
begin
  vFilteredSnapshotLog := TRoundCacheSnapshotLog.Create(ParaSnapshotLog.Count, ParaSnapshotHeight);
  for vAddr in ParaSnapshotLog.Keys do
  begin
    vLogList := ParaSnapshotLog[vAddr];
    vNeedSetStorage := vAddr = TAddressGovernance;
    SetLength(vFilteredLogList, Length(vLogList));
    for vIndex := 0 to High(vLogList) do
    begin
      vLogItem := vLogList[vIndex];
      vFilteredLogItem := Default(TRoundCacheLogItem);
      if vNeedSetStorage then
      begin
        vFilteredLogItem.Storage := vLogItem.Storage;
      end;
      vFilteredLogItem.BalanceMap := vLogItem.BalanceMap;
      vFilteredLogList[vIndex] := vFilteredLogItem;
    end;
    vFilteredSnapshotLog.LogMap.Add(vAddr, vFilteredLogList);
  end;
  Logs.Add(vFilteredSnapshotLog);
end;

{ TRedoCacheData }

constructor TRedoCacheData.Create(ParaRoundIndex: TUInt64; ParaLastSnapshotBlock: ISnapshotBlock; ParaCurrentData: TMemDB; ParaRedoLogs: TRoundCacheRedoLogs);
begin
  inherited Create;
  RoundIndex := ParaRoundIndex;
  LastSnapshotBlock := ParaLastSnapshotBlock;
  mCurrentData := ParaCurrentData;
  mRedoLogs := ParaRedoLogs;
  InitializeCriticalSection(mMutex);
end;

destructor TRedoCacheData.Destroy;
begin
  mCurrentData.Free;
  mRedoLogs.Free;
  DeleteCriticalSection(mMutex);
  inherited Destroy;
end;

{ TRoundCache }

constructor TRoundCache.Create(ParaChain: IChain; ParaStateDB: IStateDB; ParaRoundCount: Byte);
begin
  inherited Create;
  mChain := ParaChain;
  mStateDB := ParaStateDB;
  mRoundCount := ParaRoundCount;
  mData := TList<TRedoCacheData>.Create;
  mStatus := rcsStop;
  mMemPool := TMemPool.Create(ParaRoundCount, ParaRoundCount);
  InitializeCriticalSection(mMutex);
end;

destructor TRoundCache.Destroy;
begin
  mData.Free;
  mMemPool.Free;
  DeleteCriticalSection(mMutex);
  inherited Destroy;
end;

procedure TRoundCache.Init(ParaTimeIndex: ITimeIndex);
var
  vLatestSb: ISnapshotBlock;
  vLatestTime: TDateTime;
  vRoundIndex, vStartRoundIndex: TUInt64;
  vRoundsData: TList<TRedoCacheData>;
begin
  if mStatus >= rcsInited then
  begin
    Exit;
  end;

  mTimeIndex := ParaTimeIndex;

  mChain.StopWrite;
  try
    vLatestSb := mChain.GetLatestSnapshotBlock;
    EnterCriticalSection(mMutex);
    try
      mData.Clear;
    finally
      LeaveCriticalSection(mMutex);
    end;

    vLatestTime := vLatestSb.Timestamp;
    vRoundIndex := mTimeIndex.Time2Index(vLatestTime);
    mLatestRoundIndex := vRoundIndex;

    if vRoundIndex <= mRoundCount then
    begin
      Exit;
    end;

    vStartRoundIndex := vRoundIndex - mRoundCount + 1;
    vRoundsData := InitRounds(vStartRoundIndex, vRoundIndex);
    if vRoundsData <> nil then
    begin
      EnterCriticalSection(mMutex);
      try
        mData.Add(vRoundsData);
      finally
        LeaveCriticalSection(mMutex);
      end;
    end;
  finally
    mChain.RecoverWrite;
    mStatus := rcsInited;
  end;
end;

procedure TRoundCache.InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock; ParaSnapshotLog: TSnapshotLog);
var
  vRoundIndex: TUInt64;
  vLength, vDataLength: Integer;
  vCurrentRedoCacheData, vPrevRoundData, vPrevBeforePrevRoundData: TRedoCacheData;
  vRoundData: TMemDB;
  vLastSnapshotBlock: ISnapshotBlock;
  vRedoLogs: TRoundCacheRedoLogs;
begin
  if mStatus < rcsInited then
  begin
    Exit;
  end;

  vRoundIndex := mTimeIndex.Time2Index(ParaSnapshotBlock.Timestamp);
  try
    if vRoundIndex < mLatestRoundIndex then
    begin
      raise Exception.CreateFmt('roundIndex < mLatestRoundIndex, %d < %d', [vRoundIndex, mLatestRoundIndex]);
    end;

    if vRoundIndex = mLatestRoundIndex then
    begin
      vLength := mData.Count;
      if vLength <= 0 then
      begin
        Exit;
      end;
      vCurrentRedoCacheData := mData[vLength - 1];
      vCurrentRedoCacheData.RedoLogs.Add(ParaSnapshotBlock.Height, ParaSnapshotLog);
      Exit;
    end;

    vDataLength := mData.Count;
    if vDataLength <= 0 then
    begin
      vRoundData := QueryCurrentData(mLatestRoundIndex, vLastSnapshotBlock);
      if vLastSnapshotBlock = nil then
      begin
        raise Exception.CreateFmt('lastSnapshotBlock is nil, mLatestRoundIndex is %d', [mLatestRoundIndex]);
      end;
      if vRoundData = nil then
      begin
        raise Exception.CreateFmt('roundData is nil, mLatestRoundIndex is %d', [mLatestRoundIndex]);
      end;
      EnterCriticalSection(mMutex);
      try
        mData.Add(TRedoCacheData.Create(mLatestRoundIndex, vLastSnapshotBlock, vRoundData, nil));
      finally
        LeaveCriticalSection(mMutex);
      end;
    end
    else if vDataLength = 1 then
    begin
      raise Exception.CreateFmt('len(mData) is 1, mData[0] is %s', [mData[0].ToString])
    end
    else
    begin
      vPrevRoundData := mData[vDataLength - 1];
      if (vPrevRoundData.RedoLogs = nil) or (vPrevRoundData.RedoLogs.Logs.Count <= 0) then
      begin
        raise Exception.CreateFmt('prevRoundData.redoLogs is nil or empty. prevRoundData is %s', [vPrevRoundData.ToString]);
      end;
      vPrevBeforePrevRoundData := mData[vDataLength - 2];
      if vPrevBeforePrevRoundData.CurrentData = nil then
      begin
        raise Exception.CreateFmt('prevBeforePrevRoundData.currentData is nil, prevBeforePrevRoundData is %s', [vPrevBeforePrevRoundData.ToString]);
      end;

      vLastSnapshotBlock := mChain.GetSnapshotHeaderByHeight(ParaSnapshotBlock.Height - 1);
      if vLastSnapshotBlock = nil then
      begin
        raise Exception.CreateFmt('lastSnapshotBlock is nil, height is %d', [ParaSnapshotBlock.Height - 1]);
      end;

      EnterCriticalSection(vPrevRoundData.mMutex);
      try
        vPrevRoundData.CurrentData := BuildCurrentData(vPrevBeforePrevRoundData.CurrentData, vPrevRoundData.RedoLogs);
        vPrevRoundData.LastSnapshotBlock := vLastSnapshotBlock;
      finally
        LeaveCriticalSection(vPrevRoundData.mMutex);
      end;
    end;

    vRedoLogs := TRoundCacheRedoLogs.Create;
    vRedoLogs.Add(ParaSnapshotBlock.Height, ParaSnapshotLog);

    EnterCriticalSection(mMutex);
    try
      mData.Add(TRedoCacheData.Create(vRoundIndex, nil, nil, vRedoLogs));
      if mData.Count > mRoundCount then
      begin
        DestroyMemDb(mData[0].CurrentData);
        mData.Delete(0);
      end;
    finally
      LeaveCriticalSection(mMutex);
    end;
  finally
    mLatestRoundIndex := vRoundIndex;
  end;
end;

procedure TRoundCache.DeleteSnapshotBlocks(ParaSnapshotBlocks: TArray<ISnapshotBlock>);
var
  vFirstSnapshotBlock: ISnapshotBlock;
  vFirstRoundIndex, vNewLatestRoundIndex: TUInt64;
  vEnd, I, vRedoLogsEnd, J, vDeleteTo: Integer;
  vData, vLastRoundCache: TRedoCacheData;
  vRedoLog: TRoundCacheSnapshotLog;
  vBeforeFirstSnapshotBlock: ISnapshotBlock;
  vItem: TRedoCacheData;
begin
  if mStatus < rcsInited then
  begin
    Exit;
  end;
  if Length(ParaSnapshotBlocks) = 0 then
  begin
    raise Exception.Create('Length of snapshotBlocks to deleting is 0');
  end;

  vFirstSnapshotBlock := ParaSnapshotBlocks[0];
  vFirstRoundIndex := mTimeIndex.Time2Index(vFirstSnapshotBlock.Timestamp);
  vEnd := mData.Count;

  for I := vEnd - 1 downto 0 do
  begin
    vData := mData[I];
    if vData.RoundIndex > vFirstRoundIndex then
    begin
      vEnd := I
    end
    else if vData.RoundIndex = vFirstRoundIndex then
    begin
      EnterCriticalSection(vData.mMutex);
      try
        vData.CurrentData := nil;
        vData.LastSnapshotBlock := nil;
      finally
        LeaveCriticalSection(vData.mMutex);
      end;
      if (vData.RedoLogs = nil) or (vData.RedoLogs.Logs.Count <= 0) then
      begin
        vEnd := I
      end
      else
      begin
        vRedoLogsEnd := vData.RedoLogs.Logs.Count;
        for J := vRedoLogsEnd - 1 downto 0 do
        begin
          vRedoLog := vData.RedoLogs.Logs[J];
          if vRedoLog.SnapshotHeight >= vFirstSnapshotBlock.Height then
          begin
            vRedoLogsEnd := J
          end
          else
          begin
            Break;
          end;
        end;
        if vRedoLogsEnd <= 0 then
        begin
          vEnd := I
        end
        else
        begin
          vData.RedoLogs.Logs.Delete(vRedoLogsEnd, vData.RedoLogs.Logs.Count - vRedoLogsEnd);
        end;
      end;
    end
    else if vData.RoundIndex < vFirstRoundIndex then
    begin
      Break;
    end;
  end;

  EnterCriticalSection(mMutex);
  try
    vDeleteTo := vEnd;
    if vEnd <= 1 then
    begin
      vDeleteTo := 0;
    end;
    for I := vDeleteTo to mData.Count - 1 do
    begin
      vItem := mData[I];
      DestroyMemDb(vItem.CurrentData);
    end;
    mData.Delete(vDeleteTo, mData.Count - vDeleteTo);
  finally
    LeaveCriticalSection(mMutex);
  end;

  if mData.Count > 0 then
  begin
    vLastRoundCache := mData[mData.Count - 1];
    EnterCriticalSection(vLastRoundCache.mMutex);
    try
      DestroyMemDb(vLastRoundCache.CurrentData);
      vLastRoundCache.LastSnapshotBlock := nil;
      vLastRoundCache.CurrentData := nil;
    finally
      LeaveCriticalSection(vLastRoundCache.mMutex);
    end;
  end;

  vBeforeFirstSnapshotBlock := mChain.GetSnapshotHeaderByHeight(vFirstSnapshotBlock.Height - 1);
  if vBeforeFirstSnapshotBlock = nil then
  begin
    raise Exception.CreateFmt('beforeFirstSnapshotBlock is nil, height is %d', [vFirstSnapshotBlock.Height - 1]);
  end;
  vNewLatestRoundIndex := mTimeIndex.Time2Index(vBeforeFirstSnapshotBlock.Timestamp);
  mLatestRoundIndex := vNewLatestRoundIndex;
end;

function TRoundCache.GetSnapshotViteBalanceList(ParaSnapshotHash: THash; ParaAddrList: TArray<TAddress>; out ParaNotFoundAddressList: TArray<TAddress>): TDictionary<TAddress, TBigInteger>;
var
  vCurrentData: TMemDB;
  vAddr: TAddress;
  vValue: TBytes;
begin
  Result := nil;
  ParaNotFoundAddressList := nil;
  if mStatus < rcsInited then
  begin
    Exit;
  end;

  vCurrentData := GetCurrentData(ParaSnapshotHash);
  if vCurrentData = nil then
  begin
    Exit;
  end;

  Result := TDictionary<TAddress, TBigInteger>.Create;
  ParaNotFoundAddressList := TArray<TAddress>.Create();

  for vAddr in ParaAddrList do
  begin
    try
      vValue := vCurrentData.Get(MakeBalanceKey(vAddr.Bytes));
      Result.Add(vAddr, TBigInteger.FromBytes(vValue));
    except
      on E: ELevelDB do
        if E.ClassName = 'ErrNotFound' then
        begin
          ParaNotFoundAddressList := ParaNotFoundAddressList + [vAddr]
        end
        else
        begin
          raise;
        end;
    end;
  end;
end;

function TRoundCache.StorageIterator(ParaSnapshotHash: THash): IStorageIterator;
var
  vCurrentData: TMemDB;
begin
  Result := nil;
  if mStatus < rcsInited then
  begin
    Exit;
  end;
  vCurrentData := GetCurrentData(ParaSnapshotHash);
  if vCurrentData = nil then
  begin
    Exit;
  end;
  Result := TTransformIterator.Create(vCurrentData.NewIterator(TBytesPrefix.Create(MakeStorageKey(nil))), 1);
end;

function TRoundCache.GetCurrentData(ParaSnapshotHash: THash): TMemDB;
var
  vDataCopied: TArray<TRedoCacheData>;
  vDataItem: TRedoCacheData;
  vLastSnapshotBlock: ISnapshotBlock;
begin
  Result := nil;
  if mData.Count <= 0 then
  begin
    Exit;
  end;

  EnterCriticalSection(mMutex);
  try
    vDataCopied := mData.ToArray;
  finally
    LeaveCriticalSection(mMutex);
  end;

  for vDataItem in vDataCopied do
  begin
    EnterCriticalSection(vDataItem.mMutex);
    try
      vLastSnapshotBlock := vDataItem.LastSnapshotBlock;
      Result := vDataItem.CurrentData;
    finally
      LeaveCriticalSection(vDataItem.mMutex);
    end;
    if (vLastSnapshotBlock <> nil) and (vLastSnapshotBlock.Hash = ParaSnapshotHash) then
    begin
      Exit;
    end;
  end;
  Result := nil;
end;

function TRoundCache.InitRounds(ParaStartRoundIndex, ParaEndRoundIndex: TUInt64): TList<TRedoCacheData>;
var
  vFirstCurrentData, vPrevCurrentData, vCurCurrentData: TMemDB;
  vLastSnapshotBlock: ISnapshotBlock;
  vFirstRedoLogs, vRedoLogs: TRoundCacheRedoLogs;
  vHasStoreRedoLogs: Boolean;
  vIndex: TUInt64;
begin
  Result := nil;
  if ParaStartRoundIndex >= ParaEndRoundIndex then
  begin
    Exit;
  end;

  vFirstCurrentData := QueryCurrentData(ParaStartRoundIndex, vLastSnapshotBlock);
  if vFirstCurrentData = nil then
  begin
    Exit;
  end;

  vFirstRedoLogs := QueryRedoLogs(ParaStartRoundIndex, vHasStoreRedoLogs);
  if not vHasStoreRedoLogs then
  begin
    Exit(InitRounds(ParaStartRoundIndex + 1, ParaEndRoundIndex));
  end;

  Result := TList<TRedoCacheData>.Create;
  Result.Add(TRedoCacheData.Create(ParaStartRoundIndex, vLastSnapshotBlock, vFirstCurrentData, vFirstRedoLogs));
  vPrevCurrentData := vFirstCurrentData;

  for vIndex := ParaStartRoundIndex + 1 to ParaEndRoundIndex do
  begin
    vRedoLogs := QueryRedoLogs(vIndex, vHasStoreRedoLogs);
    if not vHasStoreRedoLogs then
    begin
      Exit(InitRounds(vIndex, ParaEndRoundIndex));
    end;
    if vRedoLogs = nil then
    begin
      Continue;
    end;

    vCurCurrentData := nil;
    vLastSnapshotBlock := nil;
    if vIndex < ParaEndRoundIndex then
    begin
      vLastSnapshotBlock := RoundToLastSnapshotBlock(vIndex);
      if vLastSnapshotBlock = nil then
      begin
        raise Exception.CreateFmt('lastSnapshotBlock is nil, index is %d', [vIndex]);
      end;
      vCurCurrentData := BuildCurrentData(vPrevCurrentData, vRedoLogs);
      vPrevCurrentData := vCurCurrentData;
    end;
    Result.Add(TRedoCacheData.Create(vIndex, vLastSnapshotBlock, vCurCurrentData, vRedoLogs));
  end;
end;

function TRoundCache.QueryCurrentData(ParaRoundIndex: TUInt64; out ParaLastSnapshotBlock: ISnapshotBlock): TMemDB;
begin
  Result := TMemDB.Create(TComparerDefault.Create, 0);
  ParaLastSnapshotBlock := RoundToLastSnapshotBlock(ParaRoundIndex);
  if ParaLastSnapshotBlock = nil then
  begin
    Result.Free;
    Result := nil;
    Exit;
  end;
  SetStorageToCache(Result, TAddressGovernance, ParaLastSnapshotBlock.Hash);
  SetAllBalanceToCache(Result, ParaLastSnapshotBlock.Hash);
end;

function TRoundCache.QueryRedoLogs(ParaRoundIndex: TUInt64; out ParaIsStoreRedoLogs: Boolean): TRoundCacheRedoLogs;
var
  vSnapshotBlocks: TArray<ISnapshotBlock>;
  vSnapshotBlock: ISnapshotBlock;
  vRedoLog: TSnapshotLog;
  vHasRedoLog: Boolean;
begin
  Result := nil;
  ParaIsStoreRedoLogs := False;
  vSnapshotBlocks := GetRoundSnapshotBlocks(ParaRoundIndex);
  if Length(vSnapshotBlocks) = 0 then
  begin
    ParaIsStoreRedoLogs := True;
    Exit;
  end;

  Result := TRoundCacheRedoLogs.Create;
  for vSnapshotBlock in vSnapshotBlocks do
  begin
    vRedoLog := mStateDB.Redo.QueryLog(vSnapshotBlock.Height, vHasRedoLog);
    if not vHasRedoLog then
    begin
      Exit(nil);
    end;
    Result.Add(vSnapshotBlock.Height, vRedoLog);
  end;
  ParaIsStoreRedoLogs := True;
end;

function TRoundCache.BuildCurrentData(ParaPrevCurrentData: TMemDB; ParaRedoLogs: TRoundCacheRedoLogs): TMemDB;
var
  vSnapshotLog: TRoundCacheSnapshotLog;
  vAddr: TAddress;
  vRedoLogs: TArray<TRoundCacheLogItem>;
  vRedoLog: TRoundCacheLogItem;
  vKV: TArray<TBytes>;
  vTokenId: TTokenTypeId;
  vBalance: TBigInteger;
begin
  Result := ParaPrevCurrentData.Copy2(mMemPool.GetByteSlice, mMemPool.GetIntSlice);
  for vSnapshotLog in ParaRedoLogs.Logs do
  begin
    for vAddr in vSnapshotLog.LogMap.Keys do
    begin
      vRedoLogs := vSnapshotLog.LogMap[vAddr];
      for vRedoLog in vRedoLogs do
      begin
        for vKV in vRedoLog.Storage do
        begin
          Result.Put(MakeStorageKey(vKV[0]), vKV[1]);
        end;
        for vTokenId in vRedoLog.BalanceMap.Keys do
        begin
          vBalance := vRedoLog.BalanceMap[vTokenId];
          if vTokenId = TViteTokenId then
          begin
            Result.Put(MakeBalanceKey(vAddr.Bytes), vBalance.ToBytes);
          end;
        end;
      end;
    end;
  end;
end;

function TRoundCache.RoundToLastSnapshotBlock(ParaRoundIndex: TUInt64): ISnapshotBlock;
var
  vNextRoundIndex: TUInt64;
  vStartTime: TDateTime;
  vSb: ISnapshotBlock;
  vSbRoundIndex: TUInt64;
begin
  vNextRoundIndex := ParaRoundIndex + 1;
  vStartTime := mTimeIndex.Index2Time(vNextRoundIndex);
  vSb := mChain.GetSnapshotHeaderBeforeTime(vStartTime);
  if vSb = nil then
  begin
    raise Exception.CreateFmt('startTime is %s, sb is nil', [FormatDateTime('c', vStartTime)]);
  end;
  vSbRoundIndex := mTimeIndex.Time2Index(vSb.Timestamp);
  if vSbRoundIndex = ParaRoundIndex then
  begin
    Result := vSb
  end
  else
  begin
    Result := nil;
  end;
end;

function TRoundCache.GetRoundSnapshotBlocks(ParaRoundIndex: TUInt64): TArray<ISnapshotBlock>;
var
  vStartTime, vNextStartTime: TDateTime;
  vCurrentLastSb: ISnapshotBlock;
  vNextFirstSbRoundIndex: TUInt64;
begin
  vStartTime := mTimeIndex.Index2Time(ParaRoundIndex);
  vNextStartTime := mTimeIndex.Index2Time(ParaRoundIndex + 1);
  vCurrentLastSb := mChain.GetSnapshotHeaderBeforeTime(vNextStartTime);
  if vCurrentLastSb = nil then
  begin
    raise Exception.CreateFmt('currentLastSb is nil, nextStartTime is %s', [FormatDateTime('c', vNextStartTime)]);
  end;
  vNextFirstSbRoundIndex := mTimeIndex.Time2Index(vCurrentLastSb.Timestamp);
  if vNextFirstSbRoundIndex < ParaRoundIndex then
  begin
    Exit(nil);
  end;
  if vNextFirstSbRoundIndex > ParaRoundIndex then
  begin
    raise Exception.CreateFmt('nextFirstSbRoundIndex should be smaller than roundIndex. nextFirstSbRoundIndex: %d, roundIndex: %d', [vNextFirstSbRoundIndex, ParaRoundIndex]);
  end;
  Result := mChain.GetSnapshotHeadersAfterOrEqualTime(THashHeight.Create(vCurrentLastSb.Hash, vCurrentLastSb.Height), vStartTime, nil);
end;

procedure TRoundCache.SetAllBalanceToCache(ParaRoundData: TMemDB; ParaSnapshotHash: THash);
const
  BatchSize = 10000;
var
  vAddressList: TArray<TAddress>;
begin
  SetLength(vAddressList, 0);
  mChain.IterateAccounts(
    procedure(ParaAddr: TAddress; ParaAccountId: TUInt64)
    begin
      vAddressList := vAddressList + [ParaAddr];
      if Length(vAddressList) mod BatchSize = 0 then
      begin
        SetBalanceToCache(ParaRoundData, ParaSnapshotHash, vAddressList);
        SetLength(vAddressList, 0);
      end;
    end
  );
  if Length(vAddressList) > 0 then
  begin
    SetBalanceToCache(ParaRoundData, ParaSnapshotHash, vAddressList);
  end;
end;

procedure TRoundCache.SetBalanceToCache(ParaRoundData: TMemDB; ParaSnapshotHash: THash; ParaAddressList: TArray<TAddress>);
var
  vBalanceMap: TDictionary<TAddress, TBigInteger>;
  vNotFound: TArray<TAddress>;
  vAddr: TAddress;
  vBalance: TBigInteger;
begin
  vBalanceMap := mStateDB.GetSnapshotViteBalanceList(ParaSnapshotHash, ParaAddressList, vNotFound);
  for vAddr in vBalanceMap.Keys do
  begin
    vBalance := vBalanceMap[vAddr];
    if vBalance <> nil then
    begin
      ParaRoundData.Put(MakeBalanceKey(vAddr.Bytes), vBalance.ToBytes);
    end;
  end;
end;

procedure TRoundCache.SetStorageToCache(ParaRoundData: TMemDB; ParaContractAddress: TAddress; ParaSnapshotHash: THash);
var
  vStorageDatabase: IStorageDatabase;
  vIter: IStorageIterator;
begin
  vStorageDatabase := mStateDB.NewStorageDatabase(ParaSnapshotHash, ParaContractAddress);
  vIter := vStorageDatabase.NewStorageIterator(nil);
  try
    while vIter.Next do
    begin
      ParaRoundData.Put(MakeStorageKey(vIter.Key), vIter.Value);
    end;
  finally
    vIter.Release;
  end;
end;

procedure TRoundCache.DestroyMemDb(ParaDb: TMemDB);
begin
  if ParaDb <> nil then
  begin
    ParaDb.Destroy2(mMemPool.Put);
  end;
end;

function MakeStorageKey(ParaKey: TBytes): TBytes;
begin
  Result := TBytes.Create(TChainUtils.StorageKeyPrefix) + ParaKey;
end;

function MakeBalanceKey(ParaKey: TBytes): TBytes;
begin
  Result := TBytes.Create(TChainUtils.BalanceKeyPrefix) + ParaKey;
end;

end.
