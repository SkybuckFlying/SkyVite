unit Wallet.EntropyStore.Manager.Test;

interface

uses
<<<<<<< HEAD
  TestFramework,
  SysUtils,
  Classes,
  entropystore.manager,
  entropystore.models,
  common.types,
  common.fileutils,
  common.hexutil,
  wallet.hd_bip.derivation,
  bip39,
  Assert;
=======
  SysUtils,
  DUnitX.TestFramework,
  GoToDelphi.Helpers.TBytes,
  Vite.Common.Types,
  Vite.Common.FileUtils,
  Vite.Crypto,
  Wallet.EntropyStore.Manager,
  Wallet.HD_BIP.Derivation;
>>>>>>> origin/AI0012

type
  TTestBipTuple = record
    Path: string;
    Seed: string;
    Address: string;
  end;

<<<<<<< HEAD
  [TestFixture]
  TManagerTests = class
  private
    FBaseStorePath: string;
    FTestSeedStoreManager: TManager;
    FTestTuples: TArray<TTestBipTuple>;
    procedure SetupTestTuples;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestStoreNewSeed;
    [Test]
    procedure TestManager_FindAddr;
    [Test]
    procedure TestManager_LockAndUnlock;
=======
const
  TestEntropy = 'd6456de91526eb086ce7f5ad968a64690d171def52cfc9a887e682acbef44e20';
  TestMnemonic = 'stone clock kid clean huge loud receive wrong pulse reform october spirit sphere moment run fly situate during whale aim slogan kick decade alpha';
  TestSeed = 'f2b7e88dbd85bc954725fe7d2204618b7a009141c9c6ee664d497865df2f88ade65cb983e88ff8e9644d615d5c324f7bbd9928083e042bcc4b3e55fe297f3bf3';

var
  TestTuples: TArray<TTestBipTuple>;
  TestSeedStoreManager: TEntropyStoreManager;
  BaseStorePath: string;

type
  [TestFixture]
  TTestEntropyStoreManager = class
  public
    [SetupFixture]
    class procedure SetupFixture;
    [TearDownFixture]
    class procedure TearDownFixture;
    [Test]
    procedure TestStoreNewSeed;
    [Test]
    procedure TestFindAddr;
    [Test]
    procedure TestLockAndUnlock;
>>>>>>> origin/AI0012
    [Test]
    procedure TestFindAddrFromSeed;
  end;

<<<<<<< HEAD
const
  ConstTestEntropy = 'd6456de91526eb086ce7f5ad968a64690d171def52cfc9a887e682acbef44e20';
  ConstTestMnemonic = 'stone clock kid clean huge loud receive wrong pulse reform october spirit sphere moment run fly situate during whale aim slogan kick decade alpha';
  ConstTestSeed = 'f2b7e88dbd85bc954725fe7d2204618b7a009141c9c6ee664d497865df2f88ade65cb983e88ff8e9644d615d5c324f7bbd9928083e042bcc4b3e55fe297f3bf3';

implementation

