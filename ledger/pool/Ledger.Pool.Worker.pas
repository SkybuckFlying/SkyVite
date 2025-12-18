unit Ledger.Pool.Worker;

interface

uses
  Common,
  Ledger.Pool.Account.Pool,
  Ledger.Pool.Bc.Pool,
  Ledger.Pool.Blacklist,
  Ledger.Pool.Blacklist.Test,
  Ledger.Pool.Branch.Chain,
  Ledger.Pool.Chain.Pool,
  Ledger.Pool.Chain.Pool.Test,
  Ledger.Pool.Context,
  Ledger.Pool.Face,
  Ledger.Pool.Mock.Common.Block,
  Ledger.Pool.Pipeline.Pool,
  Ledger.Pool.Pool,
  Ledger.Pool.Pool.Batch,
  Ledger.Pool.Pool.Batch.Chunk,
  Ledger.Pool.Pool.Batch.Fork,
  Ledger.Pool.Pool.Fork.Checker,
  Ledger.Pool.Pool.Fork.Checker.Test,
  Ledger.Pool.Snapshot.Listener,
  Ledger.Pool.Snapshot.Pool,
  Ledger.Pool.Snapshot.Pool.Test,
  Ledger.Pool.Tools,
  Ledger.Pool.Tools.Chain,
  Ledger.Pool.Tools.Fetcher,
  Ledger.Pool.Tools.Verifier,
  System.SysUtils System.Classes;

type
  TPoolEventBus = class
  public
    SnapshotForkChecker: TThread;
    AccountCompactT: TThread;
    SnapshotCompactT: TThread;
    BroadcasterT: TThread;
    ClearT: TThread;
    AccDestroyT: TThread;
    IrreversibleT: TThread;
    AccContext: TPoolContext;
    SnapshotContext: TPoolContext;
    Wait: TCondTimer;
    constructor Create;
    destructor Destroy; override;
    procedure NewABlockEvent;
    procedure NewSBlockEvent;
  end;

  TWorker = class(TThread)
  private
    FP: TPool;
    FBus: TPoolEventBus;
  protected
    procedure Execute; override;
  public
    constructor Create(APool: TPool);
    destructor Destroy; override;
    procedure Init;
  end;

implementation

uses
  net.interface;

{ TPoolEventBus }

constructor TPoolEventBus.Create;
begin
  inherited;
  AccContext := TPoolContext.Create;
  SnapshotContext := TPoolContext.Create;
  Wait := TCondTimer.Create;
end;

destructor TPoolEventBus.Destroy;
begin
  AccContext.Free;
  SnapshotContext.Free;
  Wait.Free;
  inherited;
end;

procedure TPoolEventBus.NewABlockEvent;
begin
  AccContext.SetCompactDirty(True);
  Wait.Signal;
end;

procedure TPoolEventBus.NewSBlockEvent;
begin
  SnapshotContext.SetCompactDirty(True);
  Wait.Signal;
end;

{ TWorker }

constructor TWorker.Create(APool: TPool);
begin
  inherited Create(False);
  FP := APool;
end;

destructor TWorker.Destroy;
begin
  FBus.Free;
  inherited;
end;

procedure TWorker.Init;
begin
  FBus := TPoolEventBus.Create;
  FBus.SnapshotForkChecker := TThread.CreateAnonymousThread(procedure
    begin
      while not Terminated do
      begin
        Sleep(2000);
        FP.CheckFork;
      end;
    end);
  FBus.BroadcasterT := TThread.CreateAnonymousThread(procedure
    begin
      while not Terminated do
      begin
        Sleep(30000);
        FP.BroadcastUnConfirmedBlocks;
      end;
    end);
  FBus.ClearT := TThread.CreateAnonymousThread(procedure
    begin
      while not Terminated do
      begin
        Sleep(60000);
        FP.DelUseLessChains;
      end;
    end);
  FBus.AccDestroyT := TThread.CreateAnonymousThread(procedure
    begin
      while not Terminated do
      begin
        Sleep(600000);
        FP.DestroyAccounts;
      end;
    end);
  FBus.IrreversibleT := TThread.CreateAnonymousThread(procedure
    begin
      while not Terminated do
      begin
        Sleep(180000);
        FP.UpdateIrreversibleBlock;
      end;
    end);
  FBus.AccountCompactT := TThread.CreateAnonymousThread(procedure
    begin
      while not Terminated do
      begin
        Sleep(6000);
        FP.AccountsCompact(False);
      end;
    end);
  FBus.SnapshotCompactT := TThread.CreateAnonymousThread(procedure
    begin
      while not Terminated do
      begin
        Sleep(1000);
        FP.SnapshotCompact;
      end;
    end);
end;

procedure TWorker.Execute;
var
  vSum: Integer;
  vPipeline: IChunkReader;
  vResult: Boolean;
begin
  FBus.Wait.Start(40);
  try
    while not Terminated do
    begin
      vSum := 0;
      if FBus.AccContext.CompactDirty then
      begin
        FP.Log.Debug('account compacts');
        FBus.AccContext.SetCompactDirty(False);
        vSum := vSum + FP.AccountsCompact(True);
      end;

      if FBus.SnapshotContext.CompactDirty then
      begin
        FBus.SnapshotContext.SetCompactDirty(False);
        vSum := vSum + FP.SnapshotCompact;
      end;

      // Simplified logic for timers
      // In a real scenario, a more sophisticated event handling would be needed

      vResult := False;
      for vPipeline in FP.Pipelines do
      begin
        vResult := FP.InsertFromChunksReader(vPipeline);
        if vResult then
          Break;
      end;
      if vResult then
        Continue;

      if (vSum > 0) or (Random(10) > 6) then
      begin
        FP.Insert;
        Continue;
      end;

      if FBus.AccContext.CompactDirty or FBus.SnapshotContext.CompactDirty then
        Continue;

      FBus.Wait.Wait;
    end;
  finally
    FBus.Wait.Stop;
  end;
end;

end.
