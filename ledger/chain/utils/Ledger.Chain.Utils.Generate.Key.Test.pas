unit Ledger.Chain.Utils.Generate.Key.Test;

interface

uses
  Common,
  Common.Types,
  DUnitX.TestFramework,
  Interfaces.Core,
  Ledger.Chain.Utils.Conversion,
  Ledger.Chain.Utils.Generate.Key,
  Ledger.Chain.Utils.Key.Prefix,
  Ledger.Chain.Utils.Keys,
  Ledger.Chain.Utils.Keys // Assuming Keys unit defines the key generation functions,
  Ledger.Chain.Utils.Keys.Index.DB,
  Ledger.Chain.Utils.Keys.State.DB,
  Ledger.Chain.Utils.Keys.State.Redo.DB,
  System.SysUtils;

type
  [TestFixture]
  TGenerateKeyTest = class(TObject)
  public
    [Test]
    procedure TestCreateAccountIdKey;
    [Test]
    procedure TestRefill;
    [Test]
    procedure TestCopy;
    [Test]
    procedure TestCopy2;
    [Test]
    procedure TestCreateAccountBlockHashKey;
    [Test]
    procedure TestRefillHeight;
    [Test]
    procedure TestCreateBalanceKey;
    [Test]
    procedure TestCreateBalanceHistoryKey;
    // Benchmarks are not directly translatable to DUnitX but can be performance tested if needed.
  end;

implementation

uses
  System.Diagnostics;

procedure TGenerateKeyTest.TestCreateAccountIdKey;
var
  vKey: TBytes;
begin
  vKey := CreateAccountIdKey(8);
  // Original test prints the bytes. A real test would assert the result.
  // For translation, we'll log it.
  TestFramework.Log(TEncoding.Default.GetString(vKey));
end;

procedure TGenerateKeyTest.TestRefill;
var
  vKey: TAccountBlockHashKey;
  vHash: THash;
begin
  vKey := TAccountBlockHashKey.Create;
  try
    vHash := THash.HexToHash('ab750df7fa9736f445572ed9c9c979c61368907d4b9f2f81fbf1822b2d947b50');
    TestFramework.Log(TEncoding.Default.GetString(vKey.Bytes));
    vKey.HashRefill(vHash);
    TestFramework.Log(TEncoding.Default.GetString(vKey.Bytes));
  finally
    vKey.Free;
  end;
end;

procedure TGenerateKeyTest.TestCopy;
var
  vAddr: TAddress;
  vKey: TBytes;
  vPadded: TBytes;
begin
  vAddr := TAddress.HexToAddress('vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a');
  vKey := CreateStorageValueKey(vAddr, [1, 1]);
  TestFramework.Log(TEncoding.Default.GetString(vKey));
  vPadded := TCommon.RightPadBytes([1, 2, 3], 32);
  System.Move(vPadded[0], vKey[1 + TAddress.AddressSize], Length(vPadded));
  TestFramework.Log(TEncoding.Default.GetString(vKey));
end;

procedure TGenerateKeyTest.TestCopy2;
begin
  TestFramework.Log(TEncoding.Default.GetString(TBytes.Create(49, 49, 49))); // '111'
  TestFramework.Log(string(TBytes.Create(49)));
  TestFramework.Log(string(TCommon.RightPadBytes(TBytes.Create(49), 32)));
end;

procedure TGenerateKeyTest.TestCreateAccountBlockHashKey;
var
  vHash: THash;
  vKey: TAccountBlockHashKey;
begin
  vHash := THash.HexToHash('ab750df7fa9736f445572ed9c9c979c61368907d4b9f2f81fbf1822b2d947b50');
  vKey := CreateAccountBlockHashKey(vHash);
  TestFramework.Log(TEncoding.Default.GetString(vKey.Bytes));
end;

procedure TGenerateKeyTest.TestRefillHeight;
var
  vAddr: TAddress;
  vKey, vKey2: IStorageValueKey;
begin
  vAddr := TAddress.HexToAddress('vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a');
  vKey := CreateStorageValueKey(vAddr, [2, 4]);
  vKey.KeyRefill(TStorageRealKey.Construct([5, 1]));
  vKey2 := CreateStorageValueKey(vAddr, [5, 1]);

  TestFramework.Log(Format('%s, %d', [TEncoding.Default.GetString(vKey.Bytes), Length(vKey.Bytes)]));
  TestFramework.Log(Format('%s, %d', [TEncoding.Default.GetString(vKey2.Bytes), Length(vKey2.Bytes)]));
end;

procedure TGenerateKeyTest.TestCreateBalanceKey;
var
  vAddr: TAddress;
  vKey: IBalanceKey;
begin
  vAddr := TAddress.HexToAddress('vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a');
  vKey := CreateBalanceKey(vAddr, ViteTokenId);
  TestFramework.Log(Format('%s, %d', [TEncoding.Default.GetString(vKey.Bytes), Length(vKey.Bytes)]));
end;

procedure TGenerateKeyTest.TestCreateBalanceHistoryKey;
var
  vAddr: TAddress;
  vKey: IHistoryBalanceKey;
begin
  vAddr := TAddress.HexToAddress('vite_ab24ef68b84e642c0ddca06beec81c9acb1977bbd7da27a87a');
  vKey := CreateHistoryBalanceKey(vAddr, ViteTokenId, 123);
  TestFramework.Log(Format('%s, %d', [TEncoding.Default.GetString(vKey.Bytes), Length(vKey.Bytes)]));
end;

end.
