unit Ledger.Chain.State.Delete;

interface

uses
  Common,
  Common.DB.XLevelDB,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.State.Cache,
  Ledger.Chain.State.Interface,
  Ledger.Chain.State.Interface.Mock,
  Ledger.Chain.State.Iteration,
  Ledger.Chain.State.Redo,
  Ledger.Chain.State.Redo.Cache,
  Ledger.Chain.State.Round.Cache,
  Ledger.Chain.State.Round.Cache.Test,
  Ledger.Chain.State.State.DB,
  Ledger.Chain.State.StateDB,
  Ledger.Chain.State.Storage.Database,
  Ledger.Chain.State.Transform.Iterator,
  Ledger.Chain.State.Write,
  Ledger.Chain.Utils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  System.SysUtils;

type
  TStateDBDeleteHelper = class helper for TStateDB
  public
    procedure RollbackSnapshotBlocks(
      ParaDeletedSnapshotSegments: TArray<ISnapshotChunk>;
      ParaNewUnconfirmedBlocks: TArray<IAccountBlock>
    );
    procedure RollbackAccountBlocks(ParaAccountBlocks: TArray<IAccountBlock>);
  private
    procedure RollbackByRedo(
      ParaBatch: IBatch;
      ParaSnapshotBlock: ISnapshotBlock;
      ParaRedoLogMap: TDictionary<TAddress, TArray<TLogItem>>;
      ParaRollbackKeySet: TDictionary<TAddress, TDictionary<string, Boolean>>;
      ParaRollbackTokenSet: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>
    );
    procedure RecoverLatestIndexToSnapshot(
      ParaBatch: IBatch;
      ParaHashHeight: THashHeight;
      ParaKeySetMap: TDictionary<TAddress, TDictionary<string, Boolean>>;
      ParaTokenSetMap: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>
    );
    procedure RecoverLatestIndexByRedo(
      ParaBatch: IBatch;
      ParaAddrMap: TDictionary<TAddress, Boolean>;
      ParaRedoLogMap: TDictionary<TAddress, TArray<TLogItem>>;
      ParaRollbackKeySet: TDictionary<TAddress, TDictionary<string, Boolean>>;
      ParaRollbackTokenSet: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>
    );
    procedure RollbackAccountBlock(ParaBatch: IBatch; ParaAccountBlock: IAccountBlock);
    procedure RecoverToSnapshot(
      ParaBatch: IBatch;
      ParaSnapshotHeight: TUInt64;
      ParaUnconfirmedLog: TDictionary<TAddress, TArray<TLogItem>>;
      ParaAddrMap: TDictionary<TAddress, Boolean>
    );
    procedure RecoverStorageToSnapshot(
      ParaBatch: IBatch;
      ParaHeight: TUInt64;
      ParaAddr: TAddress;
      ParaKeySet: TDictionary<string, TBytes>
    );
    procedure RecoverBalanceToSnapshot(
      ParaBatch: IBatch;
      ParaHeight: TUInt64;
      ParaAddr: TAddress;
      ParaTokenSet: TDictionary<TTokenTypeId, TBigInteger>
    );
    procedure CompactHistoryStorage;
    procedure DeleteContractMeta(ParaBatch: IBatch; ParaKey: TBytes);
    procedure DeleteBalance(ParaBatch: IBatch; ParaKey: TBytes);
    procedure DeleteHistoryKey(ParaBatch: IBatch; ParaKey: TBytes);
    procedure RollbackRoundCache(ParaDeletedSnapshotSegments: TArray<ISnapshotChunk>);
  end;

implementation

uses
  System.IOUtils,
  Common.DB.XLevelDB.Util,
  Ledger.Chain.State.StorageDatabase;

{ TStateDBDeleteHelper }

