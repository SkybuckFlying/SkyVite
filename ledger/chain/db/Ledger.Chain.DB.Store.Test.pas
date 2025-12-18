unit Ledger.Chain.Db.Store.Test;

interface

uses
  Common.Utils Crypto.Hash,
  DUnitX.TestFramework,
  Ledger.Chain.DB.Flush,
  Ledger.Chain.DB.Flush.Test,
  Ledger.Chain.DB.Mem.DB.Test,
  Ledger.Chain.DB.Rollback,
  Ledger.Chain.DB.Store,
  Ledger.Chain.Db.Store Common.DB.XLevelDB Common.Test.Tools Vite.Common.Types,
  Ledger.Chain.DB.Unconfirmed.Batch,
  Ledger.Chain.DB.Write,
  System.SysUtils System.Classes System.Generics.Collections System.IOUtils;

type
  TChecker = class
  private
    FBatch: TLevelDBBatch;
    FData: TArray<TArray<TBytes>>;
    FTmpData: TArray<TArray<TBytes>>;
    function BatchToData(ParaBatch: TLevelDBBatch): TArray<TArray<TBytes>>;
    function FetchData: TArray<TArray<TBytes>>;
  public
    constructor Create(ParaBatch: TLevelDBBatch);
    destructor Destroy; override;
    procedure CheckBatch(ParaBatch: TLevelDBBatch);
    procedure Put(ParaKey, ParaValue: TBytes);
    procedure Delete(ParaKey: TBytes);
  end;

  [TestFixture]
  TTestStore = class
  private
    FStore: TStore;
    FTempDir: string;
    procedure Setup;
    procedure Teardown;
    procedure WriteKv(ParaBatch: TLevelDBBatch; ParaKey, ParaValue: UInt64);
    procedure FlushToDisk(ParaStore: TStore);
    procedure WriteBlock(ParaStore: TStore; ParaBlockIndex: Integer);
    procedure Snapshot(ParaStore: TStore; ParaBlockIndexList: TArray<Integer>);
    procedure QueryBlock(ParaStore: TStore; ParaBlockIndex: Integer);
  public
    [Test]
    procedure TestStore;
    [Test]
    procedure TestSeekToLastAndPrev;
    [Test]
    procedure TestPutAndDelete;
    [Test]
    procedure TestIterator;
  end;

  [TestFixture]
  TTestStoreFlush = class
  private
    FStore: TStore;
    FTempDir: string;
    procedure Setup;
    procedure Teardown;
  public
    [Test]
    procedure TestFlush;
    [Test]
    procedure TestRecover;
  end;

implementation

uses
  System.Hash, System.Diagnostics, System.Threading;

{ TChecker }

constructor TChecker.Create(ParaBatch: TLevelDBBatch);
begin
  inherited Create;
  FBatch := ParaBatch;
  FData := BatchToData(ParaBatch);
end;

destructor TChecker.Destroy;
begin
  inherited Destroy;
end;

function TChecker.BatchToData(ParaBatch: TLevelDBBatch): TArray<TArray<TBytes>>;
begin
  ParaBatch.Replay(Self);
  Result := FetchData;
end;

function TChecker.FetchData: TArray<TArray<TBytes>>;
begin
  Result := FTmpData;
  FTmpData := nil;
end;

procedure TChecker.Put(ParaKey, ParaValue: TBytes);
var
  vItem: TArray<TBytes>;
begin
  SetLength(vItem, 3);
  vItem[0] := ParaKey;
  vItem[1] := ParaValue;
  SetLength(vItem[2], 1);
  vItem[2][0] := 1; // putFlag
  SetLength(FTmpData, Length(FTmpData) + 1);
  FTmpData[High(FTmpData)] := vItem;
end;

procedure TChecker.Delete(ParaKey: TBytes);
var
  vItem: TArray<TBytes>;
begin
  SetLength(vItem, 3);
  vItem[0] := ParaKey;
  vItem[1] := nil;
  SetLength(vItem[2], 1);
  vItem[2][0] := 2; // deleteFlag
  SetLength(FTmpData, Length(FTmpData) + 1);
  FTmpData[High(FTmpData)] := vItem;
end;

procedure TChecker.CheckBatch(ParaBatch: TLevelDBBatch);
var
  vData: TArray<TArray<TBytes>>;
  i: Integer;
begin
  vData := BatchToData(ParaBatch);
  Assert.AreEqual(Length(FData), Length(vData));
  for i := 0 to High(vData) do
  begin
    Assert.AreEqual(FData[i][0], vData[i][0]);
    Assert.AreEqual(FData[i][1], vData[i][1]);
    Assert.AreEqual(FData[i][2], vData[i][2]);
  end;
end;

{ TTestStore }

procedure TTestStore.Setup;
var
  vTestName: string;
