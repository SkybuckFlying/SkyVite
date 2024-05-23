unit unit_pool;

interface

uses
  Classes, SysUtils, SyncObjs, Generics.Collections, Ledger, Verifier, Net;

type
  TBlockSource = (Local, RemoteBroadcast, RemoteFetch);

  TWriter = interface
    procedure AddDirectAccountBlock(address: TAddress; vmAccountBlock: TVmAccountBlock);
  end;

  TPipeline = interface
    procedure AddPipeline(reader: TChunkReader);
  end;

  TSnapshotProducerWriter = interface
    procedure AddDirectSnapshotBlock(block: TSnapShotBlock);
  end;

  TReader = interface
    function GetIrreversibleBlock: TSnapShotBlock;
  end;

  TDebug = interface
    function Info: TDictionary<string, TObject>;
    function AccountBlockInfo(addr: TAddress; hash: THash): TObject;
    function SnapshotBlockInfo(hash: THash): TObject;
    function Snapshot: TDictionary<string, TObject>;
    function SnapshotPendingNum: UInt64;
    function AccountPendingNum: TBigInteger;
    function Account(addr: TAddress): TDictionary<string, TObject>;
    function SnapshotChainDetail(chainID: string; height: UInt64): TDictionary<string, TObject>;
    function AccountChainDetail(addr: TAddress; chainID: string; height: UInt64): TDictionary<string, TObject>;
  end;

  TBlockPool = interface(TWriter, TReader, TSnapshotProducerWriter, TDebug, TPipeline)
	procedure Start;
    procedure Stop;
    procedure Init(s: ISyncer; accountV: IVerifier; sbpStatReader: ISBPStatReader);
  end;

  TPool = class(TInterfacedObject, TBlockPool)
  private
    FLock: TEasyImpl;
    FPendingSc: TSnapShotPool;
    FPendingAc: TDictionary<TAddress, TAccountPool>;
    FSync: ISyncer;
    FPipelines: TList<TChunkReader>;
    FBC: TChainDb;
    FSnapshotVerifier: ISnapshotVerifier;
    FAccountVerifier: IVerifier;
    FAccountSubID: Integer;
    FSnapshotSubID: Integer;
    FNewAccBlockCond: TCondTimer;
    FNewSnapshotBlockCond: TCondTimer;
    FWorker: TWorker;
    FVersion: TVersion;
    FRollbackVersion: TVersion;
    FClosed: TEvent;
    FWG: TWaitGroup;
    FLog: TLogger;
    FStat: TRecoverStat;
    FHashBlacklist: TBlacklist;
    FSBPStatReader: ISBPStatReader;
    FPrinter: TSnapShotPrinter;
  public
    procedure AddDirectAccountBlock(address: TAddress; vmAccountBlock: TVmAccountBlock);
    procedure AddPipeline(reader: TChunkReader);
    procedure AddDirectSnapshotBlock(block: TSnapShotBlock);
    function GetIrreversibleBlock: TSnapShotBlock;
    function Info: TDictionary<string, TObject>;
    function AccountBlockInfo(addr: TAddress; hash: THash): TObject;
    function SnapshotBlockInfo(hash: THash): TObject;
    function Snapshot: TDictionary<string, TObject>;
    function SnapshotPendingNum: UInt64;
    function AccountPendingNum: TBigInteger;
    function Account(addr: TAddress): TDictionary<string, TObject>;
    function SnapshotChainDetail(chainID: string; height: UInt64): TDictionary<string, TObject>;
    function AccountChainDetail(addr: TAddress; chainID: string; height: UInt64): TDictionary<string, TObject>;
    procedure Start;
    procedure Stop;
    procedure Init(s: ISyncer; accountV: IVerifier; sbpStatReader: ISBPStatReader);
  end;

function NewPool(bc: TChainDb): TBlockPool;

implementation

function NewPool(bc: TChainDb): TBlockPool;
var
  Self: TPool;
  err: Exception;
begin
  Self := TPool.Create;
  Self.FBC := bc;
  Self.FVersion := TVersion.Create;
  Self.FRollbackVersion := TVersion.Create;
  Self.FLog := TLogger.Create('module', 'pool');
  Self.FHashBlacklist, err := NewBlacklist;
  if err <> nil then
    raise err;
  Self.FNewAccBlockCond := TCondTimer.Create;
  Self.FNewSnapshotBlockCond := TCondTimer.Create;
  Self.FWorker := TWorker.Create;
  Result := Self;
end;

procedure TPool.Init(s: ISyncer; accountV: IVerifier; sbpStatReader: ISBPStatReader);
var
  snapshotPool: TSnapShotPool;
