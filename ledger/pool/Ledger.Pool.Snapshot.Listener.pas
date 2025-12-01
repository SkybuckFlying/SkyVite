unit Ledger.Pool.Snapshot.Listener;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Interfaces.Core,
  net.interface,
  GoToDelphi.Helpers.TChannel;

type
  TSnapshotPrinter = class(TThread)
  private
    FChunks: TChannel<ISnapshotChunk>;
    FSnapshots: TChannel<ISnapshotBlock>;
    FSync: ISyncer;
  protected
    procedure Execute; override;
  public
    constructor Create(ASync: ISyncer);
    procedure Stop;
    procedure PrepareInsertAccountBlocks(blocks: TArray<IVmAccountBlock>);
    procedure InsertAccountBlocks(blocks: TArray<IVmAccountBlock>);
    procedure PrepareInsertSnapshotBlocks(chunks: TArray<ISnapshotChunk>);
    procedure InsertSnapshotBlocks(chunks: TArray<ISnapshotChunk>);
    procedure PrepareDeleteAccountBlocks(blocks: TArray<IAccountBlock>);
    procedure DeleteAccountBlocks(blocks: TArray<IAccountBlock>);
    procedure PrepareDeleteSnapshotBlocks(chunks: TArray<ISnapshotChunk>);
    procedure DeleteSnapshotBlocks(chunks: TArray<ISnapshotChunk>);
  end;

implementation

uses
  System.DateUtils;

{ TSnapshotPrinter }

constructor TSnapshotPrinter.Create(ASync: ISyncer);
begin
  inherited Create(False);
  FChunks := TChannel<ISnapshotChunk>.Create(10000);
  FSnapshots := TChannel<ISnapshotBlock>.Create(100);
  FSync := ASync;
end;

procedure TSnapshotPrinter.Stop;
begin
  Terminate;
end;

procedure TSnapshotPrinter.Execute;
var
  vStatsTicker: TThread;
  vSBlock: ISnapshotBlock;
  vChunk: ISnapshotChunk;
  vContent: TArray<ISnapshotChunk>;
begin
  vStatsTicker := TThread.CreateAnonymousThread(
    procedure
    begin
      while not Terminated do
      begin
        Sleep(10000);
        SetLength(vContent, 0);
        while FChunks.TryReceive(vChunk) do
          vContent := vContent + [vChunk];
        // printStats(vContent);
      end;
    end);
  vStatsTicker.Start;

  while not Terminated do
  begin
    if FSnapshots.TryReceive(vSBlock) then
    begin
      // printSnapshot(vSBlock);
    end;
    Sleep(10); // Prevent busy waiting
  end;
end;

procedure TSnapshotPrinter.PrepareInsertAccountBlocks(blocks: TArray<IVmAccountBlock>);
begin
  // ignore
end;

procedure TSnapshotPrinter.InsertAccountBlocks(blocks: TArray<IVmAccountBlock>);
begin
  // ignore
end;

procedure TSnapshotPrinter.PrepareInsertSnapshotBlocks(chunks: TArray<ISnapshotChunk>);
begin
  // ignore
end;

procedure TSnapshotPrinter.InsertSnapshotBlocks(chunks: TArray<ISnapshotChunk>);
var
  vChunk: ISnapshotChunk;
begin
  if FSync.SyncState = ssDone then
  begin
    for vChunk in chunks do
      FSnapshots.Add(vChunk.SnapshotBlock);
  end
  else
  begin
    for vChunk in chunks do
      FChunks.Add(vChunk);
  end;
end;

procedure TSnapshotPrinter.PrepareDeleteAccountBlocks(blocks: TArray<IAccountBlock>);
begin
  // ignore
end;

procedure TSnapshotPrinter.DeleteAccountBlocks(blocks: TArray<IAccountBlock>);
begin
  // ignore
end;

procedure TSnapshotPrinter.PrepareDeleteSnapshotBlocks(chunks: TArray<ISnapshotChunk>);
begin
  // ignore
end;

procedure TSnapshotPrinter.DeleteSnapshotBlocks(chunks: TArray<ISnapshotChunk>);
begin
  // ignore
end;

end.
