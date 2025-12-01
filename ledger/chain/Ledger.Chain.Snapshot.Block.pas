unit V2.Ledger.Chain.SnapshotBlock;

interface

uses
  System.SysUtils, Classes, V2.Interfaces.Core, V2.Ledger.Chain.FileManager, V2.Common.Types, System.DateUtils;

type
  TChainSnapshotBlockHelper = class helper for TChain
  public
    function IsGenesisSnapshotBlock(const AHash: THash): Boolean;
    function IsSnapshotBlockExisted(const AHash: THash): Boolean;
    function GetGenesisSnapshotBlock: ISnapshotBlock;
    function GetLatestSnapshotBlock: ISnapshotBlock;
    function GetSnapshotHeightByHash(const AHash: THash): TUInt64;
    function GetSnapshotHashByHeight(AHeight: TUInt64): THash;
    function GetSnapshotHeaderByHeight(AHeight: TUInt64): ISnapshotBlock;
    function GetSnapshotBlockByHeight(AHeight: TUInt64): ISnapshotBlock;
    function GetSnapshotHeaderByHash(const AHash: THash): ISnapshotBlock;
    function GetSnapshotBlockByHash(const AHash: THash): ISnapshotBlock;
    function GetRangeSnapshotHeaders(const AStartHash, AEndHash: THash): TArray<ISnapshotBlock>;
    function GetRangeSnapshotBlocks(const AStartHash, AEndHash: THash): TArray<ISnapshotBlock>;
    function GetSnapshotHeaders(const ABlockHash: THash; AHigher: Boolean; ACount: TUInt64): TArray<ISnapshotBlock>;
    function GetSnapshotBlocks(const ABlockHash: THash; AHigher: Boolean; ACount: TUInt64): TArray<ISnapshotBlock>;
    function GetSnapshotHeadersByHeight(AHeight: TUInt64; AHigher: Boolean; ACount: TUInt64): TArray<ISnapshotBlock>;
    function GetSnapshotBlocksByHeight(AHeight: TUInt64; AHigher: Boolean; ACount: TUInt64): TArray<ISnapshotBlock>;
    function GetConfirmSnapshotHeaderByAbHash(const AAbHash: THash): ISnapshotBlock;
    function GetConfirmSnapshotBlockByAbHash(const AAbHash: THash): ISnapshotBlock;
    function GetSnapshotHeaderBeforeTime(const ATimestamp: TDateTime): ISnapshotBlock;
    function GetSnapshotHeadersAfterOrEqualTime(const AEndHashHeight: IHashHeight; const AStartTime: TDateTime; const AProducer: TAddress): TArray<ISnapshotBlock>;
    function QuerySnapshotBlockByHeight(AHeight: TUInt64): ISnapshotBlock;
    function QueryLatestSnapshotBlock: ISnapshotBlock;
    function GetRandomSeed(const ASnapshotHash: THash; AN: Integer): TUInt64;
    function GetSnapshotBlockByContractMeta(const AAddr: TAddress; const AFromHash: THash): ISnapshotBlock;
    function GetSeedConfirmedSnapshotBlock(const AAddr: TAddress; const AFromHash: THash): ISnapshotBlock;
    function GetSeed(const ALimitSb: ISnapshotBlock; const AFromHash: THash): TUInt64;
    function GetLastUnpublishedSeedSnapshotHeader(const AProducer: TAddress; const ABeforeTime: TDateTime): ISnapshotBlock;
    function GetSubLedger(AStartHeight, AEndHeight: TUInt64): TArray<ISnapshotChunk>;
    function GetSubLedgerAfterHeight(AHeight: TUInt64): TArray<ISnapshotChunk>;
  private
    function GetSnapshotBlockList(AGetList: TFunc<TArray<ILocation>, TArray<TUInt64>>; AHigher, AOnlyHeader: Boolean): TArray<ISnapshotBlock>;
    function BinarySearchBeforeTime(AStart, AEnd: ISnapshotBlock; ATimeNanosecond: Int64): ISnapshotBlock;
  end;

implementation

{ TChainSnapshotBlockHelper }

function TChainSnapshotBlockHelper.IsGenesisSnapshotBlock(const AHash: THash): Boolean;
begin
  Result := Self.FGenesisSnapshotBlock.Hash = AHash;
end;

