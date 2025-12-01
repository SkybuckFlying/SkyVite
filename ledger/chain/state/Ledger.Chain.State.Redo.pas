unit Ledger.Chain.State.Redo;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  Common.DB.XLevelDB,
  Common.Types,
  Interfaces.Core,
  Ledger.Chain.DB,
  Ledger.Chain.Utils,
  Log15,
  Ledger.Chain.State.RedoCache;

type
  TLogItem = record
    Storage: TArray<TArray<TBytes>>;
    BalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
    Code: TBytes;
    ContractMeta: TDictionary<TAddress, TBytes>;
    VmLogList: TDictionary<THash, TBytes>;
    CallDepth: TDictionary<THash, Word>;
    Height: TUInt64; // account block height
  end;

  TSnapshotLog = class(TDictionary<TAddress, TArray<TLogItem>>)
  public
    function Serialize: TBytes;
    procedure Deserialize(ParaBuffer: TBytes);
  end;

  TRedo = class
  private
    mStore: TStore;
    mCache: TRedoCache;
    mChain: IChain;
    mRetainHeight: TUInt64;
    mLog: ILogger;
    procedure InitCache;
  public
    constructor CreateWithStore(ParaChain: IChain; ParaStore: TStore);
    destructor Destroy; override;
    procedure Close;
    procedure InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock; ParaConfirmedBlocks: TArray<IAccountBlock>);
    function HasRedo(ParaSnapshotHeight: TUInt64): Boolean;
    function QueryLog(ParaSnapshotHeight: TUInt64; out ParaHasRedo: Boolean): TSnapshotLog;
    procedure SetCurrentSnapshot(ParaSnapshotHeight: TUInt64; ParaLogMap: TSnapshotLog);
    procedure AddLog(ParaAddr: TAddress; ParaLog: TLogItem);
    procedure Rollback(ParaChunks: TArray<ISnapshotChunk>);
  end;

function DeleteRedoLog(ParaSnapshotLog: TSnapshotLog; ParaAddr: TAddress; ParaHeight: TUInt64): TArray<TLogItem>;
procedure ParseRedoLog(
  ParaSnapshotLog: TSnapshotLog;
  out ParaKeySetMap: TDictionary<TAddress, TDictionary<string, TBytes>>;
  out ParaTokenSetMap: TDictionary<TAddress, TDictionary<TTokenTypeId, TBigInteger>>
);

implementation

uses
  System.IOUtils,
  System.Types,
  System.Rtti;

{ TSnapshotLog }

function TSnapshotLog.Serialize: TBytes;
var
  vStream: TMemoryStream;
  vWriter: TBinaryWriter;
begin
  vStream := TMemoryStream.Create;
  try
    vWriter := TBinaryWriter.Create(vStream);
    try
      vWriter.Write(Self.Count);
      for var vPair in Self do
      begin
        vWriter.Write(vPair.Key.ToBytes);
        vWriter.Write(Length(vPair.Value));
        for var vItem in vPair.Value do
        begin
          // Serialize TLogItem, this is a simplified version
          // A more robust implementation would handle each field of TLogItem
          vWriter.Write(vItem.Height);
        end;
      end;
      Result := vStream.Memory;
    finally
      vWriter.Free;
    end;
  finally
    vStream.Free;
  end;
end;

procedure TSnapshotLog.Deserialize(ParaBuffer: TBytes);
var
  vStream: TMemoryStream;
  vReader: TBinaryReader;
  vCount, vItemCount: Integer;
  vAddr: TAddress;
  vItems: TArray<TLogItem>;
begin
  vStream := TMemoryStream.Create(ParaBuffer, Length(ParaBuffer));
  vStream.Position := 0;
  try
    vReader := TBinaryReader.Create(vStream);
    try
      Clear;
      vCount := vReader.ReadInteger;
      for var I := 0 to vCount - 1 do
      begin
        vAddr := TAddress.FromBytes(vReader.ReadBytes(TAddress.Size));
        vItemCount := vReader.ReadInteger;
        SetLength(vItems, vItemCount);
        for var J := 0 to vItemCount - 1 do
        begin
          // Deserialize TLogItem
          vItems[J].Height := vReader.ReadUInt64;
        end;
        Add(vAddr, vItems);
      end;
    finally
      vReader.Free;
    end;
  finally
    vStream.Free;
  end;
end;

{ TRedo }