procedure TStateDBDeleteHelper.RollbackSnapshotBlocks(
  ParaDeletedSnapshotSegments: TArray<ISnapshotChunk>;
  ParaNewUnconfirmedBlocks: TArray<IAccountBlock>
);
var
  vBatch: IBatch;
  vLatestSnapshotBlock: ISnapshotBlock;
  vNewUnconfirmedLog: TDictionary<TAddress, TArray<TLogItem>>;
  vHasRedo: Boolean;
  vSnapshotHeight: TUInt64;
  vHasBuiltInContract: Boolean;
  vRollbackKeySet: TDictionary<TAddress, TDictionary<string, Boolean>>;
  vRollbackTokenSet: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>;
  vSeg: ISnapshotChunk;
  vIndex: Integer;
  vCurrentSnapshotLog: TDictionary<TAddress, TArray<TLogItem>>;
  vAddrMap: TDictionary<TAddress, Boolean>;
  vOldUnconfirmedLog: TDictionary<TAddress, TArray<TLogItem>>;
  vAccountBlock: IAccountBlock;
  vBlock: IAccountBlock;
  vRedoLogList: TArray<TLogItem>;
  vStartHeight, vTargetIndex: TUInt64;
begin
  Self.DisableCache;
  try
    Self.RollbackRoundCache(ParaDeletedSnapshotSegments);

    vBatch := Self.Store.NewBatch;
    try
      vLatestSnapshotBlock := Self.Chain.GetLatestSnapshotBlock;
      vNewUnconfirmedLog := Self.Redo.QueryLog(vLatestSnapshotBlock.Height + 1, vHasRedo);

      vSnapshotHeight := vLatestSnapshotBlock.Height;
      vHasBuiltInContract := True;

      if vHasRedo then
      begin
        vRollbackKeySet := TDictionary<TAddress, TDictionary<string, Boolean>>.Create;
        vRollbackTokenSet := TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>.Create;
        try
          for vIndex := 0 to High(ParaDeletedSnapshotSegments) do
          begin
            vSeg := ParaDeletedSnapshotSegments[vIndex];
            Inc(vSnapshotHeight);
            for vAccountBlock in vSeg.AccountBlocks do
            begin
              if not vHasBuiltInContract and Self.ShouldCacheContractData(vAccountBlock.AccountAddress) then
              begin
                vHasBuiltInContract := True;
              end;
            end;

            if vIndex <= 0 then
            begin
              vCurrentSnapshotLog := vNewUnconfirmedLog
            end
            else
            begin
              vCurrentSnapshotLog := Self.Redo.QueryLog(vSnapshotHeight, vHasRedo);
            end;

            Self.RollbackByRedo(vBatch, vSeg.SnapshotBlock, vCurrentSnapshotLog, vRollbackKeySet, vRollbackTokenSet);
          end;

          Self.RecoverLatestIndexToSnapshot(vBatch, THashHeight.Create(vLatestSnapshotBlock.Height, vLatestSnapshotBlock.Hash), vRollbackKeySet, vRollbackTokenSet);
        finally
          vRollbackKeySet.Free;
          vRollbackTokenSet.Free;
        end;
      end
      else
      begin
        vAddrMap := TDictionary<TAddress, Boolean>.Create;
        try
          for vIndex := 0 to High(ParaDeletedSnapshotSegments) do
          begin
            vSeg := ParaDeletedSnapshotSegments[vIndex];
            Inc(vSnapshotHeight);
            if (vIndex = High(ParaDeletedSnapshotSegments)) and (vSeg.SnapshotBlock = nil) then
            begin
              vOldUnconfirmedLog := Self.Redo.QueryLog(vLatestSnapshotBlock.Height + Length(ParaDeletedSnapshotSegments), vHasRedo);
            end;

            for vAccountBlock in vSeg.AccountBlocks do
            begin
              vAddrMap.Add(vAccountBlock.AccountAddress, True);
              if not vHasBuiltInContract and Self.ShouldCacheContractData(vAccountBlock.AccountAddress) then
              begin
                vHasBuiltInContract := True;
              end;
              Self.RollbackAccountBlock(vBatch, vAccountBlock);
            end;
          end;
          Self.RecoverToSnapshot(vBatch, vLatestSnapshotBlock.Height, vOldUnconfirmedLog, vAddrMap);
        finally
          vAddrMap.Free;
        end;
      end;

      Self.Store.RollbackSnapshot(vBatch);
      Self.Redo.Rollback(ParaDeletedSnapshotSegments);
      Self.Redo.SetCurrentSnapshot(vLatestSnapshotBlock.Height + 1, vNewUnconfirmedLog);

      if vHasBuiltInContract then
      begin
        Self.InitSnapshotValueCache;
      end;

      for vBlock in ParaNewUnconfirmedBlocks do
      begin
        vRedoLogList := vNewUnconfirmedLog[vBlock.AccountAddress];
        vStartHeight := vRedoLogList[0].Height;
        vTargetIndex := vBlock.Height - vStartHeight;
        Self.WriteByRedo(vBlock.Hash, vBlock.AccountAddress, vRedoLogList[vTargetIndex]);
      end;
    finally
      vBatch.Free;
    end;
  finally
    Self.EnableCache;
  end;