function TChainSnapshotBlockHelper.IsSnapshotBlockExisted(const AHash: THash): Boolean;
begin
  if Self.FCache.IsSnapshotBlockExisted(AHash) then
    Exit(True);
  try
    Result := Self.FIndexDB.IsSnapshotBlockExisted(AHash);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.IsSnapshotBlockExisted failed, error is %s, hash is %s', [E.Message, AHash.ToString]), 'method', 'IsSnapshotBlockExisted');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetGenesisSnapshotBlock: ISnapshotBlock;
begin
  Result := Self.FGenesisSnapshotBlock;
end;

function TChainSnapshotBlockHelper.GetLatestSnapshotBlock: ISnapshotBlock;
begin
  Result := Self.FCache.GetLatestSnapshotBlock;
end;

function TChainSnapshotBlockHelper.GetSnapshotHeightByHash(const AHash: THash): TUInt64;
var
  LHeader: ISnapshotBlock;
begin
  LHeader := Self.FCache.GetSnapshotHeaderByHash(AHash);
  if LHeader <> nil then
    Exit(LHeader.Height);
  try
    Result := Self.FIndexDB.GetSnapshotBlockHeight(AHash);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetSnapshotBlockHeight failed,  hash is %s. Error: %s', [AHash.ToString, E.Message]), 'method', 'GetSnapshotHeightByHash');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotHashByHeight(AHeight: TUInt64): THash;
var
  LHeader: ISnapshotBlock;
begin
  LHeader := Self.FCache.GetSnapshotHeaderByHeight(AHeight);
  if LHeader <> nil then
    Exit(LHeader.Hash);
  try
    Result := Self.FIndexDB.GetSnapshotBlockByHeight(AHeight);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetSnapshotBlockByHeight failed,  height is %d. Error: %s', [AHeight, E.Message]), 'method', 'GetSnapshotBlockByHeight');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotHeaderByHeight(AHeight: TUInt64): ISnapshotBlock;
var
  LLocation: ILocation;
begin
  Result := Self.FCache.GetSnapshotHeaderByHeight(AHeight);
  if Result <> nil then
    Exit;
  try
    LLocation := Self.FIndexDB.GetSnapshotBlockLocation(AHeight);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetSnapshotBlockLocation failed,  height is %d. Error: %s', [AHeight, E.Message]), 'method', 'GetSnapshotHeaderByHeight');
      raise;
    end;
  end;
  if LLocation = nil then
    Exit(nil);
  try
    Result := Self.FBlockDB.GetSnapshotHeader(LLocation);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.blockDB.GetSnapshotHeader failed, error is %s, height is %d, location is %s', [E.Message, AHeight, LLocation.ToString]), 'method', 'GetSnapshotHeaderByHeight');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotBlockByHeight(AHeight: TUInt64): ISnapshotBlock;
begin
  Result := Self.FCache.GetSnapshotBlockByHeight(AHeight);
  if Result <> nil then
    Exit;
  Result := Self.QuerySnapshotBlockByHeight(AHeight);
end;

function TChainSnapshotBlockHelper.GetSnapshotHeaderByHash(const AHash: THash): ISnapshotBlock;
var
  LLocation: ILocation;
begin
  Result := Self.FCache.GetSnapshotHeaderByHash(AHash);
  if Result <> nil then
    Exit;
  try
    LLocation := Self.FIndexDB.GetSnapshotBlockLocationByHash(AHash);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetSnapshotBlockLocationByHash failed, error is %s, hash is %s', [E.Message, AHash.ToString]), 'method', 'GetSnapshotHeaderByHash');
      raise;
    end;
  end;
  if LLocation = nil then
    Exit(nil);
  try
    Result := Self.FBlockDB.GetSnapshotHeader(LLocation);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.blockDB.GetSnapshotHeader failed, error is %s, hash is %s, location is %s', [E.Message, AHash.ToString, LLocation.ToString]), 'method', 'GetSnapshotHeaderByHash');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotBlockByHash(const AHash: THash): ISnapshotBlock;
var
  LLocation: ILocation;
begin
  Result := Self.FCache.GetSnapshotBlockByHash(AHash);
  if Result <> nil then
    Exit;
  try
    LLocation := Self.FIndexDB.GetSnapshotBlockLocationByHash(AHash);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetSnapshotBlockLocation failed, error is %s, hash is %s', [E.Message, AHash.ToString]), 'method', 'GetSnapshotBlockByHash');
      raise;
    end;
  end;
  if LLocation = nil then
    Exit(nil);
  try
    Result := Self.FBlockDB.GetSnapshotBlock(LLocation);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.blockDB.GetSnapshotBlock failed, error is %s, hash is %s, location is %s', [E.Message, AHash.ToString, LLocation.ToString]), 'method', 'GetSnapshotBlockByHash');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetRangeSnapshotHeaders(const AStartHash, AEndHash: THash): TArray<ISnapshotBlock>;
