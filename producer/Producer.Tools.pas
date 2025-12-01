unit Producer.Tools;

interface

uses
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  Common.Types,
  Common.Upgrade,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain,
  Ledger.Consensus,
  Ledger.Pool,
  Log15,
  Monitor;

type
  TTools = class
  private
    mLog: ILogger;
    mPool: ISnapshotProducerWriter;
    mChain: IChain;
    function GetLastSeedBlock(const ParaE: TConsensusEvent; const ParaHead: ISnapshotBlock; const ParaBeforeTime: TDateTime): ISnapshotBlock;
    function GenerateAccounts(const ParaHead: ISnapshotBlock): ISnapshotContent;
  public
    constructor Create(const ParaCh: IChain; const ParaP: ISnapshotProducerWriter);
    function GenerateSnapshot(const ParaE: TConsensusEvent; const ParaCoinbase: IAccount; const ParaSeed: UInt64; const ParaFn: TFunc<THash, UInt64>): ISnapshotBlock;
    function InsertSnapshot(const ParaBlock: ISnapshotBlock): Boolean;
    function CheckStableSnapshotChain(const ParaHeader: ISnapshotBlock): Boolean;
  end;

function NewChainRw(const ParaCh: IChain; const ParaP: ISnapshotProducerWriter): TTools;

implementation

{ TTools }

constructor TTools.Create(const ParaCh: IChain; const ParaP: ISnapshotProducerWriter);
begin
  mLog := TLog15.New(['module', 'tools']);
  mChain := ParaCh;
  mPool := ParaP;
end;

function TTools.GenerateSnapshot(const ParaE: TConsensusEvent; const ParaCoinbase: IAccount; const ParaSeed: UInt64; const ParaFn: TFunc<THash, UInt64>): ISnapshotBlock;
var
  vHead: ISnapshotBlock;
  vAccounts: ISnapshotContent;
  vBlock: ISnapshotBlock;
  vLastBlock: ISnapshotBlock;
  vLastSeed: UInt64;
  vSeedHash: THash;
  vSignedData, vPubKey: TBytes;
begin
  vHead := mChain.GetLatestSnapshotBlock;
  vAccounts := GenerateAccounts(vHead);

  vBlock := TSnapshotBlock.Create;
  vBlock.PrevHash := vHead.Hash;
  vBlock.Height := vHead.Height + 1;
  vBlock.Timestamp := ParaE.Timestamp;
  vBlock.SnapshotContent := vAccounts;

  vLastBlock := GetLastSeedBlock(ParaE, vHead, ParaE.PeriodStime);
  if vLastBlock <> nil then
  begin
    if vLastBlock.Timestamp < ParaE.PeriodStime then
    begin
      vLastSeed := ParaFn(vLastBlock.SeedHash);
      vSeedHash := TSnapshotBlock.ComputeSeedHash(ParaSeed, vBlock.PrevHash, vBlock.Timestamp);
      vBlock.SeedHash := vSeedHash;
      vBlock.Seed := vLastSeed;
    end;
  end
  else
  begin
    vSeedHash := TSnapshotBlock.ComputeSeedHash(ParaSeed, vBlock.PrevHash, vBlock.Timestamp);
    vBlock.SeedHash := vSeedHash;
    vBlock.Seed := 0;
  end;

  if TUpgrade.IsLeafUpgrade(vBlock.Height) then
  begin
    vBlock.Version := TUpgrade.GetLatestPoint.Version;
  end;

  vBlock.Hash := vBlock.ComputeHash;

  if not ParaCoinbase.Sign(vBlock.Hash.Bytes, vSignedData, vPubKey) then
  begin
    Result := nil;
    Exit;
  end;
  vBlock.Signature := vSignedData;
  vBlock.PublicKey := vPubKey;
  Result := vBlock;
end;

function TTools.InsertSnapshot(const ParaBlock: ISnapshotBlock): Boolean;
var
  vTime: TDateTime;
begin
  vTime := Now;
  try
    mLog.Info('insert snapshot block.', ['block', ParaBlock.ToString, 'producer', ParaBlock.Producer.ToString]);
    Result := mPool.AddDirectSnapshotBlock(ParaBlock);
  finally
    TMonitor.LogTime('producer', 'snapshotInsert', vTime);
  end;
end;

function TTools.GenerateAccounts(const ParaHead: ISnapshotBlock): ISnapshotContent;
begin
  Result := mChain.GetContentNeedSnapshot;
end;

function TTools.GetLastSeedBlock(const ParaE: TConsensusEvent; const ParaHead: ISnapshotBlock; const ParaBeforeTime: TDateTime): ISnapshotBlock;
var
  vBlock: ISnapshotBlock;
  vLatest: ISnapshotBlock;
begin
  vBlock := mChain.GetLastUnpublishedSeedSnapshotHeader(ParaE.Address, ParaBeforeTime);
  if vBlock = nil then
  begin
    Result := nil;
    Exit;
  end;
  vLatest := mChain.GetLatestSnapshotBlock;
  if vLatest.Hash <> ParaHead.Hash then
  begin
    Result := nil;
    Exit;
  end;
  Result := vBlock;
end;

function TTools.CheckStableSnapshotChain(const ParaHeader: ISnapshotBlock): Boolean;
var
  vTargetH: UInt64;
  vBlock: ISnapshotBlock;
  vTime: TDateTime;
begin
  Result := False;
  if ParaHeader.Height <= Minute then
  begin
    Result := True;
    Exit;
  end;
  vTargetH := ParaHeader.Height - Minute;

  vBlock := mChain.GetSnapshotHeaderByHeight(vTargetH);
  if vBlock = nil then
  begin
    raise Exception.CreateFmt('empty snapshot block[%d]', [vTargetH]);
  end;

  vTime := Now - EncodeTime(0, 1, 20, 0);
  if vBlock.Timestamp < vTime then
  begin
    raise Exception.CreateFmt('snapshot is not stable[%s],[%s]', [DateTimeToStr(vTime), DateTimeToStr(vBlock.Timestamp)]);
  end;
  Result := True;
end;

function NewChainRw(const ParaCh: IChain; const ParaP: ISnapshotProducerWriter): TTools;
begin
  Result := TTools.Create(ParaCh, ParaP);
end;

end.
