unit Producer.Producer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  Common,
  Common.Types,
  Interfaces,
  Interfaces.Core,
  Ledger.Chain,
  Ledger.Consensus,
  Ledger.Pool,
  Log15,
  Net,
  Producer.Event,
  Producer.Face;

type
  ISnapshotChainRW = interface(IUnknown)
    ['{3515A534-1B3D-453B-9342-3A548758813A}']
    function WriteMiningBlock(const ParaBlock: ISnapshotBlock): Boolean;
  end;

  TProducerLifecycle = class(TLifecycleStatus)
  public
    function PreDestroy: Boolean;
    function PostDestroy: Boolean;
    function PreStart: Boolean;
    function PostStart: Boolean;
  end;

  TProducer = class(TInterfacedObject, IProducer)
  private
    mProducerLifecycle: TProducerLifecycle;
    mTools: ITools;
    mMining: Integer;
    mCoinbase: IAccount;
    mWorker: IWorker;
    mCs: IConsensusSubscriber;
    mSubscriber: INetSubscriber;
    mAccountFn: TAccountEventFunc;
    mSyncState: TSyncState;
    mNetSyncId: Integer;
    procedure ProducerContract(const ParaE: TConsensusEvent);
  public
    constructor Create(const ParaRW: IChain; const ParaSubscriber: INetSubscriber; const ParaCoinbase: IAccount;
      const ParaCs: IConsensusSubscriber; const ParaP: ISnapshotProducerWriter);
    destructor Destroy; override;
    function Init: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
    function SnapshotOnce: Boolean;
    procedure SetAccountEventFunc(const ParaAccountFn: TAccountEventFunc);
    function GetCoinBase: TAddress;
  end;

function NewProducer(const ParaRW: IChain; const ParaSubscriber: INetSubscriber; const ParaCoinbase: IAccount;
  const ParaCs: IConsensusSubscriber; const ParaP: ISnapshotProducerWriter): IProducer;

implementation

uses
  System.Threading;

var
  gLog: ILogger;

{ TProducerLifecycle }

function TProducerLifecycle.PreDestroy: Boolean;
begin
  Result := TInterlocked.CompareExchange(mStatus, 7, 6) = 6;
end;

function TProducerLifecycle.PostDestroy: Boolean;
begin
  Result := TInterlocked.CompareExchange(mStatus, 8, 7) = 7;
end;

function TProducerLifecycle.PreStart: Boolean;
begin
  Result := (TInterlocked.CompareExchange(mStatus, 3, 2) = 2) or
    (TInterlocked.CompareExchange(mStatus, 3, 6) = 6);
end;

function TProducerLifecycle.PostStart: Boolean;
begin
  Result := TInterlocked.CompareExchange(mStatus, 4, 3) = 3;
end;

{ TProducer }

constructor TProducer.Create(const ParaRW: IChain; const ParaSubscriber: INetSubscriber; const ParaCoinbase: IAccount;
  const ParaCs: IConsensusSubscriber; const ParaP: ISnapshotProducerWriter);
var
  vChain: IChainRw;
begin
  mProducerLifecycle := TProducerLifecycle.Create;
  vChain := NewChainRw(ParaRW, ParaP);
  mTools := vChain as ITools;
  mCoinbase := ParaCoinbase;
  mWorker := NewWorker(vChain, ParaCoinbase);
  mCs := ParaCs;
  mSubscriber := ParaSubscriber;
end;

destructor TProducer.Destroy;
begin
  mProducerLifecycle.Free;
  inherited;
end;

function TProducer.Init: Boolean;
begin
  Result := False;
  if not mProducerLifecycle.PreInit then
  begin
    raise Exception.Create('pre init fail');
  end;
  try
    if mWorker.Init then
    begin
      gLog.Info('init.');
      Result := True;
    end;
  finally
    mProducerLifecycle.PostInit;
  end;
end;

function TProducer.Start: Boolean;
var
  vSnapshotId, vContractId: string;
  vAddr: TAddress;
  vId: Integer;