begin
  FSync := s;
  FPipelines := TList<TChunkReader>.Create;
  snapshotPool := TSnapShotPool.Create('snapshotPool', FVersion, FSnapshotVerifier, FSync, FBC, FHashBlacklist, FNewSnapshotBlockCond, FLog);
  snapshotPool.Init(FSync, FBC, FLog);
  FPendingSc := snapshotPool;
  FStat := TRecoverStat.Create;
  FStat.Init(10, 10 * 1000);
  FWorker.Init;
end;

procedure TPool.Start;
begin
  FLog.Info('pool start.');
  try
    FClosed := TEvent.Create;
    FAccountSubID := FSync.SubscribeAccountBlock(AddAccountBlock);
    FSnapshotSubID := FSync.SubscribeSnapshotBlock(AddSnapshotBlock);
    FPendingSc.Start;
    FNewSnapshotBlockCond.Start(30);
    FNewAccBlockCond.Start(40);
    FWorker.Closed := FClosed;
    FPrinter := TSnapShotPrinter.Create(FClosed, FSync);
    FBC.Register(FPrinter);
    TThread.CreateAnonymousThread(
      procedure
      begin
        FWorker.Work;
      end).Start;
    FPrinter.Start;
  except
	on E: Exception do
    begin
      FLog.Error('pool start error', 'err', E.Message);
    end;
  end;
  FLog.Info('pool started.');
end;

procedure TPool.Stop;
begin
  FLog.Info('pool stop.');
  try
    FBC.UnRegister(FPrinter);
    FSync.UnsubscribeAccountBlock(FAccountSubID);
    FAccountSubID := 0;
    FSync.UnsubscribeSnapshotBlock(FSnapshotSubID);
    FSnapshotSubID := 0;
    FPendingSc.Stop;
    FClosed.SetEvent;
	FNewAccBlockCond.Stop;
    FNewSnapshotBlockCond.Stop;
    FWG.WaitFor;
  except
    on E: Exception do
    begin
      FLog.Error('pool stop error', 'err', E.Message);
    end;
  end;
  FLog.Info('pool stopped.');
end;


type
  commonBlock = interface
    function Height: UInt64;
    function Hash: types.Hash;
    function PrevHash: types.Hash;
    function checkForkVersion: Boolean;
    procedure resetForkVersion;
    function forkVersion: UInt64;
    function Source: types.BlockSource;
    function Latency: TTimeSpan;
    function ShouldFetch: Boolean;
    function ReferHashes: TArray<types.Hash, types.Hash, types.Hash>;
  end;

  forkBlock = class(TInterfacedObject, commonBlock)
  private
    firstV: UInt64;
    v: common.Version;
    source: types.BlockSource;
    nTime: TDateTime;
  public
    constructor Create(v: common.Version; source: types.BlockSource);
    function forkVersion: UInt64;
    function checkForkVersion: Boolean;
    procedure resetForkVersion;
    function Latency: TTimeSpan;
    function ShouldFetch: Boolean;
    function Source: types.BlockSource;
  end;

  pool = class
  private
    lock: EasyImpl;
    pendingSc: snapshotPool;
    pendingAc: TDictionary<types.Address, accountPool>;
    sync: syncer;
    pipelines: TArray<net.ChunkReader>;
    bc: chainDb;
    snapshotVerifier: verifier.SnapshotVerifier;
    accountVerifier: verifier.Verifier;
    accountSubID: Integer;
    snapshotSubID: Integer;
    newAccBlockCond: common.CondTimer;
    newSnapshotBlockCond: common.CondTimer;
    worker: worker;
    version: common.Version;
    rollbackVersion: common.Version;
    closed: TEvent;
    wg: sync.WaitGroup;
    log: log15.Logger;
    stat: recoverStat;
    hashBlacklist: Blacklist;
    sbpStatReader: core.SBPStatReader;
    printer: snapshotPrinter;
  public
    function Snapshot: TDictionary<string, TObject>;
    function SnapshotPendingNum: UInt64;
    function AccountPendingNum: BigInteger;
    function Account(addr: types.Address): TDictionary<string, TObject>;
    function SnapshotChainDetail(chainID: string; height: UInt64): TDictionary<string, TObject>;
    function AccountChainDetail(addr: types.Address; chainID: string; height: UInt64): TDictionary<string, TObject>;
    constructor Create(bc: chainDb);
    procedure Init(s: syncer; accountV: verifier.Verifier; sbpStatReader: core.SBPStatReader);
    function Info: TDictionary<string, TObject>;
    function AccountBlockInfo(addr: types.Address; hash: types.Hash): TObject;
    function SnapshotBlockInfo(hash: types.Hash): TObject;
    procedure Start;
    procedure Stop;
    procedure AddSnapshotBlock(block: ledger.SnapshotBlock; source: types.BlockSource);
    function AddDirectSnapshotBlock(block: ledger.SnapshotBlock): Exception;
    procedure AddAccountBlock(address: types.Address; block: ledger.AccountBlock; source: types.BlockSource);
  end;

