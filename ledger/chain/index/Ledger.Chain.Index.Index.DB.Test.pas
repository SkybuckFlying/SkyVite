unit Ledger.Chain.Index.Test.IndexDB;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  Common,
  Common.Types,
  Ledger.Chain.Index;

type
  [TestFixture]
  TIndexDBTest = class
  public
    [Test]
    [Ignore('Skipped by default. This test can be used to inspect IndexDB.')]
    procedure TestDumpFileLocation;
    [Test]
    [Ignore('Skipped by default. This test can be used to inspect IndexDB.')]
    procedure TestIndexDB_GetLatestAccountBlock;
  end;

implementation

uses
  System.IOUtils,
  Ledger.Chain.FileManager;

{ TIndexDBTest }

procedure TIndexDBTest.TestDumpFileLocation;
var
  vChainDir: string;
  vDb: TIndexDB;
  vErr: Exception;
  vStep: UInt64;
  vFrom: UInt64;
  vI: UInt64;
  vLocation: ILocation;
begin
  vChainDir := TPath.Combine(THome.HomeDir, '.gvite/mockdata/ledger');
  vDb := TIndexDB.Create(vChainDir);
  try
    vStep := 75 * 10;
    vFrom := GenesisHeight;

    vI := vFrom;
    while True do
    begin
      vLocation := vDb.GetSnapshotBlockLocation(vI, vErr);
      Assert.IsNull(vErr);
      if vLocation = nil then
      begin
        Break;
      end;
      Log.d(Format('%s %d', [vLocation.FileId, vLocation.Offset]));
      vI := vI + vStep;
    end;
  finally
    vDb.Free;
  end;
end;

procedure TIndexDBTest.TestIndexDB_GetLatestAccountBlock;
var
  vChainDir: string;
  vDb: TIndexDB;
  vErr: Exception;
  vAddress: TAddress;
  vHeight: UInt64;
  vLocation: ILocation;
begin
  vChainDir := TPath.Combine(THome.HomeDir, '.gvite/mockdata/ledger');
  vDb := TIndexDB.Create(vChainDir);
  try
    vAddress := TAddress.HexToAddress('vite_7c8c9e1e878e8a6ddf59c66a83791a5755a8fcf606c4bd31ea', vErr);
    Assert.IsNull(vErr);
    vErr := vDb.GetLatestAccountBlock(vAddress, vHeight, vLocation);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vLocation);

    Log.d(Format('%d %s %d', [vHeight, vLocation.FileId, vLocation.Offset]));
  finally
    vDb.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TIndexDBTest);
end.
