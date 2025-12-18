unit Ledger.Chain.Genesis.SnapshotBlock;

interface

uses
  Interfaces,
  Interfaces.Core,
  Ledger.Chain.Genesis.Account.Block,
  Ledger.Chain.Genesis.Check.Sum,
  Ledger.Chain.Genesis.Genesis,
  Ledger.Chain.Genesis.Interface,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Time;

function NewGenesisSnapshotContent(ParaAccountBlocks: TArray<IVmAccountBlock>): ISnapshotContent;
function NewGenesisSnapshotBlock(ParaAccountBlocks: TArray<IVmAccountBlock>): ISnapshotBlock;

implementation

function NewGenesisSnapshotContent(ParaAccountBlocks: TArray<IVmAccountBlock>): ISnapshotContent;
var
  vSc: ISnapshotContent;
  vVmBlock: IVmAccountBlock;
  vAccountBlock: IAccountBlock;
  vHashHeight: IHashHeight;
begin
  vSc := TSnapshotContent.Create;
  for vVmBlock in ParaAccountBlocks do
  begin
    vAccountBlock := vVmBlock.AccountBlock;
    if (not vSc.ContainsKey(vAccountBlock.AccountAddress)) or (vSc[vAccountBlock.AccountAddress].Height < vAccountBlock.Height) then
    begin
      vHashHeight := THashHeight.Create;
      vHashHeight.Height := vAccountBlock.Height;
      vHashHeight.Hash := vAccountBlock.Hash;
      vSc.AddOrSetValue(vAccountBlock.AccountAddress, vHashHeight);
    end;
  end;
  Result := vSc;
end;

function NewGenesisSnapshotBlock(ParaAccountBlocks: TArray<IVmAccountBlock>): ISnapshotBlock;
var
  vGenesisTimestamp: TDateTime;
  vGenesisSnapshotBlock: ISnapshotBlock;
begin
  // 2019/05/21 12:00:00 UTC/GMT +8
  vGenesisTimestamp := TTime.UnixToDateTime(1558411200);

  vGenesisSnapshotBlock := TSnapshotBlock.Create;
  vGenesisSnapshotBlock.Height := 1;
  vGenesisSnapshotBlock.Timestamp := vGenesisTimestamp;
  vGenesisSnapshotBlock.SnapshotContent := NewGenesisSnapshotContent(ParaAccountBlocks);

  vGenesisSnapshotBlock.Hash := vGenesisSnapshotBlock.ComputeHash;

  Result := vGenesisSnapshotBlock;
end;

end.
