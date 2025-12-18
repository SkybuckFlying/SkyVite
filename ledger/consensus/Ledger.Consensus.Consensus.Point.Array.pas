unit Ledger.Consensus.ConsensusPointArray;

interface

uses
  Common.Types,
  Go.lru,
  Ledger.Consensus.API,
  Ledger.Consensus.CDB,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
  Ledger.Consensus.ChainRw,
  Ledger.Consensus.Config,
  Ledger.Consensus.Consensus,
  Ledger.Consensus.Consensus.Contract,
  Ledger.Consensus.Consensus.Contract.Dpos,
  Ledger.Consensus.Consensus.Contract.Dpos.Test,
  Ledger.Consensus.Consensus.Event,
  Ledger.Consensus.Consensus.Impl,
  Ledger.Consensus.Consensus.Point.Array.Test,
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Simple.Test,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.Core,
  Ledger.Consensus.Dpos,
  Ledger.Consensus.Mock.Ch,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  Log15,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  V2.Interfaces.Core;

type
  ILinkedArray = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B3E}']
    function GetByIndex(ParaIndex: UInt64): TTuple<TPoint, Exception>;
    function GetByIndexWithProof(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
    function Index2Time(ParaIndex: UInt64): TDateTime;
    function Time2Index(ParaTime: TDateTime): UInt64;
  end;

  TLinkedArray = class(TInterfacedObject, ILinkedArray)
  private
    mTimeIndex: ITimeIndex;
    mPrefix: Byte;
    mRate: UInt64;
    mDb: TConsensusDB;
    mLowerArr: ILinkedArray;
    mProof: IRollbackProof;
    mExtraDataFn: TFunc<Byte, UInt64, THash, TTuple<TVoteContent, Exception>>;
    mLog: ILogger;
    function GetByIndexWithProofFromDb(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Boolean, Exception>;
    function GetByIndexWithProofFromKernel(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
  public
    constructor Create(ParaLowerArr: ILinkedArray; ParaDb: TConsensusDB; ParaProof: IRollbackProof; ParaRate: UInt64; ParaPrefix: Byte; ParaGenesisTime: TDateTime; ParaInterval: TTimeSpan; ParaLog: ILogger; ParaExtraDataFn: TFunc<Byte, UInt64, THash, TTuple<TVoteContent, Exception>> = nil);
    function GetByIndex(ParaIndex: UInt64): TTuple<TPoint, Exception>;
    function GetByIndexWithProof(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
    function Index2Time(ParaIndex: UInt64): TDateTime;
    function Time2Index(ParaTime: TDateTime): UInt64;
  end;

  TPeriodLinkedArray = class(TInterfacedObject, ILinkedArray)
  private
    mTimeIndex: ITimeIndex;
    mPeriods: TLruCache;
    mRw: IChain;
    mSnapshot: IDposReader;
    mProof: IRollbackProof;
    mLog: ILogger;
    function GetByIndexWithProofFromDb(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
    function GetByIndexWithProofFromChain(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
    procedure Set(ParaIndex: UInt64; ParaBlock: TPoint);
    function GenPeriodPoint(ParaIndex: UInt64; ParaStime, ParaEtime: TDateTime; const ParaProofHash: THash; const ParaBlocks: TArray<ISnapshotBlock>; ParaResult: IElectionResult): TTuple<TPoint, Exception>;
  public
    constructor Create(ParaRw: IChain; ParaCs: IDposReader; ParaProof: IRollbackProof; ParaLog: ILogger);
    destructor Destroy; override;
    function GetByIndex(ParaIndex: UInt64): TTuple<TPoint, Exception>;
    function GetByIndexWithProof(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
    function Index2Time(ParaIndex: UInt64): TDateTime;
    function Time2Index(ParaTime: TDateTime): UInt64;
  end;

function NewDayLinkedArray(ParaHour: ILinkedArray; ParaDb: TConsensusDB; ParaProof: IRollbackProof; ParaFn: TFunc<Byte, UInt64, THash, TTuple<TVoteContent, Exception>>; ParaGenesisTime: TDateTime; ParaLog: ILogger): ILinkedArray;
function NewHourLinkedArray(ParaPeriod: ILinkedArray; ParaDb: TConsensusDB; ParaProof: IRollbackProof; ParaIntervalSec: TTimeSpan; ParaGenesisTime: TDateTime; ParaLog: ILogger): ILinkedArray;
function NewPeriodPointArray(ParaRw: IChain; ParaCs: IDposReader; ParaProof: IRollbackProof; ParaLog: ILogger): ILinkedArray;

implementation

uses
  System.DateUtils,
  System.JSON;

function NewDayLinkedArray(ParaHour: ILinkedArray; ParaDb: TConsensusDB; ParaProof: IRollbackProof; ParaFn: TFunc<Byte, UInt64, THash, TTuple<TVoteContent, Exception>>; ParaGenesisTime: TDateTime; ParaLog: ILogger): ILinkedArray;
begin
  Result := TLinkedArray.Create(ParaHour, ParaDb, ParaProof, 24, cdb.IndexPointDay, ParaGenesisTime, TTimeSpan.FromHours(24), ParaLog, ParaFn);
end;

function NewHourLinkedArray(ParaPeriod: ILinkedArray; ParaDb: TConsensusDB; ParaProof: IRollbackProof; ParaIntervalSec: TTimeSpan; ParaGenesisTime: TDateTime; ParaLog: ILogger): ILinkedArray;
var
  vRate: UInt64;
begin
  vRate := Round(TTimeSpan.FromHours(1).TotalSeconds / ParaIntervalSec.TotalSeconds);
  Result := TLinkedArray.Create(ParaPeriod, ParaDb, ParaProof, vRate, cdb.IndexPointHour, ParaGenesisTime, TTimeSpan.FromHours(1), ParaLog);
end;

function NewPeriodPointArray(ParaRw: IChain; ParaCs: IDposReader; ParaProof: IRollbackProof; ParaLog: ILogger): ILinkedArray;
begin
  Result := TPeriodLinkedArray.Create(ParaRw, ParaCs, ParaProof, ParaLog);
end;

{ TLinkedArray }

constructor TLinkedArray.Create(ParaLowerArr: ILinkedArray; ParaDb: TConsensusDB; ParaProof: IRollbackProof; ParaRate: UInt64; ParaPrefix: Byte; ParaGenesisTime: TDateTime; ParaInterval: TTimeSpan; ParaLog: ILogger; ParaExtraDataFn: TFunc<Byte, UInt64, THash, TTuple<TVoteContent, Exception>>);
begin
  mLowerArr := ParaLowerArr;
  mDb := ParaDb;
  mProof := ParaProof;
  mRate := ParaRate;
  mPrefix := ParaPrefix;
  mTimeIndex := TTimeIndex.Create(ParaGenesisTime, ParaInterval);
  mLog := ParaLog;
  mExtraDataFn := ParaExtraDataFn;
end;

function TLinkedArray.GetByIndex(ParaIndex: UInt64): TTuple<TPoint, Exception>;
var
  vStime, vEtime: TDateTime;
  vHash: THash;
  vErr: Exception;
begin
  vStime, vEtime := mTimeIndex.Index2Time(ParaIndex);
  vHash := mProof.ProofHash(vEtime, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
  end;
  Result := GetByIndexWithProof(ParaIndex, vHash);
end;

function TLinkedArray.GetByIndexWithProof(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
var
  vPoint: TPoint;
  vExists: Boolean;
  vBytes: TBytes;
  vErr: Exception;
begin
  TValue.Make(GetByIndexWithProofFromDb(ParaIndex, ParaProofHash), vPoint, vExists, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
  end;
  if vPoint <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(vPoint, nil));
  end;

  TValue.Make(GetByIndexWithProofFromKernel(ParaIndex, ParaProofHash), vPoint, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
  end;
  if vPoint = nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, Exception.CreateFmt('index[%d][%d]proof[%s] Get fail', [mPrefix, ParaIndex, ParaProofHash.ToString])));
  end;
  if vExists and vPoint.IsEmpty then
  begin
    mDb.DeletePointByHeight(mPrefix, ParaIndex);
  end
  else
  begin
    vErr := mDb.StorePointByHeight(mPrefix, ParaIndex, vPoint);
    if vErr <> nil then
    begin
      vBytes := TEncoding.UTF8.GetBytes(TJson.Format(vPoint.ToJsonObject));
      mLog.Error('store point by height Fail.', 'index', ParaIndex, 'point', string(vBytes));
    end;
  end;
  Result := TTuple<TPoint, Exception>.Create(vPoint, nil);
end;

function TLinkedArray.GetByIndexWithProofFromDb(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Boolean, Exception>;
var
  vPoint: TPoint;
  vEmptyProofResult: Boolean;
  vStime, vEtime: TDateTime;
  vErr: Exception;
begin
  vPoint := mDb.GetPointByHeight(mPrefix, ParaIndex, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Boolean, Exception>.Create(nil, false, vErr));
  end;
  if vPoint = nil then
  begin
    vStime, vEtime := mTimeIndex.Index2Time(ParaIndex);
    vEmptyProofResult := mProof.ProofEmpty(vStime, vEtime, vErr);
    if vErr <> nil then
    begin
      Exit(TTuple<TPoint, Boolean, Exception>.Create(nil, false, vErr));
    end;
    if vEmptyProofResult then
    begin
      Result := TTuple<TPoint, Boolean, Exception>.Create(TPoint.CreateEmpty(ParaProofHash), false, nil);
    end
    else
    begin
      Result := TTuple<TPoint, Boolean, Exception>.Create(nil, false, nil);
    end;
  end
  else
  begin
    if ParaProofHash = vPoint.Hash then
    begin
      Result := TTuple<TPoint, Boolean, Exception>.Create(vPoint, true, nil);
    end
    else
    begin
      Result := TTuple<TPoint, Boolean, Exception>.Create(nil, true, nil);
    end;
  end;
end;

function TLinkedArray.GetByIndexWithProofFromKernel(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
var
  vResultPoint: TPoint;
  vStart, vEnd, vIndex: UInt64;
  vTmpProofHash: THash;
  vP: TPoint;
  vVoteContent: TVoteContent;
  vErr: Exception;
begin
  vResultPoint := TPoint.CreateEmpty(ParaProofHash);
  vStart := ParaIndex * mRate;
  vEnd := vStart + mRate;
  vTmpProofHash := ParaProofHash;
  for vIndex := vEnd downto vStart + 1 do
  begin
    TValue.Make(mLowerArr.GetByIndexWithProof(vIndex - 1, vTmpProofHash), vP, vErr);
    if vErr <> nil then
    begin
      Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
    end;
    if vP.IsEmpty then
    begin
      Continue;
    end;
    vTmpProofHash := vP.PrevHash;
    vErr := vResultPoint.LeftAppend(vP);
    if vErr <> nil then
    begin
      Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
    end;
  end;
  if not vResultPoint.IsEmpty and (Assigned(mExtraDataFn)) then
  begin
    TValue.Make(mExtraDataFn(mPrefix, ParaIndex, ParaProofHash), vVoteContent, vErr);
    if vErr <> nil then
    begin
      Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
    end;
    if vVoteContent <> nil then
    begin
      vResultPoint.Votes := vVoteContent;
    end;
  end;
  Result := TTuple<TPoint, Exception>.Create(vResultPoint, nil);
end;

function TLinkedArray.Index2Time(ParaIndex: UInt64): TDateTime;
var
  vSt, vEt: TDateTime;
begin
  vSt, vEt := mTimeIndex.Index2Time(ParaIndex);
  Result := vSt;
end;

function TLinkedArray.Time2Index(ParaTime: TDateTime): UInt64;
begin
  Result := mTimeIndex.Time2Index(ParaTime);
end;

{ TPeriodLinkedArray }

constructor TPeriodLinkedArray.Create(ParaRw: IChain; ParaCs: IDposReader; ParaProof: IRollbackProof; ParaLog: ILogger);
begin
  try
    mPeriods := TLruCache.Create(4 * 24 * 60);
  except
    on E: Exception do
    begin
      raise E;
    end;
  end;
  mTimeIndex := TTimeIndex.Create(ParaCs.GetInfo.GenesisTime, TTimeSpan.FromSeconds(ParaCs.GetInfo.PlanInterval));
  mRw := ParaRw;
  mSnapshot := ParaCs;
  mLog := ParaLog;
  mProof := ParaProof;
end;

destructor TPeriodLinkedArray.Destroy;
begin
  mPeriods.Free;
  inherited;
end;

function TPeriodLinkedArray.GetByIndex(ParaIndex: UInt64): TTuple<TPoint, Exception>;
var
  vStime, vEtime: TDateTime;
  vProofHash: THash;
  vErr: Exception;
begin
  vStime, vEtime := mTimeIndex.Index2Time(ParaIndex);
  vProofHash := mProof.ProofHash(vEtime, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
  end;
  Result := GetByIndexWithProof(ParaIndex, vProofHash);
end;

procedure TPeriodLinkedArray.Set(ParaIndex: UInt64; ParaBlock: TPoint);
begin
  mPeriods.Add(ParaIndex, ParaBlock);
end;

function TPeriodLinkedArray.GetByIndexWithProof(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
var
  vPoint: TPoint;
  vBytes: TBytes;
  vErr: Exception;
begin
  if mRw.IsGenesisSnapshotBlock(ParaProofHash) then
  begin
    Exit(TTuple<TPoint, Exception>.Create(TPoint.CreateEmpty(ParaProofHash), nil));
  end;
  TValue.Make(GetByIndexWithProofFromDb(ParaIndex, ParaProofHash), vPoint, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
  end;
  if vPoint <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(vPoint, nil));
  end;

  TValue.Make(GetByIndexWithProofFromChain(ParaIndex, ParaProofHash), vPoint, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
  end;
  if vPoint = nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, Exception.CreateFmt('period index[%d]proof[%s] Get fail', [ParaIndex, ParaProofHash.ToString])));
  end;
  vErr := Set(ParaIndex, vPoint);
  if vErr <> nil then
  begin
    vBytes := TEncoding.UTF8.GetBytes(TJson.Format(vPoint.ToJsonObject));
    mLog.Error('store period point by height Fail.', 'index', ParaIndex, 'point', string(vBytes));
  end;

  Result := TTuple<TPoint, Exception>.Create(vPoint, nil);
end;

function TPeriodLinkedArray.GetByIndexWithProofFromDb(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
var
  vValue: TObject;
  vProofEmptyResult: Boolean;
  vStime, vEtime: TDateTime;
  vErr: Exception;
begin
  if not mPeriods.Get(ParaIndex, vValue) or (vValue = nil) then
  begin
    vStime, vEtime := mTimeIndex.Index2Time(ParaIndex);
    vProofEmptyResult := mProof.ProofEmpty(vStime, vEtime, vErr);
    if vErr <> nil then
    begin
      Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
    end;
    if vProofEmptyResult then
    begin
      Result := TTuple<TPoint, Exception>.Create(TPoint.CreateEmpty(ParaProofHash), nil);
    end
    else
    begin
      Result := TTuple<TPoint, Exception>.Create(nil, nil);
    end;
  end
  else
  begin
    Result := TTuple<TPoint, Exception>.Create(TPoint(vValue), nil);
    if ParaProofHash <> TPoint(vValue).Hash then
    begin
      Result := TTuple<TPoint, Exception>.Create(nil, nil);
    end;
  end;
end;

function TPeriodLinkedArray.GetByIndexWithProofFromChain(ParaIndex: UInt64; const ParaProofHash: THash): TTuple<TPoint, Exception>;
var
  vStime, vEtime: TDateTime;
  vBlock: ISnapshotBlock;
  vBlocks: TArray<ISnapshotBlock>;
  vV: ISnapshotBlock;
  vResultElection: IElectionResult;
  vPlan: IMemberPlan;
  vErr: Exception;
begin
  vStime, vEtime := mSnapshot.Index2Time(ParaIndex);
  vBlock := mRw.GetSnapshotBlockByHash(ParaProofHash, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
  end;
  if vBlock = nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, Exception.CreateFmt('period index[%d] proof[%s] not exist.', [ParaIndex, ParaProofHash.ToString])));
  end;
  if vBlock.Timestamp < vStime then
  begin
    Exit(TTuple<TPoint, Exception>.Create(TPoint.CreateEmpty(ParaProofHash), nil));
  end;
  vBlocks := mRw.GetSnapshotHeadersAfterOrEqualTime(THashHeight.Create(vBlock.Hash, vBlock.Height), vStime, nil, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
  end;

  for vV in vBlocks do
  begin
    mLog.Debug(Format('[A]index:%d, height:%d, producer:%s, hash:%s', [ParaIndex, vV.Height, vV.Producer.ToString, vV.Hash.ToString]));
  end;

  if Length(vBlocks) = 0 then
  begin
    Exit(TTuple<TPoint, Exception>.Create(TPoint.CreateEmpty(ParaProofHash), nil));
  end;

  TValue.Make(mSnapshot.ElectionIndex(ParaIndex), vResultElection, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, vErr));
  end;

  for vPlan in vResultElection.Plans do
  begin
    mLog.Debug(Format('[E]index:%d, producer:%s, stime:%s ', [ParaIndex, vPlan.Member.ToString, DateTimeToStr(vPlan.STime)]));
  end;

  Result := GenPeriodPoint(ParaIndex, vStime, vEtime, ParaProofHash, vBlocks, vResultElection);
end;

function TPeriodLinkedArray.GenPeriodPoint(ParaIndex: UInt64; ParaStime, ParaEtime: TDateTime; const ParaProofHash: THash; const ParaBlocks: TArray<ISnapshotBlock>; ParaResult: IElectionResult): TTuple<TPoint, Exception>;
var
  vPoint: TPoint;
  vV: ISnapshotBlock;
  vSbp: TContent;
  vPlan: IMemberPlan;
begin
  if ParaProofHash <> ParaBlocks[0].Hash then
  begin
    Exit(TTuple<TPoint, Exception>.Create(nil, Exception.CreateFmt('gen period point fail[%s][%s]', [ParaProofHash.ToString, ParaBlocks[0].Hash.ToString])));
  end;
  vPoint := TPoint.CreateEmpty(ParaProofHash);
  vPoint.PrevHash := ParaBlocks[High(ParaBlocks)].PrevHash;
  vPoint.Hash := ParaBlocks[0].Hash;
  for vV in ParaBlocks do
  begin
    if vPoint.Sbps.TryGetValue(vV.Producer, vSbp) then
    begin
      vSbp.AddNum(0, 1);
    end
    else
    begin
      vPoint.Sbps.Add(vV.Producer, TContent.Create(1, 0));
    end;
  end;

  for vPlan in ParaResult.Plans do
  begin
    if vPoint.Sbps.TryGetValue(vPlan.Member, vSbp) then
    begin
      vSbp.AddNum(1, 0);
    end
    else
    begin
      vPoint.Sbps.Add(vPlan.Member, TContent.Create(0, 1));
    end;
  end;
  Result := TTuple<TPoint, Exception>.Create(vPoint, nil);
end;

function TPeriodLinkedArray.Index2Time(ParaIndex: UInt64): TDateTime;
var
  vSt, vEt: TDateTime;
begin
  vSt, vEt := mTimeIndex.Index2Time(ParaIndex);
  Result := vSt;
end;

function TPeriodLinkedArray.Time2Index(ParaTime: TDateTime): UInt64;
begin
  Result := mTimeIndex.Time2Index(ParaTime);
end;

end.