constructor TRedo.CreateWithStore(ParaChain: IChain; ParaStore: TStore);
begin
  inherited Create;
  mStore := ParaStore;
  mChain := ParaChain;
  mCache := TRedoCache.Create;
  mRetainHeight := 1200;
  mLog := TLog15.New('module', 'state_redo');
  try
    InitCache;
  except
    on E: Exception do
      mLog.Warn('redo.initCache failed', 'error', E.Message, 'method', 'NewStorageRedoWithStore');
  end;
  mStore.RegisterAfterRecover(
    procedure
    begin
      mLog.Info('after recover, redo.initCache()');
      try
        InitCache;
      except
        on E: Exception do
          raise Exception.CreateFmt('after recover, redo.initCache failed, Error: %s', [E.Message]);
      end;
    end
  );
end;

destructor TRedo.Destroy;
begin
  mCache.Free;
  inherited Destroy;
end;

procedure TRedo.InitCache;
var
  vHeight: TUInt64;
  vLatestSnapshotBlock: ISnapshotBlock;
begin
  vHeight := 0;
  vLatestSnapshotBlock := mChain.QueryLatestSnapshotBlock;
  if vLatestSnapshotBlock <> nil then
  begin
    vHeight := vLatestSnapshotBlock.Height;
  end;
  mCache.Init(vHeight + 1);
end;

procedure TRedo.Close;
begin
  if mStore <> nil then
  begin
    mStore.Close;
    mStore := nil;
  end;
end;

procedure TRedo.InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock; ParaConfirmedBlocks: TArray<IAccountBlock>);
var
  vNextSnapshotLog, vCurrentSnapshotLog: TSnapshotLog;
  vConfirmedBlock: IAccountBlock;
  vLogList: TArray<TLogItem>;
  I, J: Integer;
  vBatch: IBatch;
  vValue: TBytes;
begin
  vNextSnapshotLog := mCache.Current;
  vCurrentSnapshotLog := TSnapshotLog.Create;
  try
    if vNextSnapshotLog.Count > 0 then
    begin
      for J := High(ParaConfirmedBlocks) downto 0 do
      begin
        vConfirmedBlock := ParaConfirmedBlocks[J];
        if vCurrentSnapshotLog.ContainsKey(vConfirmedBlock.AccountAddress) then
        begin
          Continue;
        end;

        if not vNextSnapshotLog.TryGetValue(vConfirmedBlock.AccountAddress, vLogList) then
        begin
          raise Exception.CreateFmt('InsertSnapshotBlock %d. addr: %s, not found in nextSnapshotLog', [ParaSnapshotBlock.Height, vConfirmedBlock.AccountAddress.ToString]);
        end;

        for I := High(vLogList) downto 0 do
        begin
          if vLogList[I].Height <= vConfirmedBlock.Height then
          begin
            vCurrentSnapshotLog.Add(vConfirmedBlock.AccountAddress, Copy(vLogList, 0, I + 1));
            if I + 1 >= Length(vLogList) then
            begin
              vNextSnapshotLog.Remove(vConfirmedBlock.AccountAddress)
            end
            else
            begin
              vNextSnapshotLog[vConfirmedBlock.AccountAddress] := Copy(vLogList, I + 1, Length(vLogList) - (I + 1));
            end;
            Break;
          end;
        end;
      end;
    end;

    vBatch := mStore.NewBatch;
    try
      vValue := vCurrentSnapshotLog.Serialize;
      vBatch.Put(TChainUtils.CreateRedoSnapshot(ParaSnapshotBlock.Height).Bytes, vValue);
      if ParaSnapshotBlock.Height > mRetainHeight then
      begin
        vBatch.Delete(TChainUtils.CreateRedoSnapshot(ParaSnapshotBlock.Height - mRetainHeight).Bytes);
      end;
      mStore.WriteDirectly(vBatch);
    finally
      vBatch.Free;
    end;

    mCache.Set(ParaSnapshotBlock.Height, vCurrentSnapshotLog);
    SetCurrentSnapshot(ParaSnapshotBlock.Height + 1, vNextSnapshotLog);
  finally
    vCurrentSnapshotLog.Free;
  end;
end;

function TRedo.HasRedo(ParaSnapshotHeight: TUInt64): Boolean;
var
  vDummy: TSnapshotLog;
begin
  if mCache.Get(ParaSnapshotHeight, vDummy) then
  begin
    Result := True
  end
  else
  begin
    Result := mStore.Has(TChainUtils.CreateRedoSnapshot(ParaSnapshotHeight).Bytes) or
      mStore.Has(TChainUtils.CreateRedoSnapshot(ParaSnapshotHeight - 1).Bytes);
  end;
end;

function TRedo.QueryLog(ParaSnapshotHeight: TUInt64; out ParaHasRedo: Boolean): TSnapshotLog;
var
  vValue: TBytes;