end;

procedure TStateDBDeleteHelper.RollbackAccountBlocks(ParaAccountBlocks: TArray<IAccountBlock>);
var
  vBatch: IBatch;
  vLatestSnapshotBlock: ISnapshotBlock;
  vUnconfirmedLog: TDictionary<TAddress, TArray<TLogItem>>;
  vHasRedo: Boolean;
  vRollbackKeySet: TDictionary<TAddress, TDictionary<string, Boolean>>;
  vRollbackTokenSet: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>;
  vRollbackLogMap: TDictionary<TAddress, TArray<TLogItem>>;
  vAddrMap: TDictionary<TAddress, Boolean>;
  vAccountBlock: IAccountBlock;
  vDeletedLogList: TArray<TLogItem>;
begin
  vBatch := Self.Store.NewBatch;
  try
    vLatestSnapshotBlock := Self.Chain.GetLatestSnapshotBlock;
    vUnconfirmedLog := Self.Redo.QueryLog(vLatestSnapshotBlock.Height + 1, vHasRedo);
    if not vHasRedo then
    begin
      raise Exception.Create('hasRedo is false');
    end;

    vRollbackKeySet := TDictionary<TAddress, TDictionary<string, Boolean>>.Create;
    vRollbackTokenSet := TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>.Create;
    vRollbackLogMap := TDictionary<TAddress, TArray<TLogItem>>.Create;
    vAddrMap := TDictionary<TAddress, Boolean>.Create;
    try
      for vAccountBlock in ParaAccountBlocks do
      begin
        if vRollbackLogMap.ContainsKey(vAccountBlock.AccountAddress) then
        begin
          Continue;
        end;
        vAddrMap.Add(vAccountBlock.AccountAddress, True);
        vDeletedLogList := DeleteRedoLog(vUnconfirmedLog, vAccountBlock.AccountAddress, vAccountBlock.Height);
        vRollbackLogMap.Add(vAccountBlock.AccountAddress, vDeletedLogList);
      end;

      Self.RollbackByRedo(vBatch, nil, vRollbackLogMap, vRollbackKeySet, vRollbackTokenSet);
      Self.RecoverLatestIndexByRedo(vBatch, vAddrMap, vUnconfirmedLog, vRollbackKeySet, vRollbackTokenSet);
      Self.RecoverLatestIndexToSnapshot(vBatch, THashHeight.Create(vLatestSnapshotBlock.Height, vLatestSnapshotBlock.Hash), vRollbackKeySet, vRollbackTokenSet);

      Self.Redo.SetCurrentSnapshot(vLatestSnapshotBlock.Height + 1, vUnconfirmedLog);
      Self.Store.RollbackAccountBlocks(vBatch, ParaAccountBlocks);
    finally
      vRollbackKeySet.Free;
      vRollbackTokenSet.Free;
      vRollbackLogMap.Free;
      vAddrMap.Free;
    end;
  finally
    vBatch.Free;
  end;
end;

