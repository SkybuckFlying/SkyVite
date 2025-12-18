unit Ledger.Chain.Delete;

interface

uses
  Ledger.Chain.Account,
  Ledger.Chain.Account.Block,
  Ledger.Chain.Account.Block.Test,
  Ledger.Chain.Account.Test,
  Ledger.Chain.Builtin.Contract,
  Ledger.Chain.Builtin.Contract.Test,
  Ledger.Chain.Chain,
  Ledger.Chain.Chain.Test,
  Ledger.Chain.Check,
  Ledger.Chain.Delete.Test,
  Ledger.Chain.Event.Manager,
  Ledger.Chain.Fork,
  Ledger.Chain.Insert,
  Ledger.Chain.Insert.Test,
  Ledger.Chain.Interface,
  Ledger.Chain.Meta,
  Ledger.Chain.Onroad,
  Ledger.Chain.Onroad.Test,
  Ledger.Chain.Snapshot.Block,
  Ledger.Chain.Snapshot.Block.Test,
  Ledger.Chain.State,
  Ledger.Chain.State.Test,
  Ledger.Chain.Sync.Ledger,
  Ledger.Chain.Unconfirmed,
  Ledger.Chain.Unconfirmed.Test,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  V2.Common,
  V2.Common.Types,
  V2.Interfaces.Core,
  V2.Ledger.Chain.Chain;

type
  TChainHelper = class helper for TChain
  public
    function DeleteSnapshotBlocks(const ParaToHash: THash): TArray<ISnapshotChunk>;
    function DeleteSnapshotBlocksToHeight(ParaToHeight: TUInt64): TArray<ISnapshotChunk>;
    function DeleteAccountBlocks(const ParaAddr: TAddress; const ParaToHash: THash): TArray<IAccountBlock>;
    function DeleteAccountBlocksToHeight(const ParaAddr: TAddress; ParaToHeight: TUInt64): TArray<IAccountBlock>;
  private
    function deleteSnapshotBlocksToHeight(ParaToHeight: TUInt64): TArray<ISnapshotChunk>;
    function deleteAccountBlockByHeightOrHash(const ParaAddr: TAddress; ParaToHeight: TUInt64; const ParaToHash: THash): TArray<IAccountBlock>;
    procedure deleteAccountBlocks(const ParaBlocks: TArray<IAccountBlock>);
  end;

implementation

uses
  V2.Ledger.Chain.Events;

{ TChainHelper }

function TChainHelper.DeleteSnapshotBlocks(const ParaToHash: THash): TArray<ISnapshotChunk>;
var
  vHeight: TUInt64;
  vCErr: string;
begin
  try
    vHeight := Self.FIndexDB.GetSnapshotBlockHeight(ParaToHash);
  except
    on E: Exception do
    begin
      vCErr := Format('c.indexDB.GetSnapshotBlockHeight failed, snapshotHash is %s. Error: %s', [ParaToHash.ToString, E.Message]);
      Self.FLog.Error(vCErr, 'method', 'DeleteSnapshotBlocks');
      raise Exception.Create(vCErr);
    end;
  end;

  if vHeight <= 1 then
  begin
    vCErr := Format('height <= 1, snapshotHash is %s', [ParaToHash.ToString]);
    Self.FLog.Error(vCErr, 'method', 'DeleteSnapshotBlocks');
    raise Exception.Create(vCErr);
  end;

  Result := DeleteSnapshotBlocksToHeight(vHeight);
end;

function TChainHelper.DeleteSnapshotBlocksToHeight(ParaToHeight: TUInt64): TArray<ISnapshotChunk>;
var
  vLatestHeight: TUInt64;
  vCErr: string;
  vDeleteAtOnce: TUInt64;
  vTargetHeight: TUInt64;
  vAllChunksDeleted: TArray<ISnapshotChunk>;
  vChunksDeleted: TArray<ISnapshotChunk>;
