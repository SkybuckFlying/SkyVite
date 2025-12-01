unit manager;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.SyncObjs,
  Vite.Common, Vite.Ledger, Vite.Interfaces, Vite.Net, Vite.Producer, onroad.pool,
  Vite.Consensus, leveldb;

type
  TManager = class
  private
    FNet: INetReader;
    FProducer: IProducer;
    FCoinbase: IAccount;
    FPool: IPool;
    FChain: IChain;
    FSbpStatReader: ISBPStatReader;
    FContractWorkers: TDictionary<TGid, TContractWorker>;
    FNewContractListener: TDictionary<TGid, TContractReactFunc>;
    FNewSnapshotListener: TDictionary<TGid, TSnapshotEventReactFunc>;
    FOnRoadPools: TDictionary<TGid, IOnRoadPool>;
    FUnlockLid: Integer;
    FNetStateLid: Integer;
    FLastProducerAccEvent: PAccountStartEvent;
    FDb: TLevelDB;
    FLog: TLogger;
    procedure PrepareOnRoadPool(gid: TGid);
    procedure NetStateChangedFunc(state: TSyncState);
    procedure ProducerStartEventFunc(accEvent: IAccountEvent);
    procedure StopAllWorks;
    procedure ResumeContractWorks;
  public
    constructor Create(net: INetReader; pool: IPool; producer: IProducer; sbpStatReader: ISBPStatReader; account: IAccount);
    destructor Destroy; override;
    procedure Init(chain: IChain);
    procedure Start;
    procedure Stop;
    function Close: Boolean;
    function Chain: IChain;
    function Net: INetReader;
    function Producer: IProducer;
    function SbpStatReader: ISBPStatReader;
    function Info: TDictionary<string, TObject>;
  end;

implementation

{ TManager }

constructor TManager.Create(net: INetReader; pool: IPool; producer: IProducer; sbpStatReader: ISBPStatReader; account: IAccount);
begin
  inherited Create;
  FNet := net;
  FProducer := producer;
  FCoinbase := account;
  FPool := pool;
  FSbpStatReader := sbpStatReader;
  FContractWorkers := TDictionary<TGid, TContractWorker>.Create;
  FNewContractListener := TDictionary<TGid, TContractReactFunc>.Create;
  FNewSnapshotListener := TDictionary<TGid, TSnapshotEventReactFunc>.Create;
  FOnRoadPools := TDictionary<TGid, IOnRoadPool>.Create;
  FLog := TSlog.New('w', 'manager');
end;

destructor TManager.Destroy;
begin
  FContractWorkers.Free;
  FNewContractListener.Free;
  FNewSnapshotListener.Free;
  FOnRoadPools.Free;
  FDb.Free;
  inherited;
end;

procedure TManager.Init(chain: IChain);
var
  gid: TGid;
begin
  FChain := chain;
  for gid in DefaultContractGidList do
    PrepareOnRoadPool(gid);
end;

procedure TManager.Start;
begin
  FNetStateLid := FNet.SubscribeSyncStatus(NetStateChangedFunc);
  if FProducer <> nil then
    FProducer.SetAccountEventFunc(ProducerStartEventFunc);
  FChain.Register(Self);
end;

procedure TManager.Stop;
begin
  FLog.Info('Close');
  FNet.UnsubscribeSyncStatus(FNetStateLid);
  if FProducer <> nil then
    FProducer.SetAccountEventFunc(nil);
  FChain.UnRegister(Self);
  StopAllWorks;
  FLog.Info('Close end');
end;

function TManager.Close: Boolean;
begin
  FDb.Close;
  Result := True;
end;

procedure TManager.PrepareOnRoadPool(gid: TGid);
var
  db: TLevelDB;
  orPool: IOnRoadPool;
  exist: Boolean;
begin
  db := FChain.PrepareOnroadDb;
  FDb := db;
  exist := FOnRoadPools.TryGetValue(gid, orPool);
  FLog.Info('prepare OnRoadPool', 'gid', gid, 'exist', exist, 'orPool', orPool);
  if not exist or (orPool = nil) then
    FOnRoadPools.Add(gid, TContractOnRoadPool.Create(gid, FChain, db));
