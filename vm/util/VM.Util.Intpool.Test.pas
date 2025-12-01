unit vm.util.intpool_test;

interface

uses
  DUnitX.TestFramework,
  vm.util.intpool,
  GoToDelphi.Helpers.BigInt,
  SysUtils;

type
  [TestFixture]
  TIntPoolTests = class(TObject)
  public
    [Test]
    procedure TestIntPoolPoolGet;
    [Test]
    procedure TestIntPoolPoolPut;
    [Test]
    procedure TestIntPoolPoolReUse;
    [Test]
    procedure TestIntPool;
  end;

implementation

procedure TIntPoolTests.TestIntPoolPoolGet;
var
  nip: TIntPool;
begin
  TIntPoolPool.PoolOfIntPools.FPools.Clear;
  nip := TIntPoolPool.PoolOfIntPools.Get;
  Assert.IsNotNull(nip, 'Invalid pool allocation');
end;

procedure TIntPoolTests.TestIntPoolPoolPut;
var
  nip: TIntPool;
begin
  TIntPoolPool.PoolOfIntPools.FPools.Clear;
  nip := TIntPoolPool.PoolOfIntPools.Get;
  Assert.AreEqual(0, TIntPoolPool.PoolOfIntPools.FPools.Count, 'Pool got added to list when none should have been');

  TIntPoolPool.PoolOfIntPools.Put(nip);
  Assert.AreEqual(1, TIntPoolPool.PoolOfIntPools.FPools.Count, 'Pool did not get added to list when one should have been');
end;

procedure TIntPoolTests.TestIntPoolPoolReUse;
var
  nip: TIntPool;
begin
  TIntPoolPool.PoolOfIntPools.FPools.Clear;
  nip := TIntPoolPool.PoolOfIntPools.Get;
  TIntPoolPool.PoolOfIntPools.Put(nip);
  TIntPoolPool.PoolOfIntPools.Get;

  Assert.AreEqual(0, TIntPoolPool.PoolOfIntPools.FPools.Count, 'Invalid number of pools');
end;

procedure TIntPoolTests.TestIntPool;
var
  pool: TIntPool;
  val: TBigInt;
begin
  pool := TIntPool.Create;
  try
    Assert.IsNotNull(pool.Get, 'Get element from empty pool failed');
    val := TBigInt.Create(1);
    pool.Put([val]);
    Assert.IsNotNull(pool.Get, 'Get element from non-empty pool failed');

    Assert.AreEqual(0, pool.GetZero.CompareTo(TBigInt.Create(0)), 'Get zero from pool failed');
  finally
    pool.Free;
  end;
end;

initialization
  RegisterTestFixture(TIntPoolTests);
end.
