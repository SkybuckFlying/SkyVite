unit Ledger.Consensus.Core.Time.Index.Test;

interface

uses
  DUnitX.TestFramework,
  Ledger.Consensus.Core.Consensus,
  Ledger.Consensus.Core.Group,
  Ledger.Consensus.Core.Group.Test,
  Ledger.Consensus.Core.Mock.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader.Test,
  Ledger.Consensus.Core.State.Reader,
  Ledger.Consensus.Core.Time.Index,
  Ledger.Consensus.Core.TimeIndex,
  Ledger.Consensus.Core.Utils,
  Ledger.Consensus.Core.Vote.Algo,
  Ledger.Consensus.Core.Vote.Algo.Test,
  System.SysUtils;

type
  [TestFixture]
  TTimeIndexTest = class(TObject)
  public
    [Test]
    procedure Test_Time2Index;
  end;

implementation

uses
  System.DateUtils;

{ TTimeIndexTest }

procedure TTimeIndexTest.Test_Time2Index;
var
  vGenesis, vT2: TDateTime;
  vTI: ITimeIndex;
  vIndex: UInt64;
begin
  // UnixToDateTime takes a Unix timestamp (seconds from epoch) and returns TDateTime.
  vGenesis := UnixToDateTime(1552708800);
  vTI := TTimeIndex.Create(vGenesis, TTimeSpan.FromHours(24));

  vT2 := UnixToDateTime(1556251200);
  vIndex := vTI.Time2Index(vT2);

  Assert.AreEqual(UInt64(41), vIndex);
end;

end.