begin
  vLatestHeight := Self.GetLatestSnapshotBlock.Height;

  if (ParaToHeight > vLatestHeight) or (ParaToHeight <= 1) then
  begin
    vCErr := Format('toHeight is %d, GetLatestHeight is %d', [ParaToHeight, vLatestHeight]);
    Self.FLog.Error(vCErr, 'method', 'DeleteSnapshotBlocksToHeight');
    raise Exception.Create(vCErr);
  end;

  vDeleteAtOnce := 120;
  vTargetHeight := vLatestHeight + 1;
  SetLength(vAllChunksDeleted, 0);

  while vTargetHeight > ParaToHeight do
  begin
    if vTargetHeight > vDeleteAtOnce then
    begin
      vTargetHeight := vTargetHeight - vDeleteAtOnce;
      if vTargetHeight < ParaToHeight then
      begin
        vTargetHeight := ParaToHeight;
      end;
    end
    else
    begin
      vTargetHeight := ParaToHeight;
    end;

    try
      vChunksDeleted := Self.deleteSnapshotBlocksToHeight(vTargetHeight);
    except
      on E: Exception do
      begin
        vCErr := Format('c.deleteSnapshotBlocksToHeight failed, targetHeight is %d. Error: %s', [vTargetHeight, E.Message]);
        Self.FLog.Error(vCErr, 'method', 'DeleteSnapshotBlocksToHeight');
        raise Exception.Create(vCErr);
      end;
    end;

    if (Length(vAllChunksDeleted) > 0) and (vAllChunksDeleted[0].AccountBlocks = nil) and (vChunksDeleted[Length(vChunksDeleted) - 1].SnapshotBlock = nil) then
    begin
      vAllChunksDeleted[0].AccountBlocks := vChunksDeleted[Length(vChunksDeleted) - 1].AccountBlocks;
      vAllChunksDeleted := Concat(Copy(vChunksDeleted, 0, Length(vChunksDeleted) - 1), vAllChunksDeleted);
    end
    else
    begin
      vAllChunksDeleted := Concat(vChunksDeleted, vAllChunksDeleted);
    end;
  end;

  Result := vAllChunksDeleted;
end;

function TChainHelper.deleteSnapshotBlocksToHeight(ParaToHeight: TUInt64): TArray<ISnapshotChunk>;
var
  vReturnErr: Exception;
  vTmpLocation: ILocation;
  vLocation: ILocation;
  vSnapshotChunks: TArray<ISnapshotChunk>;
  vHasStorageRedoLog: Boolean;
  vNewUnconfirmedBlocks: TArray<IAccountBlock>;
  vOldUnconfirmedBlocks: TArray<IAccountBlock>;
  vRealChunksToDelete: TArray<ISnapshotChunk>;
  vFirstChunk: ISnapshotChunk;
  vChunk: ISnapshotChunk;
  vCErr: string;
