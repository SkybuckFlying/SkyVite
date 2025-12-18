unit Ledger.Chain.Sync.Cache.Cache.Item.Test;

interface

uses
  Common.Types,
  DUnitX.TestFramework,
  Interfaces,
  Ledger.Chain.Sync.Cache.Cache.Item,
  Ledger.Chain.Sync.Cache.Reader,
  Ledger.Chain.Sync.Cache.Reader.Test,
  Ledger.Chain.Sync.Cache.Segment,
  Ledger.Chain.Sync.Cache.Segment.Test,
  Ledger.Chain.Sync.Cache.Sync.Cache,
  Ledger.Chain.Sync.Cache.Sync.Cache.Test,
  Ledger.Chain.Sync.Cache.Writer,
  System.SysUtils;

type
  [TestFixture]
  TCacheItemTest = class(TObject)
  public
    [Test]
    procedure TestCacheItem_Serialize;
  end;

implementation

uses
  System.Security.Cryptography;

procedure TCacheItemTest.TestCacheItem_Serialize;
var
  vC, vC2: TCacheItem;
  vData: TBytes;
  I: Integer;
  Rng: IRandom;
begin
  vC := TCacheItem.Create;
  try
    vC.Segment.From := 101;
    vC.Segment.To := 1000;

    Rng := TGenerateRandom.Create;
    Rng.NextBytes(vC.Hash);
    Rng.NextBytes(vC.PrevHash);

    vC.Segment.Points := nil;
    vC.done := True;
    vC.verified := True;
    vC.filename := 'chunk101_1000';
    vC.size := 1837;

    vData := vC.Serialize;

    vC2 := TCacheItem.Create;
    try
      vC2.DeSerialize(vData);

      Assert.IsTrue(vC.Segment.Equal(vC2.Segment), 'different segment');

      Assert.AreEqual(Length(vC.Points), Length(vC2.Points), 'different points length');
      for I := 0 to High(vC.Points) do
      begin
        Assert.AreEqual(vC.Points[I].Height, vC2.Points[I].Height, 'different point height');
        Assert.IsTrue(vC.Points[I].Hash.IsEqual(vC2.Points[I].Hash), 'different point hash');
      end;

      Assert.AreEqual(vC.verified, vC2.verified, 'different verified');
      Assert.AreEqual(vC.filename, vC2.filename, 'different filename');
      Assert.AreEqual(vC.done, vC2.done, 'different done');
      Assert.AreEqual(vC.size, vC2.size, 'different size');
    finally
      vC2.Free;
    end;
  finally
    vC.Free;
  end;
end;

end.
