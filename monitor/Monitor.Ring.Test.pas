unit Monitor.Ring.Test;

interface

uses
  DUnitX.TestFramework,
  Monitor.Ring;

type
  [TestFixture]
  TRingTests = class(TObject)
  public
    [Test]
    procedure TestRing;
  end;

implementation

uses
  System.SysUtils;

{ TRingTests }

procedure TRingTests.TestRing;
var
  vRing: TRing;
  vAll: TArray<TObject>;
  vIndex: Integer;
begin
  vRing := TRing.Create(10);
  try
    vRing.Add(TObject(0));
    vRing.Add(TObject(1));
    vRing.Add(TObject(2));
    vAll := vRing.All;
    Assert.AreEqual(3, Length(vAll));

    vRing.Reset;
    vAll := vRing.All;
    Assert.AreEqual(0, Length(vAll));

    vRing.Add(TObject(10));
    vRing.Add(TObject(11));
    vAll := vRing.All;
    Assert.AreEqual(2, Length(vAll));

    vRing.Reset;
    for vIndex := 0 to 11 do
      vRing.Add(TObject(vIndex));

    vAll := vRing.All;
    Assert.AreEqual(10, Length(vAll));
  finally
    vRing.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TRingTests);
end.