function newForkBlock(v: common.Version; source: types.BlockSource): forkBlock;
begin
  Result := forkBlock.Create(v, source);
end;

constructor forkBlock.Create(v: common.Version; source: types.BlockSource);
begin
  firstV := v.Val();
  Self.v := v;
  Self.source := source;
  nTime := Now;
end;

function forkBlock.forkVersion: UInt64;
begin
  Result := v.Val();
end;

function forkBlock.checkForkVersion: Boolean;
begin
  Result := firstV = v.Val();
end;

procedure forkBlock.resetForkVersion;
var
  val: UInt64;
begin
  val := v.Val();
  firstV := val;
end;

function forkBlock.Latency: TTimeSpan;
begin
  if Source = types.RemoteBroadcast then
    Result := Now - nTime
  else if Source = types.RemoteFetch then
    Result := Now - nTime
  else
	Result := TTimeSpan.Zero;
end;

function forkBlock.ShouldFetch: Boolean;
begin
  if Source <> types.RemoteBroadcast then
    Result := True
  else if Latency > TTimeSpan.FromMilliseconds(200) then
    Result := True
  else
    Result := False;
end;

function forkBlock.Source: types.BlockSource;
begin
  Result := source;
end;

function pool.Snapshot: TDictionary<string, TObject>;
begin
  Result := pendingSc.info;
end;

function pool.SnapshotPendingNum: UInt64;
begin
  Result := pendingSc.CurrentChain.Size;
end;

function pool.AccountPendingNum: BigInteger;
var
  result: BigInteger;
  p: accountPool;
  size: UInt64;
begin
  result := BigInteger.Zero;
  for v in pendingAc.Values do
  begin
    p := v;
    size := p.CurrentChain.Size;
    if size > 0 then
      result := result + BigInteger(size);
  end;
  Result := result;
end;

function pool.Account(addr: types.Address): TDictionary<string, TObject>;
begin
  Result := selfPendingAc(addr).info;
end;

function pool.SnapshotChainDetail(chainID: string; height: UInt64): TDictionary<string, TObject>;
begin
  Result := pendingSc.detailChain(chainID, height);
end;

function pool.AccountChainDetail(addr: types.Address; chainID: string; height: UInt64): TDictionary<string, TObject>;
begin
  Result := selfPendingAc(addr).detailChain(chainID, height);
end;

constructor pool.Create(bc: chainDb);
begin
  Self.bc := bc;
  version := common.Version.Create;
  rollbackVersion := common.Version.Create;
  log := log15.New('module', 'pool');
  hashBlacklist := NewBlacklist;
  newAccBlockCond := common.NewCondTimer;
  newSnapshotBlockCond := common.NewCondTimer;
  worker := worker.Create(Self);
end;

procedure pool.Init(s: syncer; accountV: verifier.Verifier; sbpStatReader: core.SBPStatReader);
begin
  sync := s;
  SetLength(pipelines, 1);
  pipelines[0] := s;
  pendingSc := snapshotPool.Create('snapshotPool', version, accountV, s, bc, hashBlacklist, newSnapshotBlockCond, log);
  pendingSc.init(newTools(s, bc), Self);
  accountVerifier := accountV;
  Self.sbpStatReader := sbpStatReader;
  stat := recoverStat.init(10, TTimeSpan.FromSeconds(10));
  worker.init;
end;

function pool.Info: TDictionary<string, TObject>;
var
  result: TDictionary<string, TObject>;
  accResult: TDictionary<types.Address, TObject>;
  accSize: Integer;
  k: types.Address;
  cp: accountPool;
begin
  result := TDictionary<string, TObject>.Create;
  result.Add('snapshot', pendingSc.info);
  accResult := TDictionary<types.Address, TObject>.Create;
  accSize := 0;
  for kv in pendingAc do
  begin
    k := kv.Key;
    cp := kv.Value;
    accResult.Add(k, cp.info);
    accSize := accSize + 1;
  end;
  result.Add('accounts', accResult);
  result.Add('accLen', accSize);
  Result := result;
end;

function pool.AccountBlockInfo(addr: types.Address; hash: types.Hash): TObject;
var
  b: TObject;
  s: ledger.AccountBlock;
  sb: accountPoolBlock;
begin
  b := selfPendingAc(addr).blockpool.sprint(hash);
  if b <> nil then
  begin
    sb := b;
    Result := sb.block;
    Exit;
  end;
  s := selfPendingAc(addr).blockpool.sprint(hash);
  if s <> nil then
  begin
    Result := s;
    Exit;
  end;
  Result := nil;