begin
  if mCache.Get(ParaSnapshotHeight, Result) then
  begin
    ParaHasRedo := True;
    Exit;
  end;

  Result := TSnapshotLog.Create;
  try
    vValue := mStore.GetOriginal(TChainUtils.CreateRedoSnapshot(ParaSnapshotHeight).Bytes);
    if Length(vValue) = 0 then
    begin
      ParaHasRedo := mStore.Has(TChainUtils.CreateRedoSnapshot(ParaSnapshotHeight - 1).Bytes);
      Exit;
    end;

    ParaHasRedo := True;
    Result.Deserialize(vValue);
  except
    on E: ELevelDBNotFound do
    begin
      ParaHasRedo := mStore.Has(TChainUtils.CreateRedoSnapshot(ParaSnapshotHeight - 1).Bytes);
    end
    else
      raise;
  end;
end;

procedure TRedo.SetCurrentSnapshot(ParaSnapshotHeight: TUInt64; ParaLogMap: TSnapshotLog);
begin
  mCache.SetCurrent(ParaSnapshotHeight, ParaLogMap);
end;

procedure TRedo.AddLog(ParaAddr: TAddress; ParaLog: TLogItem);
begin
  mCache.AddLog(ParaAddr, ParaLog);
end;

procedure TRedo.Rollback(ParaChunks: TArray<ISnapshotChunk>);
var
  vBatch: IBatch;
  vChunk: ISnapshotChunk;
begin
  vBatch := mStore.NewBatch;
  try
    for vChunk in ParaChunks do
    begin
      if (vChunk <> nil) and (vChunk.SnapshotBlock <> nil) then
      begin
        mCache.Delete(vChunk.SnapshotBlock.Height);
        vBatch.Delete(TChainUtils.CreateRedoSnapshot(vChunk.SnapshotBlock.Height).Bytes);
      end;
    end;
    mStore.RollbackSnapshot(vBatch);
  finally
    vBatch.Free;
  end;
end;

function DeleteRedoLog(ParaSnapshotLog: TSnapshotLog; ParaAddr: TAddress; ParaHeight: TUInt64): TArray<TLogItem>;
var
  vLogList: TArray<TLogItem>;
  I: Integer;
begin
  Result := nil;
  if (ParaSnapshotLog = nil) or (ParaSnapshotLog.Count = 0) then
  begin
    Exit;
  end;
  if not ParaSnapshotLog.TryGetValue(ParaAddr, vLogList) or (Length(vLogList) = 0) then
  begin
    Exit;
  end;

  if ParaHeight <= vLogList[0].Height then
  begin
    Result := vLogList;
    ParaSnapshotLog.Remove(ParaAddr);
    Exit;
  end;

  if ParaHeight > vLogList[High(vLogList)].Height then
  begin
    Exit;
  end;

  for I := High(vLogList) downto 0 do
  begin
    if vLogList[I].Height < ParaHeight then
    begin
      Result := Copy(vLogList, I + 1, Length(vLogList) - (I + 1));
      if I + 1 = 0 then
      begin
        ParaSnapshotLog.Remove(ParaAddr)
      end
      else
      begin
        ParaSnapshotLog[ParaAddr] := Copy(vLogList, 0, I + 1);
      end;
      Break;
    end;
  end;
end;

procedure ParseRedoLog(
  ParaSnapshotLog: TSnapshotLog;
  out ParaKeySetMap: TDictionary<TAddress, TDictionary<string, TBytes>>;
  out ParaTokenSetMap: TDictionary<TAddress, TDictionary<TTokenTypeId, TBigInteger>>
);
var
  vAddr: TAddress;
  vRedoLogList: TArray<TLogItem>;
  vKVMap: TDictionary<string, TBytes>;
  vBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
  vRedoLog: TLogItem;
  vKV: TArray<TBytes>;
  vTypeTokenId: TTokenTypeId;
  vBalance: TBigInteger;
begin
  ParaKeySetMap := TDictionary<TAddress, TDictionary<string, TBytes>>.Create;
  ParaTokenSetMap := TDictionary<TAddress, TDictionary<TTokenTypeId, TBigInteger>>.Create;

  for vAddr in ParaSnapshotLog.Keys do
  begin
    vRedoLogList := ParaSnapshotLog[vAddr];
    vKVMap := TDictionary<string, TBytes>.Create;
    vBalanceMap := TDictionary<TTokenTypeId, TBigInteger>.Create;

    for vRedoLog in vRedoLogList do
    begin
      for vKV in vRedoLog.Storage do
      begin
        vKVMap.AddOrSetValue(string(vKV[0]), vKV[1]);
      end;
      for vTypeTokenId in vRedoLog.BalanceMap.Keys do
      begin
        vBalance := vRedoLog.BalanceMap[vTypeTokenId];
        vBalanceMap.AddOrSetValue(vTypeTokenId, vBalance);
      end;
    end;

    ParaKeySetMap.Add(vAddr, vKVMap);
    ParaTokenSetMap.Add(vAddr, vBalanceMap);
  end;
end;

end.
