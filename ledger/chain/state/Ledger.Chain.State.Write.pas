unit Ledger.Chain.State.Write;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Math.BigInt,
  GoCache,
  Interfaces.Core,
  Ledger.Chain.Utils,
  Ledger.Chain.State.StateDB,
  Common.DB.XLevelDB,
  Common.Types;

type
  TStateDBHelper = class helper for TStateDB
  public
    function Write(ABlock: IVmAccountBlock): HResult;
    procedure WriteByRedo(ABlockHash: THash; AAddr: TAddress; ARedoLog: TLogItem);
    function InsertSnapshotBlock(ASnapshotBlock: TSnapshotBlock; AConfirmedBlocks: TArray<TAccountBlock>): HResult;
  end;

implementation

{ TStateDBHelper }

function TStateDBHelper.Write(ABlock: IVmAccountBlock): HResult;
var
  batch: TBatch;
  vmDb: IVmDb;
  accountBlock: TAccountBlock;
  redoLog: TLogItem;
  unsavedStorage: TArray<TBytes>;
  kv: TBytes;
  unsavedBalanceMap: TDictionary<TTokenTypeId, TBigInteger>;
  tokenTypeId: TTokenTypeId;
  balance: TBigInteger;
  unsavedCode: TBytes;
  codeKey: TBytes;
  unsavedContractMeta: TDictionary<TAddress, TContractMeta>;
  addr: TAddress;
  meta: TContractMeta;
  contractKey, gidContractKey: TBytes;
  metaBytes: TBytes;
  vmLogListKey: TBytes;
  bytes: TBytes;
  callDepth: Word;
  callDepthBytes: TBytes;
  sendBlock: TAccountBlock;
begin
  batch := Self.Store.NewBatch;

  vmDb := ABlock.VmDb;
  if not vmDb.CanWrite then
  begin
    Result := E_FAIL;
    Exit;
  end;

  accountBlock := ABlock.AccountBlock;

  // write unsaved storage
  unsavedStorage := vmDb.GetUnsavedStorage;
  redoLog.Storage := unsavedStorage;
  for kv in unsavedStorage do
  begin
    if Length(kv[1]) <= 0 then
      batch.Delete(CreateStorageValueKey(accountBlock.AccountAddress, kv[0]))
    else
      batch.Put(CreateStorageValueKey(accountBlock.AccountAddress, kv[0]), kv[1]);
  end;

  // write unsaved balance
  unsavedBalanceMap := vmDb.GetUnsavedBalanceMap;
  redoLog.BalanceMap := TDictionary<TTokenTypeId, TBigInteger>.Create;
  for tokenTypeId in unsavedBalanceMap.Keys do
  begin
    balance := unsavedBalanceMap[tokenTypeId];
    Self.WriteBalance(batch, CreateBalanceKey(accountBlock.AccountAddress, tokenTypeId), balance.Bytes);
    redoLog.BalanceMap.Add(tokenTypeId, balance);
  end;

  // write unsaved code
  unsavedCode := vmDb.GetUnsavedContractCode;
  if unsavedCode <> nil then
  begin
    codeKey := CreateCodeKey(accountBlock.AccountAddress);
    batch.Put(codeKey, unsavedCode);
    redoLog.Code := unsavedCode;
  end;

  // write unsaved contract meta
  unsavedContractMeta := vmDb.GetUnsavedContractMeta;
  if unsavedContractMeta.Count > 0 then
  begin
    redoLog.ContractMeta := TDictionary<TAddress, TBytes>.Create;
    for addr in unsavedContractMeta.Keys do
    begin
      meta := unsavedContractMeta[addr];
      meta.CreateBlockHash := accountBlock.Hash;
      contractKey := CreateContractMetaKey(addr);
      gidContractKey := CreateGidContractKey(meta.Gid, addr);
      metaBytes := meta.Serialize;
      Self.WriteContractMeta(batch, contractKey, metaBytes);
      batch.Put(gidContractKey, nil);
      redoLog.ContractMeta.Add(addr, metaBytes);
    end;
  end;

  // write vm log
  if (accountBlock.LogHash <> nil) and CanWriteVmLog(accountBlock.AccountAddress) then
  begin
    vmLogListKey := CreateVmLogListKey(accountBlock.LogHash);
    bytes := vmDb.GetLogList.Serialize;
    batch.Put(vmLogListKey, bytes);
    redoLog.VmLogList := TDictionary<THash, TBytes>.Create;
    redoLog.VmLogList.Add(accountBlock.LogHash, bytes);
  end;

  // write call depth
  if accountBlock.IsReceiveBlock and (Length(accountBlock.SendBlockList) > 0) then
  begin
    callDepth := vmDb.GetCallDepth(accountBlock.FromBlockHash);
    Inc(callDepth);
    SetLength(callDepthBytes, 2);
    TBitConverter.GetBytes(callDepth, callDepthBytes, 0);
    redoLog.CallDepth := TDictionary<THash, Word>.Create;
    for sendBlock in accountBlock.SendBlockList do
    begin
      redoLog.CallDepth.Add(sendBlock.Hash, callDepth);
      batch.Put(CreateCallDepthKey(sendBlock.Hash), callDepthBytes);
    end;
  end;

  // add storage redo log
  redoLog.Height := accountBlock.Height;
  Self.Redo.AddLog(accountBlock.AccountAddress, redoLog);

  // write batch
  Self.Store.WriteAccountBlock(batch, ABlock.AccountBlock);

  Result := S_OK;
end;

