unit Ledger.Consensus.CDB.Point.Test;

interface

uses
  DUnitX.TestFramework,
  Ledger.Consensus.CDB.Consensus,
  Ledger.Consensus.CDB.DB.Test,
  Ledger.Consensus.CDB.Point,
  System.SysUtils;

type
  [TestFixture]
  TPointTest = class(TObject)
  public
    [Test]
    procedure TestContent_Copy;
  end;

implementation

{ TPointTest }

procedure TPointTest.TestContent_Copy;
var
  vPoint: IContent;
  vCopy: IContent;
begin
  vPoint := TContent.Create(13, 11);
  vCopy := vPoint.Copy;
  vCopy.FactualNum := 10;

  TestFramework.Log(Format('%d %d', [vCopy.FactualNum, vPoint.FactualNum]));

  Assert.AreEqual(Cardinal(10), vCopy.FactualNum);
  Assert.AreEqual(Cardinal(11), vPoint.FactualNum);
end;

end.