begin
  try
    Result := Self.GetSnapshotBlockList(function: TArray<ILocation>
    var
      LHeightRange: TArray<TUInt64>;
    begin
      Result := Self.FIndexDB.GetRangeSnapshotBlockLocations(AStartHash, AEndHash, LHeightRange);
    end, True, True);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.getSnapshotBlockList failed, error is %s, startHash is %s, endHash is %s', [E.Message, AStartHash.ToString, AEndHash.ToString]), 'method', 'GetRangeSnapshotHeaders');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetRangeSnapshotBlocks(const AStartHash, AEndHash: THash): TArray<ISnapshotBlock>;
begin
  try
    Result := Self.GetSnapshotBlockList(function: TArray<ILocation>
    var
      LHeightRange: TArray<TUInt64>;
    begin
      Result := Self.FIndexDB.GetRangeSnapshotBlockLocations(AStartHash, AEndHash, LHeightRange);
    end, True, False);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.getSnapshotBlockList failed, error is %s, startHash is %s, endHash is %s', [E.Message, AStartHash.ToString, AEndHash.ToString]), 'method', 'GetRangeSnapshotBlocks');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotHeaders(const ABlockHash: THash; AHigher: Boolean; ACount: TUInt64): TArray<ISnapshotBlock>;
begin
  try
    Result := Self.GetSnapshotBlockList(function: TArray<ILocation>
    var
      LHeightRange: TArray<TUInt64>;
    begin
      Result := Self.FIndexDB.GetSnapshotBlockLocationList(ABlockHash, AHigher, ACount, LHeightRange);
    end, AHigher, True);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.getSnapshotBlockList failed, error is %s, blockHash is %s, higher is %s, count is %d', [E.Message, ABlockHash.ToString, BoolToStr(AHigher), ACount]), 'method', 'GetSnapshotHeaders');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotBlocks(const ABlockHash: THash; AHigher: Boolean; ACount: TUInt64): TArray<ISnapshotBlock>;
begin
  try
    Result := Self.GetSnapshotBlockList(function: TArray<ILocation>
    var
      LHeightRange: TArray<TUInt64>;
    begin
      Result := Self.FIndexDB.GetSnapshotBlockLocationList(ABlockHash, AHigher, ACount, LHeightRange);
    end, AHigher, False);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.getSnapshotBlockList failed, error is %s, blockHash is %s, higher is %s, count is %d', [E.Message, ABlockHash.ToString, BoolToStr(AHigher), ACount]), 'method', 'GetSnapshotBlocks');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotHeadersByHeight(AHeight: TUInt64; AHigher: Boolean; ACount: TUInt64): TArray<ISnapshotBlock>;
begin
  try
    Result := Self.GetSnapshotBlockList(function: TArray<ILocation>
    var
      LHeightRange: TArray<TUInt64>;
    begin
      Result := Self.FIndexDB.GetSnapshotBlockLocationListByHeight(AHeight, AHigher, ACount, LHeightRange);
    end, AHigher, True);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.getSnapshotBlockList failed, height is %d, higher is %s, count is %d. Error: %s', [AHeight, BoolToStr(AHigher), ACount, E.Message]), 'method', 'GetSnapshotHeadersByHeight');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotBlocksByHeight(AHeight: TUInt64; AHigher: Boolean; ACount: TUInt64): TArray<ISnapshotBlock>;
begin
  try
    Result := Self.GetSnapshotBlockList(function: TArray<ILocation>
    var
      LHeightRange: TArray<TUInt64>;
    begin
      Result := Self.FIndexDB.GetSnapshotBlockLocationListByHeight(AHeight, AHigher, ACount, LHeightRange);
    end, AHigher, False);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.getSnapshotBlockList failed, height is %d, higher is %s, count is %d. Error: %s', [AHeight, BoolToStr(AHigher), ACount, E.Message]), 'method', 'GetSnapshotBlocksByHeight');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetConfirmSnapshotHeaderByAbHash(const AAbHash: THash): ISnapshotBlock;
var
  LConfirmHeight: TUInt64;