procedure TStateDBDeleteHelper.RollbackByRedo(
  ParaBatch: IBatch;
  ParaSnapshotBlock: ISnapshotBlock;
  ParaRedoLogMap: TDictionary<TAddress, TArray<TLogItem>>;
  ParaRollbackKeySet: TDictionary<TAddress, TDictionary<string, Boolean>>;
  ParaRollbackTokenSet: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>
);
var
  vResetKeyTemplate, vResetBalanceTemplate: IDBKey;
  vIsHistory: Boolean;
  vAddr: TAddress;
  vRedoLogList: TArray<TLogItem>;
  vKeySet: TDictionary<string, Boolean>;
  vTokenSet: TDictionary<TTokenTypeId, Boolean>;
  vRedoLog: TLogItem;
  vKV: TArray<TBytes>;
  vTokenTypeId: TTokenTypeId;
  vContractAddr: TAddress;
  vLogHash: THash;
  vSendBlockHash: THash;
begin
  vIsHistory := ParaSnapshotBlock <> nil;
  if vIsHistory then
  begin
    vResetKeyTemplate := TChainUtils.CreateHistoryStorageValueKey(Default(TAddress), nil, ParaSnapshotBlock.Height);
    vResetBalanceTemplate := TChainUtils.CreateHistoryBalanceKey(Default(TAddress), Default(TTokenTypeId), ParaSnapshotBlock.Height);
  end
  else
  begin
    vResetKeyTemplate := TChainUtils.CreateStorageValueKey(Default(TAddress), nil);
    vResetBalanceTemplate := TChainUtils.CreateBalanceKey(Default(TAddress), Default(TTokenTypeId));
  end;

  for vAddr in ParaRedoLogMap.Keys do
  begin
    vRedoLogList := ParaRedoLogMap[vAddr];
    vResetKeyTemplate.AddressRefill(vAddr);
    vResetBalanceTemplate.AddressRefill(vAddr);

    if not ParaRollbackKeySet.TryGetValue(vAddr, vKeySet) then
    begin
      vKeySet := TDictionary<string, Boolean>.Create;
      ParaRollbackKeySet.Add(vAddr, vKeySet);
    end;

    if not ParaRollbackTokenSet.TryGetValue(vAddr, vTokenSet) then
    begin
      vTokenSet := TDictionary<TTokenTypeId, Boolean>.Create;
      ParaRollbackTokenSet.Add(vAddr, vTokenSet);
    end;

    for vRedoLog in vRedoLogList do
    begin
      for vKV in vRedoLog.Storage do
      begin
        vKeySet.Add(string(vKV[0]), True);
        vResetKeyTemplate.KeyRefill(TStorageRealKey.Construct(vKV[0]));
        if vIsHistory then
        begin
          Self.DeleteHistoryKey(ParaBatch, vResetKeyTemplate.Bytes)
        end
        else
        begin
          ParaBatch.Delete(vResetKeyTemplate.Bytes);
        end;
      end;

      for vTokenTypeId in vRedoLog.BalanceMap.Keys do
      begin
        vTokenSet.Add(vTokenTypeId, True);
        vResetBalanceTemplate.TokenIdRefill(vTokenTypeId);
        if vIsHistory then
        begin
          ParaBatch.Delete(vResetBalanceTemplate.Bytes)
        end
        else
        begin
          Self.DeleteBalance(ParaBatch, vResetBalanceTemplate.Bytes);
        end;
      end;

      for vContractAddr in vRedoLog.ContractMeta.Keys do
      begin
        Self.DeleteContractMeta(ParaBatch, TChainUtils.CreateContractMetaKey(vContractAddr).Bytes);
      end;

      if Length(vRedoLog.Code) > 0 then
      begin
        ParaBatch.Delete(TChainUtils.CreateCodeKey(vAddr).Bytes);
      end;

      for vLogHash in vRedoLog.VmLogList.Keys do
      begin
        ParaBatch.Delete(TChainUtils.CreateVmLogListKey(vLogHash).Bytes);
      end;

      for vSendBlockHash in vRedoLog.CallDepth.Keys do
      begin
        ParaBatch.Delete(TChainUtils.CreateCallDepthKey(vSendBlockHash).Bytes);
      end;
    end;
  end;