begin
  vReturnErr := nil;
  Self.FFlushMu.BeginRead;
  try
    try
      vTmpLocation := Self.FIndexDB.GetSnapshotBlockLocation(ParaToHeight - 1);
    except
      on E: Exception do
      begin
        vCErr := Format('c.indexDB.GetSnapshotBlockLocation failed, height is %d. Error: %s', [ParaToHeight - 1, E.Message]);
        Self.FLog.Error(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
        raise Exception.Create(vCErr);
      end;
    end;

    try
      vLocation := Self.FBlockDB.GetNextLocation(vTmpLocation);
    except
      on E: Exception do
      begin
        vCErr := Format('c.blockDB.GetNextLocation failed. Error: %s', [E.Message]);
        Self.FLog.Error(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
        raise Exception.Create(vCErr);
      end;
    end;

    if vLocation = nil then
    begin
      vCErr := Format('location is nil, toHeight is %d', [ParaToHeight]);
      Self.FLog.Error(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
      raise Exception.Create(vCErr);
    end;

    try
      vSnapshotChunks := Self.FBlockDB.PrepareRollback(vLocation);
    except
      on E: Exception do
      begin
        vCErr := Format('c.blockDB.PrepareRollback failed, location is %s. Error: %s', [vLocation.ToString, E.Message]);
        Self.FLog.Error(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
        raise Exception.Create(vCErr);
      end;
    end;

    if Length(vSnapshotChunks) <= 0 then
    begin
      Exit(nil);
    end;

    try
      vHasStorageRedoLog := Self.FStateDB.Redo.HasRedo(ParaToHeight);
    except
      on E: Exception do
      begin
        vCErr := Format('c.stateDB.Redo().HasRedo() failed, toHeight is %d. Error: %s', [ParaToHeight, E.Message]);
        Self.FLog.Error(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
        raise Exception.Create(vCErr);
      end;
    end;

    vOldUnconfirmedBlocks := Self.FCache.GetUnconfirmedBlocks;
    if Length(vOldUnconfirmedBlocks) > 0 then
    begin
      vSnapshotChunks := Concat(vSnapshotChunks, [TCreate.SnapshotChunk(vOldUnconfirmedBlocks)]);
    end;

    vRealChunksToDelete := vSnapshotChunks;

    if vHasStorageRedoLog then
    begin
      vNewUnconfirmedBlocks := vSnapshotChunks[0].AccountBlocks;
      vRealChunksToDelete := Copy(vSnapshotChunks, 1, Length(vSnapshotChunks) - 1);
      vFirstChunk := TCreate.SnapshotChunk(nil);
      vFirstChunk.SnapshotBlock := vSnapshotChunks[0].SnapshotBlock;
      vRealChunksToDelete := Concat([vFirstChunk], vRealChunksToDelete);
    end;

    for vChunk in vSnapshotChunks do
    begin
      if vChunk.SnapshotBlock <> nil then
      begin
        Self.FLog.Info(Format('delete snapshot block %d', [vChunk.SnapshotBlock.Height]));
      end;
    end;

    try
      Self.FEM.TriggerDeleteSbs(PrepareDeleteSbsEvent, vRealChunksToDelete);
    except
      on E: Exception do
      begin
        vCErr := Format('c.em.Trigger(prepareDeleteSbsEvent) failed, error is %s', [E.Message]);
        Crit(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
      end;
    end;

    try
      Self.FBlockDB.Rollback(vLocation);
    except
      on E: Exception do
      begin
        vCErr := Format('c.blockDB.Rollback(location) failed, error is %s', [E.Message]);
        Crit(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
      end;
    end;

    try
      Self.FIndexDB.RollbackSnapshotBlocks(vSnapshotChunks, vNewUnconfirmedBlocks);
    except
      on E: Exception do
      begin
        vCErr := Format('c.indexDB.RollbackSnapshotBlocks failed, error is %s', [E.Message]);
        Crit(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
      end;
    end;

    try
      Self.FCache.RollbackSnapshotBlocks(vSnapshotChunks, vNewUnconfirmedBlocks);
    except
      on E: Exception do
      begin
        vCErr := Format('c.cache.RollbackSnapshotBlocks failed, error is %s', [E.Message]);
        Crit(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
      end;
    end;

    try
      Self.FStateDB.RollbackSnapshotBlocks(vSnapshotChunks, vNewUnconfirmedBlocks);
    except
      on E: Exception do
      begin
        vCErr := Format('c.stateDB.RollbackSnapshotBlocks failed, error is %s', [E.Message]);
        Crit(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
      end;
    end;

    try
      Self.FEM.TriggerDeleteSbs(DeleteSbsEvent, vRealChunksToDelete);
    except
      on E: Exception do
      begin
        vCErr := Format('c.em.Trigger(deleteSbsEvent) failed, error is %s', [E.Message]);
        Crit(vCErr, 'method', 'deleteSnapshotBlocksToHeight');
      end;
    end;

    Result := vRealChunksToDelete;
  except
    on E: Exception do
    begin
      vReturnErr := E;
      Self.FFlusher.Abort;
      raise;
    end;
  end;
  finally
    Self.FFlushMu.EndRead;
    if vReturnErr = nil then
    begin
      Self.FFlusher.Flush;
    end;
  end;
end;

function TChainHelper.DeleteAccountBlocks(const ParaAddr: TAddress; const ParaToHash: THash): TArray<IAccountBlock>;
begin
  Result := deleteAccountBlockByHeightOrHash(ParaAddr, 0, ParaToHash);
end;

function TChainHelper.DeleteAccountBlocksToHeight(const ParaAddr: TAddress; ParaToHeight: TUInt64): TArray<IAccountBlock>;
begin
  if ParaToHeight <= 0 then
  begin
    raise Exception.Create('DeleteAccountBlocksToHeight failed, toHeight is 0');
  end;
  Result := deleteAccountBlockByHeightOrHash(ParaAddr, ParaToHeight, nil);
end;

function TChainHelper.deleteAccountBlockByHeightOrHash(const ParaAddr: TAddress; ParaToHeight: TUInt64; const ParaToHash: THash): TArray<IAccountBlock>;
var
  vUnconfirmedBlocks: TArray<IAccountBlock>;
  vCErr: string;
  vPlanDeleteBlocks: TArray<IAccountBlock>;
  vIndex: Integer;
  vUnconfirmedBlock: IAccountBlock;
  vNeedDeleteBlocks: TArray<IAccountBlock>;
begin
  vUnconfirmedBlocks := Self.FCache.GetUnconfirmedBlocks;
  if Length(vUnconfirmedBlocks) <= 0 then
  begin
    vCErr := Format('blocks is not unconfirmed, Addr is %s, toHeight is %d', [ParaAddr.ToString, ParaToHeight]);
    Self.FLog.Error(vCErr, 'method', 'deleteAccountBlockByHeightOrHash');
    raise Exception.Create(vCErr);
  end;

  SetLength(vPlanDeleteBlocks, 0);

  if ParaToHash <> nil then
  begin
    for vIndex := 0 to High(vUnconfirmedBlocks) do
    begin
      vUnconfirmedBlock := vUnconfirmedBlocks[vIndex];
      if vUnconfirmedBlock.Hash = ParaToHash then
      begin
        vPlanDeleteBlocks := Copy(vUnconfirmedBlocks, vIndex, Length(vUnconfirmedBlocks) - vIndex);
        Break;
      end;
    end;
  end
  else if ParaToHeight > 0 then
  begin
    for vIndex := 0 to High(vUnconfirmedBlocks) do
    begin
      vUnconfirmedBlock := vUnconfirmedBlocks[vIndex];
      if (vUnconfirmedBlock.AccountAddress = ParaAddr) and (vUnconfirmedBlock.Height = ParaToHeight) then
      begin
        vPlanDeleteBlocks := Copy(vUnconfirmedBlocks, vIndex, Length(vUnconfirmedBlocks) - vIndex);
        Break;
      end;
    end;
  end;

  if Length(vPlanDeleteBlocks) <= 0 then
  begin
    vCErr := Format('can''t find block %s, %d, %s', [ParaAddr.ToString, ParaToHeight, ParaToHash.ToString]);
    Self.FLog.Error(vCErr, 'method', 'deleteAccountBlockByHeightOrHash');
    raise Exception.Create(vCErr);
  end;

  vNeedDeleteBlocks := Self.ComputeDependencies(vPlanDeleteBlocks);

  try
    deleteAccountBlocks(vNeedDeleteBlocks);
  except
    on E: Exception do
    begin
      raise E;
    end;
  end;

  Result := vNeedDeleteBlocks;
end;

procedure TChainHelper.deleteAccountBlocks(const ParaBlocks: TArray<IAccountBlock>);
var
  vDebugStr: string;
  vAb: IAccountBlock;
  vSendBlock: IAccountBlock;
  vCErr: string;
begin
  Self.FFlushMu.BeginRead;
  try
    vDebugStr := 'delete by ab ';
    for vAb in ParaBlocks do
    begin
      vDebugStr := vDebugStr + Format('%s %d %s %s, ', [vAb.AccountAddress.ToString, vAb.Height, vAb.Hash.ToString, vAb.FromBlockHash.ToString]);
      for vSendBlock in vAb.SendBlockList do
      begin
        vDebugStr := vDebugStr + Format('RS %s %s, ', [vSendBlock.Hash.ToString, vSendBlock.FromBlockHash.ToString]);
      end;
    end;
    Self.FLog.Info(vDebugStr);

    try
      Self.FEM.TriggerDeleteAbs(PrepareDeleteAbsEvent, ParaBlocks);
    except
      on E: Exception do
      begin
        raise E;
      end;
    end;

    try
      Self.FIndexDB.RollbackAccountBlocks(ParaBlocks);
    except
      on E: Exception do
      begin
        vCErr := Format('c.indexDB.RollbackAccountBlocks failed. Error: %s', [E.Message]);
        Crit(vCErr, 'method', 'deleteAccountBlocks');
      end;
    end;

    try
      Self.FCache.RollbackAccountBlocks(ParaBlocks);
    except
      on E: Exception do
      begin
        vCErr := Format('c.cache.RollbackAccountBlocks failed. Error: %s', [E.Message]);
        Crit(vCErr, 'method', 'deleteAccountBlocks');
      end;
    end;

    try
      Self.FStateDB.RollbackAccountBlocks(ParaBlocks);
    except
      on E: Exception do
      begin
        vCErr := Format('c.stateDB.RollbackAccountBlocks failed. Error: %s', [E.Message]);
        Crit(vCErr, 'method', 'deleteAccountBlocks');
      end;
    end;

    try
      Self.FEM.TriggerDeleteAbs(DeleteAbsEvent, ParaBlocks);
    except
      on E: Exception do
      begin
        vCErr := Format('trigger.RollbackAccountBlocks failed. Error: %s', [E.Message]);
        Self.FLog.Error(vCErr);
      end;
    end;
  finally
    Self.FFlushMu.EndRead;
  end;
end;

end.