end;

function pool.SnapshotBlockInfo(hash: types.Hash): TObject;
var
  b: TObject;
  s: ledger.SnapshotBlock;
  sb: snapshotPoolBlock;
begin
  b := pendingSc.blockpool.sprint(hash);
  if b <> nil then
  begin
    sb := b;
    Result := sb.block;
    Exit;
  end;
  s := pendingSc.blockpool.sprint(hash);
  if s <> nil then
  begin
    Result := s;
    Exit;
  end;
  Result := nil;
end;

procedure pool.Start;
begin
  log.Info('pool start.');
  try
    closed := TEvent.Create;
    accountSubID := sync.SubscribeAccountBlock(AddAccountBlock);
    snapshotSubID := sync.SubscribeSnapshotBlock(AddSnapshotBlock);
    pendingSc.Start;
    newSnapshotBlockCond.Start(TTimeSpan.FromMilliseconds(30));
    newAccBlockCond.Start(TTimeSpan.FromMilliseconds(40));
    worker.closed := closed;
    printer := snapshotPrinter.Create(closed, sync);
    bc.Register(printer);
    TTask.Run(
      procedure
      begin
        worker.work;
      end
    );
    printer.start;
  except
    on E: Exception do
    begin
      log.Error('pool start error', 'err', E.Message);
      raise;
    end;
  end;
  log.Info('pool started.');
end;

procedure pool.Stop;
begin
  log.Info('pool stop.');
  try
    bc.UnRegister(printer);
    sync.UnsubscribeAccountBlock(accountSubID);
    accountSubID := 0;
    sync.UnsubscribeSnapshotBlock(snapshotSubID);
    snapshotSubID := 0;
    pendingSc.Stop;
    closed.SetEvent;
    newAccBlockCond.Stop;
    newSnapshotBlockCond.Stop;
    wg.WaitFor;
  except
    on E: Exception do
    begin
      log.Error('pool stop error', 'err', E.Message);
      raise;
    end;
  end;
  log.Info('pool stopped.');
end;

procedure pool.AddSnapshotBlock(block: ledger.SnapshotBlock; source: types.BlockSource);
begin
  log.Info('receive snapshot block from network. height:' + block.Height.ToString + ', hash:' + block.Hash.ToString + '.');
  if bc.IsGenesisSnapshotBlock(block.Hash) then
    Exit;
  try
    pendingSc.v.verifySnapshotData(block);
    pendingSc.addBlock(snapshotPoolBlock.Create(block, version, source));
    newSnapshotBlockCond.Broadcast;
    worker.bus.newSBlockEvent;
  except
    on E: Exception do
    begin
      log.Error('snapshot error', 'err', E.Message, 'height', block.Height, 'hash', block.Hash);
      raise;
    end;
  end;
end;

function pool.AddDirectSnapshotBlock(block: ledger.SnapshotBlock): Exception;
var
  cBlock: snapshotPoolBlock;
  abs: TDictionary<types.Address, ledger.AccountBlock>;
  k: types.Address;
  v: ledger.AccountBlock;
begin
  try
	version.Inc;
    pendingSc.v.verifySnapshotData(block);
    cBlock := snapshotPoolBlock.Create(block, version, types.Local);
    abs := pendingSc.AddDirectBlock(cBlock);
    pendingSc.checkCurrent;
    pendingSc.f.broadcastBlock(block);
    if (abs = nil) or (abs.Count = 0) then
      Exit;
    for kv in abs do
    begin
      k := kv.Key;
      v := kv.Value;
      selfPendingAc(k).rollbackCurrent(v);
      selfPendingAc(k).checkCurrent;
	end;
    Result := nil;
  except
    on E: Exception do
    begin
      Result := E;
      raise;
    end;
  end;
end;

procedure pool.AddAccountBlock(address: types.Address; block: ledger.AccountBlock; source: types.BlockSource);
begin
  log.Info(Format('receive account block from network. addr:%s, height:%d, hash:%s.', [address, block.Height, block.Hash]));
  if bc.IsGenesisAccountBlock(block.Hash) then
    Exit;
  try
    selfPendingAc(address).addBlock(accountPoolBlock.Create(block, nil, version, source));
    selfPendingAc(address).setCompactDirty(True);
    newAccBlockCond.Broadcast;
    worker.bus.newABlockEvent;
  except
    on E: Exception do
    begin
      log.Error('account block error', 'err', E.Message);
      raise;
	end;
  end;
end;

