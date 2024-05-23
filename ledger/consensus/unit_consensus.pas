unit unit_consensus;

// direct

interface

uses
  SysUtils, Classes, DateUtils, common, types, interfaces, core, cdb, lock, log15;

type
  Event = record
    Gid: types.Gid;
    Address: types.Address;
	Stime: TDateTime;
    Etime: TDateTime;
    Timestamp: TDateTime;
	VoteTime: TDateTime;
    PeriodStime: TDateTime;
    PeriodEtime: TDateTime;
  end;

  ProducersEvent = record
    Addrs: array of types.Address;
    Index: UInt64;
    Gid: types.Gid;
  end;

  Subscriber = interface
    procedure Subscribe(gid: types.Gid; id: string; addr: types.Address; fn: TProc<Event>);
    procedure UnSubscribe(gid: types.Gid; id: string);
    procedure SubscribeProducers(gid: types.Gid; id: string; fn: TProc<ProducersEvent>);
    function TriggerMineEvent(addr: types.Address): Exception;
  end;

  Reader = interface
    function ReadByIndex(gid: types.Gid; index: UInt64): array of Event;
    function VoteTimeToIndex(gid: types.Gid; t2: TDateTime): UInt64;
    function VoteIndexToTime(gid: types.Gid; i: UInt64): TDateTime;
  end;

  APIReader = interface
    function ReadVoteMap(t: TDateTime): array of VoteDetails;
    function ReadSuccessRate(start, &end: UInt64): array of TMap<types.Address, cdb.Content>;
    function ReadByIndex(gid: types.Gid; index: UInt64): array of Event;
  end;

  Life = interface
    procedure Start;
    function Init(cfg: ConsensusCfg): Exception;
    procedure Stop;
  end;

  Consensus = interface
    function API: APIReader;
    function SBPReader: SBPStatReader;
  end;

  consensus = class(TInterfacedObject, Consensus, Subscriber, Reader, Life)
  private
    ConsensusCfg: ConsensusCfg;
    Subscriber: Subscriber;
    subscribeTrigger: subscribeTrigger;
    LifecycleStatus: LifecycleStatus;
    mLog: log15.Logger;
    genesis: TDateTime;
    rw: chainRw;
    rollback: lock.ChainRollback;
    snapshot: snapshotCs;
    contracts: contractsCs;
    dposWrapper: dposReader;
    api: APIReader;
    wg: TThread;
    closed: TEvent;
    ctx: TContext;
    cancelFn: TProc;
    tg: trigger;
  public
    function SBPReader: SBPStatReader;
    function API: APIReader;
    constructor Create(ch: Chain; rollback: lock.ChainRollback);
  end;

function NewConsensus(ch: Chain; rollback: lock.ChainRollback): Consensus;

implementation

function consensus.SBPReader: SBPStatReader;
begin
  Result := snapshot;
end;

function consensus.API: APIReader;
begin
  Result := api;
end;

constructor consensus.Create(ch: Chain; rollback: lock.ChainRollback);
var
  log: log15.Logger;
  rw: chainRw;
  sub: consensusSubscriber;
begin
  log := log15.New('module', 'consensus');
  rw := chainRw.Create(ch, log, rollback);
  sub := consensusSubscriber.Create;
  Self.rw := rw;
  Self.rollback := rollback;
  Self.mLog := log;
  Self.Subscriber := sub;
  Self.subscribeTrigger := sub;
  Self.snapshot := snapshotCs.Create(rw, mLog);
  Self.contracts := contractsCs.Create(rw, mLog);
  Self.dposWrapper := dposReader.Create(snapshot, contracts, mLog);
  Self.api := APISnapshot.Create(snapshot);
end;

function NewConsensus(ch: Chain; rollback: lock.ChainRollback): Consensus;
begin
  Result := consensus.Create(ch, rollback);
end;

end.

