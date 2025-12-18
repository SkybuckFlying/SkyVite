unit Ledger.Consensus.CDB.DB.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.IOUtils,
  System.Generics.Collections,
  GoLevelDB,
  Common.Types,
  Ledger.Consensus.CDB.Consensus,
  Ledger.Consensus.CDB.Point;

type
  [TestFixture]
  TConsensusDBTest = class(TObject)
  private
    FDB: TConsensusDB;
    FLevelDB: ILevelDB;
    procedure Setup;
    procedure Teardown;
  public
    [Setup]
    procedure BeforeEach;
    [TearDown]
    procedure AfterEach;

    [Test]
    procedure TestNewConsensusDB;
    [Test]
    procedure TestConsensusDB_Point;
    [Test]
    procedure TestPasrse;

    [Test]
    [Ignore('Skipped by default. This test can be used to inspect consensus db.')]
    procedure TestConsensusDB_read;
    [Test]
    [Ignore('Skipped by default. This test can be used to inspect consensus db.')]
    procedure TestConsensusDB_compare;
  end;

implementation

uses
  System.JSON;

{ TConsensusDBTest }

procedure TConsensusDBTest.Setup;
var
  vTestDir: string;
begin
  vTestDir := 'testdata-consensus';
  if TDirectory.Exists(vTestDir) then
    TDirectory.Delete(vTestDir, True);
  FLevelDB := TGoLevelDB.OpenFile(vTestDir);
  FDB := TConsensusDB.Create(FLevelDB);
end;

procedure TConsensusDBTest.Teardown;
begin
  if Assigned(FDB) then
  begin
    FLevelDB.Close;
    FDB := nil;
  end;
  if TDirectory.Exists('testdata-consensus') then
    TDirectory.Delete('testdata-consensus', True);
end;

procedure TConsensusDBTest.BeforeEach;
begin
  Setup;
end;

procedure TConsensusDBTest.AfterEach;
begin
  Teardown;
end;

procedure TConsensusDBTest.TestNewConsensusDB;
begin
  // The setup method already tests the creation.
  // This test is to ensure the fixture is working.
  Assert.IsNotNull(FDB);
end;

procedure TConsensusDBTest.TestConsensusDB_Point;
var
  vP1: IPoint;
  vH1, vH2: THash;
  vInfos: TDictionary<TAddress, IContent>;
  vAddr1, vAddr2: TAddress;
  vP: IPoint;
begin
  vP1 := FDB.GetPointByHeight(IndexPointDay, 1);
  Assert.IsNull(vP1, 'Point should be nil for empty DB');

  vH1 := THash.HexToHash('f3b9187d69e0749e28f9c8172fd6b7b468cbe89acb14f8038bbbb6a402d738ae');
  vH2 := THash.HexToHash('d7251a9d1da157dcfd20a729fc368f1dfc85a55e4057df229fbb1bacb3405385');
  vInfos := TDictionary<TAddress, IContent>.Create;
  try
    vAddr1 := TAddress.HexToAddress('vite_91dc0c38d104c7915d3a6c4381a40c360edd871c34ac255bb2');
    vAddr2 := TAddress.HexToAddress('vite_d6851aaf8966f4550bde3d64582f7da9c6ab8b18a289823b95');
    vInfos.Add(vAddr1, TContent.Create(3, 2));
    vInfos.Add(vAddr2, TContent.Create(9, 7));
    vP := TPoint.Create(vH1, vH2, vInfos);

    FDB.StorePointByHeight(IndexPointDay, 1, vP);

    vP1 := FDB.GetPointByHeight(IndexPointDay, 1);
    Assert.IsNotNull(vP1, 'Stored point not found');
    Assert.IsTrue(vP1.PrevHash.IsEqual(vH1));
    Assert.IsTrue(vP1.Hash.IsEqual(vH2));
    for var kvp in vP1.Sbps do
    begin
      Assert.IsTrue(vInfos.ContainsKey(kvp.Key));
      Assert.AreEqual(vInfos[kvp.Key].ExpectedNum, kvp.Value.ExpectedNum);
      Assert.AreEqual(vInfos[kvp.Key].FactualNum, kvp.Value.FactualNum);
    end;
  finally
    vInfos.Free;
  end;
