unit Ledger.Chain.DB.Flush.Test;

interface

uses
  DUnitX.TestFramework,
  Common.DB.XLevelDB;

type
  [TestFixture]
  TFlushTests = class
  public
    [Test]
    procedure TestRedoLog;
    [Test]
    procedure TestFlush;
    [Test]
    procedure TestRecover;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Threading,
  Ledger.Chain.DB,
  Ledger.Chain.Flusher,
  Ledger.Chain.Test.Tools;

const
  cPutFlag = 1;
  cDeleteFlag = 2;

type
  TChecker = class(TInterfacedObject, IBatchReplay)
  private
    FBatch: TBatch;
    FData: TArray<TArray<TBytes>>;
    FTmpData: TArray<TArray<TBytes>>;
    function BatchToData(const ABatch: TBatch): TArray<TArray<TBytes>>;
    function FetchData: TArray<TArray<TBytes>>;
  public
    constructor Create(const ABatch: TBatch);
    procedure CheckBatch(const ABatch: TBatch);
    procedure Put(const AKey, AValue: TBytes);
    procedure Delete(const AKey: TBytes);
  end;

{ TChecker }

constructor TChecker.Create(const ABatch: TBatch);
begin
  inherited Create;
  FBatch := ABatch;
  FData := BatchToData(FBatch);
end;

function TChecker.BatchToData(const ABatch: TBatch): TArray<TArray<TBytes>>;
begin
  ABatch.Replay(Self);
  Result := FetchData;
end;

function TChecker.FetchData: TArray<TArray<TBytes>>;
begin
  Result := FTmpData;
  FTmpData := nil;
end;

procedure TChecker.Put(const AKey, AValue: TBytes);
begin
  SetLength(FTmpData, Length(FTmpData) + 1);
  SetLength(FTmpData[High(FTmpData)], 3);
  FTmpData[High(FTmpData)][0] := AKey;
  FTmpData[High(FTmpData)][1] := AValue;
  FTmpData[High(FTmpData)][2] := [cPutFlag];
end;

procedure TChecker.Delete(const AKey: TBytes);
begin
  SetLength(FTmpData, Length(FTmpData) + 1);
  SetLength(FTmpData[High(FTmpData)], 3);
  FTmpData[High(FTmpData)][0] := AKey;
  FTmpData[High(FTmpData)][1] := nil;
  FTmpData[High(FTmpData)][2] := [cDeleteFlag];
end;

procedure TChecker.CheckBatch(const ABatch: TBatch);
var
  vData: TArray<TArray<TBytes>>;
  i: Integer;
begin
  vData := BatchToData(ABatch);
  Assert.AreEqual(Length(FData), Length(vData));
  for i := 0 to High(vData) do
  begin
    Assert.IsTrue(TBytes.Equals(FData[i][0], vData[i][0]));
    Assert.IsTrue(TBytes.Equals(FData[i][1], vData[i][1]));
    Assert.IsTrue(TBytes.Equals(FData[i][2], vData[i][2]));
  end;
end;

{ TFlushTests }

procedure TFlushTests.TestRedoLog;
var
  vStore: TStore;
  vTempDir: string;
  vMu: TMutex;
  vFlusher: TFlusher;
begin
  NewTestStore(vStore, vTempDir, 'TestRedoLog', True);
  try
    vMu := TMutex.Create;
    try
      vFlusher := TFlusher.Create([vStore], vMu, TPath.Combine(DefaultDataDir, 'TestRedoLog'));
      try
        vFlusher.Flush;
      finally
        vFlusher.Free;
      end;
    finally
      vMu.Free;
    end;
  finally
    ClearTestStore(vTempDir);
  end;
end;

procedure TFlushTests.TestFlush;
var
  vStore: TStore;
  vTempDir: string;
  vBatch: TBatch;
  vChecker: TChecker;
  vLog: TBytes;
  vRedoBatch: TBatch;
  vValue: TBytes;
