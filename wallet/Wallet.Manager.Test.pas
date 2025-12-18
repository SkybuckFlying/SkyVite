<<<<<<< HEAD:wallet/manager_test.pas
unit wallet.manager_test;
=======
unit Wallet.Manager.Test;
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas

interface

uses
  <<<<<<< HEAD:wallet/manager_test.pas,
  common.config,
  common.fileutils,
  common.helper,
  common.types,
  DUnitX.TestFramework,
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  Wallet.Account,
  Wallet.Account.Test,
  wallet.manager,
  Wallet.Wallet;
=======
  SysUtils,
  Classes,
  DUnitX.TestFramework,
  GoToDelphi.Helpers.TBytes,
  Vite.Common.Config,
  Vite.Common.FileUtils,
  Vite.Common.Types,
  Vite.Crypto,
  Wallet.Manager,
  Wallet.HD_BIP.Derivation,
  Wallet.EntropyStore;
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas

type
  [TestFixture]
  TManagerTests = class(TObject)
  private
<<<<<<< HEAD:wallet/manager_test.pas
    procedure testManagerRecover(const dir: string);
    procedure testManagerDerive(const dir: string);
=======
    mDir: string;
    procedure TestManagerRecover;
    procedure TestManagerDerive;
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas
  public
    [Test]
    procedure TestManager_NewMnemonicAndSeedStore3;
    [Test]
    procedure TestManage;
    [Test]
<<<<<<< HEAD:wallet/manager_test.pas
=======
    procedure TestNewMnemonicAndEntropyStore;
    [Test]
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas
    procedure TestRead;
  end;

implementation

uses
  System.IOUtils,
<<<<<<< HEAD:wallet/manager_test.pas
  System.Diagnostics;

procedure TManagerTests.testManagerRecover(const dir: string);
=======
  System.Net.HttpClient,
  System.NetEncoding,
  System.Generics.Collections,
  Vite.Wallet;

procedure TTestManager.Setup;
begin
  mDir := TFileUtils.CreateTempDir;
end;

procedure TTestManager.TearDown;
begin
  if TDirectory.Exists(mDir) then
  begin
    TDirectory.Delete(mDir, True);
  end;
end;

procedure TTestManager.TestManagerRecover;
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas
var
  vMneList: TArray<string>;
  vManager: TManager;
  vIndex: Integer;
begin
  vMneList := [
    'alter meat balance father season shop text figure pitch another fade figure faith chat smooth pottery dilemma pause differ equal shuffle series valve render',
    'that split virus bulk piece recall kick cave balance trigger burst license chat fame frog void theme soft unit subject crime tragic hip sand',
    'next aerobic ticket dragon real impulse unaware nut useful laundry forget prize ranch myth portion mail spare coast lonely lunar deer topic pill suspect',
    'twice catch reunion smooth impose predict device valid tobacco romance bind demand boy nest height toy pair salt journey bachelor choice siege setup hire',
    'orient ring dolphin metal arctic giraffe amazing great ticket genuine debate release night fit canvas fancy unknown powder burger window science health master marine',
    'twice nation bulb near fire wrap ensure gym panic color enhance zebra sail caught profit frequent process angle dad goddess jar plunge acid forward',
    'jungle south agent visa document inside sausage degree delay harbor idle sport moon cup pelican innocent bid winter gate blade faith check desert produce',
    'sound flock predict gorilla rhythm image regular ready speed hill globe thunder differ garage sustain vapor midnight arrive quiz tiger drive antique waste depend',
    'patch comic wife chair absurd tree skate win stage innocent anxiety solve spy bunker arrive actress blind ivory health sheriff hurdle enhance toss ensure',
    'sport coral praise boring shed object risk sick nominee render sunset boil aerobic gate genius spell attend tape ghost mercy myself cloud energy culture',
    'whip traffic alley rate frame digital carry survey amused picture cannon polar message lunch foil learn blossom adult together laptop smooth copy hub loop',
    'tobacco author base shift exit advice daughter unable famous twice tuna candy require carpet rocket price sea forget dog burden foster certain zero drop',
    'tide recycle razor cement keep liquid rebuild extend witness avocado era wool parade gravity that vessel blur angle bomb mechanic also prosper oak trick',
    'stereo arrive decline hockey ladder glory hip step toddler acoustic knee update oppose balcony stable various horn patrol click behave arch twice detail spare',
    'lecture weapon grief absorb road erupt call manage vessel rich lonely type wave adult glimpse before similar addict neither found sight finger friend visit',
    'dog depth grunt vault news mirror remind century illness rail main craft keep angle same trick dress brass vibrant voyage toss ceiling pumpkin fix',
    'bargain among length moral physical awkward face abstract wolf inhale nose what assault escape battle curious antenna proud express dismiss enrich lesson draw witness',
    'cash flower awesome describe style chunk expose dance figure same arrive foster blame leader bread dwarf timber random try pattern shove pattern tone antenna',
    'moment what learn beauty hover once fancy develop husband have someone patrol decide mouse total ritual gain minimum snake silk lake tragic bonus sister',
    'together perfect goddess fire broken strategy clog toe cat proud pupil enforce gaze nasty assist coin invest chat subject door theme toilet fitness lawsuit',
    'antenna donor silly valid priority runway fabric click weird need enroll ozone lottery shed blue narrow athlete coach fix drastic aware cruel depart that',
    'drive lobster pride frequent orbit citizen table thank build super seek shaft immense high hidden another sauce clever ensure miss spider sunset rotate key',
    'vibrant monitor example unhappy celery solve inject wire thank spatial suffer kick ship excite flower border erode clog chuckle seven despair chat desert daring',
    'oblige maid inch hamster joy talent poverty announce old return grass smile ginger hill delay evidence buyer curtain mutual any struggle squirrel skill whip',
    'remove protect wet couch moral slight slot virtual north where print chimney rack fresh barely angle hurdle scrub diet elder raise easily eager crisp'
  ];

