unit Ledger.Consensus.Consensus;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  Common.Types,
  V2.Interfaces,
  V2.Interfaces.Core,
  Ledger.Consensus.Config,
  Ledger.Consensus.CDB,
  Ledger.Consensus.Core,
  Ledger.Consensus.ChainRw,
  Ledger.Consensus.Snapshot,
  Ledger.Consensus.Contract,
  Ledger.Consensus.Trigger,
  Ledger.Pool.Lock,
  Log15,
  Common.Lifecycle,
  GoToDelphi.Helpers.TChannel;

type
  // Event will trigger when the snapshot block needs production
  TEvent = record
    Gid: TGid;
    Address: TAddress;
    Stime: TDateTime;
    Etime: TDateTime;
    Timestamp: TDateTime; // add to block
    VoteTime: TDateTime; // voteTime
    PeriodStime: TDateTime; // start time for period
    PeriodEtime: TDateTime; // end time for period
  end;

  // ProducersEvent describes all SBP in one period
  TProducersEvent = record
    Addrs: TArray<TAddress>;
    Index: UInt64;
    Gid: TGid;
  end;

  TEventFunc = procedure(const ParaEvent: TEvent);
  TProducersEventFunc = procedure(const ParaEvent: TProducersEvent);

  // Subscriber provide an interface to consensus event
  ISubscriber = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B3F}']
    procedure Subscribe(const ParaGid: TGid; const ParaId: string; const ParaAddr: TAddress; ParaFn: TEventFunc);
    procedure UnSubscribe(const ParaGid: TGid; const ParaId: string);
    procedure SubscribeProducers(const ParaGid: TGid; const ParaId: string; ParaFn: TProducersEventFunc);
    function TriggerMineEvent(const ParaAddr: TAddress): Exception;
  end;

  // Reader can read consensus result
  IReader = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B40}']
    function ReadByIndex(const ParaGid: TGid; ParaIndex: UInt64): TTuple<TArray<TEvent>, UInt64, Exception>;
    function VoteTimeToIndex(const ParaGid: TGid; ParaT2: TDateTime): TTuple<UInt64, Exception>;
    function VoteIndexToTime(const ParaGid: TGid; ParaI: UInt64): TTuple<TDateTime, TDateTime, Exception>;
  end;

  // APIReader is just provided for RPC api
  IAPIReader = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B41}']
    function ReadVoteMap(ParaT: TDateTime): TTuple<TArray<TVoteDetails>, IHashHeight, Exception>;
    function ReadSuccessRate(ParaStart, ParaEnd: UInt64): TTuple<TArray<TDictionary<TAddress, IContent>>, Exception>;
    function ReadByIndex(const ParaGid: TGid; ParaIndex: UInt64): TTuple<TArray<TEvent>, UInt64, Exception>;
  end;

  // Life define the life cycle for consensus component
  ILife = interface
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B42}']
    procedure Start;
    procedure Init(ParaCfg: TConsensusCfg);
    procedure Stop;
  end;

  // Consensus include all interface for consensus
  IConsensus = interface(IConsensusVerifier, ISubscriber, IReader, ILife)
    ['{E3B8B3B3-3B3B-4B3B-8B3B-4B3B3B3B3B43}']
    function API: IAPIReader;
    function SBPReader: ISBPStatReader;
  end;

  // update committee result
  TConsensus = class(TLifecycle, IConsensus)
  private
    mConsensusCfg: TConsensusCfg;
    mSubscriber: ISubscriber;
    mSubscribeTrigger: ISubscribeTrigger;
    mLog: ILogger;
    mGenesis: TDateTime;
    mRw: TChainRw;
    mRollback: IChainRollback;
    mSnapshot: TSnapshotCs;
    mContracts: TContractsCs;
    mDposWrapper: TdposReader;
    mApi: IAPIReader;
    mWg: TCountdownEvent;
    mClosed: TChannel<Boolean>;
    mCtx: ICancellationTokenSource;
    mCancelFn: TProc;
    mTg: TTrigger;
    function VerifyABsProducerByGid(const ParaGid: TGid; const ParaBlocks: TArray<IAccountBlock>): TTuple<TArray<IAccountBlock>, Exception>;
  public
    constructor Create(ParaCh: IChain; ParaRollback: IChainRollback);
    destructor Destroy; override;
    function SBPReader: ISBPStatReader;
    function API: IAPIReader;
    // IConsensusVerifier
    function VerifyAccountProducer(ParaBlock: IAccountBlock): Exception;
    function VerifyABsProducer(const ParaAbs: TDictionary<TGid, TArray<IAccountBlock>>): TArray<IAccountBlock>;
    function VerifySnapshotProducer(ParaBlock: ISnapshotBlock): Exception;
    // ISubscriber
    procedure Subscribe(const ParaGid: TGid; const ParaId: string; const ParaAddr: TAddress; ParaFn: TEventFunc);
    procedure UnSubscribe(const ParaGid: TGid; const ParaId: string);
    procedure SubscribeProducers(const ParaGid: TGid; const ParaId: string; ParaFn: TProducersEventFunc);
    function TriggerMineEvent(const ParaAddr: TAddress): Exception;
    // IReader
    function ReadByIndex(const ParaGid: TGid; ParaIndex: UInt64): TTuple<TArray<TEvent>, UInt64, Exception>;
    function VoteTimeToIndex(const ParaGid: TGid; ParaT2: TDateTime): TTuple<UInt64, Exception>;
    function VoteIndexToTime(const ParaGid: TGid; ParaI: UInt64): TTuple<TDateTime, TDateTime, Exception>;
    // ILife
    procedure Start;
    procedure Init(ParaCfg: TConsensusCfg);
    procedure Stop;
  end;

