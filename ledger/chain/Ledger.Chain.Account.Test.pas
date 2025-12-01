unit V2.Ledger.Chain.Test.Account;

interface

uses
  DUnitX.TestFramework,
  V2.Ledger.Chain,
  V2.Common.Types,
  V2.Interfaces.Core;

type
  [TestFixture]
  TAccountTest = class
  public
    [Test]
    procedure TestChain_Account;
  end;

implementation

uses
  System.SysUtils,
  V2.Ledger.Chain.Test.Utils;

procedure TestAccount(AChain: IChain; AAccounts: TDictionary<TAddress, TAccount>);
var
  LAccountIdList: TArray<TUInt64>;
  LAddr: TAddress;
  LAccount: TAccount;
  LAccountId: TUInt64;
  LQueryAddr2: TAddress;
  LQueryAccountId: TUInt64;
begin
  SetLength(LAccountIdList, 0);
  for LAddr in AAccounts.Keys do
  begin
    LAccount := AAccounts[LAddr];
    LAccountId := AChain.GetAccountId(LAddr);
    if LAccountId <= 0 then
    begin
      if LAccount.LatestBlock = nil then
        Continue;
      Assert.Fail('accountId <= 0, ' + LAddr.ToString + ', ' + LAccount.LatestBlock.ToString);
    end;
    LQueryAddr2 := AChain.GetAccountAddress(LAccountId);
    Assert.AreEqual(LQueryAddr2, LAddr);
    LAccountIdList := LAccountIdList + [LAccountId];
  end;

  for LAccountId in LAccountIdList do
  begin
    LAddr := AChain.GetAccountAddress(LAccountId);
    Assert.IsNotNull(LAddr, 'Addr is nil');
    LQueryAccountId := AChain.GetAccountId(LAddr);
    Assert.AreEqual(LQueryAccountId, LAccountId);
  end;
end;

{ TAccountTest }

procedure TAccountTest.TestChain_Account;
var
  LChain: IChain;
  LAccounts: TDictionary<TAddress, TAccount>;
begin
  LChain := SetUp(1000, 1000, 8, LAccounts);
  TestAccount(LChain, LAccounts);
  TearDown(LChain);
end;

end.