<<<<<<< HEAD:wallet/manager_test.pas
  manager := TManager.Create(TConfigWallet.Create(dir));
  try
    err := manager.Start;
    Assert.IsNull(err);
    for i := 0 to Length(mneList) - 1 do
    begin
      _, err := manager.RecoverEntropyStoreFromMnemonic(mneList[i], '123456');
      Assert.IsNull(err);
    end;
    manager.Stop;
  finally
    manager.Free;
  end;
end;

procedure TManagerTests.TestManager_NewMnemonicAndSeedStore3;
var
  manager: TManager;
  i: Integer;
  err: Exception;
begin
  manager := TManager.Create(TConfigWallet.Create(TFileUtils.CreateTempDir));
=======
  vManager := TManager.Create(TWalletConfig.Create(mDir, 0));
  try
    vManager.Start;
    for vIndex := 0 to High(vMneList) do
    begin
      Assert.IsNotNull(vManager.RecoverEntropyStoreFromMnemonic(vMneList[vIndex], '123456'));
    end;
  finally
    vManager.Stop;
    vManager.Free;
  end;
end;

procedure TTestManager.TestNewMnemonicAndEntropyStore;
var
  vManager: TManager;
  vIndex: Integer;
  vMnemonic: string;
  vEm: TEntropyStoreManager;
begin
  vManager := TManager.Create(TWalletConfig.Create(TFileUtils.CreateTempDir, 0));
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas
  try
    for vIndex := 1 to 5 do
    begin
<<<<<<< HEAD:wallet/manager_test.pas
      _, _, err := manager.NewMnemonicAndEntropyStore('123456');
      Assert.IsNull(err);
=======
      vEm := vManager.NewMnemonicAndEntropyStore('123456', vMnemonic);
      Assert.IsNotNull(vEm);
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas
    end;
  finally
    vManager.Free;
  end;
end;

procedure TManagerTests.testManagerDerive(const dir: string);
var
<<<<<<< HEAD:wallet/manager_test.pas
  manager: TManager;
  err: Exception;
  files: TArray<string>;
  v: string;
  storeManager: TEntropyStoreManager;
  key: TDerivationKey;
  keys: TEd25519PrivateKey;
  addr, address: TAddress;
  i: Integer;
begin
  manager := TManager.Create(TConfigWallet.Create(TFileUtils.CreateTempDir));
  try
    err := manager.Start;
    Assert.IsNull(err);
    files := manager.ListAllEntropyFiles;
    for v in files do
    begin
      storeManager := manager.GetEntropyStoreManager(v);
      Assert.IsNotNull(storeManager);
      err := storeManager.Unlock('123456');
      Assert.IsNull(err);
      err := storeManager.DeriveForIndexPath(0, _, key);
      Assert.IsNull(err);
      err := key.PrivateKey(keys);
      Assert.IsNull(err);
      err := key.Address(addr);
      Assert.IsNull(err);
      Writeln(Format('%s,0:%s,%s', [addr.ToString, addr.ToString, keys.Hex]));

      for i := 0 to 24 do
      begin
        err := storeManager.DeriveForIndexPath(i, _, key);
        Assert.IsNull(err, Format('deriver for index %d err', [i]));
        err := key.Address(address);
        Assert.IsNull(err);
        Writeln(Format('%d:%s', [i, address.ToString]));
      end;
    end;
    manager.Stop;
  finally
    manager.Free;