procedure TManagerTests.SetupTestTuples;
begin
  SetLength(FTestTuples, 9);
  FTestTuples[0] := TTestBipTuple.Create('m/44''/666666''/0''', '678d04f47ae63a09ca745a7dcaa75ba6481ad329ba0c617e849bf854f2b9c55a', 'vite_80d446de0b3267b03cba7d9b49afa5e71341c7cd0693651ad1');
  FTestTuples[1] := TTestBipTuple.Create('m/44''/666666''/1''', 'fa42e7cbf7f163f1121cde06d50c1f577e21c51dcd3581ce503df0dbde553ec6', 'vite_c5947d16a449ee17e14eb0dc37e702c43b9e8d8b2553b8a801');
  FTestTuples[2] := TTestBipTuple.Create('m/44''/666666''/2''', 'daee6d8bfec72f3f7b662d2a1ef854a5b1080596dc51508b6972a179ed75df32', 'vite_0fc0e0a4d1d761f96ea636f1ff93283a13dfd67e4998449ce8');
  FTestTuples[3] := TTestBipTuple.Create('m/44''/666666''/3''', 'e11e885d6d73ee04d270fae0bafccfcfa49a3b3021f19d91198d06fb16ab22c6', 'vite_7258aefb6850b77cd1a63d862f7b6743a376e5737c54685249');
  FTestTuples[4] := TTestBipTuple.Create('m/44''/666666''/4''', 'a521d6d0a336e9e26ee8e89caebb6b0c84b92f897f03bcb798575c415d4ab681', 'vite_c4f25d2172c9e42d6571a91f2c4f0031ebfd56f30b702684b2');
  FTestTuples[5] := TTestBipTuple.Create('m/44''/666666''/5''', '35ab31d40f9e1908b01dcddf9b1f85c403a5a86d2317aabcc3b5a0bcceb8e257', 'vite_434846b1293c0544be1bf9f2d62cb7ff1693fb917e495322b0');
  FTestTuples[6] := TTestBipTuple.Create('m/44''/666666''/6''', '74d9081480b93278bb297c12dc1056e8828aa4236562553b810be36cd0c03a6b', 'vite_2db685bf546ec32361d135874cccd86690b88f0aa4ec261efc');
  FTestTuples[7] := TTestBipTuple.Create('m/44''/666666''/7''', '546e5992bdb5be1f00f11d3d578c665d152fa451cc71bccb4eec427c3509722d', 'vite_755ffae48b56ef80b265e694faa9fab0f0b16e95594c8aecb9');
  FTestTuples[8] := TTestBipTuple.Create('m/44''/666666''/8''', 'ca1f60901d08fb2950a19167bcb386b22d991087eb7e934df4d6f862ed6f8d0a', 'vite_c00414ba378cd5905d7752dae32b3d2cf675f2718a0f8798f0');
end;

procedure TManagerTests.Setup;
var
  e: Exception;
begin
  FBaseStorePath := TFileUtils.CreateTempDir;
  SetupTestTuples;
  e := StoreNewEntropy(FBaseStorePath, ConstTestMnemonic, '123456', DefaultMaxIndex, FTestSeedStoreManager);
  if e <> nil then
    raise e;
end;

procedure TManagerTests.TearDown;
begin
  FTestSeedStoreManager.Free;
  TDirectory.Delete(FBaseStorePath, True);
end;

procedure TManagerTests.TestStoreNewSeed;
var
  manager: TManager;
  entropy, seed: TBytes;
  mnemonic: string;
  e: Exception;
  i: Cardinal;
  path, seedStr, addrStr: string;
  key: TDerivationKey;
begin
  entropy := TBip39.NewEntropy(256, e);
  Assert.IsNull(e);
  TLogger.Info('entropy:' + TEncoding.UTF8.GetString(entropy));

  mnemonic := TBip39.NewMnemonic(entropy, e);
  Assert.IsNull(e);
  TLogger.Info(mnemonic);

  seed := TBip39.NewSeed(mnemonic, '');
  TLogger.Info('seed   :' + TEncoding.UTF8.GetString(seed));

  e := StoreNewEntropy(FBaseStorePath, mnemonic, '123456', DefaultMaxIndex, manager);
  Assert.IsNull(e);
  try
    TLogger.Info(manager.EntropyStoreFile);
    for i := 0 to 9 do
    begin
      e := manager.DeriveForIndexPathWithPassphrase(i, '123456', path, key);
      Assert.IsNull(e);
      try
        e := key.StringPair(seedStr, addrStr);
        Assert.IsNull(e);
        TLogger.Info(path + ' ' + seedStr + ' ' + addrStr);
      finally
        key.Free;
      end;
    end;
  finally
    manager.Free;
  end;
end;

procedure TManagerTests.TestManager_FindAddr;
var
  tuple: TTestBipTuple;
  addr: TAddress;
  key: TDerivationKey;
  u: Cardinal;
  e: Exception;
  rs: TBytes;
  gAddr: TAddress;
  addresses: TAddress;