begin
  vTestName := 'TestStore'; // Simplified for example
  FStore := NewTestStore(vTestName, True, FTempDir);
end;

procedure TTestStore.Teardown;
begin
  ClearTestStore(FTempDir);
end;

procedure TTestStore.WriteKv(ParaBatch: TLevelDBBatch; ParaKey, ParaValue: UInt64);
begin
  ParaBatch.Put(Uint64ToBytes(ParaKey), Uint64ToBytes(ParaValue));
end;

procedure TTestStore.FlushToDisk(ParaStore: TStore);
begin
  ParaStore.Prepare;
  ParaStore.RedoLog;
  ParaStore.Commit;
  ParaStore.AfterCommit;
end;

procedure TTestStore.WriteBlock(ParaStore: TStore; ParaBlockIndex: Integer);
var
  vBatch: TLevelDBBatch;
  vBaseNum: UInt64;
  vRandNum, i: Integer;
  vBlockHash: TBytes;
begin
  vBatch := ParaStore.NewBatch;
  try
    vBaseNum := UInt64(ParaBlockIndex * 3);
    vBatch.Put(Uint64ToBytes(1 + vBaseNum), Uint64ToBytes(1 + vBaseNum));
    vBatch.Put(Uint64ToBytes(2 + vBaseNum), Uint64ToBytes(2 + vBaseNum));
    vBatch.Put(Uint64ToBytes(3 + vBaseNum), Uint64ToBytes(3 + vBaseNum));

    vRandNum := Random(3) + 1;
    for i := 1 to vRandNum - 1 do
    begin
      vBatch.Delete(Uint64ToBytes(UInt64(i) + vBaseNum));
    end;

    vBlockHash := THash256.GetHash(TEncoding.UTF8.GetBytes(Format('blockHash%d', [ParaBlockIndex])));
    ParaStore.WriteAccountBlockByHash(vBatch, vBlockHash);
  finally
    vBatch.Free;
  end;
end;

procedure TTestStore.Snapshot(ParaStore: TStore; ParaBlockIndexList: TArray<Integer>);
var
  vBatch: TLevelDBBatch;
  vBlockHashList: TArray<TBytes>;
  vBlockIndex: Integer;
begin
  vBatch := ParaStore.NewBatch;
  try
    SetLength(vBlockHashList, Length(ParaBlockIndexList));
    for vBlockIndex in ParaBlockIndexList do
    begin
      vBlockHashList[vBlockIndex] := THash256.GetHash(TEncoding.UTF8.GetBytes(Format('blockHash%d', [vBlockIndex])));
    end;
    ParaStore.WriteSnapshotByHash(vBatch, vBlockHashList);
  finally
    vBatch.Free;
  end;
end;

procedure TTestStore.QueryBlock(ParaStore: TStore; ParaBlockIndex: Integer);
var
  vBaseNum: UInt64;
begin
  vBaseNum := UInt64(ParaBlockIndex * 3);
  ParaStore.Get(Uint64ToBytes(1 + vBaseNum));
  ParaStore.Get(Uint64ToBytes(2 + vBaseNum));
  ParaStore.Get(Uint64ToBytes(3 + vBaseNum));
end;

procedure TTestStore.TestStore;
begin
  Setup;
  try
    WriteBlock(FStore, 1);
    QueryBlock(FStore, 1);
    FlushToDisk(FStore);
    WriteBlock(FStore, 2);
    QueryBlock(FStore, 2);
    Snapshot(FStore, [1]);
    QueryBlock(FStore, 1);
    QueryBlock(FStore, 2);
    WriteBlock(FStore, 3);
    QueryBlock(FStore, 3);
    WriteBlock(FStore, 4);
    QueryBlock(FStore, 4);
    Snapshot(FStore, [3]);
    QueryBlock(FStore, 1);
    QueryBlock(FStore, 2);
    QueryBlock(FStore, 3);
    QueryBlock(FStore, 4);
  finally
    Teardown;
  end;
end;

procedure TTestStore.TestSeekToLastAndPrev;
var
  vBatch: TLevelDBBatch;
  vEnd: UInt64;
  i: UInt64;
  vIter: IStorageIterator;
begin
  Setup;
  try
    vBatch := TLevelDBBatch.Create;
    try
      vEnd := 10;
      for i := 0 to vEnd - 1 do
      begin
        WriteKv(vBatch, i, i);
      end;
      FStore.WriteDirectly(vBatch);

      vIter := FStore.NewIterator(nil);
      Assert.IsFalse(vIter.Seek(Uint64ToBytes(vEnd + 100)));
      Assert.IsTrue(vIter.Prev);
      Assert.AreEqual(vEnd - 1, BytesToUint64(vIter.Value));
    finally
      vBatch.Free;
    end;
  finally
    Teardown;
  end;