begin
  try
    LConfirmHeight := Self.FIndexDB.GetConfirmHeightByHash(AAbHash);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetConfirmHeightByHash failed, error is %s, blockHash is %s', [E.Message, AAbHash.ToString]), 'method', 'GetConfirmSnapshotHeaderByAbHash');
      raise;
    end;
  end;
  if LConfirmHeight <= 0 then
    Exit(nil);
  Result := Self.GetSnapshotHeaderByHeight(LConfirmHeight);
end;

function TChainSnapshotBlockHelper.GetConfirmSnapshotBlockByAbHash(const AAbHash: THash): ISnapshotBlock;
var
  LConfirmHeight: TUInt64;
begin
  try
    LConfirmHeight := Self.FIndexDB.GetConfirmHeightByHash(AAbHash);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetConfirmHeightByHash failed, error is %s, blockHash is %s', [E.Message, AAbHash.ToString]), 'method', 'GetConfirmSnapshotBlockByAbHash');
      raise;
    end;
  end;
  if LConfirmHeight <= 0 then
    Exit(nil);
  Result := Self.GetSnapshotBlockByHeight(LConfirmHeight);
end;

function TChainSnapshotBlockHelper.GetSnapshotHeaderBeforeTime(const ATimestamp: TDateTime): ISnapshotBlock;
var
  LGenesis, LLatest, LHighBoundary, LLowBoundary, LBlockHeader: ISnapshotBlock;
  LTimeNanosecond: Int64;
  LEndSec, LTimeSec: Int64;
  LGap, LEstimateHeight: TUInt64;
begin
  LGenesis := Self.GetGenesisSnapshotBlock;
  LLatest := Self.GetLatestSnapshotBlock;
  LTimeNanosecond := DateTimeToUnix(ATimestamp) * 1000000000;
  if DateTimeToUnix(LGenesis.Timestamp) * 1000000000 >= LTimeNanosecond then
    Exit(nil);
  if DateTimeToUnix(LLatest.Timestamp) * 1000000000 < LTimeNanosecond then
    Exit(LLatest);

  LEndSec := DateTimeToUnix(LLatest.Timestamp);
  LTimeSec := DateTimeToUnix(ATimestamp);
  LGap := LEndSec - LTimeSec;
  LEstimateHeight := 1;
  if LLatest.Height > LGap then
    LEstimateHeight := LLatest.Height - LGap;

  LHighBoundary := nil;
  LLowBoundary := nil;
  while (LHighBoundary = nil) or (LLowBoundary = nil) do
  begin
    try
      LBlockHeader := Self.GetSnapshotHeaderByHeight(LEstimateHeight);
    except
      on E: Exception do
      begin
        Self.FLog.Error(Format('c.GetSnapshotHeaderByHeight failed, error is %s, height is %d', [E.Message, LEstimateHeight]), 'method', 'GetSnapshotHeaderBeforeTime');
        raise;
      end;
    end;

    if LBlockHeader = nil then
    begin
      Self.FLog.Error(Format('blockHeader is nil,  height is %d', [LEstimateHeight]), 'method', 'GetSnapshotHeaderBeforeTime');
      raise Exception.Create('blockHeader is nil');
    end;

    if DateTimeToUnix(LBlockHeader.Timestamp) * 1000000000 >= LTimeNanosecond then
    begin
      LHighBoundary := LBlockHeader;
      LGap := DateTimeToUnix(LBlockHeader.Timestamp) - LTimeSec;
      if LGap <= 0 then
        LGap := 1;
      if LBlockHeader.Height <= LGap then
      begin
        LLowBoundary := LGenesis;
        Break;
      end
      else
        LEstimateHeight := LBlockHeader.Height - LGap;
    end
    else
    begin
      LLowBoundary := LBlockHeader;
      LEstimateHeight := LBlockHeader.Height + (LTimeSec - DateTimeToUnix(LBlockHeader.Timestamp));
      if LEstimateHeight > LLatest.Height then
        LHighBoundary := LLatest;
    end;
  end;

  if LHighBoundary.Height = LLowBoundary.Height + 1 then
    Exit(LLowBoundary);

  try
    Result := Self.BinarySearchBeforeTime(LLowBoundary, LHighBoundary, LTimeNanosecond);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.binarySearchBeforeTime failed,  lowBoundary is %s, highBoundary is %s, timeNanosecond is %d. Error: %s', [LLowBoundary.ToString, LHighBoundary.ToString, LTimeNanosecond, E.Message]), 'method', 'GetSnapshotHeaderBeforeTime');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotHeadersAfterOrEqualTime(const AEndHashHeight: IHashHeight; const AStartTime: TDateTime; const AProducer: TAddress): TArray<ISnapshotBlock>;