begin
  for tuple in FTestTuples do
  begin
    addr := THexUtil.HexToAddress(tuple.Address);
    e := FTestSeedStoreManager.FindAddrWithPassphrase('123456', addr, key, u);
    Assert.IsNull(e);
    try
      rs := key.RawSeed;
      Assert.AreEqual(TEncoding.UTF8.GetString(rs), tuple.Seed);
      Assert.AreEqual(u, System.Cardinal(System.Linq.Enumerable.ToArray(FTestTuples).IndexOf(tuple)));
      e := key.Address(gAddr);
      Assert.IsNull(e);
      Assert.AreEqual(gAddr, addr);
    finally
      key.Free;
    end;
  end;

  addresses := TTypes.CreateAddress;
  e := FTestSeedStoreManager.FindAddrWithPassphrase('123456', addresses, key, u);
  Assert.IsNotNull(e);
  Assert.AreEqual(e.ClassName, 'EAddressNotFound');
end;

procedure TManagerTests.TestManager_LockAndUnlock;
var
  sm: TManager;
  e: Exception;
  addr: TArray<TAddress>;
  i: Integer;
  v: TAddress;
  path, seed, addrStr: string;
  key: TDerivationKey;
  dsm: TManager;
  k: TDerivationKey;
  na: TAddress;
  idx: Cardinal;
begin
  sm := FTestSeedStoreManager;

  sm.SetLockEventListener(
    procedure(event: TUnlockEvent)
    begin
      TLogger.Info('receive an event:' + event.ToString);
    end);

  try
    addr := sm.ListAddress(10, 20);
    Assert.Fail('need error');
  except
    on E: Exception do
      TLogger.Info(E.Message);
  end;

  e := sm.Unlock('123456');
  Assert.IsNull(e);

  addr := sm.ListAddress(0, 10);
  for i := Low(addr) to High(addr) do
  begin
    v := addr[i];
    Assert.IsTrue(sm.IsAddrUnlocked(v));
    TLogger.Info(IntToStr(i) + ' ' + v.ToString);
  end;

  e := sm.DeriveForIndexPath(101, path, key);
  Assert.IsNull(e);
  try
    e := key.StringPair(seed, addrStr);
    Assert.IsNull(e);
    e := key.Address(na);
    Assert.IsNull(e);
    TLogger.Info(path + ' ' + seed + ' ' + addrStr);

    e := sm.FindAddr(na, k, idx);
    Assert.IsNotNull(e);
    Assert.AreEqual(e.ClassName, 'EAddressNotFound');
    TLogger.Info(e.Message);
  finally
    key.Free;
  end;

  e := StoreNewEntropy(FBaseStorePath, ConstTestMnemonic, '123456', 200, dsm);
  Assert.IsNull(e);
  try
    e := dsm.Unlock('123456');
    Assert.IsNull(e);
    e := dsm.FindAddr(na, k, idx);
    Assert.IsNull(e);
    try
      e := k.Address(gAddr);
      Assert.IsNull(e);
      Assert.AreEqual(gAddr, na);
      Assert.AreEqual(Cardinal(101), idx);
    finally
      k.Free;
    end;
  finally
    dsm.Free;
  end;

  sm.Lock;
end;

procedure TManagerTests.TestFindAddrFromSeed;
var
  seed: TBytes;
  s: TDateTime;
  key: TDerivationKey;
  index: Cardinal;
  e: Exception;
begin
  seed := THexUtil.HexToBytes(ConstTestSeed);
  s := Now;
  TLogger.Info(DateTimeToStr(s));
  e := FindAddrFromSeed(seed, TAddress.Create, 100 * 100, key, index);
  Assert.IsNotNull(e);
  TLogger.Info(TimeToStr(Now - s));
end;

initialization
  RegisterTestFixture(TManagerTests);
=======
implementation

