unit Ledger.Consensus.ConsensusSimple.Test;

interface

uses
  DUnitX.TestFramework,
  Ledger.Consensus.API,
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
  Ledger.Consensus.Consensus.Point.Array.Test,
  Ledger.Consensus.Consensus.Simple,
  Ledger.Consensus.Consensus.Snapshot,
  Ledger.Consensus.Consensus.Snapshot.Test,
  Ledger.Consensus.Consensus.Test,
  Ledger.Consensus.Consensus.Verifier,
  Ledger.Consensus.ConsensusSimple,
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
  Log15,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils;

type
  [TestFixture]
  TSimpleCsTest = class(TObject)
  public
    [Test]
    procedure TestSimpleCs;
  end;

implementation

uses
  System.DateUtils,
  Ledger.Consensus.Core,
  Common.Types;

{ TSimpleCsTest }

procedure TSimpleCsTest.TestSimpleCs;
var
  CS: ISimpleCs;
  Info: IGroupInfo;
  STime, ETime: TDateTime;
  Result: IElectionResult;
  I: Integer;
  EleTime: IElectionResult;
  EleIndex: IElectionResult;
  Err: Exception;
begin
  CS := NewSimpleCs(TLogger.Create('unittest', 'simpleCs'));
  Info := CS.GetInfo;
  STime := CS.Index2Time(0).STime;
  ETime := CS.Index2Time(0).ETime;

  // genesis
  Assert.AreEqual(SimpleGenesis, STime);
  // plan interval
  Assert.AreEqual(IncSecond(STime, Info.PlanInterval), ETime);

  TValue.Make(CS.ElectionIndex(0), Result, Err);
  Assert.IsNull(Err);
  Assert.IsNotNull(Result);
  for I := 0 to High(Result.Plans) do
  begin
    Assert.AreEqual(SimpleAddrs[I div 3], Result.Plans[I].Member);
  end;

  TValue.Make(CS.ElectionIndex(1), Result, Err);
  Assert.IsNull(Err);
  Assert.IsNotNull(Result);
  for I := 0 to High(Result.Plans) do
  begin
    Assert.AreEqual(SimpleAddrs[I div 3], Result.Plans[I].Member);
  end;

  STime := CS.Index2Time(1).STime;
  TValue.Make(CS.ElectionTime(STime), EleTime, Err);
  Assert.IsNull(Err);
  TValue.Make(CS.ElectionIndex(1), EleIndex, Err);
  Assert.IsNull(Err);

  Assert.AreEqual(Length(EleIndex.Plans), Length(EleTime.Plans));
  for I := 0 to High(EleIndex.Plans) do
  begin
    Assert.AreEqual(EleIndex.Plans[I].Member, EleTime.Plans[I].Member);
    Assert.AreEqual(EleIndex.Plans[I].STime, EleTime.Plans[I].STime);
  end;

  Assert.AreEqual(TUInt64(0), CS.Time2Index(IncSecond(SimpleGenesis, 1)));
end;

initialization
  TDUnitX.RegisterTestFixture(TSimpleCsTest);

end.