end;

procedure TStateDBDeleteHelper.RecoverLatestIndexToSnapshot(
  ParaBatch: IBatch;
  ParaHashHeight: THashHeight;
  ParaKeySetMap: TDictionary<TAddress, TDictionary<string, Boolean>>;
  ParaTokenSetMap: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>
);
var
  vAddr: TAddress;
  vKeySet: TDictionary<string, Boolean>;
  vStorage: TStorageDatabase;
  vKeyStr: string;
  vKey, vValue: TBytes;
  vIter: IIterator;
  vBalanceTemplateKey: TBalanceKey;
  vSeekKey: THistoryBalanceKey;
  vTokenSet: TDictionary<TTokenTypeId, Boolean>;
  vTokenId: TTokenTypeId;
begin
  for vAddr in ParaKeySetMap.Keys do
  begin
    vKeySet := ParaKeySetMap[vAddr];
    vStorage := TStorageDatabase.Create(Self, ParaHashHeight, vAddr);
    try
      for vKeyStr in vKeySet.Keys do
      begin
        vKey := TBytes(vKeyStr);
        vValue := vStorage.GetValue(vKey);
        if Length(vValue) <= 0 then
        begin
          ParaBatch.Delete(TChainUtils.CreateStorageValueKey(vAddr, vKey).Bytes)
        end
        else
        begin
          ParaBatch.Put(TChainUtils.CreateStorageValueKey(vAddr, vKey).Bytes, vValue);
        end;
      end;
    finally
      vStorage.Free;
    end;
  end;

  vIter := Self.Store.NewIterator(TBytesPrefix.Create([TChainUtils.BalanceHistoryKeyPrefix]));
  try
    vBalanceTemplateKey := TChainUtils.CreateBalanceKey(Default(TAddress), Default(TTokenTypeId));
    vSeekKey := TChainUtils.CreateHistoryBalanceKey(Default(TAddress), Default(TTokenTypeId), ParaHashHeight.Height + 1);

    for vAddr in ParaTokenSetMap.Keys do
    begin
      vTokenSet := ParaTokenSetMap[vAddr];
      vSeekKey.AddressRefill(vAddr);
      vBalanceTemplateKey.AddressRefill(vAddr);

      for vTokenId in vTokenSet.Keys do
      begin
        vSeekKey.TokenIdRefill(vTokenId);
        vBalanceTemplateKey.TokenIdRefill(vTokenId);

        vIter.Seek(vSeekKey.Bytes);

        if vIter.Prev and SameBytes(Copy(vIter.Key, 0, Length(vSeekKey.Bytes) - 8), Copy(vSeekKey.Bytes, 0, Length(vSeekKey.Bytes) - 8)) then
        begin
          Self.WriteBalance(ParaBatch, vBalanceTemplateKey.Bytes, vIter.Value)
        end
        else
        begin
          Self.DeleteBalance(ParaBatch, vBalanceTemplateKey.Bytes);
        end;
      end;
    end;
  finally
    vIter := nil;
  end;
end;

procedure TStateDBDeleteHelper.RecoverLatestIndexByRedo(
  ParaBatch: IBatch;
  ParaAddrMap: TDictionary<TAddress, Boolean>;
  ParaRedoLogMap: TDictionary<TAddress, TArray<TLogItem>>;
  ParaRollbackKeySet: TDictionary<TAddress, TDictionary<string, Boolean>>;
  ParaRollbackTokenSet: TDictionary<TAddress, TDictionary<TTokenTypeId, Boolean>>
);
var
  vAddr: TAddress;
  vRedoLogList: TArray<TLogItem>;
  vRedoLog: TLogItem;
  vKV: TArray<TBytes>;
  vKeySet: TDictionary<string, Boolean>;
  vTokenId: TTokenTypeId;
  vBalance: TBigInteger;
  vTokenSet: TDictionary<TTokenTypeId, Boolean>;
