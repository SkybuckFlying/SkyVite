unit Ledger.Chain.Insert;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  V2.Interfaces,
  V2.Interfaces.Core,
  V2.Common,
  V2.Ledger.Chain.Chain;

type
  TChainHelper = class helper for TChain
  public
    function InsertAccountBlock(ParaVmAccountBlock: IVmAccountBlock): string;
    function InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock): TArray<IAccountBlock>;
  private
    function getBlocksToBeConfirmed(const ParaSc: ISnapshotContent): TArray<IAccountBlock>;
    function insertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock): string;
    function sPrintError(const ParaSc: ISnapshotContent; const ParaBlocks: TArray<IAccountBlock>): string;
  end;

implementation

uses
  System.Threading,
  V2.Ledger.Chain.Events;

{ TChainHelper }

function TChainHelper.InsertAccountBlock(ParaVmAccountBlock: IVmAccountBlock): string;
var
  vVmAbList: TArray<IVmAccountBlock>;
  vAccountBlock: IAccountBlock;
  vCErr: string;
begin
  Result := '';
  Self.FFlushMu.BeginRead;
  try
    Self.FLog.Info(Format('insert account block %s %d %s %s', [ParaVmAccountBlock.AccountBlock.AccountAddress.ToString, ParaVmAccountBlock.AccountBlock.Height, ParaVmAccountBlock.AccountBlock.Hash.ToString, ParaVmAccountBlock.AccountBlock.FromBlockHash.ToString]));

    SetLength(vVmAbList, 1);
    vVmAbList[0] := ParaVmAccountBlock;
    Result := Self.FEM.TriggerInsertAbs(prepareInsertAbsEvent, vVmAbList);
    if Result <> '' then
    begin
      Exit;
    end;

    vAccountBlock := ParaVmAccountBlock.AccountBlock;
    Self.FCache.InsertAccountBlock(vAccountBlock);

    try
      Self.FIndexDB.InsertAccountBlock(vAccountBlock);
    except
      on E: Exception do
      begin
        vCErr := Format('c.indexDB.InsertAccountBlockAndSnapshot failed, error is %s, blockHash is %s', [E.Message, vAccountBlock.Hash.ToString]);
        Crit(vCErr, 'method', 'InsertAccountBlockAndSnapshot');
      end;
    end;

    try
      Self.FStateDB.Write(ParaVmAccountBlock);
    except
      on E: Exception do
      begin
        vCErr := Format('c.stateDB.WriteAccountBlock failed, error is %s, blockHash is %s', [E.Message, vAccountBlock.Hash.ToString]);
        Crit(vCErr, 'method', 'InsertAccountBlockAndSnapshot');
      end;
    end;

    Result := Self.FEM.TriggerInsertAbs(insertAbsEvent, vVmAbList);
    if Result <> '' then
    begin
      vCErr := Format('trigger InsertAccountBlock failed, error is %s, blockHash is %s', [Result, vAccountBlock.Hash.ToString]);
      Self.FLog.Error(vCErr);
    end;
  finally
    Self.FFlushMu.EndRead;
  end;
end;

function TChainHelper.InsertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock): TArray<IAccountBlock>;
var
  vInvalidBlocks: TArray<IAccountBlock>;
  vErr: string;
begin
  Self.FLog.Info(Format('insert snapshot block %s %d', [ParaSnapshotBlock.Hash.ToString, ParaSnapshotBlock.Height]));
  vErr := Self.insertSnapshotBlock(ParaSnapshotBlock);
  if vErr <> '' then
  begin
    raise Exception.Create(vErr);
  end;

  vInvalidBlocks := Self.FilterUnconfirmedBlocks(ParaSnapshotBlock, True);

  if Length(vInvalidBlocks) > 0 then
  begin
    Self.DeleteAccountBlocks(vInvalidBlocks);
  end;

  Self.FCache.ResetUnconfirmedQuotas(Self.GetAllUnconfirmedBlocks);

  Result := vInvalidBlocks;
end;

function TChainHelper.getBlocksToBeConfirmed(const ParaSc: ISnapshotContent): TArray<IAccountBlock>;
var
  vScLen: Integer;
  vBlocks: TArray<IAccountBlock>;
  vFinishCount: Integer;
  vBlocksToBeConfirmed: TArray<IAccountBlock>;
  vBlock: IAccountBlock;
  vHashHeight: IHashHeight;
