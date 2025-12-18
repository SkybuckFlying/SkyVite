unit Ledger.Consensus.ConsensusPointArray.Test;

interface

uses
  Common.Types,
  Delphi.Mocks,
  DUnitX.TestFramework,
  Go.leveldb,
  Ledger.Consensus.API,
  Ledger.Consensus.CDB,
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
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Simple.Test,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.ConsensusPointArray,
  Ledger.Consensus.Core,
  Ledger.Consensus.Dpos,
  Ledger.Consensus.Mock.Ch,
  Ledger.Consensus.Mock.DposReader,
  Ledger.Consensus.Mock.Linkedarray,
  Ledger.Consensus.Mock.Rollback.Proof,
  Ledger.Consensus.Result,
  Ledger.Consensus.Rollback.Proof,
  Ledger.Consensus.Rollback.Proof.Test,
  Ledger.Consensus.Snapshot.Listener,
  Ledger.Consensus.Subscriber,
  Ledger.Consensus.Trigger,
  Ledger.Consensus.Unittest.Util.Test,
  Ledger.Test_Tools,
  Log15,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  V2.Interfaces.Core;

type
  [TestFixture]
  TConsensusPointArrayTest = class(TObject)
  public
    [Test]
    procedure TestPeriodLinkedArray_GetByIndex;
    [Test]
    procedure TestHourLinkedArray_GetByIndex;
  end;

implementation

uses
  System.DateUtils,
  System.Math.BigInt,
  Common.Address,
  Common.Hex;

function GenSnapshotBlockForTest(ParaHeight: UInt64; ParaHexPubKey: string; ParaPrevHash: THash; ParaT: TDateTime): ISnapshotBlock;
var
  vPub: TBytes;
  vBlock: ISnapshotBlock;
begin
  vPub := THex.DecodeString(ParaHexPubKey);
  vBlock := TSnapshotBlock.Create;
  vBlock.Hash := Default(THash);
  vBlock.PrevHash := ParaPrevHash;
  vBlock.Height := ParaHeight;
  vBlock.PublicKey := vPub;
  vBlock.Signature := nil;
  vBlock.Timestamp := ParaT;
  vBlock.Seed := 0;
  vBlock.SeedHash := nil;
  vBlock.SnapshotContent := nil;
  vBlock.Hash := vBlock.ComputeHash;
  Result := vBlock;
end;

function GenHashArr(ParaMax: Integer): TArray<THash>;
var
  vIndex: Integer;
begin
  SetLength(Result, ParaMax);
  for vIndex := 0 to ParaMax - 1 do
  begin
    Result[vIndex] := MockHash(vIndex);
  end;
end;

{ TConsensusPointArrayTest }

procedure TConsensusPointArrayTest.TestPeriodLinkedArray_GetByIndex;
var
  vMockChain: TMock<IChain>;
  vMockProof: TMock<IRollbackProof>;
  vSimple: ISimpleCs;
  vB1, vB2, vB3, vB4, vB5, vB6: ISnapshotBlock;
  vR: TArray<ISnapshotBlock>;
  vStime, vEtime: TDateTime;
  vPeriods: ILinkedArray;
  vPoint: TPoint;
  vSimpleGenesis: TDateTime;
  vErr: Exception;
begin
  vSimpleGenesis := EncodeDateTime(2018, 10, 24, 0, 0, 0, 0);
  vMockChain := TMock<IChain>.Create;
  vMockProof := TMock<IRollbackProof>.Create;
  vSimple := NewSimpleCs(TLogger.Create);

  vB1 := GenSnapshotBlockForTest(1, '3fc5224e59433bff4f48c83c0eb4edea0e4c42ea697e04cdec717d03e50d5200', Default(THash), vSimpleGenesis);
  vB2 := GenSnapshotBlockForTest(2, '3fc5224e59433bff4f48c83c0eb4edea0e4c42ea697e04cdec717d03e50d5200', vB1.Hash, IncSecond(vSimpleGenesis, 1));
  vB3 := GenSnapshotBlockForTest(3, '3fc5224e59433bff4f48c83c0eb4edea0e4c42ea697e04cdec717d03e50d5200', vB2.Hash, IncSecond(vSimpleGenesis, 2));
  vB4 := GenSnapshotBlockForTest(4, 'e0de77ffdc2719eb1d8e89139da9747bd413bfe59781c43fc078bb37d8cbd77a', vB3.Hash, IncSecond(vSimpleGenesis, 3));
  vB5 := GenSnapshotBlockForTest(5, 'e0de77ffdc2719eb1d8e89139da9747bd413bfe59781c43fc078bb37d8cbd77a', vB4.Hash, IncSecond(vSimpleGenesis, 4));
  vB6 := GenSnapshotBlockForTest(6, 'e0de77ffdc2719eb1d8e89139da9747bd413bfe59781c43fc078bb37d8cbd77a', vB5.Hash, IncSecond(vSimpleGenesis, 5));

  vMockChain.Setup.WillReturn(False).When.IsGenesisSnapshotBlock(It.IsAny<THash>);
  SetLength(vR, 6);
  vR[0] := vB6; vR[1] := vB5; vR[2] := vB4; vR[3] := vB3; vR[4] := vB2; vR[5] := vB1;
  vMockChain.Setup.WillReturn(vR).When.GetSnapshotHeadersAfterOrEqualTime(It.IsAny<IHashHeight>, It.IsAny<TDateTime>, It.IsAny<TAddress>);
  vMockChain.Setup.WillReturn(vB6).When.GetSnapshotBlockByHash(vB6.Hash);

  vStime, vEtime := vSimple.Index2Time(0);
  vMockProof.Setup.WillReturn(False).When.ProofEmpty(vStime, vEtime);
  vMockProof.Setup.WillReturn(vB6.Hash).When.ProofHash(vEtime);

  vPeriods := NewPeriodPointArray(vMockChain.Instance, vSimple, vMockProof.Instance, TLogger.Create);
  TValue.Make(vPeriods.GetByIndex(0), vPoint, vErr);
  Assert.IsNull(vErr);

  Assert.AreEqual(UInt32(3), vPoint.Sbps[vB1.Producer].FactualNum);
  Assert.AreEqual(UInt32(3), vPoint.Sbps[vB1.Producer].ExpectedNum);
  Assert.AreEqual(UInt32(3), vPoint.Sbps[vB4.Producer].FactualNum);
  Assert.AreEqual(UInt32(3), vPoint.Sbps[vB4.Producer].ExpectedNum);
  Assert.AreEqual(Default(THash), vPoint.PrevHash);
  Assert.AreEqual(vB6.Hash, vPoint.Hash);
