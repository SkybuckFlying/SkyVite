unit Wallet.EntropyStore.CryptoStore.Test;

interface

uses
  SysUtils,
  DUnitX.TestFramework,
  GoToDelphi.Helpers.TBytes,
  Vite.Common.Types,
  Vite.Common.FileUtils,
  Vite.Crypto,
  Wallet.EntropyStore.CryptoStore,
  Wallet.HD_BIP.Derivation;

const
  TestEntropy = '...'; // Replace with actual test entropy from Go test if available

type
  [TestFixture]
  TTestCryptoStore = class
  public
    [Test]
    procedure TestStoreAndExtractEntropy;
    [Test]
    procedure TestDecryptEntropy;
  end;

implementation

uses
  System.IOUtils,
  System.NetEncoding,
  BIP39,
  Vite.Common.Errors;

procedure TTestCryptoStore.TestStoreAndExtractEntropy;
var
  vEntropy, vSeed, vSeedExtract, vEntropyExtract: TBytes;
  vMnemonic: string;
  vPrimaryAddr: TAddress;
  vFilename: string;
  vStore: TCryptoStore;
begin
  vEntropy := TBIP39.NewEntropy(256);
  vMnemonic := TBIP39.NewMnemonic(vEntropy);
  WriteLn(vMnemonic);
  vSeed := TBIP39.NewSeed(vMnemonic, '');
  WriteLn('hexSeed:', TNetEncoding.Base16.EncodeBytesToString(vSeed));

  vPrimaryAddr := TDerivation.GetPrimaryAddress(vSeed);

  vFilename := TPath.Combine(TFileUtils.CreateTempDir, vPrimaryAddr.ToString);
  vStore := TCryptoStore.Create(vFilename);
  try
    vStore.StoreEntropy(vEntropy, vPrimaryAddr, '123456');
    WriteLn(vFilename);

    vStore.ExtractSeed('123456', vSeedExtract, vEntropyExtract);
    WriteLn(TBIP39.NewMnemonic(vEntropyExtract));

    Assert.IsTrue(TViteTypes.BytesEqual(vSeed, vSeedExtract), 'Seed mismatch');
  finally
    vStore.Free;
  end;
end;

procedure TTestCryptoStore.TestDecryptEntropy;
var
  vEntropy, vSeed, vJson, vDecryptEntropy: TBytes;
  vMnemonic: string;
  vPrimaryAddr: TAddress;
begin
  vEntropy := TNetEncoding.Base16.Decode(TestEntropy);
  vMnemonic := TBIP39.NewMnemonic(vEntropy);
  vSeed := TBIP39.NewSeed(vMnemonic, '');
  vPrimaryAddr := TDerivation.GetPrimaryAddress(vSeed);

  vJson := TCryptoStore.EncryptEntropy(vEntropy, vPrimaryAddr, '123456');
  WriteLn(TEncoding.UTF8.GetString(vJson));

  // Success case
  WriteLn('success case:');
  vDecryptEntropy := TCryptoStore.DecryptEntropy(vJson, '123456');
  Assert.IsTrue(TViteTypes.BytesEqual(vEntropy, vDecryptEntropy), 'Entropy mismatch in success case');

  // Passphrase error case
  WriteLn('passphrase error case:');
  try
    TCryptoStore.DecryptEntropy(vJson, '1234576');
    Assert.Fail('Expected EDecryptError was not raised');
  except
    on E: EDecryptError do
    begin
      // Expected exception
    end
    else
    begin
      raise;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCryptoStore);
end.