end;

procedure TTestStore.TestPutAndDelete;
var
  vBatch: TLevelDBBatch;
  vEnd: UInt64;
  i: UInt64;
  vValue: TBytes;
  vIter: IStorageIterator;
begin
  Setup;
  try
    vBatch := TLevelDBBatch.Create;
    try
      vEnd := 10;
      for i := 0 to vEnd - 1 do
      begin
        WriteKv(vBatch, i, i);
      end;
      FStore.WriteDirectly(vBatch);
      FlushToDisk(FStore);

      vBatch.Delete(Uint64ToBytes(7));
      vBatch.Put(Uint64ToBytes(7), Uint64ToBytes(77));
      vBatch.Delete(Uint64ToBytes(7));
      FStore.WriteDirectly(vBatch);

      vValue := FStore.Get(Uint64ToBytes(7));
      Assert.AreEqual(0, Length(vValue));

      vIter := FStore.NewIterator(nil);
      while vIter.Next do
      begin
        // Just iterating
      end;
    finally
      vBatch.Free;
    end;
  finally
    Teardown;
  end;
end;

procedure TTestStore.TestIterator;
var
  vMaxIterations: Integer;
  vCount: UInt64;
  vTask1, vTask2: ITask;
begin
  Setup;
  try
    vMaxIterations := 10;
    vCount := 0;

    vTask1 := TTask.Run(procedure
      var
        vBatch: TLevelDBBatch;
        vRandom: Integer;
      begin
        while vCount <= UInt64(vMaxIterations) do
        begin
          vBatch := TLevelDBBatch.Create;
          try
            Inc(vCount);
            vBatch.Put(Uint64ToBytes(vCount), Uint64ToBytes(vCount));
            FStore.WriteDirectly(vBatch);
            vRandom := Random(100);
            if vRandom > 50 then
            begin
              FlushToDisk(FStore);
            end;
            TThread.Sleep(10);
          finally
            vBatch.Free;
          end;
        end;
      end);

    vTask2 := TTask.Run(procedure
      var
        vIter: IStorageIterator;
        vPrev, vCurrent: UInt64;
      begin
        while True do
        begin
          vIter := FStore.NewIterator(nil);
          vPrev := 0;
          while vIter.Next do
          begin
            vCurrent := BytesToUint64(vIter.Key);
            Assert.AreEqual(vPrev + 1, vCurrent);
            vPrev := vCurrent;
          end;
          if vCount >= UInt64(vMaxIterations) then
          begin
            break;
          end;
        end;
      end);

    TTask.WaitForAll([vTask1, vTask2]);
  finally
    Teardown;
  end;
end;

{ TTestStoreFlush }

procedure TTestStoreFlush.Setup;
var
  vTestName: string;
begin
  vTestName := 'TestStoreFlush'; // Simplified for example
  FStore := NewTestStore(vTestName, True, FTempDir);
end;

procedure TTestStoreFlush.Teardown;
begin
  ClearTestStore(FTempDir);
end;

procedure TTestStoreFlush.TestFlush;
var
  vBatch: TLevelDBBatch;
  vChecker: TChecker;
  vLog: TBytes;
  vRedoBatch: TLevelDBBatch;
  vValue: TBytes;