end;

procedure TConsensusPointArrayTest.TestHourLinkedArray_GetByIndex;
var
  vDb: TLevelDB;
  vConsensusDB: TConsensusDB;
  vNum: Integer;
  vHashArr: TArray<THash>;
  vMockPeriods: TMock<ILinkedArray>;
  vMockProof: TMock<IRollbackProof>;
  vSbps: TDictionary<TAddress, TContent>;
  vAddr1, vAddr2: TAddress;
  vIndex: Integer;
  vArray: ILinkedArray;
  vStime, vEtime: TDateTime;
  vPoint: TPoint;
  vErr: Exception;
begin
  vDb := NewDb(UnitTestDir);
  try
    vConsensusDB := TConsensusDB.Create(vDb);
    vNum := 48;
    vHashArr := GenHashArr(vNum + 1);
    vMockPeriods := TMock<ILinkedArray>.Create;
    vMockProof := TMock<IRollbackProof>.Create;

    vSbps := TDictionary<TAddress, TContent>.Create;
    vAddr1 := THex.ToAddress('vite_360232b0378111b122685a15e612143dc9a89cfa7e803f4b5a');
    vSbps.Add(vAddr1, TContent.Create(10, 8));
    vAddr2 := THex.ToAddress('vite_826a1ab4c85062b239879544dc6b67e3b5ce32d0a1eba21461');
    vSbps.Add(vAddr2, TContent.Create(9, 7));

    for vIndex := 0 to vNum - 1 do
    begin
      vMockPeriods.Setup.WillReturn(TTuple<TPoint, Exception>.Create(TPoint.Create(vHashArr[vIndex], vHashArr[vIndex + 1], vSbps), nil)).When.GetByIndexWithProof(vIndex, It.IsAny<THash>);
    end;

    vArray := NewHourLinkedArray(vMockPeriods.Instance, vConsensusDB, vMockProof.Instance, TTimeSpan.FromSeconds(75), Now, TLogger.Create);
    vStime, vEtime := vArray.Index2Time(0);
    vMockProof.Setup.WillReturn(False).When.ProofEmpty(vStime, vEtime);
    vMockProof.Setup.WillReturn(vHashArr[vNum]).When.ProofHash(vEtime);

    TValue.Make(vArray.GetByIndex(0), vPoint, vErr);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vPoint);
    Assert.AreEqual(2, vPoint.Sbps.Count);
    Assert.AreEqual(vSbps[vAddr1].FactualNum * vNum, vPoint.Sbps[vAddr1].FactualNum);
    Assert.AreEqual(vSbps[vAddr1].ExpectedNum * vNum, vPoint.Sbps[vAddr1].ExpectedNum);
    Assert.AreEqual(vSbps[vAddr2].FactualNum * vNum, vPoint.Sbps[vAddr2].FactualNum);
    Assert.AreEqual(vSbps[vAddr2].ExpectedNum * vNum, vPoint.Sbps[vAddr2].ExpectedNum);

    // Test for db cache
    TValue.Make(vArray.GetByIndex(0), vPoint, vErr);
    Assert.IsNull(vErr);
    Assert.IsNotNull(vPoint);
    Assert.AreEqual(2, vPoint.Sbps.Count);
    Assert.AreEqual(vSbps[vAddr1].FactualNum * vNum, vPoint.Sbps[vAddr1].FactualNum);
    Assert.AreEqual(vSbps[vAddr1].ExpectedNum * vNum, vPoint.Sbps[vAddr1].ExpectedNum);
    Assert.AreEqual(vSbps[vAddr2].FactualNum * vNum, vPoint.Sbps[vAddr2].FactualNum);
    Assert.AreEqual(vSbps[vAddr2].ExpectedNum * vNum, vPoint.Sbps[vAddr2].ExpectedNum);

  finally
    ClearDb(UnitTestDir);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TConsensusPointArrayTest);

end.
