unit Ledger.Chain.Sync.Cache.Segment.Test;

interface

uses
  DUnitX.TestFramework,
  Interfaces,
  Ledger.Chain.Sync.Cache.Cache.Item,
  Ledger.Chain.Sync.Cache.Cache.Item.Test,
  Ledger.Chain.Sync.Cache.Reader,
  Ledger.Chain.Sync.Cache.Reader.Test,
  Ledger.Chain.Sync.Cache.Segment,
  Ledger.Chain.Sync.Cache.Sync.Cache,
  Ledger.Chain.Sync.Cache.Sync.Cache.Test,
  Ledger.Chain.Sync.Cache.Writer,
  System.SysUtils;

type
  [TestFixture]
  TSegmentTest = class(TObject)
  public
    [Test]
    procedure TestNewSegmentByFilename;
  end;

implementation

procedure TSegmentTest.TestNewSegmentByFilename;
var
  vName: string;
  vSeg: ISegment;
begin
  // Test case 1: Filename without extension
  vName := 'f_100_0000000000000000000000000000000000000000000000000000000000000001_200_0000000000000000000000000000000000000000000000000000000000000002';
  vSeg := NewSegmentByFilename(vName);
  Assert.AreEqual(UInt64(100), vSeg.From, 'Incorrect From value for filename without extension');
  Assert.AreEqual(UInt64(200), vSeg.To, 'Incorrect To value for filename without extension');

  // Test case 2: Filename with extension
  vName := 'f_100_0000000000000000000000000000000000000000000000000000000000000001_200_0000000000000000000000000000000000000000000000000000000000000002.v';
  // This call just ensures no exception is raised, which is equivalent to the Go test's err check.
  vSeg := NewSegmentByFilename(vName);
  Assert.AreEqual(UInt64(100), vSeg.From, 'Incorrect From value for filename with extension');
  Assert.AreEqual(UInt64(200), vSeg.To, 'Incorrect To value for filename with extension');
end;

end.
