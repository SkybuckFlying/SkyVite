unit Ledger.Consensus.ConsensusSimple.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Ledger.Consensus.ConsensusSimple,
  Log15;

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