begin
  for vAddr in ParaAddrMap.Keys do
  begin
    vRedoLogList := ParaRedoLogMap[vAddr];
    for vRedoLog in vRedoLogList do
    begin
      for vKV in vRedoLog.Storage do
      begin
        if Length(vKV[1]) <= 0 then
        begin
          ParaBatch.Delete(TChainUtils.CreateStorageValueKey(vAddr, vKV[0]).Bytes)
        end
        else
        begin
          ParaBatch.Put(TChainUtils.CreateStorageValueKey(vAddr, vKV[0]).Bytes, vKV[1]);
        end;
        if ParaRollbackKeySet.TryGetValue(vAddr, vKeySet) then
        begin
          vKeySet.Remove(string(vKV[0]));
        end;
      end;

      for vTokenId in vRedoLog.BalanceMap.Keys do
      begin
        vBalance := vRedoLog.BalanceMap[vTokenId];
        Self.WriteBalance(ParaBatch, TChainUtils.CreateBalanceKey(vAddr, vTokenId).Bytes, vBalance.ToBytes);
        if ParaRollbackTokenSet.TryGetValue(vAddr, vTokenSet) then
        begin
          vTokenSet.Remove(vTokenId);
        end;
      end;
    end;
  end;
end;

procedure TStateDBDeleteHelper.RollbackAccountBlock(ParaBatch: IBatch; ParaAccountBlock: IAccountBlock);
var
  vSendBlock: IAccountBlock;
begin
  if ParaAccountBlock.Height <= 1 then
  begin
    ParaBatch.Delete(TChainUtils.CreateCodeKey(ParaAccountBlock.AccountAddress).Bytes);
  end;

  if ParaAccountBlock.BlockType = TBlockType.SendCreate then
  begin
    Self.DeleteContractMeta(ParaBatch, TChainUtils.CreateContractMetaKey(ParaAccountBlock.ToAddress).Bytes);
  end;

  if ParaAccountBlock.LogHash <> nil then
  begin
    ParaBatch.Delete(TChainUtils.CreateVmLogListKey(ParaAccountBlock.LogHash).Bytes);
  end;

  for vSendBlock in ParaAccountBlock.SendBlockList do
  begin
    ParaBatch.Delete(TChainUtils.CreateCallDepthKey(vSendBlock.Hash).Bytes);
    if vSendBlock.BlockType = TBlockType.SendCreate then
    begin
      Self.DeleteContractMeta(ParaBatch, TChainUtils.CreateContractMetaKey(vSendBlock.ToAddress).Bytes);
    end;
  end;
end;

procedure TStateDBDeleteHelper.RecoverToSnapshot(
  ParaBatch: IBatch;
  ParaSnapshotHeight: TUInt64;
  ParaUnconfirmedLog: TDictionary<TAddress, TArray<TLogItem>>;
  ParaAddrMap: TDictionary<TAddress, Boolean>
);
var
  vKeySetMap: TDictionary<TAddress, TDictionary<string, TBytes>>;
  vTokenSetMap: TDictionary<TAddress, TDictionary<TTokenTypeId, TBigInteger>>;
  vAddr: TAddress;
begin
  ParseRedoLog(ParaUnconfirmedLog, vKeySetMap, vTokenSetMap);
  for vAddr in ParaAddrMap.Keys do
  begin
    Self.RecoverStorageToSnapshot(ParaBatch, ParaSnapshotHeight, vAddr, vKeySetMap[vAddr]);
    Self.RecoverBalanceToSnapshot(ParaBatch, ParaSnapshotHeight, vAddr, vTokenSetMap[vAddr]);
  end;
end;

procedure TStateDBDeleteHelper.RecoverStorageToSnapshot(
  ParaBatch: IBatch;
  ParaHeight: TUInt64;
  ParaAddr: TAddress;
  ParaKeySet: TDictionary<string, TBytes>
);
var
  vIter: IIterator;
  vStorageTemplateKey: TStorageValueKey;
  vSeekTemplateKey: THistoryStorageValueKey;
  vIterOk: Boolean;
  vStorageKeyBytes: TStorageRealKey;
  vRealKey: string;
  vPrevOk: Boolean;
  vPrevKey: THistoryStorageValueKey;
  vKey: THistoryStorageValueKey;
  vKeyStr: string;
