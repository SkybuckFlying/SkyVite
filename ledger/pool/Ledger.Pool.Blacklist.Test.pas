unit V2.Ledger.Pool.Blacklist.Test;

interface

uses
  TestFramework,
  System.SysUtils,
  System.Classes,
  System.Threading,
  V2.Common,
  V2.Common.Types,
  V2.Ledger.Pool.Blacklist;

type
  [TestFixture]
  TBlacklistTest = class(TObject)
  public
    [Test]
    procedure TestBlacklist_AddAddTimeout;
  end;

implementation

{ TBlacklistTest }

procedure TBlacklistTest.TestBlacklist_AddAddTimeout;
var
  Blacklist: IBlacklist;
  Hash: THash;
begin
  Blacklist := TBlacklist.Create;
  Assert.IsNotNull(Blacklist, 'Failed to create blacklist');

  Hash := MockHash(10);
  Blacklist.AddAddTimeout(Hash, 5 * 1000); // 5 seconds in milliseconds

  Assert.IsTrue(Blacklist.Exists(Hash), 'Hash should exist immediately after being added');

  TThread.Sleep(7 * 1000); // Wait for 7 seconds

  Assert.IsFalse(Blacklist.Exists(Hash), 'Hash should not exist after timeout');

  // Add it again
  Blacklist.AddAddTimeout(Hash, 5 * 1000);
  Assert.IsTrue(Blacklist.Exists(Hash), 'Hash should exist again after being re-added');
end;

initialization
  RegisterTest(TBlacklistTest.Suite);
end;
