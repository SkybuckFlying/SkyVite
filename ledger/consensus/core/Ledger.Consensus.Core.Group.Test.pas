unit Ledger.Consensus.Core.Group.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Generics.Collections,
  Common.Types,
  Common,
  Interfaces.Core,
  Ledger.Consensus.Core.Group;

type
  [TestFixture]
  TGroupInfoTest = class(TObject)
  public
    [Test]
    procedure TestNewGroupInfo;
    [Test]
    procedure TestGroupInfo_Time2Index;
    [Test]
    procedure TestGroupInfo_GenPlan;
  end;

function GenAddress(AN: Integer): TArray<TAddress>;

implementation

function GenAddress(AN: Integer): TArray<TAddress>;
var
  I: Integer;
begin
  SetLength(Result, AN);
  for I := 0 to AN - 1 do
  begin
    Result[I] := TCommon.MockAddress(I);
  end;
end;

{ TGroupInfoTest }

procedure TGroupInfoTest.TestNewGroupInfo;
var
  vGenesis: TDateTime;
  vInfo: TGroupInfo;
  vIdx: UInt64;
  vSTime, vETime: TDateTime;
begin
  vGenesis := Now;
  vInfo := TGroupInfo.Create(vGenesis, TConsensusGroupInfo.Create(SNAPSHOT_GID, 25, 3, 1, 2, 100, 1, 1, ViteTokenId, 0, nil, 0, nil, TAddress.Empty, nil, 0));
  try
    vIdx := vInfo.TimeIndex.Time2Index(vGenesis);
    Assert.AreEqual(UInt64(0), vIdx);

    vSTime := vInfo.TimeIndex.Index2Time(0);
    vETime := vSTime + TTimeSpan.FromSeconds(vInfo.PlanInterval);
    Assert.AreEqual(vGenesis, vSTime, 'Start time for index 0 mismatch');
    Assert.AreEqual(IncSecond(vGenesis, 75), vETime, 'End time for index 0 mismatch');

    vSTime := vInfo.TimeIndex.Index2Time(1);
    vETime := vSTime + TTimeSpan.FromSeconds(vInfo.PlanInterval);
    Assert.AreEqual(IncSecond(vGenesis, 75), vSTime, 'Start time for index 1 mismatch');
    Assert.AreEqual(IncSecond(vGenesis, 150), vETime, 'End time for index 1 mismatch');
  finally
    vInfo.Free;
  end;
end;

procedure TGroupInfoTest.TestGroupInfo_Time2Index;
var
  vNow: TDateTime;
  vInfo: TGroupInfo;
  vIndex: UInt64;
  vN, I: UInt64;
  vSTime, vETime: TDateTime;
begin
  vNow := Now;
  vInfo := TGroupInfo.Create(vNow, TConsensusGroupInfo.Create(SNAPSHOT_GID, 25, 1, 3, 0, 0, 1, 0, ViteTokenId, 0, nil, 0, nil, TAddress.Empty, nil, 0));
  try
    vIndex := vInfo.TimeIndex.Time2Index(vNow);
    Assert.AreEqual(UInt64(0), vIndex);

    vIndex := vInfo.TimeIndex.Time2Index(IncSecond(vNow, 1));
    Assert.AreEqual(UInt64(0), vIndex);

    vIndex := vInfo.TimeIndex.Time2Index(IncSecond(vNow, 74));
    Assert.AreEqual(UInt64(0), vIndex);

    vIndex := vInfo.TimeIndex.Time2Index(IncSecond(vNow, 75));
    Assert.AreEqual(UInt64(1), vIndex);

    vIndex := vInfo.TimeIndex.Time2Index(IncSecond(vNow, 150));
    Assert.AreEqual(UInt64(2), vIndex);

    vN := 100;
    for I := 0 to vN - 1 do
    begin
      vSTime := vInfo.TimeIndex.Index2Time(I);
      vETime := vSTime + TTimeSpan.FromSeconds(vInfo.PlanInterval);
      Assert.AreEqual(IncSecond(vNow, 25 * 3 * I), vSTime);
      Assert.AreEqual(IncSecond(vNow, 25 * 3 * (I + 1)), vETime);
    end;

  finally
    vInfo.Free;
  end;
end;

procedure TGroupInfoTest.TestGroupInfo_GenPlan;
var
  vNow: TDateTime;
  vInfo: TGroupInfo;
  vPlans: TArray<TMemberPlan>;
  vN: UInt64;
begin
  vNow := Now;
  vInfo := TGroupInfo.Create(vNow, TConsensusGroupInfo.Create(SNAPSHOT_GID, 10, 6, 3, 0, 100, 1, 0, TTokenTypeId.Empty, 0, nil, 0, nil, TAddress.Empty, nil, 0));
  try
    vN := 10;
    vPlans := vInfo.GenPlanByAddress(0, GenAddress(vN));
    Assert.AreEqual(30, Length(vPlans));

    vPlans := vInfo.GenPlanByAddress(0, GenAddress(11));
    Assert.AreEqual(0, Length(vPlans));
  finally
    vInfo.Free;
  end;
end;

end.