begin
  vScLen := ParaSc.Count;
  if vScLen <= 0 then
  begin
    Exit(nil);
  end;

  vBlocks := Self.FCache.GetUnconfirmedBlocks;
  vFinishCount := 0;
  SetLength(vBlocksToBeConfirmed, 0);
  for vBlock in vBlocks do
  begin
    if ParaSc.TryGetValue(vBlock.AccountAddress, vHashHeight) then
    begin
      if vBlock.Height < vHashHeight.Height then
      begin
        vBlocksToBeConfirmed := Concat(vBlocksToBeConfirmed, [vBlock])
      end
      else if vBlock.Height = vHashHeight.Height then
      begin
        vBlocksToBeConfirmed := Concat(vBlocksToBeConfirmed, [vBlock]);
        Inc(vFinishCount);
      end;
    end;
    if vFinishCount >= vScLen then
    begin
      Exit(vBlocksToBeConfirmed);
    end;
  end;

  raise Exception.Create(Format('lack block, sc is %s', [sPrintError(ParaSc, vBlocks)]));
end;

function TChainHelper.insertSnapshotBlock(ParaSnapshotBlock: ISnapshotBlock): string;
var
  vCanBeSnappedBlocks: TArray<IAccountBlock>;
  vChunks: TArray<ISnapshotChunk>;
  vAbLocationMap: TDictionary<THash, ILocation>;
  vSnapshotBlockLocation: ILocation;
  vCErr: string;
  vWg: TCountdownEvent;
begin
  Result := '';
  Self.FFlushMu.BeginRead;
  try
    try
      vCanBeSnappedBlocks := getBlocksToBeConfirmed(ParaSnapshotBlock.SnapshotContent);
    except
      on E: Exception do
      begin
        Result := E.Message;
        Exit;
      end;
    end;

    SetLength(vChunks, 1);
    vChunks[0] := TSnapshotChunk.Create(ParaSnapshotBlock, vCanBeSnappedBlocks);

    Result := Self.FEM.TriggerInsertSbs(prepareInsertSbsEvent, vChunks);
    if Result <> '' then
    begin
      Exit;
    end;

    try
      Self.FBlockDB.Write(vChunks[0], vAbLocationMap, vSnapshotBlockLocation);
    except
      on E: Exception do
      begin
        vCErr := Format('c.blockDB.WriteAccountBlock failed, snapshotBlock is %s. Error: %s', [ParaSnapshotBlock.ToString, E.Message]);
        Crit(vCErr, 'method', 'InsertSnapshotBlock');
      end;
    end;

    vWg := TCountdownEvent.Create(2);
    TTask.Run(procedure
    begin
      try
        Self.FIndexDB.InsertSnapshotBlock(ParaSnapshotBlock, vCanBeSnappedBlocks, vSnapshotBlockLocation, vAbLocationMap);
        Self.FCache.InsertSnapshotBlock(ParaSnapshotBlock, vCanBeSnappedBlocks);
      finally
        vWg.Signal;
      end;
    end);
    TTask.Run(procedure
    begin
      try
        Self.FStateDB.InsertSnapshotBlock(ParaSnapshotBlock, vCanBeSnappedBlocks);
      finally
        vWg.Signal;
      end;
    end);
    vWg.Wait;

    Self.FEM.TriggerInsertSbs(InsertSbsEvent, vChunks);
  finally
    if ExceptObject <> nil then
    begin
      Self.FFlusher.Abort;
      Self.FFlushMu.EndRead;
      raise;
    end;
    Self.FFlushMu.EndRead;
  end;
end;

function TChainHelper.sPrintError(const ParaSc: ISnapshotContent; const ParaBlocks: TArray<IAccountBlock>): string;
var
  vAddr: TAddress;
  vHashHeight: IHashHeight;
  vBlock: IAccountBlock;
begin
  Result := 'SnapshotContent: ';
  for vAddr in ParaSc.Keys do
  begin
    vHashHeight := ParaSc[vAddr];
    Result := Result + vAddr.ToString + ' ' + vHashHeight.Hash.ToString + ' ' + IntToStr(vHashHeight.Height) + ', ';
  end;

  Result := Result + '| Blocks: ';
  for vBlock in ParaBlocks do
  begin
    Result := Result + Format('%s, ', [vBlock.ToString]);
  end;
end;

end.