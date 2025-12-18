unit Ledger.Consensus.Core.Time.Index.Test;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  Ledger.Consensus.Core.TimeIndex;

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