var
  LStartHeader: ISnapshotBlock;
  LSnapshotHeaders: TArray<ISnapshotBlock>;
  LResult: TArray<ISnapshotBlock>;
  LSnapshotHeader: ISnapshotBlock;
begin
  try
    LStartHeader := Self.GetSnapshotHeaderBeforeTime(AStartTime);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.GetSnapshotHeaderBeforeTime failed,  error is %s, startTime is %s', [E.Message, DateTimeToStr(AStartTime)]), 'method', 'GetSnapshotHeaderBeforeTime');
      raise;
    end;
  end;

  if LStartHeader = nil then
    LStartHeader := Self.GetGenesisSnapshotBlock;

  if LStartHeader.Height >= AEndHashHeight.Height then
    Exit(nil);

  try
    LSnapshotHeaders := Self.GetSnapshotHeaders(AEndHashHeight.Hash, False, AEndHashHeight.Height - LStartHeader.Height);
  except
    on E: Exception do
      raise;
  end;

  Self.FLog.Info(Format('GetSnapshotHeadersAfterOrEqualTime %d, %s - %d, %s', [AEndHashHeight.Height, AEndHashHeight.Hash.ToString, LStartHeader.Height, LStartHeader.Hash.ToString]), 'method', 'GetSnapshotHeadersAfterOrEqualTime');

  if AProducer <> nil then
  begin
    SetLength(LResult, 0);
    for LSnapshotHeader in LSnapshotHeaders do
    begin
      if LSnapshotHeader.Producer = AProducer then
        LResult := Concat(LResult, [LSnapshotHeader]);
    end;
    Result := LResult;
  end
  else
    Result := LSnapshotHeaders;
end;

function TChainSnapshotBlockHelper.QuerySnapshotBlockByHeight(AHeight: TUInt64): ISnapshotBlock;
var
  LLocation: ILocation;
begin
  try
    LLocation := Self.FIndexDB.GetSnapshotBlockLocation(AHeight);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetSnapshotBlockLocation failed, height is %d. Error:  %s', [AHeight, E.Message]), 'method', 'QuerySnapshotBlockByHeight');
      raise;
    end;
  end;
  if LLocation = nil then
    Exit(nil);
  try
    Result := Self.FBlockDB.GetSnapshotBlock(LLocation);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.blockDB.GetSnapshotBlock failed, height is %d, location is %s. Error: %s', [AHeight, LLocation.ToString, E.Message]), 'method', 'QuerySnapshotBlockByHeight');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.QueryLatestSnapshotBlock: ISnapshotBlock;
var
  LLocation: ILocation;
begin
  try
    LLocation := Self.FIndexDB.GetLatestSnapshotBlockLocation;
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetLatestSnapshotBlockLocation failed, error is %s', [E.Message]), 'method', 'getLatestSnapshotBlock');
      raise;
    end;
  end;
  if LLocation = nil then
    Exit(nil);
  try
    Result := Self.FBlockDB.GetSnapshotBlock(LLocation);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.blockDB.GetSnapshotBlock failed, error is %s', [E.Message]), 'method', 'getLatestSnapshotBlock');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetRandomSeed(const ASnapshotHash: THash; AN: Integer): TUInt64;
var
  LCount, LHeadHeight, LTailHeight: TUInt64;
  LProducerMap: TDictionary<TAddress, Boolean>;
  LSeedCount: Integer;
  LRandomSeed: TUInt64;
  LPrevHash: THash;
  H: TUInt64;
  LSnapshotHeader: ISnapshotBlock;
  LProducer: TAddress;