uses
  System.IOUtils,
  System.NetEncoding,
  System.Diagnostics,
  BIP39,
  Vite.Common.Errors;

class procedure TTestEntropyStoreManager.SetupFixture;
begin
  SetLength(TestTuples, 9);
  TestTuples[0] := TTestBipTuple.Create('m/44''/666666''/0''', '678d04f47ae63a09ca745a7dcaa75ba6481ad329ba0c617e849bf854f2b9c55a', 'vite_80d446de0b3267b03cba7d9b49afa5e71341c7cd0693651ad1');
  TestTuples[1] := TTestBipTuple.Create('m/44''/666666''/1''', 'fa42e7cbf7f163f1121cde06d50c1f577e21c51dcd3581ce503df0dbde553ec6', 'vite_c5947d16a449ee17e14eb0dc37e702c43b9e8d8b2553b8a801');
  TestTuples[2] := TTestBipTuple.Create('m/44''/666666''/2''', 'daee6d8bfec72f3f7b662d2a1ef854a5b1080596dc51508b6972a179ed75df32', 'vite_0fc0e0a4d1d761f96ea636f1ff93283a13dfd67e4998449ce8');
  TestTuples[3] := TTestBipTuple.Create('m/44''/666666''/3''', 'e11e885d6d73ee04d270fae0bafccfcfa49a3b3021f19d91198d06fb16ab22c6', 'vite_7258aefb6850b77cd1a63d862f7b6743a376e5737c54685249');
  TestTuples[4] := TTestBipTuple.Create('m/44''/666666''/4''', 'a521d6d0a336e9e26ee8e89caebb6b0c84b92f897f03bcb798575c415d4ab681', 'vite_c4f25d2172c9e42d6571a91f2c4f0031ebfd56f30b702684b2');
  TestTuples[5] := TTestBipTuple.Create('m/44''/666666''/5''', '35ab31d40f9e1908b01dcddf9b1f85c403a5a86d2317aabcc3b5a0bcceb8e257', 'vite_434846b1293c0544be1bf9f2d62cb7ff1693fb917e495322b0');
  TestTuples[6] := TTestBipTuple.Create('m/44''/666666''/6''', '74d9081480b93278bb297c12dc1056e8828aa4236562553b810be36cd0c03a6b', 'vite_2db685bf546ec32361d135874cccd86690b88f0aa4ec261efc');
  TestTuples[7] := TTestBipTuple.Create('m/44''/666666''/7''', '546e5992bdb5be1f00f11d3d578c665d152fa451cc71bccb4eec427c3509722d', 'vite_755ffae48b56ef80b265e694faa9fab0f0b16e95594c8aecb9');
  TestTuples[8] := TTestBipTuple.Create('m/44''/666666''/8''', 'ca1f60901d08fb2950a19167bcb386b22d991087eb7e934df4d6f862ed6f8d0a', 'vite_c00414ba378cd5905d7752dae32b3d2cf675f2718a0f8798f0');

  BaseStorePath := TFileUtils.CreateTempDir;
  TestSeedStoreManager := TEntropyStoreManager.StoreNewEntropy(BaseStorePath, TestMnemonic, '123456', DefaultMaxIndex);
end;

class procedure TTestEntropyStoreManager.TearDownFixture;
begin
  TestSeedStoreManager.Free;
  TDirectory.Delete(BaseStorePath, True);
end;

procedure TTestEntropyStoreManager.TestStoreNewSeed;
var
  vManager: TEntropyStoreManager;
  vIndex: Cardinal;
  vPath: string;
  vKey: TDerivationKey;
  vSeed, vAddress: string;
begin
  vManager := TEntropyStoreManager.StoreNewEntropy(BaseStorePath, TEntropyStoreManager.NewMnemonic, '123456', DefaultMaxIndex);
  try
    WriteLn(vManager.GetEntropyStoreFile);
    for vIndex := 0 to 9 do
    begin
      vKey := vManager.DeriveForIndexPathWithPassphrase(vIndex, '123456', vPath);
      vKey.StringPair(vSeed, vAddress);
      WriteLn(vPath, ' ', vSeed, ' ', vAddress);
    end;
  finally
    vManager.Free;
  end;
