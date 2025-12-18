unit Ledger.Pipeline.Blocks.Test;

interface

uses
  Common.FileUtils,
  DUnitX.TestFramework,
  Ledger.Chain.Block,
  Ledger.Pipeline.Blocks,
  Ledger.Pipeline.Pipeline.Blocks,
  Ledger.Pipeline.Pipeline.Blocks.Test,
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Vite.Interfaces.Core;

type
  [TestFixture]
  TBlocksTest = class(TObject)
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
    procedure TestNewBlocks;
    [Test]
    procedure TestBlocks_location;
  end;

implementation

{ TBlocksTest }

procedure TBlocksTest.Setup;
begin
  FTmpDir := TFileUtils.CreateTempDir;
  FTestFilesize := 5 * 1024;
  PrepareTestData(FTmpDir);
end;

procedure TBlocksTest.TearDown;
begin
  TDirectory.Delete(FTmpDir, True);
end;

procedure TBlocksTest.PrepareTestData(ADir: string);
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
  WriteLn(Format('prepare data done in %s', [ADir]));
end;

procedure TBlocksTest.TestNewBlocks;
var
  vBlocks: TBlocks;
begin
  Assert.WillNotRaise(procedure
    begin
      vBlocks := TBlocks.Create(FTmpDir, FTestFilesize);
      vBlocks.Free;
    end, 'TBlocks.Create should not raise an exception');
end;

procedure TBlocksTest.TestBlocks_location;
var
  vBlocks: TBlocks;
  vLocation: TLocation;
begin
  vBlocks := TBlocks.Create(FTmpDir, FTestFilesize);
  try
    vLocation := vBlocks.Location(1000);
    Assert.IsNotNull(vLocation, 'Location for height 1000 should not be nil');
    WriteLn(vLocation.ToString);

    vLocation := vBlocks.Location(2000);
    Assert.IsNotNull(vLocation, 'Location for height 2000 should not be nil');
    WriteLn(vLocation.ToString);

    vLocation := vBlocks.Location(2999);
    Assert.IsNotNull(vLocation, 'Location for height 2999 should not be nil');
    WriteLn(vLocation.ToString);
  finally
    vBlocks.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TBlocksTest);
end.