begin
  LCount := 10 * 60;
  try
    LHeadHeight := Self.GetSnapshotHeightByHash(ASnapshotHash);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.GetSnapshotHeightByHash failed, snapshotHash is %s. Error: %s', [ASnapshotHash.ToString, E.Message]), 'method', 'GetRandomSeed');
      Exit(0);
    end;
  end;

  LTailHeight := 1;
  if LHeadHeight > LCount then
    LTailHeight := LHeadHeight - LCount;

  LProducerMap := TDictionary<TAddress, Boolean>.Create;
  try
    LSeedCount := 0;
    LRandomSeed := 0;
    LPrevHash := nil;
    for H := LHeadHeight downto LTailHeight do
    begin
      if LSeedCount >= AN then
        Break;
      try
        LSnapshotHeader := Self.GetSnapshotHeaderByHeight(H);
      except
        on E: Exception do
        begin
          Self.FLog.Error(Format('c.GetSnapshotHeaderByHeight failed, error is %s', [E.Message]), 'method', 'GetRandomSeed');
          Exit(0);
        end;
      end;

      if LSnapshotHeader = nil then
      begin
        Self.FLog.Error(Format('snapshotHeader is nil. height is %d', [H]), 'method', 'GetRandomSeed');
        Exit(0);
      end;

      if (LPrevHash <> nil) and (LSnapshotHeader.Hash <> LPrevHash) then
      begin
        Self.FLog.Error('rollbacking...', 'method', 'GetRandomSeed');
        Exit(0);
      end;

      LPrevHash := LSnapshotHeader.PrevHash;

      if LSnapshotHeader.Seed <= 0 then
        Continue;

      LProducer := LSnapshotHeader.Producer;
      if not LProducerMap.ContainsKey(LProducer) then
      begin
        LRandomSeed := LRandomSeed + LSnapshotHeader.Seed;
        Inc(LSeedCount);
        LProducerMap.Add(LProducer, True);
      end;
    end;
  finally
    LProducerMap.Free;
  end;

  Result := LRandomSeed;
end;

function TChainSnapshotBlockHelper.GetSnapshotBlockByContractMeta(const AAddr: TAddress; const AFromHash: THash): ISnapshotBlock;
var
  LMeta: IContractMeta;
  LFirstConfirmedSb, LLimitSb: ISnapshotBlock;
begin
  try
    LMeta := Self.GetContractMeta(AAddr);
  except
    on E: Exception do
      raise;
  end;
  if (LMeta = nil) or (LMeta.SendConfirmedTimes = 0) then
    Exit(nil);
  try
    LFirstConfirmedSb := Self.GetConfirmSnapshotHeaderByAbHash(AFromHash);
  except
    on E: Exception do
      raise;
  end;
  if LFirstConfirmedSb = nil then
    raise Exception.Create('failed to find referred sendBlock'' confirmSnapshotBlock');
  try
    LLimitSb := Self.GetSnapshotBlockByHeight(LFirstConfirmedSb.Height + LMeta.SendConfirmedTimes - 1);
  except
    on E: Exception do
      raise;
  end;
  if LLimitSb = nil then
    raise Exception.Create('fromBlock confirmed times not enough');
  Result := LLimitSb;
end;

function TChainSnapshotBlockHelper.GetSeedConfirmedSnapshotBlock(const AAddr: TAddress; const AFromHash: THash): ISnapshotBlock;
var
  LMeta: IContractMeta;
  LFirstConfirmedSb: ISnapshotBlock;
  LLatestHeight, H: TUInt64;
  LSeedCount: Byte;
  LSnapshotBlock: ISnapshotBlock;
begin
  try
    LMeta := Self.GetContractMeta(AAddr);
  except
    on E: Exception do
      raise;
  end;

  if (LMeta = nil) or (LMeta.SeedConfirmedTimes = 0) then
    Exit(nil);

  try
    LFirstConfirmedSb := Self.GetConfirmSnapshotHeaderByAbHash(AFromHash);
  except
    on E: Exception do
      raise;
  end;
  if LFirstConfirmedSb = nil then
    raise Exception.Create('failed to find referred sendBlock'' confirmSnapshotBlock');

  LLatestHeight := Self.GetLatestSnapshotBlock.Height;
  LSeedCount := 0;
  for H := LFirstConfirmedSb.Height to LLatestHeight do
  begin
    try
      LSnapshotBlock := Self.GetSnapshotBlockByHeight(H);
    except
      on E: Exception do
      begin
        Self.FLog.Error(Format('c.GetSnapshotBlockByHeight failed, height is %d. Error: %s', [H, E.Message]), 'method', 'GetSeedConfirmedSnapshotBlock');
        raise;
      end;
    end;

    if LSnapshotBlock = nil then
      Break;

    if LSnapshotBlock.Seed > 0 then
      Inc(LSeedCount);

    if LSeedCount = LMeta.SeedConfirmedTimes then
      Exit(LSnapshotBlock);
  end;

  raise Exception.Create('fromBlock confirmed times not enough');