begin
  Result := False;
  if not mProducerLifecycle.PreStart then
  begin
    raise Exception.Create('pre start fail');
  end;
  try
    if not mWorker.Start then
    begin
      Exit;
    end;
    if mCoinbase = nil then
    begin
      raise Exception.Create('coinbase must not be nil');
    end;

    vSnapshotId := mCoinbase.Address.ToHex + '_snapshot';
    vContractId := mCoinbase.Address.ToHex + '_contract';
    vAddr := mCoinbase.Address;

    mCs.Subscribe(SNAPSHOT_GID, vSnapshotId, @vAddr,
      procedure(const ParaE: TConsensusEvent)
      begin
        gLog.Info(Format('snapshot producer trigger. addr: %s, syncState: %d, e: %s',
          [mCoinbase.Address.ToString, Ord(mSyncState), ParaE.ToString]));
        if mSyncState = ssSyncDone then
        begin
          mWorker.ProduceSnapshot(ParaE);
        end;
      end);

    mCs.Subscribe(DELEGATE_GID, vContractId, @vAddr,
      procedure(const ParaE: TConsensusEvent)
      begin
        gLog.Info(Format('contract producer trigger. addr: %s, syncState: %d, e: %s',
          [mCoinbase.Address.ToString, Ord(mSyncState), ParaE.ToString]));
        if mSyncState = ssSyncDone then
        begin
          ProducerContract(ParaE);
        end;
      end);

    mSyncState := mSubscriber.SyncState;
    vId := mSubscriber.SubscribeSyncStatus(
      procedure(const ParaState: TSyncState)
      begin
        mSyncState := ParaState;
      end);
    mNetSyncId := vId;
    gLog.Info('started.');
    Result := True;
  finally
    mProducerLifecycle.PostStart;
  end;
end;

function TProducer.SnapshotOnce: Boolean;
var
  vTime: TDateTime;
  vEvent: TConsensusEvent;
begin
  vTime := Now;
  vEvent.Gid := SNAPSHOT_GID;
  vEvent.Address := mCoinbase.Address;
  vEvent.Stime := vTime;
  vEvent.Etime := vTime;
  vEvent.Timestamp := vTime;
  vEvent.VoteTime := vTime;
  vEvent.PeriodStime := vTime;
  vEvent.PeriodEtime := vTime;
  mWorker.GenAndInsert(vEvent);
  Result := True;
end;

function TProducer.Stop: Boolean;
var
  vSnapshotId, vContractId: string;
begin
  Result := False;
  if not mProducerLifecycle.PreStop then
  begin
    raise Exception.Create('pre stop fail');
  end;
  try
    vSnapshotId := mCoinbase.Address.ToHex + '_snapshot';
    vContractId := mCoinbase.Address.ToHex + '_contract';
    mCs.UnSubscribe(SNAPSHOT_GID, vSnapshotId);
    mCs.UnSubscribe(DELEGATE_GID, vContractId);
    mSubscriber.UnsubscribeSyncStatus(mNetSyncId);
    mNetSyncId := 0;
    Result := mWorker.Stop;
  finally
    mProducerLifecycle.PostStop;
  end;
end;

procedure TProducer.ProducerContract(const ParaE: TConsensusEvent);
var
  vFn: TAccountEventFunc;
  vHeader: ISnapshotBlock;
  vTmpEvent: TAccountStartEvent;
begin
  vFn := mAccountFn;
  if Assigned(vFn) then
  begin
    if not ParaE.Address.IsEqual(mCoinbase.Address) then
    begin
      gLog.Error(Format('coinbase can''t match. addr: %s, coinbase: %s',
        [ParaE.Address.ToString, mCoinbase.Address.ToString]));
      Exit;
    end;

    vHeader := mTools.Chain.GetLatestSnapshotBlock;
    if vHeader.Timestamp < ParaE.VoteTime then
    begin
      gLog.Error(Format('contract producer fail. snapshot is too lower. voteTime:%s, headerTime:%s, headerHeight:%d, headerHash:%s',
        [ParaE.VoteTime.ToString, vHeader.Timestamp.ToString, vHeader.Height, vHeader.Hash.ToString]));
      Exit;
    end;
    if mTools.CheckStableSnapshotChain(vHeader) <> nil then
    begin
      gLog.Error(Format('contract producer fail. snapshot is not stable version. voteTime:%s, startTime:%s, endTime:%s',
        [ParaE.VoteTime.ToString, ParaE.Stime.ToString, ParaE.Etime.ToString]));
      Exit;
    end;

    vTmpEvent.Gid := ParaE.Gid;
    vTmpEvent.Address := ParaE.Address;
    vTmpEvent.Stime := ParaE.Stime;
    vTmpEvent.Etime := ParaE.Etime;
    TTask.Run(
      procedure
      begin
        vFn(vTmpEvent);
      end);
  end;
end;

procedure TProducer.SetAccountEventFunc(const ParaAccountFn: TAccountEventFunc);
begin
  mAccountFn := ParaAccountFn;
end;

function TProducer.GetCoinBase: TAddress;
begin
  Result := mCoinbase.Address;
end;

function NewProducer(const ParaRW: IChain; const ParaSubscriber: INetSubscriber; const ParaCoinbase: IAccount;
  const ParaCs: IConsensusSubscriber; const ParaP: ISnapshotProducerWriter): IProducer;
begin
  Result := TProducer.Create(ParaRW, ParaSubscriber, ParaCoinbase, ParaCs, ParaP);
end;

initialization
  gLog := TLog15.New(['module', 'producer']);
end.