function NewConsensus(ParaCh: IChain; ParaRollback: IChainRollback): IConsensus;

implementation

uses
  Ledger.Consensus.Api,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Event;

{ TConsensus }

constructor TConsensus.Create(ParaCh: IChain; ParaRollback: IChainRollback);
var
  vLog: ILogger;
  vRw: TChainRw;
  vSub: TConsensusSubscriber;
begin
  inherited Create;
  vLog := TLogger.New('module', 'consensus');
  vRw := TChainRw.Create(ParaCh, vLog, ParaRollback);
  vSub := TConsensusSubscriber.Create;
  mRw := vRw;
  mRollback := ParaRollback;
  mLog := vLog;
  mSubscriber := vSub;
  mSubscribeTrigger := vSub;
  mSnapshot := TSnapshotCs.Create(mRw, mLog);
  mContracts := TContractsCs.Create(mRw, mLog);
  mDposWrapper := TdposReader.Create(mSnapshot, mContracts, mLog);
  mApi := TAPISnapshot.NewAPISnapshot(mSnapshot);
end;

destructor TConsensus.Destroy;
begin
  mRw.Free;
  mSnapshot.Free;
  mContracts.Free;
  mDposWrapper.Free;
  inherited;
end;

function TConsensus.SBPReader: ISBPStatReader;
begin
  Result := mSnapshot;
end;

function TConsensus.API: IAPIReader;
begin
  Result := mApi;
end;

function TConsensus.VerifySnapshotProducer(ParaBlock: ISnapshotBlock): Exception;
var
  vErr: Exception;
begin
  vErr := mSnapshot.VerifyProducerAndSeed(ParaBlock);
  if vErr <> nil then
  begin
    Exit(vErr);
  end;
  Result := mSnapshot.VerifyProducer(ParaBlock.Producer, ParaBlock.Timestamp);
end;

function TConsensus.VerifyABsProducer(const ParaAbs: TDictionary<TGid, TArray<IAccountBlock>>): TArray<IAccountBlock>;
var
  vResultList: TArray<IAccountBlock>;
  vK: TGid;
  vV: TArray<IAccountBlock>;
  vBlocks: TArray<IAccountBlock>;
  vErr: Exception;
begin
  SetLength(vResultList, 0);
  for vK in ParaAbs.Keys do
  begin
    vV := ParaAbs[vK];
    TValue.Make(VerifyABsProducerByGid(vK, vV), vBlocks, vErr);
    if vErr <> nil then
    begin
      mLog.Error('verify account block producer err', 'err', vErr.Message);
    end;
    vResultList := Concat(vResultList, vBlocks);
  end;
  Result := vResultList;
end;

function TConsensus.VerifyABsProducerByGid(const ParaGid: TGid; const ParaBlocks: TArray<IAccountBlock>): TTuple<TArray<IAccountBlock>, Exception>;
var
  vTel: TContractDposCs;
  vErr: Exception;
begin
  vTel := mContracts.GetOrLoadGid(ParaGid, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TArray<IAccountBlock>, Exception>.Create(nil, vErr));
  end;
  Result := vTel.VerifyAccountsProducer(ParaBlocks);
end;

function TConsensus.VerifyAccountProducer(ParaBlock: IAccountBlock): Exception;
var
  vGid: TGid;
  vTel: TContractDposCs;
  vErr: Exception;
begin
  vGid := mRw.GetGid(ParaBlock, vErr);
  if vErr <> nil then
  begin
    Exit(vErr);
  end;
  vTel := mContracts.GetOrLoadGid(vGid, vErr);
  if vErr <> nil then
  begin
    Exit(vErr);
  end;
  Result := vTel.VerifyAccountProducer(ParaBlock);
end;

procedure TConsensus.Subscribe(const ParaGid: TGid; const ParaId: string; const ParaAddr: TAddress; ParaFn: TEventFunc);
begin
  mSubscriber.Subscribe(ParaGid, ParaId, ParaAddr, ParaFn);
end;

procedure TConsensus.UnSubscribe(const ParaGid: TGid; const ParaId: string);
begin
  mSubscriber.UnSubscribe(ParaGid, ParaId);
end;