procedure TPool.AddDirectAccountBlock(address: TAddress; block: PVmAccountBlock);
begin
  log.Info(Format('receive account block from direct. addr:%s, height:%d, hash:%s.', [address, block.AccountBlock.Height, block.AccountBlock.Hash]));
  monitor.LogTime('pool', 'addDirectAccount', Now);
  RLockInsert;
  try
    RUnLockInsert;
  finally
    ac := selfPendingAc(address);
    err := ac.v.verifyAccountData(block.AccountBlock);
    if err <> nil then
    begin
      log.Error('account err', 'err', err, 'height', block.AccountBlock.Height, 'hash', block.AccountBlock.Hash, 'addr', address);
      Exit(err);
    end;
    cBlock := newAccountPoolBlock(block.AccountBlock, block.VmDb, pl.version, Local);
    err := ac.AddDirectBlocks(cBlock);
    if err <> nil then
    begin
      Exit(err);
    end;
    ac.f.broadcastBlock(block.AccountBlock);
  end;
end;

procedure TPool.AddAccountBlocks(address: TAddress; blocks: TArray<PLedgerAccountBlock>; source: TBlockSource);
var
  b: PLedgerAccountBlock;
begin
  monitor.LogTime('pool', 'addAccountArr', Now);
  for b in blocks do
  begin
    AddAccountBlock(address, b, source);
  end;
end;

procedure TPool.ForkAccounts(accounts: TDictionary<TAddress, TArray<TCommonBlock>>);
var
  k: TAddress;
  v: TArray<TCommonBlock>;
  err: Exception;
begin
  for k, v in accounts do
  begin
    err := selfPendingAc(k).rollbackCurrent(v);
    if err <> nil then
    begin
      Exit(err);
    end;
    selfPendingAc(k).checkCurrent();
  end;
end;

procedure TPool.ForkAccountTo(addr: TAddress; h: PHashHeight);
var
  this: TAccountPool;
  targetChain: TChain;
  cu: TChain;
  curTailHeight: UInt64;
  keyPoint: TChain;
  err: Exception;
begin
  this := selfPendingAc(addr);
  this.chainHeadMu.Lock;
  try
    this.chainTailMu.Lock;
    try
      targetChain := this.findInTree(h.Hash, h.Height);
      if targetChain = nil then
      begin
        log.Info(Format('CurrentModifyToEmpty', 'addr', addr, 'hash', h.Hash, 'height', h.Height, 'currentId', this.CurrentChain().ID(), 'Tail', this.CurrentChain().SprintTail(), 'Head', this.CurrentChain().SprintHead()));
        err := this.CurrentModifyToEmpty();
        Exit(err);
      end;
      if targetChain.ID() = this.CurrentChain().ID() then
      begin
        Exit(nil);
      end;
      cu := this.CurrentChain();
      curTailHeight, _ := cu.TailHH();
	  keyPoint, _, err := this.chainpool.tree.FindForkPointFromMain(targetChain);
      if err <> nil then
      begin
        Exit(err);
      end;
      if keyPoint = nil then
      begin
        Exit(Exception.Create(Format('forkAccountTo key point is nil, target:%s, current:%s, targetTail:%s, targetHead:%s, currentTail:%s, currentHead:%s', [targetChain.ID(), cu.ID(), targetChain.SprintTail(), targetChain.SprintHead(), cu.SprintTail(), cu.SprintHead()])));
      end;
      if keyPoint.Height() <= curTailHeight then
      begin
        log.Info(Format('RollbackAccountTo[2]', 'addr', addr, 'hash', h.Hash, 'height', h.Height, 'targetChain', targetChain.ID(), 'targetChainTail', targetChain.SprintTail(), 'targetChainHead', targetChain.SprintHead(), 'keyPoint', keyPoint.Height(), 'currentId', cu.ID(), 'Tail', cu.SprintTail(), 'Head', cu.SprintTail()));
        err := RollbackAccountTo(addr, keyPoint.Hash(), keyPoint.Height());
        if err <> nil then
		begin
          Exit(err);
        end;
      end;
      log.Info(Format('ForkAccountTo', 'addr', addr, 'hash', h.Hash, 'height', h.Height, 'targetChain', targetChain.ID(), 'targetChainTail', targetChain.SprintTail(), 'targetChainHead', targetChain.SprintHead(), 'currentId', cu.ID(), 'Tail', cu.SprintTail(), 'Head', cu.SprintHead()));
      err := this.CurrentModifyToChain(targetChain);
      Exit(err);
    finally
      this.chainTailMu.Unlock;
    end;
  finally
    this.chainHeadMu.Unlock;
  end;
end;

procedure TPool.RollbackAccountTo(addr: TAddress; hash: THash; height: UInt64);
var
  p: TAccountPool;
  snapshots: TArray<TSnapshot>;
  accounts: TDictionary<TAddress, TArray<TAccount>>;
  e: Exception;
  err: Exception;
