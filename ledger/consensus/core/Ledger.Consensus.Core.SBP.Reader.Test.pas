unit Ledger.Consensus.Core.SBP.Reader.Test;

interface

uses
  BigNumbers,
  DUnitX.TestFramework,
  Ledger.Consensus.Core.Consensus,
  Ledger.Consensus.Core.Group,
  Ledger.Consensus.Core.Group.Test,
  Ledger.Consensus.Core.Mock.SBP.Reader,
  Ledger.Consensus.Core.SBP.Reader,
  Ledger.Consensus.Core.State.Reader,
  Ledger.Consensus.Core.Time.Index,
  Ledger.Consensus.Core.Time.Index.Test,
  Ledger.Consensus.Core.Utils,
  Ledger.Consensus.Core.Vote.Algo,
  Ledger.Consensus.Core.Vote.Algo.Test,
  System.SysUtils;

type
  [TestFixture]
  TSBPReaderTest = class(TObject)
  public
    [Test]
    procedure TestBigInt;
  end;

implementation

{ TSBPReaderTest }

procedure TSBPReaderTest.TestBigInt;
var
  vN, vBt, vBt2: TBigInteger;
begin
  vN := TBigInteger.Create(10);
  vBt := vN; // In Delphi, TBigInteger is a value type, so this is a copy.

  // The Go test demonstrates pointer behavior.
  // The Delphi equivalent is more about how value types are handled.
  // Directly setting vBt2 to 11.
  vBt2 := TBigInteger.Create(11);
  vBt := vBt2; // To replicate the Go test's mutation through pointer.

  TestFramework.Log(Format('%s %s', [vBt.ToString, vBt2.ToString]));

  Assert.AreEqual('11', vBt.ToString);
  Assert.AreEqual('11', vBt2.ToString);
end;

end.
