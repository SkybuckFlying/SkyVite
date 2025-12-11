{$MODE DELPHIUNICODE}
unit Ledger.Chain.Sync.Cache.Sync.Cache.Test;

interface

uses
  fpcunit,
  testregistry;

type
  TTestSyncCache = class(TTestCase)
  private
    mDir: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSyncLoad3;
    procedure TestSyncLoad2;
    procedure TestSyncCacheLoad;
    procedure TestSyncCache_Delete;
    procedure TestSyncCache_NewWriter;
  end;

implementation

uses
{$IFDEF FPC}
  SysUtils,
  Classes,
{$ELSE}
  System.SysUtils,
  System.Classes,
{$ENDIF}
  System.IOUtils,
  Common.Types.Hash,
  Interfaces,
  Ledger.Chain.Sync.Cache;

procedure TTestSyncCache.SetUp;
begin
  mDir := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'sync_cache_test');
  if TDirectory.Exists(mDir) then
  begin
    TDirectory.Delete(mDir, True);
  end;
  TDirectory.CreateDirectory(mDir);
end;

procedure TTestSyncCache.TearDown;
begin
  if TDirectory.Exists(mDir) then
  begin
    TDirectory.Delete(mDir, True);
  end;
end;

procedure TTestSyncCache.TestSyncLoad3;
var
  vCache: TSyncCache;
  vSegments: TSegmentList;
  vSegment: IInterfaces.TSegment;
  vWriter: TStream;
  vChunks: TSegmentList;
begin
  vCache := TSyncCache.Create(mDir);
  try
    vSegments := TSegmentList.Create;
    try
      vSegments.Add(IInterfaces.TSegment.Create(1, 100, TTypes.THash.FromBytes([0]), TTypes.THash.FromBytes([1])));
      vSegments.Add(IInterfaces.TSegment.Create(101, 200, TTypes.THash.FromBytes([1]), TTypes.THash.FromBytes([2])));
      vSegments.Add(IInterfaces.TSegment.Create(301, 400, TTypes.THash.FromBytes([3]), TTypes.THash.FromBytes([4])));

      for vSegment in vSegments do
      begin
        vWriter := vCache.NewWriter(vSegment, 0);
        // Do not close the writer to simulate an incomplete write
      end;
    finally
      vSegments.Free;
    end;
    vCache.Close;
  finally
    vCache.Free;
  end;

  vCache := TSyncCache.Create(mDir);
  try
    vChunks := vCache.Chunks;
    AssertEquals(0, vChunks.Count, 'Should not have any cached chunks');
  finally
    vCache.Free;
  end;
end;

procedure TTestSyncCache.TestSyncLoad2;
var
  vCache: TSyncCache;
  vSegments: TSegmentList;
  vSegment: IInterfaces.TSegment;
  vWriter: TStream;
  vChunks: TSegmentList;
  vIndex: Integer;
begin
  vCache := TSyncCache.Create(mDir);
  try
    vSegments := TSegmentList.Create;
    try
      vSegments.Add(IInterfaces.TSegment.Create(1, 100, TTypes.THash.FromBytes([0]), TTypes.THash.FromBytes([1])));
      vSegments.Add(IInterfaces.TSegment.Create(101, 200, TTypes.THash.FromBytes([1]), TTypes.THash.FromBytes([2])));
      vSegments.Add(IInterfaces.TSegment.Create(301, 400, TTypes.THash.FromBytes([3]), TTypes.THash.FromBytes([4])));

      for vSegment in vSegments do
      begin
        vWriter := vCache.NewWriter(vSegment, 0);
        vWriter.Free;
      end;
    finally
      vSegments.Free;
    end;
    vCache.Close;
  finally
    vCache.Free;
  end;

  vCache := TSyncCache.Create(mDir);
  try
    vChunks := vCache.Chunks;
    AssertEquals(vSegments.Count, vChunks.Count, 'Different number of chunks');
    for vIndex := 0 to vChunks.Count - 1 do
    begin
      AssertTrue(vSegments[vIndex].Equal(vChunks[vIndex]), 'Different chunk');
    end;
  finally
    vCache.Free;
  end;
end;

procedure TTestSyncCache.TestSyncCacheLoad;
var
  vCache: TSyncCache;
  vSegments: TSegmentList;
  vSegment: IInterfaces.TSegment;
  vWriter: TStream;
  vChunks: TSegmentList;
  vIndex: Integer;
  vReader: IChunkReader;
  vOverlappedSeg: IInterfaces.TSegment;
  vNewSeg: IInterfaces.TSegment;
  vIn: Boolean;
