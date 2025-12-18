unit Ledger.Chain.Sync.Cache.Sync.Cache.Test;

interface

uses
  Common.Types,
  DUnitX.TestFramework,
  Interfaces,
  Ledger.Chain.Sync.Cache.Cache.Item,
  Ledger.Chain.Sync.Cache.Cache.Item.Test,
  Ledger.Chain.Sync.Cache.Reader,
  Ledger.Chain.Sync.Cache.Reader.Test,
  Ledger.Chain.Sync.Cache.Segment,
  Ledger.Chain.Sync.Cache.Segment.Test,
  Ledger.Chain.Sync.Cache.Sync.Cache,
  Ledger.Chain.Sync.Cache.Writer,
  System.IOUtils,
  System.SysUtils;

type
  [TestFixture]
  TSyncCacheTest = class(TObject)
  private
    FBaseDir: string;
    procedure Setup;
    procedure Teardown;
  public
    [Test]
    procedure TestSyncLoad3;
    [Test]
    procedure TestSyncLoad2;
    [Test]
    procedure TestSyncCacheLoad;
    [Test]
    procedure TestSyncCache_Delete;
    [Test]
    procedure TestSyncCache_NewWriter;
  end;

implementation

{ TSyncCacheTest }

procedure TSyncCacheTest.Setup;
begin
  FBaseDir := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'sync_cache');
  if TDirectory.Exists(FBaseDir) then
    TDirectory.Delete(FBaseDir, True);
end;

procedure TSyncCacheTest.Teardown;
begin
  if TDirectory.Exists(FBaseDir) then
    TDirectory.Delete(FBaseDir, True);
end;

procedure TSyncCacheTest.TestSyncLoad3;
var
  vCache: ISyncCache;
  vCS2: ISegmentList;
  I: Integer;
  vWriter: TStream;
begin
  Setup;
  try
    vCache := TSyncCache.Create(FBaseDir);
    SetLength(vCS2, 3);
    vCS2[0] := ISegment.Create(1, 100, THash.FromBytes([0]), THash.FromBytes([1]));
    vCS2[1] := ISegment.Create(101, 200, THash.FromBytes([1]), THash.FromBytes([2]));
    vCS2[2] := ISegment.Create(301, 400, THash.FromBytes([3]), THash.FromBytes([4]));

    for I := 0 to High(vCS2) do
    begin
      vWriter := vCache.NewWriter(vCS2[I], 0);
      // Not closing the writer to simulate temp/unfinished chunks
    end;

    vCache.Close;

    vCache := TSyncCache.Create(FBaseDir);
    Assert.AreEqual(0, Length(vCache.Chunks), 'Should not cache unfinished writes');

  finally
    Teardown;
  end;
end;

procedure TSyncCacheTest.TestSyncLoad2;
var
  vCache: ISyncCache;
  vCS2: ISegmentList;
  I: Integer;
  vWriter: TStream;
  vCS: ISegmentList;
begin
  Setup;
  try
    vCache := TSyncCache.Create(FBaseDir);
    SetLength(vCS2, 3);
    vCS2[0] := ISegment.Create(1, 100, THash.FromBytes([0]), THash.FromBytes([1]));
    vCS2[1] := ISegment.Create(101, 200, THash.FromBytes([1]), THash.FromBytes([2]));
    vCS2[2] := ISegment.Create(301, 400, THash.FromBytes([3]), THash.FromBytes([4]));

    for I := 0 to High(vCS2) do
    begin
      vWriter := vCache.NewWriter(vCS2[I], 0);
      vWriter.Free; // Closing the writer finalizes the chunk
    end;

    vCache.Close;

    vCache := TSyncCache.Create(FBaseDir);
    vCS := vCache.Chunks;

    Assert.AreEqual(Length(vCS2), Length(vCS), 'Different number of chunks');
    for I := 0 to High(vCS) do
    begin
      Assert.IsTrue(vCS2[I].Equal(vCS[I]), 'Different chunk');
    end;

  finally
    Teardown;
  end;
end;

procedure TSyncCacheTest.TestSyncCacheLoad;
var
  vCache: ISyncCache;
  vCS2: ISegmentList;
  vWriter: TStream;
  vReader: IChunkReader;
  vSeg: ISegment;
  vIn: Boolean;
  vBytes: TBytes;
  vCS: ISegmentList;
  I: Integer;
