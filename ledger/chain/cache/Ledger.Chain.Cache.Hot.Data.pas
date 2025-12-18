unit Ledger.Chain.Cache.HotData;

interface

uses
  Ledger.Chain.Cache.Account.Block,
  Ledger.Chain.Cache.Cache,
  Ledger.Chain.Cache.Dataset,
  Ledger.Chain.Cache.Init,
  Ledger.Chain.Cache.Interface,
  Ledger.Chain.Cache.Quota,
  Ledger.Chain.Cache.Quota.List,
  Ledger.Chain.Cache.Snapshot.Block,
  Ledger.Chain.Cache.Unconfirmed,
  Ledger.Chain.Cache.Unconfirmed.Pool,
  System.SysUtils System.Classes System.Generics.Collections,
  Vite.Common.Types Interfaces.Core Ledger.Chain.Cache.DataSet;

type
  THotData = class
  private
    mDs: TDataSet;
    mLatestSnapshotBlock: TSnapshotBlock;
    mLatestAccountBlocks: TDictionary<TAddress, TBytes>;
  public
    constructor Create(ParaDs: TDataSet);
    destructor Destroy; override;
    procedure SetLatestSnapshotBlock(ParaSnapshotBlock: TSnapshotBlock);
    function GetLatestSnapshotBlock: TSnapshotBlock;
    procedure InsertAccountBlock(ParaBlock: TAccountBlock);
    procedure DeleteAccountBlocks(ParaBlocks: TArray<TAccountBlock>);
    function GetLatestAccountBlock(ParaAddr: TAddress): TAccountBlock;
  end;

implementation

{ THotData }

constructor THotData.Create(ParaDs: TDataSet);
begin
  inherited Create;
  mDs := ParaDs;
  mLatestAccountBlocks := TDictionary<TAddress, TBytes>.Create;
end;

destructor THotData.Destroy;
begin
  mLatestAccountBlocks.Free;
  inherited Destroy;
end;

procedure THotData.SetLatestSnapshotBlock(ParaSnapshotBlock: TSnapshotBlock);
begin
  mLatestSnapshotBlock := ParaSnapshotBlock;
end;

function THotData.GetLatestSnapshotBlock: TSnapshotBlock;
begin
  Result := mLatestSnapshotBlock;
end;

procedure THotData.InsertAccountBlock(ParaBlock: TAccountBlock);
begin
  mLatestAccountBlocks.AddOrSetValue(ParaBlock.AccountAddress, ParaBlock.Hash);
end;

procedure THotData.DeleteAccountBlocks(ParaBlocks: TArray<TAccountBlock>);
var
  vBlock: TAccountBlock;
begin
  for vBlock in ParaBlocks do
  begin
    mLatestAccountBlocks.Remove(vBlock.AccountAddress);
  end;
end;

function THotData.GetLatestAccountBlock(ParaAddr: TAddress): TAccountBlock;
var
  vHash: TBytes;
begin
  if mLatestAccountBlocks.TryGetValue(ParaAddr, vHash) then
  begin
    Result := mDs.GetAccountBlock(vHash);
  end
  else
  begin
    Result := nil;
  end;
end;

end.