begin
  Setup;
  try
    vBatch := FStore.NewBatch;
    try
      vBatch.Put(TEncoding.UTF8.GetBytes('key1'), TEncoding.UTF8.GetBytes('value1'));
      vBatch.Put(TEncoding.UTF8.GetBytes('key2'), TEncoding.UTF8.GetBytes('value2'));
      vBatch.Put(TEncoding.UTF8.GetBytes('key3'), TEncoding.UTF8.GetBytes('value3'));
      FStore.WriteDirectly(vBatch); // Assuming WriteDirectly exists for test setup

      // 1. Prepare
      FStore.Prepare;
      vChecker := TChecker.Create(vBatch);
      try
        vChecker.CheckBatch(FStore.mFlushingBatch);
        Assert.IsTrue(not Assigned(FStore.mSnapshotBatch) or (FStore.mSnapshotBatch.Len <= 0));

        // 2. Cancel Prepare
        FStore.CancelPrepare;
        Assert.IsTrue(not Assigned(FStore.mFlushingBatch) or (FStore.mFlushingBatch.Len <= 0));
        vChecker.CheckBatch(FStore.mSnapshotBatch);

        // 3. Prepare again
        FStore.Prepare;
        vChecker.CheckBatch(FStore.mFlushingBatch);
        Assert.IsTrue(not Assigned(FStore.mSnapshotBatch) or (FStore.mSnapshotBatch.Len <= 0));

        // 4. Redo Log
        vLog := FStore.RedoLog;
        vChecker.CheckBatch(FStore.mFlushingBatch);
        Assert.IsTrue(not Assigned(FStore.mSnapshotBatch) or (FStore.mSnapshotBatch.Len <= 0));
        Assert.AreEqual(vLog, FStore.mFlushingBatch.Dump);

        vRedoBatch := FStore.NewBatch;
        try
          vRedoBatch.Load(vLog);
          vChecker.CheckBatch(vRedoBatch);
        finally
          vRedoBatch.Free;
        end;

        // 5. Commit
        Assert.IsTrue(FStore.Commit);
        vChecker.CheckBatch(FStore.mFlushingBatch);
        Assert.IsTrue(not Assigned(FStore.mSnapshotBatch) or (FStore.mSnapshotBatch.Len <= 0));

        vValue := FStore.Get(TEncoding.UTF8.GetBytes('key1'));
        Assert.AreEqual(TEncoding.UTF8.GetBytes('value1'), vValue);
        vValue := FStore.Get(TEncoding.UTF8.GetBytes('key2'));
        Assert.AreEqual(TEncoding.UTF8.GetBytes('value2'), vValue);
        vValue := FStore.Get(TEncoding.UTF8.GetBytes('key3'));
        Assert.AreEqual(TEncoding.UTF8.GetBytes('value3'), vValue);

        // 6. After Commit
        FStore.AfterCommit;
        Assert.IsTrue(not Assigned(FStore.mFlushingBatch) or (FStore.mFlushingBatch.Len <= 0));
        Assert.IsTrue(not Assigned(FStore.mSnapshotBatch) or (FStore.mSnapshotBatch.Len <= 0));

      finally
        vChecker.Free;
      end;
    finally
      vBatch.Free;
    end;
  finally
    Teardown;
  end;
end;

procedure TTestStoreFlush.TestRecover;
var
  vBatch: TLevelDBBatch;
  vChecker: TChecker;
  vLog: TBytes;
  vRedoBatch: TLevelDBBatch;
  vCallAfterRecover: Boolean;
  vValue: TBytes;
begin
  Setup;
  try
    vBatch := FStore.NewBatch;
    try
      vBatch.Put(TEncoding.UTF8.GetBytes('key1'), TEncoding.UTF8.GetBytes('value1'));
      vBatch.Put(TEncoding.UTF8.GetBytes('key2'), TEncoding.UTF8.GetBytes('value2'));
      vBatch.Put(TEncoding.UTF8.GetBytes('key3'), TEncoding.UTF8.GetBytes('value3'));
      FStore.WriteDirectly(vBatch);

      // 1. Prepare
      FStore.Prepare;
      vChecker := TChecker.Create(vBatch);
      try
        vChecker.CheckBatch(FStore.mFlushingBatch);
        Assert.IsTrue(not Assigned(FStore.mSnapshotBatch) or (FStore.mSnapshotBatch.Len <= 0));

        // 2. Redo Log
        vLog := FStore.RedoLog;
        vChecker.CheckBatch(FStore.mFlushingBatch);
        Assert.IsTrue(not Assigned(FStore.mSnapshotBatch) or (FStore.mSnapshotBatch.Len <= 0));
        Assert.AreEqual(vLog, FStore.mFlushingBatch.Dump);

        vRedoBatch := FStore.NewBatch;
        try
          vRedoBatch.Load(vLog);
          vChecker.CheckBatch(vRedoBatch);
        finally
          vRedoBatch.Free;
        end;

        // Reset for recovery test
        FStore.mFlushingBatch := nil;
        FStore.mSnapshotBatch.Reset;

        vCallAfterRecover := False;
        FStore.RegisterAfterRecover(procedure
          begin
            vCallAfterRecover := True;
          end);

        // 3. Before Recover
        FStore.BeforeRecover(vLog);

        // 4. Recover
        Assert.IsTrue(FStore.PatchRedoLog(vLog));

        // 5. After Recover
        FStore.AfterRecover;
        Assert.IsTrue(vCallAfterRecover);

        vValue := FStore.Get(TEncoding.UTF8.GetBytes('key1'));
        Assert.AreEqual(TEncoding.UTF8.GetBytes('value1'), vValue);
        vValue := FStore.Get(TEncoding.UTF8.GetBytes('key2'));
        Assert.AreEqual(TEncoding.UTF8.GetBytes('value2'), vValue);
        vValue := FStore.Get(TEncoding.UTF8.GetBytes('key3'));
        Assert.AreEqual(TEncoding.UTF8.GetBytes('value3'), vValue);

      finally
        vChecker.Free;
      end;
    finally
      vBatch.Free;
    end;
  finally
    Teardown;
  end;
end;

initialization
  // Add to Test Registry
  TDUnitX.RegisterTestFixture(TTestStore);
  TDUnitX.RegisterTestFixture(TTestStoreFlush);
end.