begin
  p := selfPendingAc(addr);
  snapshots, accounts, e := p.rw.delToHeight(height);
  if e <> nil then
  begin
    Exit(e);
  end;
  err := pendingSc.rollbackCurrent(snapshots);
  if err <> nil then
  begin
    Exit(err);
  end;
  pendingSc.checkCurrent();
  for k, v in accounts do
  begin
    err := selfPendingAc(k).rollbackCurrent(v);
    if err <> nil then
    begin
      Exit(err);
    end;
    selfPendingAc(k).checkCurrent();
  end;
end;

function TPool.selfPendingAc(addr: TAddress): TAccountPool;
var
  chain: TObject;
  rw: TAccountCh;
  f: TAccountSyncer;
  v: TAccountVerifier;
  p: TAccountPool;
begin
  chain := pendingAc.Load(addr);
  if chain <> nil then
  begin
    Result := chain as TAccountPool;
    Exit;
  end;
  rw := TAccountCh.Create;
  rw.address := addr;
  rw.rw := bc;
  rw.version := version;
  rw.log := log.New('account', addr);
  f := TAccountSyncer.Create;
  f.address := addr;
  f.fetcher := sync;
  f.log := log.New;
  v := TAccountVerifier.Create;
  v.v := accountVerifier;
  v.log := log.New;
  p := TAccountPool.Create('accountChainPool-' + addr.Hex, rw, version, hashBlacklist, log);
  p.address := addr;
  p.Init(newTools(f, rw), self, v, f);
  chain := pendingAc.LoadOrStore(addr, p);
  Result := chain as TAccountPool;
end;

procedure TPool.destroyPendingAc(addr: TAddress);
begin
  pendingAc.Delete(addr);
end;

procedure TPool.broadcastUnConfirmedBlocks;
var
  blocks: TArray<TAccountBlock>;
  v: TAccountBlock;
begin
  blocks := bc.GetAllUnconfirmedBlocks();
  for v in blocks do
  begin
    log.Info(Format('broadcast unconfirmed blocks', 'address', v.AccountAddress, 'Height', v.Height, 'Hash', v.Hash));
  end;
  sync.BroadcastAccountBlocks(blocks);
end;

procedure TPool.delUseLessChains;
var
  info: TIrreversibleInfo;
  pendings: TArray<TAccountPool>;
  v: TAccountPool;
begin
  if sync.SyncState() <> net.Syncing then
  begin
    RLockInsert;
    try
      info := pendingSc.irreversible;
      delChainsForIrreversible(info);
      pendingSc.checkPool();
	  pendingSc.loopDelUselessChain();
      pendings := [];
      pendingAc.Range(
        function(key, value: TObject): Boolean
        begin
          v := value as TAccountPool;
          pendings := pendings + [v];
          Result := True;
        end
      );
      for v in pendings do
      begin
        v.loopDelUselessChain();
        v.checkPool();
	  end;
    finally
      RUnLockInsert;
    end;
  end;
end;

procedure TPool.destroyAccounts;
var
  destroyList: TArray<TAddress>;
  v: TAddress;
  accP: TAccountPool;
  byt: TBytes;
begin
  destroyList := [];
  pendingAc.Range(
    function(key, value: TObject): Boolean
    begin
      v := key as TAddress;
      accP := value as TAccountPool;
      if accP.shouldDestroy() then
      begin
        destroyList := destroyList + [v];
      end;
      Result := True;
    end
  );
  for v in destroyList do
  begin
    accP := selfPendingAc(v);
    byt, _ := accP.info().ToJSON;
    log.Warn(Format('destroy account pool', 'addr', v, 'Id', string(byt)));
    destroyPendingAc(v);
  end;
end;

procedure TPool.delChainsForIrreversible(info: TIrreversibleInfo);
var
  rollbackV: Integer;
begin
  rollbackV := rollbackVersion.Val();
  if (info = nil) or (info.point = nil) or (info.rollbackV <> rollbackV) then
  begin
    Exit;
  end;
  // todo
end;

function TPool.compact: Integer;
var
  sum: Integer;
begin
  sum := 0;
  sum := sum + accountsCompact(True);
  sum := sum + pendingSc.loopCompactSnapshot();
  Result := sum;
end;

function TPool.snapshotCompact: Integer;
begin
  Result := pendingSc.loopCompactSnapshot();
end;