end;

procedure TManager.NetStateChangedFunc(state: TSyncState);
begin
  FLog.Info('receive chain net event', 'state_bak', state);
  TThread.CreateAnonymousThread(procedure
  begin
    if state = ssSyncDone then
      ResumeContractWorks
    else
      StopAllWorks;
  end).Start;
end;

procedure TManager.ProducerStartEventFunc(accEvent: IAccountEvent);
var
  netstate: TSyncState;
  event: TAccountStartEvent;
  w: TContractWorker;
  found: Boolean;
  nowTime: TDateTime;
begin
  netstate := FNet.SyncState;
  FLog.Info('producerStartEventFunc receive event', 'netstate', netstate);
  if netstate <> ssSyncDone then
  begin
    FLog.Error(ErrNotSyncDone.Message);
    Exit;
  end;

  if not Supports(accEvent, IAccountStartEvent, event) then
  begin
    FLog.Info('producerStartEventFunc not support this event');
    Exit;
  end;

  if (FCoinbase = nil) or (FCoinbase.Address <> event.Address) then
  begin
    FLog.Error('receive chain right event but address locked', 'event', event);
    Exit;
  end;

  FLastProducerAccEvent := @event;

  found := FContractWorkers.TryGetValue(event.Gid, w);
  if not found then
  begin
    w := TContractWorker.Create(Self);
    FContractWorkers.Add(event.Gid, w);
  end;

  nowTime := Now;
  if (nowTime > event.Stime) and (nowTime < event.Etime) then
  begin
    w.Start(event);
    TTask.Run(procedure
    begin
      Sleep(Round((event.Etime - nowTime) * MSecsPerDay));
      w.Stop;
    end);
  end
  else
    w.Stop;
end;

procedure TManager.StopAllWorks;
var
  wg: TCountdownEvent;
  v: TContractWorker;
begin
  FLog.Info('stopAllWorks called');
  wg := TCountdownEvent.Create(FContractWorkers.Count);
  for v in FContractWorkers.Values do
  begin
    TThread.CreateAnonymousThread(procedure
    begin
      v.Stop;
      wg.Signal;
    end).Start;
  end;
  wg.Wait;
  wg.Free;
  FLog.Info('stopAllWorks end');
end;

procedure TManager.ResumeContractWorks;
var
  nowTime: TDateTime;
  cw: TContractWorker;
  ok: Boolean;
begin
  FLog.Info('resumeContractWorks');
  if FLastProducerAccEvent <> nil then
  begin
    nowTime := Now;
    if (nowTime > FLastProducerAccEvent.Stime) and (nowTime < FLastProducerAccEvent.Etime) then
    begin
      ok := FContractWorkers.TryGetValue(FLastProducerAccEvent.Gid, cw);
      if ok then
      begin
        FLog.Info('resumeContractWorks found an cw need to resume', 'gid', FLastProducerAccEvent.Gid);
        cw.Start(FLastProducerAccEvent^);
        TTask.Run(procedure
        begin
          Sleep(Round((FLastProducerAccEvent.Etime - nowTime) * MSecsPerDay));
          cw.Stop;
        end);
      end;
    end;
  end;
  FLog.Info('end resumeContractWorks');
end;

function TManager.Chain: IChain;
begin
  Result := FChain;
end;

function TManager.Net: INetReader;
begin
  Result := FNet;
end;

function TManager.Producer: IProducer;
begin
  Result := FProducer;
end;

function TManager.SbpStatReader: ISBPStatReader;
begin
  Result := FSbpStatReader;
end;

function TManager.Info: TDictionary<string, TObject>;
var
  k: TGid;
  v: IOnRoadPool;
begin
  Result := TDictionary<string, TObject>.Create;
  for k in FOnRoadPools.Keys do
  begin
    v := FOnRoadPools[k];
    Result.Add(k.ToString, v.Info);
  end;
end;

end.