procedure TConsensus.SubscribeProducers(const ParaGid: TGid; const ParaId: string; ParaFn: TProducersEventFunc);
begin
  mSubscriber.SubscribeProducers(ParaGid, ParaId, ParaFn);
end;

function TConsensus.TriggerMineEvent(const ParaAddr: TAddress): Exception;
begin
  Result := mSubscriber.TriggerMineEvent(ParaAddr);
end;

function TConsensus.ReadByIndex(const ParaGid: TGid; ParaIndex: UInt64): TTuple<TArray<TEvent>, UInt64, Exception>;
var
  vReader: IDposReader;
  vEResult: IElectionResult;
  vVoteTime: TDateTime;
  vResultList: TArray<TEvent>;
  vP: IMemberPlan;
  vE: TEvent;
  vErr: Exception;
begin
  vReader := mDposWrapper.GetDposConsensus(ParaGid, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TArray<TEvent>, UInt64, Exception>.Create(nil, 0, vErr));
  end;
  vEResult := vReader.ElectionIndex(ParaIndex, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TArray<TEvent>, UInt64, Exception>.Create(nil, 0, vErr));
  end;

  vVoteTime := mSnapshot.GenProofTime(ParaIndex);
  SetLength(vResultList, 0);
  for vP in vEResult.Plans do
  begin
    vE := NewConsensusEvent(vEResult, vP, ParaGid, vVoteTime);
    vResultList := Concat(vResultList, [vE]);
  end;
  Result := TTuple<TArray<TEvent>, UInt64, Exception>.Create(vResultList, vEResult.Index, nil);
end;

function TConsensus.VoteTimeToIndex(const ParaGid: TGid; ParaT2: TDateTime): TTuple<UInt64, Exception>;
var
  vReader: IDposReader;
  vErr: Exception;
begin
  vReader := mDposWrapper.GetDposConsensus(ParaGid, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<UInt64, Exception>.Create(0, vErr));
  end;
  Result := TTuple<UInt64, Exception>.Create(vReader.Time2Index(ParaT2), nil);
end;

function TConsensus.VoteIndexToTime(const ParaGid: TGid; ParaI: UInt64): TTuple<TDateTime, TDateTime, Exception>;
var
  vReader: IDposReader;
  vSt, vEt: TDateTime;
  vErr: Exception;
begin
  vReader := mDposWrapper.GetDposConsensus(ParaGid, vErr);
  if vErr <> nil then
  begin
    Exit(TTuple<TDateTime, TDateTime, Exception>.Create(Default(TDateTime), Default(TDateTime), vErr));
  end;
  vSt, vEt := vReader.Index2Time(ParaI);
  Result := TTuple<TDateTime, TDateTime, Exception>.Create(vSt, vEt, nil);
end;

procedure TConsensus.Init(ParaCfg: TConsensusCfg);
var
  vErr: Exception;
begin
  if not PreInit then
  begin
    raise Exception.Create('pre init fail.');
  end;
  try
    if ParaCfg = nil then
    begin
      ParaCfg := DefaultCfg;
    end;
    mConsensusCfg := ParaCfg;
    mRw.Init(mSnapshot);
    mTg := TTrigger.Create(mRollback);
    mContracts.GetOrLoadGid(DELEGATE_GID, vErr);
    if vErr <> nil then
    begin
      raise vErr;
    end;
  finally
    PostInit;
  end;
end;

procedure TConsensus.Start;
var
  vReader: IDposReader;
  vErr: Exception;
begin
  if PreStart then
  try
    mClosed := TChannel<Boolean>.Create;
    mCtx := TCancellationTokenSource.Create;
    mCancelFn := procedure
    begin
      mCtx.Cancel;
    end;

    mWg.Add(1);
    TTask.Run(procedure
    begin
      try
        mTg.Update(mCtx.Token, SNAPSHOT_GID, mSnapshot, mSubscribeTrigger);
      finally
        mWg.Done;
      end;
    end);

    vReader := mDposWrapper.GetDposConsensus(DELEGATE_GID, vErr);
    if vErr <> nil then
    begin
      raise vErr;
    end;
    mWg.Add(1);
    TTask.Run(procedure
    begin
      try
        mTg.Update(mCtx.Token, DELEGATE_GID, vReader, mSubscribeTrigger);
      finally
        mWg.Done;
      end;
    end);

    mRw.Start;
  finally
    PostStart;
  end;
end;

procedure TConsensus.Stop;
var
  vErr: Exception;
begin
  if PreStop then
  try
    vErr := mRw.Stop;
    if vErr <> nil then
    begin
      mLog.Error('chain rw stop err', 'err', vErr.Message);
    end;
    mCancelFn;
    mClosed.Close;
    mWg.Wait;
  finally
    PostStop;
  end;
end;

function NewConsensus(ParaCh: IChain; ParaRollback: IChainRollback): IConsensus;
begin
  Result := TConsensus.Create(ParaCh, ParaRollback);
end;

end.
