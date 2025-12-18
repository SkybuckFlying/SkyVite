unit Ledger.Onroad.Pool.Types.Test;

interface

uses
  Common.Types,
  DUnitX.TestFramework,
  Ledger.Onroad.Pool.Caller.Cache.Test,
  Ledger.Onroad.Pool.Contract.Pool,
  Ledger.Onroad.Pool.Error.Table,
  Ledger.Onroad.Pool.Pool,
  Ledger.Onroad.Pool.Storage,
  Ledger.Onroad.Pool.Storage.Test,
  Ledger.Onroad.Pool.Types,
  System.SysUtils;

type
  [TestFixture]
  TTypesTest = class(TObject)
  public
    [Test]
    procedure TestOrHeightValue;
    [Test]
    procedure TestOrHeightValueDirtyTxs;
  end;

implementation

uses
  System.Generics.Collections;

procedure TTypesTest.TestOrHeightValue;
var
  vI0, vI1, vI2: UInt32;
  vTxs: TArray<TOnroadTx>;
  vVal: TOrHeightValue;
  vTx: TOnroadTx;
begin
  vI0 := 0;
  vI1 := 1;
  vI2 := 2;

  SetLength(vTxs, 3);
  vTxs[0].mFromAddr := Default(TAddress);
  vTxs[0].mToAddr := Default(TAddress);
  vTxs[0].mFromHeight := 2;
  vTxs[0].mFromHash := TDataHash.FromBytes([2]);
  vTxs[0].mFromIndex := @vI2;

  vTxs[1].mFromAddr := Default(TAddress);
  vTxs[1].mToAddr := Default(TAddress);
  vTxs[1].mFromHeight := 0;
  vTxs[1].mFromHash := TDataHash.FromBytes([0]);
  vTxs[1].mFromIndex := @vI0;

  vTxs[2].mFromAddr := Default(TAddress);
  vTxs[2].mToAddr := Default(TAddress);
  vTxs[2].mFromHeight := 0;
  vTxs[2].mFromHash := TDataHash.FromBytes([1]);
  vTxs[2].mFromIndex := @vI1;

  vVal := NewOrHeightValueFromOnroadTxs(vTxs);
  vTx := MinTx(vVal);
  Assert.AreEqual(UInt32(0), vTx.mFromIndex^);
end;

procedure TTypesTest.TestOrHeightValueDirtyTxs;
var
  vI0, vI1, vI2: UInt32;
  vTxs: TArray<TOnroadTx>;
  vVal: TOrHeightValue;
  vDirtyTxs: TArray<TOnroadTx>;
  vI: Integer;
  vJ: UInt32;
begin
  vI0 := 0;
  vI1 := 1;
  vI2 := 2;

  SetLength(vTxs, 5);
  vTxs[0].mFromAddr := Default(TAddress);
  vTxs[0].mToAddr := Default(TAddress);
  vTxs[0].mFromHeight := 2;
  vTxs[0].mFromHash := TDataHash.FromBytes([2]);
  vTxs[0].mFromIndex := @vI2;

  vTxs[1].mFromAddr := Default(TAddress);
  vTxs[1].mToAddr := Default(TAddress);
  vTxs[1].mFromHeight := 0;
  vTxs[1].mFromHash := TDataHash.FromBytes([0]);
  vTxs[1].mFromIndex := @vI0;

  vTxs[2].mFromAddr := Default(TAddress);
  vTxs[2].mToAddr := Default(TAddress);
  vTxs[2].mFromHeight := 0;
  vTxs[2].mFromHash := TDataHash.FromBytes([3]);
  vTxs[2].mFromIndex := nil;

  vTxs[3].mFromAddr := Default(TAddress);
  vTxs[3].mToAddr := Default(TAddress);
  vTxs[3].mFromHeight := 0;
  vTxs[3].mFromHash := TDataHash.FromBytes([1]);
  vTxs[3].mFromIndex := @vI1;

  vTxs[4].mFromAddr := Default(TAddress);
  vTxs[4].mToAddr := Default(TAddress);
  vTxs[4].mFromHeight := 0;
  vTxs[4].mFromHash := TDataHash.FromBytes([4]);
  vTxs[4].mFromIndex := nil;

  vVal := NewOrHeightValueFromOnroadTxs(vTxs);
  vDirtyTxs := DirtyTxs(vVal);
  Assert.AreEqual(2, Length(vDirtyTxs));
  Assert.AreEqual(TDataHash.FromBytes([3]), vDirtyTxs[0].mFromHash);
  Assert.AreEqual(TDataHash.FromBytes([4]), vDirtyTxs[1].mFromHash);

  for vI := 0 to High(vDirtyTxs) do
  begin
    vJ := vI;
    vDirtyTxs[vI].mFromIndex := @vJ;
  end;

  vDirtyTxs := DirtyTxs(vVal);
  Assert.AreEqual(0, Length(vDirtyTxs));
end;

initialization
  TDUnitX.RegisterTestFixture(TTypesTest);
end.