begin
  NewTestStore(vStore, vTempDir, 'TestFlush', True);
  try
    vBatch := vStore.NewBatch;
    vBatch.Put(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('1')), TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('1')));
    vBatch.Put(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('2')), TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('2')));
    vBatch.Put(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('3')), TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('3')));
    vStore.WriteDirectly(vBatch);

    vStore.Prepare;
    vChecker := TChecker.Create(vBatch);
    vChecker.CheckBatch(vStore.flushingBatch);
    Assert.IsTrue((vStore.snapshotBatch = nil) or (vStore.snapshotBatch.Len <= 0));

    vStore.CancelPrepare;
    Assert.IsTrue((vStore.flushingBatch = nil) or (vStore.flushingBatch.Len <= 0));
    vChecker.CheckBatch(vStore.snapshotBatch);

    vStore.Prepare;
    vChecker.CheckBatch(vStore.flushingBatch);
    Assert.IsTrue((vStore.snapshotBatch = nil) or (vStore.snapshotBatch.Len <= 0));

    vLog := vStore.RedoLog;
    vChecker.CheckBatch(vStore.flushingBatch);
    Assert.IsTrue((vStore.snapshotBatch = nil) or (vStore.snapshotBatch.Len <= 0));
    Assert.IsTrue(TBytes.Equals(vLog, vStore.flushingBatch.Dump));

    vRedoBatch := vStore.NewBatch;
    vRedoBatch.Load(vLog);
    vChecker.CheckBatch(vRedoBatch);

    Assert.AreEqual(S_OK, vStore.Commit);
    vChecker.CheckBatch(vStore.flushingBatch);
    Assert.IsTrue((vStore.snapshotBatch = nil) or (vStore.snapshotBatch.Len <= 0));

    vValue := vStore.db.Get(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('1')), nil);
    Assert.IsTrue(TBytes.Equals(vValue, TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('1'))));

    vValue := vStore.db.Get(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('2')), nil);
    Assert.IsTrue(TBytes.Equals(vValue, TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('2'))));

    vValue := vStore.db.Get(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('3')), nil);
    Assert.IsTrue(TBytes.Equals(vValue, TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('3'))));

    vStore.AfterCommit;
    Assert.IsTrue((vStore.flushingBatch = nil) or (vStore.flushingBatch.Len <= 0));
    Assert.IsTrue((vStore.snapshotBatch = nil) or (vStore.snapshotBatch.Len <= 0));
  finally
    ClearTestStore(vTempDir);
  end;
end;

procedure TFlushTests.TestRecover;
var
  vStore: TStore;
  vTempDir: string;
  vBatch: TBatch;
  vChecker: TChecker;
  vLog: TBytes;
  vRedoBatch: TBatch;
  vCallAfterRecover: Boolean;
  vValue: TBytes;
begin
  NewTestStore(vStore, vTempDir, 'TestRecover', True);
  try
    vBatch := vStore.NewBatch;
    vBatch.Put(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('1')), TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('1')));
    vBatch.Put(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('2')), TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('2')));
    vBatch.Put(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('3')), TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('3')));
    vStore.WriteDirectly(vBatch);

    vStore.Prepare;
    vChecker := TChecker.Create(vBatch);
    vChecker.CheckBatch(vStore.flushingBatch);
    Assert.IsTrue((vStore.snapshotBatch = nil) or (vStore.snapshotBatch.Len <= 0));

    vLog := vStore.RedoLog;
    vChecker.CheckBatch(vStore.flushingBatch);
    Assert.IsTrue((vStore.snapshotBatch = nil) or (vStore.snapshotBatch.Len <= 0));
    Assert.IsTrue(TBytes.Equals(vLog, vStore.flushingBatch.Dump));

    vRedoBatch := vStore.NewBatch;
    vRedoBatch.Load(vLog);
    vChecker.CheckBatch(vRedoBatch);

    vStore.flushingBatch := nil;
    vStore.snapshotBatch.Reset;

    vCallAfterRecover := False;
    vStore.RegisterAfterRecover(procedure begin vCallAfterRecover := True; end);

    vStore.BeforeRecover(vLog);
    vStore.PatchRedoLog(vLog);
    vStore.AfterRecover;

    Assert.IsTrue(vCallAfterRecover);

    vValue := vStore.db.Get(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('1')), nil);
    Assert.IsTrue(TBytes.Equals(vValue, TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('1'))));

    vValue := vStore.db.Get(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('2')), nil);
    Assert.IsTrue(TBytes.Equals(vValue, TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('2'))));

    vValue := vStore.db.Get(TBytes.Create(Ord('k'), Ord('e'), Ord('y'), Ord('3')), nil);
    Assert.IsTrue(TBytes.Equals(vValue, TBytes.Create(Ord('v'), Ord('a'), Ord('l'), Ord('u'), Ord('e'), Ord('3'))));
  finally
    ClearTestStore(vTempDir);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFlushTests);
end.