end;

procedure TConsensusDBTest.TestPasrse;
var
  vAddr1, vAddr2: TAddress;
  vDD, vRstArr: TAddrArr;
  vResult: TBytes;
  vJsonBytes: TBytes;
begin
  vAddr1 := TAddress.HexToAddress('vite_29a3ec96d1e4a52f50e3119ed9945de09bef1d74a772ee60ff');
  vAddr2 := TAddress.HexToAddress('vite_0d97a04d61dbbf238e9b6050c9d29d2b6f97986859e7856ec9');
  SetLength(vDD, 2);
  vDD[0] := vAddr1;
  vDD[1] := vAddr2;
  vResult := AddrArrToBytes(vDD);
  vJsonBytes := TEncoding.UTF8.GetBytes(TJson.ObjectToJsonString(vDD));

  TestFramework.Log(Format('%d %d byte len', [Length(vResult), Length(vJsonBytes)]));
  vRstArr := BytesToAddrArr(vResult);
  Assert.AreEqual(Length(vDD), Length(vRstArr));
  Assert.IsTrue(vDD[0].IsEqual(vRstArr[0]));
  Assert.IsTrue(vDD[1].IsEqual(vRstArr[1]));
end;

procedure TConsensusDBTest.TestConsensusDB_read;
var
  vDB: TConsensusDB;
  vLevelDB: ILevelDB;
  vPoint: IPoint;
begin
  // This test is ignored because it requires a local LevelDB database at a hardcoded path.
  // To run this test, replace the path with a valid local database path.
  vLevelDB := TGoLevelDB.OpenFile('/Users/jie/Library/GVite/maindata/ledger/consensus');
  try
    vDB := TConsensusDB.Create(vLevelDB);
    vPoint := vDB.GetPointByHeight(IndexPointHour, 1);
    Assert.IsNotNull(vPoint);
    TestFramework.Log(Format('%s %s', [vPoint.Hash.ToString, vPoint.PrevHash.ToString]));
    for var kvp in vPoint.Votes.Details do
    begin
      TestFramework.Log(Format('%s %s', [kvp.Key.ToString, kvp.Value.ToString]));
    end;
  finally
    vLevelDB.Close;
  end;
end;

procedure TConsensusDBTest.TestConsensusDB_compare;
var
  vDB1, vDB2: TConsensusDB;
  vLevelDB1, vLevelDB2: ILevelDB;
  vPoint1, vPoint2: IPoint;
  I: UInt64;
begin
  // This test is ignored because it requires local LevelDB databases at hardcoded paths.
  // To run this test, replace the paths with valid local database paths.
  vLevelDB1 := TGoLevelDB.OpenFile('/Users/jie/Library/GVite/maindata/ledger/consensus');
  vLevelDB2 := TGoLevelDB.OpenFile('/Users/jie/Library/GVite/maindata/ledger_normal/consensus');
  try
    vDB1 := TConsensusDB.Create(vLevelDB1);
    vDB2 := TConsensusDB.Create(vLevelDB2);
    for I := 1 to 23 do
    begin
      vPoint1 := vDB1.GetPointByHeight(IndexPointHour, I);
      vPoint2 := vDB2.GetPointByHeight(IndexPointHour, I);
      if (vPoint1 = nil) or (vPoint2 = nil) then
        Continue;

      TestFramework.Log(Format('%s %s', [vPoint1.Hash.ToString, vPoint1.PrevHash.ToString]));
      TestFramework.Log(Format('%s %s', [vPoint2.Hash.ToString, vPoint2.PrevHash.ToString]));
      for var addr in vPoint1.Sbps.Keys do
      begin
        TestFramework.Log(Format('%d %s %d %d %s %s', [
          I, addr.ToString,
          vPoint1.Sbps[addr].ExpectedNum, vPoint1.Sbps[addr].FactualNum,
          BoolToStr(vPoint2.Sbps[addr].ExpectedNum = vPoint1.Sbps[addr].ExpectedNum, True),
          BoolToStr(vPoint2.Sbps[addr].FactualNum = vPoint1.Sbps[addr].FactualNum, True)]));
      end;
    end;
  finally
    vLevelDB1.Close;
    vLevelDB2.Close;
  end;
end;

end.