end;

function TChainSnapshotBlockHelper.GetSeed(const ALimitSb: ISnapshotBlock; const AFromHash: THash): TUInt64;
var
  LSeed: TUInt64;
  LSeedByte: TBytes;
  LResultSeed: THash;
  I: Integer;
begin
  LSeed := Self.GetRandomSeed(ALimitSb.Hash, DefaultSeedRangeCount);
  LSeedByte := LeftPadBytes(TBigInteger.Create(LSeed).ToBytes, THash.Size);
  for I := 0 to THash.Size - 1 do
    LResultSeed[I] := LSeedByte[I] xor AFromHash[I];
  Result := BytesToU64(LResultSeed.Bytes);
end;

function TChainSnapshotBlockHelper.GetLastUnpublishedSeedSnapshotHeader(const AProducer: TAddress; const ABeforeTime: TDateTime): ISnapshotBlock;
var
  LHeadHeight, LTailHeight, LCount, H: TUInt64;
  LSeeds: TDictionary<TUInt64, Boolean>;
  LSnapshotHeader: ISnapshotBlock;
  LPublished: Boolean;
  LSeed: TUInt64;
  LSeedHash: THash;
begin
  LHeadHeight := Self.GetLatestSnapshotBlock.Height;
  LCount := 10 * 60;
  if LHeadHeight > LCount then
    LTailHeight := LHeadHeight - LCount
  else
    LTailHeight := 1;

  LSeeds := TDictionary<TUInt64, Boolean>.Create;
  try
    for H := LHeadHeight downto LTailHeight do
    begin
      try
        LSnapshotHeader := Self.GetSnapshotHeaderByHeight(H);
      except
        on E: Exception do
        begin
          Self.FLog.Error(Format('c.GetSnapshotHeaderByHeight failed, error is %s', [E.Message]), 'method', 'GetLastUnpublishedSeedSnapshotHeader');
          Exit(nil);
        end;
      end;

      if LSnapshotHeader = nil then
      begin
        Self.FLog.Error(Format('snapshotHeader is nil. height is %d', [H]), 'method', 'GetRandomSeed');
        Exit(nil);
      end;

      if LSnapshotHeader.Producer <> AProducer then
        Continue;

      if LSnapshotHeader.SeedHash = nil then
        Continue;

      if not (LSnapshotHeader.Timestamp < ABeforeTime) then
      begin
        LSeeds.AddOrSetValue(LSnapshotHeader.Seed, True);
        Continue;
      end;

      LPublished := False;
      for LSeed in LSeeds.Keys do
      begin
        LSeedHash := TSnapshotBlock.ComputeSeedHash(LSeed, LSnapshotHeader.PrevHash, LSnapshotHeader.Timestamp);
        if LSeedHash = LSnapshotHeader.SeedHash then
        begin
          LPublished := True;
          Break;
        end;
      end;

      if not LPublished then
        Exit(LSnapshotHeader);

      LSeeds.AddOrSetValue(LSnapshotHeader.Seed, True);
    end;
  finally
    LSeeds.Free;
  end;

  Result := nil;
end;

function TChainSnapshotBlockHelper.GetSubLedger(AStartHeight, AEndHeight: TUInt64): TArray<ISnapshotChunk>;
var
  LLatestSb: ISnapshotBlock;
  LStartLocation, LEndLocation: ILocation;
begin
  try
    LLatestSb := Self.QueryLatestSnapshotBlock;
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.QueryLatestSnapshotBlock failed. Error: %s', [E.Message]), 'method', 'GetSubLedger');
      raise;
    end;
  end;
  if AEndHeight > LLatestSb.Height then
    AEndHeight := LLatestSb.Height;

  if AStartHeight <= 0 then
    LStartLocation := TLocation.Create(1, 0)
  else
  begin
    try
      LStartLocation := Self.FIndexDB.GetSnapshotBlockLocation(AStartHeight);
    except
      on E: Exception do
      begin
        Self.FLog.Error(Format('c.indexDB.GetSnapshotBlockLocation failed,  height is %d. Error: %s', [AStartHeight, E.Message]), 'method', 'GetSubLedger');
        raise;
      end;
    end;
  end;

  if LStartLocation = nil then
    Exit(nil);

  try
    LEndLocation := Self.FIndexDB.GetSnapshotBlockLocation(AEndHeight);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetSnapshotBlockLocation failed,  height is %d. Error: %s', [AEndHeight, E.Message]), 'method', 'GetSubLedger');
      raise;
    end;
  end;
  if LEndLocation = nil then
    Exit(nil);

  try
    Result := Self.FBlockDB.ReadRange(LStartLocation, LEndLocation);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.blockDB.ReadRange failed, startLocation is %s, endLocation is %s, . Error: %s', [LStartLocation.ToString, LEndLocation.ToString, E.Message]), 'method', 'GetSubLedger');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSubLedgerAfterHeight(AHeight: TUInt64): TArray<ISnapshotChunk>;
