unit Ledger.Chain.Genesis.Genesis;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.Genesis.CheckSum;

const
  LedgerUnknown = Byte(0);
  LedgerEmpty = Byte(1);
  LedgerValid = Byte(2);
  LedgerInvalid = Byte(3);

function InitLedger(ParaChain: IChain; ParaGenesisSnapshotBlock: ISnapshotBlock; ParaVmBlocks: TArray<IVmAccountBlock>): Exception;
function CheckLedger(ParaChain: IChain; ParaGenesisSnapshotBlock: ISnapshotBlock; ParaGenesisAccountBlocks: TArray<IVmAccountBlock>; out OutStatus: Byte): Exception;
function VmBlocksToHashMap(ParaAccountBlocks: TArray<IVmAccountBlock>): TDictionary<THash, Boolean>;

implementation

{ TGenesis }

function InitLedger(ParaChain: IChain; ParaGenesisSnapshotBlock: ISnapshotBlock; ParaVmBlocks: TArray<IVmAccountBlock>): Exception;
var
  vAb: IVmAccountBlock;
  vErr: Exception;
  vSumHash: THash;
begin
  Result := nil;
  try
    // insert genesis account blocks
    for vAb in ParaVmBlocks do
    begin
      vErr := ParaChain.InsertAccountBlock(vAb);
      if vErr <> nil then
      begin
        raise vErr;
      end;
    end;

    // insert genesis snapshot block
    ParaChain.InsertSnapshotBlock(ParaGenesisSnapshotBlock);

    vSumHash := CheckSum(ParaVmBlocks);
    Result := ParaChain.WriteGenesisCheckSum(vSumHash);
  except
    on E: Exception do
    begin
      Result := E;
    end;
  end;
end;

function CheckLedger(ParaChain: IChain; ParaGenesisSnapshotBlock: ISnapshotBlock; ParaGenesisAccountBlocks: TArray<IVmAccountBlock>; out OutStatus: Byte): Exception;
var
  vFirstSb: ISnapshotBlock;
  vErr: Exception;
  vSumHash: THash;
  vQuerySumHash: PHash;
begin
  Result := nil;
  OutStatus := LedgerUnknown;
  try
    vFirstSb := ParaChain.QuerySnapshotBlockByHeight(1);
    if vErr <> nil then
    begin
      Result := vErr;
      Exit;
    end;

    if vFirstSb = nil then
    begin
      OutStatus := LedgerEmpty;
      Exit;
    end;

    if vFirstSb.Hash <> ParaGenesisSnapshotBlock.Hash then
    begin
      OutStatus := LedgerInvalid;
      Exit;
    end;

    vSumHash := CheckSum(ParaGenesisAccountBlocks);

    vQuerySumHash := ParaChain.QueryGenesisCheckSum;
    if vErr <> nil then
    begin
      Result := vErr;
      Exit;
    end;

    if vQuerySumHash = nil then
    begin
      vErr := ParaChain.WriteGenesisCheckSum(vSumHash);
      if vErr <> nil then
      begin
        Result := vErr;
        Exit;
      end;
    end
    else if vSumHash <> vQuerySumHash^ then
    begin
      OutStatus := LedgerInvalid;
      Exit;
    end;

    OutStatus := LedgerValid;
  except
    on E: Exception do
    begin
      Result := E;
    end;
  end;
end;

function VmBlocksToHashMap(ParaAccountBlocks: TArray<IVmAccountBlock>): TDictionary<THash, Boolean>;
var
  vHashMap: TDictionary<THash, Boolean>;
  vAccountBlock: IVmAccountBlock;
begin
  vHashMap := TDictionary<THash, Boolean>.Create;
  for vAccountBlock in ParaAccountBlocks do
  begin
    vHashMap.Add(vAccountBlock.AccountBlock.Hash, True);
  end;
  Result := vHashMap;
end;

end.