begin
  vCache := TSyncCache.Create(mDir);
  try
    vSegments := TSegmentList.Create;
    try
      vSegments.Add(IInterfaces.TSegment.Create(2, 100, TTypes.THash.FromBytes([1]), TTypes.THash.FromBytes([2])));
      vSegments.Add(IInterfaces.TSegment.Create(101, 200, TTypes.THash.FromBytes([3]), TTypes.THash.FromBytes([4])));
      vSegments.Add(IInterfaces.TSegment.Create(301, 400, TTypes.THash.FromBytes([7]), TTypes.THash.FromBytes([8])));

      for vSegment in vSegments do
      begin
        vWriter := vCache.NewWriter(vSegment, 0);
        vWriter.Free;
      end;

      vChunks := vCache.Chunks;
      AssertEquals(vSegments.Count, vChunks.Count, 'Different number of chunks');
      for vIndex := 0 to vChunks.Count - 1 do
      begin
        AssertTrue(vSegments[vIndex].Equal(vChunks[vIndex]), 'Different chunk');
      end;

      vOverlappedSeg := IInterfaces.TSegment.Create(90, 190, TTypes.THash.Empty, TTypes.THash.Empty);
      ExpectException(EException,
        procedure
        begin
          vCache.NewWriter(vOverlappedSeg, 0);
        end);

      vReader := vCache.NewReader(vSegments[0]);
      AssertFalse(vReader.Verified, 'Should not be verified initially');
      vReader.Verify;
      vReader.Close;

      vReader := vCache.NewReader(vSegments[0]);
      AssertTrue(vReader.Verified, 'Should be verified after Verify call');
      vReader.Close;

      vNewSeg := IInterfaces.TSegment.Create(401, 500, TTypes.THash.FromBytes([10]), TTypes.THash.FromBytes([9]));
      vWriter := vCache.NewWriter(vNewSeg, 0);
      vChunks := vCache.Chunks;
      for vSegment in vChunks do
      begin
        if vSegment.Equal(vNewSeg) then
        begin
          Fail('Writer not closed, should not be in chunk list');
        end;
      end;
      vWriter.WriteData(TEncoding.UTF8.GetBytes('hello'));
      vWriter.Free;

      vIn := False;
      vChunks := vCache.Chunks;
      for vSegment in vChunks do
      begin
        if vSegment.Equal(vNewSeg) then
        begin
          vIn := True;
        end;
      end;
      AssertTrue(vIn, 'Writer closed, should be in chunk list');

    finally
      vSegments.Free;
    end;
  finally
    vCache.Free;
  end;
end;

procedure TTestSyncCache.TestSyncCache_Delete;
var
  vCache: TSyncCache;
  vSegments: TSegmentList;
  vSegment: IInterfaces.TSegment;
  vWriter: TStream;
  vChunks: TSegmentList;
  vIndex: Integer;
begin
  vCache := TSyncCache.Create(mDir);
  try
    vSegments := TSegmentList.Create;
    try
      vSegments.Add(IInterfaces.TSegment.Create(2, 100, TTypes.THash.FromBytes([1]), TTypes.THash.FromBytes([2])));
      vSegments.Add(IInterfaces.TSegment.Create(101, 200, TTypes.THash.FromBytes([3]), TTypes.THash.FromBytes([4])));
      vSegments.Add(IInterfaces.TSegment.Create(301, 400, TTypes.THash.FromBytes([7]), TTypes.THash.FromBytes([8])));

      for vSegment in vSegments do
      begin
        vWriter := vCache.NewWriter(vSegment, 0);
        vWriter.Free;
      end;

      vCache.Delete(vSegments[0]);

      vChunks := vCache.Chunks;
      AssertEquals(vSegments.Count - 1, vChunks.Count, 'Different number of chunks after delete');
      for vIndex := 1 to vSegments.Count - 1 do
      begin
        AssertTrue(vSegments[vIndex].Equal(vChunks[vIndex - 1]), 'Different chunk after delete');
      end;
    finally
      vSegments.Free;
    end;
  finally
    vCache.Free;
  end;
end;

procedure TTestSyncCache.TestSyncCache_NewWriter;
var
  vCache: TSyncCache;
  vSegment: IInterfaces.TSegment;
  vWriter: TStream;
  vFind: Boolean;
  vChunks: TSegmentList;
  vChunk: IInterfaces.TSegment;
begin
  vCache := TSyncCache.Create(mDir);
  try
    vSegment := IInterfaces.TSegment.Create(1, 100, TTypes.THash.FromBytes([100]), TTypes.THash.FromBytes([1]));
    vWriter := vCache.NewWriter(vSegment, 1000);
    vWriter.Free;

    vFind := False;
    vChunks := vCache.Chunks;
    for vChunk in vChunks do
    begin
      if vChunk.Equal(vSegment) then
      begin
        vFind := True;
      end;
    end;

    AssertTrue(vFind, 'Segment not found after writing');

  finally
    vCache.Free;
  end;
end;

initialization
  RegisterTest(TTestSyncCache);
end.