begin
  vIter := Self.Store.NewIterator(TBytesPrefix.Create(TBytes.Create(TChainUtils.StorageHistoryKeyPrefix) + ParaAddr.Bytes));
  try
    vStorageTemplateKey := TChainUtils.CreateStorageValueKey(ParaAddr, nil);
    vSeekTemplateKey := TChainUtils.CreateHistoryStorageValueKey(ParaAddr, nil, ParaHeight + 1);
    vIterOk := vIter.Next;

    while vIterOk do
    begin
      vStorageKeyBytes := TStorageRealKey.ConstructFix(Copy(vIter.Key, 1 + SizeOf(TAddress), SizeOf(THash) + 1));
      vSeekTemplateKey.KeyRefill(vStorageKeyBytes);
      vStorageTemplateKey.KeyRefill(vStorageKeyBytes);
      vRealKey := vStorageKeyBytes.ToString;
      ParaKeySet.Remove(vRealKey);

      vIter.Seek(vSeekTemplateKey.Bytes);
      vPrevOk := vIter.Prev;
      vPrevKey := THistoryStorageValueKey.Construct(vIter.Key);
      if (vPrevKey <> nil) and (vPrevKey.ExtraAddress = ParaAddr) then
      begin
        if vPrevOk and SameBytes(vSeekTemplateKey.ExtraKeyAndLen, vPrevKey.ExtraKeyAndLen) then
        begin
          if Length(vIter.Value) > 0 then
          begin
            ParaBatch.Put(vStorageTemplateKey.Bytes, vIter.Value)
          end
          else
          begin
            ParaBatch.Delete(vStorageTemplateKey.Bytes);
          end;
        end
        else
        begin
          ParaBatch.Delete(vStorageTemplateKey.Bytes);
        end;
      end;

      while True do
      begin
        vIterOk := vIter.Next;
        if not vIterOk then
        begin
          Break;
        end;
        vKey := THistoryStorageValueKey.Construct(vIter.Key);
        if (vKey = nil) or (vKey.ExtraAddress <> ParaAddr) then
        begin
          Break;
        end;
        if SameBytes(vSeekTemplateKey.ExtraKeyAndLen, vKey.ExtraKeyAndLen) then
        begin
          Self.DeleteHistoryKey(ParaBatch, vKey.Bytes)
        end
        else
        begin
          Break;
        end;
      end;
    end;
  finally
    vIter := nil;
  end;

  for vKeyStr in ParaKeySet.Keys do
  begin
    vStorageTemplateKey.KeyRefill(TStorageRealKey.Construct(TBytes(vKeyStr)));
    ParaBatch.Delete(vStorageTemplateKey.Bytes);
  end;
end;

procedure TStateDBDeleteHelper.RecoverBalanceToSnapshot(
  ParaBatch: IBatch;
  ParaHeight: TUInt64;
  ParaAddr: TAddress;
  ParaTokenSet: TDictionary<TTokenTypeId, TBigInteger>
);
var
  vIter: IIterator;
  vBalanceTemplateKey: TBalanceKey;
  vSeekTemplateKey: THistoryBalanceKey;
  vIterOk: Boolean;
  vIterKey: THistoryBalanceKey;
  vTokenId: TTokenTypeId;
  vPrevOk: Boolean;
  vPrevKey: THistoryBalanceKey;
  vKey: TBytes;
