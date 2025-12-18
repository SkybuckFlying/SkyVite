unit Producer.Worker;

interface

uses
  Common,
  Common.Types,
  Interfaces,
  Ledger.Consensus,
  Log15,
  Monitor,
  Producer.Face,
  Producer.Producer,
  Producer.Producer.Test,
  Producer.Tools,
  Producer.Worker.Test,
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils,
  Vendor.Github.Com.Hashicorp.GolangLru.2q,
  Vendor.Github.Com.Hashicorp.GolangLru.Arc,
  Vendor.Github.Com.Hashicorp.GolangLru.Doc,
  Vendor.Github.Com.Hashicorp.GolangLru.Lru,
  Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.Lru,
  Vendor.Github.Com.Hashicorp.GolangLru.Simplelru.LruInterface;

type
  IWorker = interface(IUnknown)
    ['{A6A4B6C2-4A93-4D6F-A2D4-3B8D1E4A3B3C}']
    function Init: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
    procedure ProduceSnapshot(const ParaE: TConsensusEvent);
    procedure GenAndInsert(const ParaE: TConsensusEvent);
  end;

  TWorker = class(TInterfacedObject, IWorker)
  private
    mProducerLifecycle: TProducerLifecycle;
    mTools: TTools;
    mCoinbase: IAccount;
    mMu: TCriticalSection;
    mWg: TCountdownEvent;
    mSeedCache: TDictionary<THash, UInt64>;
    mLog: ILogger;
    function RandomSeed: UInt64;
    function GetSeedByHash(const ParaHash: THash): UInt64;
    procedure StoreSeedHash(const ParaSeed: UInt64; const ParaHash: THash);
  public
    constructor Create(const ParaChain: TTools; const ParaCoinbase: IAccount);
    destructor Destroy; override;
    function Init: Boolean;
    function Start: Boolean;
    function Stop: Boolean;
    procedure ProduceSnapshot(const ParaE: TConsensusEvent);
    procedure GenAndInsert(const ParaE: TConsensusEvent);
  end;

function NewWorker(const ParaChain: TTools; const ParaCoinbase: IAccount): IWorker;

implementation

uses
  System.Threading;

var
  gLog: ILogger;

{ TWorker }

constructor TWorker.Create(const ParaChain: TTools; const ParaCoinbase: IAccount);
begin
  mProducerLifecycle := TProducerLifecycle.Create;
  mTools := ParaChain;
  mCoinbase := ParaCoinbase;
  mSeedCache := TDictionary<THash, UInt64>.Create;
  mLog := TLog15.New(['module', 'producer/worker']);
  mMu := TCriticalSection.Create;
  mWg := TCountdownEvent.Create(0);
end;

destructor TWorker.Destroy;
begin
  mProducerLifecycle.Free;
  mSeedCache.Free;
  mMu.Free;
  mWg.Free;
  inherited;
end;

function TWorker.Init: Boolean;
begin
  Result := False;
  if not mProducerLifecycle.PreInit then
  begin
    raise Exception.Create('pre init worker fail');
  end;
  try
    Result := True;
  finally
    mProducerLifecycle.PostInit;
  end;
end;

function TWorker.Start: Boolean;
begin
  Result := False;
  if not mProducerLifecycle.PreStart then
  begin
    raise Exception.Create('pre start fail');
  end;
  try
    Result := True;
  finally
    mProducerLifecycle.PostStart;
  end;
end;

function TWorker.Stop: Boolean;
begin
  Result := False;
  if not mProducerLifecycle.PreStop then
  begin
    raise Exception.Create('pre stop fail');
  end;
  try
    mWg.Wait;
    Result := True;
  finally
    mProducerLifecycle.PostStop;
  end;
end;

procedure TWorker.ProduceSnapshot(const ParaE: TConsensusEvent);
var
  vTmpE: TConsensusEvent;
begin
  if ParaE.Address <> mCoinbase.Address then
  begin
    gLog.Error('coinbase must be equal.', ['addr', ParaE.Address.ToString]);
    Exit;
  end;
  vTmpE := ParaE;
  TTask.Run(
    procedure
    begin
      GenAndInsert(vTmpE);
    end);
end;

procedure TWorker.GenAndInsert(const ParaE: TConsensusEvent);
var
  vTime: TDateTime;
  vSeed: UInt64;
  vBlock: ISnapshotBlock;
begin
  gLog.Info('genAndInsert start.', ['event', ParaE.ToString]);
  vTime := Now;
  try
    mWg.Add;
    try
      mMu.Enter;
      try
        mTools.mPool.LockInsert;
        try
          vSeed := RandomSeed;
          vBlock := mTools.GenerateSnapshot(ParaE, mCoinbase, vSeed, GetSeedByHash);
          if vBlock = nil then
          begin
            gLog.Error('produce snapshot block fail[generate].');
            Exit;
          end;
          if not mTools.InsertSnapshot(vBlock) then
          begin
            gLog.Error('produce snapshot block fail[insert].');
            Exit;
          end;
          StoreSeedHash(vSeed, vBlock.SeedHash);
        finally
          mTools.mPool.UnLockInsert;
        end;
      finally
        mMu.Leave;
      end;
    finally
      mWg.Signal;
    end;
  finally
    TMonitor.LogTime('producer', 'snapshotGenInsert', vTime);
    gLog.Info('genAndInsert end.', ['event', ParaE.ToString]);
  end;
end;

function TWorker.RandomSeed: UInt64;
begin
  Result := TRandom.NextUInt64;
end;

function TWorker.GetSeedByHash(const ParaHash: THash): UInt64;
begin
  if mSeedCache.TryGetValue(ParaHash, Result) then
  begin
    mLog.Info(Format('query seed, hash:%s, seed:%d', [ParaHash.ToString, Result]));
  end
  else
  begin
    Result := 0;
  end;
end;

procedure TWorker.StoreSeedHash(const ParaSeed: UInt64; const ParaHash: THash);
begin
  if (ParaSeed = 0) or (ParaHash.IsZero) then
  begin
    Exit;
  end;
  mLog.Info(Format('store seed, hash:%s, seed:%d', [ParaHash.ToString, ParaSeed]));
  mSeedCache.AddOrSetValue(ParaHash, ParaSeed);
end;

function NewWorker(const ParaChain: TTools; const ParaCoinbase: IAccount): IWorker;
begin
  Result := TWorker.Create(ParaChain, ParaCoinbase);
end;

initialization
  gLog := TLog15.New(['module', 'miner/worker']);
end.