procedure TStateDBHelper.WriteByRedo(ABlockHash: THash; AAddr: TAddress; ARedoLog: TLogItem);
var
  batch: TBatch;
  kv: TBytes;
  tokenTypeId: TTokenTypeId;
  balance: TBigInteger;
  unsavedCode: TBytes;
  codeKey: TBytes;
  unsavedContractMeta: TDictionary<TAddress, TBytes>;
  addr: TAddress;
  metaBytes: TBytes;
  contractKey, gidContractKey: TBytes;
  logHash: THash;
  vmLogListBytes: TBytes;
  callDepthBytes: TBytes;
  sendHash: THash;
  callDepth: Word;
begin
  batch := Self.Store.NewBatch;

  // write unsaved storage
  for kv in ARedoLog.Storage do
  begin
    if Length(kv[1]) <= 0 then
      batch.Delete(CreateStorageValueKey(AAddr, kv[0]))
    else
      batch.Put(CreateStorageValueKey(AAddr, kv[0]), kv[1]);
  end;

  // write unsaved balance
  for tokenTypeId in ARedoLog.BalanceMap.Keys do
  begin
    balance := ARedoLog.BalanceMap[tokenTypeId];
    Self.WriteBalance(batch, CreateBalanceKey(AAddr, tokenTypeId), balance.Bytes);
  end;

  // write unsaved code
  unsavedCode := ARedoLog.Code;
  if unsavedCode <> nil then
  begin
    codeKey := CreateCodeKey(AAddr);
    batch.Put(codeKey, unsavedCode);
  end;

  // write unsaved contract meta
  unsavedContractMeta := ARedoLog.ContractMeta;
  for addr in unsavedContractMeta.Keys do
  begin
    metaBytes := unsavedContractMeta[addr];
    contractKey := CreateContractMetaKey(addr);
    gidContractKey := TBytes.Create(GidContractKeyPrefix);
    gidContractKey := gidContractKey + addr.Bytes;
    gidContractKey := gidContractKey + TBytes.Copy(metaBytes, 0, GidSize);
    Self.WriteContractMeta(batch, contractKey, metaBytes);
    batch.Put(gidContractKey, nil);
  end;

  // write vm log
  for logHash in ARedoLog.VmLogList.Keys do
  begin
    vmLogListBytes := ARedoLog.VmLogList[logHash];
    batch.Put(CreateVmLogListKey(logHash), vmLogListBytes);
  end;

  // write call depth
  SetLength(callDepthBytes, 2);
  for sendHash in ARedoLog.CallDepth.Keys do
  begin
    callDepth := ARedoLog.CallDepth[sendHash];
    TBitConverter.GetBytes(callDepth, callDepthBytes, 0);
    batch.Put(CreateCallDepthKey(sendHash), callDepthBytes);
  end;

  Self.Store.WriteAccountBlockByHash(batch, ABlockHash);
end;

function TStateDBHelper.InsertSnapshotBlock(ASnapshotBlock: TSnapshotBlock; AConfirmedBlocks: TArray<TAccountBlock>): HResult;
var
  height: UInt64;
  snapshotRedoLog: TSnapshotLog;
  found: Boolean;
  batch: TBatch;
  redoKvMap, redoBalanceMap: TDictionary<TAddress, TDictionary<string, TBytes>>;
  putKeyTemplate: THistoryStorageValueKey;
  addr: TAddress;
  kvMap: TDictionary<string, TBytes>;
  keyStr: string;
  value: TBytes;
  putBalanceTemplate: THistoryBalanceKey;
  balanceMap: TDictionary<TTokenTypeId, TBigInteger>;
  tokenTypeId: TTokenTypeId;
  balance: TBigInteger;
begin
  height := ASnapshotBlock.Height;
  Self.Redo.InsertSnapshotBlock(ASnapshotBlock, AConfirmedBlocks);

  snapshotRedoLog := Self.Redo.QueryLog(height, found);
  if not found then
  begin
    Result := E_FAIL;
    Exit;
  end;

  batch := Self.Store.NewBatch;

  if snapshotRedoLog.Count > 0 then
  begin
    ParseRedoLog(snapshotRedoLog, redoKvMap, redoBalanceMap);

    // put history storage kv
    putKeyTemplate := CreateHistoryStorageValueKey(TAddress.Null, [], height);

    for addr in redoKvMap.Keys do
    begin
      kvMap := redoKvMap[addr];
      putKeyTemplate.AddressRefill(addr);
      for keyStr in kvMap.Keys do
      begin
        value := kvMap[keyStr];
        putKeyTemplate.KeyRefill(TStorageRealKey.Construct(TEncoding.UTF8.GetBytes(keyStr)));
        Self.WriteHistoryKey(batch, putKeyTemplate.Bytes, value);
      end;
    end;

    putBalanceTemplate := CreateHistoryBalanceKey(TAddress.Null, TTokenTypeId.Null, height);
    for addr in redoBalanceMap.Keys do
    begin
      balanceMap := redoBalanceMap[addr];
      putBalanceTemplate.AddressRefill(addr);
      for tokenTypeId in balanceMap.Keys do
      begin
        balance := balanceMap[tokenTypeId];
        putBalanceTemplate.TokenIdRefill(tokenTypeId);
        batch.Put(putBalanceTemplate.Bytes, balance.Bytes);
      end;
    end;
  end;

  // write snapshot
  Self.Store.WriteSnapshot(batch, AConfirmedBlocks);

  // set round cache
  Self.RoundCache.InsertSnapshotBlock(ASnapshotBlock, snapshotRedoLog);

  Result := S_OK;
end;

end.