begin
  Setup;
  try
    vCache := TSyncCache.Create(FBaseDir);
    SetLength(vCS2, 3);
    vCS2[0] := ISegment.Create(2, 100, THash.FromBytes([1]), THash.FromBytes([2]));
    vCS2[1] := ISegment.Create(101, 200, THash.FromBytes([3]), THash.FromBytes([4]));
    vCS2[2] := ISegment.Create(301, 400, THash.FromBytes([7]), THash.FromBytes([8]));

    for I := 0 to High(vCS2) do
    begin
      vWriter := vCache.NewWriter(vCS2[I], 0);
      vWriter.Free;
    end;

    vCS := vCache.Chunks;
    Assert.AreEqual(Length(vCS2), Length(vCS));
    for I := 0 to High(vCS) do Assert.IsTrue(vCS2[I].Equal(vCS[I]));

    Assert.WillRaise(
      procedure
      begin
        vWriter := vCache.NewWriter(ISegment.Create(90, 190, THash.Empty, THash.Empty), 0);
      end, EOverlapException); // Assuming a specific exception for overlap

    vReader := vCache.NewReader(vCS2[0]);
    Assert.IsFalse(vReader.Verified);
    (vReader as TReader).Verify; // Cast to access implementation detail
    vReader.Close;

    vReader := vCache.NewReader(vCS2[0]);
    Assert.IsTrue(vReader.Verified);
    vReader.Close;

    vSeg := ISegment.Create(401, 500, THash.FromBytes([10]), THash.FromBytes([9]));
    vWriter := vCache.NewWriter(vSeg, 0);
    SetLength(vBytes, 5); // "hello"
    vBytes[0] := Ord('h'); vBytes[1] := Ord('e'); vBytes[2] := Ord('l'); vBytes[3] := Ord('l'); vBytes[4] := Ord('o');
    vWriter.Write(vBytes, Length(vBytes));
    vWriter.Free;

    vIn := False;
    vCS := vCache.Chunks;
    for I := 0 to High(vCS) do
    begin
      if vCS[I].Equal(vSeg) then
      begin
        vIn := True;
        break;
      end;
    end;
    Assert.IsTrue(vIn, 'write close, should be in chunk list');

  finally
    Teardown;
  end;
end;

procedure TSyncCacheTest.TestSyncCache_Delete;
var
  vCache: ISyncCache;
  vCS2: ISegmentList;
  I: Integer;
  vWriter: TStream;
  vCS: ISegmentList;
begin
  Setup;
  try
    vCache := TSyncCache.Create(FBaseDir);
    SetLength(vCS2, 3);
    vCS2[0] := ISegment.Create(2, 100, THash.FromBytes([1]), THash.FromBytes([2]));
    vCS2[1] := ISegment.Create(101, 200, THash.FromBytes([3]), THash.FromBytes([4]));
    vCS2[2] := ISegment.Create(301, 400, THash.FromBytes([7]), THash.FromBytes([8]));

    for I := 0 to High(vCS2) do
    begin
      vWriter := vCache.NewWriter(vCS2[I], 0);
      vWriter.Free;
    end;

    vCache.Delete(vCS2[0]);

    vCS := vCache.Chunks;
    Assert.AreEqual(Length(vCS2) - 1, Length(vCS));
    for I := 1 to High(vCS2) do
    begin
      Assert.IsTrue(vCS2[I].Equal(vCS[I-1]), 'different chunk');
    end;

  finally
    Teardown;
  end;
end;

procedure TSyncCacheTest.TestSyncCache_NewWriter;
var
  vCache: ISyncCache;
  vSeg: ISegment;
  vWriter: TStream;
  vFind: Boolean;
  vCS: ISegmentList;
  I: Integer;
begin
  Setup;
  try
    vCache := TSyncCache.Create(FBaseDir);
    vSeg := ISegment.Create(1, 100, THash.FromBytes([100]), THash.FromBytes([1]));
    vWriter := vCache.NewWriter(vSeg, 1000);
    vWriter.Free;

    vFind := False;
    vCS := vCache.Chunks;
    for I := 0 to High(vCS) do
    begin
      if vCS[I].Equal(vSeg) then
      begin
        vFind := True;
        break;
      end;
    end;
    Assert.IsTrue(vFind);

  finally
    Teardown;
  end;
end;

end.
