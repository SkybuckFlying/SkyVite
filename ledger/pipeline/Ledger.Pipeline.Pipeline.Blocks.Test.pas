unit Ledger.Pipeline.Pipeline.Blocks.Test;

interface

uses
  Common.FileUtils,
  DUnitX.TestFramework,
  Ledger.Chain.Block,
  Ledger.Pipeline.Blocks,
  Ledger.Pipeline.Blocks.Test,
  Ledger.Pipeline.Pipeline.Blocks,
  Net.Interface,
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.Threading,
  Vite.Interfaces.Core;

type
  [TestFixture]
  TPipelineBlocksTest = class(TObject)
  private
    FTmpDir: string;
    FTestFilesize: Int64;
    procedure PrepareTestData(ADir: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestPipeline;
  end;

implementation

{ TPipelineBlocksTest }

procedure TPipelineBlocksTest.Setup;
begin
  FTmpDir := TFileUtils.CreateTempDir;
  FTestFilesize := 5 * 1024;
  PrepareTestData(FTmpDir);
end;

procedure TPipelineBlocksTest.TearDown;
begin
  TDirectory.Delete(FTmpDir, True);
end;

procedure TPipelineBlocksTest.PrepareTestData(ADir: string);
var
  vLockFile: string;
  vBlockDb: TBlockDB;
  vI, vBlockCount: Integer;
  vBlock: ISnapshotBlock;
  vChunk: ISnapshotChunk;
begin
  vLockFile := TPath.Combine(ADir, 'lock');
  if TFile.Exists(vLockFile) then
    Exit;

  TFile.Create(vLockFile).Free;

  vBlockDb := TBlockDB.CreateFixedSize(ADir, FTestFilesize);
  try
    vBlockCount := 3000;
    for vI := 0 to vBlockCount - 1 do
    begin
      vBlock := TSnapshotBlock.Create;
      vBlock.Mock(TUInt64(vI));

      vChunk := TSnapshotChunk.Create;
      vChunk.SnapshotBlock := vBlock;
      vBlockDb.Write(vChunk);
    end;

    vBlockDb.Prepare;
    vBlockDb.Commit;
  finally
    vBlockDb.Free;
  end;
end;

procedure TPipelineBlocksTest.TestPipeline;
var
  vPipeline: TBlocksPipeline;
  vChunk1, vChunk2: IChunk;
begin
  vPipeline := NewBlocksPipeline(FTmpDir, 400);
  try
    TThread.Sleep(1000);

    vChunk1 := vPipeline.Peek;
    vChunk2 := vPipeline.Peek;

    Assert.IsNotNull(vChunk1, 'First peek should not be nil');
    Assert.IsNotNull(vChunk2, 'Second peek should not be nil');

    Assert.AreEqual(Length(vChunk1.GetSnapshotChunks), Length(vChunk2.GetSnapshotChunks));
    Assert.AreEqual(vChunk1.GetSnapshotRange[0].Height, vChunk2.GetSnapshotRange[0].Height);
    Assert.AreEqual(vChunk1.GetSnapshotRange[1].Height, vChunk2.GetSnapshotRange[1].Height);

    WriteLn(Format('Chunk Range: %d -> %d', [vChunk1.GetSnapshotRange[0].Height, vChunk1.GetSnapshotRange[1].Height]));
  finally
    vPipeline.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPipelineBlocksTest);
end.
