unit utils;

interface

uses
  Ledger.Generator.Generator,
  Ledger.Generator.Incoming.Message,
  Ledger.Generator.Utils.Test,
  System.SysUtils System.Classes,
  Vite.Common Vite.Ledger Vite.Interfaces big_int;

type
  TEnvPrepareForGenerator = record
    LatestSnapshotHash: PHash;
    LatestSnapshotHeight: UInt64;
    LatestAccountHash: PHash;
    LatestAccountHeight: UInt64;
  end;

  IStateChain = interface
    ['{B4F5B0C1-5B1A-4A7E-A4E6-3A2D2B6405D4}']
    function GetLatestSnapshotBlock: TSnapshotBlock;
    function GetLatestAccountBlock(addr: TAddress): TAccountBlock;
  end;

function GetAddressStateForGenerator(chain: IStateChain; addr: PAddress): TEnvPrepareForGenerator;

type
  TVMGlobalStatus = class
  private
    FC: TChain;
    FSb: TSnapshotBlock;
    FFromHash: THash;
    FSeed: UInt64;
    FSetSeed: Boolean;
    FRandSource: TSource64;
    FSetRandSeed: Boolean;
  public
    constructor Create(c: TChain; sb: TSnapshotBlock; fromHash: THash);
    function Seed: UInt64;
    function Random: UInt64;
    function SnapshotBlock: TSnapshotBlock;
  end;

implementation

function GetAddressStateForGenerator(chain: IStateChain; addr: PAddress): TEnvPrepareForGenerator;
var
  latestSnapshot: TSnapshotBlock;
  prevAccHash: THash;
  prevAccHeight: UInt64;
  prevAccountBlock: TAccountBlock;
begin
  latestSnapshot := chain.GetLatestSnapshotBlock;
  if latestSnapshot = nil then
    raise Exception.Create('ErrGetLatestSnapshotBlock');

  prevAccountBlock := chain.GetLatestAccountBlock(addr^);
  if prevAccountBlock <> nil then
  begin
    prevAccHash := prevAccountBlock.Hash;
    prevAccHeight := prevAccountBlock.Height;
  end
  else
  begin
    prevAccHash := THash.Create;
    prevAccHeight := 0;
  end;

  Result.LatestSnapshotHash := @latestSnapshot.Hash;
  Result.LatestSnapshotHeight := latestSnapshot.Height;
  Result.LatestAccountHash := @prevAccHash;
  Result.LatestAccountHeight := prevAccHeight;
end;

{ TVMGlobalStatus }

constructor TVMGlobalStatus.Create(c: TChain; sb: TSnapshotBlock; fromHash: THash);
begin
  FC := c;
  FSb := sb;
  FFromHash := fromHash;
  FSetSeed := False;
end;

function TVMGlobalStatus.Random: UInt64;
var
  s: UInt64;
begin
  if FSetRandSeed then
  begin
    Result := FRandSource.Uint64;
    Exit;
  end;
  s := FC.GetSeed(FSb, FFromHash);
  FRandSource := TSource64.Create(s);
  FSetRandSeed := True;
  Result := FRandSource.Uint64;
end;

function TVMGlobalStatus.Seed: UInt64;
var
  s: UInt64;
begin
  if FSetSeed then
  begin
    Result := FSeed;
    Exit;
  end;
  s := FC.GetSeed(FSb, FFromHash);
  FSeed := s;
  FSetSeed := True;
  Result := s;
end;

function TVMGlobalStatus.SnapshotBlock: TSnapshotBlock;
begin
  Result := FSb;
end;

end.
