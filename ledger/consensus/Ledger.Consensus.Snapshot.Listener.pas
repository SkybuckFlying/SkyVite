unit consensus.snapshot_listener;

interface

uses
  consensus,
  Ledger.Consensus.API,
  Ledger.Consensus.Chain.Rw,
  Ledger.Consensus.Chain.Rw.Test,
  Ledger.Consensus.Config,
  Ledger.Consensus.Consensus,
  Ledger.Consensus.Consensus.Contract,
  Ledger.Consensus.Consensus.Contract.Dpos,
  Ledger.Consensus.Consensus.Contract.Dpos.Test,
  Ledger.Consensus.Consensus.Event,
  Ledger.Consensus.Consensus.Impl,
  Ledger.Consensus.Consensus.Point.Array,
  Ledger.Consensus.Consensus.Point.Array.Test,
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Simple.Test,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.Dpos,
  Ledger.Consensus.Mock.Ch,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  System.Classes,
  System.Json,
  System.SysUtils,
  Vite.Core,
  Vite.Interfaces;

type
  TSnapshotListener = class(TInterfacedObject, IEventListener)
  private
    FConsensus: TConsensus;
  public
    constructor Create(AConsensus: TConsensus);
    procedure OnChainGC(Start, &End: TSnapshotBlock);
    procedure PrepareInsertAccountBlocks(const Blocks: TArray<IVmAccountBlock>);
    procedure InsertAccountBlocks(const Blocks: TArray<IVmAccountBlock>);
    procedure PrepareInsertSnapshotBlocks(const Chunks: TArray<TSnapshotChunk>);
    procedure InsertSnapshotBlocks(const Chunks: TArray<TSnapshotChunk>);
    procedure PrepareDeleteAccountBlocks(const Blocks: TArray<TAccountBlock>);
    procedure DeleteAccountBlocks(const Blocks: TArray<TAccountBlock>);
    procedure PrepareDeleteSnapshotBlocks(const Chunks: TArray<TSnapshotChunk>);
    procedure DeleteSnapshotBlocks(const Chunks: TArray<TSnapshotChunk>);
  end;

implementation

{ TSnapshotListener }

constructor TSnapshotListener.Create(AConsensus: TConsensus);
begin
  FConsensus := AConsensus;
end;

procedure TSnapshotListener.OnChainGC(Start, &End: TSnapshotBlock);
var
  Stime, Etime: TDateTime;
  SIndex, EIndex, I: UInt64;
  Day: TPoint;
  Byt: TBytes;
begin
  if (Start = nil) or (&End = nil) then
    raise Exception.Create(Format('start[%s] or end[%s] is nil.', [BoolToStr(Start = nil, True), BoolToStr(&End = nil, True)]));

  Stime := Start.Timestamp;
  Etime := &End.Timestamp;

  SIndex := FConsensus.Rw.DayPoints.Time2Index(Stime);
  EIndex := FConsensus.Rw.DayPoints.Time2Index(Etime);

  for I := SIndex to EIndex do
  begin
    try
      Day := FConsensus.Rw.DayPoints.GetByIndex(I);
      Byt := TEncoding.UTF8.GetBytes(TJson.ObjectToJsonString(Day.ToJsonObject));
      FConsensus.MLog.Info(Format('reload day[%d] stats for chain gc. %s', [I, TEncoding.UTF8.GetString(Byt)]));
    except
      on E: Exception do
        raise Exception.Create(Format('load day index[%d] fail. %s', [I, E.Message]));
    end;
  end;
end;

procedure TSnapshotListener.PrepareInsertAccountBlocks(const Blocks: TArray<IVmAccountBlock>);
begin
  // ignore
end;

procedure TSnapshotListener.InsertAccountBlocks(const Blocks: TArray<IVmAccountBlock>);
begin
  // ignore
end;

procedure TSnapshotListener.PrepareInsertSnapshotBlocks(const Chunks: TArray<TSnapshotChunk>);
begin
  // ignore
end;

procedure TSnapshotListener.InsertSnapshotBlocks(const Chunks: TArray<TSnapshotChunk>);
var
  V: TSnapshotChunk;
  Block: TSnapshotBlock;
  BTime: TDateTime;
  Index: UInt64;
  Stime, Etime: TDateTime;
  SnapshotBlock: TSnapshotBlock;
begin
  for V in Chunks do
  begin
    Block := V.SnapshotBlock;
    if Block = nil then
      Continue;
    BTime := Block.Timestamp;
    Index := FConsensus.Snapshot.Time2Index(BTime);
    Stime, Etime := FConsensus.Snapshot.Index2Time(Index);
    if Stime = BTime then
    begin
      try
        SnapshotBlock := FConsensus.Rw.Rw.GetSnapshotBlockByHeight(Block.Height - 1);
        FConsensus.Snapshot.TriggerLoad(SnapshotBlock);
      except
        on E: Exception do
          FConsensus.MLog.Error('can''t get block', 'height', Block.Height - 1);
      end;
    end;
  end;
end;

procedure TSnapshotListener.PrepareDeleteAccountBlocks(const Blocks: TArray<TAccountBlock>);
begin
  // ignore
end;

procedure TSnapshotListener.DeleteAccountBlocks(const Blocks: TArray<TAccountBlock>);
begin
  // ignore
end;

procedure TSnapshotListener.PrepareDeleteSnapshotBlocks(const Chunks: TArray<TSnapshotChunk>);
begin
  // ignore
end;

procedure TSnapshotListener.DeleteSnapshotBlocks(const Chunks: TArray<TSnapshotChunk>);
begin
  // ignore
end;

end.