begin
  vIter := Self.Store.NewIterator(TBytesPrefix.Create(TBytes.Create(TChainUtils.BalanceHistoryKeyPrefix) + ParaAddr.Bytes));
  try
    vBalanceTemplateKey := TChainUtils.CreateBalanceKey(ParaAddr, Default(TTokenTypeId));
    vSeekTemplateKey := TChainUtils.CreateHistoryBalanceKey(ParaAddr, Default(TTokenTypeId), ParaHeight + 1);
    vIterOk := vIter.Next;

    while vIterOk do
    begin
      vIterKey := THistoryBalanceKey.Construct(vIter.Key);
      vTokenId := vIterKey.ExtraTokenId;
      vSeekTemplateKey.TokenIdRefill(vTokenId);
      vBalanceTemplateKey.TokenIdRefill(vTokenId);
      ParaTokenSet.Remove(vTokenId);

      vIter.Seek(vSeekTemplateKey.Bytes);
      vPrevOk := vIter.Prev;
      vPrevKey := THistoryBalanceKey.Construct(vIter.Key);

      if vPrevOk and (vSeekTemplateKey.ExtraTokenId = vPrevKey.ExtraTokenId) then
      begin
        Self.WriteBalance(ParaBatch, vBalanceTemplateKey.Bytes, vIter.Value)
      end
      else
      begin
        Self.DeleteBalance(ParaBatch, vBalanceTemplateKey.Bytes);
      end;

      while True do
      begin
        vIterOk := vIter.Next;
        if not vIterOk then
        begin
          Break;
        end;
        vKey := vIter.Key;
        if SameBytes(Copy(vSeekTemplateKey.Bytes, 1 + SizeOf(TAddress), SizeOf(TTokenTypeId)), Copy(vKey, 1 + SizeOf(TAddress), SizeOf(TTokenTypeId))) then
        begin
          ParaBatch.Delete(vKey)
        end
        else
        begin
          Break;
        end;
      end;
    end;
  finally
    vIter := nil;
  end;

  for vTokenId in ParaTokenSet.Keys do
  begin
    vBalanceTemplateKey.TokenIdRefill(vTokenId);
    Self.DeleteBalance(ParaBatch, vBalanceTemplateKey.Bytes);
  end;
end;

procedure TStateDBDeleteHelper.CompactHistoryStorage;
begin
  Self.Store.CompactRange(TBytesPrefix.Create([TChainUtils.StorageHistoryKeyPrefix]));
end;

procedure TStateDBDeleteHelper.DeleteContractMeta(ParaBatch: IBatch; ParaKey: TBytes);
begin
  ParaBatch.Delete(ParaKey);
  Self.Cache.Delete(ConstContractAddrPrefix + string(ParaKey));
end;

procedure TStateDBDeleteHelper.DeleteBalance(ParaBatch: IBatch; ParaKey: TBytes);
begin
  ParaBatch.Delete(ParaKey);
  Self.Cache.Delete(ConstBalancePrefix + string(ParaKey));
end;

procedure TStateDBDeleteHelper.DeleteHistoryKey(ParaBatch: IBatch; ParaKey: TBytes);
var
  vAddrBytes: TBytes;
  vAddr: TAddress;
begin
  ParaBatch.Delete(ParaKey);
  SetLength(vAddrBytes, SizeOf(TAddress));
  System.Move(ParaKey[1], vAddrBytes[0], SizeOf(TAddress));
  vAddr := TAddress.FromBytes(vAddrBytes);
  if Self.ShouldCacheContractData(vAddr) then
  begin
    Self.Cache.Delete(ConstSnapshotValuePrefix + string(vAddrBytes) + string(Self.ParseStorageKey(ParaKey)));
  end;
end;

procedure TStateDBDeleteHelper.RollbackRoundCache(ParaDeletedSnapshotSegments: TArray<ISnapshotChunk>);
var
  vDeletedSnapshotBlocks: TArray<ISnapshotBlock>;
  vChunk: ISnapshotChunk;
begin
  SetLength(vDeletedSnapshotBlocks, 0);
  for vChunk in ParaDeletedSnapshotSegments do
  begin
    if vChunk.SnapshotBlock <> nil then
    begin
      vDeletedSnapshotBlocks := vDeletedSnapshotBlocks + [vChunk.SnapshotBlock];
    end;
  end;
  Self.RoundCache.DeleteSnapshotBlocks(vDeletedSnapshotBlocks);
end;

end.
