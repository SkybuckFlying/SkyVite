unit vm.util.quota_test;

interface

uses
  DUnitX.TestFramework,
  vm.util.quota,
  vm.util.errors,
  SysUtils;

type
  [TestFixture]
  TQuotaTests = class(TObject)
  public
    [Test]
    procedure TestCalcQuotaUsed;
    [Test]
    procedure TestUseQuota;
  end;

implementation

procedure TQuotaTests.TestCalcQuotaUsed;
type
  TCalcQuotaUsedTest = record
    quotaTotal, quotaAddition, quotaLeft, qStakeUsed, qUsed: UInt64;
    err: Exception;
  end;
var
  tests: TArray<TCalcQuotaUsedTest>;
  test: TCalcQuotaUsedTest;
  qStakeUsed, qUsed: UInt64;
  i: Integer;
begin
  tests := [
    TCalcQuotaUsedTest.Create(15000, 5000, 10001, 0, 4999, nil),
    TCalcQuotaUsedTest.Create(15000, 5000, 9999, 1, 5001, nil),
    TCalcQuotaUsedTest.Create(10000, 0, 9999, 1, 1, nil),
    TCalcQuotaUsedTest.Create(10000, 0, 5000, 5000, 5000, nil),
    TCalcQuotaUsedTest.Create(15000, 5000, 5000, 5000, 10000, nil),
    TCalcQuotaUsedTest.Create(15000, 5000, 10001, 0, 0, ErrOutOfQuota),
    TCalcQuotaUsedTest.Create(15000, 5000, 9999, 0, 0, ErrOutOfQuota),
    TCalcQuotaUsedTest.Create(10000, 0, 9999, 0, 0, ErrOutOfQuota),
    TCalcQuotaUsedTest.Create(10000, 0, 5000, 0, 0, ErrOutOfQuota),
    TCalcQuotaUsedTest.Create(15000, 5000, 10001, 0, 4999, Exception.Create('')),
    TCalcQuotaUsedTest.Create(15000, 5000, 9999, 1, 5001, Exception.Create('')),
    TCalcQuotaUsedTest.Create(10000, 0, 9999, 1, 1, Exception.Create('')),
    TCalcQuotaUsedTest.Create(10000, 0, 5000, 5000, 5000, Exception.Create('')),
    TCalcQuotaUsedTest.Create(15000, 5000, 5000, 5000, 10000, Exception.Create(''))
  ];

  for i := 0 to Length(tests) - 1 do
  begin
    test := tests[i];
    CalcQuotaUsed(True, test.quotaTotal, test.quotaAddition, test.quotaLeft, test.err, qStakeUsed, qUsed);
    Assert.AreEqual(test.qUsed, qUsed, Format('%d th calculate quota used failed, qUsed', [i]));
    Assert.AreEqual(test.qStakeUsed, qStakeUsed, Format('%d th calculate quota used failed, qStakeUsed', [i]));
  end;
end;

procedure TQuotaTests.TestUseQuota;
type
  TUseQuotaTest = record
    quotaInit, cost, quotaLeft: UInt64;
    err: Exception;
  end;
var
  tests: TArray<TUseQuotaTest>;
  test: TUseQuotaTest;
  quotaLeft: UInt64;
  err: Exception;
begin
  tests := [
    TUseQuotaTest.Create(100, 100, 0, nil),
    TUseQuotaTest.Create(100, 101, 0, ErrOutOfQuota)
  ];

  for test in tests do
  begin
    try
      quotaLeft := UseQuota(test.quotaInit, test.cost);
      err := nil;
    except
      on E: Exception do
      begin
        quotaLeft := 0;
        err := E;
      end;
    end;
    Assert.AreEqual(test.quotaLeft, quotaLeft, 'use quota fail, quotaLeft');
    if test.err = nil then
      Assert.IsNull(err, 'use quota fail, err')
    else
      Assert.AreEqual(test.err.ClassName, err.ClassName, 'use quota fail, err');
  end;
end;

initialization
  RegisterTestFixture(TQuotaTests);
end.
