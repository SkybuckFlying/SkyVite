unit Wallet.Account.Test;

interface

uses
  DUnitX.TestFramework,
  GoToDelphi.Helpers.TBytes,
  SysUtils,
  Vite.Common.Types,
  Vite.Crypto,
  Wallet.Account,
  Wallet.Manager,
  Wallet.Manager.Test,
  Wallet.Wallet;

type
  [TestFixture]
  TTestAccount = class
  public
    [Test]
    procedure TestAccount;
  end;

implementation

procedure TTestAccount.TestAccount;
var
  vAcc: IAccount;
  vAcc2: IAccount;
  vMsg: TBytes;
  vSig: TBytes;
  vPub: TEd25519PublicKey;
begin
  vAcc := TAccount.RandomAccount;
  Assert.IsNotNull(vAcc, 'Failed to create random account');

  vMsg := TEncoding.UTF8.GetBytes('hello world');
  vSig := vAcc.Sign(vMsg, vPub);

  Assert.IsTrue(vAcc.Verify(vPub, vMsg, vSig), 'Failed to verify signature');

  vAcc2 := TAccount.NewAccountFromHexKey(vAcc.PrivateKey.ToHex);
  Assert.IsNotNull(vAcc2, 'Failed to create account from hex key');

  Assert.AreEqual(vAcc.PrivateKey.ToHex, vAcc2.PrivateKey.ToHex);
  Assert.AreEqual(vAcc.Address.ToHex, vAcc2.Address.ToHex);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAccount);
end.