=======
  vManager: TManager;
  vFiles: TArray<string>;
  vFile: string;
  vStoreManager: TEntropyStoreManager;
  vKey: TDerivationKey;
  vPrivKey: TEd25519PrivateKey;
  vAddr: TAddress;
  vIndex: Integer;
  vAddress: TAddress;
  vPath: string;
begin
  vManager := TManager.Create(TWalletConfig.Create(mDir, 0));
  try
    vManager.Start;
    vFiles := vManager.ListAllEntropyFiles;
    for vFile in vFiles do
    begin
      vStoreManager := vManager.GetEntropyStoreManager(vFile);
      vStoreManager.Unlock('123456');
      vStoreManager.DeriveForIndexPath(0, vPath, vKey);
      vPrivKey := vKey.PrivateKey;
      vAddr := vKey.Address;
      WriteLn(Format('%s,0:%s,%s', [vAddr.ToString, vAddr.ToString, vPrivKey.ToHex]));

      for vIndex := 0 to 24 do
      begin
        vStoreManager.DeriveForIndexPath(vIndex, vPath, vKey);
        vAddress := vKey.Address;
        WriteLn(Format('%d:%s', [vIndex, vAddress.ToString]));
      end;
    end;
  finally
    vManager.Stop;
    vManager.Free;
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas
  end;
end;

procedure TManagerTests.TestManage;
var
  tmpDir: string;
begin
  tmpDir := TFileUtils.CreateTempDir;
  testManagerRecover(tmpDir);
  testManagerDerive(tmpDir);
end;

procedure TManagerTests.TestRead;
var
<<<<<<< HEAD:wallet/manager_test.pas
  hexPath: string;
  byt: TBytes;
  err: Exception;
  length: Byte;
  nums: TArray<Cardinal>;
  i: Integer;
  path: string;
begin
  hexPath := '020000000d000000000000000000000000';
  byt := THex.DecodeString(hexPath);
  Assert.AreEqual(17, Length(byt));
=======
  vHexPath: string;
  vBytes: TBytes;
  vLength: Byte;
  vNums: TArray<Cardinal>;
  vIndex: Integer;
  vPath: string;
  vReader: TBinaryReader;
  vStream: TMemoryStream;
begin
  vHexPath := '020000000d000000000000000000000000';
  vBytes := TNetEncoding.Base16.Decode(vHexPath);

  Assert.AreEqual(17, System.Length(vBytes), 'Invalid byte array length');
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas

  vLength := vBytes[0];
  Assert.AreEqual(2, vLength, 'Invalid path length');

<<<<<<< HEAD:wallet/manager_test.pas
  SetLength(nums, 4);
  nums[0] := TBitConverter.ToUInt32(byt, 1);
  nums[1] := TBitConverter.ToUInt32(byt, 6);
  nums[2] := TBitConverter.ToUInt32(byt, 11);
  nums[3] := TBitConverter.ToUInt32(byt, 16);
  Writeln(nums);

  path := 'm';
  for i := 0 to length - 1 do
    path := path + Format('/%d', [nums[i]]);
  Writeln(path);
=======
  vStream := TMemoryStream.Create(vBytes, False);
  try
    vReader := TBinaryReader.Create(vStream, TEncoding.UTF8, True); // True for Big Endian
    try
      vReader.ReadByte; // Skip length byte
      SetLength(vNums, 4);
      vNums[0] := vReader.ReadUInt32;
      vNums[1] := vReader.ReadUInt32;
      vNums[2] := vReader.ReadUInt32;
      vNums[3] := vReader.ReadUInt32;
    finally
      vReader.Free;
    end;
  finally
    vStream.Free;
  end;

  Assert.AreEqual(13, vNums[0]);
  Assert.AreEqual(0, vNums[1]);

  vPath := 'm';
  for vIndex := 0 to vLength - 1 do
  begin
    vPath := vPath + Format('/%d', [vNums[vIndex]]);
  end;

  Assert.AreEqual('m/13/0', vPath);
>>>>>>> origin/AI0012:wallet/Wallet.Manager.Test.pas
end;

initialization
  RegisterTestFixture(TManagerTests);
end.