type
  TPool = class
  private
    lock: EasyImpl;
    pendingSc: snapshotPool;
    pendingAc: sync.Map;
    sync: syncer;
    pipelines: array of ChunkReader;
    bc: chainDb;
    snapshotVerifier: SnapshotVerifier;
    accountVerifier: Verifier;
    accountSubID: Integer;
    snapshotSubID: Integer;
    newAccBlockCond: CondTimer;
    newSnapshotBlockCond: CondTimer;
    worker: worker;
    version: Version;
    rollbackVersion: Version;
    closed: array of struct;
    wg: sync.WaitGroup;
    log: Logger;
    stat: recoverStat;
    hashBlacklist: Blacklist;
    sbpStatReader: SBPStatReader;
    printer: snapshotPrinter;
  public
    function accountsCompact(filterDirty: Boolean): Integer;
    function checkBlock(block: snapshotPoolBlock): Boolean;
    function realSnapshotHeight(fc: Branch): UInt64;
    function fetchForSnapshot(fc: Branch): Error;
    procedure snapshotPendingFix(p: Batch; snapshot: HashHeight; pending: snapshotPending);
    procedure fetchAccounts(accounts: map[Address]HashHeight; sHeight: UInt64; sHash: Hash);
    procedure forkAccountsFor(accounts: map[Address]HashHeight; snapshot: HashHeight);
  end;

function TPool.accountsCompact(filterDirty: Boolean): Integer;
var
  sum: Integer;
  pendings: array of accountPool;
  p: accountPool;
begin
  sum := 0;
  pendingAc.Range(
    function(_, v: interface): Boolean
    begin
      p := v as accountPool;
      if filterDirty and p.compactDirty then
      begin
        SetLength(pendings, Length(pendings) + 1);
        pendings[High(pendings)] := p;
        p.setCompactDirty(False);
      end
      else if not filterDirty then
      begin
        SetLength(pendings, Length(pendings) + 1);
        pendings[High(pendings)] := p;
      end;
      Result := True;
    end
  );
  if Length(pendings) > 0 then
  begin
    monitor.LogEventNum('pool', 'AccountsCompact', Length(pendings));
    for p in pendings do
    begin
      log.Debug('account compact', 'addr', p.address, 'filterDirty', filterDirty);
      sum := sum + p.Compact();
    end;
  end;
  Result := sum;
end;

function TPool.checkBlock(block: snapshotPoolBlock): Boolean;
var
  fail: Boolean;
  k: Address;
  v: SnapshotContent;
  ac: accountPool;
  fc: TreeDisk;
begin
  fail := block.failStat.isFail();
  if fail then
    Exit(False);
  if hashBlacklist.Exists(block.Hash()) then
    Exit(False);
  Result := True;
  for k, v in block.block.SnapshotContent do
  begin
    ac := selfPendingAc(k);
    fc := ac.findInTreeDisk(v.Hash, v.Height, True);
    if fc = nil then
    begin
      Result := False;
      if ac.findInPool(v.Hash, v.Height) then
        Continue;
      if block.ShouldFetch() then
        ac.f.fetchBySnapshot(ledger.HashHeight(Hash: v.Hash, Height: v.Height), k, 1, block.Height(), block.Hash());
    end;
  end;
end;

function TPool.realSnapshotHeight(fc: Branch): UInt64;
var
  h: UInt64;
  b: snapshotPoolBlock;
  now: TDateTime;
begin
  h := fc.TailHH();
  while True do
  begin
    b := fc.GetKnot(h + 1, False) as snapshotPoolBlock;
    if b = nil then
      Exit(h);
    now := Now;
    if now > b.lastCheckTime + 5 * Second then
    begin
      b.lastCheckTime := now;
      b.checkResult := checkBlock(b);
    end;
    if not b.checkResult then
      Exit(h);
    h := h + 1;
  end;
end;

function TPool.fetchForSnapshot(fc: Branch): Error;
var
  reqs: array of fetchRequest;
  j: Integer;
  tailHeight, headHeight: UInt64;
  headHash: Hash;
  addrM: map[Address]HashHeight;
  i: UInt64;
  b: snapshotPoolBlock;
  sb: snapshotPoolBlock;
  k: Address;
  v: HashHeight;
begin
  j := 0;
  tailHeight := fc.TailHH();
  headHeight := fc.HeadHH();
  headHash := fc.HeadHH();
  addrM := map[Address]HashHeight;
  for i := tailHeight + 1 to headHeight do
  begin
    b := fc.GetKnot(i, False) as snapshotPoolBlock;
    if b = nil then
      Continue;
    sb := b;
    if not sb.ShouldFetch() then
      Continue;
    for k, v in sb.block.SnapshotContent do
    begin
      if k in addrM then
      begin
        if addrM[k].Height < v.Height then
        begin
          addrM[k].Hash := v.Hash;
          addrM[k].Height := v.Height;
        end;
      end
      else
      begin
        addrM[k] := v;
      end;
    end;
  end;
  for k, v in addrM do
  begin
    if v.chain = nil then
      Continue;
    ac := selfPendingAc(v.chain);
    if ac.findInPool(v.hash, v.accHeight) then
      Continue;
    fc := ac.findInTreeDisk(v.hash, v.accHeight, True);
    if fc = nil then
      ac.f.fetchBySnapshot(ledger.HashHeight(Hash: v.hash, Height: v.accHeight), v.chain, 1, v.snapshotHeight, v.snapshotHash);
  end;
  Result := nil;