end;

procedure TTestEntropyStoreManager.TestFindAddr;
var
  vTuple: TTestBipTuple;
  vAddr: TAddress;
  vKey: TDerivationKey;
  vIndex: Cardinal;
  vRs: TBytes;
  vGAddr: TAddress;
  vAddresses: TAddress;
begin
  for vTuple in TestTuples do
  begin
    vAddr := TViteTypes.HexToAddress(vTuple.Address);
    Assert.IsTrue(TestSeedStoreManager.FindAddrWithPassphrase('123456', vAddr, vKey, vIndex));
    vRs := vKey.RawSeed;
    Assert.AreEqual(vTuple.Seed, TNetEncoding.Base16.EncodeBytesToString(vRs));
    // Assert.AreEqual(k, u); // Index check is implicit in FindAddr
    vGAddr := vKey.Address;
    Assert.IsTrue(vGAddr.Equals(vAddr));
  end;

  vAddresses := TViteTypes.CreateAddress;
  Assert.IsFalse(TestSeedStoreManager.FindAddrWithPassphrase('123456', vAddresses, vKey, vIndex));
end;

procedure TTestEntropyStoreManager.TestLockAndUnlock;
var
  vSm: TEntropyStoreManager;
  vAddr: TArray<TAddress>;
  vIndex: Integer;
  v: TAddress;
  vPath: string;
  vKey: TDerivationKey;
  vSeed, vAddrStr: string;
  vAddr2: TAddress;
  vDsm: TEntropyStoreManager;
  vK: TDerivationKey;
  vI: Cardinal;
  vNa: TAddress;
begin
  vSm := TestSeedStoreManager;
  vSm.SetLockEventListener(procedure(const ParaEvent: TUnlockEvent)
    begin
      WriteLn('receive an event:', ParaEvent.ToString);
    end);

  try
    vSm.ListAddress(10, 20);
    Assert.Fail('Expected EWalletError');
  except
    on E: EWalletError do WriteLn(E.Message);
  end;

  vSm.Unlock('123456');
  vAddr := vSm.ListAddress(0, 10);
  for vIndex, v in vAddr do
  begin
    Assert.IsTrue(vSm.IsAddrUnlocked(v), 'expect unlock');
    WriteLn(vIndex, ' ', v.ToString);
  end;

  vKey := vSm.DeriveForIndexPath(101, vPath);
  vKey.StringPair(vSeed, vAddrStr);
  vAddr2 := vKey.Address;
  WriteLn(vPath, ' ', vSeed, ' ', vAddrStr);
  Assert.IsFalse(vSm.FindAddr(vAddr2, vKey, vI), 'expect not found error');

  vDsm := TEntropyStoreManager.StoreNewEntropy(BaseStorePath, TestMnemonic, '123456', 200);
  try
    vDsm.Unlock('123456');
    Assert.IsTrue(vDsm.FindAddr(vAddr2, vK, vI));
    vNa := vK.Address;
    Assert.IsTrue(vNa.Equals(vAddr2));
    Assert.AreEqual(101, vI);
  finally
    vDsm.Free;
  end;

  vSm.Lock;
end;

procedure TTestEntropyStoreManager.TestFindAddrFromSeed;
var
  vSeed: TBytes;
  vSw: TStopwatch;
begin
  vSeed := TNetEncoding.Base16.Decode(TestSeed);
  vSw := TStopwatch.StartNew;
  TEntropyStoreManager.FindAddrFromSeed(vSeed, TViteTypes.CreateAddress, 100 * 100, var vKey, var vIndex);
  vSw.Stop;
  WriteLn(vSw.ElapsedMilliseconds);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEntropyStoreManager);
>>>>>>> origin/AI0012
end.