var
  LStartLocation: ILocation;
begin
  try
    LStartLocation := Self.FIndexDB.GetSnapshotBlockLocation(AHeight);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.indexDB.GetSnapshotBlockLocation failed,  height is %d. Error: %s', [AHeight, E.Message]), 'method', 'GetSubLedgerAfterHeight');
      raise;
    end;
  end;
  if LStartLocation = nil then
    Exit(nil);

  try
    Result := Self.FBlockDB.ReadRange(LStartLocation, nil);
  except
    on E: Exception do
    begin
      Self.FLog.Error(Format('c.blockDB.ReadRange failed,  startLocation is %s, endLocation is nil. Error: %s', [LStartLocation.ToString, E.Message]), 'method', 'GetSubLedgerAfterHeight');
      raise;
    end;
  end;
end;

function TChainSnapshotBlockHelper.GetSnapshotBlockList(AGetList: TFunc<TArray<ILocation>, TArray<TUInt64>>; AHigher, AOnlyHeader: Boolean): TArray<ISnapshotBlock>;
var
  LLocations: TArray<ILocation>;
  LHeightRange: TArray<TUInt64>;
  LLocationsLen, I: Integer;
  LBlocks: TArray<ISnapshotBlock>;
  LEndHeight: TUInt64;
  LLocation: ILocation;
  LBlock: ISnapshotBlock;
begin
  LLocations := AGetList(LHeightRange);
  LLocationsLen := Length(LLocations);
  if LLocationsLen <= 0 then
    Exit(nil);

  SetLength(LBlocks, LLocationsLen);
  LEndHeight := LHeightRange[0];

  for I := 0 to LLocationsLen - 1 do
  begin
    LLocation := LLocations[I];
    LBlock := Self.FCache.GetSnapshotBlockByHeight(LEndHeight - I);
    if LBlock = nil then
    begin
      try
        LBlock := Self.FBlockDB.GetSnapshotBlock(LLocation);
      except
        on E: Exception do
          raise;
      end;
    end;

    if AHigher then
      LBlocks[LLocationsLen - 1 - I] := LBlock
    else
      LBlocks[I] := LBlock;
  end;

  Result := LBlocks;
end;

function TChainSnapshotBlockHelper.BinarySearchBeforeTime(AStart, AEnd: ISnapshotBlock; ATimeNanosecond: Int64): ISnapshotBlock;
var
  N, I: Integer;
  LBlockMap: TDictionary<Integer, ISnapshotBlock>;
  LErr: Exception;
  LHeight: TUInt64;
  LBlock: ISnapshotBlock;
begin
  N := AEnd.Height - AStart.Height + 1;
  LBlockMap := TDictionary<Integer, ISnapshotBlock>.Create;
  try
    LErr := nil;
    I := TArray.BinarySearch<Integer>(N, function(AIndex: Integer): Integer
    begin
      if LErr <> nil then
        Exit(1);
      LHeight := AStart.Height + AIndex;
      try
        LBlockMap.AddOrSetValue(AIndex, Self.GetSnapshotHeaderByHeight(LHeight));
      except
        on E: Exception do
        begin
          LErr := E;
          Exit(1);
        end;
      end;
      if LBlockMap[AIndex] = nil then
      begin
        LErr := Exception.Create('Rolling back');
        Exit(1);
      end;
      if DateTimeToUnix(LBlockMap[AIndex].Timestamp) * 1000000000 >= ATimeNanosecond then
        Result := 1
      else
        Result := -1;
    end);

    if LErr <> nil then
      raise LErr;

    if I >= N then
      Exit(nil);

    if LBlockMap.TryGetValue(I - 1, LBlock) then
      Result := LBlock
    else
      Result := Self.GetSnapshotHeaderByHeight(AStart.Height + I - 1);
  finally
    LBlockMap.Free;
  end;
end;

end.