end;

procedure TPool.snapshotPendingFix(p: Batch; snapshot: HashHeight; pending: snapshotPending);
var
  accounts: map[Address]HashHeight;
  k: Address;
  account: HashHeight;
  this: accountPool;
  hashH: HashHeight;
begin
  if (pending.snapshot <> nil) and pending.snapshot.ShouldFetch() then
    fetchAccounts(pending.addrM, snapshot.Height, snapshot.Hash);
  LockInsert();
  try
    if p.Version() <> version.Val() then
    begin
      log.Warn('new version happened.');
      Exit;
    end;
    accounts := map[Address]HashHeight;
    for k, account in pending.addrM do
    begin
      log.Debug('db for account.', 'addr', k.String(), 'height', account.Height, 'hash', account.Hash, 'sbHash', snapshot.Hash, 'sbHeight', snapshot.Height);
      this := selfPendingAc(k);
      hashH := this.pendingAccountTo(account, account.Height);
      if hashH <> nil then
        accounts[k] := account;
    end;
    if Length(accounts) > 0 then
    begin
      monitor.LogEventNum('pool', 'snapshotPendingFork', Length(accounts));
      forkAccountsFor(accounts, snapshot);
    end;
  finally
    UnLockInsert();
  end;
end;

procedure TPool.fetchAccounts(accounts: map[Address]HashHeight; sHeight: UInt64; sHash: Hash);
var
  addr: Address;
  hashH: HashHeight;
  ac: accountPool;
  head: UInt64;
  u: UInt64;
begin
  for addr, hashH in accounts do
  begin
    ac := selfPendingAc(addr);
    if not ac.existInPool(hashH.Hash) then
    begin
      head := ac.chainpool.diskChain.HeadHH();
      u := 10;
      if hashH.Height > head then
        u := hashH.Height - head;
      ac.f.fetchBySnapshot(hashH, addr, u, sHeight, sHash);
    end;
  end;
end;

procedure TPool.forkAccountsFor(accounts: map[Address]HashHeight; snapshot: HashHeight);
var
  k: Address;
  v: HashHeight;
  err: Error;
begin
  for k, v in accounts do
  begin
    log.Debug('forkAccounts', 'Addr', k.String(), 'Height', v.Height, 'Hash', v.Hash);
    err := ForkAccountTo(k, v);
    if err <> nil then
    begin
      log.Error('forkaccountTo err', 'err', err);
      Sleep(Second);
      raise Exception.CreateFmt('snapshot:%s-%d', [snapshot.Hash, snapshot.Height]);
    end;
  end;
  version.Inc();
end;

function failStat.init(d: TDateTime): failStat;
begin
  timeThreshold := d;
  Result := Self;
end;

function failStat.inc(): Boolean;
var
  update: TDateTime;
  now: TDateTime;
begin
  update := Self.update;
  if update <> 0 then
  begin
    now := Now;
    if now - update > timeThreshold then
    begin
      clear();
      Result := False;
      Exit;
    end;
  end;
  if first = 0 then
    first := Now;
  update := Now;
  Self.update := update;
  if update - first > timeThreshold then
  begin
    Result := False;
    Exit;
  end;
  Result := True;
end;

function failStat.isFail(): Boolean;
var
  first: TDateTime;
  update: TDateTime;
begin
  first := Self.first;
  if first = 0 then
  begin
    Result := False;
    Exit;
  end;
  update := Self.update;
  if update = 0 then
  begin
    Result := False;
    Exit;
  end;
  if Now - update > 10 * timeThreshold then
  begin
    clear();
    Result := False;
    Exit;
  end;
  if update - first > timeThreshold then
    Result := True
  else
    Result := False;
end;

procedure failStat.clear();
begin
  first := 0;
  update := 0;
end;

function recoverStat.init(t: Integer; d: TDateTime): recoverStat;
begin
  num := 0;
  updateTime := Now;
  threshold := t;
  timeThreshold := d;
  Result := Self;
end;

function recoverStat.reset(): recoverStat;
begin
  num := 0;
  updateTime := Now;
  Result := Self;
end;

function recoverStat.inc(): Boolean;
begin
  AtomicIncrement(num);
  if Now - updateTime > timeThreshold then
  begin
    updateTime := Now;
    AtomicExchange(num, 0);
  end
  else
  begin
    if num > threshold then
    begin
      Result := False;
      Exit;
    end;
  end;
  Result := True;
end;



end.

